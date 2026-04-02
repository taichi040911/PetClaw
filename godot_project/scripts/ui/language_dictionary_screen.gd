## LanguageDictionaryScreen — 独自言語の完全辞書ブラウザ
## 全語彙のHebbian強度・カテゴリ・文法情報を一覧表示
class_name LanguageDictionaryScreen
extends Control

signal back_requested

# === Category Colors ===
const CATEGORY_COLORS: Dictionary = {
	"emotion": Color(0.9, 0.5, 0.6),
	"action": Color(0.5, 0.8, 0.5),
	"environment": Color(0.5, 0.7, 0.9),
	"relationship": Color(0.9, 0.75, 0.3),
	"verb": Color(0.7, 0.5, 0.9),
}
const DEFAULT_CATEGORY_COLOR: Color = Color(0.6, 0.65, 0.75)

# === UI Theme ===
const BG_COLOR: Color = Color(0.06, 0.08, 0.14)
const PANEL_BG: Color = Color(0.10, 0.12, 0.20, 0.95)
const HEADER_COLOR: Color = Color(0.6, 0.85, 1.0)
const TEXT_COLOR: Color = Color(0.75, 0.78, 0.85)
const DIM_COLOR: Color = Color(0.5, 0.55, 0.65)
const SECTION_COLOR: Color = Color(0.55, 0.6, 0.75)

# === UI Nodes ===
var _bg: ColorRect
var _vbox: VBoxContainer
var _search_edit: LineEdit
var _vocab_container: VBoxContainer
var _grammar_container: VBoxContainer
var _stage_label: Label
var _count_label: Label
var _scroll: ScrollContainer

# === Data Cache ===
var _cached_vocab: Dictionary = {}  # human_word → entry
var _filter_text: String = ""


func _ready() -> void:
	_build_ui()
	_populate_data()


func _build_ui() -> void:
	# Full-screen dark background
	_bg = ColorRect.new()
	_bg.color = BG_COLOR
	_bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_bg)

	# Root scroll
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 10)
	_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	_scroll.add_child(_vbox)

	# === Header Row ===
	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	_vbox.add_child(header_row)

	var back_btn: Button = Button.new()
	back_btn.text = "< Back"
	back_btn.pressed.connect(_on_back_pressed)
	var back_style: StyleBoxFlat = StyleBoxFlat.new()
	back_style.bg_color = Color(0.15, 0.18, 0.28)
	back_style.corner_radius_top_left = 8
	back_style.corner_radius_top_right = 8
	back_style.corner_radius_bottom_left = 8
	back_style.corner_radius_bottom_right = 8
	back_style.content_margin_left = 12
	back_style.content_margin_right = 12
	back_style.content_margin_top = 6
	back_style.content_margin_bottom = 6
	back_btn.add_theme_stylebox_override("normal", back_style)
	back_btn.add_theme_color_override("font_color", HEADER_COLOR)
	back_btn.add_theme_font_size_override("font_size", 13)
	header_row.add_child(back_btn)

	var title_label: Label = Label.new()
	title_label.text = "Language Dictionary"
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", HEADER_COLOR)
	title_label.size_flags_horizontal = SIZE_EXPAND_FILL
	header_row.add_child(title_label)

	# === Stage Info Row ===
	var info_row: HBoxContainer = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 16)
	_vbox.add_child(info_row)

	_stage_label = Label.new()
	_stage_label.text = "Stage: --"
	_stage_label.add_theme_font_size_override("font_size", 13)
	_stage_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9))
	info_row.add_child(_stage_label)

	_count_label = Label.new()
	_count_label.text = "0 words"
	_count_label.add_theme_font_size_override("font_size", 13)
	_count_label.add_theme_color_override("font_color", Color(0.5, 0.75, 0.5))
	info_row.add_child(_count_label)

	# === Search Bar ===
	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = "Filter by word or AI term..."
	_search_edit.text_changed.connect(_on_filter_changed)
	var search_style: StyleBoxFlat = StyleBoxFlat.new()
	search_style.bg_color = Color(0.12, 0.14, 0.22)
	search_style.corner_radius_top_left = 8
	search_style.corner_radius_top_right = 8
	search_style.corner_radius_bottom_left = 8
	search_style.corner_radius_bottom_right = 8
	search_style.content_margin_left = 10
	search_style.content_margin_right = 10
	search_style.content_margin_top = 6
	search_style.content_margin_bottom = 6
	search_style.border_width_bottom = 1
	search_style.border_color = Color(0.25, 0.3, 0.45)
	_search_edit.add_theme_stylebox_override("normal", search_style)
	_search_edit.add_theme_color_override("font_color", TEXT_COLOR)
	_search_edit.add_theme_color_override("font_placeholder_color", DIM_COLOR)
	_search_edit.add_theme_font_size_override("font_size", 13)
	_vbox.add_child(_search_edit)

	# === Vocabulary Section Header ===
	var vocab_header: Label = Label.new()
	vocab_header.text = "Vocabulary"
	vocab_header.add_theme_font_size_override("font_size", 14)
	vocab_header.add_theme_color_override("font_color", SECTION_COLOR)
	_vbox.add_child(vocab_header)

	# === Vocabulary List ===
	_vocab_container = VBoxContainer.new()
	_vocab_container.add_theme_constant_override("separation", 4)
	_vbox.add_child(_vocab_container)

	# === Grammar Section Header ===
	var grammar_header: Label = Label.new()
	grammar_header.text = "Grammar"
	grammar_header.add_theme_font_size_override("font_size", 14)
	grammar_header.add_theme_color_override("font_color", SECTION_COLOR)
	_vbox.add_child(grammar_header)

	# === Grammar Info ===
	_grammar_container = VBoxContainer.new()
	_grammar_container.add_theme_constant_override("separation", 4)
	_vbox.add_child(_grammar_container)


func _populate_data() -> void:
	_update_stage_info()
	_load_vocabulary()
	_render_vocabulary()
	_render_grammar()


func _update_stage_info() -> void:
	if not GameManager.instance or not GameManager.instance.original_language:
		return
	var stage: Dictionary = GameManager.instance.original_language.get_language_stage()
	_stage_label.text = "Stage %d: %s" % [stage["stage"] + 1, stage["name"]]
	_count_label.text = "%d words (%d archived)" % [stage["vocabulary_size"], stage["archived_size"]]


func _load_vocabulary() -> void:
	if not GameManager.instance or not GameManager.instance.original_language:
		return
	_cached_vocab = GameManager.instance.original_language.get_full_vocabulary()


func _render_vocabulary() -> void:
	# Clear existing entries
	for child: Node in _vocab_container.get_children():
		child.queue_free()

	if _cached_vocab.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No words invented yet. Talk to your pet!"
		empty_label.add_theme_font_size_override("font_size", 12)
		empty_label.add_theme_color_override("font_color", DIM_COLOR)
		_vocab_container.add_child(empty_label)
		return

	# Sort by strength descending
	var sorted_entries: Array[Dictionary] = []
	for human_word: String in _cached_vocab:
		var entry: Dictionary = _cached_vocab[human_word].duplicate()
		entry["_human_word"] = human_word
		sorted_entries.append(entry)

	sorted_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("strength", 0.0) > b.get("strength", 0.0)
	)

	var filter_lower: String = _filter_text.to_lower()
	var displayed: int = 0

	for entry: Dictionary in sorted_entries:
		var human_word: String = entry.get("_human_word", "")
		var ai_term: String = entry.get("ai_term", "???")

		# Apply filter
		if not filter_lower.is_empty():
			if not human_word.to_lower().contains(filter_lower) and not ai_term.to_lower().contains(filter_lower):
				continue

		_add_vocab_row(human_word, entry)
		displayed += 1

	if displayed == 0 and not filter_lower.is_empty():
		var no_match: Label = Label.new()
		no_match.text = "No matches for \"%s\"" % _filter_text
		no_match.add_theme_font_size_override("font_size", 12)
		no_match.add_theme_color_override("font_color", DIM_COLOR)
		_vocab_container.add_child(no_match)


func _add_vocab_row(human_word: String, entry: Dictionary) -> void:
	var row_panel: PanelContainer = PanelContainer.new()
	var row_style: StyleBoxFlat = StyleBoxFlat.new()
	row_style.bg_color = PANEL_BG
	row_style.corner_radius_top_left = 8
	row_style.corner_radius_top_right = 8
	row_style.corner_radius_bottom_left = 8
	row_style.corner_radius_bottom_right = 8
	row_style.content_margin_left = 10
	row_style.content_margin_right = 10
	row_style.content_margin_top = 6
	row_style.content_margin_bottom = 6
	row_panel.add_theme_stylebox_override("panel", row_style)
	_vocab_container.add_child(row_panel)

	var row_vbox: VBoxContainer = VBoxContainer.new()
	row_vbox.add_theme_constant_override("separation", 3)
	row_panel.add_child(row_vbox)

	# Top row: AI term + human word + strength bar
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	row_vbox.add_child(top_row)

	var ai_term: String = entry.get("ai_term", "???")
	var category: String = _classify_category(human_word, entry)
	var cat_color: Color = CATEGORY_COLORS.get(category, DEFAULT_CATEGORY_COLOR)

	var term_label: Label = Label.new()
	term_label.text = ai_term
	term_label.custom_minimum_size.x = 90
	term_label.add_theme_font_size_override("font_size", 14)
	term_label.add_theme_color_override("font_color", cat_color)
	top_row.add_child(term_label)

	var arrow_label: Label = Label.new()
	arrow_label.text = "="
	arrow_label.add_theme_font_size_override("font_size", 12)
	arrow_label.add_theme_color_override("font_color", DIM_COLOR)
	top_row.add_child(arrow_label)

	var human_label: Label = Label.new()
	human_label.text = human_word
	human_label.add_theme_font_size_override("font_size", 13)
	human_label.add_theme_color_override("font_color", TEXT_COLOR)
	human_label.size_flags_horizontal = SIZE_EXPAND_FILL
	top_row.add_child(human_label)

	# Strength ProgressBar
	var strength: float = entry.get("strength", 0.0)
	var strength_box: VBoxContainer = VBoxContainer.new()
	strength_box.custom_minimum_size.x = 60
	top_row.add_child(strength_box)

	var bar: ProgressBar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(60, 10)
	bar.max_value = 100.0
	bar.value = strength * 100.0
	bar.show_percentage = false
	var bar_bg: StyleBoxFlat = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.12, 0.14, 0.22)
	bar_bg.corner_radius_top_left = 4
	bar_bg.corner_radius_top_right = 4
	bar_bg.corner_radius_bottom_left = 4
	bar_bg.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bar_bg)
	var bar_fill: StyleBoxFlat = bar_bg.duplicate()
	var fill_color: Color = Color(0.3, 0.7, 0.4, 0.8) if strength > 0.5 else Color(0.6, 0.5, 0.3, 0.8)
	bar_fill.bg_color = fill_color
	bar.add_theme_stylebox_override("fill", bar_fill)
	strength_box.add_child(bar)

	var pct_label: Label = Label.new()
	pct_label.text = "%.0f%%" % (strength * 100.0)
	pct_label.add_theme_font_size_override("font_size", 9)
	pct_label.add_theme_color_override("font_color", DIM_COLOR)
	pct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	strength_box.add_child(pct_label)

	# Bottom row: category tag + context
	var bottom_row: HBoxContainer = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 8)
	row_vbox.add_child(bottom_row)

	# Category tag
	var tag_panel: PanelContainer = PanelContainer.new()
	var tag_style: StyleBoxFlat = StyleBoxFlat.new()
	tag_style.bg_color = Color(cat_color.r, cat_color.g, cat_color.b, 0.2)
	tag_style.corner_radius_top_left = 4
	tag_style.corner_radius_top_right = 4
	tag_style.corner_radius_bottom_left = 4
	tag_style.corner_radius_bottom_right = 4
	tag_style.content_margin_left = 6
	tag_style.content_margin_right = 6
	tag_style.content_margin_top = 2
	tag_style.content_margin_bottom = 2
	tag_panel.add_theme_stylebox_override("panel", tag_style)
	bottom_row.add_child(tag_panel)

	var tag_label: Label = Label.new()
	tag_label.text = category
	tag_label.add_theme_font_size_override("font_size", 10)
	tag_label.add_theme_color_override("font_color", cat_color)
	tag_panel.add_child(tag_label)

	# Origin context
	var origin_context: String = entry.get("origin_context", "")
	if not origin_context.is_empty() and origin_context != "unknown":
		var ctx_label: Label = Label.new()
		ctx_label.text = "First: %s" % origin_context.replace("_", " ")
		ctx_label.add_theme_font_size_override("font_size", 10)
		ctx_label.add_theme_color_override("font_color", DIM_COLOR)
		bottom_row.add_child(ctx_label)

	# Usage count
	var usage: int = entry.get("usage_count", 0)
	var usage_label: Label = Label.new()
	usage_label.text = "x%d" % usage
	usage_label.add_theme_font_size_override("font_size", 10)
	usage_label.add_theme_color_override("font_color", DIM_COLOR)
	bottom_row.add_child(usage_label)


func _classify_category(human_word: String, entry: Dictionary) -> String:
	## Derive a display category from the semantic_field and human_word
	var field: String = entry.get("semantic_field", "").to_lower()
	var word_lower: String = human_word.to_lower()

	# Check relationship first (field-based)
	if field.begins_with("relationship") or "friend" in word_lower or "love" in word_lower or "bond" in word_lower:
		return "relationship"

	# Emotion keywords
	var emotion_words: Array[String] = ["joy", "sad", "fear", "happy", "anger", "love", "excite", "calm"]
	for ew: String in emotion_words:
		if ew in field or ew in word_lower:
			return "emotion"

	# Environment
	var env_words: Array[String] = ["forest", "sea", "sky", "rain", "sun", "wind", "tree", "water", "fire", "earth", "mountain"]
	for ev: String in env_words:
		if ev in word_lower:
			return "environment"

	# Food / feeding = action
	if "food" in field or "feed" in word_lower or "eat" in word_lower:
		return "action"

	# Verb-like words
	var verb_words: Array[String] = ["run", "jump", "walk", "fly", "swim", "sing", "dance", "fight", "play", "sleep", "go", "come", "give", "take"]
	for vw: String in verb_words:
		if vw in word_lower:
			return "verb"

	# Freedom / general action
	if "free" in field or "freedom" in field:
		return "action"

	# Default based on semantic_field prefix
	if field.begins_with("general"):
		return "emotion"

	return "action"


func _render_grammar() -> void:
	for child: Node in _grammar_container.get_children():
		child.queue_free()

	if not GameManager.language_evolution:
		var no_grammar: Label = Label.new()
		no_grammar.text = "Grammar system not initialized."
		no_grammar.add_theme_font_size_override("font_size", 12)
		no_grammar.add_theme_color_override("font_color", DIM_COLOR)
		_grammar_container.add_child(no_grammar)
		return

	var grammar: Dictionary = GameManager.language_evolution.get_current_grammar()

	# Word Order
	_add_grammar_row("Word Order", grammar.get("word_order", "SVO"))

	# Active Suffixes
	var suffixes: Variant = grammar.get("suffixes", {})
	var suffix_counts: Dictionary = GameManager.language_evolution.suffix_usage_counts
	if suffixes is Dictionary:
		var suffix_panel: PanelContainer = PanelContainer.new()
		var sp_style: StyleBoxFlat = StyleBoxFlat.new()
		sp_style.bg_color = PANEL_BG
		sp_style.corner_radius_top_left = 8
		sp_style.corner_radius_top_right = 8
		sp_style.corner_radius_bottom_left = 8
		sp_style.corner_radius_bottom_right = 8
		sp_style.content_margin_left = 10
		sp_style.content_margin_right = 10
		sp_style.content_margin_top = 6
		sp_style.content_margin_bottom = 6
		suffix_panel.add_theme_stylebox_override("panel", sp_style)
		_grammar_container.add_child(suffix_panel)

		var suffix_vbox: VBoxContainer = VBoxContainer.new()
		suffix_vbox.add_theme_constant_override("separation", 3)
		suffix_panel.add_child(suffix_vbox)

		var suffix_title: Label = Label.new()
		suffix_title.text = "Active Suffixes"
		suffix_title.add_theme_font_size_override("font_size", 12)
		suffix_title.add_theme_color_override("font_color", Color(0.7, 0.9, 0.5))
		suffix_vbox.add_child(suffix_title)

		for context_key: String in suffixes:
			var suffix_str: String = str(suffixes[context_key])
			var count: int = int(suffix_counts.get(suffix_str, 0))
			var row: HBoxContainer = HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			suffix_vbox.add_child(row)

			var ctx_label: Label = Label.new()
			ctx_label.text = context_key
			ctx_label.custom_minimum_size.x = 80
			ctx_label.add_theme_font_size_override("font_size", 11)
			ctx_label.add_theme_color_override("font_color", DIM_COLOR)
			row.add_child(ctx_label)

			var sfx_label: Label = Label.new()
			sfx_label.text = suffix_str
			sfx_label.custom_minimum_size.x = 70
			sfx_label.add_theme_font_size_override("font_size", 11)
			sfx_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.6))
			row.add_child(sfx_label)

			var cnt_label: Label = Label.new()
			cnt_label.text = "x%d" % count
			cnt_label.add_theme_font_size_override("font_size", 10)
			cnt_label.add_theme_color_override("font_color", DIM_COLOR)
			row.add_child(cnt_label)

	# Prepositions
	var preps: Variant = grammar.get("prepositions", {})
	if preps is Dictionary and not preps.is_empty():
		var prep_panel: PanelContainer = PanelContainer.new()
		var pp_style: StyleBoxFlat = StyleBoxFlat.new()
		pp_style.bg_color = PANEL_BG
		pp_style.corner_radius_top_left = 8
		pp_style.corner_radius_top_right = 8
		pp_style.corner_radius_bottom_left = 8
		pp_style.corner_radius_bottom_right = 8
		pp_style.content_margin_left = 10
		pp_style.content_margin_right = 10
		pp_style.content_margin_top = 6
		pp_style.content_margin_bottom = 6
		prep_panel.add_theme_stylebox_override("panel", pp_style)
		_grammar_container.add_child(prep_panel)

		var prep_vbox: VBoxContainer = VBoxContainer.new()
		prep_vbox.add_theme_constant_override("separation", 3)
		prep_panel.add_child(prep_vbox)

		var prep_title: Label = Label.new()
		prep_title.text = "Prepositions"
		prep_title.add_theme_font_size_override("font_size", 12)
		prep_title.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
		prep_vbox.add_child(prep_title)

		for role: String in preps:
			var prep_str: String = str(preps[role])
			var row: HBoxContainer = HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			prep_vbox.add_child(row)

			var role_label: Label = Label.new()
			role_label.text = role
			role_label.custom_minimum_size.x = 80
			role_label.add_theme_font_size_override("font_size", 11)
			role_label.add_theme_color_override("font_color", DIM_COLOR)
			row.add_child(role_label)

			var val_label: Label = Label.new()
			val_label.text = prep_str
			val_label.add_theme_font_size_override("font_size", 11)
			val_label.add_theme_color_override("font_color", Color(0.65, 0.75, 0.9))
			row.add_child(val_label)


func _add_grammar_row(label_text: String, value_text: String) -> void:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	_grammar_container.add_child(panel)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	var lbl: Label = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 100
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", SECTION_COLOR)
	row.add_child(lbl)

	var val: Label = Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", 13)
	val.add_theme_color_override("font_color", TEXT_COLOR)
	row.add_child(val)


# === Callbacks ===

func _on_back_pressed() -> void:
	back_requested.emit()


func _on_filter_changed(new_text: String) -> void:
	_filter_text = new_text
	_render_vocabulary()
