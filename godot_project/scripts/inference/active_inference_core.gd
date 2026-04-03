## active_inference_core.gd
## PetClaw AtoA向け Active Inference実装
##
## 予測 → 比較 → 行動選択 → 学習 の4ステップをローカルで実行
## API呼び出しゼロ、1会話あたり < 1ms
##
## 使い方:
##   var ai := ActiveInferenceCore.new()
##   var result := ai.run(conversation, pet_state, emotion_strength)
##   print(result.action)  # "propose_new_word" / "reinforce_existing" / "maintain" / "explore"
##
## KB参照: KB104 (FEP), KB107 (修正版), KB108 (最終調整版)
class_name ActiveInferenceCore
extends RefCounted

# ─── シグナル ───
signal step_completed(action: String, error: float)

# ─── 調整パラメータ ───
# 新語が多すぎる → HIGH_ERROR を上げる（0.6→0.8）
# 新語が少なすぎる → HIGH_ERROR を下げる（0.6→0.4）
const HIGH_ERROR: float = 0.6
const MEDIUM_ERROR: float = 0.3
const EXPLORE_CHANCE: float = 0.25
const COMPLEXITY_COST: float = 0.3

# Hebbian学習連携（KB99）
const HEBBIAN_LTP: float = 0.15
const HIGH_SURPRISE_MULTIPLIER: float = 1.8
const MEDIUM_SURPRISE_MULTIPLIER: float = 1.2
const LOW_SURPRISE_MULTIPLIER: float = 0.8

# 履歴上限
const MAX_HISTORY: int = 20

# ─── ペットの記憶（信念） ───
var memory: Dictionary = {}

# ─── 予測モデル（経験から改善） ───
var model: Dictionary = {
	"emotion_accuracy": 0.3,
	"common_word": "",
	"conversation_count": 0,
}

# ─── 履歴 ───
var history: Array[Dictionary] = []


# ==========================================
#  メイン関数
# ==========================================

func run(
	conversation: Array[Dictionary],
	pet_state: Dictionary,
	emotion_strength: float = 0.5
) -> Dictionary:
	## Active Inferenceの4ステップを実行
	##
	## 引数:
	##   conversation: [{message: "...", emotion: "joy", pet_id: 1}, ...]
	##   pet_state: {pet_id: 1, emotion: "joy", vocab_size: 10}
	##   emotion_strength: 感情の強さ (0.0～1.0)
	##
	## 戻り値:
	##   {action, reason, error, surprise, prediction, target_emotion, learning_boost}

	# ステップ1: 予測
	var prediction: Dictionary = _step1_predict(conversation, pet_state)

	# ステップ2: 比較（誤差計算）
	var last_message: Dictionary = conversation.back() if not conversation.is_empty() else {}
	var error_info: Dictionary = _step2_compare(
		prediction, last_message, pet_state, emotion_strength
	)

	# ステップ3: 行動選択
	var action: Dictionary = _step3_choose_action(
		error_info, pet_state, emotion_strength
	)

	# ステップ4: 学習
	_step4_learn(pet_state, action, error_info)

	# 結果をまとめる
	var result: Dictionary = {
		"action": action.get("action", "maintain"),
		"reason": action.get("reason", ""),
		"error": error_info.get("error", 0.0),
		"surprise": error_info.get("surprise_level", "low"),
		"free_energy": error_info.get("free_energy", 0.0),
		"prediction": prediction,
		"target_emotion": action.get("target_emotion", "neutral"),
		"learning_boost": action.get("learning_boost", 1.0),
	}

	# 履歴に追加（上限管理）
	history.append(result)
	if history.size() > MAX_HISTORY:
		history.pop_front()

	# 会話カウント更新
	model["conversation_count"] = model.get("conversation_count", 0) + 1

	# シグナル発火
	step_completed.emit(result["action"], result["error"])

	# デバッグログ
	if OS.is_debug_build():
		print("[ActiveInference] action=%s error=%.2f fe=%.2f reason=%s" % [
			result["action"], result["error"], result["free_energy"], result["reason"]])

	return result


# ==========================================
#  ステップ1: 予測
# ==========================================

func _step1_predict(
	conversation: Array[Dictionary],
	pet_state: Dictionary
) -> Dictionary:
	## 次の会話展開を予測する
	## - 前の発言の感情が続くと予測
	## - 会話が長いほど信頼度が上がる

	if conversation.is_empty():
		return {
			"emotion": pet_state.get("emotion", "neutral"),
			"word": "",
			"confidence": 0.2,
		}

	var last: Dictionary = conversation.back()
	var predicted_emotion: String = last.get("emotion", "neutral")
	var predicted_word: String = model.get("common_word", "")

	# 信頼度: 会話が長いほど上がる（最大0.8）
	var confidence: float = clampf(
		0.2 + conversation.size() * 0.08,
		0.1, 0.8
	)

	return {
		"emotion": predicted_emotion,
		"word": predicted_word,
		"confidence": confidence,
	}


# ==========================================
#  ステップ2: 比較（Variational Free Energy）
# ==========================================

func _step2_compare(
	prediction: Dictionary,
	actual: Dictionary,
	pet_state: Dictionary,
	emotion_strength: float
) -> Dictionary:
	## 予測と実際を比べて驚き度を計算
	## Free Energy = surprise + COMPLEXITY_COST * complexity

	# 感情予測の一致判定
	var emotion_hit: bool = (
		prediction.get("emotion", "") == actual.get("emotion", "")
	)

	# 言葉予測の一致判定
	var word_hit: bool = false
	var pred_word: String = prediction.get("word", "")
	var actual_text: String = actual.get("message", "")
	if not pred_word.is_empty() and actual_text.contains(pred_word):
		word_hit = true

	# surprise = 1 - (emotion_match * 0.4 + word_match * 0.6)
	var match_score: float = (
		(1.0 if emotion_hit else 0.0) * 0.4
		+ (1.0 if word_hit else 0.0) * 0.6
	)
	var surprise: float = 1.0 - match_score

	# 感情が強いと驚きが増幅（注意力の上昇）
	surprise *= (0.5 + emotion_strength * 0.5)
	surprise = clampf(surprise, 0.0, 1.0)

	# 複雑さペナルティ（語彙が多いほど高い）
	var vocab_size: int = pet_state.get("vocab_size", 0)
	var complexity: float = clampf(float(vocab_size) / 100.0, 0.0, 1.0)

	# Variational Free Energy
	var free_energy: float = surprise + COMPLEXITY_COST * complexity

	# 驚きレベル判定
	var level: String = "low"
	if surprise > 0.7:
		level = "high"
	elif surprise > 0.4:
		level = "medium"

	return {
		"error": surprise,
		"free_energy": free_energy,
		"complexity": complexity,
		"surprise_level": level,
		"emotion_hit": emotion_hit,
		"word_hit": word_hit,
	}


# ==========================================
#  ステップ3: 行動選択（Expected Free Energy）
# ==========================================

func _step3_choose_action(
	error_info: Dictionary,
	pet_state: Dictionary,
	emotion_strength: float
) -> Dictionary:
	## 誤差を減らすための行動を選択
	## 大誤差 → propose_new_word（創造的）
	## 中誤差 → reinforce_existing（確認的）
	## 小誤差 → maintain（安定的）

	var error: float = error_info.get("error", 0.0)
	var emotion: String = pet_state.get("emotion", "neutral")

	# ランダム探索（25%）: 同じ行動ばかりにならないように
	if randf() < EXPLORE_CHANCE:
		return {
			"action": "explore",
			"reason": "random exploration for diversity",
			"target_emotion": emotion,
			"learning_boost": 1.0,
		}

	# 感情で閾値を調整
	var high_threshold: float = HIGH_ERROR
	var medium_threshold: float = MEDIUM_ERROR

	# 強い感情 → 冒険しやすくなる
	if emotion_strength > 0.7:
		high_threshold -= 0.15
		medium_threshold -= 0.10

	# 感情別の閾値調整
	match emotion:
		"sadness":
			high_threshold -= 0.20   # 追悼語彙の創出を促進
		"excitement":
			high_threshold -= 0.10   # 冒険的
		"fear":
			high_threshold += 0.10   # 安全志向

	# 行動決定
	if error > high_threshold:
		return {
			"action": "propose_new_word",
			"reason": "high prediction error triggers new word creation",
			"target_emotion": emotion,
			"learning_boost": 1.5,
		}

	if error > medium_threshold:
		return {
			"action": "reinforce_existing",
			"reason": "moderate prediction error reinforces existing vocabulary",
			"target_emotion": emotion,
			"learning_boost": 1.0,
		}

	return {
		"action": "maintain",
		"reason": "prediction accurate, maintaining stable conversation",
		"target_emotion": emotion,
		"learning_boost": 0.5,
	}


# ==========================================
#  ステップ4: 学習（Belief Update）
# ==========================================

func _step4_learn(
	pet_state: Dictionary,
	action: Dictionary,
	error_info: Dictionary
) -> void:
	## 経験から記憶と予測モデルを更新
	## - 予測が当たった → 感情精度アップ
	## - 予測が外れた → 感情精度ダウン

	# 記憶の更新
	for key: String in pet_state:
		memory[key] = pet_state[key]
	memory["last_action"] = action.get("action", "")
	memory["last_error"] = error_info.get("error", 0.0)

	# 予測モデルの改善
	if error_info.get("emotion_hit", false):
		model["emotion_accuracy"] = clampf(
			model.get("emotion_accuracy", 0.3) + 0.05,
			0.0, 0.9
		)
	else:
		model["emotion_accuracy"] = maxf(
			model.get("emotion_accuracy", 0.3) - 0.03,
			0.1
		)


# ==========================================
#  語彙への反映（Hebbian学習連携 — KB99）
# ==========================================

func apply_to_words(
	vocabulary: Dictionary,
	conversation: Array[Dictionary],
	result: Dictionary
) -> Dictionary:
	## Active Inferenceの結果を語彙のHebbian強度に反映
	##
	## 戻り値: {strengthened: int, total_boost: float}

	var boost: float = result.get("learning_boost", 1.0)
	var error: float = result.get("error", 0.0)
	var count: int = 0
	var total: float = 0.0

	for msg: Dictionary in conversation:
		var text: String = msg.get("message", "")

		for word: String in vocabulary:
			var ai_term: String = vocabulary[word].get("ai_term", "")
			if ai_term.is_empty() or not text.contains(ai_term):
				continue

			# 基本強化: Hebbian LTP (0.15)
			var delta: float = HEBBIAN_LTP

			# Active Inference変調: 驚きの大きさで強化度を調整
			if error > HIGH_ERROR:
				delta *= HIGH_SURPRISE_MULTIPLIER * boost
			elif error > MEDIUM_ERROR:
				delta *= MEDIUM_SURPRISE_MULTIPLIER * boost
			else:
				delta *= LOW_SURPRISE_MULTIPLIER

			# 語彙に反映
			vocabulary[word]["strength"] = clampf(
				vocabulary[word].get("strength", 0.5) + delta,
				0.0, 1.0
			)
			vocabulary[word]["usage_count"] = vocabulary[word].get("usage_count", 0) + 1
			vocabulary[word]["last_used"] = Time.get_unix_time_from_system()

			count += 1
			total += delta

	return {"strengthened": count, "total_boost": total}


# ==========================================
#  Multi-Agent連携（Shared Protention）
# ==========================================

func merge_predictions(
	my_prediction: Dictionary,
	others: Array[Dictionary]
) -> Dictionary:
	## 自分と他ペットの予測を合わせて合意度を計算
	##
	## 戻り値: {prediction: Dictionary, consensus: float}

	if others.is_empty():
		return {"prediction": my_prediction, "consensus": 1.0}

	# 感情の投票集計
	var votes: Dictionary = {}
	var my_emotion: String = my_prediction.get("emotion", "neutral")
	votes[my_emotion] = 1

	for other: Dictionary in others:
		var e: String = other.get("emotion", "neutral")
		votes[e] = votes.get(e, 0) + 1

	# 最多投票の感情
	var winner: String = "neutral"
	var max_count: int = 0
	for e: String in votes:
		if votes[e] > max_count:
			max_count = votes[e]
			winner = e

	# 合意度 = 最多得票数 / 全投票数
	var total_votes: int = 1 + others.size()
	var consensus: float = float(max_count) / float(total_votes)

	return {
		"prediction": {
			"emotion": winner,
			"word": my_prediction.get("word", ""),
			"confidence": my_prediction.get("confidence", 0.3) * consensus,
		},
		"consensus": consensus,
	}


# ==========================================
#  PetBook連携
# ==========================================

func get_petbook_data(result: Dictionary) -> Dictionary:
	## PetBook投稿用のハイライトデータを生成
	## 驚きが大きいほど派手な演出

	var error: float = result.get("error", 0.0)
	var action: String = result.get("action", "maintain")

	var color: Color
	var particles: int
	var text: String

	if action == "propose_new_word":
		color = Color(1.0, 0.8, 0.2)   # 金色
		particles = 200
		text = "A brand new word was born!"
	elif error > HIGH_ERROR:
		color = Color(1.0, 0.4, 0.3)   # 赤
		particles = 120
		text = "A surprising conversation!"
	elif error > MEDIUM_ERROR:
		color = Color(1.0, 0.9, 0.3)   # 黄
		particles = 60
		text = "An interesting chat!"
	else:
		color = Color(0.4, 0.8, 0.6)   # 緑
		particles = 30
		text = "A peaceful conversation"

	return {
		"particle_color": color,
		"particle_amount": particles,
		"particle_duration": 1.5 + error * 3.0,
		"highlight_text": text,
		"surprise_level": result.get("surprise", "low"),
	}


# ==========================================
#  VFX連携
# ==========================================

func get_vfx(result: Dictionary) -> Dictionary:
	## GameManager.visual_fx.play_effect() 用のデータ生成

	var level: String = result.get("surprise", "low")

	match level:
		"high":
			return {
				"effect": "language_evolution",
				"color": Color(1.0, 0.4, 0.3),
				"particle_amount": 150,
				"duration": 4.0,
			}
		"medium":
			return {
				"effect": "language_evolution",
				"color": Color(1.0, 0.9, 0.3),
				"particle_amount": 80,
				"duration": 2.5,
			}
		_:
			return {
				"effect": "language_evolution",
				"color": Color(0.4, 0.8, 0.6),
				"particle_amount": 30,
				"duration": 1.5,
			}


# ==========================================
#  セーブ / ロード
# ==========================================

func to_dict() -> Dictionary:
	return {
		"memory": memory.duplicate(true),
		"model": model.duplicate(true),
		"history": history.slice(-10),  # 最新10件のみ保存
	}


func from_dict(data: Dictionary) -> void:
	memory = data.get("memory", {})
	model = data.get("model", {
		"emotion_accuracy": 0.3,
		"common_word": "",
		"conversation_count": 0,
	})
	history = []
	var raw_history: Array = data.get("history", [])
	for item: Variant in raw_history:
		if item is Dictionary:
			history.append(item)
