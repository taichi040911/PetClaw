## MainScene — メイン画面のUI制御とペット表示の統合
## GameManager（AutoLoad）が全サブシステムを管理し、
## このスクリプトはUI操作とペット表示の橋渡しを行う
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

# === Pet Reference ===
var current_pet: PetEntity
var pet_display_node: Node2D


func _ready() -> void:
	# ボタン接続
	feed_button.pressed.connect(_on_feed_pressed)
	pet_button.pressed.connect(_on_pet_pressed)
	play_button.pressed.connect(_on_play_pressed)

	# GameManager の初期化完了を待つ
	await get_tree().process_frame
	await get_tree().process_frame

	_setup_pet_display()


func _process(_delta: float) -> void:
	if current_pet and current_pet.is_alive:
		_update_ui()


func _setup_pet_display() -> void:
	# PetDisplay シーンからペットエンティティを取得
	pet_display_node = $PetArea/SubViewport/PetDisplay
	if not pet_display_node:
		push_warning("PetDisplay node not found")
		return

	var pet_node: Node = pet_display_node.get_node_or_null("PetEntity")
	if pet_node is PetEntity:
		current_pet = pet_node
	else:
		# GameManager からペットを取得（既存ペットがあれば）
		if GameManager.instance and GameManager.instance.pets.size() > 0:
			var first_id: int = GameManager.instance.pets.keys()[0]
			current_pet = GameManager.instance.pets[first_id]
		else:
			# 新しいペットを作成
			current_pet = pet_node as PetEntity
			if current_pet:
				current_pet.pet_name = "Mimi"

	if current_pet:
		pet_name_label.text = current_pet.pet_name
		# GameManager にペットを登録
		if GameManager.instance:
			GameManager.instance.register_pet(current_pet)

		# EmotionSystem シグナル接続
		current_pet.emotion_changed.connect(_on_emotion_changed)
		current_pet.stat_changed.connect(_on_stat_changed)


func _update_ui() -> void:
	if not current_pet:
		return

	# Stats バーの更新
	hunger_bar.value = current_pet.stats.hunger * 100.0
	health_bar.value = current_pet.stats.health * 100.0

	# 感情表示の更新
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

	# 満腹度を回復
	current_pet.stats.modify("hunger", 0.2)

	# 感情刺激: joy
	if GameManager.instance and GameManager.instance.emotion_system:
		GameManager.instance.emotion_system.stimulate(
			current_pet.pet_id, "joy", 0.3
		)

	# CareActionSystem 経由でも記録
	if GameManager.instance and GameManager.instance.care_system:
		GameManager.instance.care_system.perform_care(
			current_pet.pet_id, "feed"
		)


func _on_pet_pressed() -> void:
	if not current_pet or not current_pet.is_alive:
		return

	# 愛情を回復
	current_pet.stats.modify("affection", 0.15)

	# 感情刺激: love
	if GameManager.instance and GameManager.instance.emotion_system:
		GameManager.instance.emotion_system.stimulate(
			current_pet.pet_id, "love", 0.4
		)

	if GameManager.instance and GameManager.instance.care_system:
		GameManager.instance.care_system.perform_care(
			current_pet.pet_id, "pet"
		)


func _on_play_pressed() -> void:
	if not current_pet or not current_pet.is_alive:
		return

	# エネルギー消費 + 気分上昇
	current_pet.stats.modify("energy", -0.1)
	current_pet.stats.modify("mood", 0.2)

	# 感情刺激: excitement
	if GameManager.instance and GameManager.instance.emotion_system:
		GameManager.instance.emotion_system.stimulate(
			current_pet.pet_id, "excitement", 0.5
		)

	if GameManager.instance and GameManager.instance.care_system:
		GameManager.instance.care_system.perform_care(
			current_pet.pet_id, "play"
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
