## SettingsScreen — 設定画面
## 音量、APIキー設定、セーブデータ管理
class_name SettingsScreen
extends Control

signal back_requested

var _vbox: VBoxContainer


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.14)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_preset(PRESET_FULL_RECT)
	scroll.offset_top = 50
	scroll.offset_left = 20
	scroll.offset_right = -20
	add_child(scroll)

	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(_vbox)

	# ヘッダー
	var header: HBoxContainer = HBoxContainer.new()
	header.set_anchors_preset(PRESET_TOP_WIDE)
	header.offset_bottom = 48
	header.offset_left = 8
	add_child(header)

	var back_btn: Button = Button.new()
	back_btn.text = "< Back"
	back_btn.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back_btn)

	var title: Label = Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)

	# === 音量設定 ===
	_add_section_label("Audio")

	_add_slider_row("BGM Volume", 0.7, func(value: float) -> void:
		if GameManager.instance:
			# AudioManager 経由で設定
			pass
	)

	_add_slider_row("SFX Volume", 0.8, func(value: float) -> void:
		pass
	)

	# === API 設定 ===
	_add_section_label("Claude API")

	var api_row: HBoxContainer = HBoxContainer.new()
	_vbox.add_child(api_row)

	var api_label: Label = Label.new()
	api_label.text = "API Key:"
	api_label.custom_minimum_size = Vector2(100, 0)
	api_row.add_child(api_label)

	var api_input: LineEdit = LineEdit.new()
	api_input.placeholder_text = "sk-ant-..."
	api_input.secret = true
	api_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	api_row.add_child(api_input)

	var api_save_btn: Button = Button.new()
	api_save_btn.text = "Save"
	api_save_btn.pressed.connect(func() -> void:
		var key: String = api_input.text.strip_edges()
		if not key.is_empty():
			var file: FileAccess = FileAccess.open("user://api_key.txt", FileAccess.WRITE)
			if file:
				file.store_string(key)
				file.close()
				api_input.text = ""
				api_input.placeholder_text = "Saved!"
	)
	api_row.add_child(api_save_btn)

	# API ステータス
	var api_status: Label = Label.new()
	if OS.has_environment("ANTHROPIC_API_KEY") or FileAccess.file_exists("user://api_key.txt"):
		api_status.text = "API Key: Configured"
		api_status.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	else:
		api_status.text = "API Key: Not set (template mode)"
		api_status.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
	api_status.add_theme_font_size_override("font_size", 12)
	_vbox.add_child(api_status)

	# === セーブデータ ===
	_add_section_label("Save Data")

	var save_row: HBoxContainer = HBoxContainer.new()
	_vbox.add_child(save_row)

	var save_btn: Button = Button.new()
	save_btn.text = "Save Now"
	save_btn.pressed.connect(func() -> void:
		if GameManager.instance:
			GameManager.instance.save_game()
	)
	save_row.add_child(save_btn)

	var save_info: Label = Label.new()
	save_info.text = "Auto-save every 5 minutes"
	save_info.add_theme_font_size_override("font_size", 12)
	save_info.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	save_row.add_child(save_info)

	# === バージョン情報 ===
	_add_section_label("About")

	var version_label: Label = Label.new()
	version_label.text = "PetClaw v0.1.0 Alpha\nGodot 4.x | Claude API Powered"
	version_label.add_theme_font_size_override("font_size", 12)
	version_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	_vbox.add_child(version_label)


func _add_section_label(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	_vbox.add_child(label)

	var sep: HSeparator = HSeparator.new()
	_vbox.add_child(sep)


func _add_slider_row(label_text: String, default_value: float, callback: Callable) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	_vbox.add_child(row)

	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(120, 0)
	row.add_child(label)

	var slider: HSlider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = default_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(callback)
	row.add_child(slider)

	var value_label: Label = Label.new()
	value_label.text = "%d%%" % int(default_value * 100)
	value_label.custom_minimum_size = Vector2(40, 0)
	slider.value_changed.connect(func(v: float) -> void:
		value_label.text = "%d%%" % int(v * 100)
	)
	row.add_child(value_label)
