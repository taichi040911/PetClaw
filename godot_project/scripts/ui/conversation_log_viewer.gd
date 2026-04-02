## ConversationLogViewer — AtoA会話ログをスクロール可能なUIで表示
## ペット同士の過去の会話を閲覧 + 言語進化状況を可視化 + 手動会話トリガー
class_name ConversationLogViewer
extends Control

signal back_requested
signal conversation_triggered  ## 手動会話トリガー時にMainSceneに通知

var _vbox: VBoxContainer
var _scroll: ScrollContainer
var _trigger_button: Button
var _export_button: Button
var _status_label: Label
var _export_toast: Label
var _refresh_timer: float = 0.0
var _relationships_container: VBoxContainer
var _last_displayed_pet_name: String = ""


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

	# 関係性セクション（LanguageEvolutionPanelの後、コントロールの前）
	_relationships_container = VBoxContainer.new()
	_relationships_container.add_theme_constant_override("separation", 4)
	_vbox.add_child(_relationships_container)
	_rebuild_relationships()

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

	# エクスポートボタン
	_export_button = Button.new()
	_export_button.text = "📤 Export"
	_export_button.custom_minimum_size = Vector2(120, 48)
	var export_style: StyleBoxFlat = StyleBoxFlat.new()
	export_style.bg_color = Color(0.18, 0.15, 0.35)
	export_style.corner_radius_top_left = 12
	export_style.corner_radius_top_right = 12
	export_style.corner_radius_bottom_left = 12
	export_style.corner_radius_bottom_right = 12
	_export_button.add_theme_stylebox_override("normal", export_style)
	var export_hover: StyleBoxFlat = export_style.duplicate()
	export_hover.bg_color = Color(0.25, 0.2, 0.5)
	_export_button.add_theme_stylebox_override("hover", export_hover)
	var export_pressed: StyleBoxFlat = export_style.duplicate()
	export_pressed.bg_color = Color(0.12, 0.1, 0.25)
	_export_button.add_theme_stylebox_override("pressed", export_pressed)
	_export_button.add_theme_color_override("font_color", Color(0.85, 0.8, 1.0))
	_export_button.add_theme_font_size_override("font_size", 14)
	_export_button.pressed.connect(_on_export_pressed)
	controls.add_child(_export_button)

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
	## 会話ログ部分のみ再構築（言語カード・関係性・コントロールは維持）
	# _vboxの子を逆順にチェックし、会話ログ部分を削除
	var children: Array[Node] = []
	for child: Node in _vbox.get_children():
		children.append(child)

	# 最初の4つ（言語カード、関係性、コントロール、ログセクション以降）を残し、ログ部分を削除
	var remove_start: int = 4  # language card + relationships + controls + (log section starts)
	for i: int in range(remove_start, children.size()):
		children[i].queue_free()

	# 関係性セクションも更新
	_rebuild_relationships()

	# 少し待ってからログを再追加
	await get_tree().process_frame
	_add_conversation_log()

	# 自動スクロール: 新しい会話が追加された後に最下部へ
	await get_tree().process_frame
	if _scroll:
		_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


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

	_last_displayed_pet_name = ""
	for msg: Variant in display_log:
		if not msg is Dictionary:
			continue
		_add_message_bubble(msg as Dictionary)

	# 会話統計サマリー
	_add_conversation_stats(log)


func _add_message_bubble(msg: Dictionary) -> void:
	var pet_name: String = msg.get("pet_name", "???")
	var text: String = msg.get("message", "...")
	var emotion: String = msg.get("emotion", "neutral")
	var is_template: bool = msg.get("is_template", false)

	# 連続メッセージ間の関係性インジケーター（異なるペット同士）
	if not _last_displayed_pet_name.is_empty() and _last_displayed_pet_name != pet_name:
		var rel_indicator: Label = _build_relationship_indicator(_last_displayed_pet_name, pet_name)
		if rel_indicator:
			_vbox.add_child(rel_indicator)
	_last_displayed_pet_name = pet_name

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

	# ペット名 + 感情 + 創造語インジケーター
	var emotion_icons: Dictionary = {
		"joy": "☀", "love": "♥", "excitement": "⚡",
		"sadness": "💧", "fear": "👁", "neutral": "·",
	}
	var header: Label = Label.new()
	var tag: String = ""
	var compliance: Dictionary = msg.get("language_compliance", {})
	var has_invented_words: bool = false
	if is_template:
		tag = " [T]"
	else:
		var score: float = compliance.get("score", -1.0)
		if score >= 0.0:
			tag = " [%.0f%%]" % (score * 100.0)
	# 独自語彙が使われていればヘッダーに表示
	var checks: Dictionary = compliance.get("checks", {})
	if checks.get("uses_vocabulary", false):
		has_invented_words = true
		tag += " ✨"
	header.text = "%s %s%s" % [emotion_icons.get(emotion, "·"), pet_name, tag]
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", Color(0.6, 0.65, 0.8))
	content.add_child(header)

	# サマリー表示（存在する場合）
	var summary: String = msg.get("summary", "")
	if not summary.is_empty():
		var summary_label: Label = Label.new()
		summary_label.text = "📋 %s" % summary
		summary_label.add_theme_font_size_override("font_size", 10)
		summary_label.add_theme_color_override("font_color", Color(0.45, 0.5, 0.65))
		content.add_child(summary_label)

	# メッセージ本文（独自語彙使用時はプレフィックス付き）
	var body: Label = Label.new()
	if has_invented_words:
		body.text = "✨ %s" % text
	else:
		body.text = text
	body.add_theme_font_size_override("font_size", 13)
	body.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	content.add_child(body)

	# リアクション表示（R84で追加されるデータ）
	var reactions: Array = msg.get("reactions", [])
	if not reactions.is_empty():
		var reactions_text: String = ""
		for reaction: Variant in reactions:
			if reaction is Dictionary:
				var r: Dictionary = reaction
				reactions_text += "%s %s  " % [r.get("emoji", ""), r.get("reactor_name", "")]
		if not reactions_text.is_empty():
			var reactions_label: Label = Label.new()
			reactions_label.text = reactions_text.strip_edges()
			reactions_label.add_theme_font_size_override("font_size", 9)
			reactions_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
			content.add_child(reactions_label)

	# ワードティーチング表示
	var word_teaching: Variant = msg.get("word_teaching", {})
	if word_teaching is Dictionary and not (word_teaching as Dictionary).is_empty():
		var wt: Dictionary = word_teaching as Dictionary
		var wt_context: String = wt.get("teaching_context", "")
		if not wt_context.is_empty():
			var wt_label: Label = Label.new()
			wt_label.text = "📚 %s" % wt_context
			wt_label.add_theme_font_size_override("font_size", 9)
			wt_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.45))
			content.add_child(wt_label)


func _build_relationship_indicator(name_a: String, name_b: String) -> Label:
	## 連続メッセージ間の関係性を小さなテキストで表示
	if not GameManager.instance or not GameManager.instance.a2a_system:
		return null

	var relationships: Dictionary = GameManager.instance.a2a_system.pet_relationships
	if relationships.is_empty():
		return null

	# ペア名でキーを探す（sorted IDs で格納されているが、名前ベースで検索）
	var rel_type: String = "strangers"
	for key: String in relationships:
		var rel: Dictionary = relationships[key]
		var r_type: String = rel.get("relationship_type", "strangers")
		# キーからは名前が取れないのでpet_namesフィールドを確認
		var r_names: Array = rel.get("pet_names", [])
		if r_names.size() == 2:
			if (name_a in r_names and name_b in r_names):
				rel_type = r_type
				break

	var rel_icons: Dictionary = {
		"strangers": "⚪",
		"acquaintances": "🔵",
		"friends": "💚",
		"close_friends": "💛",
		"rivals": "🔴",
	}
	var icon: String = rel_icons.get(rel_type, "⚪")

	var indicator: Label = Label.new()
	indicator.text = "%s %s" % [icon, rel_type]
	indicator.add_theme_font_size_override("font_size", 9)
	indicator.add_theme_color_override("font_color", Color(0.4, 0.45, 0.55))
	indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return indicator


func _rebuild_relationships() -> void:
	## 関係性セクションを構築/再構築
	# 既存の子を削除
	for child: Node in _relationships_container.get_children():
		child.queue_free()

	if not GameManager.instance or not GameManager.instance.a2a_system:
		return

	var relationships: Dictionary = GameManager.instance.a2a_system.pet_relationships
	if relationships.is_empty():
		return

	# セクションヘッダー
	var rel_title: Label = Label.new()
	rel_title.text = "🤝 Relationships"
	rel_title.add_theme_font_size_override("font_size", 13)
	rel_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85))
	_relationships_container.add_child(rel_title)

	# 各関係性ペアを表示
	var rel_type_colors: Dictionary = {
		"strangers": Color(0.45, 0.45, 0.5),
		"acquaintances": Color(0.35, 0.5, 0.8),
		"friends": Color(0.35, 0.7, 0.4),
		"close_friends": Color(0.85, 0.75, 0.2),
		"rivals": Color(0.8, 0.3, 0.3),
	}

	for key: String in relationships:
		var rel: Dictionary = relationships[key]
		var rel_type: String = rel.get("relationship_type", "strangers")
		var affinity_val: float = clampf(rel.get("affinity", 0.0), 0.0, 1.0)
		var pet_names: Array = rel.get("pet_names", [])

		# ペア名を取得（pet_namesフィールドがなければキーから推定）
		var pair_label_text: String = ""
		if pet_names.size() == 2:
			pair_label_text = "%s & %s" % [str(pet_names[0]), str(pet_names[1])]
		else:
			pair_label_text = key

		# 行コンテナ
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_relationships_container.add_child(row)

		# ペア名
		var names_label: Label = Label.new()
		names_label.text = pair_label_text
		names_label.add_theme_font_size_override("font_size", 11)
		names_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8))
		names_label.custom_minimum_size = Vector2(120, 0)
		row.add_child(names_label)

		# 関係タイプバッジ
		var badge: PanelContainer = PanelContainer.new()
		var badge_style: StyleBoxFlat = StyleBoxFlat.new()
		var badge_color: Color = rel_type_colors.get(rel_type, Color(0.45, 0.45, 0.5))
		badge_style.bg_color = Color(badge_color.r, badge_color.g, badge_color.b, 0.25)
		badge_style.corner_radius_top_left = 6
		badge_style.corner_radius_top_right = 6
		badge_style.corner_radius_bottom_left = 6
		badge_style.corner_radius_bottom_right = 6
		badge_style.content_margin_left = 6
		badge_style.content_margin_right = 6
		badge_style.content_margin_top = 1
		badge_style.content_margin_bottom = 1
		badge.add_theme_stylebox_override("panel", badge_style)
		row.add_child(badge)

		var badge_label: Label = Label.new()
		badge_label.text = rel_type
		badge_label.add_theme_font_size_override("font_size", 10)
		badge_label.add_theme_color_override("font_color", badge_color)
		badge.add_child(badge_label)

		# 親密度ProgressBar
		var affinity_bar: ProgressBar = ProgressBar.new()
		affinity_bar.min_value = 0.0
		affinity_bar.max_value = 100.0
		affinity_bar.value = affinity_val * 100.0
		affinity_bar.custom_minimum_size = Vector2(80, 12)
		affinity_bar.show_percentage = false
		var bar_bg: StyleBoxFlat = StyleBoxFlat.new()
		bar_bg.bg_color = Color(0.1, 0.1, 0.15)
		bar_bg.corner_radius_top_left = 4
		bar_bg.corner_radius_top_right = 4
		bar_bg.corner_radius_bottom_left = 4
		bar_bg.corner_radius_bottom_right = 4
		affinity_bar.add_theme_stylebox_override("background", bar_bg)
		var bar_fill: StyleBoxFlat = StyleBoxFlat.new()
		bar_fill.bg_color = badge_color
		bar_fill.corner_radius_top_left = 4
		bar_fill.corner_radius_top_right = 4
		bar_fill.corner_radius_bottom_left = 4
		bar_fill.corner_radius_bottom_right = 4
		affinity_bar.add_theme_stylebox_override("fill", bar_fill)
		row.add_child(affinity_bar)

		# パーセント表示
		var pct_label: Label = Label.new()
		pct_label.text = "%.0f%%" % (affinity_val * 100.0)
		pct_label.add_theme_font_size_override("font_size", 10)
		pct_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
		row.add_child(pct_label)


func _add_conversation_stats(log: Array) -> void:
	## 会話統計サマリーを最下部に追加
	if log.is_empty():
		return

	var stats_panel: PanelContainer = PanelContainer.new()
	var stats_style: StyleBoxFlat = StyleBoxFlat.new()
	stats_style.bg_color = Color(0.07, 0.08, 0.12)
	stats_style.corner_radius_top_left = 8
	stats_style.corner_radius_top_right = 8
	stats_style.corner_radius_bottom_left = 8
	stats_style.corner_radius_bottom_right = 8
	stats_style.content_margin_left = 10
	stats_style.content_margin_right = 10
	stats_style.content_margin_top = 6
	stats_style.content_margin_bottom = 6
	stats_style.border_width_top = 1
	stats_style.border_color = Color(0.2, 0.22, 0.3, 0.4)
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	_vbox.add_child(stats_panel)

	var stats_vbox: VBoxContainer = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 2)
	stats_panel.add_child(stats_vbox)

	# 統計を計算
	var total_conversations: int = log.size()
	var total_vocab_uses: int = 0
	var pet_message_counts: Dictionary = {}
	var strongest_pair_key: String = ""
	var strongest_affinity: float = 0.0

	for entry: Variant in log:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry as Dictionary
		var pname: String = d.get("pet_name", "")
		if not pname.is_empty():
			pet_message_counts[pname] = pet_message_counts.get(pname, 0) + 1
		var comp: Dictionary = d.get("language_compliance", {})
		var comp_checks: Dictionary = comp.get("checks", {})
		if comp_checks.get("uses_vocabulary", false):
			total_vocab_uses += 1

	# 最もおしゃべりなペット
	var most_talkative: String = ""
	var max_messages: int = 0
	for pname: String in pet_message_counts:
		var count: int = pet_message_counts[pname]
		if count > max_messages:
			max_messages = count
			most_talkative = pname

	# 最強の関係性ペア
	if GameManager.instance and GameManager.instance.a2a_system:
		var relationships: Dictionary = GameManager.instance.a2a_system.pet_relationships
		for key: String in relationships:
			var rel: Dictionary = relationships[key]
			var aff: float = rel.get("affinity", 0.0)
			if aff > strongest_affinity:
				strongest_affinity = aff
				var names: Array = rel.get("pet_names", [])
				if names.size() == 2:
					strongest_pair_key = "%s & %s" % [str(names[0]), str(names[1])]
				else:
					strongest_pair_key = key

	# タイトル
	var stats_title: Label = Label.new()
	stats_title.text = "📊 Conversation Stats"
	stats_title.add_theme_font_size_override("font_size", 11)
	stats_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.75))
	stats_vbox.add_child(stats_title)

	# 統計テキスト
	var stats_lines: Array[String] = []
	stats_lines.append("Total messages: %d" % total_conversations)
	if total_vocab_uses > 0:
		stats_lines.append("Invented word uses: %d" % total_vocab_uses)
	if not most_talkative.is_empty():
		stats_lines.append("Most talkative: %s (%d msgs)" % [most_talkative, max_messages])
	if not strongest_pair_key.is_empty() and strongest_affinity > 0.0:
		stats_lines.append("Strongest bond: %s (%.0f%%)" % [strongest_pair_key, strongest_affinity * 100.0])

	var stats_body: Label = Label.new()
	stats_body.text = " | ".join(stats_lines)
	stats_body.add_theme_font_size_override("font_size", 10)
	stats_body.add_theme_color_override("font_color", Color(0.45, 0.5, 0.6))
	stats_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	stats_vbox.add_child(stats_body)


func _on_export_pressed() -> void:
	if not GameManager.instance or not GameManager.instance.a2a_system:
		_show_export_toast("No conversation data to export")
		return

	var log: Array = GameManager.instance.a2a_system.conversation_log
	if log.is_empty():
		_show_export_toast("No conversations to export")
		return

	var export_text: String = _build_export_text(log)

	# ファイルに書き出し
	var file: FileAccess = FileAccess.open("user://conversation_export.txt", FileAccess.WRITE)
	if not file:
		push_warning("ConversationLogViewer: Failed to open export file")
		_show_export_toast("Export failed — could not write file")
		return
	file.store_string(export_text)
	file.close()

	# Web環境ではクリップボードにもコピー
	if OS.get_name() == "Web":
		DisplayServer.clipboard_set(export_text)
		_show_export_toast("Exported & copied to clipboard!")
	else:
		_show_export_toast("Exported to conversation_export.txt")


func _build_export_text(log: Array) -> String:
	var lines: Array[String] = []
	lines.append("=== PetClaw Conversation Log ===")
	lines.append("Exported: %s" % Time.get_datetime_string_from_system(false, true))
	lines.append("")

	# 最新10件をエクスポート
	var export_log: Array = log.slice(-10)
	for entry: Variant in export_log:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry as Dictionary
		var pet_name: String = d.get("pet_name", "???")
		var emotion: String = d.get("emotion", "neutral")
		var message: String = d.get("message", "...")
		lines.append("[%s] (%s): %s" % [pet_name, emotion, message])

		# リアクション行
		var reactions: Array = d.get("reactions", [])
		if not reactions.is_empty():
			var reaction_parts: Array[String] = []
			for reaction: Variant in reactions:
				if reaction is Dictionary:
					var r: Dictionary = reaction
					reaction_parts.append("%s %s" % [r.get("emoji", ""), r.get("reactor_name", "")])
			if not reaction_parts.is_empty():
				lines.append("Reactions: %s" % ", ".join(reaction_parts))
		lines.append("")

	# フッター: 言語統計
	lines.append("---")
	var total_vocab_uses: int = 0
	for entry2: Variant in log:
		if not entry2 is Dictionary:
			continue
		var d2: Dictionary = entry2 as Dictionary
		var comp: Dictionary = d2.get("language_compliance", {})
		var checks: Dictionary = comp.get("checks", {})
		if checks.get("uses_vocabulary", false):
			total_vocab_uses += 1

	var stage: String = "unknown"
	if GameManager.instance and GameManager.instance.a2a_system:
		var a2a: AtoAConversationSystem = GameManager.instance.a2a_system
		var status: Dictionary = a2a.get_conversation_status()
		stage = "Day %d, %d conversations" % [status.get("daily_count", 0), log.size()]

	lines.append("Language stats: %d invented word uses | %s" % [total_vocab_uses, stage])
	lines.append("=== End of Log ===")

	return "\n".join(lines)


func _show_export_toast(message: String) -> void:
	# 既存トーストを削除
	if _export_toast and is_instance_valid(_export_toast):
		_export_toast.queue_free()

	_export_toast = Label.new()
	_export_toast.text = message
	_export_toast.add_theme_font_size_override("font_size", 12)
	_export_toast.add_theme_color_override("font_color", Color(0.9, 0.95, 0.8))
	_export_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_export_toast.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_export_toast.offset_top = -40
	_export_toast.offset_bottom = -12
	add_child(_export_toast)

	# 3秒後にフェードアウト・削除
	var tween: Tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(_export_toast, "modulate:a", 0.0, 1.0)
	tween.tween_callback(_export_toast.queue_free)
