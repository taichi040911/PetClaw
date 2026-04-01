## ConversationBubble — AtoA会話の吹き出し表示
## ペット同士の会話をリアルタイムで画面に表示する
class_name ConversationBubble
extends Control

signal conversation_display_finished

var _bubble_container: VBoxContainer
var _messages: Array[Dictionary] = []  # {pet_name, text, emotion, is_left}
var _current_index: int = 0
var _auto_advance_timer: float = 0.0
const AUTO_ADVANCE_DELAY: float = 3.0
const MAX_VISIBLE_MESSAGES: int = 4


func _ready() -> void:
	_build_ui()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build_ui() -> void:
	set_anchors_preset(PRESET_FULL_RECT)

	_bubble_container = VBoxContainer.new()
	_bubble_container.set_anchors_preset(PRESET_WIDE)
	_bubble_container.anchor_top = 0.05
	_bubble_container.anchor_bottom = 0.55
	_bubble_container.offset_left = 16
	_bubble_container.offset_right = -16
	_bubble_container.add_theme_constant_override("separation", 8)
	add_child(_bubble_container)


func show_conversation(messages: Array[Dictionary]) -> void:
	_messages = messages
	_current_index = 0
	_show_next_message()


func _process(delta: float) -> void:
	if _current_index > 0 and _current_index < _messages.size():
		_auto_advance_timer += delta
		if _auto_advance_timer >= AUTO_ADVANCE_DELAY:
			_auto_advance_timer = 0.0
			_show_next_message()


func _show_next_message() -> void:
	if _current_index >= _messages.size():
		# 会話終了 — フェードアウト
		var tween: Tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func() -> void:
			conversation_display_finished.emit()
			queue_free()
		)
		return

	var msg: Dictionary = _messages[_current_index]
	_current_index += 1
	_auto_advance_timer = 0.0

	# 古いメッセージを削除（MAX_VISIBLE_MESSAGES を超えたら）
	while _bubble_container.get_child_count() >= MAX_VISIBLE_MESSAGES:
		var oldest: Node = _bubble_container.get_child(0)
		_bubble_container.remove_child(oldest)
		oldest.queue_free()

	# 吹き出しを作成
	var is_left: bool = msg.get("is_left", true)
	var bubble: PanelContainer = _create_bubble(
		msg.get("pet_name", "???"),
		msg.get("text", "..."),
		msg.get("emotion", "neutral"),
		is_left
	)

	_bubble_container.add_child(bubble)

	# 入場アニメーション
	bubble.modulate.a = 0.0
	bubble.position.y += 20
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(bubble, "modulate:a", 1.0, 0.2)
	tween.tween_property(bubble, "position:y", bubble.position.y - 20, 0.2) \
		.set_ease(Tween.EASE_OUT)


func _create_bubble(pet_name: String, text: String, emotion: String, is_left: bool) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if is_left else Control.SIZE_SHRINK_END

	# 吹き出しスタイル
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.set_content_margin_all(10)
	style.set_corner_radius_all(12)

	# 感情に応じた色
	match emotion:
		"joy": style.bg_color = Color(0.2, 0.25, 0.15, 0.9)
		"love": style.bg_color = Color(0.25, 0.15, 0.2, 0.9)
		"sadness": style.bg_color = Color(0.15, 0.18, 0.25, 0.9)
		"fear": style.bg_color = Color(0.2, 0.15, 0.25, 0.9)
		"excitement": style.bg_color = Color(0.25, 0.22, 0.12, 0.9)
		_: style.bg_color = Color(0.18, 0.2, 0.25, 0.9)

	style.border_color = style.bg_color.lightened(0.3)
	style.set_border_width_all(1)

	panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	panel.add_child(vbox)

	# 名前
	var name_label: Label = Label.new()
	name_label.text = pet_name
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	vbox.add_child(name_label)

	# 会話テキスト
	var text_label: Label = Label.new()
	text_label.text = text
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(200, 0)
	text_label.add_theme_font_size_override("font_size", 14)
	text_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	vbox.add_child(text_label)

	return panel
