## oja_language_core.gd
## Oja's Rule — Hebbian学習の正規化版。語彙strengthの自動バランス維持
##
## Hebbian強化後に全語彙のstrengthを正規化し、
## 特定の語だけが極端に強くなるのを防ぐ。
##
## API呼び出しゼロ。1回の処理 < 0.3ms。
##
## 使い方:
##   var oja := OjaLanguageCore.new()
##   var result := oja.apply_oja_learning(vocabulary, conversation, 0.6)
##
## KB参照: KB99 (Hebbian), KB108 (Active Inference), KB113 (Oja詳細)
class_name OjaLanguageCore
extends RefCounted

# ─── パラメータ ───
const HEBBIAN_LTP_RATE: float = 0.15
const HEBBIAN_LTD_RATE: float = 0.03
const OJA_RATE: float = 0.1
const TARGET_AVG_STRENGTH: float = 0.55
const STRENGTH_FLOOR: float = 0.05
const STRENGTH_CEILING: float = 1.0
const SCALE_MIN: float = 0.5
const SCALE_MAX: float = 2.0
const QUADRATIC_DECAY: float = 0.02
const EMOTION_BOOST: float = 0.5

# ─── 内部状態 ───
var conversation_count: int = 0
var last_normalization: Dictionary = {}
var last_result: Dictionary = {}


# ==========================================
#  メイン処理
# ==========================================

func apply_oja_learning(
	vocabulary: Dictionary,
	conversation: Array[Dictionary],
	emotion_intensity: float = 0.5
) -> Dictionary:
	if vocabulary.is_empty():
		last_result = {"strengthened": 0, "weakened": 0, "normalized": false,
			"scale_factor": 1.0, "avg_before": 0.0, "avg_after": 0.0, "details": []}
		return last_result

	var used_words: Dictionary = _find_used_words(vocabulary, conversation)
	var avg_before: float = _calc_avg(vocabulary)

	# Hebbian強化/弱化
	var details: Array[Dictionary] = _apply_hebbian(vocabulary, used_words, emotion_intensity)

	# Oja二次項（コントラスト増強）
	_apply_oja_quadratic(vocabulary, used_words)

	# 正規化
	var norm_result: Dictionary = _normalize(vocabulary)

	var strengthened: int = 0
	var weakened: int = 0
	for d: Dictionary in details:
		if d.get("delta", 0.0) > 0:
			strengthened += 1
		elif d.get("delta", 0.0) < 0:
			weakened += 1

	conversation_count += 1

	last_result = {
		"strengthened": strengthened,
		"weakened": weakened,
		"normalized": norm_result.get("applied", false),
		"scale_factor": norm_result.get("scale_factor", 1.0),
		"avg_before": avg_before,
		"avg_after": _calc_avg(vocabulary),
		"vocab_size": vocabulary.size(),
		"conversation_count": conversation_count,
		"details": details,
	}

	if OS.is_debug_build():
		print("[Oja] LTP=%d LTD=%d scale=%.3f avg=%.3f→%.3f" % [
			strengthened, weakened, norm_result.get("scale_factor", 1.0),
			avg_before, last_result["avg_after"]])

	return last_result


# ==========================================
#  Hebbian強化/弱化
# ==========================================

func _apply_hebbian(
	vocabulary: Dictionary,
	used_words: Dictionary,
	emotion_intensity: float
) -> Array[Dictionary]:
	var details: Array[Dictionary] = []

	for word: String in vocabulary:
		var old_s: float = vocabulary[word].get("strength", 0.5)
		var was_used: bool = used_words.has(word)
		var delta: float = 0.0

		if was_used:
			delta = HEBBIAN_LTP_RATE * (1.0 + emotion_intensity * EMOTION_BOOST)
			vocabulary[word]["usage_count"] = vocabulary[word].get("usage_count", 0) + 1
			vocabulary[word]["last_used"] = Time.get_unix_time_from_system()
		else:
			delta = -HEBBIAN_LTD_RATE

		vocabulary[word]["strength"] = clampf(old_s + delta, STRENGTH_FLOOR, STRENGTH_CEILING)

		if absf(delta) > 0.001:
			details.append({"word": word, "type": "LTP" if delta > 0 else "LTD",
				"old": old_s, "new": vocabulary[word]["strength"], "delta": delta})

	return details


# ==========================================
#  Oja二次項
# ==========================================

func _apply_oja_quadratic(vocabulary: Dictionary, used_words: Dictionary) -> void:
	for word: String in vocabulary:
		var s: float = vocabulary[word].get("strength", 0.5)
		var decay: float = s * s * QUADRATIC_DECAY
		if used_words.has(word):
			decay *= 0.5
		vocabulary[word]["strength"] = maxf(
			vocabulary[word].get("strength", 0.5) - decay, STRENGTH_FLOOR
		)


# ==========================================
#  正規化（Oja核心）
# ==========================================

func _normalize(vocabulary: Dictionary) -> Dictionary:
	if vocabulary.is_empty():
		return {"applied": false, "scale_factor": 1.0}

	var current_avg: float = _calc_avg(vocabulary)
	if absf(current_avg - TARGET_AVG_STRENGTH) < 0.03:
		last_normalization = {"applied": false, "scale_factor": 1.0}
		return last_normalization

	var target_total: float = float(vocabulary.size()) * TARGET_AVG_STRENGTH
	var current_total: float = current_avg * float(vocabulary.size())
	if current_total < 0.001:
		last_normalization = {"applied": false, "scale_factor": 1.0}
		return last_normalization

	var raw_scale: float = target_total / current_total
	var scale: float = clampf(1.0 + OJA_RATE * (raw_scale - 1.0), SCALE_MIN, SCALE_MAX)

	for word: String in vocabulary:
		vocabulary[word]["strength"] = clampf(
			vocabulary[word].get("strength", 0.5) * scale,
			STRENGTH_FLOOR, STRENGTH_CEILING
		)

	last_normalization = {"applied": true, "scale_factor": scale,
		"avg_before": current_avg, "avg_after": _calc_avg(vocabulary)}
	return last_normalization


# ==========================================
#  BCM後の正規化連携 (KB112)
# ==========================================

func apply_after_bcm(vocabulary: Dictionary, bcm_result: Dictionary) -> Dictionary:
	var norm_result: Dictionary = _normalize(vocabulary)
	return {
		"bcm_ltp": bcm_result.get("ltp_count", 0),
		"bcm_ltd": bcm_result.get("ltd_count", 0),
		"oja_normalized": norm_result.get("applied", false),
		"oja_scale": norm_result.get("scale_factor", 1.0),
		"avg_after": _calc_avg(vocabulary),
	}


# ==========================================
#  コントラスト分析
# ==========================================

func analyze_contrast(vocabulary: Dictionary) -> Dictionary:
	if vocabulary.size() < 2:
		return {"contrast_ratio": 1.0, "std_dev": 0.0, "health": "too_few_words"}

	var max_s: float = 0.0
	var min_s: float = 1.0
	var strengths: Array[float] = []

	for word: String in vocabulary:
		var s: float = vocabulary[word].get("strength", 0.0)
		strengths.append(s)
		max_s = maxf(max_s, s)
		min_s = minf(min_s, s)

	var contrast: float = max_s / maxf(min_s, 0.01)
	var avg: float = _calc_avg(vocabulary)
	var variance: float = 0.0
	for s: float in strengths:
		variance += (s - avg) * (s - avg)
	variance /= float(strengths.size())
	var std_dev: float = sqrt(variance)

	var health: String = "good"
	if contrast < 1.2:
		health = "too_uniform"
	elif contrast > 10.0:
		health = "too_extreme"
	elif std_dev < 0.05:
		health = "stagnant"

	return {"contrast_ratio": contrast, "std_dev": std_dev,
		"max_strength": max_s, "min_strength": min_s,
		"avg_strength": avg, "health": health, "vocab_size": vocabulary.size()}


# ==========================================
#  PetBook連携
# ==========================================

func get_petbook_oja_data(result: Dictionary) -> Dictionary:
	var normalized: bool = result.get("normalized", false)
	var scale: float = result.get("scale_factor", 1.0)
	var strengthened: int = result.get("strengthened", 0)

	if normalized and scale < 0.9:
		return {"particle_color": Color(0.4, 0.6, 1.0), "particle_amount": 50,
			"highlight_text": "Language finding its balance"}
	elif normalized and scale > 1.1:
		return {"particle_color": Color(0.9, 0.7, 0.3), "particle_amount": 80,
			"highlight_text": "Words gaining new life"}
	elif strengthened > 3:
		return {"particle_color": Color(1.0, 0.8, 0.2), "particle_amount": 120,
			"highlight_text": "Vocabulary blooming!"}
	else:
		return {"particle_color": Color(0.5, 0.8, 0.5), "particle_amount": 25,
			"highlight_text": "Language patterns balanced"}


# ==========================================
#  ヘルパー
# ==========================================

func _find_used_words(vocabulary: Dictionary, conversation: Array[Dictionary]) -> Dictionary:
	var used: Dictionary = {}
	for msg: Dictionary in conversation:
		var text: String = msg.get("message", "")
		if text.is_empty():
			continue
		for word: String in vocabulary:
			if used.has(word):
				continue
			var ai_term: String = vocabulary[word].get("ai_term", "")
			if not ai_term.is_empty() and text.contains(ai_term):
				used[word] = true
	return used


func _calc_avg(vocabulary: Dictionary) -> float:
	if vocabulary.is_empty():
		return 0.0
	var total: float = 0.0
	for word: String in vocabulary:
		total += vocabulary[word].get("strength", 0.0)
	return total / float(vocabulary.size())


# ==========================================
#  セーブ / ロード
# ==========================================

func to_dict() -> Dictionary:
	return {"conversation_count": conversation_count,
		"last_normalization": last_normalization.duplicate(true)}


func from_dict(data: Dictionary) -> void:
	conversation_count = data.get("conversation_count", 0)
	last_normalization = data.get("last_normalization", {})
