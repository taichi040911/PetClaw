## learning_model_bridge.gd
## Active Inference → BCM → Oja 学習パイプラインの統合ブリッジ
##
## AtoA会話完了時に3段階の学習処理を自動実行:
##   1. Active Inference: 予測誤差に基づくHebbian語彙強化
##   2. BCM Theory: スライディング閾値による安定化（LTP/LTD）
##   3. Oja's Rule: 正規化でstrength分布を健全に保つ
##
## API呼び出しゼロ。全処理 < 2ms。
##
## 使い方:
##   var bridge := LearningModelBridge.new()
##   var result := bridge.process_conversation(vocabulary, conversation, pet_state, emotion)
##
## KB参照: KB108 (Active Inference), KB112 (BCM), KB113 (Oja)
class_name LearningModelBridge
extends RefCounted

const _AIC := preload("res://scripts/inference/active_inference_core.gd")
const _BCM := preload("res://scripts/inference/bcm_language_core.gd")
const _OJA := preload("res://scripts/inference/oja_language_core.gd")

# ─── シグナル ───
signal learning_completed(result: Dictionary)
signal vocabulary_warning(warning: String)

# ─── 学習モデルインスタンス ───
var active_inference: RefCounted  # ActiveInferenceCore
var bcm_core: RefCounted          # BCMLanguageCore
var oja_core: RefCounted          # OjaLanguageCore

# ─── パラメータ ───
const ENABLE_AI: bool = true
const ENABLE_BCM: bool = true
const ENABLE_OJA: bool = true

# ─── 統計 ───
var total_cycles: int = 0
var last_result: Dictionary = {}
var cumulative_stats: Dictionary = {
	"total_ltp": 0,
	"total_ltd": 0,
	"total_normalizations": 0,
	"total_new_word_proposals": 0,
}


func _init() -> void:
	active_inference = _AIC.new()
	bcm_core = _BCM.new()
	oja_core = _OJA.new()


# ==========================================
#  メインパイプライン
# ==========================================

func process_conversation(
	vocabulary: Dictionary,
	conversation: Array[Dictionary],
	pet_state: Dictionary,
	emotion_intensity: float = 0.5,
	event_type: String = "daily"
) -> Dictionary:
	## 3段階学習パイプラインを実行
	##
	## 引数:
	##   vocabulary: {word: {strength, ai_term, usage_count, ...}, ...}
	##   conversation: [{message, emotion, pet_id}, ...]
	##   pet_state: {pet_id, emotion, vocab_size, ...}
	##   emotion_intensity: 感情の強さ (0.0～1.0)
	##   event_type: イベント種別 ("daily", "death", "evolution", etc.)
	##
	## 戻り値:
	##   {ai_result, bcm_result, oja_result, pipeline_summary, health}

	var ai_result: Dictionary = {}
	var bcm_result: Dictionary = {}
	var oja_result: Dictionary = {}

	# ── Stage 1: Active Inference ──
	if ENABLE_AI and not conversation.is_empty():
		ai_result = active_inference.run(conversation, pet_state, emotion_intensity)

		# Active Inference の学習ブーストを語彙に適用
		active_inference.apply_to_words(vocabulary, conversation, ai_result)

	# ── Stage 2: BCM Theory ──
	if ENABLE_BCM:
		if event_type != "daily":
			bcm_result = bcm_core.apply_bcm_with_event(
				vocabulary, conversation, emotion_intensity, event_type
			)
		elif not ai_result.is_empty():
			bcm_result = bcm_core.integrate_with_active_inference(
				ai_result, vocabulary, conversation
			)
		else:
			bcm_result = bcm_core.apply_bcm_learning(
				vocabulary, conversation, emotion_intensity
			)

	# ── Stage 3: Oja's Rule ──
	if ENABLE_OJA:
		if not bcm_result.is_empty():
			oja_result = oja_core.apply_after_bcm(vocabulary, bcm_result)
		else:
			oja_result = oja_core.apply_oja_learning(
				vocabulary, conversation, emotion_intensity
			)

	# ── 健全性チェック ──
	var health: Dictionary = _check_health(vocabulary)

	# ── 統計更新 ──
	total_cycles += 1
	_update_cumulative_stats(ai_result, bcm_result, oja_result)

	# ── 結果構築 ──
	last_result = {
		"ai_result": ai_result,
		"bcm_result": bcm_result,
		"oja_result": oja_result,
		"pipeline_summary": _build_summary(ai_result, bcm_result, oja_result),
		"health": health,
		"cycle": total_cycles,
		"event_type": event_type,
	}

	# ── 警告チェック ──
	for warning: String in health.get("warnings", []):
		vocabulary_warning.emit(warning)

	# ── シグナル発火 ──
	learning_completed.emit(last_result)

	if OS.is_debug_build():
		var summary: Dictionary = last_result["pipeline_summary"]
		print("[Bridge] cycle=%d AI=%s BCM_LTP=%d BCM_LTD=%d Oja_norm=%s avg=%.3f health=%s" % [
			total_cycles,
			str(ai_result.get("action", "skip")),
			summary.get("bcm_ltp", 0),
			summary.get("bcm_ltd", 0),
			str(summary.get("oja_normalized", false)),
			summary.get("avg_strength", 0.0),
			health.get("healthy", true),
		])

	return last_result


# ==========================================
#  イベント特化処理
# ==========================================

func process_death_event(
	vocabulary: Dictionary,
	conversation: Array[Dictionary],
	pet_state: Dictionary
) -> Dictionary:
	## 死亡イベント: 閾値を大幅に下げ、追悼語彙が定着しやすくする
	return process_conversation(vocabulary, conversation, pet_state, 0.9, "death")


func process_evolution_event(
	vocabulary: Dictionary,
	conversation: Array[Dictionary],
	pet_state: Dictionary
) -> Dictionary:
	## 進化イベント: 新しい語彙が生まれやすい状態にする
	return process_conversation(vocabulary, conversation, pet_state, 0.8, "evolution")


func process_resurrection_event(
	vocabulary: Dictionary,
	conversation: Array[Dictionary],
	pet_state: Dictionary
) -> Dictionary:
	## 復活イベント: 復活に関連する語彙の再活性化
	return process_conversation(vocabulary, conversation, pet_state, 0.95, "resurrection")


func process_breeding_event(
	vocabulary: Dictionary,
	conversation: Array[Dictionary],
	pet_state: Dictionary
) -> Dictionary:
	## 交配イベント: 親の語彙が子に伝わりやすくする
	return process_conversation(vocabulary, conversation, pet_state, 0.7, "breeding")


# ==========================================
#  PetBook統合データ
# ==========================================

func get_petbook_data(result: Dictionary) -> Dictionary:
	## PetBook投稿用のハイライトデータを統合生成
	## 3モデルの中で最も「派手な」結果を採用

	var ai_pb: Dictionary = {}
	var bcm_pb: Dictionary = {}
	var oja_pb: Dictionary = {}

	if not result.get("ai_result", {}).is_empty():
		ai_pb = active_inference.get_petbook_data(result["ai_result"])
	if not result.get("bcm_result", {}).is_empty():
		bcm_pb = bcm_core.get_petbook_bcm_data(result["bcm_result"])
	if not result.get("oja_result", {}).is_empty():
		oja_pb = oja_core.get_petbook_oja_data(result["oja_result"])

	# 最もパーティクル量が多いものを採用
	var best: Dictionary = ai_pb
	var best_particles: int = best.get("particle_amount", 0)

	if bcm_pb.get("particle_amount", 0) > best_particles:
		best = bcm_pb
		best_particles = bcm_pb["particle_amount"]
	if oja_pb.get("particle_amount", 0) > best_particles:
		best = oja_pb

	return best


# ==========================================
#  VFXデータ
# ==========================================

func get_vfx_data(result: Dictionary) -> Dictionary:
	## VFXエフェクト用データを生成
	if not result.get("ai_result", {}).is_empty():
		return active_inference.get_vfx(result["ai_result"])

	# AI結果がない場合はBCM/Ojaから推定
	var bcm: Dictionary = result.get("bcm_result", {})
	var ltp: int = bcm.get("ltp_count", 0)

	if ltp > 3:
		return {"effect": "language_evolution", "color": Color(1.0, 0.8, 0.2),
			"particle_amount": 150, "duration": 4.0}
	elif ltp > 0:
		return {"effect": "language_evolution", "color": Color(0.4, 0.9, 0.4),
			"particle_amount": 60, "duration": 2.0}
	else:
		return {"effect": "language_evolution", "color": Color(0.5, 0.7, 0.5),
			"particle_amount": 25, "duration": 1.5}


# ==========================================
#  コントラスト分析
# ==========================================

func analyze_vocabulary(vocabulary: Dictionary) -> Dictionary:
	## 語彙の健全性を包括的に分析
	var bcm_health: Dictionary = bcm_core.check_vocabulary_health(vocabulary)
	var oja_contrast: Dictionary = oja_core.analyze_contrast(vocabulary)

	return {
		"bcm_health": bcm_health,
		"oja_contrast": oja_contrast,
		"overall_healthy": bcm_health.get("healthy", true) and oja_contrast.get("health", "") != "too_extreme",
		"avg_strength": oja_contrast.get("avg_strength", 0.0),
		"contrast_ratio": oja_contrast.get("contrast_ratio", 1.0),
		"bcm_threshold": bcm_core.get_threshold(),
		"total_cycles": total_cycles,
	}


# ==========================================
#  Multi-Agent連携
# ==========================================

func merge_multi_agent_predictions(
	my_pet_state: Dictionary,
	other_predictions: Array[Dictionary]
) -> Dictionary:
	## 複数ペットの予測を合意形成
	var my_prediction: Dictionary = {
		"emotion": my_pet_state.get("emotion", "neutral"),
		"word": "",
		"confidence": 0.5,
	}
	return active_inference.merge_predictions(my_prediction, other_predictions)


# ==========================================
#  内部ヘルパー
# ==========================================

func _check_health(vocabulary: Dictionary) -> Dictionary:
	var bcm_health: Dictionary = bcm_core.check_vocabulary_health(vocabulary)
	var oja_contrast: Dictionary = oja_core.analyze_contrast(vocabulary)

	var warnings: Array[String] = []
	for w: String in bcm_health.get("warnings", []):
		warnings.append("BCM: " + w)

	var oja_health: String = oja_contrast.get("health", "good")
	if oja_health == "too_extreme":
		warnings.append("Oja: contrast ratio too extreme (%.1f)" % oja_contrast.get("contrast_ratio", 0.0))
	elif oja_health == "stagnant":
		warnings.append("Oja: vocabulary stagnant (std_dev=%.3f)" % oja_contrast.get("std_dev", 0.0))

	return {
		"healthy": warnings.is_empty(),
		"warnings": warnings,
		"bcm_threshold": bcm_core.get_threshold(),
		"contrast_ratio": oja_contrast.get("contrast_ratio", 1.0),
		"avg_strength": oja_contrast.get("avg_strength", 0.0),
	}


func _build_summary(
	ai_result: Dictionary,
	bcm_result: Dictionary,
	oja_result: Dictionary
) -> Dictionary:
	return {
		"ai_action": ai_result.get("action", "skip"),
		"ai_error": ai_result.get("error", 0.0),
		"ai_surprise": ai_result.get("surprise", "none"),
		"bcm_ltp": bcm_result.get("ltp_count", 0),
		"bcm_ltd": bcm_result.get("ltd_count", 0),
		"bcm_threshold": bcm_result.get("threshold", 0.5),
		"oja_normalized": oja_result.get("oja_normalized", oja_result.get("normalized", false)),
		"oja_scale": oja_result.get("oja_scale", oja_result.get("scale_factor", 1.0)),
		"avg_strength": oja_result.get("avg_after", bcm_result.get("avg_strength", 0.0)),
	}


func _update_cumulative_stats(
	ai_result: Dictionary,
	bcm_result: Dictionary,
	oja_result: Dictionary
) -> void:
	cumulative_stats["total_ltp"] += bcm_result.get("ltp_count", 0)
	cumulative_stats["total_ltd"] += bcm_result.get("ltd_count", 0)
	if oja_result.get("oja_normalized", oja_result.get("normalized", false)):
		cumulative_stats["total_normalizations"] += 1
	if ai_result.get("action", "") == "propose_new_word":
		cumulative_stats["total_new_word_proposals"] += 1


# ==========================================
#  セーブ / ロード
# ==========================================

func to_dict() -> Dictionary:
	return {
		"active_inference": active_inference.to_dict(),
		"bcm_core": bcm_core.to_dict(),
		"oja_core": oja_core.to_dict(),
		"total_cycles": total_cycles,
		"cumulative_stats": cumulative_stats.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	if data.has("active_inference"):
		active_inference.from_dict(data["active_inference"])
	if data.has("bcm_core"):
		bcm_core.from_dict(data["bcm_core"])
	if data.has("oja_core"):
		oja_core.from_dict(data["oja_core"])
	total_cycles = data.get("total_cycles", 0)
	cumulative_stats = data.get("cumulative_stats", {
		"total_ltp": 0, "total_ltd": 0,
		"total_normalizations": 0, "total_new_word_proposals": 0,
	})
