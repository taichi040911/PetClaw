## TutorialOverlay — 初回プレイ用チュートリアル
## 基本操作を6ステップで段階的に案内する
## user://tutorial_done.flag が存在すればスキップ
class_name TutorialOverlay
extends Control

signal tutorial_completed

const FLAG_PATH: String = "user://tutorial_done.flag"
const OVERLAY_COLOR: Color = Color(0, 0, 0, 0.65)
const PANEL_BG: Color = Color(0.12, 0.14, 0.22, 0.95)
const PANEL_BORDER: Color = Color(0.4, 0.5, 0.8)
const TEXT_COLOR: Color = Color(0.9, 0.9, 1.0)
const ARROW_COLOR: Color = Color(1.0, 0.85, 0.3)

var _steps: Array[Dictionary] = [
	{"text": "Welcome to PetClaw!\nYour new pet is waiting for you.", "highlight": ""},
	{"text": "Feed your pet\nKeep hunger at bay with regular meals!", "highlight": "FeedButton"},
	{"text": "Pet to show affection\nTouch builds trust and happiness.", "highlight": "PetButton"},
	{"text": "Play to boost energy\nFun activities lift your pet's spirits!", "highlight": "PlayButton"},
	{"text": "Chat to see AI conversations\nYour pet talks with other pets!", "highlight": "ChatButton"},
	{"text": "Watch your pet's language evolve!\n22 forms await discovery.", "highlight": ""},
]

var _current_step: int = 0
var _overlay: ColorRect
var _text_label: Label
var _next_button: Button
var _skip_button: Button
var _arrow_label: Label


func _ready() -> void:
	if _flag_exists():
		tutorial_completed.emit()
		queue_free()
		return
	set_anchors_preset(PRESET_FULL_RECT)
	_build_ui()
	_show_step(0)


func _flag_exists() -> bool:
	return FileAccess.file_exists(FLAG_PATH)


func _write_flag() -> void:
	var file: FileAccess = FileAccess.open(FLAG_PATH, FileAccess.WRITE)
	if file:
		file.store_string("done")
		file.close()


func _build_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.color = OVERLAY_COLOR
	_overlay.set_anchors_preset(PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	_arrow_label = Label.new()
	_arrow_label.text = "▼"
	_arrow_label.add_theme_font_size_override("font_size", 28)
	_arrow_label.add_theme_color_override("font_color", ARROW_COLOR)
	_arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_arrow_label.visible = false
	_arrow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_arrow_label)

	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(PRESET_CENTER_BOTTOM)
	panel.offset_top = -200
	panel.offset_bottom = -40
	panel.offset_left = -280
	panel.offset_right = 280
	add_child(panel)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = PANEL_BORDER
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
	_text_label.add_theme_font_size_override("font_size", 18)
	_text_label.add_theme_color_override("font_color", TEXT_COLOR)
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
	_next_button.text = "Let's go!" if index == _steps.size() - 1 else "Next"
	_update_arrow(step["highlight"])
	_text_label.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(_text_label, "modulate:a", 1.0, 0.3)


func _update_arrow(highlight_name: String) -> void:
	if highlight_name.is_empty():
		_arrow_label.visible = false
		return
	var target: Control = _find_node_by_name(get_tree().root, highlight_name)
	if target == null:
		_arrow_label.visible = false
		return
	_arrow_label.visible = true
	var target_rect: Rect2 = target.get_global_rect()
	_arrow_label.global_position = Vector2(
		target_rect.position.x + target_rect.size.x * 0.5 - 14.0,
		target_rect.position.y - 36.0
	)


func _find_node_by_name(node: Node, target_name: String) -> Control:
	if node.name == target_name and node is Control:
		return node as Control
	for child: Node in node.get_children():
		var found: Control = _find_node_by_name(child, target_name)
		if found != null:
			return found
	return null


func _on_next() -> void:
	_show_step(_current_step + 1)


func _on_skip() -> void:
	_finish_tutorial()


func _finish_tutorial() -> void:
	_write_flag()
	tutorial_completed.emit()
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
