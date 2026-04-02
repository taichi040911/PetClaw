## EnvironmentSelector — 環境背景セレクター
## プレイヤーがペットの環境（forest, sea, city, ruins, sky）を選択するパネル
class_name EnvironmentSelector
extends Control

signal environment_changed(env_name: String)
signal back_requested

# === 環境データ定義 ===
const ENVIRONMENTS: Array[Dictionary] = [
	{"key": "forest", "label": "Forest", "icon": "🌲", "color": Color(0.18, 0.55, 0.24), "bg_tint": Color(0.12, 0.22, 0.10)},
	{"key": "sea", "label": "Sea", "icon": "🌊", "color": Color(0.15, 0.40, 0.70), "bg_tint": Color(0.08, 0.15, 0.28)},
	{"key": "city", "label": "City", "icon": "🏙", "color": Color(0.55, 0.50, 0.45), "bg_tint": Color(0.18, 0.16, 0.14)},
	{"key": "ruins", "label": "Ruins", "icon": "🏛", "color": Color(0.50, 0.35, 0.55), "bg_tint": Color(0.16, 0.10, 0.20)},
	{"key": "sky", "label": "Sky", "icon": "☁", "color": Color(0.40, 0.65, 0.85), "bg_tint": Color(0.14, 0.20, 0.30)},
]

const CARD_SIZE: Vector2 = Vector2(140, 160)
const CARD_GAP: int = 16
const COLUMNS: int = 3

var _selected_env: String = "forest"
var _cards: Dictionary = {}  # key -> PanelContainer
var _grid: GridContainer


func _ready() -> void:
	_build_ui()


func set_current_environment(env_name: String) -> void:
	_selected_env = env_name
	_update_selection_visuals()


func _build_ui() -> void:
	# === 背景 ===
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.14)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	# === ヘッダー ===
	var header: HBoxContainer = HBoxContainer.new()
	header.set_anchors_preset(PRESET_TOP_WIDE)
	header.offset_bottom = 48
	header.offset_left = 8
	add_child(header)

	var back_btn: Button = Button.new()
	back_btn.text = "< Back"
	back_btn.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back_btn)

	var title: Label = Label.new()
	title.text = "Environment"
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)

	# === スクロール領域 ===
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_preset(PRESET_FULL_RECT)
	scroll.offset_top = 56
	scroll.offset_left = 20
	scroll.offset_right = -20
	scroll.offset_bottom = -20
	add_child(scroll)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(vbox)

	# === 説明 ===
	var desc: Label = Label.new()
	desc.text = "Choose where your pet lives.\nEach environment affects mood and personality."
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(desc)

	# === グリッド ===
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", CARD_GAP)
	_grid.add_theme_constant_override("v_separation", CARD_GAP)
	vbox.add_child(_grid)

	# === カード生成 ===
	for env: Dictionary in ENVIRONMENTS:
		var card: PanelContainer = _create_env_card(env)
		_grid.add_child(card)
		_cards[env["key"]] = card

	_update_selection_visuals()


func _create_env_card(env: Dictionary) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE

	# スタイル（StyleBoxFlat）
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.13, 0.20)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.2, 0.3)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	card.add_theme_stylebox_override("panel", style)

	# カード内レイアウト
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	# カラーバー（環境テーマカラー）
	var color_bar: ColorRect = ColorRect.new()
	color_bar.color = env["color"]
	color_bar.custom_minimum_size = Vector2(0, 6)
	var color_bar_style: StyleBoxFlat = StyleBoxFlat.new()
	color_bar_style.bg_color = env["color"]
	color_bar_style.corner_radius_top_left = 4
	color_bar_style.corner_radius_top_right = 4
	color_bar_style.corner_radius_bottom_left = 4
	color_bar_style.corner_radius_bottom_right = 4
	var color_panel: PanelContainer = PanelContainer.new()
	color_panel.custom_minimum_size = Vector2(0, 6)
	color_panel.add_theme_stylebox_override("panel", color_bar_style)
	vbox.add_child(color_panel)

	# アイコン
	var icon_label: Label = Label.new()
	icon_label.text = env["icon"]
	icon_label.add_theme_font_size_override("font_size", 36)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_label)

	# 環境名
	var name_label: Label = Label.new()
	name_label.text = env["label"]
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# タップ検出ボタン（透明オーバーレイ）
	var tap_btn: Button = Button.new()
	tap_btn.set_anchors_preset(PRESET_FULL_RECT)
	tap_btn.flat = true
	tap_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var env_key: String = env["key"]
	tap_btn.pressed.connect(func() -> void: _on_env_selected(env_key))
	card.add_child(tap_btn)

	return card


func _on_env_selected(env_key: String) -> void:
	if env_key == _selected_env:
		return
	_selected_env = env_key
	_update_selection_visuals()
	environment_changed.emit(env_key)


func _update_selection_visuals() -> void:
	for key: String in _cards:
		var card: PanelContainer = _cards[key]
		var style: StyleBoxFlat = card.get_theme_stylebox("panel") as StyleBoxFlat
		if not style:
			continue

		if key == _selected_env:
			# 選択中: テーマカラーのボーダー + 明るめ背景
			var env_color: Color = _get_env_color(key)
			style.border_color = env_color
			style.bg_color = Color(env_color.r * 0.25, env_color.g * 0.25, env_color.b * 0.25, 1.0)
		else:
			# 非選択: 暗いボーダー + デフォルト背景
			style.border_color = Color(0.2, 0.2, 0.3)
			style.bg_color = Color(0.12, 0.13, 0.20)


func _get_env_color(env_key: String) -> Color:
	for env: Dictionary in ENVIRONMENTS:
		if env["key"] == env_key:
			return env["color"]
	return Color.WHITE


## 指定環境の背景ティントカラーを返す（SubViewport/PetArea用）
static func get_bg_tint(env_key: String) -> Color:
	for env: Dictionary in ENVIRONMENTS:
		if env["key"] == env_key:
			return env["bg_tint"]
	return Color(0.08, 0.09, 0.14)
