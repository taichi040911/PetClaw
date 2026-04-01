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


func _ready() -> void:
	# ボタン接続
	feed_button.pressed.connect(_on_feed_pressed)
	pet_button.pressed.connect(_on_pet_pressed)
	play_button.pressed.connect(_on_play_pressed)
	petbook_button.pressed.connect(_on_petbook_pressed)

	# GameManager の初期化完了を待つ
	await get_tree().process_frame
	await get_tree().process_frame

	# セーブデータの有無で初回起動を判定
	if GameManager.instance and GameManager.instance.pets.size() == 0:
		_is_first_launch = true
		_show_egg_hatch()
	else:
		_setup_pet_display()

	# GameManager シグナル接続
	_connect_game_signals()


func _process(_delta: float) -> void:
	if current_pet and current_pet.is_alive:
		_update_ui()


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

	hunger_bar.value = current_pet.stats.hunger * 100.0
	health_bar.value = current_pet.stats.health * 100.0

	var dominant_emotion: String = _get_dominant_emotion()
	emotion_label.text = "Emotion: %s" % dominant_emotion


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
	emotion_label.text = "Emotion: %s (%.0f%%)" % [emotion, intensity * 100.0]


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
	if current_pet and current_pet.pet_id == pet_id:
		emotion_label.text = "Your pet has passed away..."
		feed_button.disabled = true
		pet_button.disabled = true
		play_button.disabled = true


# === Screen Navigation ===

func _on_petbook_pressed() -> void:
	if petbook_screen:
		return

	petbook_screen = _petbook_scene.instantiate() as PetBookScreen
	petbook_screen.back_requested.connect(_on_petbook_back)
	add_child(petbook_screen)

	$PetArea.visible = false
	$UIPanel.visible = false


func _on_petbook_back() -> void:
	if petbook_screen:
		petbook_screen.queue_free()
		petbook_screen = null

	$PetArea.visible = true
	$UIPanel.visible = true
