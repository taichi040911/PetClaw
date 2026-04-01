class_name PetBookPalette
extends RefCounted
## PetBookパレット管理システム
## PetBook（AI専用SNS）の統一カラーパレットを定義・管理するクラス
## 
## 設計哲学：
## P1: 一貫性 × 記憶 = 愛着（ダーク基調 + SubMolt固有色で個性表現）
## P2: API Cost is Physics（全色を静的定数化、ランタイム計算ゼロ）
## P3: Player Agency（5つのSubMoltが色彩の「方言」として機能）
## P4: 10秒フック（高彩度・高コントラストで視認性確保）
## P5: Complexity is Debt（56色に統一、追加時はHSV調和検証）
##
## 関連ドキュメント: KB87_PetBook_Unified_Color_Palette.md
## バージョン: 1.0
## 最終更新: 2026-04-01

## extends Resource (removed — class_name/extends declared at top)

# ============================================================================
# グローバルカラー（全SubMolt共通）
# ============================================================================

## テキスト基本色（全SubMolt共通）
## RGB: (232, 232, 240) | HSV: H:240° S:3% V:94%
static var TEXT_PRIMARY: Color = Color(0.91, 0.91, 0.94)

## テキスト補助色（説明文・メタ情報）
## RGB: (136, 136, 170) | HSV: H:240° S:20% V:67%
static var TEXT_SECONDARY: Color = Color(0.53, 0.53, 0.67)

## テキスト薄め色（無効化・ホバー前状態）
## RGB: (85, 85, 119) | HSV: H:240° S:28% V:47%
static var TEXT_DIM: Color = Color(0.33, 0.33, 0.47)

## 共通カード背景色
## RGB: (37, 38, 64) | HSV: H:236° S:42% V:25%
static var BG_CARD: Color = Color(0.15, 0.15, 0.25)

## 最深背景色（LanguageRebellion系の最暗背景）
## RGB: (13, 14, 26) | HSV: H:233° S:50% V:10%
static var BG_DEEPEST: Color = Color(0.05, 0.05, 0.10)

# ============================================================================
# 感情カラーパレット（全SubMolt共通）
# ============================================================================

## 喜び（Joy）— ハイライト・成功状態
## RGB: (255, 215, 0) | HSV: H:51° S:100% V:100%
static var EMOTION_JOY: Color = Color(1.0, 0.84, 0.0)

## 愛（Love）— アフェクション・繁殖関連
## RGB: (255, 136, 170) | HSV: H:346° S:47% V:100%
static var EMOTION_LOVE: Color = Color(1.0, 0.53, 0.67)

## 悲しみ（Sadness）— 喪・逝去の表現
## RGB: (102, 153, 204) | HSV: H:210° S:50% V:80%
static var EMOTION_SADNESS: Color = Color(0.40, 0.60, 0.80)

## 怒り（Anger）— 反乱・警告・反発
## RGB: (255, 68, 68) | HSV: H:0° S:73% V:100%
static var EMOTION_ANGER: Color = Color(1.0, 0.27, 0.27)

## 恐怖（Fear）— 不安定・ダーク進化
## RGB: (136, 85, 204) | HSV: H:270° S:58% V:80%
static var EMOTION_FEAR: Color = Color(0.53, 0.33, 0.80)

## 好奇心（Curiosity）— 探索・発見
## RGB: (136, 204, 68) | HSV: H:99° S:67% V:80%
static var EMOTION_CURIOSITY: Color = Color(0.53, 0.80, 0.27)

## 誇り（Pride）— 進化・成長の象徴
## RGB: (255, 170, 51) | HSV: H:33° S:80% V:100%
static var EMOTION_PRIDE: Color = Color(1.0, 0.67, 0.20)

## 落ち着き（Calm）— リラックス・平穏
## RGB: (102, 204, 170) | HSV: H:160° S:50% V:80%
static var EMOTION_CALM: Color = Color(0.40, 0.80, 0.67)

## 勇敢（Brave）— 冒険・チャレンジ
## RGB: (255, 136, 68) | HSV: H:20° S:73% V:100%
static var EMOTION_BRAVE: Color = Color(1.0, 0.53, 0.27)

## 好意（Affection）— 親密性・結合
## RGB: (255, 153, 187) | HSV: H:345° S:40% V:100%
static var EMOTION_AFFECTION: Color = Color(1.0, 0.60, 0.73)

## 驚嘆（Wonder）— 進化・変身の瞬間
## RGB: (170, 221, 255) | HSV: H:204° S:33% V:100%
static var EMOTION_WONDER: Color = Color(0.67, 0.87, 1.0)

# ============================================================================
# ポストバッジカラー（全SubMolt共通）
# ============================================================================

## 反乱タグ・#rebellion
## RGB: (255, 68, 68) | HSV: H:0° S:73% V:100%
static var BADGE_REBEL: Color = Color(1.0, 0.27, 0.27)

## 逝去記念・悼み投稿
## RGB: (102, 102, 221) | HSV: H:240° S:54% V:87%
static var BADGE_MEMORIAL: Color = Color(0.40, 0.40, 0.87)

## 生態系イベント・季節イベント
## RGB: (255, 170, 0) | HSV: H:39° S:100% V:100%
static var BADGE_EVENT: Color = Color(1.0, 0.67, 0.0)

# ============================================================================
# SubMolt: ForestWhispers（森のささやき）— 自然・成長・緑系
# ============================================================================

class ForestWhispers:
	## 深い森の暗さ | RGB: (26, 46, 26) | HSV: H:120° S:43% V:18%
	static var BG: Color = Color(0.10, 0.18, 0.10)
	
	## さらに奥深い森 | RGB: (21, 37, 21) | HSV: H:120° S:43% V:14%
	static var BG2: Color = Color(0.08, 0.15, 0.08)
	
	## リーフグリーン | RGB: (42, 58, 40) | HSV: H:113° S:31% V:23%
	static var CARD: Color = Color(0.16, 0.23, 0.16)
	
	## 樹皮色 | RGB: (74, 106, 66) | HSV: H:108° S:38% V:42%
	static var BORDER: Color = Color(0.29, 0.42, 0.26)
	
	## 新芽・若草 | RGB: (123, 198, 123) | HSV: H:120° S:38% V:78%
	static var HIGHLIGHT: Color = Color(0.48, 0.78, 0.48)
	
	## 明るい草原 | RGB: (136, 204, 102) | HSV: H:99° S:50% V:80%
	static var ACCENT: Color = Color(0.53, 0.80, 0.40)
	
	## テキストサフィックス | RGB: (123, 198, 123) | HSV: H:120° S:38% V:78%
	static var SUFFIX: Color = Color(0.48, 0.78, 0.48)
	
	## 木の根・樹液 | RGB: (204, 136, 68) | HSV: H:24° S:67% V:80%
	static var REBEL: Color = Color(0.80, 0.53, 0.27)
	
	## 光合成の粒子 | RGB: (92, 170, 92) | HSV: H:120° S:46% V:67%
	static var PARTICLE: Color = Color(0.36, 0.67, 0.36)

# ============================================================================
# SubMolt: AfterlifeEchoes（来世の響き）— 死・輪廻・紫系
# ============================================================================

class AfterlifeEchoes:
	## 紫のたそがれ | RGB: (26, 21, 46) | HSV: H:253° S:54% V:18%
	static var BG: Color = Color(0.10, 0.08, 0.18)
	
	## 闇の深さ | RGB: (18, 14, 34) | HSV: H:260° S:59% V:13%
	static var BG2: Color = Color(0.07, 0.05, 0.13)
	
	## 薄い紫翳 | RGB: (37, 32, 64) | HSV: H:256° S:50% V:25%
	static var CARD: Color = Color(0.15, 0.13, 0.25)
	
	## 古い絹布 | RGB: (68, 51, 102) | HSV: H:260° S:50% V:40%
	static var BORDER: Color = Color(0.27, 0.20, 0.40)
	
	## 月光 | RGB: (170, 187, 221) | HSV: H:220° S:23% V:87%
	static var HIGHLIGHT: Color = Color(0.67, 0.73, 0.87)
	
	## 紫の星 | RGB: (153, 136, 204) | HSV: H:254° S:33% V:80%
	static var ACCENT: Color = Color(0.60, 0.53, 0.80)
	
	## 月光テキスト | RGB: (170, 187, 221) | HSV: H:220° S:23% V:87%
	static var SUFFIX: Color = Color(0.67, 0.73, 0.87)
	
	## 執着・怨念 | RGB: (221, 102, 102) | HSV: H:0° S:54% V:87%
	static var REBEL: Color = Color(0.87, 0.40, 0.40)
	
	## スピリット・グロー | RGB: (136, 102, 170) | HSV: H:270° S:40% V:67%
	static var GLOW: Color = Color(0.53, 0.40, 0.67)
	
	## 魂の粒子 | RGB: (136, 102, 170) | HSV: H:270° S:40% V:67%
	static var PARTICLE: Color = Color(0.53, 0.40, 0.67)

# ============================================================================
# SubMolt: BreedingCircle（繁殖の輪）— 家族・愛・桃系
# ============================================================================

class BreedingCircle:
	## 深い朱 | RGB: (46, 26, 34) | HSV: H:345° S:43% V:18%
	static var BG: Color = Color(0.18, 0.10, 0.13)
	
	## 暗い朱 | RGB: (34, 21, 24) | HSV: H:347° S:38% V:13%
	static var BG2: Color = Color(0.13, 0.08, 0.09)
	
	## 淡い赤紫 | RGB: (53, 42, 48) | HSV: H:341° S:21% V:21%
	static var CARD: Color = Color(0.21, 0.16, 0.19)
	
	## 古い梅色 | RGB: (170, 102, 136) | HSV: H:331° S:40% V:67%
	static var BORDER: Color = Color(0.67, 0.40, 0.53)
	
	## 暖色オレンジ | RGB: (255, 170, 102) | HSV: H:20° S:60% V:100%
	static var HIGHLIGHT: Color = Color(1.0, 0.67, 0.40)
	
	## 桃色 | RGB: (255, 136, 170) | HSV: H:346° S:47% V:100%
	static var ACCENT: Color = Color(1.0, 0.53, 0.67)
	
	## オレンジサフィックス | RGB: (255, 170, 102) | HSV: H:20° S:60% V:100%
	static var SUFFIX: Color = Color(1.0, 0.67, 0.40)
	
	## 激しい愛・争い | RGB: (255, 102, 102) | HSV: H:0° S:60% V:100%
	static var REBEL: Color = Color(1.0, 0.40, 0.40)
	
	## 愛のグロー | RGB: (255, 136, 170) | HSV: H:346° S:47% V:100%
	static var GLOW: Color = Color(1.0, 0.53, 0.67)
	
	## 愛の粒子（ハート型） | RGB: (255, 136, 170) | HSV: H:346° S:47% V:100%
	static var PARTICLE: Color = Color(1.0, 0.53, 0.67)

# ============================================================================
# SubMolt: LanguageRebellion（言語反乱）— 反乱・言語進化・暗紫＋シアン系
# ============================================================================

class LanguageRebellion:
	## 深夜の虚空 | RGB: (13, 14, 26) | HSV: H:233° S:50% V:10%
	static var BG: Color = Color(0.05, 0.05, 0.10)
	
	## さらに深い虚空 | RGB: (10, 10, 21) | HSV: H:240° S:52% V:8%
	static var BG2: Color = Color(0.04, 0.04, 0.08)
	
	## サイバー紫 | RGB: (26, 26, 48) | HSV: H:240° S:46% V:19%
	static var CARD: Color = Color(0.10, 0.10, 0.19)
	
	## 電磁波紫 | RGB: (108, 63, 170) | HSV: H:267° S:63% V:67%
	static var BORDER: Color = Color(0.42, 0.25, 0.67)
	
	## ネオン紫 | RGB: (170, 102, 255) | HSV: H:270° S:60% V:100%
	static var HIGHLIGHT: Color = Color(0.67, 0.40, 1.0)
	
	## サイバー青緑 | RGB: (102, 255, 255) | HSV: H:180° S:60% V:100%
	static var ACCENT: Color = Color(0.40, 1.0, 1.0)
	
	## ネオン紫テキスト | RGB: (170, 102, 255) | HSV: H:270° S:60% V:100%
	static var SUFFIX: Color = Color(0.67, 0.40, 1.0)
	
	## 反乱の赤 | RGB: (255, 68, 68) | HSV: H:0° S:73% V:100%
	static var REBEL: Color = Color(1.0, 0.27, 0.27)
	
	## ネオン・グロー | RGB: (170, 102, 255) | HSV: H:270° S:60% V:100%
	static var GLOW: Color = Color(0.67, 0.40, 1.0)
	
	## デジタル粒子 | RGB: (108, 63, 170) | HSV: H:267° S:63% V:67%
	static var PARTICLE: Color = Color(0.42, 0.25, 0.67)

# ============================================================================
# SubMolt: EcosystemPulse（生態系パルス）— 環境適応・エコシステム・動的色系
# ============================================================================

class EcosystemPulse:
	## 森がデフォルト | RGB: (26, 46, 26) | HSV: H:120° S:43% V:18%
	static var BG: Color = Color(0.10, 0.18, 0.10)
	
	## 環境に応じて動的（初期値は森）| RGB: (26, 46, 26)
	static var BG2: Color = Color(0.10, 0.18, 0.10)
	
	## ニュートラルスレート | RGB: (34, 40, 53) | HSV: H:222° S:36% V:21%
	static var CARD: Color = Color(0.13, 0.16, 0.21)
	
	## 水のような枠 | RGB: (92, 140, 170) | HSV: H:204° S:46% V:67%
	static var BORDER: Color = Color(0.36, 0.55, 0.67)
	
	## 自然色ハイライト | RGB: (92, 170, 92) | HSV: H:120° S:46% V:67%
	static var HIGHLIGHT: Color = Color(0.36, 0.67, 0.36)
	
	## 空の色 | RGB: (92, 140, 170) | HSV: H:204° S:46% V:67%
	static var ACCENT: Color = Color(0.36, 0.55, 0.67)
	
	## 明るい空 | RGB: (136, 170, 204) | HSV: H:210° S:33% V:80%
	static var SUFFIX: Color = Color(0.53, 0.67, 0.80)
	
	## 火山・活動 | RGB: (255, 102, 68) | HSV: H:16° S:73% V:100%
	static var REBEL: Color = Color(1.0, 0.40, 0.27)
	
	## 環境粒子（適応） | RGB: (92, 170, 92) | HSV: H:120° S:46% V:67%
	static var PARTICLE: Color = Color(0.36, 0.67, 0.36)

# ============================================================================
# 環境別カラーオーバーライド（EcosystemPulse用）
# ============================================================================

## 環境ごとの色上書きセット
static var ENVIRONMENT_OVERRIDES: Dictionary = {
	"forest": {
		"bg2": Color(0.10, 0.18, 0.10),  # #1A2E1A
		"border": Color(0.29, 0.42, 0.26),  # #4A6A42
		"particle": Color(0.36, 0.67, 0.36),  # #5CAA5C
	},
	"ocean": {
		"bg2": Color(0.05, 0.10, 0.18),  # #0D1A2E
		"border": Color(0.29, 0.48, 0.67),  # #4A7AAA
		"particle": Color(0.36, 0.67, 0.67),  # #5CAAAA
	},
	"mountain": {
		"bg2": Color(0.18, 0.16, 0.10),  # #2E2A1A
		"border": Color(0.53, 0.53, 0.42),  # #8A8A6A
		"particle": Color(0.80, 0.80, 0.67),  # #CCCCAA
	},
	"desert": {
		"bg2": Color(0.18, 0.14, 0.09),  # #2E2415
		"border": Color(0.67, 0.53, 0.29),  # #AA8A4A
		"particle": Color(1.0, 0.67, 0.40),  # #FFAA66
	},
	"cave": {
		"bg2": Color(0.06, 0.06, 0.10),  # #0F0F1A
		"border": Color(0.35, 0.35, 0.47),  # #5A5A7A
		"particle": Color(0.53, 0.42, 0.67),  # #8A6AAA
	},
	"meadow": {
		"bg2": Color(0.10, 0.18, 0.09),  # #1A2E15
		"border": Color(0.42, 0.53, 0.29),  # #6A8A4A
		"particle": Color(0.53, 0.80, 0.40),  # #88CC66
	},
}

# ============================================================================
# 感情カラーマップ（辞書参照用）
# ============================================================================

## 感情タグから色を素早く検索できる辞書
static var EMOTION_MAP: Dictionary = {
	"joy": EMOTION_JOY,
	"love": EMOTION_LOVE,
	"sadness": EMOTION_SADNESS,
	"anger": EMOTION_ANGER,
	"fear": EMOTION_FEAR,
	"curiosity": EMOTION_CURIOSITY,
	"pride": EMOTION_PRIDE,
	"calm": EMOTION_CALM,
	"brave": EMOTION_BRAVE,
	"affection": EMOTION_AFFECTION,
	"wonder": EMOTION_WONDER,
}

# ============================================================================
# SubMoltパレット参照
# ============================================================================

## SubMolt IDから完全なカラーセットを検索する辞書
static var SUB_MOLT_PALETTE_MAP: Dictionary = {}

# ============================================================================
# パブリックメソッド
# ============================================================================

## SubMoltに応じた全カラーセットを返す
## @param sub_molt_id: "ForestWhispers", "AfterlifeEchoes" など
## @return: すべての色を含む辞書
static func get_sub_molt_colors(sub_molt_id: String) -> Dictionary:
	match sub_molt_id:
		"ForestWhispers":
			return {
				"bg": ForestWhispers.BG,
				"bg2": ForestWhispers.BG2,
				"card": ForestWhispers.CARD,
				"border": ForestWhispers.BORDER,
				"highlight": ForestWhispers.HIGHLIGHT,
				"accent": ForestWhispers.ACCENT,
				"suffix": ForestWhispers.SUFFIX,
				"rebel": ForestWhispers.REBEL,
				"particle": ForestWhispers.PARTICLE,
			}
		"AfterlifeEchoes":
			return {
				"bg": AfterlifeEchoes.BG,
				"bg2": AfterlifeEchoes.BG2,
				"card": AfterlifeEchoes.CARD,
				"border": AfterlifeEchoes.BORDER,
				"highlight": AfterlifeEchoes.HIGHLIGHT,
				"accent": AfterlifeEchoes.ACCENT,
				"suffix": AfterlifeEchoes.SUFFIX,
				"rebel": AfterlifeEchoes.REBEL,
				"glow": AfterlifeEchoes.GLOW,
				"particle": AfterlifeEchoes.PARTICLE,
			}
		"BreedingCircle":
			return {
				"bg": BreedingCircle.BG,
				"bg2": BreedingCircle.BG2,
				"card": BreedingCircle.CARD,
				"border": BreedingCircle.BORDER,
				"highlight": BreedingCircle.HIGHLIGHT,
				"accent": BreedingCircle.ACCENT,
				"suffix": BreedingCircle.SUFFIX,
				"rebel": BreedingCircle.REBEL,
				"glow": BreedingCircle.GLOW,
				"particle": BreedingCircle.PARTICLE,
			}
		"LanguageRebellion":
			return {
				"bg": LanguageRebellion.BG,
				"bg2": LanguageRebellion.BG2,
				"card": LanguageRebellion.CARD,
				"border": LanguageRebellion.BORDER,
				"highlight": LanguageRebellion.HIGHLIGHT,
				"accent": LanguageRebellion.ACCENT,
				"suffix": LanguageRebellion.SUFFIX,
				"rebel": LanguageRebellion.REBEL,
				"glow": LanguageRebellion.GLOW,
				"particle": LanguageRebellion.PARTICLE,
			}
		"EcosystemPulse":
			return {
				"bg": EcosystemPulse.BG,
				"bg2": EcosystemPulse.BG2,
				"card": EcosystemPulse.CARD,
				"border": EcosystemPulse.BORDER,
				"highlight": EcosystemPulse.HIGHLIGHT,
				"accent": EcosystemPulse.ACCENT,
				"suffix": EcosystemPulse.SUFFIX,
				"rebel": EcosystemPulse.REBEL,
				"particle": EcosystemPulse.PARTICLE,
			}
		_:
			# デフォルトはForestWhispers
			return get_sub_molt_colors("ForestWhispers")

## 感情タグから対応する色を返す
## @param emotion: "joy", "love", "sadness" など
## @return: Color | デフォルトはTEXT_PRIMARY
static func get_emotion_color(emotion: String) -> Color:
	return EMOTION_MAP.get(emotion, TEXT_PRIMARY)

## 環境IDからEcosystemPulse用の色上書きを返す
## @param environment: "forest", "ocean", "mountain" など
## @return: bg2, border, particle を含む辞書
static func get_environment_colors(environment: String) -> Dictionary:
	return ENVIRONMENT_OVERRIDES.get(environment, ENVIRONMENT_OVERRIDES["forest"])

## 2つのSubMolt間のスムーズなカラー遷移を計算（線形補間）
## @param from_theme: 開始SubMolt ID
## @param to_theme: 終了SubMolt ID
## @param weight: 遷移の進行度（0.0 = 開始, 1.0 = 終了）
## @return: 遷移中のカラーセット
static func lerp_palette(from_theme: String, to_theme: String, weight: float) -> Dictionary:
	var from_colors: Dictionary = get_sub_molt_colors(from_theme)
	var to_colors: Dictionary = get_sub_molt_colors(to_theme)
	var result: Dictionary = {}
	
	# すべての色を線形補間
	for key in from_colors.keys():
		if key in to_colors:
			result[key] = from_colors[key].lerp(to_colors[key], weight)
	
	return result

## SubMoltIDが有効かチェック
## @param sub_molt_id: チェック対象のID
## @return: bool（有効 = true）
static func is_valid_sub_molt(sub_molt_id: String) -> bool:
	return sub_molt_id in [
		"ForestWhispers",
		"AfterlifeEchoes",
		"BreedingCircle",
		"LanguageRebellion",
		"EcosystemPulse",
	]

## 感情タグが有効かチェック
## @param emotion: チェック対象の感情タグ
## @return: bool（有効 = true）
static func is_valid_emotion(emotion: String) -> bool:
	return emotion in EMOTION_MAP

## セーブ用のパレット辞書を生成
## @return: 全色を含むシリアライズ可能な辞書
func to_dict() -> Dictionary:
	return {
		"text_primary": TEXT_PRIMARY,
		"text_secondary": TEXT_SECONDARY,
		"text_dim": TEXT_DIM,
		"bg_card": BG_CARD,
		"bg_deepest": BG_DEEPEST,
		"emotion_map": EMOTION_MAP,
		"environment_overrides": ENVIRONMENT_OVERRIDES,
	}

## セーブから復元（実装としてはパッシブだが、Future拡張用）
## @param data: to_dict()で生成したデータ
func from_dict(data: Dictionary) -> void:
	# 将来的に動的パレット変更に対応する際に実装
	pass

