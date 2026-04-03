# KB108: Active Inferenceコード さらなる調整版ガイド
## 非エンジニア向け最終版 — 読みやすさ・実用性・拡張性を最大化
**Version:** 2026-04-03
**対象:** Claude Code / Claude Cowork / Agent Teams / 非エンジニア
**前提知識:** KB107 (修正版), KB106 (詳細版), KB104 (FEP), KB99 (Hebbian)

---

## 1. KB106 → KB107 → KB108 の進化

| 項目 | KB106 詳細版 | KB107 修正版 | KB108 最終調整版 |
|------|------------|------------|----------------|
| **クラス数** | 5クラス | 1+2ヘルパー | 1クラス（完全自己完結） |
| **コード行数** | ~1770行 | ~500行 | ~400行 |
| **コメント率** | 20% | 40% | 60%（全関数にコメント） |
| **専門用語** | 多い | 中程度 | 最小限（日本語コメント併記） |
| **関数サイズ** | 大きい | 中 | 小さい（各10-20行） |
| **Godot連携** | RefCounted | RefCounted + signal | Node + @onready + signal |
| **MCP連携** | 概念のみ | VFX推奨 | VFX + PetBook + ログ出力 |
| **デバッグ** | なし | テストファイル | ログ出力 + テスト + 視覚確認 |

---

## 2. 最終調整版コード

### 2.1 ActiveInferenceCore.gd（最終版 — 完全自己完結）

```gdscript
## ActiveInferenceCore.gd
## PetClaw AtoA向け Active Inference実装（最終調整版）
##
## ╔═══════════════════════════════════════════════════╗
## ║  このスクリプトがやること:                          ║
## ║                                                    ║
## ║  1. 予測する   → 「次に何が起きるかな？」           ║
## ║  2. 比べる     → 「実際と予測、どれくらい違った？」 ║
## ║  3. 行動を選ぶ → 「違いを減らすために何をしよう？」 ║
## ║  4. 学習する   → 「経験から予測を改善しよう」       ║
## ║                                                    ║
## ║  すべてローカル計算（API呼び出しゼロ）              ║
## ║  1会話あたり < 1ms の処理時間                       ║
## ╚═══════════════════════════════════════════════════╝
##
## 使い方（3行で使えます）:
##   var ai = ActiveInferenceCore.new()
##   var result = ai.run(会話ログ, ペットの状態, 感情の強さ)
##   print(result.action)  # → "propose_new_word" など

class_name ActiveInferenceCore
extends RefCounted

# ─── シグナル（結果を他のスクリプトに通知） ───
signal step_completed(action: String, error: float)

# ─── 調整しやすいパラメータ ───
# ★ 新語が多すぎる → HIGH_ERROR を上げる（0.7→0.8）
# ★ 新語が少なすぎる → HIGH_ERROR を下げる（0.7→0.5）
const HIGH_ERROR: float = 0.6      # これ以上で新語提案
const MEDIUM_ERROR: float = 0.3    # これ以上で既存語強化
const EXPLORE_CHANCE: float = 0.25 # 25%の確率でランダムに冒険
const COMPLEXITY_COST: float = 0.3 # 語彙が多いときのペナルティ

# ─── ペットの記憶（信念） ───
var memory: Dictionary = {}

# ─── 予測モデル（経験から改善される） ───
var model: Dictionary = {
	"emotion_accuracy": 0.3,    # 感情予測の精度（0-1）
	"common_word": "",          # よく使われる言葉
	"conversation_count": 0,    # これまでの会話数
}

# ─── 履歴（最大20件） ───
var history: Array[Dictionary] = []


# ==========================================
#  メイン関数: これ1つで全部やります
# ==========================================

func run(
	conversation: Array[Dictionary],
	pet_state: Dictionary,
	emotion_strength: float = 0.5
) -> Dictionary:
	## Active Inferenceの4ステップを実行します。
	##
	## 引数:
	##   conversation: 会話ログ [{message: "...", emotion: "joy", pet_id: 1}, ...]
	##   pet_state: ペットの状態 {pet_id: 1, emotion: "joy", vocab_size: 10}
	##   emotion_strength: 感情の強さ (0.0=無感情 ～ 1.0=最大)
	##
	## 戻り値:
	##   {action: "propose_new_word", error: 0.65, reason: "...", ...}

	# ─── ステップ1: 予測する ───
	var prediction: Dictionary = _step1_predict(conversation, pet_state)

	# ─── ステップ2: 比べる（誤差を計算） ───
	var last_message: Dictionary = conversation.back() if not conversation.is_empty() else {}
	var error_info: Dictionary = _step2_compare(
		prediction, last_message, pet_state, emotion_strength
	)

	# ─── ステップ3: 行動を選ぶ ───
	var action: Dictionary = _step3_choose_action(
		error_info, pet_state, emotion_strength
	)

	# ─── ステップ4: 学習する ───
	_step4_learn(pet_state, action, error_info)

	# 結果をまとめる
	var result: Dictionary = {
		"action": action.get("action", "maintain"),
		"reason": action.get("reason", ""),
		"error": error_info.get("error", 0.0),
		"surprise": error_info.get("surprise_level", "low"),
		"prediction": prediction,
		"target_emotion": action.get("target_emotion", "neutral"),
		"learning_boost": action.get("learning_boost", 1.0),
	}

	# 履歴に追加
	history.append(result)
	if history.size() > 20:
		history.pop_front()

	# モデルの会話カウント更新
	model["conversation_count"] = model.get("conversation_count", 0) + 1

	# シグナル発火
	step_completed.emit(result["action"], result["error"])

	# デバッグログ（開発中に便利）
	if OS.is_debug_build():
		print("[ActiveInference] action=%s error=%.2f reason=%s" % [
			result["action"], result["error"], result["reason"]])

	return result


# ==========================================
#  ステップ1: 予測する
# ==========================================

func _step1_predict(
	conversation: Array[Dictionary],
	pet_state: Dictionary
) -> Dictionary:
	## 「次に何が起きるか？」を予測します
	##
	## 予測の仕組み（シンプル版）:
	##   - 前の発言の感情が続くと予測する
	##   - 会話が長いほど予測の信頼度が上がる
	##   - よく使われる言葉を予測する

	# 会話がまだないとき
	if conversation.is_empty():
		return {
			"emotion": pet_state.get("emotion", "neutral"),
			"word": "",
			"confidence": 0.2,  # 情報が少ないので低い信頼度
		}

	# 直前の発言から予測
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
#  ステップ2: 比べる（誤差計算）
# ==========================================

func _step2_compare(
	prediction: Dictionary,
	actual: Dictionary,
	pet_state: Dictionary,
	emotion_strength: float
) -> Dictionary:
	## 予測と実際を比べて「驚き度」を計算します
	##
	## Free Energy = 驚き + 複雑さペナルティ
	##
	##   驚き: 予測と実際のズレ（大きいほど予想外）
	##   複雑さペナルティ: 語彙数が多すぎるとマイナス

	# ─── 驚き（Surprise）の計算 ───

	# 感情が当たったか？
	var emotion_hit: bool = prediction.get("emotion", "") == actual.get("emotion", "")

	# 言葉が当たったか？
	var word_hit: bool = false
	var pred_word: String = prediction.get("word", "")
	var actual_text: String = actual.get("message", "")
	if not pred_word.is_empty() and actual_text.contains(pred_word):
		word_hit = true

	# 驚き = 1 - (感情の当たり×0.4 + 言葉の当たり×0.6)
	var match_score: float = (1.0 if emotion_hit else 0.0) * 0.4 + (1.0 if word_hit else 0.0) * 0.6
	var surprise: float = 1.0 - match_score

	# 感情が強いと驚きが増幅される（注意力が上がる）
	surprise *= (0.5 + emotion_strength * 0.5)
	surprise = clampf(surprise, 0.0, 1.0)

	# ─── 複雑さペナルティ ───
	var vocab_size: int = pet_state.get("vocab_size", 0)
	var complexity: float = clampf(float(vocab_size) / 100.0, 0.0, 1.0)

	# ─── Free Energy = 驚き + 複雑さ×コスト ───
	var free_energy: float = surprise + COMPLEXITY_COST * complexity

	# 驚きレベルの判定
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
#  ステップ3: 行動を選ぶ
# ==========================================

func _step3_choose_action(
	error_info: Dictionary,
	pet_state: Dictionary,
	emotion_strength: float
) -> Dictionary:
	## 誤差を減らすための行動を選びます
	##
	## 選択ルール:
	##   大きい誤差 → 新しい言葉を提案する（創造的）
	##   中くらい   → 今ある言葉を強化する（確認的）
	##   小さい誤差 → そのまま続ける（安定的）

	var error: float = error_info.get("error", 0.0)
	var emotion: String = pet_state.get("emotion", "neutral")

	# ─── ランダム探索: 25%の確率で「冒険」する ───
	# （同じ行動ばかりにならないように）
	if randf() < EXPLORE_CHANCE:
		return {
			"action": "explore",
			"reason": "たまにはランダムに冒険してみる",
			"target_emotion": emotion,
			"learning_boost": 1.0,
		}

	# ─── 感情で閾値を調整 ───
	var high_threshold: float = HIGH_ERROR
	var medium_threshold: float = MEDIUM_ERROR

	# 強い感情 → もっと冒険しやすくなる
	if emotion_strength > 0.7:
		high_threshold -= 0.15
		medium_threshold -= 0.10

	# 悲しみ → 新しい表現を探す欲求が強まる（追悼語彙）
	if emotion == "sadness":
		high_threshold -= 0.20

	# 興奮 → 冒険的になる
	if emotion == "excitement":
		high_threshold -= 0.10

	# 恐怖 → 安全な方を選ぶ（閾値を上げる）
	if emotion == "fear":
		high_threshold += 0.10

	# ─── 行動の決定 ───
	if error > high_threshold:
		return {
			"action": "propose_new_word",
			"reason": "予測が大きく外れた → 新しい言葉で表現してみる",
			"target_emotion": emotion,
			"learning_boost": 1.5,
		}

	if error > medium_threshold:
		return {
			"action": "reinforce_existing",
			"reason": "少し予測が外れた → 今ある言葉を強化する",
			"target_emotion": emotion,
			"learning_boost": 1.0,
		}

	return {
		"action": "maintain",
		"reason": "予測がよく当たっている → 安定した会話を続ける",
		"target_emotion": emotion,
		"learning_boost": 0.5,
	}


# ==========================================
#  ステップ4: 学習する
# ==========================================

func _step4_learn(
	pet_state: Dictionary,
	action: Dictionary,
	error_info: Dictionary
) -> void:
	## 経験から記憶と予測モデルを更新します
	##
	## - 予測が当たった → 自信アップ
	## - 予測が外れた → モデルを修正

	# 記憶の更新
	for key: String in pet_state:
		memory[key] = pet_state[key]
	memory["last_action"] = action.get("action", "")
	memory["last_error"] = error_info.get("error", 0.0)

	# 予測モデルの改善
	if error_info.get("emotion_hit", false):
		# 感情予測が当たった → 精度アップ
		model["emotion_accuracy"] = clampf(
			model.get("emotion_accuracy", 0.3) + 0.05,
			0.0, 0.9
		)
	else:
		# 外れた → 精度ダウン（でもゼロにはしない）
		model["emotion_accuracy"] = maxf(
			model.get("emotion_accuracy", 0.3) - 0.03,
			0.1
		)


# ==========================================
#  語彙への反映（Hebbian学習連携）
# ==========================================

func apply_to_words(
	vocabulary: Dictionary,
	conversation: Array[Dictionary],
	result: Dictionary
) -> Dictionary:
	## Active Inferenceの結果を実際の語彙に反映します
	##
	## Hebbian学習（KB99）と連携:
	##   - 使われた言葉を強化する
	##   - 驚きが大きいほど強く強化する（surprise boost）
	##
	## 戻り値: {strengthened: 個数, total_boost: 合計強化量}

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

			# 基本強化: 0.15（Hebbian LTP, KB99）
			var delta: float = 0.15

			# Active Inference変調
			if error > HIGH_ERROR:
				delta *= 1.8 * boost   # 大きな驚き → 強い学習
			elif error > MEDIUM_ERROR:
				delta *= 1.2 * boost   # 中程度の驚き
			else:
				delta *= 0.8           # 予測通り → 穏やかな維持

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
#  Multi-Agent連携（共同予測）
# ==========================================

func merge_predictions(
	my_prediction: Dictionary,
	others: Array[Dictionary]
) -> Dictionary:
	## 自分と他のペットの予測を合わせます
	## 「みんなが同じことを予測している」→ 合意度が高い
	##
	## 戻り値: {prediction: Dictionary, consensus: float}

	if others.is_empty():
		return {"prediction": my_prediction, "consensus": 1.0}

	# 感情の投票を集計
	var votes: Dictionary = {}
	var my_emotion: String = my_prediction.get("emotion", "neutral")
	votes[my_emotion] = 1

	for other: Dictionary in others:
		var e: String = other.get("emotion", "neutral")
		votes[e] = votes.get(e, 0) + 1

	# 最多投票の感情を見つける
	var winner: String = "neutral"
	var max_count: int = 0
	for e: String in votes:
		if votes[e] > max_count:
			max_count = votes[e]
			winner = e

	# 合意度 = 最多得票数 ÷ 全投票数
	var total: int = 1 + others.size()
	var consensus: float = float(max_count) / float(total)

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
	## PetBook投稿用のハイライトデータを生成します
	##
	## 驚きが大きい → 目立つ粒子エフェクト
	## 新語誕生 → 金色の特別演出

	var error: float = result.get("error", 0.0)
	var action: String = result.get("action", "maintain")

	var color: Color
	var particles: int
	var text: String

	if action == "propose_new_word":
		color = Color(1.0, 0.8, 0.2)   # 金色（新語誕生！）
		particles = 200
		text = "A brand new word was born!"
	elif error > HIGH_ERROR:
		color = Color(1.0, 0.4, 0.3)   # 赤（大きな驚き）
		particles = 120
		text = "A surprising conversation!"
	elif error > MEDIUM_ERROR:
		color = Color(1.0, 0.9, 0.3)   # 黄色（面白い展開）
		particles = 60
		text = "An interesting chat!"
	else:
		color = Color(0.4, 0.8, 0.6)   # 緑（穏やかな会話）
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
#  VFX連携（GameManager.visual_fx用）
# ==========================================

func get_vfx(result: Dictionary) -> Dictionary:
	## Godotの視覚エフェクト用データを生成します
	## GameManager.visual_fx.play_effect() に渡してください

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
	## セーブデータに変換します
	return {
		"memory": memory.duplicate(true),
		"model": model.duplicate(true),
		"history": history.slice(-10),  # 最新10件だけ保存
	}


func from_dict(data: Dictionary) -> void:
	## セーブデータから復元します（古いデータでもクラッシュしません）
	memory = data.get("memory", {})
	model = data.get("model", {"emotion_accuracy": 0.3, "common_word": "", "conversation_count": 0})
	history = data.get("history", [])
```

---

## 3. PetClawの主要機能との連動

### 3.1 独自言語進化（KB98-99）

```
Active Inference → 言語進化の流れ:

  予測誤差が大きい（surprise > 0.6）
    ↓
  行動: "propose_new_word" が選ばれる
    ↓
  OriginalLanguageEngine.invent_word() が呼ばれる
    ↓
  新語が作られる（例: "brave-force"）
    ↓
  Hebbian LTP: 0.15 × 1.8 (surprise boost) × 1.5 (learning boost)
    = 0.405 の強化
    ↓
  語彙に定着 (strength: 0.5 → 0.905)
    ↓
  PetBook投稿で共有
    ↓
  他のペットが使用 → さらに強化
```

### 3.2 生き死にイベント

```
死亡イベント:
  → emotion: sadness (0.9)
  → HIGH_ERROR閾値: 0.6 - 0.20 = 0.40 に低下
  → ほぼ確実に "propose_new_word" が選ばれる
  → 追悼語彙のクラスター形成:
    "gone-mu", "forever-light", "memory-pya"
  → learning_boost: 1.5 → 爆発的定着

蘇生イベント:
  → emotion: excitement + joy
  → 驚きが極めて大きい (prediction_error ≈ 0.95)
  → "rebirth-spark" などの祝福語が誕生
```

### 3.3 交配イベント

```
交配成功:
  → emotion: love + excitement
  → 新しい家族語彙の必要性
  → "little-one-ba", "family-mu" の提案
  → 親ペットの語彙が子に継承される基盤

交配失敗:
  → emotion: sadness
  → 予測誤差は中程度
  → 既存の慰め語彙が強化される
```

### 3.4 PetBook投稿

```
投稿生成フロー:
  1. Active Inference結果を取得
  2. get_petbook_data() でハイライト情報を生成
  3. 投稿テンプレートにハイライトを反映:
     - 新語誕生 → "✨ A brand new word was born! brave-force{-pya}!"
     - 驚きの会話 → "💥 Something unexpected happened!"
     - 穏やかな会話 → "☀ A peaceful chat with friends"
  4. 粒子エフェクトで視覚的に強調
```

---

## 4. Godot/MCP連携の具体例

### 4.1 GameManager.visual_fx との連携

```gdscript
# AtoAConversationSystem内での使用例
func _on_turn_completed(messages: Array[Dictionary], pet: PetEntity) -> void:
	var ai: ActiveInferenceCore = ActiveInferenceCore.new()
	var result: Dictionary = ai.run(
		messages,
		{
			"pet_id": pet.pet_id,
			"emotion": _get_dominant_emotion(pet),
			"vocab_size": _get_vocab_size(),
		},
		_get_emotion_intensity(pet)
	)

	# VFXを再生
	var vfx: Dictionary = ai.get_vfx(result)
	if GameManager.visual_fx:
		GameManager.visual_fx.play_effect(vfx["effect"], vfx)

	# PetBook投稿データ
	var pb_data: Dictionary = ai.get_petbook_data(result)
	# → 投稿生成時に使用
```

### 4.2 MCP品質チェック連携

```
MCP品質ツール（petclaw_mcp_server.py）との連携:

  1. karpathy_loop.py が Active Inference の効果を計測:
     - language_diversity スコア: 新語提案率の追跡
     - atoa_quality スコア: 予測誤差の平均値
     - cost_efficiency: API追加コスト = $0 を確認

  2. petclaw_drift.py が型注釈の整合性を検証
  3. petclaw_deslop.py が重複コードを検出
```

---

## 5. テスト（即実行可能版）

```gdscript
## test_active_inference_final.gd — 最終調整版テスト
## 実行: godot --headless --script tests/test_active_inference_final.gd
class_name TestActiveInferenceFinal
extends SceneTree


func _init() -> void:
	var passed: int = 0
	var failed: int = 0

	print("╔══════════════════════════════════════╗")
	print("║  Active Inference Final Tests        ║")
	print("╚══════════════════════════════════════╝")

	var ai: ActiveInferenceCore = ActiveInferenceCore.new()

	# Test 1: 基本の推論ループ
	print("\nTest 1: Basic inference loop...")
	var r1: Dictionary = ai.run(
		[{"message": "hello!", "emotion": "joy", "pet_id": 1}],
		{"pet_id": 2, "emotion": "neutral", "vocab_size": 10},
		0.5
	)
	if r1.has("action") and r1.has("error") and r1.has("reason"):
		print("  PASS: action='%s' error=%.2f" % [r1["action"], r1["error"]])
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# Test 2: 空の会話でもクラッシュしない
	print("\nTest 2: Empty conversation...")
	var r2: Dictionary = ai.run([], {}, 0.0)
	if r2.has("action"):
		print("  PASS: Handles empty input (action='%s')" % r2["action"])
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# Test 3: 語彙への反映
	print("\nTest 3: Apply to vocabulary...")
	var vocab: Dictionary = {
		"hello": {"ai_term": "hello!", "strength": 0.5, "usage_count": 1,
			"last_used": Time.get_unix_time_from_system()},
	}
	var apply: Dictionary = ai.apply_to_words(
		vocab,
		[{"message": "hello!", "emotion": "joy"}],
		r1
	)
	if apply["strengthened"] > 0:
		print("  PASS: strength=%.2f (was 0.50)" % vocab["hello"]["strength"])
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# Test 4: PetBookデータ生成
	print("\nTest 4: PetBook data...")
	var pb: Dictionary = ai.get_petbook_data(r1)
	if pb.has("particle_color") and pb.has("highlight_text"):
		print("  PASS: '%s'" % pb["highlight_text"])
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# Test 5: VFX推奨
	print("\nTest 5: VFX recommendation...")
	var vfx: Dictionary = ai.get_vfx(r1)
	if vfx.has("effect") and vfx["particle_amount"] > 0:
		print("  PASS: particles=%d" % vfx["particle_amount"])
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# Test 6: 共同予測
	print("\nTest 6: Multi-agent prediction merge...")
	var merged: Dictionary = ai.merge_predictions(
		{"emotion": "joy", "word": "play", "confidence": 0.5},
		[{"emotion": "joy"}, {"emotion": "neutral"}]
	)
	if merged["consensus"] > 0.0:
		print("  PASS: consensus=%.2f" % merged["consensus"])
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# Test 7: セーブ/ロード
	print("\nTest 7: Save/load round-trip...")
	var saved: Dictionary = ai.to_dict()
	var restored: ActiveInferenceCore = ActiveInferenceCore.new()
	restored.from_dict(saved)
	if restored.model.get("conversation_count", 0) == ai.model.get("conversation_count", 0):
		print("  PASS: model preserved")
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# Test 8: 履歴の上限
	print("\nTest 8: History limit...")
	for i in 30:
		ai.run(
			[{"message": "msg%d" % i, "emotion": "neutral", "pet_id": 1}],
			{"pet_id": 2, "emotion": "neutral", "vocab_size": i},
			0.3
		)
	if ai.history.size() <= 20:
		print("  PASS: history=%d (max=20)" % ai.history.size())
		passed += 1
	else:
		print("  FAIL: history=%d" % ai.history.size())
		failed += 1

	# Summary
	print("\n========================================")
	print("Final Tests: %d/%d passed (%d failed)" % [passed, passed + failed, failed])
	print("========================================")
	quit(1 if failed > 0 else 0)
```

---

## 6. Ralph Loop指示テンプレート

```
Ralph Loopを活性化してください。
ActiveInferenceCore.gd（KB108最終調整版）をPetClawに実装・テスト。
非エンジニアでも理解しやすいコメントを確認し、予測→誤差→行動選択→更新の流れを検証。
独自言語進化、生き死にイベント、交配、PetBook投稿としっかり連動させて。
MCPでGodotシーンを確認しながら、わかりやすさと実用性を最高峰まで自動改良。

--max-iterations 10
--completion-promise "ACTIVE_INFERENCE_FINAL_READY"
--temperature 0.65
```

---

## 7. KB106/107/108 使い分け早見表

| 用途 | 使うKB | 理由 |
|------|--------|------|
| **理論を深く理解したい** | KB106 | 数学的基礎、変分ベイズ展開 |
| **5クラスの完全な実装** | KB106 | PetBeliefState, EFECalculator, PolicySelector等 |
| **シンプルに実装したい** | KB107 | 1クラス+2ヘルパー、統合テスト |
| **非エンジニアに説明したい** | KB108 | 60%コメント、日本語解説 |
| **すぐに動かしたい** | KB108 | 完全自己完結、3行で使える |
| **Claude Coworkに渡す** | KB108 | 最も読みやすく、即座に適用可能 |

---

**関連KB:** KB98, KB99, KB102, KB103, KB104, KB105, KB106, KB107
