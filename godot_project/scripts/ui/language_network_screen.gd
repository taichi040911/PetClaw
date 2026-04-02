## LanguageNetworkScreen — 語彙伝播ネットワークの可視化
## ペット間の共有語彙・関係性をグラフ表示
class_name LanguageNetworkScreen
extends Control

signal back_requested

# === UI Theme ===
const BG_COLOR: Color = Color(0.06, 0.08, 0.14)
const PANEL_BG: Color = Color(0.10, 0.12, 0.20, 0.95)
const HEADER_COLOR: Color = Color(0.6, 0.85, 1.0)
const TEXT_COLOR: Color = Color(0.75, 0.78, 0.85)
const DIM_COLOR: Color = Color(0.4, 0.42, 0.5)
const HIGHLIGHT_COLOR: Color = Color(1.0, 0.95, 0.5)

# === Relationship Line Colors ===
const REL_COLORS: Dictionary = {
	"strangers": Color(0.35, 0.38, 0.45, 0.3),
	"acquaintances": Color(0.5, 0.55, 0.65, 0.5),
	"friends": Color(0.35, 0.8, 0.45, 0.8),
	"close_friends": Color(0.95, 0.78, 0.2, 0.9),
	"best_friends": Color(0.95, 0.78, 0.2, 1.0),
	"rivals": Color(0.9, 0.3, 0.3, 0.9),
}

# === Layout ===
const LAYOUT_RADIUS: float = 200.0
const NODE_MIN_RADIUS: float = 18.0
const NODE_MAX_RADIUS: float = 42.0
const LINE_MIN_WIDTH: float = 1.0
const LINE_MAX_WIDTH: float = 6.0

# === Stage Palettes (from PetVisualBridge) ===
const STAGE_PALETTES: Dictionary = {
	0: Color(0.95, 0.90, 0.80),
	1: Color(0.90, 0.65, 0.20),
	2: Color(0.45, 0.78, 0.72),
	3: Color(0.55, 0.70, 0.85),
	4: Color(0.80, 0.50, 0.55),
	5: Color(0.92, 0.82, 0.35),
}

# === State ===
var _pet_nodes: Array[Dictionary] = []  # [{pet_id, pet_name, stage, vocab_size, pos, radius}]
var _edges: Array[Dictionary] = []      # [{from_idx, to_idx, shared_count, rel_type, words}]
var _selected_pet_idx: int = -1         # -1 = no selection (show all)
var _graph_center: Vector2 = Vector2.ZERO

# === UI Nodes ===
var _bg: ColorRect
var _back_btn: Button
var _title_label: Label
var _stats_panel: VBoxContainer
var _stats_bg: ColorRect
var _graph_area: Control  # Custom draw node for the network


func _ready() -> void:
	_build_ui()
	_gather_data()
	_calculate_layout()
	_update_stats_panel()
	_graph_area.queue_redraw()


func _build_ui() -> void:
	# Full-screen dark background
	_bg = ColorRect.new()
	_bg.color = BG_COLOR
	_bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_bg)

	# Header row
	var header: HBoxContainer = HBoxContainer.new()
	header.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	header.offset_left = 12
	header.offset_right = -12
	header.offset_top = 10
	header.offset_bottom = 50
	header.add_theme_constant_override("separation", 12)
	add_child(header)

	_back_btn = Button.new()
	_back_btn.text = "< Back"
	_back_btn.pressed.connect(_on_back_pressed)
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
	_back_btn.add_theme_stylebox_override("normal", back_style)
	_back_btn.add_theme_color_override("font_color", TEXT_COLOR)
	header.add_child(_back_btn)

	_title_label = Label.new()
	_title_label.text = "Language Network"
	_title_label.add_theme_color_override("font_color", HEADER_COLOR)
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(_title_label)

	# Graph area (custom draw)
	_graph_area = Control.new()
	_graph_area.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_graph_area.offset_top = 55
	_graph_area.offset_right = -180
	_graph_area.offset_bottom = 0
	_graph_area.draw.connect(_on_graph_draw)
	_graph_area.gui_input.connect(_on_graph_input)
	_graph_area.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_graph_area)

	# Stats panel on right side
	_stats_bg = ColorRect.new()
	_stats_bg.color = PANEL_BG
	_stats_bg.anchor_left = 1.0
	_stats_bg.anchor_right = 1.0
	_stats_bg.anchor_top = 0.0
	_stats_bg.anchor_bottom = 1.0
	_stats_bg.offset_left = -175
	_stats_bg.offset_right = 0
	_stats_bg.offset_top = 55
	_stats_bg.offset_bottom = 0
	add_child(_stats_bg)

	_stats_panel = VBoxContainer.new()
	_stats_panel.anchor_left = 1.0
	_stats_panel.anchor_right = 1.0
	_stats_panel.anchor_top = 0.0
	_stats_panel.anchor_bottom = 1.0
	_stats_panel.offset_left = -170
	_stats_panel.offset_right = -5
	_stats_panel.offset_top = 60
	_stats_panel.offset_bottom = -10
	_stats_panel.add_theme_constant_override("separation", 8)
	add_child(_stats_panel)


func _gather_data() -> void:
	_pet_nodes.clear()
	_edges.clear()

	if not GameManager.instance:
		return

	var all_pets: Array = GameManager.instance.get_all_pets()
	if all_pets.is_empty():
		return

	# Gather per-pet vocabulary size from language engine
	var lang_engine: Node = GameManager.instance.original_language
	var vocab: Dictionary = {}
	if lang_engine and lang_engine.has_method("get_full_vocabulary"):
		vocab = lang_engine.get_full_vocabulary()

	# Build pet nodes
	for pet in all_pets:
		if not pet is PetEntity:
			continue
		var pe: PetEntity = pet as PetEntity
		if not pe.is_alive:
			continue
		# Count words this pet originated
		var pet_vocab_size: int = 0
		for word_key: String in vocab:
			var entry: Dictionary = vocab[word_key]
			if entry.get("origin_pet_id", -1) == pe.pet_id:
				pet_vocab_size += 1

		_pet_nodes.append({
			"pet_id": pe.pet_id,
			"pet_name": pe.pet_name,
			"stage": pe.evolution_stage,
			"vocab_size": pet_vocab_size,
			"pos": Vector2.ZERO,
			"radius": 0.0,
		})

	# Build edges from pet_relationships
	var a2a: Node = GameManager.instance.a2a_system
	if not a2a:
		return
	var relationships: Dictionary = a2a.pet_relationships

	for rel_key: String in relationships:
		var rel: Dictionary = relationships[rel_key]
		var parts: PackedStringArray = rel_key.split("_")
		if parts.size() < 2:
			continue
		var id_a: int = parts[0].to_int()
		var id_b: int = parts[1].to_int()
		var shared_words: Array = rel.get("shared_words", [])
		var rel_type: String = rel.get("relationship_type", "strangers")

		# Find indices
		var idx_a: int = -1
		var idx_b: int = -1
		for i: int in _pet_nodes.size():
			if _pet_nodes[i]["pet_id"] == id_a:
				idx_a = i
			if _pet_nodes[i]["pet_id"] == id_b:
				idx_b = i

		if idx_a >= 0 and idx_b >= 0 and not shared_words.is_empty():
			_edges.append({
				"from_idx": idx_a,
				"to_idx": idx_b,
				"shared_count": shared_words.size(),
				"rel_type": rel_type,
				"words": shared_words,
			})


func _calculate_layout() -> void:
	var count: int = _pet_nodes.size()
	if count == 0:
		return

	# Graph center in the graph_area
	var area_size: Vector2 = _graph_area.size
	if area_size == Vector2.ZERO:
		# Fallback: estimate from screen size
		area_size = get_viewport_rect().size
		area_size.x -= 180  # stats panel width
		area_size.y -= 55   # header height

	_graph_center = area_size * 0.5

	# Determine max vocab size for radius scaling
	var max_vocab: int = 1
	for node: Dictionary in _pet_nodes:
		max_vocab = maxi(max_vocab, node["vocab_size"] + 1)

	# Place pets in circle
	for i: int in count:
		var angle: float = (TAU * float(i) / float(count)) - PI / 2.0
		var effective_radius: float = LAYOUT_RADIUS
		if count == 1:
			effective_radius = 0.0
		_pet_nodes[i]["pos"] = _graph_center + Vector2(cos(angle), sin(angle)) * effective_radius

		# Radius based on vocab size
		var vocab_ratio: float = float(_pet_nodes[i]["vocab_size"] + 1) / float(max_vocab)
		_pet_nodes[i]["radius"] = lerpf(NODE_MIN_RADIUS, NODE_MAX_RADIUS, vocab_ratio)


func _on_graph_draw() -> void:
	var is_selecting: bool = _selected_pet_idx >= 0

	# Draw edges first (behind nodes)
	for edge: Dictionary in _edges:
		var from_node: Dictionary = _pet_nodes[edge["from_idx"]]
		var to_node: Dictionary = _pet_nodes[edge["to_idx"]]

		# Determine if this edge is highlighted
		var is_active: bool = true
		if is_selecting:
			is_active = edge["from_idx"] == _selected_pet_idx or edge["to_idx"] == _selected_pet_idx

		var rel_type: String = edge["rel_type"]
		var base_color: Color = REL_COLORS.get(rel_type, REL_COLORS["acquaintances"])

		if not is_active:
			base_color.a *= 0.15

		# Line width based on shared word count
		var shared: int = edge["shared_count"]
		var width: float = clampf(
			LINE_MIN_WIDTH + float(shared) * 0.8,
			LINE_MIN_WIDTH,
			LINE_MAX_WIDTH
		)

		_graph_area.draw_line(from_node["pos"], to_node["pos"], base_color, width, true)

		# Draw shared word count at midpoint
		if is_active and shared > 0:
			var mid: Vector2 = (from_node["pos"] + to_node["pos"]) * 0.5
			var count_text: String = str(shared)
			var font: Font = ThemeDB.fallback_font
			var font_size: int = 11
			var text_size: Vector2 = font.get_string_size(count_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			# Background pill
			var pill_rect: Rect2 = Rect2(
				mid - text_size * 0.5 - Vector2(4, 2),
				text_size + Vector2(8, 4)
			)
			_graph_area.draw_rect(pill_rect, Color(0.08, 0.10, 0.18, 0.85), true)
			_graph_area.draw_string(
				font, mid - Vector2(text_size.x * 0.5, -text_size.y * 0.3),
				count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
				base_color.lightened(0.3)
			)

	# Draw nodes
	for i: int in _pet_nodes.size():
		var node: Dictionary = _pet_nodes[i]
		var pos: Vector2 = node["pos"]
		var radius: float = node["radius"]
		var stage: int = node["stage"]

		# Determine opacity
		var is_active: bool = true
		if is_selecting and i != _selected_pet_idx:
			# Check if connected to selected
			is_active = false
			for edge: Dictionary in _edges:
				if (edge["from_idx"] == _selected_pet_idx and edge["to_idx"] == i) or \
					(edge["to_idx"] == _selected_pet_idx and edge["from_idx"] == i):
					is_active = true
					break

		var node_color: Color = STAGE_PALETTES.get(stage, STAGE_PALETTES[1])
		var alpha_mult: float = 1.0 if is_active else 0.2

		# Outer glow for selected
		if is_selecting and i == _selected_pet_idx:
			_graph_area.draw_circle(pos, radius + 6, Color(HIGHLIGHT_COLOR, 0.3))

		# Circle fill
		_graph_area.draw_circle(pos, radius, Color(node_color, 0.85 * alpha_mult))
		# Circle outline
		_graph_area.draw_arc(pos, radius, 0.0, TAU, 48, Color(node_color.lightened(0.4), alpha_mult), 2.0)

		# Pet name below
		var font: Font = ThemeDB.fallback_font
		var font_size: int = 12
		var name_text: String = node["pet_name"]
		var text_size: Vector2 = font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos: Vector2 = pos + Vector2(-text_size.x * 0.5, radius + 16)
		var name_color: Color = TEXT_COLOR if is_active else DIM_COLOR
		_graph_area.draw_string(font, text_pos, name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, name_color)

		# Vocab count inside circle
		var vocab_text: String = str(node["vocab_size"])
		var v_text_size: Vector2 = font.get_string_size(vocab_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
		_graph_area.draw_string(
			font, pos + Vector2(-v_text_size.x * 0.5, v_text_size.y * 0.3),
			vocab_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
			Color(1.0, 1.0, 1.0, 0.9 * alpha_mult)
		)

	# Empty state
	if _pet_nodes.is_empty():
		var font: Font = ThemeDB.fallback_font
		_graph_area.draw_string(
			font, _graph_center + Vector2(-80, 0),
			"No pets to display", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, DIM_COLOR
		)


func _on_graph_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return

	var click_pos: Vector2 = mb.position

	# Check if clicked on a pet node
	var clicked_idx: int = -1
	for i: int in _pet_nodes.size():
		var node: Dictionary = _pet_nodes[i]
		var dist: float = click_pos.distance_to(node["pos"])
		if dist <= node["radius"] + 4.0:
			clicked_idx = i
			break

	# Toggle selection
	if clicked_idx == _selected_pet_idx:
		_selected_pet_idx = -1  # Deselect
	else:
		_selected_pet_idx = clicked_idx

	_update_stats_panel()
	_graph_area.queue_redraw()


func _update_stats_panel() -> void:
	# Clear existing
	for child: Node in _stats_panel.get_children():
		child.queue_free()

	# Title
	_add_stat_header("Network Stats")

	# Total vocabulary
	var total_vocab: int = 0
	if GameManager.instance and GameManager.instance.original_language:
		var lang: Node = GameManager.instance.original_language
		if lang.has_method("get_full_vocabulary"):
			total_vocab = lang.get_full_vocabulary().size()
	_add_stat_row("Total Vocabulary", str(total_vocab))

	# Language stage
	if GameManager.instance and GameManager.instance.original_language:
		var lang: Node = GameManager.instance.original_language
		if lang.has_method("get_language_stage"):
			var stage_info: Dictionary = lang.get_language_stage()
			_add_stat_row("Language Stage", stage_info.get("name", "---"))

	# Most connected pet
	var best_pet_name: String = "---"
	var best_shared: int = 0
	var pet_shared_totals: Dictionary = {}  # pet_idx → total shared words

	for edge: Dictionary in _edges:
		var count: int = edge["shared_count"]
		var from_idx: int = edge["from_idx"]
		var to_idx: int = edge["to_idx"]
		pet_shared_totals[from_idx] = pet_shared_totals.get(from_idx, 0) + count
		pet_shared_totals[to_idx] = pet_shared_totals.get(to_idx, 0) + count

	for idx: int in pet_shared_totals:
		if pet_shared_totals[idx] > best_shared:
			best_shared = pet_shared_totals[idx]
			best_pet_name = _pet_nodes[idx]["pet_name"]

	_add_stat_row("Most Connected", best_pet_name)
	_add_stat_row("Shared Words", str(best_shared))

	# Most popular word (shared by most pets)
	var word_frequency: Dictionary = {}  # word → count of edges it appears in
	for edge: Dictionary in _edges:
		var words: Array = edge["words"]
		for word in words:
			word_frequency[word] = word_frequency.get(word, 0) + 1

	var popular_word: String = "---"
	var popular_count: int = 0
	for word: String in word_frequency:
		if word_frequency[word] > popular_count:
			popular_count = word_frequency[word]
			popular_word = word

	_add_stat_row("Most Shared Word", popular_word)

	# Separator
	var sep: HSeparator = HSeparator.new()
	sep.add_theme_color_override("separator", DIM_COLOR)
	_stats_panel.add_child(sep)

	# Pet count / edge count
	_add_stat_row("Pets", str(_pet_nodes.size()))
	_add_stat_row("Connections", str(_edges.size()))

	# Selected pet info
	if _selected_pet_idx >= 0 and _selected_pet_idx < _pet_nodes.size():
		var sep2: HSeparator = HSeparator.new()
		sep2.add_theme_color_override("separator", DIM_COLOR)
		_stats_panel.add_child(sep2)

		var selected: Dictionary = _pet_nodes[_selected_pet_idx]
		_add_stat_header(selected["pet_name"])
		_add_stat_row("Stage", str(selected["stage"]))
		_add_stat_row("Invented", str(selected["vocab_size"]))

		# List connections for this pet
		var connections: Array[String] = []
		for edge: Dictionary in _edges:
			if edge["from_idx"] == _selected_pet_idx:
				var other: Dictionary = _pet_nodes[edge["to_idx"]]
				connections.append("%s (%d)" % [other["pet_name"], edge["shared_count"]])
			elif edge["to_idx"] == _selected_pet_idx:
				var other: Dictionary = _pet_nodes[edge["from_idx"]]
				connections.append("%s (%d)" % [other["pet_name"], edge["shared_count"]])

		if not connections.is_empty():
			_add_stat_row("Links", "")
			for conn: String in connections:
				_add_stat_detail(conn)

	# Legend at bottom
	var sep3: HSeparator = HSeparator.new()
	sep3.add_theme_color_override("separator", DIM_COLOR)
	_stats_panel.add_child(sep3)
	_add_stat_header("Legend")
	_add_legend_row("Friends", REL_COLORS["friends"])
	_add_legend_row("Close Friends", REL_COLORS["close_friends"])
	_add_legend_row("Rivals", REL_COLORS["rivals"])

	# Tap hint
	var hint: Label = Label.new()
	hint.text = "Tap a pet to highlight"
	hint.add_theme_color_override("font_color", DIM_COLOR)
	hint.add_theme_font_size_override("font_size", 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_panel.add_child(hint)


func _add_stat_header(text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", HEADER_COLOR)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_stats_panel.add_child(lbl)


func _add_stat_row(label_text: String, value_text: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_stats_panel.add_child(row)

	var lbl: Label = Label.new()
	lbl.text = label_text
	lbl.add_theme_color_override("font_color", DIM_COLOR)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(lbl)

	var val: Label = Label.new()
	val.text = value_text
	val.add_theme_color_override("font_color", TEXT_COLOR)
	val.add_theme_font_size_override("font_size", 11)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val)


func _add_stat_detail(text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = "  %s" % text
	lbl.add_theme_color_override("font_color", TEXT_COLOR)
	lbl.add_theme_font_size_override("font_size", 10)
	_stats_panel.add_child(lbl)


func _add_legend_row(label_text: String, color: Color) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_stats_panel.add_child(row)

	var swatch: ColorRect = ColorRect.new()
	swatch.custom_minimum_size = Vector2(12, 12)
	swatch.color = color
	row.add_child(swatch)

	var lbl: Label = Label.new()
	lbl.text = label_text
	lbl.add_theme_color_override("font_color", TEXT_COLOR)
	lbl.add_theme_font_size_override("font_size", 10)
	row.add_child(lbl)


func _on_back_pressed() -> void:
	back_requested.emit()
