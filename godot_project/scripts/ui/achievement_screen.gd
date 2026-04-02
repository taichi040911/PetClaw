## AchievementScreen — 実績一覧画面
## カテゴリ別に実績カードをグリッド表示。ロック/アンロック状態を視覚的に区別。
class_name AchievementScreen
extends Control

signal back_requested

# === UI Constants ===
const BG_COLOR: Color = Color(0.08, 0.09, 0.14)
const CARD_BG_UNLOCKED: Color = Color(0.16, 0.18, 0.28)
const CARD_BG_LOCKED: Color = Color(0.10, 0.11, 0.16)
const ACCENT_COLOR: Color = Color(0.4, 0.75, 0.95)
const GOLD_COLOR: Color = Color(1.0, 0.85, 0.3)
const LOCKED_TEXT_COLOR: Color = Color(0.4, 0.42, 0.5)
const UNLOCKED_TEXT_COLOR: Color = Color(0.88, 0.9, 0.95)
const GRID_COLUMNS: int = 4
const CARD_MIN_SIZE: Vector2 = Vector2(150, 130)

const CATEGORY_LABELS: Dictionary = {
	&"language": "Language",
	&"social": "Social",
	&"battle": "Battle",
	&"care": "Care",
}

const CATEGORY_EMOJIS: Dictionary = {
	&"language": "📖",
	&"social": "💬",
	&"battle": "⚔",
	&"care": "❤",
}

const ICON_EMOJIS: Dictionary = {
	"scroll": "📜",
	"book_open": "📚",
	"feather": "🪶",
	"globe": "🌍",
	"graduation_cap": "🎓",
	"speech_bubble": "💬",
	"megaphone": "📢",
	"heart": "❤",
	"crossed_swords": "⚔",
	"users": "👥",
	"trophy_bronze": "🥉",
	"trophy_gold": "🏆",
	"lightning": "⚡",
	"star": "⭐",
	"shield": "🛡",
	"egg": "🥚",
	"dna": "🧬",
	"crown": "👑",
	"grid": "📦",
	"clock": "⏰",
}

# === State ===
var _progress_bar: ProgressBar
var _progress_label: Label
var _scroll: ScrollContainer
var _content_vbox: VBoxContainer


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Background
	var bg: ColorRect = ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	# Header bar
	var header: HBoxContainer = HBoxContainer.new()
	header.set_anchors_preset(PRESET_TOP_WIDE)
	header.offset_top = 8
	header.offset_bottom = 52
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
	title.text = "Achievements"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", GOLD_COLOR)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	# Progress section
	var progress_box: VBoxContainer = VBoxContainer.new()
	progress_box.set_anchors_preset(PRESET_TOP_WIDE)
	progress_box.offset_top = 56
	progress_box.offset_bottom = 100
	progress_box.offset_left = 16
	progress_box.offset_right = -16
	progress_box.add_theme_constant_override("separation", 4)
	add_child(progress_box)

	_progress_label = Label.new()
	_progress_label.add_theme_font_size_override("font_size", 14)
	_progress_label.add_theme_color_override("font_color", ACCENT_COLOR)
	progress_box.add_child(_progress_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 12)
	_progress_bar.max_value = 100.0
	_progress_bar.show_percentage = false
	progress_box.add_child(_progress_bar)

	# Scrollable content
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_preset(PRESET_FULL_RECT)
	_scroll.offset_top = 108
	_scroll.offset_left = 12
	_scroll.offset_right = -12
	_scroll.offset_bottom = -8
	add_child(_scroll)

	_content_vbox = VBoxContainer.new()
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_vbox.add_theme_constant_override("separation", 20)
	_scroll.add_child(_content_vbox)

	# Populate with achievement data
	_populate_achievements()


func _populate_achievements() -> void:
	var achievements: Array[Dictionary] = _get_achievements()
	var total: int = achievements.size()
	var unlocked: int = 0
	for ach: Dictionary in achievements:
		if ach.get("unlocked", false):
			unlocked += 1

	# Update progress
	_progress_label.text = "%d/%d unlocked" % [unlocked, total]
	if total > 0:
		_progress_bar.value = (float(unlocked) / float(total)) * 100.0
	else:
		_progress_bar.value = 0.0

	# Group by category
	var categories: Array[StringName] = [&"language", &"social", &"battle", &"care"]
	for cat: StringName in categories:
		var cat_achievements: Array[Dictionary] = []
		for ach: Dictionary in achievements:
			if ach.get("category", &"") == cat:
				cat_achievements.append(ach)

		if cat_achievements.is_empty():
			continue

		_add_category_section(cat, cat_achievements)


func _add_category_section(category: StringName, achievements: Array[Dictionary]) -> void:
	# Section header
	var header: Label = Label.new()
	var emoji: String = CATEGORY_EMOJIS.get(category, "")
	var label_text: String = CATEGORY_LABELS.get(category, str(category))
	header.text = "%s %s" % [emoji, label_text]
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", ACCENT_COLOR)
	_content_vbox.add_child(header)

	# Grid container
	var grid: GridContainer = GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_content_vbox.add_child(grid)

	for ach: Dictionary in achievements:
		var card: PanelContainer = _create_achievement_card(ach)
		grid.add_child(card)


func _create_achievement_card(ach: Dictionary) -> PanelContainer:
	var is_unlocked: bool = ach.get("unlocked", false)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = CARD_MIN_SIZE

	# Style the panel
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = CARD_BG_UNLOCKED if is_unlocked else CARD_BG_LOCKED
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0

	if is_unlocked:
		style.border_color = GOLD_COLOR
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_width_left = 2
		style.border_width_right = 2
	else:
		style.border_color = Color(0.2, 0.22, 0.3)
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_width_left = 1
		style.border_width_right = 1

	panel.add_theme_stylebox_override("panel", style)

	# Card content
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# Icon
	var icon_label: Label = Label.new()
	var icon_key: String = ach.get("icon", "star")
	icon_label.text = ICON_EMOJIS.get(icon_key, "?")
	icon_label.add_theme_font_size_override("font_size", 28)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_label)

	# Title
	var title_label: Label = Label.new()
	title_label.text = ach.get("title", "???") if is_unlocked else "???"
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", UNLOCKED_TEXT_COLOR if is_unlocked else LOCKED_TEXT_COLOR)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title_label)

	# Description
	var desc_label: Label = Label.new()
	desc_label.text = ach.get("description", "") if is_unlocked else "???"
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", Color(0.65, 0.68, 0.75) if is_unlocked else LOCKED_TEXT_COLOR)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Opacity for locked cards
	if not is_unlocked:
		panel.modulate.a = 0.5
		icon_label.text = "🔒"

	return panel


func _get_achievements() -> Array[Dictionary]:
	## Safely get achievements from AchievementSystem via GameManager.
	if not GameManager.instance:
		return []
	if not GameManager.instance.has_method("get") and not ("achievement_system" in GameManager.instance):
		# Try via get() on the node
		pass
	var ach_sys: Node = GameManager.instance.get("achievement_system") as Node
	if ach_sys and ach_sys.has_method("get_all_achievements"):
		return ach_sys.get_all_achievements()
	return []
