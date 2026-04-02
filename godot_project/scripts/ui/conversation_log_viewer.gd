## ConversationLogViewer — AtoA会話ログをスクロール可能なUIで表示
## ペット同士の過去の会話を閲覧 + 言語進化状況を可視化 + 手動会話トリガー
class_name ConversationLogViewer
extends Control

signal back_requested
signal conversation_triggered  ## 手動会話トリガー時にMainSceneに通知

var _vbox: VBoxContainer
var _scroll: ScrollContainer
var _trigger_button: Button
var _status_label: Label
var _refresh_timer: float = 0.0


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	_build_ui()


func _process(delta: float) -> void:
	# ステータス表示を定期更新
	_refresh_timer += delta
	if _refresh_timer >= 2.0:
		_refresh_timer = 0.0
		_update_status()


func _build_ui() -> void:
	# 背景
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.12)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	# ヘッダー
	var header: HBoxContainer = HBoxContainer.new()
	header.set_anchors_preset(PRESET_TOP_WIDE)
	header.offset_bottom = 48
	header.offset_left = 8
	header.offset_right = -8
	add_child(header)

	var back_btn: Button = Button.new()
	back_btn.text = "< Back"
	back_btn.pressed.connect(func() -> void: back_requested.emit())
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.22, 0.32)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	back_btn.add_theme_stylebox_override("normal", btn_style)
	back_btn.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	header.add_child(back_btn)

	var title: Label = Label.new()
	title.text = "  💬 AtoA Conversations"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	header.add_child(title)

	# スクロールエリア
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_preset(PRESET_FULL_RECT)
	_scroll.offset_top = 52
	_scroll.offset_left = 8
	_scroll.offset_right = -8
	_scroll.offset_bottom = -8
	add_child(_scroll)

	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 12)
	_scroll.add_child(_vbox)

	# 言語進化ライブパネル（リアルタイム更新）
	var lang_panel: LanguageEvolutionPanel = LanguageEvolutionPanel.new()
	_vbox.add_child(lang_panel)

	# 会話トリガーボタン + ステータス
	_add_conversation_controls()

	# 会話ログを表示
	_add_conversation_log()


func _add_conversation_controls() -> void:
	var controls: HBoxContainer = HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 12)
	_vbox.add_child(controls)

	# トリガーボタン
	_trigger_button = Button.new()
	_trigger_button.text = "⚡ Trigger Conversation"
	_trigger_button.custom_minimum_size = Vector2(220, 48)
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.35, 0.55)
	btn_style.corner_radius_top_left = 12
	btn_style.corner_radius_top_right = 12
	btn_style.corner_radius_bottom_left = 12
	btn_style.corner_radius_bottom_right = 12
	_trigger_button.add_theme_stylebox_override("normal", btn_style)
	var btn_hover: StyleBoxFlat = btn_style.duplicate()
	btn_hover.bg_color = Color(0.25, 0.45, 0.7)
	_trigger_button.add_theme_stylebox_override("hover", btn_hover)
	var btn_pressed: StyleBoxFlat = btn_style.duplicate()
	btn_pressed.bg_color = Color(0.15, 0.25, 0.4)
	_trigger_button.add_theme_stylebox_override("pressed", btn_pressed)
	_trigger_button.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	_trigger_button.add_theme_font_size_override("font_size", 14)
	_trigger_button.pressed.connect(_on_trigger_pressed)
	controls.add_child(_trigger_button)

	# ステータスラベル
	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.75))
	controls.add_child(_status_label)
	_update_status()


func _on_trigger_pressed() -> void:
	if not GameManager.instance or not GameManager.instance.a2a_system:
		return

	var a2a: AtoAConversationSystem = GameManager.instance.a2a_system
	var status: Dictionary = a2a.get_conversation_status()

	if status["is_active"]:
		_trigger_button.text = "⏳ In progress..."
		_trigger_button.disabled = true
		return

	_trigger_button.text = "⏳ Starting..."
	_trigger_button.disabled = true
	conversation_triggered.emit()

	# 会話をトリガー
	a2a.trigger_conversation_now()

	# 少し待ってからUI更新
	await get_tree().create_timer(3.0).timeout
	_trigger_button.text = "⚡ Trigger Conversation"
	_trigger_button.disabled = false
	_update_status()
	# ログを再構築（新しい会話が追加されている可能性）
	_rebuild_log()


func _update_status() -> void:
	if not _status_label:
		return
	if not GameManager.instance or not GameManager.instance.a2a_system:
		_status_label.text = "System not ready"
		return

	var a2a: AtoAConversationSystem = GameManager.instance.a2a_system
	var status: Dictionary = a2a.get_conversation_status()

	var active_text: String = "🟢 Active" if status["is_active"] else "⚪ Idle"
	var compliance: float = status.get("avg_compliance", 0.0)
	var compliance_text: String = ""
	if compliance > 0.0:
		compliance_text = " | Lang: %.0f%%" % (compliance * 100.0)
	_status_label.text = "%s | $%.2f | %d/%d%s" % [
		active_text,
		status["budget_remaining"],
		status["daily_count"],
		status["max_daily"],
		compliance_text,
	]

	# 会話中はボタンを無効化
	if _trigger_button:
		_trigger_button.disabled = status["is_active"]
		if status["is_active"]:
			_trigger_button.text = "⏳ In progress..."
		else:
			_trigger_button.text = "⚡ Trigger Conversation"


func _rebuild_log() -> void:
	## 会話ログ部分のみ再構築（言語カードは維持）
	# _vboxの子を逆順にチェックし、会話ログ部分を削除
	var children: Array[Node] = []
	for child: Node in _vbox.get_children():
		children.append(child)

	# 最初の3つ（言語カード、コントロール、ログタイトル以降）を残し、ログ部分を削除
	var remove_start: int = 3  # language card + controls + (log section starts)
	for i: int in range(remove_start, children.size()):
		children[i].queue_free()

	# 少し待ってからログを再追加
	await get_tree().process_frame
	_add_conversation_log()


func _add_conversation_log() -> void:
	if not GameManager.instance or not GameManager.instance.a2a_system:
		var empty_label: Label = Label.new()
		empty_label.text = "No conversations yet. Pets will start talking when emotions run high!"
		empty_label.add_theme_font_size_override("font_size", 13)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_vbox.add_child(empty_label)
		return

	var log: Array = GameManager.instance.a2a_system.conversation_log
	if log.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No conversations yet.\n\nPets automatically start talking every 3 minutes when their emotions are strong enough (>40%).\n\nTry feeding, petting, or playing to increase emotions!"
		empty_label.add_theme_font_size_override("font_size", 12)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_vbox.add_child(empty_label)
		return

	# セクションタイトル
	var log_title: Label = Label.new()
	log_title.text = "📜 Recent Conversations (%d total)" % log.size()
	log_title.add_theme_font_size_override("font_size", 14)
	log_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85))
	_vbox.add_child(log_title)

	# 最新20件を逆順で表示
	var display_log: Array = log.slice(-20)
	display_log.reverse()

	for msg: Variant in display_log:
		if not msg is Dictionary:
			continue
		_add_message_bubble(msg as Dictionary)


func _add_message_bubble(msg: Dictionary) -> void:
	var pet_name: String = msg.get("pet_name", "???")
	var text: String = msg.get("message", "...")
	var emotion: String = msg.get("emotion", "neutral")
	var is_template: bool = msg.get("is_template", false)

	var bubble: PanelContainer = PanelContainer.new()
	var bubble_style: StyleBoxFlat = StyleBoxFlat.new()

	# 感情に応じた色
	var emotion_colors: Dictionary = {
		"joy": Color(0.15, 0.18, 0.1),
		"love": Color(0.18, 0.12, 0.15),
		"excitement": Color(0.18, 0.16, 0.08),
		"sadness": Color(0.1, 0.12, 0.18),
		"fear": Color(0.14, 0.1, 0.16),
		"neutral": Color(0.1, 0.11, 0.16),
	}
	bubble_style.bg_color = emotion_colors.get(emotion, Color(0.1, 0.11, 0.16))
	bubble_style.corner_radius_top_left = 10
	bubble_style.corner_radius_top_right = 10
	bubble_style.corner_radius_bottom_left = 10
	bubble_style.corner_radius_bottom_right = 10
	bubble_style.content_margin_left = 10
	bubble_style.content_margin_right = 10
	bubble_style.content_margin_top = 6
	bubble_style.content_margin_bottom = 6

	if is_template:
		bubble_style.border_width_left = 1
		bubble_style.border_color = Color(0.4, 0.35, 0.2, 0.3)

	bubble.add_theme_stylebox_override("panel", bubble_style)
	_vbox.add_child(bubble)

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	bubble.add_child(content)

	# ペット名 + 感情
	var emotion_icons: Dictionary = {
		"joy": "☀", "love": "♥", "excitement": "⚡",
		"sadness": "💧", "fear": "👁", "neutral": "·",
	}
	var header: Label = Label.new()
	var tag: String = ""
	if is_template:
		tag = " [T]"
	else:
		var compliance: Dictionary = msg.get("language_compliance", {})
		var score: float = compliance.get("score", -1.0)
		if score >= 0.0:
			tag = " [%.0f%%]" % (score * 100.0)
	header.text = "%s %s%s" % [emotion_icons.get(emotion, "·"), pet_name, tag]
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", Color(0.6, 0.65, 0.8))
	content.add_child(header)

	# メッセージ本文
	var body: Label = Label.new()
	body.text = text
	body.add_theme_font_size_override("font_size", 13)
	body.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	content.add_child(body)
