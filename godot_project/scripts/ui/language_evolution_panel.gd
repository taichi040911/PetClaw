## LanguageEvolutionPanel — 言語進化のリアルタイム可視化パネル
## 語彙成長・接尾辞使用・語順変化をライブ表示し、AtoAの革新性をショーケース
class_name LanguageEvolutionPanel
extends PanelContainer

# === UI References ===
var _vbox: VBoxContainer
var _word_flow: VBoxContainer       # 新語のライブフィード
var _suffix_bars: Dictionary = {}   # suffix → ProgressBar
var _stage_label: Label
var _word_order_label: Label
var _vocab_count_label: Label
var _event_log: VBoxContainer       # 進化イベントログ
var _max_events: int = 8

# === アニメーション ===
var _pending_animations: Array[Dictionary] = []


func _ready() -> void:
	_build_panel()
	_connect_signals()
	_populate_current_state()


func _process(_delta: float) -> void:
	# ペンディングアニメーションを処理
	if not _pending_animations.is_empty():
		var anim: Dictionary = _pending_animations.pop_front()
		_play_event_animation(anim)


func _build_panel() -> void:
	# パネルスタイル
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.1, 0.18, 0.95)
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.2, 0.3, 0.5, 0.6)
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	add_theme_stylebox_override("panel", panel_style)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 8)
	add_child(_vbox)

	# ── ヘッダー ──
	var header: Label = Label.new()
	header.text = "🧬 Language Evolution — LIVE"
	header.add_theme_font_size_override("font_size", 15)
	header.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	_vbox.add_child(header)

	# ── ステージ + 語順 + 語彙数 ──
	var info_row: HBoxContainer = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 16)
	_vbox.add_child(info_row)

	_stage_label = Label.new()
	_stage_label.add_theme_font_size_override("font_size", 12)
	_stage_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9))
	info_row.add_child(_stage_label)

	_word_order_label = Label.new()
	_word_order_label.add_theme_font_size_override("font_size", 12)
	_word_order_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.85))
	info_row.add_child(_word_order_label)

	_vocab_count_label = Label.new()
	_vocab_count_label.add_theme_font_size_override("font_size", 12)
	_vocab_count_label.add_theme_color_override("font_color", Color(0.5, 0.75, 0.5))
	info_row.add_child(_vocab_count_label)

	# ── 接尾辞使用バー ──
	var suffix_section: Label = Label.new()
	suffix_section.text = "Suffix Usage"
	suffix_section.add_theme_font_size_override("font_size", 11)
	suffix_section.add_theme_color_override("font_color", Color(0.55, 0.6, 0.75))
	_vbox.add_child(suffix_section)

	var suffix_container: VBoxContainer = VBoxContainer.new()
	suffix_container.add_theme_constant_override("separation", 3)
	_vbox.add_child(suffix_container)

	# 現在の接尾辞からバーを作成
	if GameManager.language_evolution:
		var grammar: Dictionary = GameManager.language_evolution.get_current_grammar()
		var suffixes: Variant = grammar.get("suffixes", {})
		if suffixes is Dictionary:
			for context_key: String in suffixes:
				var suffix_str: String = str(suffixes[context_key])
				_add_suffix_bar(suffix_container, suffix_str)
		elif suffixes is Array:
			for suffix_val: Variant in suffixes:
				_add_suffix_bar(suffix_container, str(suffix_val))

	# ── 進化イベントログ ──
	var event_section: Label = Label.new()
	event_section.text = "Recent Evolution Events"
	event_section.add_theme_font_size_override("font_size", 11)
	event_section.add_theme_color_override("font_color", Color(0.55, 0.6, 0.75))
	_vbox.add_child(event_section)

	_event_log = VBoxContainer.new()
	_event_log.add_theme_constant_override("separation", 4)
	_vbox.add_child(_event_log)

	# ── 語彙フロー（新語のライブ表示） ──
	var word_section: Label = Label.new()
	word_section.text = "Vocabulary"
	word_section.add_theme_font_size_override("font_size", 11)
	word_section.add_theme_color_override("font_color", Color(0.55, 0.6, 0.75))
	_vbox.add_child(word_section)

	_word_flow = VBoxContainer.new()
	_word_flow.add_theme_constant_override("separation", 2)
	_vbox.add_child(_word_flow)


func _add_suffix_bar(container: VBoxContainer, suffix_str: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	container.add_child(row)

	var name_label: Label = Label.new()
	name_label.text = suffix_str
	name_label.custom_minimum_size.x = 60
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.6))
	row.add_child(name_label)

	var bar: ProgressBar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(120, 12)
	bar.max_value = 100.0
	bar.value = 0.0
	bar.show_percentage = false
	var bar_style: StyleBoxFlat = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.12, 0.14, 0.22)
	bar_style.corner_radius_top_left = 4
	bar_style.corner_radius_top_right = 4
	bar_style.corner_radius_bottom_left = 4
	bar_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bar_style)
	var fill_style: StyleBoxFlat = bar_style.duplicate()
	fill_style.bg_color = Color(0.3, 0.6, 0.4, 0.8)
	bar.add_theme_stylebox_override("fill", fill_style)
	row.add_child(bar)

	var count_label: Label = Label.new()
	count_label.text = "0"
	count_label.add_theme_font_size_override("font_size", 10)
	count_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	row.add_child(count_label)

	_suffix_bars[suffix_str] = {"bar": bar, "label": count_label}


func _connect_signals() -> void:
	if GameManager.language_evolution:
		var le: Node = GameManager.language_evolution
		if le.has_signal("word_order_changed"):
			le.word_order_changed.connect(_on_word_order_changed)
		if le.has_signal("suffix_created"):
			le.suffix_created.connect(_on_suffix_created)
		if le.has_signal("grammar_milestone"):
			le.grammar_milestone.connect(_on_grammar_milestone)
		if le.has_signal("evolution_event"):
			le.evolution_event.connect(_on_evolution_event)

	if GameManager.instance and GameManager.instance.original_language:
		var ol: Node = GameManager.instance.original_language
		if ol.has_signal("word_invented"):
			ol.word_invented.connect(_on_word_invented)
		if ol.has_signal("word_strengthened"):
			ol.word_strengthened.connect(_on_word_strengthened)
		if ol.has_signal("word_forgotten"):
			ol.word_forgotten.connect(_on_word_forgotten)
		if ol.has_signal("language_stage_advanced"):
			ol.language_stage_advanced.connect(_on_stage_advanced)


func _populate_current_state() -> void:
	# 現在の言語状態を表示
	if GameManager.instance and GameManager.instance.original_language:
		var stage: Dictionary = GameManager.instance.original_language.get_language_stage()
		_stage_label.text = "Stage %d: %s" % [stage["stage"] + 1, stage["name"]]
		_vocab_count_label.text = "%d words" % stage["vocabulary_size"]

		# 語彙一覧を表示
		var vocab: Dictionary = GameManager.instance.original_language.get_full_vocabulary()
		var sorted_words: Array = []
		for key: String in vocab:
			var entry: Dictionary = vocab[key]
			sorted_words.append(entry)
		sorted_words.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return a.get("strength", 0.0) > b.get("strength", 0.0)
		)
		for entry: Dictionary in sorted_words.slice(0, 12):
			_add_vocab_entry(entry)

	if GameManager.language_evolution:
		var grammar: Dictionary = GameManager.language_evolution.get_current_grammar()
		_word_order_label.text = "Order: %s" % grammar["word_order"]

		# 接尾辞使用カウントを更新
		_update_suffix_bars()


func _update_suffix_bars() -> void:
	if not GameManager.language_evolution:
		return
	var counts: Dictionary = GameManager.language_evolution.suffix_usage_counts
	var max_count: int = 1
	for s: String in counts:
		max_count = maxi(max_count, int(counts[s]))

	for suffix_str: String in _suffix_bars:
		var data: Dictionary = _suffix_bars[suffix_str]
		var count: int = int(counts.get(suffix_str, 0))
		var bar: ProgressBar = data["bar"]
		var label: Label = data["label"]
		bar.value = (float(count) / float(max_count)) * 100.0
		label.text = str(count)


func _add_vocab_entry(entry: Dictionary) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_word_flow.add_child(row)

	var term_label: Label = Label.new()
	term_label.text = entry.get("ai_term", "???")
	term_label.custom_minimum_size.x = 70
	term_label.add_theme_font_size_override("font_size", 11)
	term_label.add_theme_color_override("font_color", Color(0.8, 0.7, 1.0))
	row.add_child(term_label)

	var meaning_label: Label = Label.new()
	meaning_label.text = "= %s" % entry.get("human_word", "?")
	meaning_label.add_theme_font_size_override("font_size", 10)
	meaning_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	row.add_child(meaning_label)

	var strength_label: Label = Label.new()
	var strength: float = entry.get("strength", 0.0)
	strength_label.text = "%.0f%%" % (strength * 100.0)
	strength_label.add_theme_font_size_override("font_size", 10)
	var strength_color: Color = Color(0.4, 0.7, 0.4) if strength > 0.5 else Color(0.6, 0.5, 0.3)
	strength_label.add_theme_color_override("font_color", strength_color)
	row.add_child(strength_label)


# === Signal Handlers ===

func _on_word_invented(word_data: Dictionary) -> void:
	_add_event("✨ NEW WORD: %s = '%s'" % [
		word_data.get("ai_term", "???"),
		word_data.get("human_word", "???"),
	], Color(0.8, 0.7, 1.0))
	_add_vocab_entry(word_data)
	_update_vocab_count()


func _on_word_strengthened(ai_term: String, new_strength: float) -> void:
	# 語彙リストを更新（該当エントリの強度を更新）
	for child: Node in _word_flow.get_children():
		if child is HBoxContainer:
			var labels: Array[Node] = child.get_children()
			if labels.size() >= 3:
				var term_lbl: Label = labels[0] as Label
				if term_lbl and term_lbl.text == ai_term:
					var str_lbl: Label = labels[2] as Label
					if str_lbl:
						str_lbl.text = "%.0f%%" % (new_strength * 100.0)
						# 強化アニメーション（一瞬明るくする）
						str_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
						var tween: Tween = create_tween()
						tween.tween_callback(func() -> void:
							var c: Color = Color(0.4, 0.7, 0.4) if new_strength > 0.5 else Color(0.6, 0.5, 0.3)
							str_lbl.add_theme_color_override("font_color", c)
						).set_delay(0.8)
					break


func _on_word_forgotten(ai_term: String) -> void:
	_add_event("💀 FORGOTTEN: %s" % ai_term, Color(0.6, 0.4, 0.4))
	# 語彙リストから削除
	for child: Node in _word_flow.get_children():
		if child is HBoxContainer:
			var labels: Array[Node] = child.get_children()
			if labels.size() >= 1:
				var term_lbl: Label = labels[0] as Label
				if term_lbl and term_lbl.text == ai_term:
					child.queue_free()
					break
	_update_vocab_count()


func _on_stage_advanced(new_stage: int, stage_name: String) -> void:
	_stage_label.text = "Stage %d: %s" % [new_stage + 1, stage_name]
	_add_event("🎉 STAGE UP: %s (Stage %d)" % [stage_name, new_stage + 1], Color(1.0, 0.85, 0.3))


func _on_word_order_changed(old_order: String, new_order: String, reason: String) -> void:
	_word_order_label.text = "Order: %s" % new_order
	_add_event("📐 WORD ORDER: %s → %s (%s)" % [old_order, new_order, reason], Color(0.5, 0.8, 1.0))


func _on_suffix_created(suffix: String, _context: String, reason: String) -> void:
	_add_event("🔤 NEW SUFFIX: %s (%s)" % [suffix, reason], Color(0.7, 0.9, 0.5))
	# バーを追加（親コンテナを探す）
	for child: Node in _vbox.get_children():
		if child is VBoxContainer and child != _event_log and child != _word_flow:
			_add_suffix_bar(child, suffix)
			break


func _on_grammar_milestone(milestone_name: String, _details: Dictionary) -> void:
	_add_event("🏆 MILESTONE: %s" % milestone_name, Color(1.0, 0.8, 0.3))


func _on_evolution_event(event_type: String, data: Dictionary) -> void:
	_add_event("🧬 %s: %s" % [event_type, str(data).substr(0, 60)], Color(0.6, 0.7, 0.9))
	_update_suffix_bars()


func _add_event(text: String, color: Color) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD

	# 先頭に追加（最新が上）
	_event_log.add_child(label)
	_event_log.move_child(label, 0)

	# 古いイベントを削除
	while _event_log.get_child_count() > _max_events:
		var old: Node = _event_log.get_child(_event_log.get_child_count() - 1)
		old.queue_free()

	# フェードインアニメーション
	label.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.4)


func _update_vocab_count() -> void:
	if GameManager.instance and GameManager.instance.original_language:
		var stage: Dictionary = GameManager.instance.original_language.get_language_stage()
		_vocab_count_label.text = "%d words" % stage["vocabulary_size"]


func _play_event_animation(anim: Dictionary) -> void:
	# 将来の拡張用（パーティクルやフラッシュ）
	pass
