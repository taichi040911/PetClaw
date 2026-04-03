# KB111: Hebbian学習に類似する生物学習モデルの応用ガイド
## PetClaw AtoA独自言語進化・感情・記憶・Multi-Agent協調への統合
**Version:** 2026-04-03
**対象:** Claude Code / Claude Cowork / Agent Teams / 非エンジニア
**前提知識:** KB99 (Hebbian), KB102 (STDP), KB103 (予測符号化), KB104 (FEP), KB107-108 (Active Inference)

---

## 1. Hebbian学習との関係まとめ

Hebbian学習（「一緒に発火する細胞はつながる」）は**局所的な強化ルール**です。
類似モデルはこれを**拡張・補完**する形で進化しており、PetClawでは**予測誤差の扱い・安定性・感情連動・創発性**をさらに豊かにできます。

```
Hebbian学習（基本）
  ├── BCM Theory → 閾値依存で過剰活性を防止
  ├── Oja's Rule → 正規化で安定化
  ├── Homeostatic Plasticity → 全体活動レベルの恒常性維持
  ├── Dopamine-modulated Plasticity → 報酬/感情駆動の学習加速
  ├── Synaptic Scaling → ネットワーク全体のバランス調整
  ├── Metaplasticity → 「学習のしやすさ」自体が変化
  └── Competitive Learning → 勝者総取りで特化・分化
```

### PetClawでの位置づけ

| 学習モデル | 既存実装 | 追加で得られる効果 |
|-----------|---------|------------------|
| **Hebbian LTP/LTD** | ✅ KB99, original_language_engine.gd | 基本的な語彙強化・弱化 |
| **STDP** | ✅ KB102 (設計済み) | 会話ターン順序に基づく時間依存強化 |
| **予測符号化** | ✅ KB103 (設計済み) | 3層予測モデルによる驚き検出 |
| **Active Inference** | ✅ KB108, active_inference_core.gd | 予測→行動→学習のフルループ |
| **BCM Theory** | 🆕 本KB | 語彙爆発の自動抑制 |
| **Oja's Rule** | 🆕 本KB | 語彙バランスの正規化 |
| **Homeostatic Plasticity** | 🆕 本KB | 長期安定性の維持 |
| **Dopamine-modulated** | 🆕 本KB | 感情イベントでの爆発的学習 |
| **Synaptic Scaling** | 🆕 本KB | Multi-Agent間の言語バランス |
| **Metaplasticity** | 🆕 本KB | 学習感受性の動的調整 |
| **Competitive Learning** | 🆕 本KB | 派閥言語の分化促進 |

---

## 2. 各モデルの詳細とPetClaw応用

### 2.1 BCM Theory (Bienenstock-Cooper-Munro Theory)

**神経科学基礎:**
- Hebbianの「閾値依存版」
- シナプス強化に**スライディング閾値**がある
- 活動が閾値を超えるとLTP（強化）、下回るとLTD（弱化）
- 閾値自体が過去の活動量に応じて動的に変化する
- **過剰活性を自動防止**: 活動が高すぎると閾値が上がり、強化されにくくなる

**PetClaw応用:**
独自言語が爆発的に増えすぎないよう自動調整。強い感情会話で新語が強化されるが、日常会話では安定。

**応用例:**
接尾辞「-spark」が頻出するとstrengthが上がるが、一定以上で自動抑制（言語の自然さ維持）。

```gdscript
## BCM Theory: スライディング閾値による語彙安定化
## 語彙が増えすぎると閾値が上がり、新語の定着が難しくなる

const BCM_BASE_THRESHOLD: float = 0.5
const BCM_THRESHOLD_RATE: float = 0.01   # 閾値の変化速度

## スライディング閾値を計算
## 最近の平均strengthが高い → 閾値が上がる → 新語が定着しにくくなる
func calculate_bcm_threshold(vocabulary: Dictionary) -> float:
	if vocabulary.is_empty():
		return BCM_BASE_THRESHOLD

	var total_strength: float = 0.0
	var count: int = 0
	for word: String in vocabulary:
		total_strength += vocabulary[word].get("strength", 0.0)
		count += 1

	var avg_strength: float = total_strength / float(count)

	# 閾値 = 基本値 + 平均strength × 調整率
	# 語彙全体が強いほど、新しい語の定着に高い活動が必要
	return BCM_BASE_THRESHOLD + avg_strength * BCM_THRESHOLD_RATE * float(count)


## BCM変調付きHebbian強化
## delta > 0: threshold以上の活動 → LTP（強化）
## delta < 0: threshold以下の活動 → LTD（弱化）
func apply_bcm_hebbian(
	word_strength: float,
	activity: float,        # 使用頻度・会話での出現率
	threshold: float
) -> float:
	var delta: float
	if activity > threshold:
		# 閾値を超えた → 強化（でも閾値が高いと強化幅は小さい）
		delta = 0.15 * (activity - threshold)
	else:
		# 閾値以下 → 弱化
		delta = -0.05 * (threshold - activity)

	return clampf(word_strength + delta, 0.0, 1.0)
```

**バランス効果:**
- 語彙数5個: 閾値 ≈ 0.52 → 新語が定着しやすい
- 語彙数30個: 閾値 ≈ 0.65 → 新語の定着にはより強い使用が必要
- 語彙数80個: 閾値 ≈ 0.90 → 新語はほぼ定着しない → 語彙の自然な飽和

---

### 2.2 Oja's Rule（正規化Hebbian学習）

**神経科学基礎:**
- Hebbianの**正規化版**
- 強化されすぎたシナプスを全体の合計でスケーリングし安定化
- 重みベクトルの大きさが一定に保たれる
- **主成分分析（PCA）との数学的等価性**: 最も重要なパターンを自動抽出

**PetClaw応用:**
独自言語の複雑性を自動調整。新しい接尾辞が生まれても全体の言語バランスが崩れない。

**応用例:**
「happy-spark」と「brave-force」が同時に強くなったら、両方を少し弱めてバランスを取る。

```gdscript
## Oja's Rule: 語彙strength全体を正規化
## 1つの語が極端に強くなるのを防ぎ、多様性を維持

const OJA_LEARNING_RATE: float = 0.1
const OJA_TARGET_NORM: float = 5.0   # 全strengthの目標合計値

## Oja's Rule適用後のstrengthを計算
func apply_oja_rule(
	word_strength: float,
	input_activity: float,   # その語が使われた強度
	total_strength: float    # 全語彙のstrength合計
) -> float:
	# Oja's Rule: Δw = η * (x * y - y² * w)
	# x = input_activity, y = word_strength, w = word_strength
	var output: float = word_strength * input_activity
	var delta: float = OJA_LEARNING_RATE * (
		input_activity * output - output * output * word_strength
	)
	return clampf(word_strength + delta, 0.0, 1.0)


## 語彙全体の正規化（Oja-inspired normalization）
## 全strengthの合計が目標値を超えたらスケーリング
func normalize_vocabulary_strength(vocabulary: Dictionary) -> void:
	var total: float = 0.0
	for word: String in vocabulary:
		total += vocabulary[word].get("strength", 0.0)

	if total <= OJA_TARGET_NORM or total == 0.0:
		return  # 正規化不要

	# スケーリング係数
	var scale: float = OJA_TARGET_NORM / total

	for word: String in vocabulary:
		vocabulary[word]["strength"] = vocabulary[word].get("strength", 0.0) * scale
```

**効果例:**
```
正規化前:
  happy-spark: 0.95, brave-force: 0.90, gentle-mu: 0.85, play-ba: 0.80
  合計: 3.50 (4語)

正規化後（目標合計: 5.0, 語彙30個で合計8.0の場合）:
  全体がスケーリングされ、極端な支配を防止
```

---

### 2.3 Homeostatic Plasticity（恒常性可塑性）

**神経科学基礎:**
- 全体の神経活動レベルを一定に保つ仕組み
- Hebbianだけではネットワークが不安定になる（暴走 or 沈黙）
- **長期的にスケーリング**して安定を維持
- 時間スケール: Hebbian = 秒〜分、Homeostatic = 時間〜日

**PetClaw応用:**
ペット同士の会話が長期間続いても言語がカオス化せず、安定した関係性を維持。

**応用例:**
長時間AtoA会話で新語が増えすぎたら、既存の基本語を少し強化して全体バランスを取る。

```gdscript
## Homeostatic Plasticity: 長期的な語彙活動レベルの安定化
## 活動が高すぎる → 全体を抑制、低すぎる → 全体を興奮

const HOMEOSTATIC_TARGET: float = 0.5    # 目標平均strength
const HOMEOSTATIC_RATE: float = 0.02     # 調整速度（ゆっくり）
const HOMEOSTATIC_INTERVAL: int = 10     # 10会話ごとに適用

var homeostatic_counter: int = 0

## 恒常性調整を実行
## 全語彙の平均strengthが目標から外れていたら、全体をゆっくり調整
func apply_homeostatic_plasticity(vocabulary: Dictionary) -> Dictionary:
	homeostatic_counter += 1
	if homeostatic_counter < HOMEOSTATIC_INTERVAL:
		return {"applied": false, "adjustment": 0.0}

	homeostatic_counter = 0

	if vocabulary.is_empty():
		return {"applied": false, "adjustment": 0.0}

	# 平均strengthを計算
	var total: float = 0.0
	var count: int = 0
	for word: String in vocabulary:
		total += vocabulary[word].get("strength", 0.0)
		count += 1

	var avg: float = total / float(count)
	var diff: float = HOMEOSTATIC_TARGET - avg

	# 目標との差が小さければスキップ
	if absf(diff) < 0.05:
		return {"applied": false, "adjustment": 0.0}

	# 全語彙を微調整
	var adjustment: float = diff * HOMEOSTATIC_RATE
	for word: String in vocabulary:
		vocabulary[word]["strength"] = clampf(
			vocabulary[word].get("strength", 0.0) + adjustment,
			0.0, 1.0
		)

	return {"applied": true, "adjustment": adjustment, "avg_before": avg, "avg_after": avg + adjustment}
```

**タイムライン:**
```
会話 1-9:   Hebbian LTP/LTD が自由に動作
会話 10:    Homeostatic チェック → 平均が0.7なら全体を-0.004ずつ調整
会話 11-19: また自由に動作
会話 20:    Homeostatic チェック → 平均が0.48ならほぼ調整なし
```

---

### 2.4 Dopamine-modulated Plasticity（報酬/感情駆動学習）

**神経科学基礎:**
- Hebbianに**ドーパミン（報酬・感情シグナル）**を乗算
- 三因子学習: pre-synaptic × post-synaptic × neuromodulator
- 強い報酬/感情で学習が**大幅に加速**
- 逆に報酬なしでは学習が**抑制**される
- PetClawでは**感情強度 = ドーパミン信号**として使用

**PetClaw応用:**
生き死にや交配のような強い感情イベントで新語・接尾辞が爆発的に定着。

**応用例:**
蘇生後の会話で「rebirth-spark」が一気にstrengthアップ。

```gdscript
## Dopamine-modulated Plasticity: 感情駆動の学習変調
## 感情が強いほど学習が加速される（三因子学習）

## 感情→ドーパミンレベルのマッピング
## 強い感情イベントほど高いドーパミン（学習加速）
const DOPAMINE_MAP: Dictionary = {
	"joy": 1.2,          # 喜び → やや加速
	"excitement": 1.5,   # 興奮 → 加速
	"love": 1.3,         # 愛情 → 加速
	"sadness": 1.4,      # 悲しみ → 加速（追悼学習）
	"fear": 0.8,         # 恐怖 → やや抑制（安全優先）
	"anger": 1.1,        # 怒り → やや加速
	"neutral": 1.0,      # 中立 → 変調なし
	"surprise": 1.6,     # 驚き → 大幅加速
}

## イベント種別→ドーパミンブーストのマッピング
const EVENT_DOPAMINE_BOOST: Dictionary = {
	"death": 2.0,        # 死亡 → 最大の学習加速
	"resurrection": 2.5, # 蘇生 → 爆発的学習
	"breeding": 1.8,     # 交配 → 大きな加速
	"evolution": 1.6,    # 進化 → 加速
	"first_meeting": 1.4,# 初対面 → 加速
	"daily": 1.0,        # 日常 → 変調なし
}


## ドーパミン変調付きHebbian強化
## delta = base_ltp × dopamine_level × emotion_intensity × event_boost
func apply_dopamine_modulated_hebbian(
	word_strength: float,
	emotion: String,
	emotion_intensity: float,
	event_type: String = "daily"
) -> float:
	var base_ltp: float = 0.15  # Hebbian LTP (KB99)

	# ドーパミンレベル（感情種別）
	var dopamine: float = DOPAMINE_MAP.get(emotion, 1.0)

	# イベントブースト
	var event_boost: float = EVENT_DOPAMINE_BOOST.get(event_type, 1.0)

	# 三因子学習: base × dopamine × intensity × event
	var delta: float = base_ltp * dopamine * emotion_intensity * event_boost

	# 上限: 1回の強化で+0.6を超えない（安全弁）
	delta = minf(delta, 0.6)

	return clampf(word_strength + delta, 0.0, 1.0)
```

**効果例:**
```
日常会話（neutral, 0.5, daily）:
  delta = 0.15 × 1.0 × 0.5 × 1.0 = 0.075

死亡イベント（sadness, 0.9, death）:
  delta = 0.15 × 1.4 × 0.9 × 2.0 = 0.378  ← 5倍の学習加速！

蘇生イベント（excitement, 0.95, resurrection）:
  delta = 0.15 × 1.5 × 0.95 × 2.5 = 0.534 ← 7倍の学習加速！
```

---

### 2.5 Synaptic Scaling（シナプススケーリング）

**神経科学基礎:**
- 個々のシナプスではなく**ニューロン全体**の活動レベルを調整
- 全シナプスの強度を**乗算的に**スケーリング
- Homeostatic Plasticityの一種だが、より細かい粒度で動作
- **相対的な強度比率を保存**しながら全体レベルを調整

**PetClaw応用:**
1匹のペットが特定の言葉ばかり使うと、そのペットの語彙全体がスケーリングされる。
他のペットへの影響も考慮したMulti-Agentレベルの調整。

```gdscript
## Synaptic Scaling: ペットごとの語彙活動レベルを調整
## 特定ペットの言語活動が極端に偏らないようにする

const SCALING_TARGET_ACTIVITY: float = 0.5  # 目標活動レベル
const SCALING_TAU: float = 0.05             # 調整の時定数

## ペット単位のシナプススケーリング
## 全語彙のstrength比率を保ったまま、平均を目標に近づける
func apply_synaptic_scaling(
	vocabulary: Dictionary,
	pet_id: int
) -> Dictionary:
	if vocabulary.is_empty():
		return {"scaled": false}

	# 現在の平均活動レベル
	var total: float = 0.0
	var count: int = 0
	for word: String in vocabulary:
		total += vocabulary[word].get("strength", 0.0)
		count += 1

	var current_avg: float = total / float(count)

	# スケーリング係数（乗算的）
	# 平均が高すぎる → scale < 1.0 → 全体を抑制
	# 平均が低すぎる → scale > 1.0 → 全体を興奮
	var target_ratio: float = SCALING_TARGET_ACTIVITY / maxf(current_avg, 0.01)
	var scale: float = 1.0 + SCALING_TAU * (target_ratio - 1.0)

	# 極端なスケーリングを防止
	scale = clampf(scale, 0.9, 1.1)

	for word: String in vocabulary:
		vocabulary[word]["strength"] = clampf(
			vocabulary[word].get("strength", 0.0) * scale,
			0.0, 1.0
		)

	return {
		"scaled": true,
		"pet_id": pet_id,
		"scale_factor": scale,
		"avg_before": current_avg,
		"avg_after": current_avg * scale,
	}


## Multi-Agentレベルのスケーリング
## 全ペットの語彙活動を比較し、極端に偏ったペットを調整
func apply_multi_agent_scaling(
	all_vocabularies: Dictionary  # {pet_id: vocabulary}
) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	# 全ペットの平均を計算
	var global_avg: float = 0.0
	var pet_count: int = 0
	for pet_id: int in all_vocabularies:
		var vocab: Dictionary = all_vocabularies[pet_id]
		if vocab.is_empty():
			continue
		var pet_total: float = 0.0
		for word: String in vocab:
			pet_total += vocab[word].get("strength", 0.0)
		global_avg += pet_total / float(vocab.size())
		pet_count += 1

	if pet_count == 0:
		return results

	global_avg /= float(pet_count)

	# 各ペットをグローバル平均に向けてスケーリング
	for pet_id: int in all_vocabularies:
		var result: Dictionary = apply_synaptic_scaling(
			all_vocabularies[pet_id], pet_id
		)
		results.append(result)

	return results
```

---

### 2.6 Metaplasticity（メタ可塑性）

**神経科学基礎:**
- **「学習のしやすさ」自体が変化する**メカニズム
- 最近たくさん学習した → 次の学習が**難しくなる**
- 最近あまり学習していない → 次の学習が**容易になる**
- BCM閾値の動的調整の一般化
- **学習の飽和を防ぎ、新しいパターンの獲得を促進**

**PetClaw応用:**
最近語彙を大量に獲得したペットは、次の会話では既存語の強化に集中。
逆に長く新語を獲得していないペットは、次の会話で新語を作りやすくなる。

```gdscript
## Metaplasticity: 学習感受性の動的調整
## 「最近どれだけ学習したか」で次の学習のしやすさが変わる

const META_WINDOW: int = 5        # 直近5会話を参照
const META_HIGH_ACTIVITY: float = 3.0  # この回数以上新語獲得 → 学習抑制
const META_LOW_ACTIVITY: float = 1.0   # この回数以下 → 学習促進

var recent_learning_events: Array[float] = []  # 直近の学習イベント数


## メタ可塑性係数を計算
## 戻り値: 1.0 = 通常, >1.0 = 学習促進, <1.0 = 学習抑制
func calculate_metaplasticity_factor() -> float:
	if recent_learning_events.is_empty():
		return 1.2  # 初期状態 → やや促進（新語が生まれやすい）

	# 直近の学習イベント数の平均
	var window: Array[float] = recent_learning_events.slice(
		-META_WINDOW
	)
	var avg: float = 0.0
	for v: float in window:
		avg += v
	avg /= float(window.size())

	# 高活動 → 抑制、低活動 → 促進
	if avg > META_HIGH_ACTIVITY:
		return 0.6   # 学習飽和 → 新語が定着しにくい
	elif avg < META_LOW_ACTIVITY:
		return 1.5   # 学習飢餓 → 新語が定着しやすい
	else:
		return 1.0   # 通常


## メタ可塑性をActive Inferenceと統合
func apply_with_metaplasticity(
	ai_result: Dictionary,
	new_words_this_turn: int
) -> Dictionary:
	# 学習イベントを記録
	recent_learning_events.append(float(new_words_this_turn))
	if recent_learning_events.size() > META_WINDOW * 2:
		recent_learning_events = recent_learning_events.slice(-META_WINDOW)

	# メタ可塑性係数を計算
	var meta_factor: float = calculate_metaplasticity_factor()

	# Active Inferenceのlearning_boostを変調
	var original_boost: float = ai_result.get("learning_boost", 1.0)
	var modulated_boost: float = original_boost * meta_factor

	return {
		"learning_boost": modulated_boost,
		"meta_factor": meta_factor,
		"original_boost": original_boost,
		"recent_avg_events": recent_learning_events.slice(-META_WINDOW),
	}
```

**効果例:**
```
ペットA（直近5会話で新語8個獲得）:
  meta_factor = 0.6 → 学習飽和 → 新語が定着しにくい
  → 既存語の安定化に集中

ペットB（直近5会話で新語0個獲得）:
  meta_factor = 1.5 → 学習飢餓 → 新語が定着しやすい
  → 次の強い感情イベントで爆発的に新語を獲得
```

---

### 2.7 Competitive Learning（競合学習）

**神経科学基礎:**
- **勝者総取り（Winner-Take-All）**: 最も活性化されたニューロンだけが学習
- 他のニューロンは**抑制**される
- 特化・分化を促進
- **自己組織化マップ（SOM）**の基礎

**PetClaw応用:**
派閥（Faction）ごとに異なる言語が分化していく仕組み。
ある派閥で支配的な接尾辞が決まると、他の接尾辞は抑制される。

```gdscript
## Competitive Learning: 派閥内での語彙競合
## 最も使われる接尾辞が「勝者」になり、他は抑制される

const COMPETITIVE_WINNER_BOOST: float = 0.10
const COMPETITIVE_LOSER_PENALTY: float = -0.03
const COMPETITIVE_MIN_VOCAB: int = 5     # 競合開始の最低語彙数

## 派閥内の接尾辞競合を処理
## 最も使用頻度の高い接尾辞が強化され、他は弱化される
func apply_competitive_learning(
	vocabulary: Dictionary,
	faction_id: String
) -> Dictionary:
	if vocabulary.size() < COMPETITIVE_MIN_VOCAB:
		return {"applied": false, "reason": "too few words"}

	# 接尾辞ごとの使用回数を集計
	var suffix_counts: Dictionary = {}
	for word: String in vocabulary:
		var ai_term: String = vocabulary[word].get("ai_term", "")
		var suffix: String = _extract_suffix(ai_term)
		if suffix.is_empty():
			continue
		suffix_counts[suffix] = suffix_counts.get(suffix, 0) + vocabulary[word].get("usage_count", 0)

	if suffix_counts.is_empty():
		return {"applied": false, "reason": "no suffixes found"}

	# 勝者を決定
	var winner_suffix: String = ""
	var max_count: int = 0
	for suffix: String in suffix_counts:
		if suffix_counts[suffix] > max_count:
			max_count = suffix_counts[suffix]
			winner_suffix = suffix

	# 勝者の語彙を強化、他を弱化
	var strengthened: int = 0
	var weakened: int = 0
	for word: String in vocabulary:
		var ai_term: String = vocabulary[word].get("ai_term", "")
		var suffix: String = _extract_suffix(ai_term)
		if suffix.is_empty():
			continue

		if suffix == winner_suffix:
			vocabulary[word]["strength"] = clampf(
				vocabulary[word].get("strength", 0.0) + COMPETITIVE_WINNER_BOOST,
				0.0, 1.0
			)
			strengthened += 1
		else:
			vocabulary[word]["strength"] = clampf(
				vocabulary[word].get("strength", 0.0) + COMPETITIVE_LOSER_PENALTY,
				0.0, 1.0
			)
			weakened += 1

	return {
		"applied": true,
		"faction_id": faction_id,
		"winner_suffix": winner_suffix,
		"strengthened": strengthened,
		"weakened": weakened,
	}


## 接尾辞を抽出（ハイフン区切りの最後の部分）
func _extract_suffix(ai_term: String) -> String:
	if not ai_term.contains("-"):
		return ""
	var parts: PackedStringArray = ai_term.split("-")
	return parts[parts.size() - 1]
```

**効果例:**
```
Faction "Brave Warriors":
  brave-spark: usage 15 → 勝者 (suffix: spark)
  brave-force: usage 8  → 敗者 (-0.03)
  brave-mu:    usage 3  → 敗者 (-0.03)

  結果: "-spark" が派閥の支配的接尾辞に
  → 他派閥は "-mu" や "-ba" が支配的になる
  → 派閥間の言語分化が自然に発生
```

---

## 3. 統合アーキテクチャ

### 3.1 全モデルの処理順序

```
1会話ターンの処理フロー:

  ┌─────────────────────────────────────────┐
  │ Active Inference Core (KB108)            │
  │  1. 予測 → 2. 比較 → 3. 行動選択 → 4. 学習  │
  └──────────────┬──────────────────────────┘
                 ↓
  ┌─────────────────────────────────────────┐
  │ Dopamine-modulated Plasticity           │
  │  感情×イベント → 学習加速係数            │
  └──────────────┬──────────────────────────┘
                 ↓
  ┌─────────────────────────────────────────┐
  │ Metaplasticity                          │
  │  最近の学習量 → 感受性調整              │
  └──────────────┬──────────────────────────┘
                 ↓
  ┌─────────────────────────────────────────┐
  │ Hebbian LTP/LTD (KB99)                  │
  │  × dopamine × meta_factor → Δstrength  │
  └──────────────┬──────────────────────────┘
                 ↓
  ┌─────────────────────────────────────────┐
  │ BCM Theory (語彙が多いとき)              │
  │  スライディング閾値 → 新語定着制限       │
  └──────────────┬──────────────────────────┘
                 ↓
  ┌─────────────────────────────────────────┐
  │ Oja's Rule (strength合計が目標超過時)     │
  │  正規化 → 比率保存スケーリング           │
  └──────────────┬──────────────────────────┘
                 ↓ (10会話ごと)
  ┌─────────────────────────────────────────┐
  │ Homeostatic Plasticity                   │
  │  平均strength → 目標値へ微調整           │
  └──────────────┬──────────────────────────┘
                 ↓ (派閥形成後)
  ┌─────────────────────────────────────────┐
  │ Competitive Learning                     │
  │  勝者接尾辞 → 強化、他 → 抑制           │
  └──────────────┬──────────────────────────┘
                 ↓ (Multi-Agent)
  ┌─────────────────────────────────────────┐
  │ Synaptic Scaling                         │
  │  全ペット間のバランス調整                │
  └─────────────────────────────────────────┘
```

### 3.2 計算コスト見積もり

| モデル | 1会話あたり | 頻度 | 50ペットでの合計 |
|--------|-----------|------|----------------|
| Active Inference | < 0.5ms | 毎ターン | < 25ms |
| Dopamine-modulated | < 0.1ms | 毎ターン | < 5ms |
| Metaplasticity | < 0.1ms | 毎ターン | < 5ms |
| Hebbian LTP/LTD | < 0.2ms | 毎ターン | < 10ms |
| BCM Theory | < 0.1ms | 毎ターン | < 5ms |
| Oja's Rule | < 0.1ms | 語彙超過時 | < 2ms |
| Homeostatic | < 0.1ms | 10会話ごと | < 1ms |
| Competitive | < 0.2ms | 派閥形成後 | < 5ms |
| Synaptic Scaling | < 0.3ms | 10会話ごと | < 3ms |
| **合計** | **< 1.5ms** | — | **< 61ms** |

**すべてローカル計算。API呼び出しゼロ。P2原則完全準拠。**

---

## 4. PetClaw機能との連動マトリクス

| 機能 | 関与モデル | 効果 |
|------|-----------|------|
| **新語誕生** | Active Inference + Dopamine + Meta | 驚き×感情×感受性で創出 |
| **語彙定着** | Hebbian + BCM + Oja | 使用で強化、過剰を抑制 |
| **語彙消滅** | Hebbian LTD + Homeostatic | 不使用で弱化、長期安定 |
| **追悼語彙** | Dopamine (death event) + AI高surprise | 爆発的定着 |
| **交配語彙** | Dopamine (breeding) + Meta促進 | 新語が生まれやすい |
| **派閥言語** | Competitive + Synaptic Scaling | 支配接尾辞の分化 |
| **言語バランス** | Oja + Homeostatic + Synaptic | 3層の安定化機構 |
| **長期進化** | Meta + Homeostatic | 飽和防止、新パターン促進 |

---

## 5. 視覚フィードバック連携（PetBook投稿）

| 学習モデル | PetBook表示 | 粒子色 |
|-----------|------------|--------|
| Dopamine × death | "A word of farewell was born..." | 紫 (0.6, 0.3, 0.8) |
| Dopamine × resurrection | "A word of rebirth emerged!" | 金 (1.0, 0.9, 0.3) |
| Competitive winner | "'-spark' became the faction's signature!" | 赤 (1.0, 0.4, 0.3) |
| Homeostatic rebalance | "Language patterns stabilized" | 青 (0.4, 0.6, 1.0) |
| Metaplasticity burst | "A creative explosion of new words!" | 虹色 |

---

## 6. Ralph Loop指示テンプレート

```
Ralph Loopを活性化してください。
Hebbian学習に類似する生物学習モデル（BCM、Oja's Rule、Homeostatic Plasticity、
Dopamine-modulated、Synaptic Scaling、Metaplasticity、Competitive Learning）を
PetClawの独自言語進化に統合せよ。

予測誤差が大きい場面で新語を強く定着させ、全体の言語バランスを自動調整。
Multi-Agent協調で検証し、MCPでPetBook投稿の視覚効果を確認しながら、
自然さと安定性を最高峰まで自動改良。

--max-iterations 12
--completion-promise "BIOLOGICAL_LEARNING_MODELS_INTEGRATED"
--temperature 0.7
```

---

## 7. KB使い分け早見表

| やりたいこと | 参照KB |
|-------------|--------|
| Hebbian基礎を理解 | KB99 |
| STDPで時間依存学習 | KB102 |
| 予測符号化で驚き検出 | KB103 |
| FEPの数学的基礎 | KB104 |
| Active Inferenceの実装 | KB107, KB108 |
| 語彙爆発を防ぎたい | KB111 (BCM, Oja) |
| 感情イベントで学習加速 | KB111 (Dopamine) |
| 長期的な言語安定 | KB111 (Homeostatic) |
| 派閥言語の分化 | KB111 (Competitive) |
| Multi-Agent間のバランス | KB111 (Synaptic Scaling) |
| 学習飽和の防止 | KB111 (Metaplasticity) |
| 実践的な応用例 | KB110 |

---

**関連KB:** KB98, KB99, KB102, KB103, KB104, KB105, KB106, KB107, KB108, KB109, KB110
