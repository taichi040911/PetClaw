## PetListScreen — ペット一覧・管理画面
## 所持ペットの一覧、ステータス確認、ペット切り替え
class_name PetListScreen
extends Control

signal pet_selected(pet_id: int)
signal back_requested

# === Constants ===
const STAGE_NAMES: Array[String] = ["Egg", "Baby", "Child", "Teen", "Adult", "Elder"]

const EMOTION_ICONS: Dictionary = {
	"joy": "☀",
	"love": "♥",
	"excitement": "⚡",
	"sadness": "💧",
	"fear": "👁",
	"neutral": "—",
}

const EMOTION_COLORS: Dictionary = {
	"joy": Color(1.0, 0.92, 0.3),
	"love": Color(1.0, 0.5, 0.6),
	"excitement": Color(1.0, 0.7, 0.15),
	"sadness": Color(0.5, 0.6, 0.85),
	"fear": Color(0.65, 0.5, 0.8),
	"neutral": Color(0.7, 0.75, 0.8),
}

const COLOR_BG: Color = Color(0.1, 0.11, 0.18)
const COLOR_CARD_BG: Color = Color(0.15, 0.17, 0.25)
const COLOR_CARD_BORDER: Color = Color(0.25, 0.3, 0.45)
const COLOR_CARD_ACTIVE_BORDER: Color = Color(0.4, 0.75, 0.95)
const COLOR_DEAD_CARD_BG: Color = Color(0.12, 0.12, 0.14)
const COLOR_DEAD_CARD_BORDER: Color = Color(0.2, 0.2, 0.22)
const COLOR_DEAD_TEXT: Color = Color(0.4, 0.4, 0.42)
const COLOR_DEAD_ICON: Color = Color(0.3, 0.3, 0.3)
const COLOR_ALIVE_ICON: Color = Color(0.4, 0.6, 0.8)
const COLOR_SUB_TEXT: Color = Color(0.6, 0.6, 0.7)
const COLOR_DEAD_LABEL: Color = Color(0.6, 0.4, 0.4)

# === State ===
var _vbox: VBoxContainer
var _pet_cards: Array[Control] = []
var _active_pet_id: int = -1


func _ready() -> void:
	_detect_active_pet()
	_build_ui()
	_populate_pet_list()


## Set the currently active pet id so the card can be highlighted
func set_active_pet_id(pet_id: int) -> void:
	_active_pet_id = pet_id


func _detect_active_pet() -> void:
	# Try to detect from MainScene's current_pet
	var main_scene: Node = get_tree().current_scene if get_tree() else null
	if main_scene and main_scene.has_method("get") and "current_pet" in main_scene:
		var pet: PetEntity = main_scene.get("current_pet")
		if pet:
			_active_pet_id = pet.pet_id


func _build_ui() -> void:
	# 背景
	var bg: ColorRect = ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	# ヘッダー
	var header: HBoxContainer = HBoxContainer.new()
	header.set_anchors_preset(PRESET_TOP_WIDE)
	header.offset_bottom = 50
	header.add_theme_constant_override("separation", 12)
	add_child(header)

	var back_btn: Button = Button.new()
	back_btn.text = "< Back"
	back_btn.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back_btn)

	var title: Label = Label.new()
	title.text = "My Pets"
	title.add_theme_font_size_override("font_size", 20)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	# ペット数カウンター
	var count_label: Label = Label.new()
	var alive_count: int = _count_alive_pets()
	var total_count: int = _count_total_pets()
	count_label.text = "%d/%d alive" % [alive_count, total_count]
	count_label.add_theme_font_size_override("font_size", 13)
	count_label.add_theme_color_override("font_color", COLOR_SUB_TEXT)
	header.add_child(count_label)

	# スクロール可能なペットリスト
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_preset(PRESET_TOP_WIDE)
	scroll.anchor_top = 0.06
	scroll.anchor_bottom = 1.0
	add_child(scroll)

	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(_vbox)


func _populate_pet_list() -> void:
	if not GameManager.instance:
		return

	# Alive pets first, then dead pets
	var alive_pets: Array[PetEntity] = []
	var dead_pets: Array[PetEntity] = []

	for pet_id: int in GameManager.instance.pets:
		var pet: PetEntity = GameManager.instance.pets[pet_id]
		if pet.is_alive:
			alive_pets.append(pet)
		else:
			dead_pets.append(pet)

	for pet: PetEntity in alive_pets:
		var card: PanelContainer = _create_pet_card(pet)
		_vbox.add_child(card)
		_pet_cards.append(card)

	# Dead pets section header (only if there are dead pets)
	if not dead_pets.is_empty():
		var separator: HSeparator = HSeparator.new()
		_vbox.add_child(separator)

		var memorial_label: Label = Label.new()
		memorial_label.text = "Memorial (%d)" % dead_pets.size()
		memorial_label.add_theme_font_size_override("font_size", 13)
		memorial_label.add_theme_color_override("font_color", COLOR_DEAD_TEXT)
		memorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_vbox.add_child(memorial_label)

		for pet: PetEntity in dead_pets:
			var card: PanelContainer = _create_pet_card(pet)
			_vbox.add_child(card)
			_pet_cards.append(card)

	if alive_pets.is_empty() and dead_pets.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No pets yet. Hatch an egg!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		_vbox.add_child(empty_label)


func _create_pet_card(pet: PetEntity) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	var is_active: bool = pet.pet_id == _active_pet_id and pet.is_alive

	if pet.is_alive:
		style.bg_color = COLOR_CARD_BG
		style.border_color = COLOR_CARD_ACTIVE_BORDER if is_active else COLOR_CARD_BORDER
		style.set_border_width_all(2 if is_active else 1)
	else:
		style.bg_color = COLOR_DEAD_CARD_BG
		style.border_color = COLOR_DEAD_CARD_BORDER
		style.set_border_width_all(1)

	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	# ペットアイコン（プレースホルダー）
	var icon: ColorRect = ColorRect.new()
	icon.custom_minimum_size = Vector2(56, 56)
	icon.color = COLOR_ALIVE_ICON if pet.is_alive else COLOR_DEAD_ICON
	hbox.add_child(icon)

	# 情報カラム
	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	# 名前行
	var name_row: HBoxContainer = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	info.add_child(name_row)

	var name_label: Label = Label.new()
	name_label.text = pet.pet_name
	name_label.add_theme_font_size_override("font_size", 16)
	if not pet.is_alive:
		name_label.add_theme_color_override("font_color", COLOR_DEAD_TEXT)
	name_row.add_child(name_label)

	if is_active:
		var active_tag: Label = Label.new()
		active_tag.text = "(active)"
		active_tag.add_theme_font_size_override("font_size", 12)
		active_tag.add_theme_color_override("font_color", COLOR_CARD_ACTIVE_BORDER)
		name_row.add_child(active_tag)

	# ステータス行: Stage | Condition | Age
	var stage_name: String = STAGE_NAMES[mini(pet.evolution_stage, 5)]
	var condition: String = pet.stats.get_overall_condition()

	var status_label: Label = Label.new()
	status_label.text = "%s | %s | Age: %.0fh" % [stage_name, condition, pet.age]
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", COLOR_DEAD_TEXT if not pet.is_alive else COLOR_SUB_TEXT)
	info.add_child(status_label)

	# 感情行（alive only）
	if pet.is_alive:
		var emotion_row: HBoxContainer = _create_emotion_row(pet)
		info.add_child(emotion_row)

	# 生死表示
	if not pet.is_alive:
		var dead_label: Label = Label.new()
		dead_label.text = "Passed away"
		dead_label.add_theme_font_size_override("font_size", 12)
		dead_label.add_theme_color_override("font_color", COLOR_DEAD_LABEL)
		info.add_child(dead_label)

	# 選択ボタン（alive only）
	if pet.is_alive:
		var select_btn: Button = Button.new()
		select_btn.text = "Active" if is_active else "Select"
		select_btn.disabled = is_active
		select_btn.custom_minimum_size = Vector2(70, 32)
		var captured_id: int = pet.pet_id
		select_btn.pressed.connect(func() -> void: pet_selected.emit(captured_id))
		hbox.add_child(select_btn)

	return panel


## Create the emotion display row for a pet
func _create_emotion_row(pet: PetEntity) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var dominant: String = _get_dominant_emotion(pet)
	var dominant_intensity: float = pet.emotions.get(dominant, 0.0) if dominant != "neutral" else 0.0

	# Dominant emotion with icon
	var emotion_icon: Label = Label.new()
	var icon_str: String = EMOTION_ICONS.get(dominant, "—")
	emotion_icon.text = icon_str
	emotion_icon.add_theme_font_size_override("font_size", 14)
	var emo_color: Color = EMOTION_COLORS.get(dominant, COLOR_SUB_TEXT)
	emotion_icon.add_theme_color_override("font_color", emo_color)
	row.add_child(emotion_icon)

	var emotion_text: Label = Label.new()
	if dominant == "neutral":
		emotion_text.text = "calm"
	else:
		var intensity_word: String = _intensity_label(dominant_intensity)
		emotion_text.text = "%s %s" % [intensity_word, dominant]
	emotion_text.add_theme_font_size_override("font_size", 11)
	emotion_text.add_theme_color_override("font_color", emo_color)
	row.add_child(emotion_text)

	# Secondary emotions as small tags
	var secondary: Array[String] = _get_secondary_emotions(pet, dominant)
	if not secondary.is_empty():
		var sep: Label = Label.new()
		sep.text = "|"
		sep.add_theme_font_size_override("font_size", 11)
		sep.add_theme_color_override("font_color", COLOR_SUB_TEXT)
		row.add_child(sep)

		for emo_name: String in secondary:
			var tag: Label = Label.new()
			var sec_icon: String = EMOTION_ICONS.get(emo_name, "")
			tag.text = "%s%s" % [sec_icon, emo_name]
			tag.add_theme_font_size_override("font_size", 10)
			var sec_color: Color = EMOTION_COLORS.get(emo_name, COLOR_SUB_TEXT)
			tag.add_theme_color_override("font_color", sec_color.lerp(COLOR_SUB_TEXT, 0.4))
			row.add_child(tag)

	return row


## Get the dominant emotion for a pet (highest intensity above threshold)
func _get_dominant_emotion(pet: PetEntity) -> String:
	var best_name: String = "neutral"
	var best_val: float = 0.15  # Threshold to count as "feeling" something
	for emo_name: String in pet.emotions:
		var val: float = pet.emotions[emo_name]
		if val > best_val:
			best_val = val
			best_name = emo_name
	return best_name


## Get secondary emotions above a lower threshold, excluding dominant
func _get_secondary_emotions(pet: PetEntity, dominant: String) -> Array[String]:
	var result: Array[String] = []
	const SECONDARY_THRESHOLD: float = 0.1
	for emo_name: String in pet.emotions:
		if emo_name == dominant:
			continue
		if pet.emotions[emo_name] > SECONDARY_THRESHOLD:
			result.append(emo_name)
	return result


## Convert intensity float to human-readable word
func _intensity_label(intensity: float) -> String:
	if intensity > 0.8:
		return "very"
	elif intensity > 0.5:
		return ""
	elif intensity > 0.3:
		return "slightly"
	else:
		return "faintly"


func _count_alive_pets() -> int:
	if not GameManager.instance:
		return 0
	var count: int = 0
	for pet_id: int in GameManager.instance.pets:
		var pet: PetEntity = GameManager.instance.pets[pet_id]
		if pet.is_alive:
			count += 1
	return count


func _count_total_pets() -> int:
	if not GameManager.instance:
		return 0
	return GameManager.instance.pets.size()
