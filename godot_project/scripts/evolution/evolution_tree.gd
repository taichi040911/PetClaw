## EvolutionTree — 進化ツリーデータ定義と分岐判定
## たまごっち/デジモン/ポケモンの進化チャートを統合分析した5段階進化システム
## Care Misses + 性格 + 環境 + 関係性 + AtoA履歴で分岐
class_name EvolutionTree
extends RefCounted

# ========================================================
# 進化段階定義
# ========================================================
# Stage 0: Egg — 卵（孵化待ち）
# Stage 1: Blob — 幼体（丸い塊、目だけ）
# Stage 2: Infant — 幼児（体の特徴が出始める）
# Stage 3: Youth — 少年/少女（IPの顔、性格が視覚化）← ここが最重要
# Stage 4: Adult — 成体（完成形、威厳）
# Stage 5: Elder/Legend — 伝説形態（特別エフェクト、到達感）

# ========================================================
# 進化条件パラメータ
# ========================================================

## Care Missesの閾値（たまごっち直系）
const CARE_QUALITY_THRESHOLDS := {
	"excellent": 1,   # 0-1 misses → 最良ルート
	"good": 3,        # 2-3 misses → 良ルート
	"average": 5,     # 4-5 misses → 中間ルート
	"poor": 99,       # 6+ misses → 低ルート / ダーク進化
}

## 進化に必要な最低年齢（ゲーム内時間・時間単位）
const MIN_AGE_FOR_STAGE := {
	1: 0.0,    # Egg → Blob: 即時（孵化）
	2: 2.0,    # Blob → Infant: 2時間
	3: 8.0,    # Infant → Youth: 8時間
	4: 24.0,   # Youth → Adult: 24時間
	5: 72.0,   # Adult → Elder: 72時間（3日）
}

## 進化準備度の閾値
const READINESS_THRESHOLD := 0.75


# ========================================================
# 完全進化ツリーデータ
# ========================================================

## Stage 1→2: Blob→Infant（環境で初期分岐）
static func get_stage_2_paths() -> Array[Dictionary]:
	return [
		{
			"id": "forest_infant",
			"display_name": "森の幼子",
			"description": "木漏れ日に包まれ、小さな葉っぱの耳が生えた",
			"conditions": {
				"primary_environment": "forest",
				"care_quality": "good",
			},
			"stat_bonus": {"health": 0.1, "disease_resistance": 0.1},
			"visual": {"color_shift": "green", "feature": "leaf_ears"},
			"unlock_trait": "nature_affinity",
		},
		{
			"id": "sea_infant",
			"display_name": "海の幼子",
			"description": "潮風を浴びて、小さなヒレが見え始めた",
			"conditions": {
				"primary_environment": "sea",
				"care_quality": "good",
			},
			"stat_bonus": {"energy": 0.1, "health": 0.05},
			"visual": {"color_shift": "blue", "feature": "small_fins"},
			"unlock_trait": "water_affinity",
		},
		{
			"id": "ruins_infant",
			"display_name": "遺跡の幼子",
			"description": "古代の力に触れ、額に不思議な紋章が浮かんだ",
			"conditions": {
				"primary_environment": "ruins",
				"care_quality": "good",
			},
			"stat_bonus": {"disease_resistance": 0.15},
			"visual": {"color_shift": "purple", "feature": "rune_mark"},
			"unlock_trait": "mystic_sense",
		},
		{
			"id": "city_infant",
			"display_name": "街の幼子",
			"description": "人々の賑わいの中で、小さなスカーフを纏った",
			"conditions": {
				"primary_environment": "city",
				"care_quality": "good",
			},
			"stat_bonus": {"affection": 0.1, "energy": 0.05},
			"visual": {"color_shift": "orange", "feature": "tiny_scarf"},
			"unlock_trait": "social_charm",
		},
		{
			"id": "neglected_infant",
			"display_name": "さすらいの幼子",
			"description": "ひとりで過ごす時間が長く、瞳が少し鋭くなった",
			"conditions": {
				"care_quality": "poor",
			},
			"stat_bonus": {"disease_resistance": 0.05},
			"visual": {"color_shift": "grey", "feature": "sharp_eyes"},
			"unlock_trait": "lone_wolf",
			"is_dark_route": true,
		},
	]


## Stage 2→3: Infant→Youth（性格 + Care Qualityで分岐）← 最重要段階
static func get_stage_3_paths() -> Array[Dictionary]:
	return [
		# === 戦士系（brave主導）===
		{
			"id": "warrior_youth",
			"display_name": "勇者の若者",
			"description": "勇気ある心で前に進む。小さな体に大きな意志が宿った",
			"conditions": {
				"personality_primary": "brave",
				"personality_threshold": 0.65,
				"care_quality": "good",
			},
			"stat_bonus": {"health": 0.15, "energy": 0.05},
			"visual": {"color_accent": "red", "feature": "brave_crest", "body": "athletic"},
		},
		# === 学者系（curious主導）===
		{
			"id": "scholar_youth",
			"display_name": "知恵の若者",
			"description": "知識への渇望が止まらない。目がキラキラと輝く",
			"conditions": {
				"personality_primary": "curious",
				"personality_threshold": 0.65,
				"care_quality": "good",
			},
			"stat_bonus": {"disease_resistance": 0.15, "health": 0.05},
			"visual": {"color_accent": "blue", "feature": "book_mark", "body": "slim"},
		},
		# === 癒し系（affectionate主導）===
		{
			"id": "healer_youth",
			"display_name": "癒しの若者",
			"description": "温かい心で周りを包む。手から優しい光がこぼれる",
			"conditions": {
				"personality_primary": "affectionate",
				"personality_threshold": 0.65,
				"care_quality": "excellent",
			},
			"stat_bonus": {"affection": 0.15, "health": 0.1},
			"visual": {"color_accent": "pink", "feature": "glow_hands", "body": "soft"},
		},
		# === いたずら系（playful主導）===
		{
			"id": "trickster_youth",
			"display_name": "いたずらの若者",
			"description": "好奇心とユーモアが爆発。尻尾がくるりと巻いた",
			"conditions": {
				"personality_primary": "playful",
				"personality_threshold": 0.65,
				"care_quality": "good",
			},
			"stat_bonus": {"energy": 0.15},
			"visual": {"color_accent": "yellow", "feature": "curly_tail", "body": "bouncy"},
		},
		# === 番人系（calm主導）===
		{
			"id": "sentinel_youth",
			"display_name": "静寂の若者",
			"description": "穏やかだが芯が強い。瞳に深い知性が宿る",
			"conditions": {
				"personality_primary": "calm",
				"personality_threshold": 0.65,
				"care_quality": "good",
			},
			"stat_bonus": {"disease_resistance": 0.1, "health": 0.1},
			"visual": {"color_accent": "teal", "feature": "calm_aura", "body": "balanced"},
		},
		# === 社交系（AtoA会話回数多い）===
		{
			"id": "diplomat_youth",
			"display_name": "語り部の若者",
			"description": "多くの仲間と話し合い、言葉の力に目覚めた",
			"conditions": {
				"a2a_conversation_count_min": 20,
				"care_quality": "good",
			},
			"stat_bonus": {"affection": 0.1, "energy": 0.05},
			"visual": {"color_accent": "gold", "feature": "speech_mark", "body": "expressive"},
		},
		# === ダークルート（care poor + 孤立）===
		{
			"id": "shadow_youth",
			"display_name": "影の若者",
			"description": "孤独の中で強さを見つけた。暗い炎が瞳に宿る",
			"conditions": {
				"care_quality": "poor",
				"relationship_max_below": 0.3,
			},
			"stat_bonus": {"health": 0.1, "disease_resistance": 0.1},
			"visual": {"color_accent": "dark_purple", "feature": "shadow_flame", "body": "angular"},
			"is_dark_route": true,
		},
	]


## Stage 3→4: Youth→Adult（複合条件、たまごっち的Care品質重視）
static func get_stage_4_paths() -> Array[Dictionary]:
	return [
		# === 守護者（brave + affectionate融合）===
		{
			"id": "guardian_adult",
			"display_name": "守護者",
			"description": "仲間を守る盾となる。愛と勇気の結晶",
			"conditions": {
				"personality_primary": "brave",
				"personality_secondary": "affectionate",
				"primary_threshold": 0.75,
				"secondary_threshold": 0.55,
				"care_quality": "excellent",
			},
			"stat_bonus": {"health": 0.2, "disease_resistance": 0.15, "affection": 0.1},
			"visual": {"armor": "light_shield", "aura": "golden"},
		},
		# === 賢者（calm + curious融合）===
		{
			"id": "sage_adult",
			"display_name": "賢者",
			"description": "静かなる知の探求者。あらゆる答えを持つ",
			"conditions": {
				"personality_primary": "calm",
				"personality_secondary": "curious",
				"primary_threshold": 0.75,
				"secondary_threshold": 0.55,
				"care_quality": "good",
			},
			"stat_bonus": {"disease_resistance": 0.25, "health": 0.1},
			"visual": {"accessory": "wisdom_crystal", "aura": "blue"},
		},
		# === 絆の達人（affectionate + 高関係性）===
		{
			"id": "bond_master_adult",
			"display_name": "絆の達人",
			"description": "すべてのペットと深い絆を結ぶ。言語の橋渡し役",
			"conditions": {
				"personality_primary": "affectionate",
				"primary_threshold": 0.75,
				"relationship_avg_min": 0.6,
				"a2a_conversation_count_min": 40,
				"care_quality": "good",
			},
			"stat_bonus": {"affection": 0.25},
			"visual": {"accessory": "bond_ribbon", "aura": "rainbow"},
		},
		# === 嵐の戦士（brave + playful + バトル経験）===
		{
			"id": "storm_warrior_adult",
			"display_name": "嵐の戦士",
			"description": "戦いの中で笑う。嵐のような力と遊び心の融合",
			"conditions": {
				"personality_primary": "brave",
				"personality_secondary": "playful",
				"primary_threshold": 0.75,
				"secondary_threshold": 0.5,
				"care_quality": "good",
			},
			"stat_bonus": {"health": 0.15, "energy": 0.15},
			"visual": {"accessory": "storm_cape", "aura": "electric"},
		},
		# === 神秘者（ruins環境 + calm + brave）===
		{
			"id": "mystic_adult",
			"display_name": "神秘者",
			"description": "遺跡の古代知識を継承した。時空を感じる者",
			"conditions": {
				"primary_environment": "ruins",
				"personality_primary": "calm",
				"personality_secondary": "brave",
				"primary_threshold": 0.65,
				"secondary_threshold": 0.55,
			},
			"stat_bonus": {"disease_resistance": 0.2, "energy": 0.1},
			"visual": {"accessory": "ancient_rune", "aura": "purple"},
		},
		# === 闇の覇者（ダークルート最終）===
		{
			"id": "dark_sovereign_adult",
			"display_name": "闇の覇者",
			"description": "孤独と苦難が究極の力を生んだ。SkullGreymon的分岐",
			"conditions": {
				"care_quality": "poor",
				"previous_form_dark": true,
			},
			"stat_bonus": {"health": 0.2, "disease_resistance": 0.2},
			"visual": {"accessory": "dark_crown", "aura": "shadow"},
			"is_dark_route": true,
		},
	]


## Stage 4→5: Adult→Elder/Legend（特殊条件、到達感重視）
static func get_stage_5_paths() -> Array[Dictionary]:
	return [
		# === 太古の長老（全体バランス型）===
		{
			"id": "ancient_elder",
			"display_name": "太古の長老",
			"description": "時の流れを見守ってきた存在。すべてを受け入れる穏やかさ",
			"conditions": {
				"min_age_hours": 100,
				"care_quality": "good",
				"personality_balance": true,  # 全性格が0.4以上
			},
			"stat_bonus": {"health": 0.15, "disease_resistance": 0.3},
			"visual": {"aura": "ancient_gold", "effect": "floating_runes"},
		},
		# === 永遠の伴侶（最高関係性）===
		{
			"id": "eternal_companion",
			"display_name": "永遠の伴侶",
			"description": "プレイヤーとの絆が永遠の光を纏った。最強の愛着形態",
			"conditions": {
				"affection_stat_min": 0.9,
				"care_quality": "excellent",
				"total_a2a_conversations_min": 80,
			},
			"stat_bonus": {"affection": 0.3, "health": 0.1},
			"visual": {"aura": "eternal_light", "effect": "heart_orbit"},
		},
		# === 言語の大賢者（独自言語マスター）===
		{
			"id": "language_sage_elder",
			"display_name": "言語の大賢者",
			"description": "独自言語を完全にマスター。すべてのペットの通訳者",
			"conditions": {
				"language_vocabulary_min": 50,
				"a2a_conversation_count_min": 100,
				"care_quality": "good",
			},
			"stat_bonus": {"disease_resistance": 0.2, "affection": 0.2},
			"visual": {"aura": "language_flow", "effect": "floating_words"},
		},
		# === 闇からの帰還者（ダーク→ライト転換）===
		{
			"id": "redeemed_elder",
			"display_name": "闇からの帰還者",
			"description": "闇を経て真の強さを知った。最も稀少な形態",
			"conditions": {
				"previous_form_dark": true,
				"care_quality": "excellent",  # ダーク後にexcellentケアで贖い
				"affection_stat_min": 0.7,
			},
			"stat_bonus": {"health": 0.2, "disease_resistance": 0.2, "affection": 0.15},
			"visual": {"aura": "dual_light_shadow", "effect": "redemption_wings"},
			"is_special": true,
		},
	]


# ========================================================
# 進化ツリー取得ユーティリティ
# ========================================================

static func get_paths_for_stage(stage: int) -> Array[Dictionary]:
	match stage:
		2: return get_stage_2_paths()
		3: return get_stage_3_paths()
		4: return get_stage_4_paths()
		5: return get_stage_5_paths()
		_: return []


static func get_all_form_ids() -> Array[String]:
	var ids: Array[String] = []
	for stage in [2, 3, 4, 5]:
		for path in get_paths_for_stage(stage):
			ids.append(path["id"])
	return ids


static func find_form_by_id(form_id: String) -> Dictionary:
	for stage in [2, 3, 4, 5]:
		for path in get_paths_for_stage(stage):
			if path["id"] == form_id:
				return path
	return {}
