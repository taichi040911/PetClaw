## CareNotification — ケア必要通知ポップアップ
## ペットの状態が悪化したとき画面上部にスライドイン通知を表示
## タップで消える。無視すると数秒後に自動フェードアウト
class_name CareNotification
extends Control

signal notification_tapped(notification_type: String)

## 通知タイプ
enum NotifyType {
	HUNGRY,       ## 空腹
	LOW_HEALTH,   ## 体調不良
	LOW_ENERGY,   ## エネルギー低下
	SAD,          ## 悲しい
	LONELY,       ## 放置されている
	CONVERSATION, ## AtoA会話が発生
	NEW_WORD,     ## 新しい単語が発明された
	RELATIONSHIP_UPGRADE,  ## ペット同士が友達/親友になった
	WORD_TAUGHT,           ## ペットが他ペットに言葉を教えた
	LANDMARK_CONVERSATION, ## 高スコア会話が発生
	LANGUAGE_MILESTONE,    ## 言語が新しいステージに進化
}

## 通知データ
const NOTIFY_DATA: Dictionary = {
	NotifyType.HUNGRY: {
		"icon": "🍖",
		"text": "Your pet is hungry!",
		"color": Color(0.9, 0.5, 0.2),
	},
	NotifyType.LOW_HEALTH: {
		"icon": "💊",
		"text": "Your pet feels sick...",
		"color": Color(0.9, 0.3, 0.3),
	},
	NotifyType.LOW_ENERGY: {
		"icon": "😴",
		"text": "Your pet is tired",
		"color": Color(0.5, 0.5, 0.8),
	},
	NotifyType.SAD: {
		"icon": "💧",
		"text": "Your pet is sad...",
		"color": Color(0.4, 0.6, 0.9),
	},
	NotifyType.LONELY: {
		"icon": "💔",
		"text": "Your pet misses you!",
		"color": Color(0.8, 0.4, 0.6),
	},
	NotifyType.CONVERSATION: {
		"icon": "🗣️",
		"text": "",  # 動的に設定
		"color": Color(0.3, 0.7, 0.5),
		"duration": DISPLAY_DURATION,
	},
	NotifyType.NEW_WORD: {
		"icon": "📚",
		"text": "",  # 動的に設定
		"color": Color(0.6, 0.4, 0.8),
		"duration": DISPLAY_DURATION,
	},
	NotifyType.RELATIONSHIP_UPGRADE: {
		"icon": "💕",
		"text": "",  # 動的に設定
		"color": Color(0.85, 0.45, 0.65),
		"duration": 5.0,
	},
	NotifyType.WORD_TAUGHT: {
		"icon": "🎓",
		"text": "",  # 動的に設定
		"color": Color(0.4, 0.65, 0.85),
		"duration": DISPLAY_DURATION,
	},
	NotifyType.LANDMARK_CONVERSATION: {
		"icon": "⭐",
		"text": "",  # 動的に設定
		"color": Color(0.9, 0.75, 0.2),
		"duration": 6.0,
	},
	NotifyType.LANGUAGE_MILESTONE: {
		"icon": "🌱",
		"text": "",  # 動的に設定
		"color": Color(0.3, 0.8, 0.45),
		"duration": 6.0,
	},
}

## 状態
var _active_notifications: Dictionary = {}  # NotifyType → Label
var _cooldowns: Dictionary = {}             # NotifyType → float (time remaining)
var _check_timer: float = 0.0

const CHECK_INTERVAL: float = 5.0
const DISPLAY_DURATION: float = 4.0
const COOLDOWN_DURATION: float = 30.0  # 同じ通知の再表示まで30秒
const SLIDE_DURATION: float = 0.3

var _container: VBoxContainer
var _next_y_offset: float = 0.0
## 動的テキスト用: NotifyType → String のキー
var _dynamic_text_queue: Dictionary = {}

## AtoAイベント定期チェック用
var _a2a_check_timer: float = 0.0
const A2A_CHECK_INTERVAL: float = 5.0
var _last_known_conversation_count: int = 0
var _last_known_relationship_types: Dictionary = {}  # "petA_petB" → relationship_type
var _last_known_language_stage: int = -1


func _ready() -> void:
	set_anchors_preset(PRESET_TOP_WIDE)
	offset_top = 10
	offset_bottom = 200
	offset_left = 16
	offset_right = -16
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_container = VBoxContainer.new()
	_container.add_theme_constant_override("separation", 4)
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)

	# AtoA会話・言語エンジンのシグナルに接続（利用可能な場合のみ）
	_connect_external_signals.call_deferred()


func _process(delta: float) -> void:
	# クールダウン更新
	for key: int in _cooldowns.keys():
		_cooldowns[key] = maxf(0.0, _cooldowns[key] - delta)

	# ペットケアチェック間隔
	_check_timer += delta
	if _check_timer >= CHECK_INTERVAL:
		_check_timer = 0.0
		_check_pet_needs()

	# AtoAイベント定期ポーリング
	_a2a_check_timer += delta
	if _a2a_check_timer >= A2A_CHECK_INTERVAL:
		_a2a_check_timer = 0.0
		_poll_a2a_events()


func _check_pet_needs() -> void:
	if not GameManager.instance:
		return

	# 全ペットをチェック
	for pet_id: int in GameManager.instance.pets:
		var pet: PetEntity = GameManager.instance.pets[pet_id]
		if not pet or not pet.is_alive:
			continue

		# 空腹
		if pet.stats.hunger < 0.2:
			_show_notification(NotifyType.HUNGRY)

		# 体調
		if pet.stats.health < 0.25:
			_show_notification(NotifyType.LOW_HEALTH)

		# エネルギー
		if pet.stats.energy < 0.15:
			_show_notification(NotifyType.LOW_ENERGY)

		# 悲しみ
		if pet.emotions.get("sadness", 0.0) > 0.6:
			_show_notification(NotifyType.SAD)

		# 放置（愛情値の低下で判定）
		if pet.stats.affection < 0.15:
			_show_notification(NotifyType.LONELY)


func _show_notification(notify_type: NotifyType) -> void:
	# クールダウン中なら表示しない
	if _cooldowns.has(notify_type) and _cooldowns[notify_type] > 0.0:
		return
	# 既に表示中なら重複しない
	if _active_notifications.has(notify_type):
		return

	var data: Dictionary = NOTIFY_DATA[notify_type]
	_cooldowns[notify_type] = COOLDOWN_DURATION

	# 通知パネル作成
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(data["color"].r, data["color"].g, data["color"].b, 0.85)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var label: Label = Label.new()
	label.text = "%s %s" % [data["icon"], data["text"]]
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)

	# タッチ対応
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			notification_tapped.emit(NOTIFY_DATA[notify_type]["text"])
			_dismiss_notification(notify_type, panel)
	)

	_container.add_child(panel)
	_active_notifications[notify_type] = panel

	# スライドインアニメーション
	panel.modulate.a = 0.0
	panel.position.y = -30
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, SLIDE_DURATION)
	tween.tween_property(panel, "position:y", 0.0, SLIDE_DURATION).set_trans(Tween.TRANS_BACK)

	# 自動消去
	await get_tree().create_timer(DISPLAY_DURATION).timeout
	if _active_notifications.has(notify_type):
		_dismiss_notification(notify_type, panel)


func _dismiss_notification(notify_type: NotifyType, panel: PanelContainer) -> void:

	if not is_instance_valid(panel):
		_active_notifications.erase(notify_type)
		return

	_active_notifications.erase(notify_type)
	var tween: Tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(panel.queue_free)


## --- 外部シグナル接続 ---

func _connect_external_signals() -> void:
	if not GameManager.instance:
		return

	# AtoAConversationSystem の conversation_ended に接続
	var a2a_system: Node = _find_system_node("AtoAConversationSystem")
	if a2a_system:
		if a2a_system.has_signal("conversation_ended"):
			a2a_system.conversation_ended.connect(_on_conversation_ended)
		if a2a_system.has_signal("relationship_changed"):
			a2a_system.relationship_changed.connect(_on_relationship_changed)
		if a2a_system.has_signal("word_taught"):
			a2a_system.word_taught.connect(_on_word_taught)

	# OriginalLanguageEngine の word_invented に接続
	var lang_engine: Node = _find_system_node("OriginalLanguageEngine")
	if lang_engine:
		if lang_engine.has_signal("word_invented"):
			lang_engine.word_invented.connect(_on_word_invented)
		if lang_engine.has_signal("language_stage_advanced"):
			lang_engine.language_stage_advanced.connect(_on_language_stage_advanced)


func _find_system_node(class_name_str: String) -> Node:
	## GameManager の子ノードからシステムを探す
	if not GameManager.instance:
		return null
	for child: Node in GameManager.instance.get_children():
		if child.get_class() == class_name_str or child.get_script() != null:
			# class_name ベースのチェック
			if child is AtoAConversationSystem and class_name_str == "AtoAConversationSystem":
				return child
			if child is OriginalLanguageEngine and class_name_str == "OriginalLanguageEngine":
				return child
	return null


## --- AtoA 会話通知 ---

func _on_conversation_ended(participants: Array[int], _summary: String) -> void:
	if participants.size() < 2:
		return
	if not GameManager.instance:
		return

	var name_a: String = _get_pet_name(participants[0])
	var name_b: String = _get_pet_name(participants[1])
	var text: String = "%s just chatted with %s!" % [name_a, name_b]
	show_dynamic_notification(NotifyType.CONVERSATION, text)


func _get_pet_name(pet_id: int) -> String:
	if not GameManager.instance:
		return "Pet"
	if GameManager.instance.pets.has(pet_id):
		var pet: PetEntity = GameManager.instance.pets[pet_id]
		if pet:
			return pet.pet_name
	return "Pet"


## --- 言語新語通知 ---

func _on_word_invented(word_data: Dictionary) -> void:
	var ai_term: String = word_data.get("ai_term", "???")
	var text: String = "New word invented: %s!" % ai_term
	show_dynamic_notification(NotifyType.NEW_WORD, text)


## --- 動的テキスト通知（公開API） ---

## AtoA会話が発生したことを通知する
func notify_conversation(pet_name_a: String, pet_name_b: String) -> void:
	var text: String = "%s just chatted with %s!" % [pet_name_a, pet_name_b]
	show_dynamic_notification(NotifyType.CONVERSATION, text)


## 新しい単語が発明されたことを通知する
func notify_new_word(word: String) -> void:
	var text: String = "New word invented: %s!" % word
	show_dynamic_notification(NotifyType.NEW_WORD, text)


## 動的テキストを持つ通知を表示する
func show_dynamic_notification(notify_type: NotifyType, dynamic_text: String) -> void:
	# クールダウン中なら表示しない
	if _cooldowns.has(notify_type) and _cooldowns[notify_type] > 0.0:
		return
	# 既に表示中なら重複しない
	if _active_notifications.has(notify_type):
		return

	var data: Dictionary = NOTIFY_DATA[notify_type]
	_cooldowns[notify_type] = COOLDOWN_DURATION

	# 通知パネル作成
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(data["color"].r, data["color"].g, data["color"].b, 0.85)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var label: Label = Label.new()
	label.text = "%s %s" % [data["icon"], dynamic_text]
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)

	# タッチ対応
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			notification_tapped.emit(dynamic_text)
			_dismiss_notification(notify_type, panel)
	)

	_container.add_child(panel)
	_active_notifications[notify_type] = panel

	# スライドインアニメーション
	panel.modulate.a = 0.0
	panel.position.y = -30
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, SLIDE_DURATION)
	tween.tween_property(panel, "position:y", 0.0, SLIDE_DURATION).set_trans(Tween.TRANS_BACK)

	# 自動消去
	await get_tree().create_timer(DISPLAY_DURATION).timeout
	if _active_notifications.has(notify_type):
		_dismiss_notification(notify_type, panel)
