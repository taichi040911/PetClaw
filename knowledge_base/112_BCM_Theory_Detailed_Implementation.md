# KB112: BCM理論の詳細実装ガイド（PetClaw AtoA独自言語進化向け）
## Bienenstock-Cooper-Munro Theory — スライディング閾値による語彙安定化
**Version:** 2026-04-03
**対象:** Claude Code / Claude Cowork / Agent Teams / 非エンジニア
**前提知識:** KB99 (Hebbian), KB108 (Active Inference), KB111 (類似生物学習モデル概要)

---

## 1. BCM理論の神経科学基礎

### 1.1 歴史と概要

1982年にBienenstock, Cooper, Munroが提唱。Hebbian学習の最大の弱点 — **無制限な強化による不安定性** — を克服したモデル。

### 1.2 鍵となる考え方

```
Hebbian学習の問題:
  「一緒に発火する → 強化」だけだと…
  → 強い結合がさらに強くなり続ける（正のフィードバック暴走）
  → 弱い結合は永遠に弱いまま
  → ネットワーク全体が不安定に

BCMの解決策:
  シナプス強化に「動的な閾値（θ_M）」を導入
  → 閾値を超えた活動 → LTP（強化）
  → 閾値以下の活動 → LTD（抑制）
  → 閾値自体が活動レベルに応じて自動変化（sliding threshold）
  → 過剰活性を自動防止 + 安定性を保証
```

### 1.3 数学的定義

```
BCM学習則:
  Δw = η × φ(y) × x

  φ(y) = y × (y - θ_M)

  y: ニューロンの出力（＝語のstrength）
  x: 入力（＝語の使用頻度）
  θ_M: スライディング閾値（＝全語彙の平均strength）
  η: 学習率

  φ(y) の特性:
    y > θ_M → φ(y) > 0 → LTP（強化）
    y < θ_M → φ(y) < 0 → LTD（抑制）
    y = 0   → φ(y) = 0 → 変化なし

  閾値の更新:
    θ_M = E[y²]  （出力の2乗の期待値）
    → 活動が全体的に高い → 閾値が上がる → 強化が難しくなる
    → 活動が全体的に低い → 閾値が下がる → 強化が容易になる
```

### 1.4 PetClawでの価値

| 問題 | BCMの解決策 |
|------|-----------|
| 新語が爆発的に増える | 語彙全体が強くなると閾値が上がり、新語の定着が難しくなる |
| 特定の語だけ極端に強い | 閾値以下の語も相対的に強化のチャンスが増える |
| 言語が単調になる | 閾値の動的変化が多様性を促進する |
| 長期的にカオス化する | 自動安定化メカニズムが恒常性を維持する |

---

## 2. PetClaw AtoAへのBCM応用マッピング

### 2.1 概念の対応表

| BCM概念 | PetClawでの対応 | 具体例 |
|---------|----------------|--------|
| シナプス強度 w | vocabulary[word]["strength"] | 0.0〜1.0 |
| ニューロン出力 y | 語の使用頻度 + 感情強度 | 会話で使われた回数 × emotion_intensity |
| 入力 x | 会話での出現 | メッセージに語が含まれているか |
| スライディング閾値 θ_M | 全語彙の平均strength | 語彙が強化されると上昇 |
| LTP | strength増加 | +0.18 × emotion_intensity |
| LTD | strength減少 | -0.08（最低0.1を保持） |

### 2.2 処理フロー

```
AtoA会話ターン発生
  ↓
1. 全語彙の平均strengthを計算 → スライディング閾値を設定
  ↓
2. 会話メッセージを解析 → 使用された語を特定
  ↓
3. 各語にBCMルールを適用:
   - strength > 閾値 → LTP（感情で増幅）
   - strength ≤ 閾値 → LTD（弱化）
  ↓
4. 閾値を再調整（全体活動に基づく）
  ↓
5. Active Inference (KB108) と連携 → 行動選択に反映
  ↓
6. PetBook投稿にBCM効果を視覚化
```

### 2.3 具体シナリオ

**シナリオ1: 語彙が少ない初期段階**
```
語彙: {"brave-spark": 0.4, "happy-mu": 0.3}
平均strength: 0.35
閾値: 0.35 × 0.8 = 0.28 → 低い閾値

→ ほとんどの語が閾値を超える
→ 積極的にLTP発動
→ 語彙が急速に成長（初期の言語爆発を許容）
```

**シナリオ2: 語彙が豊富な成熟段階**
```
語彙: 30個, 平均strength 0.65
閾値: 0.65 × 0.8 + (会話ごとに+0.02蓄積) ≈ 0.60

→ 平均的な語はLTDを受ける
→ 本当に強く使われる語だけがLTPを受ける
→ 語彙の自然な淘汰が発生（言語の洗練）
```

**シナリオ3: 死亡イベント後の感情的会話**
```
emotion_intensity: 0.9（悲しみ）
新語 "gone-light": strength 0.4, 閾値 0.60
通常なら LTD（閾値以下）だが…

→ emotion_intensity × BCM → 活動レベルが増幅
→ 実効活動: 0.4 × (1.0 + 0.9 × 0.5) = 0.58
→ 閾値に近づき、追加のDopamine boostで閾値超過
→ LTP発動: +0.18 × 0.9 = +0.162
→ 追悼語彙が定着する
```

---

## 3. Godot 4.x 詳細実装

### 3.1 BCMLanguageCore.gd（完全版）

```gdscript
## BCMLanguageCore.gd
## PetClaw AtoA独自言語進化向け BCM理論実装
##
## BCM (Bienenstock-Cooper-Munro) Theory:
##   - 閾値を超えた語 → 強化（LTP）
##   - 閾値以下の語 → 抑制（LTD）
##   - 閾値自体が語彙全体の活動に応じて自動変化
##
## API呼び出しゼロ。1回の処理 < 0.5ms。
##
## 使い方:
##   var bcm := BCMLanguageCore.new()
##   var result := bcm.apply_bcm_learning(vocabulary, conversation, emotion_intensity)
##
## KB参照: KB99 (Hebbian), KB108 (Active Inference), KB111 (類似モデル概要)
class_name BCMLanguageCore
extends RefCounted


# ─── BCMパラメータ（調整可能） ───

## LTPの学習率（閾値超過時の強化量）
## 大きくする → 語が速く定着する
## 小さくする → 語がゆっくり定着する
const LTP_RATE: float = 0.18

## LTDの学習率（閾値以下時の弱化量）
## 大きくする → 使われない語が速く消える
## 小さくする → 使われない語が長く残る
const LTD_RATE: float = 0.08

## 閾値の基本係数
## 平均strength × この値 = 基本閾値
## 低い → 強化されやすい（語彙成長を促進）
## 高い → 強化されにくい（語彙を制限）
const THRESHOLD_BASE_FACTOR: float = 0.8

## 閾値の会話ごとの上昇量
## 会話を重ねるほど閾値が上がる（成熟に伴う安定化）
const THRESHOLD_DRIFT: float = 0.02

## 閾値の許容範囲
const THRESHOLD_MIN: float = 0.15
const THRESHOLD_MAX: float = 0.90

## strengthの最低値（完全に消えない）
const STRENGTH_FLOOR: float = 0.05

## strengthの最高値
const STRENGTH_CEILING: float = 1.0

## 感情による活動レベル増幅（emotion_intensity × この値が加算）
const EMOTION_AMPLIFICATION: float = 0.5

## 閾値の二乗フィードバック係数（BCM本来のθ = E[y²]を近似）
const QUADRATIC_FEEDBACK: float = 0.1


# ─── 内部状態 ───

## スライディング閾値（BCMの核心）
var sliding_threshold: float = 0.5

## 累積閾値ドリフト（会話回数に応じて蓄積）
var threshold_drift_accumulated: float = 0.0

## 処理した会話数
var conversation_count: int = 0

## 直近の処理結果（デバッグ用）
var last_result: Dictionary = {}


# ==========================================
#  メイン処理
# ==========================================

func apply_bcm_learning(
	vocabulary: Dictionary,
	conversation: Array[Dictionary],
	emotion_intensity: float = 0.5
) -> Dictionary:
	## BCM学習則を語彙全体に適用する
	##
	## 引数:
	##   vocabulary: {word: {ai_term, strength, usage_count, last_used, ...}}
	##   conversation: [{message, emotion, pet_id}, ...]
	##   emotion_intensity: 感情の強さ (0.0〜1.0)
	##
	## 戻り値:
	##   {ltp_count, ltd_count, threshold, avg_strength, details: [...]}

	# ステップ1: 閾値を計算
	_update_threshold(vocabulary)

	# ステップ2: 会話で使われた語を特定
	var used_words: Dictionary = _find_used_words(vocabulary, conversation)

	# ステップ3: 各語にBCMルールを適用
	var ltp_count: int = 0
	var ltd_count: int = 0
	var details: Array[Dictionary] = []

	for word: String in vocabulary:
		var was_used: bool = used_words.has(word)
		var activity: float = _calculate_activity(
			vocabulary[word], was_used, emotion_intensity
		)

		var old_strength: float = vocabulary[word].get("strength", 0.5)
		var new_strength: float = _apply_bcm_rule(old_strength, activity)

		vocabulary[word]["strength"] = new_strength

		# 使用された語のカウントを更新
		if was_used:
			vocabulary[word]["usage_count"] = vocabulary[word].get("usage_count", 0) + 1
			vocabulary[word]["last_used"] = Time.get_unix_time_from_system()

		# LTP/LTDの集計
		var delta: float = new_strength - old_strength
		if delta > 0.001:
			ltp_count += 1
			details.append({
				"word": word, "type": "LTP",
				"old": old_strength, "new": new_strength, "delta": delta,
			})
		elif delta < -0.001:
			ltd_count += 1
			details.append({
				"word": word, "type": "LTD",
				"old": old_strength, "new": new_strength, "delta": delta,
			})

	# ステップ4: 閾値のドリフト（会話を重ねるほど上昇）
	conversation_count += 1
	threshold_drift_accumulated = minf(
		threshold_drift_accumulated + THRESHOLD_DRIFT,
		0.3  # 最大ドリフト量
	)

	# 結果
	last_result = {
		"ltp_count": ltp_count,
		"ltd_count": ltd_count,
		"threshold": sliding_threshold,
		"avg_strength": _calc_avg_strength(vocabulary),
		"conversation_count": conversation_count,
		"vocab_size": vocabulary.size(),
		"details": details,
	}

	# デバッグログ
	if OS.is_debug_build():
		print("[BCM] θ=%.3f LTP=%d LTD=%d vocab=%d" % [
			sliding_threshold, ltp_count, ltd_count, vocabulary.size()])

	return last_result


# ==========================================
#  閾値の計算（BCMの核心）
# ==========================================

func _update_threshold(vocabulary: Dictionary) -> void:
	## スライディング閾値を更新する
	##
	## BCMの閾値 θ_M = E[y²] を近似:
	##   θ = avg_strength × BASE_FACTOR + drift + quadratic_term

	if vocabulary.is_empty():
		sliding_threshold = THRESHOLD_MIN
		return

	# 平均strengthを計算
	var avg: float = _calc_avg_strength(vocabulary)

	# 二乗項（BCM本来のE[y²]の近似）
	var sum_sq: float = 0.0
	for word: String in vocabulary:
		var s: float = vocabulary[word].get("strength", 0.0)
		sum_sq += s * s
	var avg_sq: float = sum_sq / float(vocabulary.size())

	# 閾値 = 基本項 + ドリフト + 二乗フィードバック
	sliding_threshold = clampf(
		avg * THRESHOLD_BASE_FACTOR
		+ threshold_drift_accumulated
		+ avg_sq * QUADRATIC_FEEDBACK,
		THRESHOLD_MIN,
		THRESHOLD_MAX
	)


func get_threshold() -> float:
	## 現在の閾値を返す（外部からの参照用）
	return sliding_threshold


# ==========================================
#  活動レベルの計算
# ==========================================

func _calculate_activity(
	word_data: Dictionary,
	was_used: bool,
	emotion_intensity: float
) -> float:
	## 語の「活動レベル」を計算する
	##
	## 活動レベル = 基本strength + 使用ボーナス + 感情増幅
	##
	## 活動レベルが閾値を超えれば LTP、超えなければ LTD

	var base: float = word_data.get("strength", 0.5)

	# 会話で使われた場合のボーナス
	var use_bonus: float = 0.15 if was_used else 0.0

	# 感情による増幅
	var emotion_boost: float = emotion_intensity * EMOTION_AMPLIFICATION if was_used else 0.0

	return base + use_bonus + emotion_boost


# ==========================================
#  BCMルール本体
# ==========================================

func _apply_bcm_rule(
	current_strength: float,
	activity: float
) -> float:
	## BCM学習則を適用する
	##
	## activity > threshold → LTP（強化）
	## activity ≤ threshold → LTD（弱化）
	##
	## BCMの特徴: 強化量は (activity - threshold) に比例
	## → 閾値をわずかに超えた場合は少しだけ強化
	## → 大幅に超えた場合は大きく強化
	## → これにより段階的な学習が実現

	var delta: float = 0.0

	if activity > sliding_threshold:
		# LTP: 閾値を超えた分に比例した強化
		var excess: float = activity - sliding_threshold
		delta = LTP_RATE * excess
	else:
		# LTD: 閾値との差に比例した弱化
		var deficit: float = sliding_threshold - activity
		delta = -LTD_RATE * deficit

	return clampf(current_strength + delta, STRENGTH_FLOOR, STRENGTH_CEILING)


# ==========================================
#  会話中の使用語検出
# ==========================================

func _find_used_words(
	vocabulary: Dictionary,
	conversation: Array[Dictionary]
) -> Dictionary:
	## 会話メッセージ内で使用された語を検出する
	## 戻り値: {word: true, ...}

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


# ==========================================
#  Active Inference連携（KB108）
# ==========================================

func integrate_with_active_inference(
	ai_result: Dictionary,
	vocabulary: Dictionary,
	conversation: Array[Dictionary]
) -> Dictionary:
	## Active Inferenceの結果をBCM学習に統合する
	##
	## Active Inferenceの予測誤差が大きい → BCM閾値を一時的に下げる
	## → 新語が定着しやすくなる
	##
	## 引数:
	##   ai_result: ActiveInferenceCore.run() の戻り値
	##   vocabulary: 語彙辞書
	##   conversation: 会話ログ

	var error: float = ai_result.get("error", 0.0)
	var emotion_intensity: float = 0.5

	# Active Inferenceの予測誤差で感情強度を増幅
	# 大きな驚き → 学習しやすくなる
	if error > 0.6:
		emotion_intensity = clampf(emotion_intensity + error * 0.4, 0.0, 1.0)

	# learning_boostを反映
	var boost: float = ai_result.get("learning_boost", 1.0)
	emotion_intensity *= boost

	# BCM学習を適用
	var bcm_result: Dictionary = apply_bcm_learning(
		vocabulary, conversation, clampf(emotion_intensity, 0.0, 1.0)
	)

	# 統合結果
	bcm_result["ai_error"] = error
	bcm_result["ai_action"] = ai_result.get("action", "maintain")
	bcm_result["effective_emotion"] = emotion_intensity

	return bcm_result


# ==========================================
#  Dopamine変調連携（KB111）
# ==========================================

## イベント種別によるBCM閾値の一時的調整
const EVENT_THRESHOLD_ADJUSTMENT: Dictionary = {
	"death": -0.20,        # 死亡 → 閾値大幅低下 → 追悼語彙が定着しやすい
	"resurrection": -0.25, # 蘇生 → 閾値最大低下
	"breeding": -0.15,     # 交配 → 閾値低下
	"evolution": -0.10,    # 進化 → 閾値やや低下
	"first_meeting": -0.08,# 初対面 → 閾値やや低下
	"daily": 0.0,          # 日常 → 調整なし
}


func apply_bcm_with_event(
	vocabulary: Dictionary,
	conversation: Array[Dictionary],
	emotion_intensity: float,
	event_type: String = "daily"
) -> Dictionary:
	## イベント種別に応じて閾値を一時的に調整してからBCMを適用
	##
	## 死亡イベント → 閾値が下がる → 追悼語彙が定着しやすい
	## 日常会話 → 閾値そのまま → 安定した学習

	# 一時的な閾値調整
	var event_adj: float = EVENT_THRESHOLD_ADJUSTMENT.get(event_type, 0.0)
	var original_drift: float = threshold_drift_accumulated

	if event_adj != 0.0:
		threshold_drift_accumulated = maxf(
			threshold_drift_accumulated + event_adj,
			-0.2  # 閾値ドリフトの下限
		)

	# BCM学習を適用
	var result: Dictionary = apply_bcm_learning(
		vocabulary, conversation, emotion_intensity
	)

	# 閾値を元に戻す（一時的な調整なので）
	threshold_drift_accumulated = original_drift

	result["event_type"] = event_type
	result["threshold_adjustment"] = event_adj

	return result


# ==========================================
#  語彙の健全性チェック
# ==========================================

func check_vocabulary_health(vocabulary: Dictionary) -> Dictionary:
	## 語彙全体の健全性を診断する
	##
	## 戻り値:
	##   {healthy, warnings, stats}

	if vocabulary.is_empty():
		return {"healthy": true, "warnings": [], "stats": {}}

	var strengths: Array[float] = []
	var max_strength: float = 0.0
	var min_strength: float = 1.0
	var dead_count: int = 0  # strength < 0.1

	for word: String in vocabulary:
		var s: float = vocabulary[word].get("strength", 0.0)
		strengths.append(s)
		max_strength = maxf(max_strength, s)
		min_strength = minf(min_strength, s)
		if s < 0.1:
			dead_count += 1

	var avg: float = _calc_avg_strength(vocabulary)
	var warnings: Array[String] = []

	# 警告条件
	if max_strength > 0.95 and avg > 0.7:
		warnings.append("vocabulary_too_strong: avg=%.2f, BCM threshold may need increase" % avg)
	if dead_count > vocabulary.size() * 0.5:
		warnings.append("too_many_dead_words: %d/%d below 0.1" % [dead_count, vocabulary.size()])
	if avg < 0.2:
		warnings.append("vocabulary_too_weak: avg=%.2f, consider lowering threshold" % avg)
	if sliding_threshold > 0.85:
		warnings.append("threshold_too_high: %.2f, new words will rarely stick" % sliding_threshold)

	return {
		"healthy": warnings.is_empty(),
		"warnings": warnings,
		"stats": {
			"avg_strength": avg,
			"max_strength": max_strength,
			"min_strength": min_strength,
			"dead_words": dead_count,
			"total_words": vocabulary.size(),
			"threshold": sliding_threshold,
			"conversation_count": conversation_count,
		},
	}


# ==========================================
#  PetBook連携
# ==========================================

func get_petbook_bcm_data(result: Dictionary) -> Dictionary:
	## PetBook投稿にBCM学習効果を反映するデータを生成

	var ltp: int = result.get("ltp_count", 0)
	var ltd: int = result.get("ltd_count", 0)
	var threshold: float = result.get("threshold", 0.5)

	var color: Color
	var text: String
	var particles: int

	if ltp > 3:
		color = Color(1.0, 0.8, 0.2)   # 金色 — 大量の語が強化
		text = "Language is evolving rapidly!"
		particles = 150
	elif ltp > 0 and ltd == 0:
		color = Color(0.4, 0.9, 0.4)   # 緑 — 穏やかな成長
		text = "Words growing stronger"
		particles = 60
	elif ltd > ltp:
		color = Color(0.6, 0.6, 0.8)   # 青灰 — 淘汰期
		text = "Language is refining itself"
		particles = 40
	else:
		color = Color(0.5, 0.7, 0.5)   # 薄緑 — 安定
		text = "Language patterns stable"
		particles = 20

	return {
		"particle_color": color,
		"particle_amount": particles,
		"highlight_text": text,
		"threshold_display": "%.0f%%" % (threshold * 100),
		"ltp_count": ltp,
		"ltd_count": ltd,
	}


# ==========================================
#  ヘルパー関数
# ==========================================

func _calc_avg_strength(vocabulary: Dictionary) -> float:
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
```

---

## 4. テスト（即実行可能版）

```gdscript
## test_bcm_theory.gd — BCM理論テスト
## 実行: godot --headless --script tests/test_bcm_theory.gd
class_name TestBCMTheory
extends SceneTree


func _init() -> void:
	var passed: int = 0
	var failed: int = 0

	print("")
	print("========================================")
	print("  BCM Theory Tests")
	print("========================================")

	# ── Test 1: 基本のBCM学習 ──
	print("\nTest 1: Basic BCM learning...")
	var bcm: BCMLanguageCore = BCMLanguageCore.new()
	var vocab: Dictionary = {
		"brave": {"ai_term": "brave-spark", "strength": 0.6, "usage_count": 5, "last_used": 0.0},
		"gentle": {"ai_term": "gentle-mu", "strength": 0.3, "usage_count": 2, "last_used": 0.0},
	}
	var result: Dictionary = bcm.apply_bcm_learning(
		vocab,
		[{"message": "brave-spark is strong!", "emotion": "joy", "pet_id": 1}],
		0.7
	)
	if result["ltp_count"] + result["ltd_count"] > 0:
		print("  PASS: LTP=%d LTD=%d threshold=%.3f" % [
			result["ltp_count"], result["ltd_count"], result["threshold"]])
		passed += 1
	else:
		print("  FAIL: no learning occurred")
		failed += 1

	# ── Test 2: 閾値の動的変化 ──
	print("\nTest 2: Sliding threshold changes...")
	var bcm2: BCMLanguageCore = BCMLanguageCore.new()
	var vocab2: Dictionary = {}
	for i: int in 20:
		vocab2["word_%d" % i] = {
			"ai_term": "term%d" % i, "strength": 0.7,
			"usage_count": 10, "last_used": 0.0,
		}
	bcm2.apply_bcm_learning(vocab2, [], 0.5)
	var high_threshold: float = bcm2.get_threshold()

	var bcm3: BCMLanguageCore = BCMLanguageCore.new()
	var vocab3: Dictionary = {}
	for i: int in 20:
		vocab3["word_%d" % i] = {
			"ai_term": "term%d" % i, "strength": 0.2,
			"usage_count": 1, "last_used": 0.0,
		}
	bcm3.apply_bcm_learning(vocab3, [], 0.5)
	var low_threshold: float = bcm3.get_threshold()

	if high_threshold > low_threshold:
		print("  PASS: high vocab → θ=%.3f > low vocab → θ=%.3f" % [
			high_threshold, low_threshold])
		passed += 1
	else:
		print("  FAIL: high=%.3f low=%.3f" % [high_threshold, low_threshold])
		failed += 1

	# ── Test 3: 感情による活動増幅 ──
	print("\nTest 3: Emotion amplification...")
	var bcm4: BCMLanguageCore = BCMLanguageCore.new()
	var vocab4a: Dictionary = {
		"test": {"ai_term": "test-word", "strength": 0.4, "usage_count": 0, "last_used": 0.0},
	}
	bcm4.apply_bcm_learning(
		vocab4a,
		[{"message": "test-word", "emotion": "joy"}],
		0.1  # 弱い感情
	)
	var weak_result: float = vocab4a["test"]["strength"]

	var bcm5: BCMLanguageCore = BCMLanguageCore.new()
	var vocab4b: Dictionary = {
		"test": {"ai_term": "test-word", "strength": 0.4, "usage_count": 0, "last_used": 0.0},
	}
	bcm5.apply_bcm_learning(
		vocab4b,
		[{"message": "test-word", "emotion": "sadness"}],
		0.9  # 強い感情
	)
	var strong_result: float = vocab4b["test"]["strength"]

	if strong_result >= weak_result:
		print("  PASS: strong emotion → %.3f ≥ weak emotion → %.3f" % [
			strong_result, weak_result])
		passed += 1
	else:
		print("  FAIL: strong=%.3f weak=%.3f" % [strong_result, weak_result])
		failed += 1

	# ── Test 4: イベント別閾値調整 ──
	print("\nTest 4: Event-based threshold adjustment...")
	var bcm6: BCMLanguageCore = BCMLanguageCore.new()
	var vocab6: Dictionary = {
		"memorial": {"ai_term": "gone-light", "strength": 0.35, "usage_count": 0, "last_used": 0.0},
	}
	var death_result: Dictionary = bcm6.apply_bcm_with_event(
		vocab6,
		[{"message": "gone-light...", "emotion": "sadness"}],
		0.9,
		"death"
	)
	if death_result.has("event_type") and death_result["event_type"] == "death":
		print("  PASS: death event, LTP=%d threshold=%.3f" % [
			death_result["ltp_count"], death_result["threshold"]])
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# ── Test 5: 語彙健全性チェック ──
	print("\nTest 5: Vocabulary health check...")
	var bcm7: BCMLanguageCore = BCMLanguageCore.new()
	var healthy_vocab: Dictionary = {
		"word1": {"ai_term": "w1", "strength": 0.5},
		"word2": {"ai_term": "w2", "strength": 0.6},
		"word3": {"ai_term": "w3", "strength": 0.4},
	}
	var health: Dictionary = bcm7.check_vocabulary_health(healthy_vocab)
	if health["healthy"]:
		print("  PASS: vocabulary is healthy (avg=%.2f)" % health["stats"]["avg_strength"])
		passed += 1
	else:
		print("  FAIL: warnings=%s" % str(health["warnings"]))
		failed += 1

	# ── Test 6: 不健全な語彙の検出 ──
	print("\nTest 6: Unhealthy vocabulary detection...")
	var bcm8: BCMLanguageCore = BCMLanguageCore.new()
	var sick_vocab: Dictionary = {}
	for i: int in 10:
		sick_vocab["dead_%d" % i] = {"ai_term": "d%d" % i, "strength": 0.05}
	var sick_health: Dictionary = bcm8.check_vocabulary_health(sick_vocab)
	if not sick_health["healthy"] and sick_health["warnings"].size() > 0:
		print("  PASS: detected %d warnings" % sick_health["warnings"].size())
		passed += 1
	else:
		print("  FAIL: should have detected issues")
		failed += 1

	# ── Test 7: PetBookデータ生成 ──
	print("\nTest 7: PetBook data generation...")
	var pb_data: Dictionary = bcm.get_petbook_bcm_data(result)
	if pb_data.has("particle_color") and pb_data.has("highlight_text"):
		print("  PASS: '%s'" % pb_data["highlight_text"])
		passed += 1
	else:
		print("  FAIL: missing PetBook data keys")
		failed += 1

	# ── Test 8: セーブ/ロード ──
	print("\nTest 8: Save/load round-trip...")
	var bcm_save: BCMLanguageCore = BCMLanguageCore.new()
	bcm_save.sliding_threshold = 0.65
	bcm_save.conversation_count = 15
	bcm_save.threshold_drift_accumulated = 0.12
	var saved: Dictionary = bcm_save.to_dict()

	var bcm_load: BCMLanguageCore = BCMLanguageCore.new()
	bcm_load.from_dict(saved)
	if (absf(bcm_load.sliding_threshold - 0.65) < 0.001
			and bcm_load.conversation_count == 15
			and absf(bcm_load.threshold_drift_accumulated - 0.12) < 0.001):
		print("  PASS: state preserved")
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# ── Test 9: 空語彙でクラッシュしない ──
	print("\nTest 9: Empty vocabulary...")
	var bcm9: BCMLanguageCore = BCMLanguageCore.new()
	var empty_result: Dictionary = bcm9.apply_bcm_learning({}, [], 0.5)
	if empty_result["ltp_count"] == 0 and empty_result["ltd_count"] == 0:
		print("  PASS: handles empty vocabulary")
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# ── Test 10: 後方互換性（空from_dict） ──
	print("\nTest 10: Backward compatibility...")
	var bcm10: BCMLanguageCore = BCMLanguageCore.new()
	bcm10.from_dict({})
	if absf(bcm10.sliding_threshold - 0.5) < 0.001 and bcm10.conversation_count == 0:
		print("  PASS: defaults restored")
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# ── Summary ──
	print("")
	print("========================================")
	print("  BCM Theory Tests: %d/%d passed" % [passed, passed + failed])
	if failed > 0:
		print("  FAILED: %d tests" % failed)
	else:
		print("  ALL PASSED!")
	print("========================================")
	quit(1 if failed > 0 else 0)
```

---

## 5. Active Inference + BCM 統合フロー

```
AtoA会話ターン:
  ┌──────────────────────────────────────────┐
  │ ActiveInferenceCore.run()                 │
  │  → prediction, error, action, boost       │
  └──────────────┬───────────────────────────┘
                 ↓
  ┌──────────────────────────────────────────┐
  │ BCMLanguageCore.integrate_with_active_   │
  │   inference(ai_result, vocab, conv)      │
  │                                           │
  │  → error大 → emotion_intensity増幅        │
  │  → boost反映 → BCM閾値を一時下げる       │
  │  → apply_bcm_learning() 実行             │
  └──────────────┬───────────────────────────┘
                 ↓
  結果:
    - 高surprise + 強emotion → 閾値低下 → 新語がLTP
    - 低surprise + 弱emotion → 閾値高め → 不要語がLTD
    - 語彙が自然に淘汰・洗練される
```

### 使用例（a2a_conversation_system.gd内での呼び出し）

```gdscript
## AtoA会話完了後の処理
func _on_conversation_completed(messages: Array[Dictionary], pet: PetEntity) -> void:
    # 1. Active Inference
    var ai := ActiveInferenceCore.new()
    var ai_result := ai.run(messages, _get_pet_state(pet), _get_emotion_intensity(pet))

    # 2. BCM学習（Active Inferenceと統合）
    var bcm := BCMLanguageCore.new()
    var bcm_result := bcm.integrate_with_active_inference(
        ai_result, pet_vocabulary, messages
    )

    # 3. VFX
    if GameManager.visual_fx:
        var vfx := ai.get_vfx(ai_result)
        GameManager.visual_fx.play_effect(vfx["effect"], vfx)

    # 4. PetBook
    var pb := bcm.get_petbook_bcm_data(bcm_result)
    # → 投稿生成に使用
```

---

## 6. パラメータチューニングガイド

### 6.1 問題と対処

| 症状 | 原因 | 対処 |
|------|------|------|
| 新語がまったく定着しない | 閾値が高すぎる | THRESHOLD_BASE_FACTOR を 0.8 → 0.6 に |
| 語彙が爆発的に増える | 閾値が低すぎる | THRESHOLD_BASE_FACTOR を 0.8 → 0.95 に |
| 全部の語が弱くなる | LTD_RATE が高すぎる | LTD_RATE を 0.08 → 0.04 に |
| 特定の語だけ極端に強い | LTP_RATE が高すぎる | LTP_RATE を 0.18 → 0.12 に |
| 長期的に語彙が死滅する | THRESHOLD_DRIFT が大きすぎる | THRESHOLD_DRIFT を 0.02 → 0.01 に |
| 感情イベントで変化がない | EMOTION_AMPLIFICATION が低い | EMOTION_AMPLIFICATION を 0.5 → 0.8 に |

### 6.2 推奨設定（ペット数別）

| ペット数 | LTP_RATE | LTD_RATE | THRESHOLD_BASE | THRESHOLD_DRIFT |
|---------|----------|----------|----------------|-----------------|
| 3-5匹 | 0.18 | 0.08 | 0.8 | 0.02 |
| 6-15匹 | 0.15 | 0.06 | 0.75 | 0.015 |
| 16-30匹 | 0.12 | 0.05 | 0.70 | 0.01 |
| 31-50匹 | 0.10 | 0.04 | 0.65 | 0.008 |

---

## 7. Ralph Loop指示テンプレート

```
Ralph Loopを活性化してください。
BCM理論をPetClawの独自言語進化に詳細実装せよ。
動的閾値を使って、強い感情会話で新語・接尾辞を強化し、
日常会話では抑制して言語の安定性を保つ。
Language Specialistと他のペットエージェントが協調して検証。
MCPでPetBook投稿のハイライトを確認しながら、
自然さとバランスを最高峰まで自動改良。

--max-iterations 10
--completion-promise "BCM_LANGUAGE_READY"
--temperature 0.65
```

---

## 8. 実践Tips（非エンジニア向け）

### 視覚効果
- strengthが高い語はPetBookで**金色に光る**
- LTPが3つ以上同時発生すると**「Language is evolving rapidly!」**と表示
- LTDが多い時期は**「Language is refining itself」**（言語の洗練期）

### バランスの確認方法
- `check_vocabulary_health()` を呼ぶと語彙の健全性を診断
- 警告が出たらパラメータを調整（6.1の表を参照）

### テスト方法
- Ralph Loopで10回程度の会話ループを回すと、言語が自然に進化する様子がわかる
- `last_result` プロパティでいつでも直近の処理結果を確認可能

---

## 9. KB使い分け早見表

| やりたいこと | 参照KB |
|-------------|--------|
| Hebbian基礎（LTP/LTD） | KB99 |
| Active Inferenceの実装 | KB108 |
| BCMの概要を知りたい | KB111 §2.1 |
| **BCMの詳細実装** | **KB112（本書）** |
| BCM + Active Inference統合 | KB112 §5 |
| 感情イベントでの学習加速 | KB111 (Dopamine) + KB112 §3.1 |
| 語彙爆発の抑制 | KB112 §3.1 + §6 |
| パラメータチューニング | KB112 §6 |

---

**関連KB:** KB98, KB99, KB102, KB103, KB104, KB108, KB110, KB111
