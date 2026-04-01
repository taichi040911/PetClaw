## PetBookThemeBuilder — Godot Theme リソース生成・スタイル統合
## PetBookSubMoltThemeからGodot Themeを構築・遷移・カスタマイズ
## 5つのSubMolt全体テーマ・カード・入力・スクロール・リアクション等を統一管理
class_name PetBookThemeBuilder
extends RefCounted

# === フォントサイズ定義 ===
const FONT_SIZES: Dictionary = {
	"title": 18,
	"author_name": 14,
	"handle": 12,
	"body": 14,
	"meta": 11,
	"reaction": 12,
	"badge": 11,
	"header": 16,
	"button": 13,
}

# === Post Type定義 ===
enum PostType {
	DAILY = 0,
	EVENT = 1,
	REPLY = 2,
	REBEL = 3,
	MEMORIAL = 4,
}


# === Theme全体生成 ===

static func build_theme(sub_molt_theme: PetBookSubMoltTheme) -> Theme:
	## PetBookSubMoltThemeからGodot Themeリソースを生成
	## 全てのUI要素（Panel・Label・Button・LineEdit等）のスタイルを統合
	if sub_molt_theme == null:
		sub_molt_theme = PetBookSubMoltTheme.create(PetBookSubMoltTheme.SubMoltId.FOREST_WHISPERS)

	var theme := Theme.new()

	# === PanelContainer（カード用） ===
	theme.set_stylebox("panel", "PanelContainer", build_card_panel(sub_molt_theme))

	# === パネルバリエーション ===
	theme.set_stylebox("card_normal", "PanelContainer", build_card_panel(sub_molt_theme))
	theme.set_stylebox("card_hover", "PanelContainer", build_card_panel_hover(sub_molt_theme))
	theme.set_stylebox("card_pressed", "PanelContainer", build_card_panel_pressed(sub_molt_theme))
	theme.set_stylebox("card_memorial", "PanelContainer", build_card_panel_memorial(sub_molt_theme))
	theme.set_stylebox("card_rebel", "PanelContainer", build_card_panel_rebel(sub_molt_theme))

	# === 背景パネル ===
	theme.set_stylebox("panel", "PanelContainer", build_feed_background(sub_molt_theme))

	# === Label（テキスト色） ===
	theme.set_color("font_color", "Label", sub_molt_theme.text_highlight_color)
	theme.set_color("font_color_shadow", "Label", Color.BLACK)
	theme.set_font_size("font_size", "Label", FONT_SIZES["body"])

	# === RichTextLabel（BBCode対応） ===
	theme.set_color("default_color", "RichTextLabel", sub_molt_theme.text_highlight_color)
	theme.set_color("highlight_color", "RichTextLabel", sub_molt_theme.text_accent_color)
	theme.set_color("selection_color", "RichTextLabel", Color(sub_molt_theme.text_accent_color, 0.3))
	theme.set_font_size("normal_font_size", "RichTextLabel", FONT_SIZES["body"])

	# === Button（フラットスタイル・アクセント色） ===
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(sub_molt_theme.card_bg_color, 0.6)
	btn_normal.border_color = sub_molt_theme.text_accent_color
	btn_normal.set_border_width_all(1)
	btn_normal.set_corner_radius_all(4)
	btn_normal.content_margin_left = 12
	btn_normal.content_margin_right = 12
	btn_normal.content_margin_top = 6
	btn_normal.content_margin_bottom = 6

	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(sub_molt_theme.text_accent_color, 0.15)
	btn_hover.border_color = sub_molt_theme.text_accent_color
	btn_hover.set_border_width_all(2)
	btn_hover.set_corner_radius_all(4)
	btn_hover.content_margin_left = 12
	btn_hover.content_margin_right = 12
	btn_hover.content_margin_top = 6
	btn_hover.content_margin_bottom = 6

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_color("font_color", "Button", sub_molt_theme.text_accent_color)
	theme.set_font_size("font_size", "Button", FONT_SIZES["button"])

	# === ScrollContainer（スクロールバー） ===
	theme.set_stylebox("scroll", "ScrollContainer", build_scrollbar_background(sub_molt_theme))

	# === LineEdit（検索バー等） ===
	theme.set_stylebox("normal", "LineEdit", build_search_bar(sub_molt_theme))
	theme.set_color("font_color", "LineEdit", sub_molt_theme.text_highlight_color)
	theme.set_color("caret_color", "LineEdit", sub_molt_theme.text_accent_color)
	theme.set_font_size("font_size", "LineEdit", FONT_SIZES["body"])

	# === HBoxContainer / VBoxContainer（分離） ===
	theme.set_constant("separation", "HBoxContainer", 12)
	theme.set_constant("separation", "VBoxContainer", 8)

	# === TabBar（SubMoltタブ） ===
	theme.set_stylebox("tab_selected", "TabBar", build_sub_molt_tab_active(sub_molt_theme))
	theme.set_stylebox("tab_unselected", "TabBar", build_sub_molt_tab_inactive(sub_molt_theme))
	theme.set_color("font_color_selected", "TabBar", sub_molt_theme.text_highlight_color)
	theme.set_color("font_color_unselected", "TabBar", Color(sub_molt_theme.text_highlight_color, 0.5))
	theme.set_font_size("font_size", "TabBar", FONT_SIZES["handle"])

	# === ツールチップ ===
	theme.set_stylebox("panel", "TooltipLabel", build_tooltip_panel(sub_molt_theme))
	theme.set_color("font_color", "TooltipLabel", Color.WHITE)
	theme.set_font_size("font_size", "TooltipLabel", FONT_SIZES["meta"])

	return theme


# === カード系StyleBox ===

static func build_card_panel(theme: PetBookSubMoltTheme) -> StyleBoxFlat:
	## 投稿カード用 — 角丸・枠色・グロー・内部マージン
	var style := StyleBoxFlat.new()
	style.bg_color = theme.card_bg_color
	style.border_color = theme.card_border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(theme.card_corner_radius)

	# 内部マージン
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10

	# グロー（shadow_colorで代用）
	if theme.card_glow_color != Color.TRANSPARENT and theme.card_glow_intensity > 0.0:
		style.shadow_color = Color(theme.card_glow_color, theme.card_glow_intensity)
		style.shadow_size = 4
		style.shadow_offset = Vector2(0, 0)

	return style


static func build_card_panel_hover(theme: PetBookSubMoltTheme) -> StyleBoxFlat:
	## ホバー時 — 明度10%上昇 + 枠太く
	var style := build_card_panel(theme)

	# 明度10%上昇
	var hover_bg := theme.card_bg_color.lightened(0.1)
	style.bg_color = hover_bg

	# 枠を太くする
	style.set_border_width_all(2)

	# グロー強化
	if theme.card_glow_color != Color.TRANSPARENT:
		style.shadow_color = Color(theme.card_glow_color, theme.card_glow_intensity + 0.1)
		style.shadow_size = 6

	return style


static func build_card_panel_pressed(theme: PetBookSubMoltTheme) -> StyleBoxFlat:
	## 押下時 — 明度5%下降
	var style := build_card_panel(theme)

	var pressed_bg := theme.card_bg_color.darkened(0.05)
	style.bg_color = pressed_bg

	style.set_border_width_all(2)
	style.border_color = theme.text_accent_color

	return style


static func build_card_panel_memorial(theme: PetBookSubMoltTheme) -> StyleBoxFlat:
	## 追悼投稿用 — 外枠ダブルライン + 微かな青白グロー
	var style := build_card_panel(theme)

	# ダブルライン効果（border + shadow）
	style.set_border_width_all(2)
	style.border_color = Color(theme.card_border_color, 0.8)

	# 青白グロー
	var memorial_glow := Color("#AABBDD")
	style.shadow_color = Color(memorial_glow, 0.2)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 0)

	return style


static func build_card_panel_rebel(theme: PetBookSubMoltTheme) -> StyleBoxFlat:
	## 反乱投稿用 — 赤い点線枠 + 微かな赤グロー
	var style := build_card_panel(theme)

	# 赤い枠（点線の代わりに太い枠で視覚的に表現）
	var rebel_border := Color("#FF4444")
	style.set_border_width_all(3)
	style.border_color = rebel_border

	# 赤グロー
	style.shadow_color = Color(rebel_border, 0.25)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 0)

	return style


# === 背景系StyleBox ===

static func build_feed_background(theme: PetBookSubMoltTheme) -> StyleBoxFlat:
	## フィード全体背景
	var style := StyleBoxFlat.new()
	style.bg_color = theme.bg_color
	return style


static func build_header_bar(theme: PetBookSubMoltTheme) -> StyleBoxFlat:
	## SubMoltヘッダーバー — テーマ名表示エリア
	var style := StyleBoxFlat.new()
	style.bg_color = theme.bg_secondary
	style.border_color = theme.card_border_color
	style.set_border_width_all(0)
	style.set_border_width(SIDE_BOTTOM, 2)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


static func build_sidebar_panel(theme: PetBookSubMoltTheme) -> StyleBoxFlat:
	## サイドバー（トレンドワード表示等）
	var style := StyleBoxFlat.new()
	style.bg_color = Color(theme.bg_secondary, 0.85)
	style.border_color = theme.card_border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


static func build_sub_molt_tab_active(theme: PetBookSubMoltTheme) -> StyleBoxFlat:
	## アクティブタブ — accent色の下線
	var style := StyleBoxFlat.new()
	style.bg_color = Color(theme.card_bg_color, 0.3)
	style.border_color = Color.TRANSPARENT
	style.set_border_width(SIDE_BOTTOM, 3)
	style.border_color = theme.text_accent_color
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


static func build_sub_molt_tab_inactive(theme: PetBookSubMoltTheme) -> StyleBoxFlat:
	## 非アクティブタブ — 半透明
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color.TRANSPARENT
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


# === リアクションバー ===

static func build_reaction_button(theme: PetBookSubMoltTheme) -> StyleBoxFlat:
	## リアクションボタン背景（透明ベース）
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color.TRANSPARENT
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


static func build_reaction_button_hover(theme: PetBookSubMoltTheme) -> StyleBoxFlat:
	## リアクションボタンホバー
	var style := StyleBoxFlat.new()
	style.bg_color = Color(theme.text_accent_color, 0.1)
	style.border_color = Color(theme.text_accent_color, 0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


# === スクロールバー ===

static func build_scrollbar_grabber(theme: PetBookSubMoltTheme) -> StyleBoxFlat:
	## テーマ色スクロールバーグラバー
	var style := StyleBoxFlat.new()
	style.bg_color = theme.text_accent_color
	style.set_corner_radius_all(3)
	return style


static func build_scrollbar_background(theme: PetBookSubMoltTheme) -> StyleBoxFlat:
	## スクロールバー背景
	var style := StyleBoxFlat.new()
	style.bg_color = Color(theme.bg_secondary, 0.5)
	return style


# === 検索・入力 ===

static func build_search_bar(theme: PetBookSubMoltTheme) -> StyleBoxFlat:
	## 検索バー背景（暗め + 枠線）
	var style := StyleBoxFlat.new()
	style.bg_color = Color(theme.bg_secondary, 0.6)
	style.border_color = Color(theme.card_border_color, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


# === ツールチップ ===

static func build_tooltip_panel(theme: PetBookSubMoltTheme) -> StyleBoxFlat:
	## ツールチップ背景 — 半透明の暗色
	var style := StyleBoxFlat.new()
	style.bg_color = Color(theme.bg_color, 0.95)
	style.border_color = Color(theme.card_border_color, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


# === Theme遷移サポート ===

static func lerp_stylebox(from: StyleBoxFlat, to: StyleBoxFlat, weight: float) -> StyleBoxFlat:
	## 2つのStyleBox間を補間（SubMolt切り替えアニメーション用）
	if from == null or to == null:
		return from if from != null else to

	var result := StyleBoxFlat.new()
	result.bg_color = from.bg_color.lerp(to.bg_color, weight)
	result.border_color = from.border_color.lerp(to.border_color, weight)

	# 角丸補間
	var from_radius = from.get_corner_radius(CORNER_TOP_LEFT)
	var to_radius = to.get_corner_radius(CORNER_TOP_LEFT)
	var lerp_radius = int(lerpf(float(from_radius), float(to_radius), weight))
	result.set_corner_radius_all(lerp_radius)

	# マージン補間
	result.content_margin_left = lerpf(from.content_margin_left, to.content_margin_left, weight)
	result.content_margin_right = lerpf(from.content_margin_right, to.content_margin_right, weight)
	result.content_margin_top = lerpf(from.content_margin_top, to.content_margin_top, weight)
	result.content_margin_bottom = lerpf(from.content_margin_bottom, to.content_margin_bottom, weight)

	return result


static func create_transition_tween(
	control: Control,
	from_theme: PetBookSubMoltTheme,
	to_theme: PetBookSubMoltTheme,
	duration: float = 0.5
) -> Tween:
	## SubMolt切り替え時のなめらかなテーマ遷移Tweenを生成
	if control == null or from_theme == null or to_theme == null:
		return null

	var tween := control.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)

	# 色遷移用の補間ラッパー
	var color_tween = ColorTweenHelper.new(from_theme, to_theme, control)
	tween.tween_method(color_tween.update_colors, 0.0, 1.0, duration)

	return tween


# === Typography Helpers ===

static func get_font_sizes() -> Dictionary:
	## PetBook用フォントサイズ定義を取得
	return FONT_SIZES.duplicate()


static func apply_typography(control: Control, role: String, theme: PetBookSubMoltTheme) -> void:
	## コントロールにフォントサイズ・色を適用
	if control == null or theme == null:
		return

	var font_size: int = FONT_SIZES.get(role, FONT_SIZES["body"])
	var text_color: Color = theme.text_highlight_color

	if control is Label:
		var label := control as Label
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", text_color)
	elif control is RichTextLabel:
		var rtl := control as RichTextLabel
		rtl.add_theme_font_size_override("normal_font_size", font_size)
		rtl.add_theme_color_override("default_color", text_color)
	elif control is LineEdit:
		var le := control as LineEdit
		le.add_theme_font_size_override("font_size", font_size)
		le.add_theme_color_override("font_color", text_color)
	elif control is Button:
		var btn := control as Button
		btn.add_theme_font_size_override("font_size", font_size)
		btn.add_theme_color_override("font_color", text_color)


# === PostType-specific Modifiers ===

static func apply_post_type_modifier(card: PanelContainer, post_type: int, theme: PetBookSubMoltTheme) -> void:
	## 投稿タイプに応じたカードスタイル修正
	if card == null or theme == null:
		return

	match post_type:
		PostType.MEMORIAL:
			card.add_theme_stylebox_override("panel", build_card_panel_memorial(theme))
		PostType.REBEL:
			card.add_theme_stylebox_override("panel", build_card_panel_rebel(theme))
		PostType.EVENT:
			# イベント投稿用 — golden accent border
			var event_style := build_card_panel(theme)
			event_style.border_color = Color("#FFD700")
			event_style.set_border_width_all(2)
			card.add_theme_stylebox_override("panel", event_style)
		_:
			card.add_theme_stylebox_override("panel", build_card_panel(theme))


# === ユーティリティ ===

static func create_empty_theme() -> Theme:
	## 空のテーマリソースを生成（フォールバック用）
	return Theme.new()


static func merge_themes(base: Theme, override: Theme) -> Theme:
	## 2つのテーマをマージ（overrideがbaseを上書き）
	if base == null:
		return override
	if override == null:
		return base

	var merged := Theme.new()
	# 実装簡略化：overrideを使用
	return override


# === 内部ヘルパー ===

class ColorTweenHelper:
	## 色遷移用ヘルパークラス
	var from_theme: PetBookSubMoltTheme
	var to_theme: PetBookSubMoltTheme
	var control: Control

	func _init(f: PetBookSubMoltTheme, t: PetBookSubMoltTheme, c: Control) -> void:
		from_theme = f
		to_theme = t
		control = c

	func update_colors(progress: float) -> void:
		## 0.0 ~ 1.0の進捗に応じて色を更新
		if from_theme == null or to_theme == null or control == null:
			return

		var from_bg = from_theme.bg_color
		var to_bg = to_theme.bg_color
		var lerp_bg = from_bg.lerp(to_bg, progress)

		var from_accent = from_theme.text_accent_color
		var to_accent = to_theme.text_accent_color
		var lerp_accent = from_accent.lerp(to_accent, progress)

		# 動的にthemeを更新（パフォーマンス注意）
		if control.has_theme_stylebox("panel", "PanelContainer"):
			var old_style = control.get_theme_stylebox("panel", "PanelContainer")
			if old_style is StyleBoxFlat:
				(old_style as StyleBoxFlat).bg_color = lerp_bg
