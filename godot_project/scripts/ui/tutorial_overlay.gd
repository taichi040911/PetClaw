## TutorialOverlay — 初回プレイ用チュートリアル
## 卵孵化後に基本操作を段階的に案内する
class_name TutorialOverlay
extends Control

signal tutorial_completed

var _steps: Array[Dictionary] = [
	{
		"text": "Welcome to PetClaw!\nYour pet was just born. Let's take care of it!",
		"highlight": "",
	},
	{
		"text": "Tap 'Feed' to give your pet food.\nKeep the hunger bar full!",
		"highlight": "FeedButton",
	},
	{
		"text": "Tap 'Pet' to show love.\nYour pet's emotions will change!",
		"highlight": "PetButton",
	},
	{
		"text": "Tap 'Play' to have fun together.\nIt uses energy but boosts mood!",
		"highlight": "PlayButton",
	},
	{
		"text": "Open 'PetBook' to see your pet's social life.\nPets post and chat with each other!",
		"highlight": "PetBookButton",
	},
	{
		"text": "Take good care of your pet and it will evolve!\nThere are 22 different forms to discover.",
		"highlight": "",
	},
]

var _current_step: int = 0
var _overlay: ColorRect
var _text_label: Label
var _next_button: Button
var _skip_button: Button


func _ready() -> void:
	_build_ui()
	_show_step(0)


func _build_ui() -> void:
	# 半透明オーバーレイ
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.6)
	_overlay.set_anchors_preset(PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	# 中央のテキストパネル
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(PRESET_CENTER_BOTTOM)
	panel.offset_top = -200
	panel.offset_bottom = -40
	panel.offset_left = -280
	panel.offset_right = 280
	add_child(panel)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.22, 0.95)
	style.border_color = Color(0.4, 0.5, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label.add_theme_font_size_override("font_size", 16)
	_text_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	vbox.add_child(_text_label)

	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	_skip_button = Button.new()
	_skip_button.text = "Skip"
	_skip_button.custom_minimum_size = Vector2(80, 36)
	_skip_button.pressed.connect(_on_skip)
	btn_row.add_child(_skip_button)

	_next_button = Button.new()
	_next_button.text = "Next"
	_next_button.custom_minimum_size = Vector2(80, 36)
	_next_button.pressed.connect(_on_next)
	btn_row.add_child(_next_button)


func _show_step(index: int) -> void:
	if index >= _steps.size():
		_finish_tutorial()
		return

	_current_step = index
	var step: Dictionary = _steps[index]

	_text_label.text = step["text"]

	if index == _steps.size() - 1:
		_next_button.text = "Let's go!"
	else:
		_next_button.text = "Next"

	# 入場アニメーション
	_text_label.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(_text_label, "modulate:a", 1.0, 0.3)


func _on_next() -> void:
	_show_step(_current_step + 1)


func _on_skip() -> void:
	_finish_tutorial()


func _finish_tutorial() -> void:
	tutorial_completed.emit()
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
