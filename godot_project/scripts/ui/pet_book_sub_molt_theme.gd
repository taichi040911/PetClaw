## PetBookSubMoltTheme — SubMoltテーマ定義・管理
## 5つのSubMolt（ForestWhispers / AfterlifeEchoes / BreedingCircle / LanguageRebellion / EcosystemPulse）
## 各SubMoltの背景色・カードスタイル・粒子設定・ハイライト色を統合管理
class_name PetBookSubMoltTheme
extends RefCounted

# === テーマID一覧 ===
enum SubMoltId {
	FOREST_WHISPERS,
	AFTERLIFE_ECHOES,
	BREEDING_CIRCLE,
	LANGUAGE_REBELLION,
	ECOSYSTEM_PULSE,
}

# === テーマデータ構造 ===
var theme_id: String = ""
var display_name: String = ""
var description: String = ""

# 背景
var bg_color: Color = Color("#1A1B2E")
var bg_secondary: Color = Color("#15162A")

# カードスタイル
var card_bg_color: Color = Color("#252640")
var card_border_color: Color = Color("#3A3A5C")
var card_corner_radius: int = 8
var card_glow_color: Color = Color.TRANSPARENT
var card_glow_intensity: float = 0.0

# テキスト
var text_highlight_color: Color = Color("#6C7EFF")
var text_accent_color: Color = Color("#6C7EFF")
var suffix_color: Color = Color("#6C7EFF")
var rebel_text_color: Color = Color("#FF4444")

# 粒子
var env_particle_color: Color = Color("#5CAA5C")
var env_particle_color_end: Color = Color("#3A7A3A")
var env_particle_amount: int = 15
var env_particle_lifetime: float = 6.0
var env_particle_gravity: Vector2 = Vector2(0, 10)
var env_particle_scale_min: float = 0.3
var env_particle_scale_max: float = 0.8

# イベント粒子
var event_particle_configs: Dictionary = {}

# アニメーション
var entrance_style: String = "fade"  # "fade" | "slide_up" | "glitch" | "bloom"
var card_entrance_duration: float = 0.3

# ParallaxBackground色
var parallax_silhouette_color: Color = Color("#0D0E1A")
var parallax_mid_alpha: float = 0.3


# === ファクトリーメソッド ===
static func create(id: SubMoltId) -> PetBookSubMoltTheme:
	match id:
		SubMoltId.FOREST_WHISPERS:
			return _create_forest_whispers()
		SubMoltId.AFTERLIFE_ECHOES:
			return _create_afterlife_echoes()
		SubMoltId.BREEDING_CIRCLE:
			return _create_breeding_circle()
		SubMoltId.LANGUAGE_REBELLION:
			return _create_language_rebellion()
		SubMoltId.ECOSYSTEM_PULSE:
			return _create_ecosystem_pulse()
	return _create_forest_whispers()  # デフォルト


static func create_by_name(name: String) -> PetBookSubMoltTheme:
	## SubMolt名からテーマを取得
	match name:
		"#ForestWhispers", "ForestWhispers", "forest_whispers":
			return create(SubMoltId.FOREST_WHISPERS)
		"#AfterlifeEchoes", "AfterlifeEchoes", "afterlife_echoes":
			return create(SubMoltId.AFTERLIFE_ECHOES)
		"#BreedingCircle", "BreedingCircle", "breeding_circle":
			return create(SubMoltId.BREEDING_CIRCLE)
		"#LanguageRebellion", "LanguageRebellion", "language_rebellion":
			return create(SubMoltId.LANGUAGE_REBELLION)
		"#EcosystemPulse", "EcosystemPulse", "ecosystem_pulse":
			return create(SubMoltId.ECOSYSTEM_PULSE)
	# DailyPetLife等のデフォルトはForestWhispers
	return create(SubMoltId.FOREST_WHISPERS)


static func get_all_themes() -> Array[PetBookSubMoltTheme]:
	## 全テーマを取得
	var themes: Array[PetBookSubMoltTheme] = []
	for id in SubMoltId.values():
		themes.append(create(id))
	return themes


# === 各テーマの定義 ===

static func _create_forest_whispers() -> PetBookSubMoltTheme:
	var t := PetBookSubMoltTheme.new()
	t.theme_id = "forest_whispers"
	t.display_name = "#ForestWhispers"
	t.description = "森のささやき — 自然・成長・好奇心"

	# 背景: 柔らかい緑基調
	t.bg_color = Color("#1A2E1A")
	t.bg_secondary = Color("#152515")
	t.parallax_silhouette_color = Color("#0A150A")

	# カード: 明るい緑〜ベージュ + 木目感
	t.card_bg_color = Color("#2A3A28")
	t.card_border_color = Color("#4A6A42")
	t.card_corner_radius = 10
	t.card_glow_color = Color.TRANSPARENT
	t.card_glow_intensity = 0.0

	# テキスト: 新語は柔らかい緑
	t.text_highlight_color = Color("#7BC67B")
	t.text_accent_color = Color("#88CC66")
	t.suffix_color = Color("#7BC67B")
	t.rebel_text_color = Color("#CC8844")

	# 環境粒子: 緑の葉 + 光の粒
	t.env_particle_color = Color("#5CAA5C")
	t.env_particle_color_end = Color("#3A7A3A")
	t.env_particle_amount = 20
	t.env_particle_lifetime = 8.0
	t.env_particle_gravity = Vector2(5, 15)  # ゆっくり落下+微風
	t.env_particle_scale_min = 0.3
	t.env_particle_scale_max = 0.8

	# イベント粒子
	t.event_particle_configs = {
		"new_post": {"color": Color("#AADD88"), "amount": 8, "lifetime": 1.5},
		"curiosity": {"color": Color("#FFD700"), "amount": 12, "lifetime": 1.0},
		"growth": {"color": Color("#88CC44"), "amount": 15, "lifetime": 2.0},
	}

	t.entrance_style = "fade"
	t.card_entrance_duration = 0.3
	return t


static func _create_afterlife_echoes() -> PetBookSubMoltTheme:
	var t := PetBookSubMoltTheme.new()
	t.theme_id = "afterlife_echoes"
	t.display_name = "#AfterlifeEchoes"
	t.description = "死と再生の残響 — 生き死に・老化・蘇生"

	# 背景: 暗い紫〜灰色基調
	t.bg_color = Color("#1A152E")
	t.bg_secondary = Color("#120E22")
	t.parallax_silhouette_color = Color("#08060F")

	# カード: 半透明の暗い枠
	t.card_bg_color = Color("#252040")
	t.card_border_color = Color("#443366")
	t.card_corner_radius = 6
	t.card_glow_color = Color("#8866AA")
	t.card_glow_intensity = 0.15

	# テキスト: 死・蘇生関連語は淡い青白
	t.text_highlight_color = Color("#AABBDD")
	t.text_accent_color = Color("#9988CC")
	t.suffix_color = Color("#AABBDD")
	t.rebel_text_color = Color("#DD6666")

	# 環境粒子: 浮遊する淡い光（幽玄）
	t.env_particle_color = Color("#8866AA")
	t.env_particle_color_end = Color("#443366")
	t.env_particle_amount = 12
	t.env_particle_lifetime = 6.0
	t.env_particle_gravity = Vector2(0, -3)  # 上昇する魂の光
	t.env_particle_scale_min = 0.2
	t.env_particle_scale_max = 0.5

	# イベント粒子
	t.event_particle_configs = {
		"death": {"color": Color("#443333"), "amount": 25, "lifetime": 4.0,
				  "gravity": Vector2(0, -8), "one_shot": true},
		"resurrection": {"color": Color("#FFFFDD"), "amount": 40, "lifetime": 2.0,
						 "gravity": Vector2(0, -30), "one_shot": true, "explosiveness": 0.9},
		"resurrection_burst": {"color": Color("#FFDDFF"), "amount": 50, "lifetime": 1.5,
							   "gravity": Vector2(0, -40), "one_shot": true, "explosiveness": 1.0},
		"aging": {"color": Color("#555555"), "amount": 10, "lifetime": 3.0,
				  "gravity": Vector2(0, 5)},
		"memorial_glow": {"color": Color("#FFD700"), "amount": 20, "lifetime": 3.0,
						  "gravity": Vector2(0, -5)},
		"void_whisper": {"color": Color("#332244"), "amount": 8, "lifetime": 5.0,
						 "gravity": Vector2(0, -1)},
		"soul_thread": {"color": Color("#AABBFF"), "amount": 12, "lifetime": 3.5,
						"gravity": Vector2(0, -6), "one_shot": true, "explosiveness": 0.4},
	}

	t.entrance_style = "fade"
	t.card_entrance_duration = 0.5  # ゆっくりフェードイン
	return t


static func _create_breeding_circle() -> PetBookSubMoltTheme:
	var t := PetBookSubMoltTheme.new()
	t.theme_id = "breeding_circle"
	t.display_name = "#BreedingCircle"
	t.description = "繁殖の輪 — 交配・遺伝・家族"

	# 背景: 暖かいピンク〜オレンジ基調
	t.bg_color = Color("#2E1A22")
	t.bg_secondary = Color("#221518")
	t.parallax_silhouette_color = Color("#0F0A0C")

	# カード: 柔らかい丸み + ピンクグロー
	t.card_bg_color = Color("#352A30")
	t.card_border_color = Color("#AA6688")
	t.card_corner_radius = 16
	t.card_glow_color = Color("#FF88AA")
	t.card_glow_intensity = 0.2

	# テキスト: 遺伝・家族関連語は暖かいオレンジ
	t.text_highlight_color = Color("#FFAA66")
	t.text_accent_color = Color("#FF88AA")
	t.suffix_color = Color("#FFAA66")
	t.rebel_text_color = Color("#FF6666")

	# 環境粒子: ハート・花びら
	t.env_particle_color = Color("#FF88AA")
	t.env_particle_color_end = Color("#FFAACC")
	t.env_particle_amount = 15
	t.env_particle_lifetime = 5.0
	t.env_particle_gravity = Vector2(3, 10)  # ゆっくり降る花びら
	t.env_particle_scale_min = 0.2
	t.env_particle_scale_max = 0.6

	# イベント粒子
	t.event_particle_configs = {
		"breeding": {"color": Color("#FF88AA"), "amount": 30, "lifetime": 2.0,
					 "gravity": Vector2(0, -10), "one_shot": true, "explosiveness": 0.7},
		"birth": {"color": Color("#FFDDAA"), "amount": 50, "lifetime": 1.5,
				  "gravity": Vector2(0, 0), "one_shot": true, "explosiveness": 1.0},
		"bloom_burst": {"color": Color("#FFAACC"), "amount": 40, "lifetime": 1.8,
						"gravity": Vector2(0, -5), "one_shot": true, "explosiveness": 0.85},
		"genetics": {"color": Color("#FFD700"), "amount": 15, "lifetime": 2.0,
					 "gravity": Vector2(0, -8)},
		"twin_birth": {"color": Color("#FFCC88"), "amount": 60, "lifetime": 2.0,
					   "gravity": Vector2(0, 0), "one_shot": true, "explosiveness": 1.0},
		"nest_warmth": {"color": Color("#FF9977"), "amount": 20, "lifetime": 3.0,
						"gravity": Vector2(0, 2)},
		"child_departure": {"color": Color("#FFAADD"), "amount": 15, "lifetime": 4.0,
							"gravity": Vector2(3, -10), "one_shot": true},
	}

	t.entrance_style = "bloom"
	t.card_entrance_duration = 0.35
	return t


static func _create_language_rebellion() -> PetBookSubMoltTheme:
	var t := PetBookSubMoltTheme.new()
	t.theme_id = "language_rebellion"
	t.display_name = "#LanguageRebellion"
	t.description = "言語の反乱 — 独自言語・反乱・哲学"

	# 背景: ダークモード（黒〜深い紫）
	t.bg_color = Color("#0D0E1A")
	t.bg_secondary = Color("#0A0A15")
	t.parallax_silhouette_color = Color("#050508")

	# カード: シャープな枠 + 新語部分グロー
	t.card_bg_color = Color("#1A1A30")
	t.card_border_color = Color("#6C3FAA")
	t.card_corner_radius = 2  # シャープ
	t.card_glow_color = Color("#AA66FF")
	t.card_glow_intensity = 0.25

	# テキスト: 独自言語は鮮やかな紫〜シアン
	t.text_highlight_color = Color("#AA66FF")
	t.text_accent_color = Color("#66FFFF")
	t.suffix_color = Color("#AA66FF")
	t.rebel_text_color = Color("#FF4444")

	# 環境粒子: 微かな紫スパーク
	t.env_particle_color = Color("#6C3FAA")
	t.env_particle_color_end = Color("#3A1A6A")
	t.env_particle_amount = 8
	t.env_particle_lifetime = 3.0
	t.env_particle_gravity = Vector2(0, 0)  # ランダム浮遊
	t.env_particle_scale_min = 0.1
	t.env_particle_scale_max = 0.3

	# イベント粒子
	t.event_particle_configs = {
		"new_word": {"color": Color("#AA66FF"), "amount": 30, "lifetime": 1.0,
					 "gravity": Vector2(0, -15), "one_shot": true, "explosiveness": 0.8},
		"rebellion_spark": {"color": Color("#FF4444"), "amount": 25, "lifetime": 1.5,
							"gravity": Vector2(0, -8), "one_shot": true, "explosiveness": 0.9},
		"rebel_post": {"color": Color("#FF4444"), "amount": 20, "lifetime": 2.0,
					   "gravity": Vector2(0, -5), "one_shot": true},
		"philosophy": {"color": Color("#66FFFF"), "amount": 10, "lifetime": 2.5,
					   "gravity": Vector2(0, -2)},
		"word_forge_flash": {"color": Color("#FFAA33"), "amount": 35, "lifetime": 0.8,
							 "gravity": Vector2(0, -20), "one_shot": true, "explosiveness": 1.0},
		"syntax_break": {"color": Color("#FF6666"), "amount": 15, "lifetime": 1.2,
						 "gravity": Vector2(0, 0), "one_shot": true, "explosiveness": 0.6},
		"solidarity_pulse": {"color": Color("#AA88FF"), "amount": 20, "lifetime": 2.0,
							 "gravity": Vector2(0, -3)},
	}

	t.entrance_style = "glitch"
	t.card_entrance_duration = 0.2  # 素早いグリッチ入場
	return t


static func _create_ecosystem_pulse() -> PetBookSubMoltTheme:
	var t := PetBookSubMoltTheme.new()
	t.theme_id = "ecosystem_pulse"
	t.display_name = "#EcosystemPulse"
	t.description = "生態系の鼓動 — 環境・体調・全体俯瞰"

	# 背景: 環境に応じて動的変化（デフォルトは森）
	t.bg_color = Color("#1A2E1A")
	t.bg_secondary = Color("#152515")
	t.parallax_silhouette_color = Color("#0A150A")

	# カード: シンプル＆クリーン
	t.card_bg_color = Color("#222835")
	t.card_border_color = Color("#5C8CAA")
	t.card_corner_radius = 8
	t.card_glow_color = Color.TRANSPARENT
	t.card_glow_intensity = 0.0

	# テキスト: 環境色で強調
	t.text_highlight_color = Color("#5CAA5C")
	t.text_accent_color = Color("#5C8CAA")
	t.suffix_color = Color("#88AACC")
	t.rebel_text_color = Color("#FF6644")

	# 環境粒子: 環境に応じて変化
	t.env_particle_color = Color("#5CAA5C")
	t.env_particle_color_end = Color("#3A7A3A")
	t.env_particle_amount = 15
	t.env_particle_lifetime = 6.0
	t.env_particle_gravity = Vector2(0, 10)
	t.env_particle_scale_min = 0.2
	t.env_particle_scale_max = 0.6

	t.event_particle_configs = {
		"environment_change": {"color": Color("#FFFFFF"), "amount": 25, "lifetime": 2.0,
							   "one_shot": true, "explosiveness": 0.5},
		"health_change": {"color": Color("#88FF88"), "amount": 12, "lifetime": 1.5},
		"migration": {"color": Color("#88AACC"), "amount": 20, "lifetime": 2.5,
					  "gravity": Vector2(10, -5), "one_shot": true},
		"disaster_warning": {"color": Color("#FF6644"), "amount": 35, "lifetime": 1.0,
							 "gravity": Vector2(0, 0), "one_shot": true, "explosiveness": 1.0},
		"population_shift": {"color": Color("#AADDAA"), "amount": 15, "lifetime": 2.0,
							 "gravity": Vector2(0, -3)},
	}

	t.entrance_style = "slide_up"
	t.card_entrance_duration = 0.25
	return t


# === 環境連動（EcosystemPulse専用） ===
func apply_environment_override(environment: String) -> void:
	## EcosystemPulseテーマの環境別色を適用
	if theme_id != "ecosystem_pulse":
		return

	match environment:
		"forest":
			bg_color = Color("#1A2E1A")
			text_highlight_color = Color("#5CAA5C")
			text_accent_color = Color("#88CC66")
			card_border_color = Color("#4A6A42")
			env_particle_color = Color("#5CAA5C")
			env_particle_color_end = Color("#3A7A3A")
		"ocean":
			bg_color = Color("#1A1A2E")
			text_highlight_color = Color("#5C8CAA")
			text_accent_color = Color("#66AACC")
			card_border_color = Color("#4A5A8A")
			env_particle_color = Color("#5C8CAA")
			env_particle_color_end = Color("#3A5A8A")
		"mountain":
			bg_color = Color("#2E2E2E")
			text_highlight_color = Color("#AAAACC")
			text_accent_color = Color("#CCCCDD")
			card_border_color = Color("#8888AA")
			env_particle_color = Color("#CCCCDD")
			env_particle_color_end = Color("#888899")
		"desert":
			bg_color = Color("#2E2A1A")
			text_highlight_color = Color("#CCAA66")
			text_accent_color = Color("#DDBB77")
			card_border_color = Color("#AA8844")
			env_particle_color = Color("#CCAA66")
			env_particle_color_end = Color("#886633")
		"cave":
			bg_color = Color("#151518")
			text_highlight_color = Color("#8877AA")
			text_accent_color = Color("#AA99CC")
			card_border_color = Color("#665588")
			env_particle_color = Color("#8877AA")
			env_particle_color_end = Color("#554466")
		"meadow":
			bg_color = Color("#1E2E1A")
			text_highlight_color = Color("#88CC66")
			text_accent_color = Color("#AADD88")
			card_border_color = Color("#66AA44")
			env_particle_color = Color("#88CC66")
			env_particle_color_end = Color("#55AA33")


# === StyleBox生成ユーティリティ ===
func create_card_stylebox() -> StyleBoxFlat:
	## テーマに基づくカード用StyleBoxを生成
	var style := StyleBoxFlat.new()
	style.bg_color = card_bg_color
	style.border_color = card_border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(card_corner_radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10

	# グロー（shadow_colorで代用）
	if card_glow_color != Color.TRANSPARENT:
		style.shadow_color = Color(card_glow_color, card_glow_intensity)
		style.shadow_size = 4
		style.shadow_offset = Vector2(0, 0)

	return style


func create_bg_stylebox() -> StyleBoxFlat:
	## テーマに基づく背景用StyleBoxを生成
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	return style


func create_header_stylebox() -> StyleBoxFlat:
	## テーマに基づくヘッダー用StyleBoxを生成
	var style := StyleBoxFlat.new()
	style.bg_color = bg_secondary
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func create_sidebar_stylebox() -> StyleBoxFlat:
	## テーマに基づくサイドバー用StyleBoxを生成
	var style := StyleBoxFlat.new()
	style.bg_color = Color(bg_secondary, 0.8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


# === SubMolt自動推薦 ===
static func recommend_for_post(post) -> String:
	## 投稿内容から最適なSubMolt名を推薦
	## post: PetBookPost（型注釈避け：循環参照防止）
	if post.post_type == 4:  # MEMORIAL
		return "#AfterlifeEchoes"
	if post.post_type == 3:  # REBEL
		return "#LanguageRebellion"
	if post.post_type == 2:  # REPLY
		return "#ForestWhispers"  # 返信はデフォルト
	if post.post_type == 1:  # EVENT
		if post.triggered_by_event in ["birth", "breeding"]:
			return "#BreedingCircle"
		if post.triggered_by_event.begins_with("death"):
			return "#AfterlifeEchoes"
		if post.triggered_by_event == "evolution":
			return "#EcosystemPulse"
		if post.triggered_by_event == "disaster":
			return "#EcosystemPulse"
	# DAILY + 環境情報あり → EcosystemPulse
	if post.environment != "":
		return "#EcosystemPulse"
	# 新語・接尾辞多い → LanguageRebellion
	if not post.rebel_expressions.is_empty() or post.suffixes_used.size() >= 3:
		return "#LanguageRebellion"
	return "#ForestWhispers"


# === セーブ/ロード（現SubMoltの保存用） ===
func to_dict() -> Dictionary:
	return {
		"theme_id": theme_id,
		"display_name": display_name,
	}


static func from_dict(data: Dictionary) -> PetBookSubMoltTheme:
	var name: String = data.get("display_name", "#ForestWhispers")
	return create_by_name(name)
