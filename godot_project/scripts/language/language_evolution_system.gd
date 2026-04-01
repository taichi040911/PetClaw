## LanguageEvolutionSystem — AtoA独自言語の進化を統合管理
## 語順 × 接尾辞 × 前置詞の連動進化エンジン
class_name LanguageEvolutionSystem
extends Node

signal word_order_changed(old_order: String, new_order: String, reason: String)
signal suffix_created(suffix: String, context: String, reason: String)
signal preposition_evolved(change: Dictionary)
signal grammar_milestone(milestone_name: String, details: Dictionary)
signal evolution_event(event_type: String, data: Dictionary)

# === 語順定義 ===
enum WordOrder {
	SVO,   # Subject-Verb-Object（基本）
	SOV,   # Subject-Object-Verb（感情的・親密）
	VSO,   # Verb-Subject-Object（命令的・緊急）
	OVS,   # Object-Verb-Subject（強調・驚き）
	OSV,   # Object-Subject-Verb（詩的・美的）
	VOS,   # Verb-Object-Subject（受動的・内省）
}

const WORD_ORDER_NAMES: Dictionary = {
	WordOrder.SVO: "subject-verb-object",
	WordOrder.SOV: "subject-object-verb",
	WordOrder.VSO: "verb-subject-object",
	WordOrder.OVS: "object-verb-subject",
	WordOrder.OSV: "object-subject-verb",
	WordOrder.VOS: "verb-object-subject",
}

const WORD_ORDER_TRAITS: Dictionary = {
	# 各語順が好まれる性格・感情の傾向
	WordOrder.SVO: {"personality": {}, "emotions": {}},  # ニュートラル
	WordOrder.SOV: {"personality": {"affectionate": 0.6}, "emotions": {"love": 0.5}},
	WordOrder.VSO: {"personality": {"brave": 0.7}, "emotions": {"excitement": 0.6}},
	WordOrder.OVS: {"personality": {"curious": 0.6}, "emotions": {"excitement": 0.5}},
	WordOrder.OSV: {"personality": {"calm": 0.7}, "emotions": {"joy": 0.4}},
	WordOrder.VOS: {"personality": {"calm": 0.5}, "emotions": {"sadness": 0.3}},
}

# === State ===
var current_word_order: int = WordOrder.SVO
var suffixes: Dictionary = {}           # key: context → value: suffix string
var prepositions: Dictionary = {}       # key: role → value: preposition string
var evolution_history: Array[Dictionary] = []
var conversation_count_since_last_evolution: int = 0
var total_evolutions: int = 0

# === 進化トリガーパラメータ ===
var evolution_cooldown: float = 0.0
const MIN_CONVERSATIONS_FOR_EVOLUTION: int = 3
const EVOLUTION_COOLDOWN_TIME: float = 120.0    # 2分間のクールダウン
const EMOTION_INTENSITY_TRIGGER: float = 0.6    # この感情強度以上で進化チャンス
const CLIMATE_EVOLUTION_CHANCE: float = 0.3     # 気候イベント時の進化確率

# === 基本接尾辞シード ===
var base_suffixes: Dictionary = {
	"neutral": "-spark",
	"joy": "-glow",
	"fear": "-shade",
	"excitement": "-flash",
	"sadness": "-mist",
	"love": "-bloom",
}

# === 基本前置詞シード ===
var base_prepositions: Dictionary = {
	"location": "at-",
	"direction": "to-",
	"source": "from-",
	"companion": "with-",
	"cause": "for-",
}


func _ready() -> void:
	suffixes = base_suffixes.duplicate()
	prepositions = base_prepositions.duplicate()


func _process(delta: float) -> void:
	if evolution_cooldown > 0.0:
		evolution_cooldown -= delta


# ============================
# 語順進化エンジン
# ============================

func evaluate_word_order_change(conversation_context: Dictionary) -> Dictionary:
	## 会話コンテキストに基づいて語順変更を評価
	## Returns: {"should_change": bool, "new_order": int, "reason": String}

	if evolution_cooldown > 0.0:
		return {"should_change": false}
	if conversation_count_since_last_evolution < MIN_CONVERSATIONS_FOR_EVOLUTION:
		return {"should_change": false}

	var dominant_emotion: String = conversation_context.get("dominant_emotion", "neutral")
	var emotion_intensity: float = conversation_context.get("emotion_intensity", 0.0)
	var avg_personality: Dictionary = conversation_context.get("avg_personality", {})

	# 感情強度が閾値以下なら変更なし
	if emotion_intensity < EMOTION_INTENSITY_TRIGGER:
		return {"should_change": false}

	# 最適な語順を計算
	var best_order: int = current_word_order
	var best_score: float = 0.0

	for order in WORD_ORDER_TRAITS:
		if order == current_word_order:
			continue
		var traits: Dictionary = WORD_ORDER_TRAITS[order]
		var score := _calculate_order_affinity(traits, avg_personality, dominant_emotion, emotion_intensity)
		if score > best_score:
			best_score = score
			best_order = order

	# スコアが十分高ければ変更
	if best_score > 0.5 and best_order != current_word_order:
		var reason := "emotion:%s(%.1f) + personality affinity" % [dominant_emotion, emotion_intensity]
		return {"should_change": true, "new_order": best_order, "reason": reason}

	return {"should_change": false}


func _calculate_order_affinity(
	order_traits: Dictionary, avg_personality: Dictionary,
	dominant_emotion: String, emotion_intensity: float
) -> float:
	var score := 0.0

	# 性格との親和性
	for t_name in order_traits.get("personality", {}):
		var required: float = order_traits["personality"][t_name]
		var actual: float = avg_personality.get(t_name, 0.5)
		if actual >= required:
			score += 0.3

	# 感情との親和性
	for emotion in order_traits.get("emotions", {}):
		var required: float = order_traits["emotions"][emotion]
		if emotion == dominant_emotion and emotion_intensity >= required:
			score += 0.4

	return score


func apply_word_order_change(new_order: int, reason: String) -> void:
	var old_order := current_word_order
	current_word_order = new_order
	conversation_count_since_last_evolution = 0
	evolution_cooldown = EVOLUTION_COOLDOWN_TIME
	total_evolutions += 1

	var record := {
		"type": "word_order",
		"from": WORD_ORDER_NAMES[old_order],
		"to": WORD_ORDER_NAMES[new_order],
		"reason": reason,
		"timestamp": Time.get_unix_time_from_system(),
		"total_evolutions": total_evolutions,
	}
	evolution_history.append(record)

	word_order_changed.emit(
		WORD_ORDER_NAMES[old_order],
		WORD_ORDER_NAMES[new_order],
		reason
	)
	evolution_event.emit("word_order", record)

	# 語順変更に連動して接尾辞も影響を受ける
	_word_order_suffix_interconnection(new_order, reason)


# ============================
# 接尾辞進化エンジン
# ============================

func evaluate_suffix_evolution(conversation_context: Dictionary) -> Dictionary:
	## 新しい接尾辞の生成を評価
	## Returns: {"should_create": bool, "context": String, "suffix": String, "reason": String}

	var dominant_emotion: String = conversation_context.get("dominant_emotion", "neutral")
	var emotion_intensity: float = conversation_context.get("emotion_intensity", 0.0)
	var environment: String = conversation_context.get("environment", "forest")

	# 既存の接尾辞とのコンビネーション
	var context_key := "%s_%s" % [dominant_emotion, environment]

	# まだこのコンテキストの接尾辞がなければ生成チャンス
	if context_key not in suffixes and emotion_intensity > 0.5:
		var base_suffix: String = suffixes.get(dominant_emotion, "-spark")
		var env_prefix := environment.substr(0, 3)
		var new_suffix := "-%s%s" % [env_prefix, base_suffix.trim_prefix("-")]

		return {
			"should_create": true,
			"context": context_key,
			"suffix": new_suffix,
			"reason": "new context: %s in %s (intensity: %.1f)" % [dominant_emotion, environment, emotion_intensity],
		}

	return {"should_create": false}


func apply_suffix_creation(context: String, suffix: String, reason: String) -> void:
	suffixes[context] = suffix
	total_evolutions += 1

	var record := {
		"type": "suffix",
		"context": context,
		"suffix": suffix,
		"reason": reason,
		"timestamp": Time.get_unix_time_from_system(),
	}
	evolution_history.append(record)

	suffix_created.emit(suffix, context, reason)
	evolution_event.emit("suffix", record)


# ============================
# 前置詞進化エンジン
# ============================

func evaluate_preposition_evolution(conversation_context: Dictionary) -> Dictionary:
	## 前置詞システムの進化を評価
	var topics: Array = conversation_context.get("topics", [])
	var word_order_name: String = WORD_ORDER_NAMES[current_word_order]

	# 語順が変わったときに前置詞の配置も連動して変わる
	# OSV/OVS（目的語先頭）の場合、方向前置詞が後置に変化する可能性
	if current_word_order in [WordOrder.OSV, WordOrder.OVS]:
		if "direction" in prepositions and prepositions["direction"].begins_with("to-"):
			return {
				"should_evolve": true,
				"role": "direction",
				"new_form": "-ward",  # 前置詞→後置詞に変化
				"reason": "word order %s promotes postpositions" % word_order_name,
			}

	# 環境トピックから新しい前置詞が生まれる
	for topic in topics:
		var topic_key := "topic_%s" % topic
		if topic_key not in prepositions:
			return {
				"should_evolve": true,
				"role": topic_key,
				"new_form": "%s-" % topic.substr(0, 3),
				"reason": "new topic '%s' needs its own preposition" % topic,
			}

	return {"should_evolve": false}


func apply_preposition_evolution(role: String, new_form: String, reason: String) -> void:
	var old_form: String = prepositions.get(role, "")
	prepositions[role] = new_form
	total_evolutions += 1

	var record := {
		"type": "preposition",
		"role": role,
		"from": old_form,
		"to": new_form,
		"reason": reason,
		"timestamp": Time.get_unix_time_from_system(),
	}
	evolution_history.append(record)

	preposition_evolved.emit(record)
	evolution_event.emit("preposition", record)


# ============================
# 語順×接尾辞 相互強化（Hebbian Learning模倣）
# ============================

func _word_order_suffix_interconnection(new_order: int, trigger_reason: String) -> void:
	## 語順が変わった際に、接尾辞も連動して強化・変化する
	match new_order:
		WordOrder.SOV:
			# 親密な語順 → 愛情系接尾辞が強化
			if "love" in suffixes:
				var enhanced: String = suffixes["love"] + "-deep"
				suffixes["love_enhanced"] = enhanced
				suffix_created.emit(enhanced, "love_enhanced", "SOV interconnection")

		WordOrder.VSO:
			# 命令的語順 → 力強い接尾辞が生成
			var force_suffix: String = "-force-" + suffixes.get("excitement", "flash").trim_prefix("-")
			suffixes["command"] = force_suffix
			suffix_created.emit(force_suffix, "command", "VSO interconnection")

		WordOrder.OVS:
			# 強調語順 → 驚きの接尾辞
			var emphasis_suffix: String = "-!" + suffixes.get("excitement", "flash").trim_prefix("-")
			suffixes["emphasis"] = emphasis_suffix
			suffix_created.emit(emphasis_suffix, "emphasis", "OVS interconnection")

		WordOrder.OSV:
			# 詩的語順 → 美的接尾辞
			var poetic_suffix: String = "-" + suffixes.get("joy", "glow").trim_prefix("-") + "-song"
			suffixes["poetic"] = poetic_suffix
			suffix_created.emit(poetic_suffix, "poetic", "OSV interconnection")

	# マイルストーンチェック
	_check_grammar_milestone()


# ============================
# 気候変動との連動
# ============================

func on_climate_event(event_type: String, intensity: float) -> void:
	## 気候イベントが言語進化を促進する
	if randf() > CLIMATE_EVOLUTION_CHANCE:
		return

	# 気候に応じた特別接尾辞
	var climate_suffix := ""
	match event_type:
		"rain": climate_suffix = "-rain-whisper"
		"storm": climate_suffix = "-thunder-cry"
		"bloom": climate_suffix = "-petal-dance"
		"ghost": climate_suffix = "-shadow-voice"
		"festival": climate_suffix = "-cheer-wave"
		_: climate_suffix = "-%s-echo" % event_type

	var context_key := "climate_%s" % event_type
	if context_key not in suffixes:
		apply_suffix_creation(
			context_key, climate_suffix,
			"climate event '%s' (intensity: %.1f)" % [event_type, intensity]
		)


# ============================
# 進化マイルストーン
# ============================

func _check_grammar_milestone() -> void:
	var milestones_reached: Array[String] = []

	if total_evolutions >= 5 and not _milestone_exists("first_grammar"):
		milestones_reached.append("first_grammar")
	if suffixes.size() >= 10 and not _milestone_exists("rich_vocabulary"):
		milestones_reached.append("rich_vocabulary")
	if prepositions.size() >= 8 and not _milestone_exists("complex_syntax"):
		milestones_reached.append("complex_syntax")
	if total_evolutions >= 20 and not _milestone_exists("language_maturity"):
		milestones_reached.append("language_maturity")

	for milestone in milestones_reached:
		grammar_milestone.emit(milestone, {
			"total_evolutions": total_evolutions,
			"suffix_count": suffixes.size(),
			"preposition_count": prepositions.size(),
			"word_order": WORD_ORDER_NAMES[current_word_order],
		})


func _milestone_exists(name: String) -> bool:
	for record in evolution_history:
		if record.get("type") == "milestone" and record.get("name") == name:
			return true
	return false


# ============================
# 会話カウント更新（AtoAシステムから呼ばれる）
# ============================

func on_conversation_completed(context: Dictionary) -> void:
	conversation_count_since_last_evolution += 1

	# 語順進化チェック
	var order_eval := evaluate_word_order_change(context)
	if order_eval["should_change"]:
		apply_word_order_change(order_eval["new_order"], order_eval["reason"])

	# 接尾辞進化チェック
	var suffix_eval := evaluate_suffix_evolution(context)
	if suffix_eval["should_create"]:
		apply_suffix_creation(suffix_eval["context"], suffix_eval["suffix"], suffix_eval["reason"])

	# 前置詞進化チェック
	var prep_eval := evaluate_preposition_evolution(context)
	if prep_eval.get("should_evolve", false):
		apply_preposition_evolution(prep_eval["role"], prep_eval["new_form"], prep_eval["reason"])


# ============================
# 現在の文法状態を取得（AtoAプロンプト構築用）
# ============================

func get_current_grammar() -> Dictionary:
	return {
		"word_order": WORD_ORDER_NAMES[current_word_order],
		"suffixes": suffixes.duplicate(),
		"prepositions": prepositions.duplicate(),
		"total_evolutions": total_evolutions,
		"history_summary": _get_recent_history(5),
	}


func _get_recent_history(count: int) -> Array:
	var start := maxi(0, evolution_history.size() - count)
	return evolution_history.slice(start)


# ============================
# シリアライズ
# ============================

func to_dict() -> Dictionary:
	return {
		"current_word_order": current_word_order,
		"suffixes": suffixes.duplicate(),
		"prepositions": prepositions.duplicate(),
		"evolution_history": evolution_history.duplicate(true),
		"total_evolutions": total_evolutions,
		"conversation_count": conversation_count_since_last_evolution,
	}


func from_dict(data: Dictionary) -> void:
	current_word_order = data.get("current_word_order", WordOrder.SVO)
	suffixes = data.get("suffixes", base_suffixes.duplicate())
	prepositions = data.get("prepositions", base_prepositions.duplicate())
	evolution_history = data.get("evolution_history", [])
	total_evolutions = data.get("total_evolutions", 0)
	conversation_count_since_last_evolution = data.get("conversation_count", 0)
