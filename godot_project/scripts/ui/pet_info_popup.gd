## PetInfoPopup — ペット名タップで表示される詳細ステータスポップアップ
## 全ステータス、性格、感情、年齢、進化段階を一覧表示
class_name PetInfoPopup
extends Control

signal closed

var _panel: PanelContainer
var _pet: PetEntity


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# 半透明オーバーレイ
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_close()
	)
	add_child(overlay)

	# パネル
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(PRESET_CENTER)
	_panel.offset_left = -160
	_panel.offset_right = 160
	_panel.offset_top = -220
	_panel.offset_bottom = 220
	add_child(_panel)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.2, 0.95)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.35, 0.5, 0.6)
	_panel.add_theme_stylebox_override("panel", style)

	# 出現アニメーション
	_panel.scale = Vector2(0.8, 0.8)
	_panel.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.15)


func setup(pet: PetEntity) -> void:
	_pet = pet
	_build_content()


func _build_content() -> void:
	if not _pet or not _panel:
		return

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(scroll)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	# === ペット名 ===
	var name_label: Label = Label.new()
	name_label.text = _pet.pet_name
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# === ステージ & 年齢 ===
	var stage_names: Array = ["Egg", "Baby", "Child", "Teen", "Adult", "Elder"]
	var stage_icons: Array = ["🥚", "🐣", "🐥", "🐾", "🐺", "👑"]
	var stage: int = clampi(_pet.evolution_stage, 0, 5)
	var age_text: String = "%.1fh" % _pet.age if _pet.age >= 1.0 else "%dm" % int(_pet.age * 60.0)

	_add_info_row(vbox, "Stage", "%s %s" % [stage_icons[stage], stage_names[stage]])
	_add_info_row(vbox, "Age", age_text)
	_add_info_row(vbox, "Condition", _pet.stats.get_overall_condition().capitalize())

	_add_separator(vbox)

	# === ステータス ===
	_add_section(vbox, "Stats")
	_add_stat_row(vbox, "🍖 Hunger", _pet.stats.hunger)
	_add_stat_row(vbox, "❤️ Health", _pet.stats.health)
	_add_stat_row(vbox, "⚡ Energy", _pet.stats.energy)
	_add_stat_row(vbox, "💗 Affection", _pet.stats.affection)
	_add_stat_row(vbox, "😊 Mood", _pet.stats.mood)

	_add_separator(vbox)

	# === 性格 ===
	_add_section(vbox, "Personality")
	var trait_icons: Dictionary = {
		"brave": "🗡", "curious": "🔍", "calm": "🌿",
		"affectionate": "💕", "playful": "⭐",
	}
	for trait_name: String in _pet.personality:
		var icon: String = trait_icons.get(trait_name, "·")
		_add_stat_row(vbox, "%s %s" % [icon, trait_name.capitalize()], _pet.personality[trait_name])

	_add_separator(vbox)

	# === 感情 ===
	_add_section(vbox, "Emotions")
	var emotion_icons: Dictionary = {
		"joy": "☀", "fear": "👁", "excitement": "⚡",
		"sadness": "💧", "love": "♥",
	}
	for emotion_name: String in _pet.emotions:
		var icon: String = emotion_icons.get(emotion_name, "·")
		_add_stat_row(vbox, "%s %s" % [icon, emotion_name.capitalize()], _pet.emotions[emotion_name])

	# === 閉じるボタン ===
	var close_btn: Button = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(_close)
	close_btn.custom_minimum_size = Vector2(0, 36)
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.25, 0.28, 0.4)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	close_btn.add_theme_stylebox_override("normal", btn_style)
	close_btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	vbox.add_child(close_btn)


func _add_section(parent: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.8))
	parent.add_child(label)


func _add_info_row(parent: VBoxContainer, key: String, value: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	parent.add_child(row)

	var key_label: Label = Label.new()
	key_label.text = key + ":"
	key_label.custom_minimum_size = Vector2(90, 0)
	key_label.add_theme_font_size_override("font_size", 12)
	key_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.7))
	row.add_child(key_label)

	var val_label: Label = Label.new()
	val_label.text = value
	val_label.add_theme_font_size_override("font_size", 12)
	val_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	row.add_child(val_label)


func _add_stat_row(parent: VBoxContainer, label_text: String, value: float) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	parent.add_child(row)

	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(120, 0)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	row.add_child(label)

	var bar: ProgressBar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(100, 14)
	bar.value = value * 100.0
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 値に応じた色
	var fill_color: Color
	if value > 0.7:
		fill_color = Color(0.4, 0.8, 0.45)
	elif value > 0.4:
		fill_color = Color(0.8, 0.75, 0.3)
	else:
		fill_color = Color(0.9, 0.4, 0.35)

	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.17, 0.25)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fill_style)
	row.add_child(bar)

	var pct: Label = Label.new()
	pct.text = "%d%%" % int(value * 100.0)
	pct.custom_minimum_size = Vector2(35, 0)
	pct.add_theme_font_size_override("font_size", 10)
	pct.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(pct)


func _add_separator(parent: VBoxContainer) -> void:
	var sep: HSeparator = HSeparator.new()
	parent.add_child(sep)


func _close() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "scale", Vector2(0.8, 0.8), 0.15)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.12)
	tween.chain().tween_callback(func() -> void:
		closed.emit()
		queue_free()
	)
