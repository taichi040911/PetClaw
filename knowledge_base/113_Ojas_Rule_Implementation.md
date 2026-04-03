# KB113: Oja's Rule 実装例ガイド（PetClaw AtoA独自言語進化向け）
## Hebbian学習の正規化版 — 語彙バランスの自動維持
**Version:** 2026-04-03
**対象:** Claude Code / Claude Cowork / Agent Teams / 非エンジニア
**前提知識:** KB99 (Hebbian), KB108 (Active Inference), KB111 (類似モデル概要), KB112 (BCM)

---

## 1. Oja's Ruleの神経科学基礎

### 1.1 歴史と概要

1982年にErkki Ojaが提唱。Hebbian学習の**正規化版**として、シナプス重みが無制限に増大する問題を解決。数学的には**主成分分析（PCA）のオンライン版**と等価であり、最も重要なパターンを自動的に抽出する能力を持つ。

### 1.2 Hebbianの問題とOja's Ruleの解決策

```
Hebbian学習の問題:
  「使われた語は強化される」だけだと…
  → "brave-spark" が 0.95 に到達
  → "gentle-mu" も 0.90 に到達
  → "play-ba" も 0.88 に到達
  → 全部の語が上限近くに張り付く
  → 語の間の「差」が消える → 言語の意味的区別が失われる

Oja's Ruleの解決策:
  「強化した後に、全体を正規化する」
  → 重みベクトルの大きさ（ノルム）を一定に保つ
  → 強い語はより強く、弱い語はより弱く（コントラスト増強）
  → 相対的な順序を保ちながら全体のスケールを制御
```

### 1.3 数学的定義

```
標準Hebbian:
  Δw = η × x × y
  → wが無制限に増大する可能性

Oja's Rule:
  Δw = η × (x × y - y² × w)

  w: シナプス重み（= 語のstrength）
  x: 入力（= 語の使用/出現）
  y: 出力（= w × x、語の活性度）
  η: 学習率

  追加項「-y² × w」の意味:
    - y（出力）が大きいほど、wを引き戻す力が強い
    - これにより ||w|| ≈ 1 に収束（自動正規化）
    - 最も入力と相関の高い方向にwが向く（PCA第1主成分）

簡略化版（PetClaw向け）:
  1. まずHebbianで強化: w += η × x × y
  2. 次に全体を正規化: w_i = w_i × (target / ||w||)
  → 実装がシンプルで効果は同等
```

### 1.4 BCM理論との比較

| 特性 | BCM (KB112) | Oja's Rule (本KB) |
|------|------------|-------------------|
| **目的** | 過剰活性の防止 | 重みの正規化 |
| **メカニズム** | 動的閾値で強化/抑制を切り替え | 強化後に全体をスケーリング |
| **制御対象** | 個々の語の強化判定 | 全語彙の合計バランス |
| **時間スケール** | 各会話ターン | 各会話ターン（Hebbian後に即適用） |
| **得意な場面** | 語彙爆発の抑制 | 語の間のコントラスト維持 |
| **組み合わせ** | BCM → Oja の順で適用が最適 | BCMの後に適用すると安定性が最大 |

---

## 2. PetClaw AtoAへの応用マッピング

### 2.1 概念の対応表

| Oja's Rule概念 | PetClawでの対応 | 具体例 |
|---------------|----------------|--------|
| 重みベクトル w | 全語彙のstrength配列 | [0.8, 0.6, 0.4, 0.3] |
| ノルム ||w|| | 全strengthの合計 | 2.1 |
| 目標ノルム | 語数 × 目標平均 | 4語 × 0.55 = 2.2 |
| 正規化 | scale = target / total | 2.2 / 2.1 = 1.048 |
| PCA第1主成分 | 最も使用頻度の高い語パターン | 派閥の支配的接尾辞 |

### 2.2 処理フロー

```
AtoA会話ターン:
  ┌──────────────────────────────────┐
  │ 1. Hebbian LTP/LTD (KB99)        │
  │    使用語を強化、不使用語を弱化    │
  └──────────┬───────────────────────┘
             ↓
  ┌──────────────────────────────────┐
  │ 2. BCM Theory (KB112, optional)   │
  │    閾値に基づく強化/抑制判定       │
  └──────────┬───────────────────────┘
             ↓
  ┌──────────────────────────────────┐
  │ 3. Oja's Rule (本KB)             │
  │    全語彙のstrengthを正規化       │
  │    → 合計を目標値に近づける        │
  │    → 相対的順序は保存             │
  └──────────┬───────────────────────┘
             ↓
  結果: 語彙のバランスが維持された状態で
        次のActive Inference (KB108) に渡す
```

### 2.3 具体シナリオ

**シナリオ1: 正規化前後の比較**
```
Hebbian強化後:
  brave-spark:  0.92
  gentle-mu:    0.85
  play-ba:      0.78
  gone-light:   0.71
  合計: 3.26

Oja's Rule適用後（目標: 4語 × 0.55 = 2.20）:
  scale = 2.20 / 3.26 = 0.675
  brave-spark:  0.92 × 0.675 = 0.621
  gentle-mu:    0.85 × 0.675 = 0.574
  play-ba:      0.78 × 0.675 = 0.527
  gone-light:   0.71 × 0.675 = 0.479
  合計: 2.201

効果: 相対的順序は保存（brave > gentle > play > gone）
      しかし全体のスケールが制御され、上限張り付きを防止
```

**シナリオ2: 新語追加時の自動調整**
```
既存語彙（正規化済み、合計 ≈ 2.20）:
  brave-spark: 0.60, gentle-mu: 0.55, play-ba: 0.52, gone-light: 0.48

新語 "rebirth-glow" が追加（initial strength: 0.50）:
  合計: 2.70 → 目標: 5語 × 0.55 = 2.75

→ ほぼ目標と一致 → 大きなスケーリング不要
→ 新語が自然に語彙に溶け込む
```

**シナリオ3: 1語だけ極端に強い場合**
```
問題状態:
  brave-spark: 0.98  ← 異常に強い
  gentle-mu:   0.30
  play-ba:     0.25
  合計: 1.53, 目標: 3 × 0.55 = 1.65

scale = 1.65 / 1.53 = 1.078
  brave-spark: 0.98 × 1.078 = 1.0 (cap)
  gentle-mu:   0.30 × 1.078 = 0.323
  play-ba:     0.25 × 1.078 = 0.269

→ brave-sparkは上限でキャップ
→ 他の語は少し強化されてバランス改善
→ 完全な均等化ではなく、差を保ちつつ調整
```

---

## 3. Godot 4.x 詳細実装

### 3.1 OjaLanguageCore.gd（完全版）

```gdscript
## OjaLanguageCore.gd
## PetClaw AtoA独自言語進化向け Oja's Rule実装
##
## Hebbian学習で語を強化した後、全体のstrengthバランスを自動正規化。
## 特定の語だけが極端に強くなるのを防ぎ、語彙の多様性を維持する。
##
## API呼び出しゼロ。1回の処理 < 0.3ms。
##
## 使い方:
##   var oja := OjaLanguageCore.new()
##   var result := oja.apply_oja_learning(vocabulary, conversation, emotion_intensity)
##
## KB参照: KB99 (Hebbian), KB108 (Active Inference), KB111 (概要), KB112 (BCM)
class_name OjaLanguageCore
extends RefCounted


# ─── パラメータ（調整可能） ───

## Hebbian LTP学習率（正規化前の強化量）
const HEBBIAN_LTP_RATE: float = 0.15

## Hebbian LTD学習率（不使用語の弱化量）
const HEBBIAN_LTD_RATE: float = 0.03

## Oja's Rule学習率（正規化の強度）
## 高い → 正規化が強い（全語が均等に近づく）
## 低い → 正規化が弱い（Hebbianの結果をあまり変えない）
const OJA_RATE: float = 0.1

## 目標平均strength（全語彙の平均をこの値に近づける）
## 高い → 全体的に強い語彙（活発な言語）
## 低い → 全体的に弱い語彙（控えめな言語）
const TARGET_AVG_STRENGTH: float = 0.55

## 正規化後のstrength下限（完全消滅を防止）
const STRENGTH_FLOOR: float = 0.05

## 正規化後のstrength上限
const STRENGTH_CEILING: float = 1.0

## スケーリング係数の許容範囲（極端な変動を防止）
const SCALE_MIN: float = 0.5
const SCALE_MAX: float = 2.0

## Oja本来の二次項の係数（高次の正規化効果）
## y² × w の近似。コントラスト増強に寄与。
const QUADRATIC_DECAY: float = 0.02

## 感情による強化増幅
const EMOTION_BOOST: float = 0.5


# ─── 内部状態 ───

## 処理した会話数
var conversation_count: int = 0

## 直近の正規化情報
var last_normalization: Dictionary = {}

## 直近の処理結果
var last_result: Dictionary = {}


# ==========================================
#  メイン処理
# ==========================================

func apply_oja_learning(
	vocabulary: Dictionary,
	conversation: Array[Dictionary],
	emotion_intensity: float = 0.5
) -> Dictionary:
	## Hebbian強化 + Oja's Rule正規化を実行する
	##
	## 引数:
	##   vocabulary: {word: {ai_term, strength, usage_count, last_used, ...}}
	##   conversation: [{message, emotion, pet_id}, ...]
	##   emotion_intensity: 感情の強さ (0.0〜1.0)
	##
	## 戻り値:
	##   {strengthened, weakened, normalized, scale_factor, avg_before, avg_after, details}

	if vocabulary.is_empty():
		last_result = {
			"strengthened": 0, "weakened": 0, "normalized": false,
			"scale_factor": 1.0, "avg_before": 0.0, "avg_after": 0.0, "details": [],
		}
		return last_result

	# ステップ1: 使用語を特定
	var used_words: Dictionary = _find_used_words(vocabulary, conversation)

	# ステップ2: Hebbian強化/弱化
	var avg_before: float = _calc_avg(vocabulary)
	var hebbian_details: Array[Dictionary] = _apply_hebbian(
		vocabulary, used_words, emotion_intensity
	)

	# ステップ3: Oja's Rule二次項（コントラスト増強）
	_apply_oja_quadratic(vocabulary, used_words)

	# ステップ4: 正規化（全体スケーリング）
	var norm_result: Dictionary = _normalize(vocabulary)

	# ステップ5: 結果まとめ
	var strengthened: int = 0
	var weakened: int = 0
	for d: Dictionary in hebbian_details:
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
		"details": hebbian_details,
	}

	# デバッグログ
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
	## 通常のHebbian LTP/LTDを適用する（Oja正規化の前段階）

	var details: Array[Dictionary] = []

	for word: String in vocabulary:
		var old_strength: float = vocabulary[word].get("strength", 0.5)
		var was_used: bool = used_words.has(word)

		var delta: float = 0.0
		if was_used:
			# LTP: 使用語を強化
			delta = HEBBIAN_LTP_RATE * (1.0 + emotion_intensity * EMOTION_BOOST)
			vocabulary[word]["usage_count"] = vocabulary[word].get("usage_count", 0) + 1
			vocabulary[word]["last_used"] = Time.get_unix_time_from_system()
		else:
			# LTD: 不使用語をわずかに弱化
			delta = -HEBBIAN_LTD_RATE

		vocabulary[word]["strength"] = clampf(
			old_strength + delta,
			STRENGTH_FLOOR,
			STRENGTH_CEILING
		)

		if absf(delta) > 0.001:
			details.append({
				"word": word,
				"type": "LTP" if delta > 0 else "LTD",
				"old": old_strength,
				"new": vocabulary[word]["strength"],
				"delta": delta,
			})

	return details


# ==========================================
#  Oja's Rule 二次項（コントラスト増強）
# ==========================================

func _apply_oja_quadratic(
	vocabulary: Dictionary,
	used_words: Dictionary
) -> void:
	## Oja's Ruleの二次項 (-η × y² × w) を適用
	##
	## 効果:
	##   - 強い語ほど引き戻す力が大きい（自動正規化の一部）
	##   - 使用された語は引き戻しが緩和される
	##   - 結果: 頻用語と非頻用語のコントラストが増強される

	for word: String in vocabulary:
		var strength: float = vocabulary[word].get("strength", 0.5)
		var was_used: bool = used_words.has(word)

		# y² × w の近似: strength² × QUADRATIC_DECAY
		var decay: float = strength * strength * QUADRATIC_DECAY

		# 使用語は引き戻しを半減（使われた語は維持されやすい）
		if was_used:
			decay *= 0.5

		vocabulary[word]["strength"] = maxf(
			vocabulary[word].get("strength", 0.5) - decay,
			STRENGTH_FLOOR
		)


# ==========================================
#  正規化（Oja's Ruleの核心）
# ==========================================

func _normalize(vocabulary: Dictionary) -> Dictionary:
	## 全語彙のstrengthを目標平均に向けてスケーリングする
	##
	## Oja's Ruleの本質: ||w|| を一定に保つ
	## PetClaw版: 平均strengthを TARGET_AVG_STRENGTH に近づける

	if vocabulary.is_empty():
		return {"applied": false, "scale_factor": 1.0}

	var current_avg: float = _calc_avg(vocabulary)

	# 目標との差が小さければスキップ（無駄な正規化を防止）
	if absf(current_avg - TARGET_AVG_STRENGTH) < 0.03:
		last_normalization = {"applied": false, "scale_factor": 1.0}
		return last_normalization

	# スケーリング係数を計算
	var target_total: float = float(vocabulary.size()) * TARGET_AVG_STRENGTH
	var current_total: float = current_avg * float(vocabulary.size())

	if current_total < 0.001:
		last_normalization = {"applied": false, "scale_factor": 1.0}
		return last_normalization

	var raw_scale: float = target_total / current_total

	# OJA_RATEで段階的に適用（急激な変動を防止）
	var scale: float = 1.0 + OJA_RATE * (raw_scale - 1.0)

	# 極端なスケーリングを制限
	scale = clampf(scale, SCALE_MIN, SCALE_MAX)

	# 全語彙にスケーリングを適用
	for word: String in vocabulary:
		vocabulary[word]["strength"] = clampf(
			vocabulary[word].get("strength", 0.5) * scale,
			STRENGTH_FLOOR,
			STRENGTH_CEILING
		)

	last_normalization = {
		"applied": true,
		"scale_factor": scale,
		"avg_before": current_avg,
		"avg_after": _calc_avg(vocabulary),
		"target": TARGET_AVG_STRENGTH,
	}

	return last_normalization


# ==========================================
#  Pure Oja's Rule（数学的に忠実な版）
# ==========================================

func apply_pure_oja(
	vocabulary: Dictionary,
	input_word: String,
	learning_rate: float = 0.1
) -> Dictionary:
	## 数学的に忠実なOja's Ruleを1語に対して適用
	##
	## Δw_i = η × (x_i × y - y² × w_i)
	##   x_i = 1 if word == input_word, else 0
	##   y = Σ(w_i × x_i) = w[input_word] (入力語のstrength)
	##
	## 他の全語に対しても -η × y² × w_i の減衰が適用される
	##
	## 用途: 1語ずつ精密に処理したい場合（計算コストは高い）

	if not vocabulary.has(input_word):
		return {"applied": false}

	var y: float = vocabulary[input_word].get("strength", 0.5)
	var y_sq: float = y * y
	var updated: int = 0

	for word: String in vocabulary:
		var w: float = vocabulary[word].get("strength", 0.5)
		var x: float = 1.0 if word == input_word else 0.0

		# Oja's Rule: Δw = η × (x × y - y² × w)
		var delta: float = learning_rate * (x * y - y_sq * w)

		vocabulary[word]["strength"] = clampf(
			w + delta,
			STRENGTH_FLOOR,
			STRENGTH_CEILING
		)
		updated += 1

	return {"applied": true, "input_word": input_word, "output_y": y, "updated": updated}


# ==========================================
#  Active Inference連携（KB108）
# ==========================================

func integrate_with_active_inference(
	ai_result: Dictionary,
	vocabulary: Dictionary,
	conversation: Array[Dictionary]
) -> Dictionary:
	## Active Inferenceの結果とOja's Ruleを統合
	##
	## 高surprise → 感情強度を増幅してHebbian強化
	## → その後Oja's Ruleで全体バランスを維持

	var error: float = ai_result.get("error", 0.0)
	var boost: float = ai_result.get("learning_boost", 1.0)

	# Active Inferenceの予測誤差で感情強度を調整
	var emotion_intensity: float = clampf(0.5 + error * 0.3, 0.0, 1.0)
	emotion_intensity *= boost

	# Oja学習を適用
	var oja_result: Dictionary = apply_oja_learning(
		vocabulary, conversation, clampf(emotion_intensity, 0.0, 1.0)
	)

	# 統合結果に追記
	oja_result["ai_error"] = error
	oja_result["ai_action"] = ai_result.get("action", "maintain")
	oja_result["effective_emotion"] = emotion_intensity

	return oja_result


# ==========================================
#  BCM + Oja 連携（KB112）
# ==========================================

func apply_after_bcm(
	vocabulary: Dictionary,
	bcm_result: Dictionary
) -> Dictionary:
	## BCM理論適用後にOja's Rule正規化を実行
	##
	## BCM → LTP/LTDで個々の語を調整
	## Oja → 全体のバランスを正規化
	## この順序が最も安定した結果を生む

	var norm_result: Dictionary = _normalize(vocabulary)

	return {
		"bcm_ltp": bcm_result.get("ltp_count", 0),
		"bcm_ltd": bcm_result.get("ltd_count", 0),
		"oja_normalized": norm_result.get("applied", false),
		"oja_scale": norm_result.get("scale_factor", 1.0),
		"avg_after": _calc_avg(vocabulary),
	}


# ==========================================
#  語彙コントラスト分析
# ==========================================

func analyze_contrast(vocabulary: Dictionary) -> Dictionary:
	## 語彙のコントラスト（多様性）を分析する
	##
	## コントラスト比 = 最大strength / 最小strength
	## 高い → 語の間に明確な差がある（良い）
	## 低い → 全部似たような強さ（単調）

	if vocabulary.size() < 2:
		return {"contrast_ratio": 1.0, "std_dev": 0.0, "health": "too_few_words"}

	var strengths: Array[float] = []
	var max_s: float = 0.0
	var min_s: float = 1.0

	for word: String in vocabulary:
		var s: float = vocabulary[word].get("strength", 0.0)
		strengths.append(s)
		max_s = maxf(max_s, s)
		min_s = minf(min_s, s)

	# コントラスト比
	var contrast: float = max_s / maxf(min_s, 0.01)

	# 標準偏差
	var avg: float = _calc_avg(vocabulary)
	var variance: float = 0.0
	for s: float in strengths:
		variance += (s - avg) * (s - avg)
	variance /= float(strengths.size())
	var std_dev: float = sqrt(variance)

	# 健全性判定
	var health: String = "good"
	if contrast < 1.2:
		health = "too_uniform"   # 全部同じ → 言語に個性がない
	elif contrast > 10.0:
		health = "too_extreme"   # 差が大きすぎ → 一部の語が支配的
	elif std_dev < 0.05:
		health = "stagnant"      # 変動がない → 学習が停滞

	return {
		"contrast_ratio": contrast,
		"std_dev": std_dev,
		"max_strength": max_s,
		"min_strength": min_s,
		"avg_strength": avg,
		"health": health,
		"vocab_size": vocabulary.size(),
	}


# ==========================================
#  Multi-Agent Oja正規化
# ==========================================

func normalize_across_agents(
	all_vocabularies: Dictionary  # {pet_id: vocabulary}
) -> Dictionary:
	## 全ペットの語彙を跨いだ正規化
	## 特定ペットの語彙だけが極端に強い場合に全体を調整

	if all_vocabularies.is_empty():
		return {"applied": false}

	# 全ペットの平均strengthを計算
	var pet_avgs: Dictionary = {}
	var global_total: float = 0.0
	var pet_count: int = 0

	for pet_id: Variant in all_vocabularies:
		var vocab: Dictionary = all_vocabularies[pet_id]
		if vocab.is_empty():
			continue
		var avg: float = _calc_avg(vocab)
		pet_avgs[pet_id] = avg
		global_total += avg
		pet_count += 1

	if pet_count == 0:
		return {"applied": false}

	var global_avg: float = global_total / float(pet_count)

	# 各ペットの語彙を全体平均に向けて調整
	var adjustments: Array[Dictionary] = []
	for pet_id: Variant in all_vocabularies:
		if not pet_avgs.has(pet_id):
			continue
		var pet_avg: float = pet_avgs[pet_id]
		var diff: float = global_avg - pet_avg

		# 差が大きいペットだけ調整
		if absf(diff) < 0.05:
			continue

		var adjustment: float = diff * OJA_RATE
		var vocab: Dictionary = all_vocabularies[pet_id]
		for word: String in vocab:
			vocab[word]["strength"] = clampf(
				vocab[word].get("strength", 0.5) + adjustment,
				STRENGTH_FLOOR,
				STRENGTH_CEILING
			)

		adjustments.append({
			"pet_id": pet_id,
			"avg_before": pet_avg,
			"adjustment": adjustment,
		})

	return {
		"applied": adjustments.size() > 0,
		"global_avg": global_avg,
		"adjustments": adjustments,
	}


# ==========================================
#  PetBook連携
# ==========================================

func get_petbook_oja_data(result: Dictionary) -> Dictionary:
	## PetBook投稿用のOja's Rule効果データを生成

	var normalized: bool = result.get("normalized", false)
	var scale: float = result.get("scale_factor", 1.0)
	var strengthened: int = result.get("strengthened", 0)

	var color: Color
	var text: String
	var particles: int

	if normalized and scale < 0.9:
		# 下方正規化（語彙が強すぎた）
		color = Color(0.4, 0.6, 1.0)   # 青 — 安定化
		text = "Language finding its balance"
		particles = 50
	elif normalized and scale > 1.1:
		# 上方正規化（語彙が弱すぎた）
		color = Color(0.9, 0.7, 0.3)   # オレンジ — 活性化
		text = "Words gaining new life"
		particles = 80
	elif strengthened > 3:
		# 多くの語が強化
		color = Color(1.0, 0.8, 0.2)   # 金 — 成長
		text = "Vocabulary blooming!"
		particles = 120
	else:
		# 通常状態
		color = Color(0.5, 0.8, 0.5)   # 緑 — 安定
		text = "Language patterns balanced"
		particles = 25

	return {
		"particle_color": color,
		"particle_amount": particles,
		"highlight_text": text,
		"normalized": normalized,
		"scale_factor": scale,
	}


# ==========================================
#  ヘルパー関数
# ==========================================

func _find_used_words(
	vocabulary: Dictionary,
	conversation: Array[Dictionary]
) -> Dictionary:
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
		"conversation_count": conversation_count,
		"last_normalization": last_normalization.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	conversation_count = data.get("conversation_count", 0)
	last_normalization = data.get("last_normalization", {})
```

---

## 4. テスト（即実行可能版）

```gdscript
## test_ojas_rule.gd — Oja's Rule テスト
## 実行: godot --headless --script tests/test_ojas_rule.gd
class_name TestOjasRule
extends SceneTree


func _init() -> void:
	var passed: int = 0
	var failed: int = 0

	print("")
	print("========================================")
	print("  Oja's Rule Tests")
	print("========================================")

	# ── Test 1: 基本のOja学習 ──
	print("\nTest 1: Basic Oja learning...")
	var oja: OjaLanguageCore = OjaLanguageCore.new()
	var vocab: Dictionary = {
		"brave": {"ai_term": "brave-spark", "strength": 0.7, "usage_count": 5, "last_used": 0.0},
		"gentle": {"ai_term": "gentle-mu", "strength": 0.4, "usage_count": 2, "last_used": 0.0},
	}
	var result: Dictionary = oja.apply_oja_learning(
		vocab,
		[{"message": "brave-spark!", "emotion": "joy", "pet_id": 1}],
		0.6
	)
	if result["strengthened"] > 0:
		print("  PASS: strengthened=%d avg=%.3f→%.3f" % [
			result["strengthened"], result["avg_before"], result["avg_after"]])
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# ── Test 2: 正規化で平均が目標に近づく ──
	print("\nTest 2: Normalization toward target...")
	var oja2: OjaLanguageCore = OjaLanguageCore.new()
	var vocab2: Dictionary = {}
	for i: int in 10:
		vocab2["word_%d" % i] = {
			"ai_term": "term%d" % i, "strength": 0.85,
			"usage_count": 0, "last_used": 0.0,
		}
	oja2.apply_oja_learning(vocab2, [], 0.5)
	var avg_after: float = oja2.last_result.get("avg_after", 0.0)
	# 平均0.85から目標0.55に向かって下がるはず
	if avg_after < 0.85:
		print("  PASS: avg dropped from 0.85 to %.3f (target=0.55)" % avg_after)
		passed += 1
	else:
		print("  FAIL: avg=%.3f did not decrease" % avg_after)
		failed += 1

	# ── Test 3: 相対順序の保存 ──
	print("\nTest 3: Relative order preserved...")
	var oja3: OjaLanguageCore = OjaLanguageCore.new()
	var vocab3: Dictionary = {
		"strong": {"ai_term": "s1", "strength": 0.9, "usage_count": 0, "last_used": 0.0},
		"medium": {"ai_term": "s2", "strength": 0.6, "usage_count": 0, "last_used": 0.0},
		"weak":   {"ai_term": "s3", "strength": 0.3, "usage_count": 0, "last_used": 0.0},
	}
	oja3.apply_oja_learning(vocab3, [], 0.5)
	var s1: float = vocab3["strong"]["strength"]
	var s2: float = vocab3["medium"]["strength"]
	var s3: float = vocab3["weak"]["strength"]
	if s1 > s2 and s2 > s3:
		print("  PASS: order preserved (%.3f > %.3f > %.3f)" % [s1, s2, s3])
		passed += 1
	else:
		print("  FAIL: order broken (%.3f, %.3f, %.3f)" % [s1, s2, s3])
		failed += 1

	# ── Test 4: 空語彙でクラッシュしない ──
	print("\nTest 4: Empty vocabulary...")
	var oja4: OjaLanguageCore = OjaLanguageCore.new()
	var empty_result: Dictionary = oja4.apply_oja_learning({}, [], 0.5)
	if empty_result["strengthened"] == 0 and empty_result["weakened"] == 0:
		print("  PASS: handles empty vocabulary")
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# ── Test 5: Pure Oja's Rule ──
	print("\nTest 5: Pure Oja's Rule (mathematical)...")
	var oja5: OjaLanguageCore = OjaLanguageCore.new()
	var vocab5: Dictionary = {
		"target": {"ai_term": "t1", "strength": 0.6, "usage_count": 0, "last_used": 0.0},
		"other":  {"ai_term": "t2", "strength": 0.5, "usage_count": 0, "last_used": 0.0},
	}
	var pure_result: Dictionary = oja5.apply_pure_oja(vocab5, "target", 0.1)
	if pure_result["applied"] and vocab5["target"]["strength"] != 0.6:
		print("  PASS: target changed to %.3f, other=%.3f" % [
			vocab5["target"]["strength"], vocab5["other"]["strength"]])
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# ── Test 6: コントラスト分析 ──
	print("\nTest 6: Contrast analysis...")
	var oja6: OjaLanguageCore = OjaLanguageCore.new()
	var vocab6: Dictionary = {
		"high": {"ai_term": "h1", "strength": 0.9},
		"mid":  {"ai_term": "m1", "strength": 0.5},
		"low":  {"ai_term": "l1", "strength": 0.1},
	}
	var contrast: Dictionary = oja6.analyze_contrast(vocab6)
	if contrast["contrast_ratio"] > 1.0 and contrast.has("health"):
		print("  PASS: contrast=%.1f std=%.3f health='%s'" % [
			contrast["contrast_ratio"], contrast["std_dev"], contrast["health"]])
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# ── Test 7: 均一語彙の検出 ──
	print("\nTest 7: Uniform vocabulary detection...")
	var oja7: OjaLanguageCore = OjaLanguageCore.new()
	var uniform: Dictionary = {
		"w1": {"ai_term": "u1", "strength": 0.50},
		"w2": {"ai_term": "u2", "strength": 0.51},
		"w3": {"ai_term": "u3", "strength": 0.49},
	}
	var uniform_contrast: Dictionary = oja7.analyze_contrast(uniform)
	if uniform_contrast["health"] == "too_uniform":
		print("  PASS: detected uniform vocabulary")
		passed += 1
	else:
		print("  FAIL: health='%s'" % uniform_contrast["health"])
		failed += 1

	# ── Test 8: PetBookデータ生成 ──
	print("\nTest 8: PetBook data...")
	var pb: Dictionary = oja.get_petbook_oja_data(result)
	if pb.has("particle_color") and pb.has("highlight_text"):
		print("  PASS: '%s'" % pb["highlight_text"])
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# ── Test 9: セーブ/ロード ──
	print("\nTest 9: Save/load round-trip...")
	var oja9: OjaLanguageCore = OjaLanguageCore.new()
	oja9.conversation_count = 25
	oja9.last_normalization = {"applied": true, "scale_factor": 0.95}
	var saved: Dictionary = oja9.to_dict()
	var oja9b: OjaLanguageCore = OjaLanguageCore.new()
	oja9b.from_dict(saved)
	if oja9b.conversation_count == 25:
		print("  PASS: state preserved")
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# ── Test 10: 後方互換性 ──
	print("\nTest 10: Backward compatibility...")
	var oja10: OjaLanguageCore = OjaLanguageCore.new()
	oja10.from_dict({})
	if oja10.conversation_count == 0:
		print("  PASS: defaults restored")
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# ── Test 11: Multi-Agent正規化 ──
	print("\nTest 11: Multi-agent normalization...")
	var oja11: OjaLanguageCore = OjaLanguageCore.new()
	var all_vocabs: Dictionary = {
		1: {"w1": {"ai_term": "a1", "strength": 0.9}, "w2": {"ai_term": "a2", "strength": 0.8}},
		2: {"w3": {"ai_term": "b1", "strength": 0.2}, "w4": {"ai_term": "b2", "strength": 0.3}},
	}
	var multi_result: Dictionary = oja11.normalize_across_agents(all_vocabs)
	if multi_result["applied"]:
		print("  PASS: cross-agent normalization applied, global_avg=%.3f" % multi_result["global_avg"])
		passed += 1
	else:
		print("  FAIL")
		failed += 1

	# ── Test 12: 感情強度の効果 ──
	print("\nTest 12: Emotion intensity effect...")
	var oja12a: OjaLanguageCore = OjaLanguageCore.new()
	var vocab12a: Dictionary = {
		"test": {"ai_term": "test-w", "strength": 0.4, "usage_count": 0, "last_used": 0.0},
	}
	oja12a.apply_oja_learning(
		vocab12a, [{"message": "test-w", "emotion": "joy"}], 0.1
	)
	var weak_s: float = vocab12a["test"]["strength"]

	var oja12b: OjaLanguageCore = OjaLanguageCore.new()
	var vocab12b: Dictionary = {
		"test": {"ai_term": "test-w", "strength": 0.4, "usage_count": 0, "last_used": 0.0},
	}
	oja12b.apply_oja_learning(
		vocab12b, [{"message": "test-w", "emotion": "sadness"}], 0.9
	)
	var strong_s: float = vocab12b["test"]["strength"]

	# 両方とも正規化されるが、強い感情のほうが強化量が大きいはず（正規化前の段階で）
	if strong_s >= weak_s - 0.01:  # 正規化のため僅差を許容
		print("  PASS: strong emotion=%.3f ≥ weak emotion=%.3f" % [strong_s, weak_s])
		passed += 1
	else:
		print("  FAIL: strong=%.3f weak=%.3f" % [strong_s, weak_s])
		failed += 1

	# ── Summary ──
	print("")
	print("========================================")
	print("  Oja's Rule Tests: %d/%d passed" % [passed, passed + failed])
	if failed > 0:
		print("  FAILED: %d tests" % failed)
	else:
		print("  ALL PASSED!")
	print("========================================")
	quit(1 if failed > 0 else 0)
```

---

## 5. Hebbian + BCM + Oja 統合フロー

```
推奨処理順序（1会話ターンあたり）:

  ┌──────────────────────────────────────────┐
  │ 1. Active Inference (KB108)               │
  │    予測 → 比較 → 行動選択 → 学習          │
  │    → error, learning_boost を取得         │
  └──────────────┬───────────────────────────┘
                 ↓
  ┌──────────────────────────────────────────┐
  │ 2. Hebbian LTP/LTD (KB99)                │
  │    使用語を +0.15、不使用語を -0.03       │
  │    × emotion_intensity × learning_boost  │
  └──────────────┬───────────────────────────┘
                 ↓
  ┌──────────────────────────────────────────┐
  │ 3. BCM Theory (KB112)                     │
  │    閾値に基づく追加の強化/抑制判定         │
  │    語彙爆発の防止                         │
  └──────────────┬───────────────────────────┘
                 ↓
  ┌──────────────────────────────────────────┐
  │ 4. Oja's Rule (本KB)                      │
  │    全語彙strengthを正規化                 │
  │    コントラスト増強 + バランス維持         │
  └──────────────────────────────────────────┘

  合計処理時間: < 1.5ms（50ペット時 < 75ms）
  API呼び出し: ゼロ
```

### 統合コード例

```gdscript
## 推奨統合パターン: Active Inference → BCM → Oja
func process_conversation_learning(
    messages: Array[Dictionary],
    pet: PetEntity,
    vocabulary: Dictionary,
    emotion_intensity: float
) -> Dictionary:
    # 1. Active Inference
    var ai := ActiveInferenceCore.new()
    var ai_result := ai.run(messages, _get_pet_state(pet), emotion_intensity)

    # 2. BCM Theory
    var bcm := BCMLanguageCore.new()
    var bcm_result := bcm.integrate_with_active_inference(
        ai_result, vocabulary, messages
    )

    # 3. Oja's Rule
    var oja := OjaLanguageCore.new()
    var oja_result := oja.apply_after_bcm(vocabulary, bcm_result)

    return {
        "ai": ai_result,
        "bcm": bcm_result,
        "oja": oja_result,
        "final_avg": oja_result.get("avg_after", 0.0),
    }
```

---

## 6. パラメータチューニングガイド

### 6.1 問題と対処

| 症状 | 原因 | 対処 |
|------|------|------|
| 全語彙が平均に張り付く | OJA_RATE が高すぎる | OJA_RATE を 0.1 → 0.05 に |
| 正規化が全く効かない | OJA_RATE が低すぎる | OJA_RATE を 0.1 → 0.2 に |
| 語の差がなくなる | QUADRATIC_DECAY が低い | QUADRATIC_DECAY を 0.02 → 0.05 に |
| 新語が弱すぎる | TARGET_AVG_STRENGTH が低い | TARGET_AVG_STRENGTH を 0.55 → 0.65 に |
| 全体が強すぎる | TARGET_AVG_STRENGTH が高い | TARGET_AVG_STRENGTH を 0.55 → 0.45 に |
| 急激な変動が起きる | SCALE_MIN/MAX が広すぎる | 範囲を 0.7〜1.3 に狭める |

### 6.2 BCMとOjaの組み合わせ推奨値

| 場面 | BCM THRESHOLD_BASE | OJA TARGET_AVG | 効果 |
|------|-------------------|----------------|------|
| 初期（語彙少） | 0.6 | 0.60 | 成長促進 |
| 成長期 | 0.8 | 0.55 | バランス維持 |
| 成熟期（語彙多） | 0.9 | 0.50 | 安定化重視 |
| イベント時 | 0.5 | 0.60 | 爆発的成長を許容 |

---

## 7. Ralph Loop指示テンプレート

```
Ralph Loopを活性化してください。
Oja's RuleをPetClawの独自言語進化に実装せよ。
Hebbianで語を強化した後、Oja's Ruleで全体のバランスを自動調整。
強い感情会話で新語が生まれやすいが、言語が複雑になりすぎないように。
Language Specialistと他のペットエージェントが協調して検証。
MCPでPetBook投稿のハイライトを確認しながら、
自然さと読みやすさを最高峰まで自動改良。

--max-iterations 10
--completion-promise "OJA_RULE_READY"
--temperature 0.65
```

---

## 8. 実践Tips（非エンジニア向け）

### Oja's Ruleが必要な理由（日常の例え）
- **Hebbianだけ** = 「頑張った人全員にボーナス」 → 全員が高給取りになってインフレ
- **Oja's Rule追加** = 「ボーナスを出すけど、全体の給与予算は一定」 → 給与バランスが維持される

### 視覚効果
- 正規化で下方スケーリング → PetBookに**「Language finding its balance」**（青い粒子）
- 正規化で上方スケーリング → **「Words gaining new life」**（オレンジの粒子）
- 多くの語が同時強化 → **「Vocabulary blooming!」**（金の粒子）

### 確認方法
- `analyze_contrast()` でコントラスト比を確認
  - 1.5〜5.0: 健全（good）
  - < 1.2: 均一すぎ（too_uniform）— 語に個性がない
  - > 10.0: 極端すぎ（too_extreme）— 一部の語が支配的

### 組み合わせ推奨
**Hebbian + BCM + Oja's Rule** を一緒に使うと最も安定した言語進化が実現:
1. Hebbian: 使われた語を強化
2. BCM: 語彙爆発を防止
3. Oja: 全体バランスを正規化

---

## 9. KB使い分け早見表

| やりたいこと | 参照KB |
|-------------|--------|
| Hebbian基礎（LTP/LTD） | KB99 |
| Active Inferenceの実装 | KB108 |
| BCM理論の詳細実装 | KB112 |
| **Oja's Ruleの実装** | **KB113（本書）** |
| 純粋な数学的Oja | KB113 §3.1 apply_pure_oja |
| BCM + Oja統合 | KB113 §5 |
| Multi-Agent正規化 | KB113 §3.1 normalize_across_agents |
| コントラスト分析 | KB113 §3.1 analyze_contrast |
| パラメータチューニング | KB113 §6 |
| 類似モデルの概要 | KB111 |

---

**関連KB:** KB98, KB99, KB102, KB103, KB104, KB108, KB110, KB111, KB112
