## PetListScreen — ペット一覧・管理画面
## 所持ペットの一覧、ステータス確認、ペット切り替え
class_name PetListScreen
extends Control

signal pet_selected(pet_id: int)
signal back_requested

var _vbox: VBoxContainer
var _pet_cards: Array[Control] = []


func _ready() -> void:
	_build_ui()
	_populate_pet_list()


func _build_ui() -> void:
	# 背景
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.1, 0.11, 0.18)
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

	for pet_id: int in GameManager.instance.pets:
		var pet: PetEntity = GameManager.instance.pets[pet_id]
		var card: PanelContainer = _create_pet_card(pet)
		_vbox.add_child(card)
		_pet_cards.append(card)

	if GameManager.instance.pets.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No pets yet. Hatch an egg!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		_vbox.add_child(empty_label)


func _create_pet_card(pet: PetEntity) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.17, 0.25)
	style.set_border_width_all(1)
	style.border_color = Color(0.25, 0.3, 0.45)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	# ペットアイコン（プレースホルダー）
	var icon: ColorRect = ColorRect.new()
	icon.custom_minimum_size = Vector2(56, 56)
	icon.color = Color(0.4, 0.6, 0.8) if pet.is_alive else Color(0.3, 0.3, 0.3)
	hbox.add_child(icon)

	# 情報
	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var name_label: Label = Label.new()
	name_label.text = pet.pet_name
	name_label.add_theme_font_size_override("font_size", 16)
	info.add_child(name_label)

	# ステータスサマリー
	var stage_names: Array[String] = ["Egg", "Baby", "Child", "Teen", "Adult", "Elder"]
	var stage_name: String = stage_names[mini(pet.evolution_stage, 5)]
	var condition: String = pet.stats.get_overall_condition()

	var status_label: Label = Label.new()
	status_label.text = "%s | %s | Age: %.0fh" % [stage_name, condition, pet.age]
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	info.add_child(status_label)

	# 生死表示
	if not pet.is_alive:
		var dead_label: Label = Label.new()
		dead_label.text = "Passed away"
		dead_label.add_theme_font_size_override("font_size", 12)
		dead_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4))
		info.add_child(dead_label)

	# 選択ボタン
	if pet.is_alive:
		var select_btn: Button = Button.new()
		select_btn.text = "Select"
		select_btn.custom_minimum_size = Vector2(70, 32)
		select_btn.pressed.connect(func() -> void: pet_selected.emit(pet.pet_id))
		hbox.add_child(select_btn)

	return panel
