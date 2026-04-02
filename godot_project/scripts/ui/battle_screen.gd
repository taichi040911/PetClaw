## BattleScreen — ペット同士の言語バトルUI画面
## LanguageBattleSystemと連携し、3ラウンド制ワードデュエルを表示
class_name BattleScreen
extends Control

signal back_requested
signal battle_complete(winner_id: int)

# === UI Theme (dark, matching other screens) ===
const BG_COLOR: Color = Color(0.06, 0.08, 0.14)
const PANEL_COLOR: Color = Color(0.10, 0.12, 0.20, 0.95)
const ACCENT_COLOR: Color = Color(0.85, 0.45, 0.35)
const HEADER_COLOR: Color = Color(0.95, 0.75, 0.3)
const TEXT_COLOR: Color = Color(0.85, 0.88, 0.92)
const MUTED_COLOR: Color = Color(0.5, 0.55, 0.65)
const WIN_COLOR: Color = Color(0.4, 0.9, 0.5)
const LOSE_COLOR: Color = Color(0.9, 0.4, 0.4)
const CARD_BG: Color = Color(0.12, 0.14, 0.24, 0.9)
const SCORE_VOCAB_COLOR: Color = Color(0.4, 0.75, 0.95)
const SCORE_GRAMMAR_COLOR: Color = Color(0.5, 0.8, 0.45)
const SCORE_CREATIVITY_COLOR: Color = Color(0.85, 0.55, 0.9)
const SCORE_EMOTION_COLOR: Color = Color(0.95, 0.6, 0.5)

# === State ===
var _pet1: PetEntity = null
var _pet2: PetEntity = null
var _battle_system: LanguageBattleSystem = null
var _is_battling: bool = false

# === UI Nodes ===
var _bg: ColorRect
var _main_vbox: VBoxContainer
var _pet1_card: PanelContainer
var _pet2_card: PanelContainer
var _pet1_name_label: Label
var _pet2_name_label: Label
var _pet1_info_label: Label
var _pet2_info_label: Label
var _pet1_record_label: Label
var _pet2_record_label: Label
var _start_button: Button
var _back_button: Button
var _round_label: Label
var _theme_label: Label
var _log_container: VBoxContainer
var _scroll_container: ScrollContainer
var _result_panel: PanelContainer
var _result_label: Label
var _pet1_select: OptionButton
var _pet2_select: OptionButton

# === Score Bars ===
var _pet1_score_bars: Dictionary = {}  # category → ProgressBar
var _pet2_score_bars: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	_build_ui()
	_populate_pet_selectors()
	_connect_battle_signals()


func _build_ui() -> void:
	# Background
	_bg = ColorRect.new()
	_bg.color = BG_COLOR
	_bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(_bg)

	# Main scroll wrapper
	var outer_scroll: ScrollContainer = ScrollContainer.new()
	outer_scroll.set_anchors_preset(PRESET_FULL_RECT)
	outer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(outer_scroll)

	_main_vbox = VBoxContainer.new()
	_main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_vbox.add_theme_constant_override("separation", 10)
	outer_scroll.add_child(_main_vbox)

	# === Header ===
	var header_hbox: HBoxContainer = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 12)
	_main_vbox.add_child(header_hbox)

	_back_button = Button.new()
	_back_button.text = "< Back"
	_back_button.custom_minimum_size = Vector2(80, 36)
	_style_button(_back_button, Color(0.25, 0.28, 0.38))
	_back_button.pressed.connect(_on_back_pressed)
	header_hbox.add_child(_back_button)

	var title_label: Label = Label.new()
	title_label.text = "Language Battle"
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", HEADER_COLOR)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_hbox.add_child(title_label)

	# Spacer to balance back button
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(80, 0)
	header_hbox.add_child(spacer)

	# === Pet Selectors ===
	var select_hbox: HBoxContainer = HBoxContainer.new()
	select_hbox.add_theme_constant_override("separation", 16)
	select_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_main_vbox.add_child(select_hbox)

	var sel1_vbox: VBoxContainer = VBoxContainer.new()
	sel1_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select_hbox.add_child(sel1_vbox)
	var sel1_label: Label = Label.new()
	sel1_label.text = "Pet 1"
	sel1_label.add_theme_font_size_override("font_size", 13)
	sel1_label.add_theme_color_override("font_color", MUTED_COLOR)
	sel1_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sel1_vbox.add_child(sel1_label)
	_pet1_select = OptionButton.new()
	_pet1_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pet1_select.item_selected.connect(_on_pet1_selected)
	sel1_vbox.add_child(_pet1_select)

	var vs_label: Label = Label.new()
	vs_label.text = "VS"
	vs_label.add_theme_font_size_override("font_size", 20)
	vs_label.add_theme_color_override("font_color", ACCENT_COLOR)
	vs_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	select_hbox.add_child(vs_label)

	var sel2_vbox: VBoxContainer = VBoxContainer.new()
	sel2_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select_hbox.add_child(sel2_vbox)
	var sel2_label: Label = Label.new()
	sel2_label.text = "Pet 2"
	sel2_label.add_theme_font_size_override("font_size", 13)
	sel2_label.add_theme_color_override("font_color", MUTED_COLOR)
	sel2_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sel2_vbox.add_child(sel2_label)
	_pet2_select = OptionButton.new()
	_pet2_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pet2_select.item_selected.connect(_on_pet2_selected)
	sel2_vbox.add_child(_pet2_select)

	# === Pet Cards (side by side) ===
	var cards_hbox: HBoxContainer = HBoxContainer.new()
	cards_hbox.add_theme_constant_override("separation", 12)
	_main_vbox.add_child(cards_hbox)

	_pet1_card = _create_pet_card()
	cards_hbox.add_child(_pet1_card)
	_pet1_name_label = _pet1_card.get_meta("name_label")
	_pet1_info_label = _pet1_card.get_meta("info_label")
	_pet1_record_label = _pet1_card.get_meta("record_label")

	_pet2_card = _create_pet_card()
	cards_hbox.add_child(_pet2_card)
	_pet2_name_label = _pet2_card.get_meta("name_label")
	_pet2_info_label = _pet2_card.get_meta("info_label")
	_pet2_record_label = _pet2_card.get_meta("record_label")

	# === Start Button ===
	_start_button = Button.new()
	_start_button.text = "Start Battle!"
	_start_button.custom_minimum_size = Vector2(0, 44)
	_style_button(_start_button, ACCENT_COLOR.darkened(0.2))
	_start_button.add_theme_font_size_override("font_size", 18)
	_start_button.pressed.connect(_on_start_pressed)
	_main_vbox.add_child(_start_button)

	# === Round Info ===
	var round_hbox: HBoxContainer = HBoxContainer.new()
	round_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	round_hbox.add_theme_constant_override("separation", 16)
	_main_vbox.add_child(round_hbox)

	_round_label = Label.new()
	_round_label.text = ""
	_round_label.add_theme_font_size_override("font_size", 16)
	_round_label.add_theme_color_override("font_color", HEADER_COLOR)
	round_hbox.add_child(_round_label)

	_theme_label = Label.new()
	_theme_label.text = ""
	_theme_label.add_theme_font_size_override("font_size", 14)
	_theme_label.add_theme_color_override("font_color", MUTED_COLOR)
	round_hbox.add_child(_theme_label)

	# === Score Bars (two columns) ===
	var scores_hbox: HBoxContainer = HBoxContainer.new()
	scores_hbox.add_theme_constant_override("separation", 12)
	_main_vbox.add_child(scores_hbox)

	var p1_scores_vbox: VBoxContainer = _create_score_bars_column("Pet 1")
	p1_scores_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scores_hbox.add_child(p1_scores_vbox)
	_pet1_score_bars = p1_scores_vbox.get_meta("bars")

	var p2_scores_vbox: VBoxContainer = _create_score_bars_column("Pet 2")
	p2_scores_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scores_hbox.add_child(p2_scores_vbox)
	_pet2_score_bars = p2_scores_vbox.get_meta("bars")

	# === Battle Log ===
	var log_label: Label = Label.new()
	log_label.text = "Battle Log"
	log_label.add_theme_font_size_override("font_size", 14)
	log_label.add_theme_color_override("font_color", MUTED_COLOR)
	_main_vbox.add_child(log_label)

	_scroll_container = ScrollContainer.new()
	_scroll_container.custom_minimum_size = Vector2(0, 160)
	_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var log_panel_style: StyleBoxFlat = StyleBoxFlat.new()
	log_panel_style.bg_color = Color(0.08, 0.09, 0.16)
	log_panel_style.corner_radius_top_left = 8
	log_panel_style.corner_radius_top_right = 8
	log_panel_style.corner_radius_bottom_left = 8
	log_panel_style.corner_radius_bottom_right = 8
	log_panel_style.content_margin_left = 8
	log_panel_style.content_margin_right = 8
	log_panel_style.content_margin_top = 6
	log_panel_style.content_margin_bottom = 6
	_scroll_container.add_theme_stylebox_override("panel", log_panel_style)
	_main_vbox.add_child(_scroll_container)

	_log_container = VBoxContainer.new()
	_log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_container.add_theme_constant_override("separation", 6)
	_scroll_container.add_child(_log_container)

	# === Result Panel (hidden initially) ===
	_result_panel = PanelContainer.new()
	_result_panel.visible = false
	var result_style: StyleBoxFlat = StyleBoxFlat.new()
	result_style.bg_color = Color(0.12, 0.15, 0.25, 0.95)
	result_style.corner_radius_top_left = 12
	result_style.corner_radius_top_right = 12
	result_style.corner_radius_bottom_left = 12
	result_style.corner_radius_bottom_right = 12
	result_style.content_margin_left = 16
	result_style.content_margin_right = 16
	result_style.content_margin_top = 12
	result_style.content_margin_bottom = 12
	result_style.border_width_left = 2
	result_style.border_width_right = 2
	result_style.border_width_top = 2
	result_style.border_width_bottom = 2
	result_style.border_color = HEADER_COLOR.darkened(0.3)
	_result_panel.add_theme_stylebox_override("panel", result_style)
	_main_vbox.add_child(_result_panel)

	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 16)
	_result_label.add_theme_color_override("font_color", TEXT_COLOR)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_panel.add_child(_result_label)

	# Initial state
	_update_start_button_state()


func _create_pet_card() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = CARD_BG
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var name_label: Label = Label.new()
	name_label.text = "---"
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var info_label: Label = Label.new()
	info_label.text = "Select a pet"
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.add_theme_color_override("font_color", MUTED_COLOR)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info_label)

	var record_label: Label = Label.new()
	record_label.text = ""
	record_label.add_theme_font_size_override("font_size", 11)
	record_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(record_label)

	panel.set_meta("name_label", name_label)
	panel.set_meta("info_label", info_label)
	panel.set_meta("record_label", record_label)

	return panel


func _create_score_bars_column(title: String) -> VBoxContainer:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)

	var title_lbl: Label = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.add_theme_color_override("font_color", MUTED_COLOR)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)
	vbox.set_meta("title_label", title_lbl)

	var bars: Dictionary = {}
	var categories: Array[Array] = [
		["vocabulary", SCORE_VOCAB_COLOR, 30.0],
		["grammar", SCORE_GRAMMAR_COLOR, 25.0],
		["creativity", SCORE_CREATIVITY_COLOR, 25.0],
		["emotion", SCORE_EMOTION_COLOR, 20.0],
	]

	for cat: Array in categories:
		var cat_name: String = cat[0]
		var cat_color: Color = cat[1]
		var cat_max: float = cat[2]

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 4)
		vbox.add_child(hbox)

		var lbl: Label = Label.new()
		lbl.text = cat_name.substr(0, 4).to_upper()
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", cat_color.lightened(0.2))
		lbl.custom_minimum_size = Vector2(36, 0)
		hbox.add_child(lbl)

		var bar: ProgressBar = ProgressBar.new()
		bar.min_value = 0.0
		bar.max_value = cat_max
		bar.value = 0.0
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size = Vector2(0, 14)
		bar.show_percentage = false
		_style_score_bar(bar, cat_color)
		hbox.add_child(bar)

		bars[cat_name] = bar

	vbox.set_meta("bars", bars)
	return vbox


func _style_score_bar(bar: ProgressBar, fill_color: Color) -> void:
	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.12, 0.13, 0.20)
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


func _style_button(btn: Button, color: Color) -> void:
	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.corner_radius_top_left = 10
	normal_style.corner_radius_top_right = 10
	normal_style.corner_radius_bottom_left = 10
	normal_style.corner_radius_bottom_right = 10
	normal_style.content_margin_left = 10
	normal_style.content_margin_right = 10
	normal_style.content_margin_top = 6
	normal_style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style: StyleBoxFlat = normal_style.duplicate()
	pressed_style.bg_color = color.lightened(0.25)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	var disabled_style: StyleBoxFlat = normal_style.duplicate()
	disabled_style.bg_color = color.darkened(0.4)
	btn.add_theme_stylebox_override("disabled", disabled_style)

	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.6))
	btn.add_theme_font_size_override("font_size", 14)


# ========================================================
# Pet Selection
# ========================================================

func _populate_pet_selectors() -> void:
	_pet1_select.clear()
	_pet2_select.clear()

	if not GameManager.instance:
		return

	var alive_pets: Array = []
	for pet_id: int in GameManager.instance.pets:
		var pet: Node = GameManager.instance.pets[pet_id]
		if pet.is_alive:
			alive_pets.append(pet)

	for i: int in alive_pets.size():
		var pet: Node = alive_pets[i]
		_pet1_select.add_item(pet.pet_name, pet.pet_id)
		_pet2_select.add_item(pet.pet_name, pet.pet_id)

	# Auto-select first two pets if possible
	if alive_pets.size() >= 1:
		_pet1_select.selected = 0
		_pet1 = alive_pets[0]
		_update_pet_card(_pet1, _pet1_name_label, _pet1_info_label, _pet1_record_label)

	if alive_pets.size() >= 2:
		_pet2_select.selected = 1
		_pet2 = alive_pets[1]
		_update_pet_card(_pet2, _pet2_name_label, _pet2_info_label, _pet2_record_label)

	_update_start_button_state()


func _on_pet1_selected(index: int) -> void:
	var pet_id: int = _pet1_select.get_item_id(index)
	if GameManager.instance and GameManager.instance.pets.has(pet_id):
		_pet1 = GameManager.instance.pets[pet_id]
		_update_pet_card(_pet1, _pet1_name_label, _pet1_info_label, _pet1_record_label)
	_update_start_button_state()


func _on_pet2_selected(index: int) -> void:
	var pet_id: int = _pet2_select.get_item_id(index)
	if GameManager.instance and GameManager.instance.pets.has(pet_id):
		_pet2 = GameManager.instance.pets[pet_id]
		_update_pet_card(_pet2, _pet2_name_label, _pet2_info_label, _pet2_record_label)
	_update_start_button_state()


func _update_pet_card(pet: PetEntity, name_lbl: Label, info_lbl: Label, record_lbl: Label) -> void:
	if not pet:
		name_lbl.text = "---"
		info_lbl.text = "Select a pet"
		record_lbl.text = ""
		return

	name_lbl.text = pet.pet_name

	# Evolution stage name
	var stage_names: Array[String] = ["Egg", "Baby", "Child", "Teen", "Adult", "Elder"]
	var stage_idx: int = clampi(pet.evolution_stage, 0, stage_names.size() - 1)
	var stage_name: String = stage_names[stage_idx]

	# Vocab size
	var vocab_size: int = 0
	if GameManager.instance and GameManager.instance.original_language:
		var vocab: Dictionary = GameManager.instance.original_language.get_full_vocabulary()
		vocab_size = vocab.size()

	info_lbl.text = "Stage: %s | Vocab: %d" % [stage_name, vocab_size]

	# Win/loss record
	if _battle_system:
		var stats: Dictionary = _battle_system.get_battle_stats(pet.pet_id)
		var wins: int = stats.get("wins", 0)
		var losses: int = stats.get("losses", 0)
		var total: int = stats.get("total_battles", 0)
		var best: float = stats.get("best_score", 0.0)
		if total > 0:
			record_lbl.text = "W:%d L:%d (Best: %.0f)" % [wins, losses, best]
		else:
			record_lbl.text = "No battles yet"
	else:
		record_lbl.text = ""


func _update_start_button_state() -> void:
	var can_battle: bool = (
		_pet1 != null
		and _pet2 != null
		and _pet1 != _pet2
		and _pet1.is_alive
		and _pet2.is_alive
		and not _is_battling
	)
	_start_button.disabled = not can_battle

	if _pet1 == null or _pet2 == null:
		_start_button.text = "Select 2 pets to battle"
	elif _pet1 == _pet2:
		_start_button.text = "Select different pets"
	elif not _pet1.is_alive or not _pet2.is_alive:
		_start_button.text = "Both pets must be alive"
	elif _is_battling:
		_start_button.text = "Battle in progress..."
	else:
		_start_button.text = "Start Battle!"


# ========================================================
# Battle Signals
# ========================================================

func _connect_battle_signals() -> void:
	if GameManager.instance and GameManager.instance.battle_system:
		_battle_system = GameManager.instance.battle_system
		_battle_system.battle_started.connect(_on_battle_started)
		_battle_system.battle_round_complete.connect(_on_battle_round_complete)
		_battle_system.battle_ended.connect(_on_battle_ended)


func _on_back_pressed() -> void:
	if _is_battling:
		return  # Don't allow back during battle
	back_requested.emit()


func _on_start_pressed() -> void:
	if not _pet1 or not _pet2 or _pet1 == _pet2:
		return
	if not _battle_system:
		push_warning("BattleScreen: No battle system available")
		return

	_is_battling = true
	_result_panel.visible = false
	_clear_log()
	_reset_score_bars()
	_update_start_button_state()
	_back_button.disabled = true

	# Update column titles with pet names
	var p1_title: Label = _pet1_score_bars.values()[0].get_parent().get_parent().get_meta("title_label")
	var p2_title: Label = _pet2_score_bars.values()[0].get_parent().get_parent().get_meta("title_label")
	p1_title.text = _pet1.pet_name
	p2_title.text = _pet2.pet_name

	_add_log_entry("Battle begins: %s vs %s!" % [_pet1.pet_name, _pet2.pet_name], HEADER_COLOR)
	_battle_system.start_battle(_pet1, _pet2)


func _on_battle_started(pet1_id: int, pet2_id: int) -> void:
	_round_label.text = "Round 0/%d" % LanguageBattleSystem.TOTAL_ROUNDS
	_theme_label.text = "Preparing..."


func _on_battle_round_complete(round_num: int, scores: Dictionary) -> void:
	var theme_name: String = scores.get("theme", "unknown")
	_round_label.text = "Round %d/%d" % [round_num, LanguageBattleSystem.TOTAL_ROUNDS]
	_theme_label.text = "Theme: %s" % theme_name.capitalize()

	var p1_score: Dictionary = scores.get("pet1_score", {})
	var p2_score: Dictionary = scores.get("pet2_score", {})
	var p1_response: String = scores.get("pet1_response", "")
	var p2_response: String = scores.get("pet2_response", "")

	# Update score bars
	_update_score_bar(_pet1_score_bars, p1_score)
	_update_score_bar(_pet2_score_bars, p2_score)

	# Log round results
	var p1_name: String = _pet1.pet_name if _pet1 else "Pet1"
	var p2_name: String = _pet2.pet_name if _pet2 else "Pet2"

	_add_log_entry("--- Round %d: %s ---" % [round_num, theme_name.capitalize()], HEADER_COLOR)
	_add_log_entry("%s: \"%s\"" % [p1_name, p1_response], SCORE_VOCAB_COLOR)
	_add_log_entry("  Score: %.1f (V:%.1f G:%.1f C:%.1f E:%.1f)" % [
		p1_score.get("total", 0.0),
		p1_score.get("vocabulary_score", 0.0),
		p1_score.get("grammar_score", 0.0),
		p1_score.get("creativity_score", 0.0),
		p1_score.get("emotion_score", 0.0),
	], MUTED_COLOR)
	_add_log_entry("%s: \"%s\"" % [p2_name, p2_response], SCORE_EMOTION_COLOR)
	_add_log_entry("  Score: %.1f (V:%.1f G:%.1f C:%.1f E:%.1f)" % [
		p2_score.get("total", 0.0),
		p2_score.get("vocabulary_score", 0.0),
		p2_score.get("grammar_score", 0.0),
		p2_score.get("creativity_score", 0.0),
		p2_score.get("emotion_score", 0.0),
	], MUTED_COLOR)

	# Auto-scroll to bottom
	await get_tree().process_frame
	_scroll_container.scroll_vertical = int(_log_container.size.y)


func _on_battle_ended(winner_id: int, final_scores: Dictionary) -> void:
	_is_battling = false
	_back_button.disabled = false
	_update_start_button_state()

	var p1_total: float = final_scores.get("pet1_total", 0.0)
	var p2_total: float = final_scores.get("pet2_total", 0.0)
	var p1_name: String = _pet1.pet_name if _pet1 else "Pet1"
	var p2_name: String = _pet2.pet_name if _pet2 else "Pet2"

	# Determine winner name
	var winner_name: String = "Draw"
	if _pet1 and _pet1.pet_id == winner_id:
		winner_name = _pet1.pet_name
	elif _pet2 and _pet2.pet_id == winner_id:
		winner_name = _pet2.pet_name

	# Show result
	_result_panel.visible = true
	_result_label.text = (
		"Winner: %s!\n\n"
		+ "%s: %.1f pts\n"
		+ "%s: %.1f pts"
	) % [winner_name, p1_name, p1_total, p2_name, p2_total]

	_add_log_entry("=== BATTLE OVER ===", HEADER_COLOR)
	_add_log_entry("Winner: %s! (%.1f vs %.1f)" % [winner_name, p1_total, p2_total], WIN_COLOR)

	# Update pet cards with new records
	_update_pet_card(_pet1, _pet1_name_label, _pet1_info_label, _pet1_record_label)
	_update_pet_card(_pet2, _pet2_name_label, _pet2_info_label, _pet2_record_label)

	# Auto-scroll
	await get_tree().process_frame
	_scroll_container.scroll_vertical = int(_log_container.size.y)

	battle_complete.emit(winner_id)


# ========================================================
# Score Bar Updates
# ========================================================

func _update_score_bar(bars: Dictionary, score: Dictionary) -> void:
	if "vocabulary" in bars:
		var bar: ProgressBar = bars["vocabulary"]
		bar.value = score.get("vocabulary_score", 0.0)
	if "grammar" in bars:
		var bar: ProgressBar = bars["grammar"]
		bar.value = score.get("grammar_score", 0.0)
	if "creativity" in bars:
		var bar: ProgressBar = bars["creativity"]
		bar.value = score.get("creativity_score", 0.0)
	if "emotion" in bars:
		var bar: ProgressBar = bars["emotion"]
		bar.value = score.get("emotion_score", 0.0)


func _reset_score_bars() -> void:
	for cat: String in _pet1_score_bars:
		_pet1_score_bars[cat].value = 0.0
	for cat: String in _pet2_score_bars:
		_pet2_score_bars[cat].value = 0.0


# ========================================================
# Battle Log
# ========================================================

func _add_log_entry(text: String, color: Color) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_container.add_child(label)


func _clear_log() -> void:
	for child: Node in _log_container.get_children():
		child.queue_free()
