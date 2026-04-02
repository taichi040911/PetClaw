## MainScene — メイン画面のUI制御とペット表示の統合
## GameManager（AutoLoad）が全サブシステムを管理し、
## このスクリプトはUI操作とペット表示の橋渡しを行う
## ゲームループ: 卵孵化 → 育成 → 進化 → AtoA会話 → PetBook
class_name MainScene
extends Control

# === UI References ===
@onready var emotion_label: Label = $UIPanel/VBox/EmotionLabel
@onready var hunger_bar: ProgressBar = $UIPanel/VBox/StatsBar/HungerBar
@onready var health_bar: ProgressBar = $UIPanel/VBox/StatsBar/HealthBar
@onready var pet_name_label: Label = $UIPanel/VBox/PetNameLabel
@onready var feed_button: Button = $UIPanel/VBox/ActionButtons/FeedButton
@onready var pet_button: Button = $UIPanel/VBox/ActionButtons/PetButton
@onready var play_button: Button = $UIPanel/VBox/ActionButtons/PlayButton
@onready var petbook_button: Button = $UIPanel/VBox/ActionButtons/PetBookButton
@onready var pets_button: Button = $UIPanel/VBox/NavButtons/PetsButton
@onready var settings_button: Button = $UIPanel/VBox/NavButtons/SettingsButton

# === Pet Reference ===
var current_pet: PetEntity
var pet_display_node: Node2D

# === Screen Navigation ===
var petbook_screen: PetBookScreen
var _petbook_scene: PackedScene = preload("res://scenes/pet_book_screen.tscn")

# === Game State ===
var _is_first_launch: bool = false
var _evolution_screen: EvolutionChoiceScreen
var _conversation_bubble: ConversationBubble
var _sfx: SfxManager
var _day_night: DayNightCycle
var _bgm: AmbientBGM
var _notifications: CareNotification

# === UI Theme Colors ===
const UI_BG: Color = Color(0.08, 0.10, 0.18)
const UI_PANEL_BG: Color = Color(0.12, 0.14, 0.22, 0.95)
const UI_ACCENT: Color = Color(0.4, 0.75, 0.95)
const UI_FEED_COLOR: Color = Color(0.35, 0.8, 0.45)
const UI_PET_COLOR: Color = Color(0.9, 0.5, 0.65)
const UI_PLAY_COLOR: Color = Color(0.95, 0.75, 0.2)
const UI_BOOK_COLOR: Color = Color(0.5, 0.6, 0.9)

const EMOTION_COLORS: Dictionary = {
	"joy": Color(1.0, 0.92, 0.3),
	"love": Color(1.0, 0.5, 0.6),
	"excitement": Color(1.0, 0.7, 0.15),
	"sadness": Color(0.5, 0.6, 0.85),
	"fear": Color(0.65, 0.5, 0.8),
	"neutral": Color(0.7, 0.75, 0.8),
}

const EMOTION_ICONS: Dictionary = {
	"joy": "☀",
	"love": "♥",
	"excitement": "⚡",
	"sadness": "💧",
	"fear": "👁",
	"neutral": "—",
}


func _ready() -> void:
	# SFXマネージャー初期化
	_sfx = SfxManager.new()
	add_child(_sfx)

	# 昼夜サイクル初期化
	_day_night = DayNightCycle.new()
	add_child(_day_night)
	_day_night.setup($Background, $PetArea)

	# BGM初期化・開始
	_bgm = AmbientBGM.new()
	add_child(_bgm)
	_bgm.start()

	# ケア通知初期化
	_notifications = CareNotification.new()
	add_child(_notifications)

	# UIスタイリング
	_apply_ui_theme()

	# ボタン接続
	feed_button.pressed.connect(_on_feed_pressed)
	pet_button.pressed.connect(_on_pet_pressed)
	play_button.pressed.connect(_on_play_pressed)
	petbook_button.pressed.connect(_on_petbook_pressed)
	pets_button.pressed.connect(_on_pets_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

	# GameManager の初期化完了を待つ
	await get_tree().process_frame
	await get_tree().process_frame

	# セーブデータの有無で初回起動を判定
	if GameManager.instance and GameManager.instance.pets.size() == 0:
		_is_first_launch = true
		_show_egg_hatch()
	else:
		_setup_pet_display()

	# 初回チュートリアル判定
	if not FileAccess.file_exists("user://tutorial_done.flag"):
		_show_tutorial()

	# GameManager シグナル接続
	_connect_game_signals()


var _warning_pulse_time: float = 0.0
var _action_cooldowns: Dictionary = {}  # action_name → time_remaining
const ACTION_COOLDOWN: float = 2.0
var _pet_sleeping: bool = false
var _sleep_label: Label

func _process(delta: float) -> void:
	_warning_pulse_time += delta
	_update_cooldowns(delta)
	_update_sleep_state()
	if current_pet and current_pet.is_alive:
		_update_ui()
		_update_status_warnings()


func _connect_game_signals() -> void:
	if not GameManager.instance:
		return

	# 進化可能シグナル
	if GameManager.instance.evolution_mechanics:
		if GameManager.instance.evolution_mechanics.has_signal("evolution_available"):
			GameManager.instance.evolution_mechanics.evolution_available.connect(
				_on_evolution_available
			)

	# AtoA 会話シグナル
	if GameManager.instance.a2a_system:
		if GameManager.instance.a2a_system.has_signal("conversation_message"):
			GameManager.instance.a2a_system.conversation_message.connect(
				_on_conversation_message
			)

	# 死亡シグナル
	if GameManager.instance.life_death:
		if GameManager.instance.life_death.has_signal("pet_died"):
			GameManager.instance.life_death.pet_died.connect(_on_pet_died)


# === 初回起動: 卵孵化 ===

func _show_egg_hatch() -> void:
	# メインUIを隠す
	$PetArea.visible = false
	$UIPanel.visible = false

	var hatch_screen: EggHatchScreen = EggHatchScreen.new()
	hatch_screen.hatch_completed.connect(_on_hatch_completed)
	add_child(hatch_screen)


func _on_hatch_completed(pet: PetEntity) -> void:
	current_pet = pet
	_is_first_launch = false

	# PetDisplay にペットを配置
	$PetArea.visible = true
	$UIPanel.visible = true

	pet_display_node = $PetArea/SubViewport/PetDisplay
	var pet_node: Node = pet_display_node.get_node_or_null("PetEntity")
	if pet_node is PetEntity:
		# 既存の PetEntity にデータをコピー
		pet_node.pet_name = pet.pet_name
		pet_node.pet_id = pet.pet_id
		pet_node.stats = pet.stats
		pet_node.personality = pet.personality
		pet_node.emotions = pet.emotions
		current_pet = pet_node

		if GameManager.instance:
			GameManager.instance.register_pet(current_pet)

	pet_name_label.text = current_pet.pet_name

	# シグナル接続
	if not current_pet.emotion_changed.is_connected(_on_emotion_changed):
		current_pet.emotion_changed.connect(_on_emotion_changed)
	if not current_pet.stat_changed.is_connected(_on_stat_changed):
		current_pet.stat_changed.connect(_on_stat_changed)

	# 孵化画面を削除（子ノードから探す）
	for child: Node in get_children():
		if child is EggHatchScreen:
			child.queue_free()


# === ペット表示セットアップ ===

func _setup_pet_display() -> void:
	pet_display_node = $PetArea/SubViewport/PetDisplay
	if not pet_display_node:
		push_warning("PetDisplay node not found")
		return

	var pet_node: Node = pet_display_node.get_node_or_null("PetEntity")
	if pet_node is PetEntity:
		current_pet = pet_node
	else:
		if GameManager.instance and GameManager.instance.pets.size() > 0:
			var first_id: int = GameManager.instance.pets.keys()[0]
			current_pet = GameManager.instance.pets[first_id]

	if current_pet:
		pet_name_label.text = current_pet.pet_name
		if GameManager.instance:
			GameManager.instance.register_pet(current_pet)
		current_pet.emotion_changed.connect(_on_emotion_changed)
		current_pet.stat_changed.connect(_on_stat_changed)


func _update_ui() -> void:
	if not current_pet:
		return

	# スタッツバーの更新（スムーズ補間）
	hunger_bar.value = lerpf(hunger_bar.value, current_pet.stats.hunger * 100.0, 0.1)
	health_bar.value = lerpf(health_bar.value, current_pet.stats.health * 100.0, 0.1)

	# 空腹バーの色変化（低いと赤に）
	var hunger_ratio: float = current_pet.stats.hunger
	if hunger_ratio < 0.3:
		hunger_bar.modulate = Color(1.0, 0.4, 0.4).lerp(Color.WHITE, hunger_ratio / 0.3)
	else:
		hunger_bar.modulate = Color.WHITE

	# BGMのムード更新
	var dominant_emotion: String = _get_dominant_emotion()
	if _bgm:
		_bgm.set_mood(dominant_emotion)

	# 感情表示（アイコン + 色付き）
	var emotion_icon: String = EMOTION_ICONS.get(dominant_emotion, "—")
	var emotion_color: Color = EMOTION_COLORS.get(dominant_emotion, Color.WHITE)
	emotion_label.text = "%s %s" % [emotion_icon, dominant_emotion.capitalize()]
	emotion_label.add_theme_color_override("font_color", emotion_color)


func _update_status_warnings() -> void:
	if not current_pet:
		return

	var hunger: float = current_pet.stats.hunger
	var health: float = current_pet.stats.health

	# 空腹警告 — アイコンがパルスする
	var hunger_icon: Label = $UIPanel/VBox/StatsBar/HungerIcon
	if hunger < 0.25:
		var pulse: float = (sin(_warning_pulse_time * 4.0) + 1.0) * 0.5
		hunger_icon.modulate = Color(1.0, 0.3 + pulse * 0.4, 0.3 + pulse * 0.2)
		hunger_icon.add_theme_font_size_override("font_size", int(18 + pulse * 4))
	else:
		hunger_icon.modulate = Color.WHITE
		hunger_icon.add_theme_font_size_override("font_size", 18)

	# 体力警告 — ハートアイコンがパルス
	var health_icon: Label = $UIPanel/VBox/StatsBar/HealthIcon
	if health < 0.3:
		var pulse: float = (sin(_warning_pulse_time * 5.0) + 1.0) * 0.5
		health_icon.modulate = Color(1.0, 0.2 + pulse * 0.3, 0.2 + pulse * 0.3)
		health_icon.add_theme_font_size_override("font_size", int(18 + pulse * 5))
	else:
		health_icon.modulate = Color.WHITE
		health_icon.add_theme_font_size_override("font_size", 18)

	# 背景色のムード反映 — 昼夜ベースカラーに感情色をブレンド
	var base_bg: Color = _day_night.get_bg_color() if _day_night else UI_BG
	var dominant: String = _get_dominant_emotion()
	var mood_offset: Color = Color.BLACK
	match dominant:
		"joy":
			mood_offset = Color(0.04, 0.04, -0.02)
		"love":
			mood_offset = Color(0.04, -0.02, 0.0)
		"sadness":
			mood_offset = Color(-0.02, 0.0, 0.04)
		"fear":
			mood_offset = Color(0.02, -0.02, 0.02)
		"excitement":
			mood_offset = Color(0.04, 0.02, -0.04)
	# DayNightCycle handles the main bg lerp; we just nudge it slightly
	if _day_night and _day_night._bg_node:
		var target: Color = Color(
			clampf(base_bg.r + mood_offset.r, 0.0, 0.2),
			clampf(base_bg.g + mood_offset.g, 0.0, 0.2),
			clampf(base_bg.b + mood_offset.b, 0.0, 0.25),
		)
		_day_night._bg_node.color = _day_night._bg_node.color.lerp(target, 0.01)


func _get_dominant_emotion() -> String:
	if not current_pet:
		return "neutral"

	var max_intensity: float = 0.0
	var dominant: String = "neutral"

	for emotion_name: String in current_pet.emotions:
		var intensity: float = current_pet.emotions[emotion_name]
		if intensity > max_intensity:
			max_intensity = intensity
			dominant = emotion_name

	if max_intensity < 0.1:
		return "neutral"
	return dominant


# === Care Actions ===

func _on_feed_pressed() -> void:
	if not current_pet or not current_pet.is_alive:
		return
	if not _try_action("feed"):
		return
	_animate_button(feed_button)
	if _sfx:
		_sfx.play(SfxManager.SfxType.FEED)
	if _pet_sleeping:
		_spawn_floating_text("Zzz... (sleeping)", Color(0.5, 0.5, 0.7))
		return
	_spawn_floating_text("🍖 +Hunger!", UI_FEED_COLOR)
	_screen_shake(2.0, 0.1)
	if GameManager.instance and GameManager.instance.care_system:
		GameManager.instance.care_system.perform_action(current_pet, "feed")
	else:
		current_pet.stats.modify("hunger", 0.2)
		if GameManager.instance and GameManager.instance.emotion_system:
			GameManager.instance.emotion_system.stimulate(
				current_pet.pet_id, "joy", 0.3
			)


func _on_pet_pressed() -> void:
	if not current_pet or not current_pet.is_alive:
		return
	if not _try_action("pet"):
		return
	_animate_button(pet_button)
	if _sfx:
		_sfx.play(SfxManager.SfxType.PET)
	if _pet_sleeping:
		_spawn_floating_text("Zzz... (sleeping)", Color(0.5, 0.5, 0.7))
		return
	_spawn_floating_text("♥ +Love!", UI_PET_COLOR)
	if GameManager.instance and GameManager.instance.care_system:
		GameManager.instance.care_system.perform_action(current_pet, "pet")
	else:
		current_pet.stats.modify("affection", 0.15)
		if GameManager.instance and GameManager.instance.emotion_system:
			GameManager.instance.emotion_system.stimulate(
				current_pet.pet_id, "love", 0.4
			)


func _on_play_pressed() -> void:
	if not current_pet or not current_pet.is_alive:
		return
	if not _try_action("play"):
		return
	_animate_button(play_button)
	if _sfx:
		_sfx.play(SfxManager.SfxType.PLAY)
	if _pet_sleeping:
		_spawn_floating_text("Zzz... (sleeping)", Color(0.5, 0.5, 0.7))
		return
	_spawn_floating_text("⚡ +Fun!", UI_PLAY_COLOR)
	_screen_shake(3.0, 0.12)
	if GameManager.instance and GameManager.instance.care_system:
		GameManager.instance.care_system.perform_action(current_pet, "play")
	else:
		current_pet.stats.modify("energy", -0.1)
		current_pet.stats.modify("mood", 0.2)
		if GameManager.instance and GameManager.instance.emotion_system:
			GameManager.instance.emotion_system.stimulate(
				current_pet.pet_id, "excitement", 0.5
			)


# === Signal Handlers ===

func _on_emotion_changed(emotion: String, intensity: float) -> void:
	var icon: String = EMOTION_ICONS.get(emotion, "—")
	var color: Color = EMOTION_COLORS.get(emotion, Color.WHITE)
	emotion_label.text = "%s %s (%.0f%%)" % [icon, emotion.capitalize(), intensity * 100.0]
	emotion_label.add_theme_color_override("font_color", color)

	# 感情変化時にラベルをパルスさせる
	if intensity > 0.4:
		var tween: Tween = create_tween()
		tween.tween_property(emotion_label, "scale", Vector2(1.1, 1.1), 0.1)
		tween.tween_property(emotion_label, "scale", Vector2(1.0, 1.0), 0.15)


func _on_stat_changed(stat_name: String, _old_value: float, new_value: float) -> void:
	match stat_name:
		"hunger":
			hunger_bar.value = new_value * 100.0
		"health":
			health_bar.value = new_value * 100.0


# === Evolution UI ===

func _on_evolution_available(pet_id: int, choices: Array) -> void:
	if _evolution_screen:
		return

	_evolution_screen = EvolutionChoiceScreen.new()
	_evolution_screen.evolution_chosen.connect(_on_evolution_chosen)
	_evolution_screen.evolution_cancelled.connect(_on_evolution_cancelled)
	add_child(_evolution_screen)

	var typed_choices: Array[Dictionary] = []
	for c: Variant in choices:
		if c is Dictionary:
			typed_choices.append(c)
	_evolution_screen.show_choices(pet_id, typed_choices)


func _on_evolution_chosen(pet_id: int, form_id: String) -> void:
	_evolution_screen = null
	if _sfx:
		_sfx.play(SfxManager.SfxType.EVOLVE)

	if GameManager.instance and GameManager.instance.evolution_mechanics:
		GameManager.instance.evolution_mechanics.execute_evolution(pet_id, form_id)

	# VFX
	if GameManager.instance and GameManager.instance.visual_fx:
		GameManager.instance.visual_fx.play_effect("evolution", {
			"pet_id": pet_id,
		})


func _on_evolution_cancelled() -> void:
	_evolution_screen = null


# === AtoA Conversation Display ===

func _on_conversation_message(pet_id: int, message: String, metadata: Dictionary) -> void:
	if not _conversation_bubble:
		_conversation_bubble = ConversationBubble.new()
		_conversation_bubble.conversation_display_finished.connect(
			func() -> void: _conversation_bubble = null
		)
		add_child(_conversation_bubble)

	# メッセージを吹き出しに追加
	var pet_name: String = "Pet"
	if GameManager.instance and GameManager.instance.pets.has(pet_id):
		pet_name = GameManager.instance.pets[pet_id].pet_name

	var is_left: bool = metadata.get("turn_index", 0) % 2 == 0

	_conversation_bubble.show_conversation([{
		"pet_name": pet_name,
		"text": message,
		"emotion": metadata.get("emotion", "neutral"),
		"is_left": is_left,
	}])


# === Pet Death ===

func _on_pet_died(pet_id: int) -> void:
	if _sfx:
		_sfx.play(SfxManager.SfxType.DEATH)
	if current_pet and current_pet.pet_id == pet_id:
		emotion_label.text = "Your pet has passed away..."
		feed_button.disabled = true
		pet_button.disabled = true
		play_button.disabled = true


# === Screen Navigation ===

# === Tutorial ===

func _show_tutorial() -> void:
	# 卵孵化後にチュートリアルを表示
	await get_tree().create_timer(1.0).timeout

	var tutorial: TutorialOverlay = TutorialOverlay.new()
	tutorial.tutorial_completed.connect(func() -> void:
		# チュートリアル完了フラグを保存
		var file: FileAccess = FileAccess.open("user://tutorial_done.flag", FileAccess.WRITE)
		if file:
			file.store_string("done")
			file.close()
	)
	add_child(tutorial)


# === Settings Screen ===

func _on_settings_pressed() -> void:
	_animate_button(settings_button)
	if _sfx:
		_sfx.play(SfxManager.SfxType.UI_OPEN)
	var settings: SettingsScreen = SettingsScreen.new()
	settings.back_requested.connect(func() -> void:
		settings.queue_free()
		_fade_in_main_ui()
	)
	await _fade_out_main_ui()
	add_child(settings)


# === Pet List Screen ===

func _on_pets_pressed() -> void:
	_animate_button(pets_button)
	if _sfx:
		_sfx.play(SfxManager.SfxType.UI_OPEN)
	var pet_list: PetListScreen = PetListScreen.new()
	pet_list.back_requested.connect(func() -> void:
		pet_list.queue_free()
		_fade_in_main_ui()
	)
	pet_list.pet_selected.connect(func(selected_pet_id: int) -> void:
		if GameManager.instance and GameManager.instance.pets.has(selected_pet_id):
			current_pet = GameManager.instance.pets[selected_pet_id]
			pet_name_label.text = current_pet.pet_name
		pet_list.queue_free()
		_fade_in_main_ui()
	)
	await _fade_out_main_ui()
	add_child(pet_list)


func _on_petbook_pressed() -> void:
	if petbook_screen:
		return
	_animate_button(petbook_button)
	if _sfx:
		_sfx.play(SfxManager.SfxType.UI_OPEN)

	petbook_screen = _petbook_scene.instantiate() as PetBookScreen
	petbook_screen.back_requested.connect(_on_petbook_back)
	await _fade_out_main_ui()
	add_child(petbook_screen)


func _on_petbook_back() -> void:
	if petbook_screen:
		petbook_screen.queue_free()
		petbook_screen = null

	_fade_in_main_ui()


# ========================================================
# UI Theme & Styling
# ========================================================

func _apply_ui_theme() -> void:
	# 背景グラデーション色
	var bg: ColorRect = $Background
	bg.color = UI_BG

	# パネルスタイル
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = UI_PANEL_BG
	panel_style.corner_radius_top_left = 24
	panel_style.corner_radius_top_right = 24
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 8
	$UIPanel.add_theme_stylebox_override("panel", panel_style)

	# ボタンスタイリング
	_style_action_button(feed_button, UI_FEED_COLOR, "🍖 Feed")
	_style_action_button(pet_button, UI_PET_COLOR, "🤚 Pet")
	_style_action_button(play_button, UI_PLAY_COLOR, "⚽ Play")
	_style_action_button(petbook_button, UI_BOOK_COLOR, "📱 Book")

	# ナビボタン
	_style_nav_button(pets_button, "🐾 Pets")
	_style_nav_button(settings_button, "⚙ Settings")

	# ラベルスタイリング
	emotion_label.add_theme_font_size_override("font_size", 20)
	emotion_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))

	pet_name_label.add_theme_font_size_override("font_size", 22)
	pet_name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))

	# スタッツバーのスタイル
	_style_progress_bar(hunger_bar, Color(0.35, 0.8, 0.45))
	_style_progress_bar(health_bar, Color(0.9, 0.35, 0.35))


func _style_action_button(btn: Button, color: Color, label_text: String) -> void:
	btn.text = label_text

	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = color.darkened(0.3)
	normal_style.corner_radius_top_left = 12
	normal_style.corner_radius_top_right = 12
	normal_style.corner_radius_bottom_left = 12
	normal_style.corner_radius_bottom_right = 12
	normal_style.content_margin_left = 8
	normal_style.content_margin_right = 8
	normal_style.content_margin_top = 8
	normal_style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.bg_color = color.darkened(0.1)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style: StyleBoxFlat = normal_style.duplicate()
	pressed_style.bg_color = color
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 16)


func _style_nav_button(btn: Button, label_text: String) -> void:
	btn.text = label_text

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.22, 0.32)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style)

	var hover_style: StyleBoxFlat = style.duplicate()
	hover_style.bg_color = Color(0.3, 0.32, 0.42)
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 14)


func _style_progress_bar(bar: ProgressBar, fill_color: Color) -> void:
	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.17, 0.25)
	bg_style.corner_radius_top_left = 6
	bg_style.corner_radius_top_right = 6
	bg_style.corner_radius_bottom_left = 6
	bg_style.corner_radius_bottom_right = 6
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.corner_radius_top_left = 6
	fill_style.corner_radius_top_right = 6
	fill_style.corner_radius_bottom_left = 6
	fill_style.corner_radius_bottom_right = 6
	bar.add_theme_stylebox_override("fill", fill_style)


# ========================================================
# Action Cooldowns
# ========================================================

func _try_action(action_name: String) -> bool:
	if _action_cooldowns.has(action_name) and _action_cooldowns[action_name] > 0.0:
		return false
	_action_cooldowns[action_name] = ACTION_COOLDOWN
	return true


func _update_cooldowns(delta: float) -> void:
	for key: String in _action_cooldowns:
		_action_cooldowns[key] = maxf(0.0, _action_cooldowns[key] - delta)


# ========================================================
# Sleep State
# ========================================================

func _update_sleep_state() -> void:
	var should_sleep: bool = _day_night != null and _day_night.is_sleepy_time()
	if should_sleep != _pet_sleeping:
		_pet_sleeping = should_sleep
		if _pet_sleeping:
			_show_sleep_indicator()
		else:
			_hide_sleep_indicator()


func _show_sleep_indicator() -> void:
	if _sleep_label:
		return
	_sleep_label = Label.new()
	_sleep_label.text = "Z z z . . ."
	_sleep_label.add_theme_font_size_override("font_size", 28)
	_sleep_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.8, 0.7))
	_sleep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sleep_label.set_anchors_preset(PRESET_CENTER_TOP)
	_sleep_label.offset_top = 50
	_sleep_label.offset_left = -80
	_sleep_label.offset_right = 80
	_sleep_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sleep_label)
	# フェードイン
	_sleep_label.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(_sleep_label, "modulate:a", 1.0, 0.5)


func _hide_sleep_indicator() -> void:
	if not _sleep_label:
		return
	var label: Label = _sleep_label
	_sleep_label = null
	var tween: Tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(label.queue_free)


# ========================================================
# Floating Feedback Text
# ========================================================

func _spawn_floating_text(text: String, color: Color) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(PRESET_CENTER)
	label.offset_left = -100
	label.offset_right = 100
	label.offset_top = -80
	label.offset_bottom = -50
	# ランダムな横方向オフセット
	label.offset_left += randf_range(-40, 40)
	label.offset_right += randf_range(-40, 40)
	label.z_index = 50
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "offset_top", label.offset_top - 80, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "offset_bottom", label.offset_bottom - 80, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)


# ========================================================
# Button Animation
# ========================================================

func _animate_button(btn: Button) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_BACK)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)


# ========================================================
# Screen Shake
# ========================================================

func _screen_shake(intensity: float = 4.0, duration: float = 0.15) -> void:
	var pet_area: SubViewportContainer = $PetArea
	if not pet_area:
		return
	var original_pos: Vector2 = Vector2.ZERO
	var tween: Tween = create_tween()
	for i: int in range(4):
		var offset: Vector2 = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(pet_area, "position", pet_area.position + offset, duration / 8.0)
		tween.tween_property(pet_area, "position", pet_area.position, duration / 8.0)


# ========================================================
# Screen Transitions
# ========================================================

func _fade_out_main_ui() -> void:
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property($PetArea, "modulate:a", 0.0, 0.2)
	tween.tween_property($UIPanel, "modulate:a", 0.0, 0.2)
	await tween.finished
	$PetArea.visible = false
	$UIPanel.visible = false
	$PetArea.modulate.a = 1.0
	$UIPanel.modulate.a = 1.0


func _fade_in_main_ui() -> void:
	$PetArea.visible = true
	$UIPanel.visible = true
	$PetArea.modulate.a = 0.0
	$UIPanel.modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property($PetArea, "modulate:a", 1.0, 0.25)
	tween.tween_property($UIPanel, "modulate:a", 1.0, 0.25)
