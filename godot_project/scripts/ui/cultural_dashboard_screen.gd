## CulturalDashboardScreen — v1.1.0 文化・チーム・記憶の統合ダッシュボード
## 文化アーティファクト、アクティブチーム、グリーフ状態、ドリームログを表示
class_name CulturalDashboardScreen
extends Control

signal back_requested

# === UI Constants ===
const BG_COLOR: Color = Color(0.06, 0.07, 0.12)
const SECTION_BG: Color = Color(0.12, 0.13, 0.20)
const ACCENT_CULTURE: Color = Color(0.85, 0.55, 0.95)
const ACCENT_TEAM: Color = Color(0.45, 0.85, 0.55)
const ACCENT_MEMORY: Color = Color(0.55, 0.75, 0.95)
const ACCENT_DREAM: Color = Color(0.75, 0.65, 0.95)
const TEXT_PRIMARY: Color = Color(0.9, 0.92, 0.96)
const TEXT_SECONDARY: Color = Color(0.6, 0.62, 0.68)
const CARD_BG: Color = Color(0.14, 0.16, 0.24)
const CARD_HIGHLIGHT: Color = Color(0.18, 0.20, 0.30)
const TRADITION_GOLD: Color = Color(1.0, 0.85, 0.3)

const ARTIFACT_ICONS: Dictionary = {
	"festival": "🎉", "story": "📖", "song": "🎵",
	"ritual": "🕯", "tradition": "👑",
}
const TASK_ICONS: Dictionary = {
	"EXPLORATION": "🧭", "TEACHING": "📚", "CAREGIVING": "💗",
	"EVENT_PLANNING": "🎪", "LANGUAGE_PROJECT": "🗣", "PATROL": "🛡",
}
const GRIEF_ICONS: Dictionary = {
	"denial": "😶", "anger": "😠", "bargaining": "🤝",
	"depression": "😢", "acceptance": "🕊",
}

# === State ===
var _scroll: ScrollContainer
var _content: VBoxContainer
var _tab_buttons: Array[Button] = []
var _tab_containers: Array[VBoxContainer] = []
var _active_tab: int = 0


func _ready() -> void:
	_build_ui()


func refresh() -> void:
	## 外部から呼んでデータを再描画
	_populate_all_tabs()


func _build_ui() -> void:
	# Full background
	var bg: ColorRect = ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	# Header
	var header: HBoxContainer = HBoxContainer.new()
	header.set_anchors_preset(PRESET_TOP_WIDE)
	header.offset_top = 8
	header.offset_bottom = 48
	header.offset_left = 12
	header.offset_right = -12
	header.add_theme_constant_override("separation", 12)
	add_child(header)

	var back_btn: Button = Button.new()
	back_btn.text = "< Back"
	back_btn.custom_minimum_size = Vector2(80, 36)
	back_btn.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back_btn)

	var title: Label = Label.new()
	title.text = "Cultural Dashboard"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", ACCENT_CULTURE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	# Tab bar
	var tab_bar: HBoxContainer = HBoxContainer.new()
	tab_bar.set_anchors_preset(PRESET_TOP_WIDE)
	tab_bar.offset_top = 52
	tab_bar.offset_bottom = 84
	tab_bar.offset_left = 12
	tab_bar.offset_right = -12
	tab_bar.add_theme_constant_override("separation", 8)
	add_child(tab_bar)

	var tab_names: Array[String] = ["🎉 Culture", "🧭 Teams", "🕊 Memory", "💭 Dreams"]
	var tab_colors: Array[Color] = [ACCENT_CULTURE, ACCENT_TEAM, ACCENT_MEMORY, ACCENT_DREAM]
	for i: int in tab_names.size():
		var btn: Button = Button.new()
		btn.text = tab_names[i]
		btn.custom_minimum_size = Vector2(90, 28)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var idx: int = i
		btn.pressed.connect(func() -> void: _switch_tab(idx))
		tab_bar.add_child(btn)
		_tab_buttons.append(btn)

	# Scrollable content area
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_preset(PRESET_FULL_RECT)
	_scroll.offset_top = 92
	_scroll.offset_left = 12
	_scroll.offset_right = -12
	_scroll.offset_bottom = -8
	add_child(_scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	_scroll.add_child(_content)

	# Create tab containers
	for i: int in 4:
		var container: VBoxContainer = VBoxContainer.new()
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_theme_constant_override("separation", 8)
		_content.add_child(container)
		_tab_containers.append(container)

	_populate_all_tabs()
	_switch_tab(0)


func _switch_tab(index: int) -> void:
	_active_tab = index
	for i: int in _tab_containers.size():
		_tab_containers[i].visible = (i == index)
	# Visual feedback on buttons
	for i: int in _tab_buttons.size():
		_tab_buttons[i].modulate = Color.WHITE if i == index else Color(0.6, 0.6, 0.6)


func _populate_all_tabs() -> void:
	_populate_culture_tab()
	_populate_teams_tab()
	_populate_memory_tab()
	_populate_dreams_tab()


# === Culture Tab ===
func _populate_culture_tab() -> void:
	var container: VBoxContainer = _tab_containers[0]
	_clear_children(container)

	var cultural_sys: CulturalEmergenceSystem = _get_cultural_system()
	if not cultural_sys:
		_add_empty_label(container, "Cultural system not available yet.")
		return

	var artifacts: Dictionary = cultural_sys.artifacts
	if artifacts.is_empty():
		_add_empty_label(container, "No cultural artifacts yet. Keep your pets talking!")
		return

	# Stats header
	var stats_box: HBoxContainer = _create_stats_row(container)
	_add_stat_pill(stats_box, "Total", str(artifacts.size()), ACCENT_CULTURE)

	var tradition_count: int = 0
	for art_id: String in artifacts:
		var art: Dictionary = artifacts[art_id]
		if art.get("type", "") == "tradition":
			tradition_count += 1
	_add_stat_pill(stats_box, "Traditions", str(tradition_count), TRADITION_GOLD)
	_add_stat_pill(stats_box, "Created", str(cultural_sys.total_artifacts_created), TEXT_SECONDARY)

	# Artifact cards
	var sorted_ids: Array = artifacts.keys()
	sorted_ids.sort_custom(func(a: Variant, b: Variant) -> bool:
		return artifacts[a].get("popularity", 0.0) > artifacts[b].get("popularity", 0.0)
	)

	for art_id: Variant in sorted_ids.slice(0, 12):  # Show top 12
		var art: Dictionary = artifacts[str(art_id)]
		_add_artifact_card(container, str(art_id), art)


func _add_artifact_card(parent: VBoxContainer, art_id: String, art: Dictionary) -> void:
	var card: PanelContainer = _create_card()
	parent.add_child(card)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	card.add_child(hbox)

	# Type icon
	var art_type: String = art.get("type", "story")
	var icon_label: Label = Label.new()
	icon_label.text = ARTIFACT_ICONS.get(art_type, "📄")
	icon_label.add_theme_font_size_override("font_size", 24)
	icon_label.custom_minimum_size = Vector2(32, 0)
	hbox.add_child(icon_label)

	# Info column
	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	hbox.add_child(info)

	var name_label: Label = Label.new()
	var display_name: String = art.get("name", art_id)
	var is_tradition: bool = art_type == "tradition"
	name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", TRADITION_GOLD if is_tradition else TEXT_PRIMARY)
	info.add_child(name_label)

	var detail_label: Label = Label.new()
	var popularity: float = art.get("popularity", 0.0)
	var known_by: int = art.get("known_by_count", 0)
	detail_label.text = "%s  •  Pop: %.0f%%  •  Known by %d pets" % [art_type.capitalize(), popularity * 100.0, known_by]
	detail_label.add_theme_font_size_override("font_size", 11)
	detail_label.add_theme_color_override("font_color", TEXT_SECONDARY)
	info.add_child(detail_label)

	# Popularity bar
	var pop_bar: ProgressBar = ProgressBar.new()
	pop_bar.custom_minimum_size = Vector2(60, 6)
	pop_bar.max_value = 1.0
	pop_bar.value = popularity
	pop_bar.show_percentage = false
	hbox.add_child(pop_bar)


# === Teams Tab ===
func _populate_teams_tab() -> void:
	var container: VBoxContainer = _tab_containers[1]
	_clear_children(container)

	var team_sys: PetTeamOrchestrator = _get_team_system()
	if not team_sys:
		_add_empty_label(container, "Team system not available yet.")
		return

	# Stats
	var stats_box: HBoxContainer = _create_stats_row(container)
	_add_stat_pill(stats_box, "Active", str(team_sys.active_teams.size()), ACCENT_TEAM)
	_add_stat_pill(stats_box, "Completed", str(team_sys.completed_teams.size()), TEXT_SECONDARY)
	_add_stat_pill(stats_box, "Today", str(team_sys._daily_formation_count), TEXT_SECONDARY)

	# Active teams
	if team_sys.active_teams.is_empty():
		_add_empty_label(container, "No active teams. Pets form teams every 4 minutes.")
	else:
		var section_label: Label = Label.new()
		section_label.text = "Active Missions"
		section_label.add_theme_font_size_override("font_size", 16)
		section_label.add_theme_color_override("font_color", ACCENT_TEAM)
		container.add_child(section_label)

		for team_id: String in team_sys.active_teams:
			var team: Dictionary = team_sys.active_teams[team_id]
			_add_team_card(container, team)

	# Recent completed
	if not team_sys.completed_teams.is_empty():
		var hist_label: Label = Label.new()
		hist_label.text = "Recently Completed"
		hist_label.add_theme_font_size_override("font_size", 16)
		hist_label.add_theme_color_override("font_color", TEXT_SECONDARY)
		container.add_child(hist_label)

		var recent: Array[Dictionary] = team_sys.completed_teams.slice(-5)
		recent.reverse()
		for team: Dictionary in recent:
			_add_team_card(container, team, true)


func _add_team_card(parent: VBoxContainer, team: Dictionary, completed: bool = false) -> void:
	var card: PanelContainer = _create_card()
	parent.add_child(card)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	card.add_child(hbox)

	var task_name: String = team.get("task", "EXPLORATION")
	var icon_label: Label = Label.new()
	icon_label.text = TASK_ICONS.get(task_name, "📋")
	icon_label.add_theme_font_size_override("font_size", 22)
	icon_label.custom_minimum_size = Vector2(30, 0)
	hbox.add_child(icon_label)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	hbox.add_child(info)

	var title: Label = Label.new()
	var members: Array = team.get("members", [])
	var leader: int = team.get("leader", -1)
	title.text = "%s Mission — %d members" % [task_name.capitalize().replace("_", " "), members.size()]
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", TEXT_SECONDARY if completed else TEXT_PRIMARY)
	info.add_child(title)

	var detail: Label = Label.new()
	if completed:
		var result_text: String = team.get("result_summary", "Completed")
		detail.text = "✅ %s" % result_text
	else:
		var progress: float = team.get("progress", 0.0)
		detail.text = "Leader: Pet #%d  •  Progress: %.0f%%" % [leader, progress * 100.0]
	detail.add_theme_font_size_override("font_size", 11)
	detail.add_theme_color_override("font_color", TEXT_SECONDARY)
	info.add_child(detail)

	if completed:
		card.modulate = Color(0.7, 0.7, 0.7)


# === Memory Tab (Grief & Nostalgia) ===
func _populate_memory_tab() -> void:
	var container: VBoxContainer = _tab_containers[2]
	_clear_children(container)

	var bridge: MemoryPersonalityBridge = _get_memory_bridge()
	if not bridge:
		_add_empty_label(container, "Memory system not available yet.")
		return

	# Grief states
	if not bridge.grief_states.is_empty():
		var grief_label: Label = Label.new()
		grief_label.text = "🕊 Grief Processing"
		grief_label.add_theme_font_size_override("font_size", 16)
		grief_label.add_theme_color_override("font_color", ACCENT_MEMORY)
		container.add_child(grief_label)

		for pet_id_key: Variant in bridge.grief_states:
			var state: Dictionary = bridge.grief_states[pet_id_key]
			_add_grief_card(container, int(pet_id_key), state)

	# Nostalgia entries
	var total_nostalgia: int = 0
	for pet_id_key: Variant in bridge.nostalgia_log:
		total_nostalgia += bridge.nostalgia_log[pet_id_key].size()

	if total_nostalgia > 0:
		var nost_label: Label = Label.new()
		nost_label.text = "💫 Nostalgia Moments (%d)" % total_nostalgia
		nost_label.add_theme_font_size_override("font_size", 16)
		nost_label.add_theme_color_override("font_color", ACCENT_MEMORY)
		container.add_child(nost_label)

		# Show latest 5 across all pets
		var all_entries: Array[Dictionary] = []
		for pet_id_key: Variant in bridge.nostalgia_log:
			for entry: Dictionary in bridge.nostalgia_log[pet_id_key]:
				var e: Dictionary = entry.duplicate()
				e["pet_id"] = int(pet_id_key)
				all_entries.append(e)
		all_entries.sort_custom(func(a: Variant, b: Variant) -> bool:
			return a.get("timestamp", 0.0) > b.get("timestamp", 0.0)
		)
		for entry: Dictionary in all_entries.slice(0, 5):
			_add_nostalgia_card(container, entry)

	# Personality modifiers
	if not bridge.personality_modifiers.is_empty():
		var mod_label: Label = Label.new()
		mod_label.text = "🧠 Personality Growth"
		mod_label.add_theme_font_size_override("font_size", 16)
		mod_label.add_theme_color_override("font_color", ACCENT_MEMORY)
		container.add_child(mod_label)

		for pet_id_key: Variant in bridge.personality_modifiers:
			var mods: Dictionary = bridge.personality_modifiers[pet_id_key]
			if mods.is_empty():
				continue
			var card: PanelContainer = _create_card()
			container.add_child(card)
			var lbl: Label = Label.new()
			var parts: Array[String] = []
			for trait: String in mods:
				var val: float = mods[trait]
				parts.append("%s %+.2f" % [trait, val])
			lbl.text = "Pet #%s: %s" % [str(pet_id_key), ", ".join(parts)]
			lbl.add_theme_font_size_override("font_size", 12)
			lbl.add_theme_color_override("font_color", TEXT_PRIMARY)
			card.add_child(lbl)

	if bridge.grief_states.is_empty() and total_nostalgia == 0 and bridge.personality_modifiers.is_empty():
		_add_empty_label(container, "No memory events yet. Memories form through conversations and life events.")


func _add_grief_card(parent: VBoxContainer, pet_id: int, state: Dictionary) -> void:
	var card: PanelContainer = _create_card()
	parent.add_child(card)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	card.add_child(hbox)

	var stage_name: String = state.get("stage", "denial")
	var icon: Label = Label.new()
	icon.text = GRIEF_ICONS.get(stage_name, "😶")
	icon.add_theme_font_size_override("font_size", 22)
	icon.custom_minimum_size = Vector2(30, 0)
	hbox.add_child(icon)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	hbox.add_child(info)

	var title: Label = Label.new()
	title.text = "Pet #%d — %s stage" % [pet_id, stage_name.capitalize()]
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", TEXT_PRIMARY)
	info.add_child(title)

	var stage_index: int = state.get("stage_index", 0)
	var progress_bar: ProgressBar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 8)
	progress_bar.max_value = 5.0
	progress_bar.value = float(stage_index + 1)
	progress_bar.show_percentage = false
	info.add_child(progress_bar)


func _add_nostalgia_card(parent: VBoxContainer, entry: Dictionary) -> void:
	var card: PanelContainer = _create_card()
	parent.add_child(card)

	var lbl: Label = Label.new()
	var pet_id: int = entry.get("pet_id", 0)
	var summary: String = entry.get("memory_summary", "A distant memory...")
	lbl.text = "💫 Pet #%d: %s" % [pet_id, summary]
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", ACCENT_MEMORY)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(lbl)


# === Dreams Tab ===
func _populate_dreams_tab() -> void:
	var container: VBoxContainer = _tab_containers[3]
	_clear_children(container)

	var bridge: MemoryPersonalityBridge = _get_memory_bridge()
	if not bridge:
		_add_empty_label(container, "Dream system not available yet.")
		return

	var total_dreams: int = 0
	var all_dreams: Array[Dictionary] = []
	for pet_id_key: Variant in bridge.dream_log:
		var dreams: Array = bridge.dream_log[pet_id_key]
		total_dreams += dreams.size()
		for dream: Dictionary in dreams:
			var d: Dictionary = dream.duplicate()
			d["pet_id"] = int(pet_id_key)
			all_dreams.append(d)

	if all_dreams.is_empty():
		_add_empty_label(container, "No dreams yet. Pets dream when they sleep...")
		return

	# Stats
	var stats_box: HBoxContainer = _create_stats_row(container)
	_add_stat_pill(stats_box, "Total Dreams", str(total_dreams), ACCENT_DREAM)
	_add_stat_pill(stats_box, "Dreamers", str(bridge.dream_log.size()), TEXT_SECONDARY)

	# Sort by timestamp (newest first)
	all_dreams.sort_custom(func(a: Variant, b: Variant) -> bool:
		return a.get("timestamp", 0.0) > b.get("timestamp", 0.0)
	)

	for dream: Dictionary in all_dreams.slice(0, 10):
		var card: PanelContainer = _create_card()
		container.add_child(card)

		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		card.add_child(vbox)

		var header: Label = Label.new()
		header.text = "💭 Pet #%d's Dream" % dream.get("pet_id", 0)
		header.add_theme_font_size_override("font_size", 13)
		header.add_theme_color_override("font_color", ACCENT_DREAM)
		vbox.add_child(header)

		var content: Label = Label.new()
		content.text = dream.get("content", "A mysterious dream...")
		content.add_theme_font_size_override("font_size", 12)
		content.add_theme_color_override("font_color", TEXT_PRIMARY)
		content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(content)


# === UI Helpers ===
func _create_card() -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = CARD_BG
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)
	return card


func _create_stats_row(parent: VBoxContainer) -> HBoxContainer:
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	parent.add_child(hbox)
	return hbox


func _add_stat_pill(parent: HBoxContainer, label_text: String, value_text: String, color: Color) -> void:
	var pill: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = SECTION_BG
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	pill.add_theme_stylebox_override("panel", style)
	parent.add_child(pill)

	var lbl: Label = Label.new()
	lbl.text = "%s: %s" % [label_text, value_text]
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", color)
	pill.add_child(lbl)


func _add_empty_label(parent: VBoxContainer, text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", TEXT_SECONDARY)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)


func _clear_children(node: Node) -> void:
	for child: Node in node.get_children():
		child.queue_free()


# === System References ===
func _get_cultural_system() -> CulturalEmergenceSystem:
	if GameManager.instance and GameManager.instance.has_meta("cultural_system"):
		return GameManager.instance.get_meta("cultural_system") as CulturalEmergenceSystem
	if GameManager.instance and "cultural_system" in GameManager.instance:
		return GameManager.instance.cultural_system as CulturalEmergenceSystem
	return null


func _get_team_system() -> PetTeamOrchestrator:
	if GameManager.instance and GameManager.instance.has_meta("team_orchestrator"):
		return GameManager.instance.get_meta("team_orchestrator") as PetTeamOrchestrator
	if GameManager.instance and "team_orchestrator" in GameManager.instance:
		return GameManager.instance.team_orchestrator as PetTeamOrchestrator
	return null


func _get_memory_bridge() -> MemoryPersonalityBridge:
	if GameManager.instance and GameManager.instance.has_meta("memory_bridge"):
		return GameManager.instance.get_meta("memory_bridge") as MemoryPersonalityBridge
	if GameManager.instance and "memory_bridge" in GameManager.instance:
		return GameManager.instance.memory_bridge as MemoryPersonalityBridge
	return null
