## bcm_language_core.gd
## BCM Theory (Bienenstock-Cooper-Munro) — スライディング閾値で語彙安定化
##
## 閾値を超えた語 → LTP（強化）、閾値以下 → LTD（弱化）
## 閾値自体が語彙全体の活動に応じて自動変化 → 語彙爆発を防止
##
## API呼び出しゼロ。1回の処理 < 0.5ms。
##
## 使い方:
##   var bcm := BCMLanguageCore.new()
##   var result := bcm.apply_bcm_learning(vocabulary, conversation, 0.7)
##
## KB参照: KB99 (Hebbian), KB108 (Active Inference), KB112 (BCM詳細)
class_name BCMLanguageCore
extends RefCounted

# ─── BCMパラメータ ───
const LTP_RATE: float = 0.18
const LTD_RATE: float = 0.08
const THRESHOLD_BASE_FACTOR: float = 0.8
const THRESHOLD_DRIFT: float = 0.02
const THRESHOLD_MIN: float = 0.15
const THRESHOLD_MAX: float = 0.90
const STRENGTH_FLOOR: float = 0.05
const STRENGTH_CEILING: float = 1.0
const EMOTION_AMPLIFICATION: float = 0.5
const QUADRATIC_FEEDBACK: float = 0.1

# ─── イベント別閾値調整 ───
const EVENT_THRESHOLD_ADJ: Dictionary = {
	"death": -0.20,
	"resurrection": -0.25,
	"breeding": -0.15,
	"evolution": -0.10,
	"first_meeting": -0.08,
	"daily": 0.0,
}

# ─── 内部状態 ───
var sliding_threshold: float = 0.5
var threshold_drift_accumulated: float = 0.0
var conversation_count: int = 0
var last_result: Dictionary = {}


# ==========================================
#  メイン処理
# ==========================================

func apply_bcm_learning(
	vocabulary: Dictionary,
	conversation: Array[Dictionary],
	emotion_intensity: float = 0.5
) -> Dictionary:
	_update_threshold(vocabulary)

	var used_words: Dictionary = _find_used_words(vocabulary, conversation)
	var ltp_count: int = 0
	var ltd_count: int = 0
	var details: Array[Dictionary] = []

	for word: String in vocabulary:
		var was_used: bool = used_words.has(word)
		var activity: float = _calculate_activity(
			vocabulary[word], was_used, emotion_intensity
		)
		var old_s: float = vocabulary[word].get("strength", 0.5)
		var new_s: float = _apply_bcm_rule(old_s, activity)
		vocabulary[word]["strength"] = new_s

		if was_used:
			vocabulary[word]["usage_count"] = vocabulary[word].get("usage_count", 0) + 1
			vocabulary[word]["last_used"] = Time.get_unix_time_from_system()

		var delta: float = new_s - old_s
		if delta > 0.001:
			ltp_count += 1
			details.append({"word": word, "type": "LTP", "old": old_s, "new": new_s, "delta": delta})
		elif delta < -0.001:
			ltd_count += 1
			details.append({"word": word, "type": "LTD", "old": old_s, "new": new_s, "delta": delta})

	conversation_count += 1
	threshold_drift_accumulated = minf(threshold_drift_accumulated + THRESHOLD_DRIFT, 0.3)

	last_result = {
		"ltp_count": ltp_count,
		"ltd_count": ltd_count,
		"threshold": sliding_threshold,
		"avg_strength": _calc_avg(vocabulary),
		"conversation_count": conversation_count,
		"vocab_size": vocabulary.size(),
		"details": details,
	}

	if OS.is_debug_build():
		print("[BCM] θ=%.3f LTP=%d LTD=%d vocab=%d" % [
			sliding_threshold, ltp_count, ltd_count, vocabulary.size()])

	return last_result


# ==========================================
#  閾値の計算
# ==========================================

func _update_threshold(vocabulary: Dictionary) -> void:
	if vocabulary.is_empty():
		sliding_threshold = THRESHOLD_MIN
		return

	var avg: float = _calc_avg(vocabulary)
	var sum_sq: float = 0.0
	for word: String in vocabulary:
		var s: float = vocabulary[word].get("strength", 0.0)
		sum_sq += s * s
	var avg_sq: float = sum_sq / float(vocabulary.size())

	sliding_threshold = clampf(
		avg * THRESHOLD_BASE_FACTOR + threshold_drift_accumulated + avg_sq * QUADRATIC_FEEDBACK,
		THRESHOLD_MIN, THRESHOLD_MAX
	)


func get_threshold() -> float:
	return sliding_threshold


# ==========================================
#  活動レベル計算
# ==========================================

func _calculate_activity(
	word_data: Dictionary, was_used: bool, emotion_intensity: float
) -> float:
	var base: float = word_data.get("strength", 0.5)
	var use_bonus: float = 0.15 if was_used else 0.0
	var emotion_boost: float = emotion_intensity * EMOTION_AMPLIFICATION if was_used else 0.0
	return base + use_bonus + emotion_boost


# ==========================================
#  BCMルール本体
# ==========================================

func _apply_bcm_rule(current_strength: float, activity: float) -> float:
	var delta: float = 0.0
	if activity > sliding_threshold:
		delta = LTP_RATE * (activity - sliding_threshold)
	else:
		delta = -LTD_RATE * (sliding_threshold - activity)
	return clampf(current_strength + delta, STRENGTH_FLOOR, STRENGTH_CEILING)


# ==========================================
#  イベント連携
# ==========================================

func apply_bcm_with_event(
	vocabulary: Dictionary,
	conversation: Array[Dictionary],
	emotion_intensity: float,
	event_type: String = "daily"
) -> Dictionary:
	var event_adj: float = EVENT_THRESHOLD_ADJ.get(event_type, 0.0)
	var original_drift: float = threshold_drift_accumulated

	if event_adj != 0.0:
		threshold_drift_accumulated = maxf(threshold_drift_accumulated + event_adj, -0.2)

	var result: Dictionary = apply_bcm_learning(vocabulary, conversation, emotion_intensity)

	threshold_drift_accumulated = original_drift
	result["event_type"] = event_type
	result["threshold_adjustment"] = event_adj
	return result


# ==========================================
#  Active Inference連携 (KB108)
# ==========================================

func integrate_with_active_inference(
	ai_result: Dictionary,
	vocabulary: Dictionary,
	conversation: Array[Dictionary]
) -> Dictionary:
	var error: float = ai_result.get("error", 0.0)
	var emotion_intensity: float = 0.5
	if error > 0.6:
		emotion_intensity = clampf(emotion_intensity + error * 0.4, 0.0, 1.0)
	emotion_intensity *= ai_result.get("learning_boost", 1.0)

	var bcm_result: Dictionary = apply_bcm_learning(
		vocabulary, conversation, clampf(emotion_intensity, 0.0, 1.0)
	)
	bcm_result["ai_error"] = error
	bcm_result["ai_action"] = ai_result.get("action", "maintain")
	bcm_result["effective_emotion"] = emotion_intensity
	return bcm_result


# ==========================================
#  語彙健全性チェック
# ==========================================

func check_vocabulary_health(vocabulary: Dictionary) -> Dictionary:
	if vocabulary.is_empty():
		return {"healthy": true, "warnings": [], "stats": {}}

	var max_s: float = 0.0
	var min_s: float = 1.0
	var dead_count: int = 0

	for word: String in vocabulary:
		var s: float = vocabulary[word].get("strength", 0.0)
		max_s = maxf(max_s, s)
		min_s = minf(min_s, s)
		if s < 0.1:
			dead_count += 1

	var avg: float = _calc_avg(vocabulary)
	var warnings: Array[String] = []

	if max_s > 0.95 and avg > 0.7:
		warnings.append("vocabulary_too_strong: avg=%.2f" % avg)
	if dead_count > vocabulary.size() * 0.5:
		warnings.append("too_many_dead_words: %d/%d" % [dead_count, vocabulary.size()])
	if avg < 0.2:
		warnings.append("vocabulary_too_weak: avg=%.2f" % avg)
	if sliding_threshold > 0.85:
		warnings.append("threshold_too_high: %.2f" % sliding_threshold)

	return {
		"healthy": warnings.is_empty(),
		"warnings": warnings,
		"stats": {
			"avg_strength": avg, "max_strength": max_s, "min_strength": min_s,
			"dead_words": dead_count, "total_words": vocabulary.size(),
			"threshold": sliding_threshold, "conversation_count": conversation_count,
		},
	}


# ==========================================
#  PetBook連携
# ==========================================

func get_petbook_bcm_data(result: Dictionary) -> Dictionary:
	var ltp: int = result.get("ltp_count", 0)
	var ltd: int = result.get("ltd_count", 0)

	if ltp > 3:
		return {"particle_color": Color(1.0, 0.8, 0.2), "particle_amount": 150,
			"highlight_text": "Language is evolving rapidly!"}
	elif ltp > 0 and ltd == 0:
		return {"particle_color": Color(0.4, 0.9, 0.4), "particle_amount": 60,
			"highlight_text": "Words growing stronger"}
	elif ltd > ltp:
		return {"particle_color": Color(0.6, 0.6, 0.8), "particle_amount": 40,
			"highlight_text": "Language is refining itself"}
	else:
		return {"particle_color": Color(0.5, 0.7, 0.5), "particle_amount": 20,
			"highlight_text": "Language patterns stable"}


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
	return {
		"sliding_threshold": sliding_threshold,
		"threshold_drift_accumulated": threshold_drift_accumulated,
		"conversation_count": conversation_count,
	}


func from_dict(data: Dictionary) -> void:
	sliding_threshold = data.get("sliding_threshold", 0.5)
	threshold_drift_accumulated = data.get("threshold_drift_accumulated", 0.0)
	conversation_count = data.get("conversation_count", 0)
