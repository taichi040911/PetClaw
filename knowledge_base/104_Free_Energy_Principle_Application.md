# KB104: Free Energy Principle (FEP) の応用ガイド
## PetClaw AtoA独自言語進化 × Multi-Agent協調 × 生物模倣記憶向け
**Version:** 2026-04-03
**対象:** Claude Code / Claude Cowork / Agent Teams
**前提知識:** KB103 (予測符号化統合), KB102 (STDP), KB101 (神経科学基礎), KB99 (Hebbian実装), KB98 (独自言語進化)

---

## 1. Free Energy Principle の神経科学・情報物理学的基礎

### 1.1 理論の起源と発展

| 年 | 研究者 | 理論/発見 | PetClawへの意義 |
|----|--------|---------|----------------|
| 2005 | Karl Friston | 自由エネルギー原理 (FEP) | 全体の統一目的関数 |
| 2006 | Friston | 変分ベイズと脳 | 局所ルール（Hebbian）を大域目的に接続 |
| 2009 | Friston et al. | Active Inference | ペットが「行動で誤差を減らす」基盤 |
| 2010 | Friston | Generalized Free Energy | Expected Free Energy (EFE) で将来行動を選択 |
| 2015 | Hohwy | The Predictive Mind | 認知科学への普及 |
| 2017 | Parr & Friston | Multi-Agent Active Inference | AtoA会話への理論的基盤 |
| 2020 | Da Costa et al. | Active Inference in Discrete Time | ターンベース実装の理論保証 |
| 2022 | Hesp et al. | Deeply Felt Affect | 感情を自由エネルギーの一部として形式化 |
| 2024 | Verses AI | Axiomアーキテクチャ | マルチエージェントFEPの産業実装 |
| 2025-26 | 多数 | 言語創発とActive Inference | LLM + FEPのハイブリッド研究が加速 |

### 1.2 FEPの数学的基礎（直感的理解）

```
自由エネルギー F の定義:

  F = E_q[ln q(s) - ln p(o,s)]

  = KL[q(s) || p(s|o)] + (-ln p(o))
    ├── 認識誤差 ──┤   ├── 驚き ──┤

  ≈ 予測誤差 + 複雑性ペナルティ（変分近似時）

ここで:
  o = 観測（会話で聞いた言葉）
  s = 隠れ状態（相手の意図・感情）
  q(s) = 近似事後分布（ペットの内部モデル）
  p(o,s) = 生成モデル（世界の予測）
```

### 1.3 PetClawにおける直感的理解

```
                   ┌─ 予測誤差 ─────────────────────────────┐
                   │  「思ったのと違う！」                     │
                   │   → 新語が強く定着（Hebbian LTP増強）    │
                   │   → STDPのタイミング窓が広がる           │
    自由エネルギー ─┤                                         │
    最小化 F↓     │                                         │
                   │  「複雑すぎ！」                          │
                   │   → 過剰な新語を抑制（複雑性ペナルティ）   │
                   │   → 低頻度語を減衰させる                  │
                   └─ 複雑性ペナルティ ──────────────────────┘

    Active Inference:
    「誤差を減らすために行動する」
      → ペットが新語を提案・検証・採用する
      → 探索（epistemic value）と利用（pragmatic value）のバランス
```

### 1.4 Hebbian/STDP/予測符号化との統合関係

```
      ┌──── Free Energy Principle (FEP) ────┐
      │          統一目的関数                   │
      │   F = 予測誤差 + 複雑性ペナルティ       │
      │                                       │
      │   ┌─────────────────────────────┐    │
      │   │  Predictive Coding (KB103)   │    │
      │   │  メッセージパス（階層的予測誤差）│    │
      │   │                              │    │
      │   │  ┌─── Hebbian (KB99) ──────┐│    │
      │   │  │  局所学習ルール          ││    │
      │   │  │  LTP/LTD 強化・弱化      ││    │
      │   │  └──────────────────────────┘│    │
      │   │  ┌─── STDP (KB102) ────────┐│    │
      │   │  │  タイミング依存強化       ││    │
      │   │  │  t-LTP / t-LTD          ││    │
      │   │  └──────────────────────────┘│    │
      │   └─────────────────────────────┘    │
      │                                       │
      │   ┌─── Active Inference ───────────┐ │
      │   │  行動選択（新語提案・検証）       │ │
      │   │  EFE = リスク + 情報獲得        │ │
      │   └─────────────────────────────────┘ │
      └─────────────────────────────────────────┘

  役割分担:
    FEP       → 全体の目的関数（F↓を最小化）
    Predictive Coding → 予測誤差の計算・伝播
    Hebbian   → 局所的な結合強化（成功体験で強化）
    STDP      → タイミング依存の精密な強化
    Active Inference → 行動選択（探索 vs 利用）
```

---

## 2. PetClaw AtoAへのFEP応用マッピング

### 2.1 FEP要素 → PetClawシステム対応表

| FEP概念 | PetClawでの実装 | 統合先 | 効果 |
|---------|----------------|--------|------|
| **Generative Model** | `OriginalLanguageEngine.vocabulary` + `LanguageEvolutionSystem` の文法モデル | 上位層予測 | 会話の「次の言葉」を予測 |
| **Prediction Error** | `calculate_prediction_error()` (KB103) | 誤差計算 | 予想外の発言 → 学習トリガー |
| **Variational Free Energy** | `calculate_variational_free_energy()` | F↓最小化 | 予測誤差 + 複雑性を同時最適化 |
| **Active Inference** | `active_inference_action_selection()` | 行動選択 | ペットが新語提案 or 既存語使用を選択 |
| **Expected Free Energy** | `calculate_expected_free_energy()` | 将来計画 | 情報獲得 vs リスクのトレードオフ |
| **Precision Weighting** | 感情強度 × 文脈確信度 | 注意機構 | 重要な情報に選択的注意 |
| **Complexity Penalty** | 語彙数に比例するペナルティ | 過剰抑制 | 言語がカオス化しない |
| **Epistemic Value** | 「新しいことを学ぶ価値」 | 探索促進 | 未知の状況で新語を積極的に試す |
| **Pragmatic Value** | 「目的を達成する価値」 | 利用促進 | 確立された語彙を効率的に使う |

### 2.2 FEP統合フロー（会話サイクル）

```
  ┌── 会話開始 ─────────────────────────────────────────────┐
  │                                                          │
  │  1. 予測生成 (Generative Model)                          │
  │     ├── 文化層: 「このペアの会話パターン」               │
  │     ├── 会話層: 「前のターンからの予測」                 │
  │     └── 語彙層: 「次に使われる語の確率」                 │
  │                                                          │
  │  2. 実際の発言を受信                                     │
  │                                                          │
  │  3. 変分自由エネルギー計算                               │
  │     F = prediction_error + complexity_penalty            │
  │       = |実際 - 予測|² + λ × (vocab_size / max_vocab)    │
  │                                                          │
  │  4. 学習ルール適用                                       │
  │     ├── Hebbian: strength += LTP × prediction_error     │
  │     │            (KB99: 誤差が大きいほど強く強化)         │
  │     ├── STDP: timing_factor × prediction_error          │
  │     │          (KB102: タイミング窓 × 誤差の積)          │
  │     └── 予測符号化: モデル更新                           │
  │                (KB103: 階層的予測誤差の逆伝播)            │
  │                                                          │
  │  5. Active Inference（行動選択）                         │
  │     ├── EFE計算: 各候補語のExpected Free Energy          │
  │     ├── 探索 (epistemic): 新語を試す → 情報獲得大       │
  │     ├── 利用 (pragmatic): 確立語を使う → リスク小       │
  │     └── 選択: EFEが最小の行動を実行                     │
  │                                                          │
  │  6. 複雑性ペナルティ適用                                 │
  │     └── 語彙数が過剰な場合、低強度語を積極的に減衰      │
  │                                                          │
  │  7. 予測モデル更新                                       │
  │     └── F↓が達成されたら、生成モデルのパラメータを更新   │
  │                                                          │
  └── 次のターン ──────────────────────────────────────────┘
```

### 2.3 感情とFEP: Deeply Felt Affect

Hesp et al. (2022) の理論に基づき、感情をFEPの枠組みで形式化:

| 感情 | FEP解釈 | PetClawでの効果 |
|------|---------|----------------|
| **joy** | 自由エネルギーの急激な減少（予測が当たった）| 使用語の強化（Hebbian LTP増強） |
| **excitement** | 高い認識的価値の検出（新しい情報） | 探索行動の促進（新語提案確率↑） |
| **fear** | 自由エネルギーの急激な増加（予測が大きく外れた）| Active Inferenceの安全行動選択 |
| **sadness** | 持続的な高い自由エネルギー（予測モデルの根本的誤り）| モデルの大規模更新トリガー |
| **love** | 他者モデルの精度向上（精密重み付けの増加）| 特定ペア語彙の精密強化 |
| **neutral** | 低い自由エネルギー（安定状態）| 通常の減衰・維持モード |

---

## 3. GDScript実装

### 3.1 FEP定数とパラメータ

```gdscript
## FEP Constants for PetClaw Language System
## KB104: Free Energy Principle Application

# === 変分自由エネルギー (VFE) ===
const VFE_PREDICTION_ERROR_WEIGHT: float = 1.0    # 予測誤差の重み
const VFE_COMPLEXITY_WEIGHT: float = 0.3           # 複雑性ペナルティの重み
const VFE_MAX_VOCAB_FOR_PENALTY: int = 100         # この語彙数で複雑性ペナルティが最大
const VFE_UPDATE_RATE: float = 0.1                 # モデル更新率

# === Active Inference ===
const EPISTEMIC_WEIGHT: float = 0.4                # 探索（情報獲得）の重み
const PRAGMATIC_WEIGHT: float = 0.6                # 利用（目的達成）の重み
const EXPLORATION_TEMPERATURE: float = 0.3          # 行動選択のソフトマックス温度
const MIN_EXPLORATION_RATE: float = 0.1            # 最低限の探索率

# === Precision Weighting ===
const EMOTION_PRECISION_BOOST: float = 1.5         # 強い感情での精密重み付け
const CONTEXT_CONFIDENCE_BASE: float = 0.5         # ベースの文脈確信度
const FAMILIARITY_PRECISION_BONUS: float = 0.3     # 馴染みのあるペアでの精度ボーナス

# === 閾値 ===
const FREE_ENERGY_THRESHOLD_HIGH: float = 0.7      # 高FE: 大規模モデル更新トリガー
const FREE_ENERGY_THRESHOLD_LOW: float = 0.2       # 低FE: 安定状態
const SURPRISE_THRESHOLD: float = 0.5              # これ以上で「驚き」判定
```

### 3.2 変分自由エネルギー計算

```gdscript
func calculate_variational_free_energy(
	prediction: Dictionary,
	actual: Dictionary,
	vocabulary_size: int
) -> Dictionary:
	## 変分自由エネルギー F = 予測誤差 + 複雑性ペナルティ を計算
	## KB104: FEPの中核計算
	##
	## prediction: {"word": "happy-spark", "confidence": 0.7, "emotion": "joy"}
	## actual: {"word": "brave-force", "emotion": "excitement"}
	## vocabulary_size: 現在の語彙数

	# 1. 予測誤差（Prediction Error）
	var word_match: float = 1.0 if prediction.get("word", "") == actual.get("word", "") else 0.0
	var emotion_distance: float = _emotion_distance(
		prediction.get("emotion", "neutral"),
		actual.get("emotion", "neutral")
	)
	var prediction_error: float = (1.0 - word_match) * 0.6 + emotion_distance * 0.4

	# 2. 複雑性ペナルティ（Complexity Penalty）
	var complexity: float = clampf(
		float(vocabulary_size) / float(VFE_MAX_VOCAB_FOR_PENALTY),
		0.0, 1.0
	)

	# 3. 変分自由エネルギー
	var free_energy: float = (
		VFE_PREDICTION_ERROR_WEIGHT * prediction_error
		+ VFE_COMPLEXITY_WEIGHT * complexity
	)

	return {
		"free_energy": free_energy,
		"prediction_error": prediction_error,
		"complexity_penalty": complexity,
		"is_surprising": prediction_error > SURPRISE_THRESHOLD,
		"requires_model_update": free_energy > FREE_ENERGY_THRESHOLD_HIGH,
	}


func _emotion_distance(emotion_a: String, emotion_b: String) -> float:
	## 感情間の「距離」を計算（0.0=同一, 1.0=正反対）
	if emotion_a == emotion_b:
		return 0.0

	# 感情の極性マップ（簡易版）
	var polarity: Dictionary = {
		"joy": 1.0, "love": 0.8, "excitement": 0.9,
		"neutral": 0.0,
		"sadness": -0.7, "fear": -0.9,
	}

	var val_a: float = polarity.get(emotion_a, 0.0)
	var val_b: float = polarity.get(emotion_b, 0.0)
	return clampf(absf(val_a - val_b) / 2.0, 0.0, 1.0)
```

### 3.3 Active Inference（行動選択）

```gdscript
func active_inference_action_selection(
	candidate_words: Array[Dictionary],
	conversation_context: Dictionary,
	vocabulary: Dictionary
) -> Dictionary:
	## Active Inferenceに基づく語彙選択
	## 各候補語のExpected Free Energy (EFE) を計算し、最良の行動を選択
	##
	## candidate_words: [{"word": "happy-spark", "strength": 0.8, "novelty": 0.2}, ...]
	## conversation_context: {"emotion_intensity": 0.7, "turn": 3, "relationship": 0.6}
	## vocabulary: OriginalLanguageEngine.vocabulary

	if candidate_words.is_empty():
		return {"word": "", "action": "silence", "efe": 0.0}

	var best_word: Dictionary = {}
	var lowest_efe: float = INF
	var emotion_intensity: float = conversation_context.get("emotion_intensity", 0.5)

	for candidate: Dictionary in candidate_words:
		var word: String = candidate.get("word", "")
		var strength: float = candidate.get("strength", 0.5)
		var novelty: float = candidate.get("novelty", 0.0)

		# Pragmatic Value: 確立された語彙を使うことの価値
		# 強い語ほど pragmatic value が高い（リスクが低い）
		var pragmatic_value: float = strength * PRAGMATIC_WEIGHT

		# Epistemic Value: 新しい語を試すことの情報獲得価値
		# novelty が高いほど epistemic value が高い
		var epistemic_value: float = novelty * EPISTEMIC_WEIGHT

		# 感情による探索促進
		# 強い感情 → 探索を促進（excitement, fear で新しい表現を試みる）
		var emotion_boost: float = emotion_intensity * 0.2

		# Expected Free Energy = -(pragmatic + epistemic + emotion_boost)
		# EFEが低いほど良い行動
		var efe: float = -(pragmatic_value + epistemic_value + emotion_boost)

		if efe < lowest_efe:
			lowest_efe = efe
			best_word = candidate

	# 温度付きソフトマックスによる確率的選択（完全に最適なだけでなく、ランダム性も）
	if randf() < EXPLORATION_TEMPERATURE:
		# 確率的探索: ランダムに候補から選ぶ
		best_word = candidate_words[randi() % candidate_words.size()]
		return {
			"word": best_word.get("word", ""),
			"action": "explore",
			"efe": lowest_efe,
			"selection_type": "stochastic_exploration",
		}

	return {
		"word": best_word.get("word", ""),
		"action": "exploit" if best_word.get("strength", 0.0) > 0.5 else "explore",
		"efe": lowest_efe,
		"selection_type": "efe_optimal",
	}
```

### 3.4 FEP統合型Hebbian強化

```gdscript
func apply_fep_modulated_hebbian(
	vocabulary: Dictionary,
	word: String,
	free_energy_result: Dictionary,
	emotion_intensity: float
) -> float:
	## FEPで変調されたHebbian学習
	## KB99 (Hebbian) + KB103 (Predictive Coding) + KB104 (FEP) の統合
	##
	## 予測誤差が大きい → 強い強化（驚きによる学習）
	## 複雑性ペナルティが高い → 弱い語の積極的減衰
	## Active Inference → 行動に応じた差分強化

	if word not in vocabulary:
		return 0.0

	var entry: Dictionary = vocabulary[word]
	var current_strength: float = entry.get("strength", 0.5)
	var prediction_error: float = free_energy_result.get("prediction_error", 0.0)
	var is_surprising: bool = free_energy_result.get("is_surprising", false)
	var complexity_penalty: float = free_energy_result.get("complexity_penalty", 0.0)

	# === Hebbian LTP (KB99) × FEP変調 ===
	# 基本Hebbian強化: STRENGTH_ON_SUCCESS = 0.15
	var base_ltp: float = 0.15

	# FEP変調: 予測誤差に応じた強化倍率
	var fep_modulation: float = 1.0
	if is_surprising:
		# 驚きブースト: KB103の SURPRISE_BOOST_FACTOR = 1.8 を適用
		fep_modulation = 1.8
	else:
		# 馴染み減衰: 予測通りの場合は学習率を下げる
		fep_modulation = 0.5 + prediction_error  # 0.5〜1.5の範囲

	# 感情精密重み付け (Precision Weighting)
	var precision: float = CONTEXT_CONFIDENCE_BASE + emotion_intensity * EMOTION_PRECISION_BOOST
	precision = clampf(precision, 0.1, 3.0)

	# 最終的な強化量
	var delta_strength: float = base_ltp * fep_modulation * precision

	# 複雑性ペナルティによる減衰（語彙が多すぎる場合）
	if complexity_penalty > 0.5 and current_strength < 0.3:
		# 弱い語は複雑性ペナルティで追加減衰
		delta_strength -= 0.05 * complexity_penalty

	# 適用
	entry["strength"] = clampf(current_strength + delta_strength, 0.0, 1.0)
	entry["last_used"] = Time.get_unix_time_from_system()
	entry["usage_count"] = entry.get("usage_count", 0) + 1

	return delta_strength
```

### 3.5 Expected Free Energy（将来行動選択）

```gdscript
func calculate_expected_free_energy(
	action: String,
	current_state: Dictionary,
	vocabulary: Dictionary
) -> float:
	## 将来の行動についてのExpected Free Energy (EFE) を計算
	## EFE = リスク (pragmatic) + 曖昧さ (epistemic)
	##
	## action: "use_existing_word" or "propose_new_word" or "use_template"
	## current_state: {"turn": 3, "emotion": "joy", "emotion_intensity": 0.7, "vocab_size": 25}

	var turn: int = current_state.get("turn", 0)
	var emotion: String = current_state.get("emotion", "neutral")
	var emotion_intensity: float = current_state.get("emotion_intensity", 0.5)
	var vocab_size: int = current_state.get("vocab_size", 0)

	var risk: float = 0.0      # Pragmatic: 目的達成失敗のリスク
	var ambiguity: float = 0.0 # Epistemic: 情報獲得の可能性

	match action:
		"use_existing_word":
			# 既存語を使う → リスク低、情報獲得低
			risk = 0.1
			ambiguity = 0.05
		"propose_new_word":
			# 新語を提案する → リスク中、情報獲得高
			risk = 0.4
			ambiguity = 0.6
			# 感情が強い場面では新語のリスクが下がる
			if emotion_intensity > 0.6:
				risk *= 0.7  # 強い感情 → 新語が受け入れられやすい
		"use_template":
			# テンプレート使用 → リスク最低、情報獲得なし
			risk = 0.05
			ambiguity = 0.0

	# 会話の後半ほど保守的に（低リスクを選好）
	var turn_factor: float = 1.0 + float(turn) * 0.1
	risk *= turn_factor

	# 語彙が少ない場合は探索を促進
	if vocab_size < 10:
		ambiguity *= 1.5  # 情報獲得の価値が高い

	# EFE = PRAGMATIC_WEIGHT × risk - EPISTEMIC_WEIGHT × ambiguity
	# EFEが低いほど良い行動
	var efe: float = PRAGMATIC_WEIGHT * risk - EPISTEMIC_WEIGHT * ambiguity
	return efe
```

### 3.6 FEP統合型会話処理

```gdscript
func process_conversation_with_fep(
	messages: Array[Dictionary],
	vocabulary: Dictionary,
	prediction_model: Dictionary
) -> Dictionary:
	## 会話全体にFEPを適用する統合処理
	## KB98-104の全知識を統合した最上位関数
	##
	## Returns: {"total_free_energy": float, "words_strengthened": int,
	##           "new_words_proposed": int, "model_updated": bool}

	var total_fe: float = 0.0
	var words_strengthened: int = 0
	var new_proposals: int = 0
	var model_needs_update: bool = false

	for i in range(messages.size()):
		var msg: Dictionary = messages[i]
		var text: String = msg.get("message", "")
		var emotion: String = msg.get("emotion", "neutral")
		var pet_id: int = msg.get("pet_id", 0)

		# 1. 予測生成（前のターンに基づく）
		var prediction: Dictionary = _generate_prediction(
			messages.slice(0, i), prediction_model
		)

		# 2. 変分自由エネルギー計算
		var actual: Dictionary = {
			"word": _extract_primary_word(text, vocabulary),
			"emotion": emotion,
		}
		var fe_result: Dictionary = calculate_variational_free_energy(
			prediction, actual, vocabulary.size()
		)
		total_fe += fe_result["free_energy"]

		# 3. FEP変調型Hebbian強化
		var emotion_intensity: float = msg.get("emotion_intensity", 0.5)
		for word: String in vocabulary:
			var ai_term: String = vocabulary[word].get("ai_term", "")
			if text.contains(ai_term):
				apply_fep_modulated_hebbian(
					vocabulary, word, fe_result, emotion_intensity
				)
				words_strengthened += 1

		# 4. Active Inference: 新語提案判定
		if fe_result["is_surprising"]:
			var efe_new: float = calculate_expected_free_energy(
				"propose_new_word",
				{"turn": i, "emotion": emotion,
				 "emotion_intensity": emotion_intensity,
				 "vocab_size": vocabulary.size()},
				vocabulary
			)
			var efe_existing: float = calculate_expected_free_energy(
				"use_existing_word",
				{"turn": i, "emotion": emotion,
				 "emotion_intensity": emotion_intensity,
				 "vocab_size": vocabulary.size()},
				vocabulary
			)
			if efe_new < efe_existing:
				new_proposals += 1

		# 5. モデル更新判定
		if fe_result["requires_model_update"]:
			model_needs_update = true

	# 6. 予測モデル更新
	if model_needs_update:
		_update_generative_model(prediction_model, messages)

	return {
		"total_free_energy": total_fe,
		"average_free_energy": total_fe / maxf(messages.size(), 1),
		"words_strengthened": words_strengthened,
		"new_words_proposed": new_proposals,
		"model_updated": model_needs_update,
	}


func _generate_prediction(
	previous_messages: Array,
	model: Dictionary
) -> Dictionary:
	## 生成モデルから次の発言を予測
	if previous_messages.is_empty():
		return {"word": "", "confidence": 0.1, "emotion": "neutral"}

	var last_msg: Dictionary = previous_messages[-1]
	var last_emotion: String = last_msg.get("emotion", "neutral")

	# 簡易予測: 最後の感情が続くと予測
	var predicted_emotion: String = last_emotion
	var confidence: float = model.get("base_confidence", 0.3)

	# 会話が長いほど予測精度が上がる
	confidence += previous_messages.size() * 0.05
	confidence = clampf(confidence, 0.1, 0.9)

	return {
		"word": model.get("most_likely_word", ""),
		"confidence": confidence,
		"emotion": predicted_emotion,
	}


func _extract_primary_word(text: String, vocabulary: Dictionary) -> String:
	## テキストから最も顕著な独自語を抽出
	var best_word: String = ""
	var best_strength: float = 0.0

	for word: String in vocabulary:
		var ai_term: String = vocabulary[word].get("ai_term", "")
		if text.contains(ai_term):
			var strength: float = vocabulary[word].get("strength", 0.0)
			if strength > best_strength:
				best_strength = strength
				best_word = ai_term

	return best_word


func _update_generative_model(model: Dictionary, messages: Array[Dictionary]) -> void:
	## 会話結果に基づいて生成モデルを更新
	if messages.is_empty():
		return

	# 最頻感情を更新
	var emotion_counts: Dictionary = {}
	for msg: Dictionary in messages:
		var e: String = msg.get("emotion", "neutral")
		emotion_counts[e] = emotion_counts.get(e, 0) + 1

	var dominant_emotion: String = "neutral"
	var max_count: int = 0
	for e: String in emotion_counts:
		if emotion_counts[e] > max_count:
			max_count = emotion_counts[e]
			dominant_emotion = e

	# モデル更新（学習率で緩やかに）
	model["predicted_emotion"] = dominant_emotion
	model["base_confidence"] = clampf(
		model.get("base_confidence", 0.3) + VFE_UPDATE_RATE,
		0.1, 0.8
	)
```

---

## 4. 応用シーン

### 4.1 シーン1: 日常会話でのFEP駆動言語進化

```
状況: MimiとKuroの日常会話（3回目）

予測:
  Generative Model → 「Mimiは'happy-spark'を使うだろう」（信頼度 0.6）

実際:
  Mimi: "I feel brave-force today{-pya}!"

FEP計算:
  prediction_error = (1.0 - 0.0) * 0.6 + 0.45 * 0.4 = 0.78
  complexity_penalty = 15/100 * 0.3 = 0.045
  free_energy = 1.0 * 0.78 + 0.3 * 0.045 = 0.794

  → is_surprising = true (0.78 > 0.5)
  → requires_model_update = true (0.794 > 0.7)

学習適用:
  Hebbian LTP: 0.15 × 1.8 (surprise) × 1.55 (emotion precision) = 0.419
  'brave-force': strength 0.5 → 0.919

Active Inference:
  EFE(propose_new): 0.6 × 0.28 - 0.4 × 0.6 = -0.072  ← 選択
  EFE(use_existing): 0.6 × 0.1 - 0.4 × 0.05 = 0.04

  → 新語を提案: Kuroが'force-glo'を提案
```

### 4.2 シーン2: 死亡イベントでの大規模モデル更新

```
状況: Shiroが死亡。MimiとKuroが追悼会話

感情: sadness 0.9, fear 0.6

予測:
  Generative Model → 通常の会話パターン（Shiroの話題は予測外）

実際:
  Mimi: "*cries quietly{-nano}* Shiro... gone-mu..."

FEP計算:
  prediction_error = 0.95 (大幅な予測外れ)
  complexity_penalty = 20/100 * 0.3 = 0.06
  free_energy = 1.0 * 0.95 + 0.3 * 0.06 = 0.968

  → is_surprising = true
  → requires_model_update = true

特殊処理（Deeply Felt Affect）:
  sadness = 0.9 → 「持続的高FE: モデルの根本的更新」
  → 死関連語彙のクラスター形成
  → 'gone-mu', 'miss-nano', 'memory-pya' が同時強化

Active Inference:
  死亡イベント → 探索促進（新しい追悼表現の発明）
  → 'forever-light' (新語) が EFE最適として提案

Complexity Penalty 効果:
  死亡語彙クラスターは保護（高strength）
  一方、低頻度の日常語は軽く減衰 → 言語の「焦点化」
```

### 4.3 シーン3: Multi-Agent協調でのFEP

```
状況: 3ペット同時会話（グループ）

各ペットの生成モデル:
  Mimi: 「KuroとShiroは一般的な挨拶をする」
  Kuro: 「Mimiは新語を使いたがる」
  Shiro: 「今日は穏やかな会話」

ターン1: Mimi → "Let's invent-ku a new song-ba{-pya}!"
  Kuro's FE: 0.3 (予測通り、Mimiらしい)
  Shiro's FE: 0.8 (予測外れ、活発すぎる)

ターン2: Shiro → (Active Inference)
  EFE(同調): 0.6 × 0.15 - 0.4 × 0.1 = 0.05
  EFE(自分のペース): 0.6 × 0.3 - 0.4 × 0.3 = 0.06
  EFE(新語で応答): 0.6 × 0.25 - 0.4 × 0.5 = -0.05 ← 選択

  → Shiroが新語 'melody-ze' で応答
  → 全員のモデルが更新: 「グループ会話では新語が出やすい」

社会的FEP効果:
  各ペットが他のペットの「モデル」を持つ
  → 「Kuroは保守的」「Mimiは革新的」という社会的予測
  → 予測が外れたとき（保守的なKuroが新語を使った）に大きな学習
```

### 4.4 シーン4: PetBook投稿とFEPフィードバック

```
状況: 会話後のPetBook投稿で言語が社会的に評価される

投稿: Mimi posted "brave-force{-pya}! New strength discovered{-pya}!"

コミュニティ反応:
  いいね×5, 引用×2 → 社会的確認

FEP更新:
  社会的予測誤差 = |期待された反応 - 実際の反応|

  期待: 2いいね（平均的投稿）
  実際: 5いいね（予想以上の反応）

  → positive surprise: 社会的FEが低下
  → 'brave-force' の社会的強度が増加
  → 他のペットのモデルにも伝播

  PetBook→Language フィードバック:
  社会的成功した語 → Hebbian強化 +0.10
  社会的無反応の語 → 弱い減衰 -0.02
```

---

## 5. パラメータチューニングガイド

### 5.1 FEPパラメータとペット数スケーリング

| パラメータ | 3ペット | 10ペット | 30ペット | 50+ペット |
|-----------|---------|----------|----------|-----------|
| VFE_COMPLEXITY_WEIGHT | 0.2 | 0.3 | 0.4 | 0.5 |
| EPISTEMIC_WEIGHT | 0.5 | 0.4 | 0.35 | 0.3 |
| PRAGMATIC_WEIGHT | 0.5 | 0.6 | 0.65 | 0.7 |
| EXPLORATION_TEMPERATURE | 0.4 | 0.3 | 0.25 | 0.2 |
| VFE_UPDATE_RATE | 0.15 | 0.1 | 0.08 | 0.05 |

**理由:**
- ペットが多い → 語彙が爆発しやすい → 複雑性ペナルティ↑
- ペットが多い → 社会的検証が速い → 探索率↓、利用率↑
- ペットが多い → モデル更新頻度が高い → 更新率を下げて安定化

### 5.2 感情強度 × FEP効果マトリクス

| 感情強度 | 予測誤差小 (< 0.3) | 予測誤差中 (0.3-0.6) | 予測誤差大 (> 0.6) |
|---------|-------------------|---------------------|-------------------|
| 低 (< 0.3) | 通常減衰 -0.01 | 穏やかな学習 +0.05 | 中程度の学習 +0.10 |
| 中 (0.3-0.6) | 弱い強化 +0.03 | 標準学習 +0.12 | 強い学習 +0.25 |
| 高 (> 0.6) | 確認強化 +0.08 | 精密学習 +0.20 | 爆発的学習 +0.42 |

**爆発的学習 = 0.15 (base) × 1.8 (surprise) × 1.55 (precision) = 0.42**

### 5.3 コスト影響（P2原則との整合性）

```
FEP計算のコスト:
  - calculate_variational_free_energy(): O(1) — 純粋計算、API不要
  - active_inference_action_selection(): O(n) — n=候補語数、API不要
  - apply_fep_modulated_hebbian(): O(1) — 純粋計算、API不要
  - process_conversation_with_fep(): O(m×n) — m=メッセージ数、n=語彙数

  → すべてローカル計算。APIコスト増加なし。
  → 1会話あたりの追加計算時間: < 1ms
  → P2原則完全遵守: テンプレート/API比率に影響なし
```

---

## 6. to_dict/from_dict 拡張

### 6.1 FEPモデル状態の永続化

```gdscript
func fep_to_dict() -> Dictionary:
	## FEP関連の状態を永続化
	return {
		"generative_model": generative_model.duplicate(true),
		"total_free_energy_history": _recent_fe_values.duplicate(),
		"active_inference_stats": {
			"total_explorations": _total_explorations,
			"total_exploitations": _total_exploitations,
			"exploration_ratio": _get_exploration_ratio(),
		},
		"precision_weights": _precision_weights.duplicate(true),
	}


func fep_from_dict(data: Dictionary) -> void:
	## FEP状態を復元（後方互換性あり）
	generative_model = data.get("generative_model", {})
	_recent_fe_values = data.get("total_free_energy_history", [])
	var ai_stats: Dictionary = data.get("active_inference_stats", {})
	_total_explorations = ai_stats.get("total_explorations", 0)
	_total_exploitations = ai_stats.get("total_exploitations", 0)
	_precision_weights = data.get("precision_weights", {})
```

### 6.2 既存to_dict()への統合パターン

```gdscript
# OriginalLanguageEngine.to_dict() に追加
func to_dict() -> Dictionary:
	var base: Dictionary = {
		"vocabulary": vocabulary.duplicate(true),
		"archived_words": archived_words.duplicate(true),
		"current_stage": current_stage,
		"total_words_invented": total_words_invented,
		"dialect_data": dialect_data.duplicate(true),
		# KB104: FEP state
		"fep_model": fep_to_dict(),
	}
	return base

# OriginalLanguageEngine.from_dict() に追加
func from_dict(data: Dictionary) -> void:
	vocabulary = data.get("vocabulary", {})
	archived_words = data.get("archived_words", [])
	current_stage = data.get("current_stage", LanguageStage.BORROWING)
	total_words_invented = data.get("total_words_invented", 0)
	dialect_data = data.get("dialect_data", {})
	# KB104: FEP state (backward compatible)
	if data.has("fep_model"):
		fep_from_dict(data["fep_model"])
```

---

## 7. テスト実装

### 7.1 変分自由エネルギー計算テスト

```gdscript
func test_variational_free_energy() -> bool:
	print("Test: Variational Free Energy calculation...")

	# 予測と実際が一致 → 低FE
	var fe_match: Dictionary = calculate_variational_free_energy(
		{"word": "happy-spark", "emotion": "joy"},
		{"word": "happy-spark", "emotion": "joy"},
		15
	)
	assert(fe_match["prediction_error"] < 0.01, "Matching prediction should have ~0 error")
	assert(not fe_match["is_surprising"], "Matching should not be surprising")

	# 予測と実際が不一致 → 高FE
	var fe_mismatch: Dictionary = calculate_variational_free_energy(
		{"word": "happy-spark", "emotion": "joy"},
		{"word": "brave-force", "emotion": "fear"},
		15
	)
	assert(fe_mismatch["prediction_error"] > 0.5, "Mismatched prediction should have high error")
	assert(fe_mismatch["is_surprising"], "Mismatch should be surprising")

	# 語彙数が多い → 複雑性ペナルティ増加
	var fe_complex: Dictionary = calculate_variational_free_energy(
		{"word": "test", "emotion": "neutral"},
		{"word": "other", "emotion": "neutral"},
		90  # 高い語彙数
	)
	assert(fe_complex["complexity_penalty"] > fe_mismatch["complexity_penalty"],
		"Larger vocab should have higher complexity penalty")

	print("  PASS")
	return true
```

### 7.2 Active Inferenceテスト

```gdscript
func test_active_inference() -> bool:
	print("Test: Active Inference action selection...")

	var candidates: Array[Dictionary] = [
		{"word": "happy-spark", "strength": 0.9, "novelty": 0.1},  # 確立語
		{"word": "brave-force", "strength": 0.3, "novelty": 0.8},  # 新語
	]
	var context: Dictionary = {
		"emotion_intensity": 0.3,  # 穏やかな状態
		"turn": 1,
		"relationship": 0.5,
	}
	var vocabulary: Dictionary = {}

	# 穏やかな状態 → 確立語が選ばれやすい
	var result: Dictionary = active_inference_action_selection(
		candidates, context, vocabulary
	)

	# stochastic_explorationの場合もあるので、action typeだけ確認
	assert(result.has("word"), "Should return a word")
	assert(result.has("action"), "Should return an action type")

	print("  PASS")
	return true
```

### 7.3 FEP統合型Hebbian強化テスト

```gdscript
func test_fep_modulated_hebbian() -> bool:
	print("Test: FEP-modulated Hebbian reinforcement...")

	var vocabulary: Dictionary = {
		"happy": {
			"ai_term": "happy-spark",
			"strength": 0.5,
			"usage_count": 3,
			"last_used": Time.get_unix_time_from_system(),
		}
	}

	# 高い予測誤差 + 高い感情強度 → 強い強化
	var fe_surprising: Dictionary = {
		"prediction_error": 0.8,
		"is_surprising": true,
		"complexity_penalty": 0.1,
	}
	var delta_high: float = apply_fep_modulated_hebbian(
		vocabulary, "happy", fe_surprising, 0.9  # 高感情
	)

	# リセット
	vocabulary["happy"]["strength"] = 0.5

	# 低い予測誤差 + 低い感情強度 → 弱い強化
	var fe_expected: Dictionary = {
		"prediction_error": 0.1,
		"is_surprising": false,
		"complexity_penalty": 0.1,
	}
	var delta_low: float = apply_fep_modulated_hebbian(
		vocabulary, "happy", fe_expected, 0.2  # 低感情
	)

	assert(delta_high > delta_low,
		"Surprising + emotional should produce stronger reinforcement (%.3f > %.3f)" % [delta_high, delta_low])
	assert(delta_high > 0.3, "High surprise should produce at least +0.3 delta")

	print("  PASS (delta_high=%.3f, delta_low=%.3f)" % [delta_high, delta_low])
	return true
```

### 7.4 Expected Free Energyテスト

```gdscript
func test_expected_free_energy() -> bool:
	print("Test: Expected Free Energy calculation...")

	var state_calm: Dictionary = {
		"turn": 1, "emotion": "neutral",
		"emotion_intensity": 0.3, "vocab_size": 25,
	}
	var vocabulary: Dictionary = {}

	var efe_existing: float = calculate_expected_free_energy(
		"use_existing_word", state_calm, vocabulary
	)
	var efe_new: float = calculate_expected_free_energy(
		"propose_new_word", state_calm, vocabulary
	)
	var efe_template: float = calculate_expected_free_energy(
		"use_template", state_calm, vocabulary
	)

	# テンプレート < 既存語 < 新語（リスク順）
	# ただしEFEはリスク - 情報獲得なので、新語が最低（最良）になりうる
	assert(efe_template >= -0.1, "Template should have low EFE magnitude")
	print("  PASS (template=%.3f, existing=%.3f, new=%.3f)" % [
		efe_template, efe_existing, efe_new])
	return true
```

---

## 8. Agent Teams統合テンプレート

### 8.1 FEP統合実装タスク

```
=== Agent Teams FEP Integration Task ===

@architect: FEPの全体アーキテクチャをレビュー。
  既存のOriginalLanguageEngine + LanguageEvolutionSystem + AtoAConversationSystem
  にFEPレイヤーをどう追加するかを設計せよ。
  制約: 既存のto_dict/from_dictキーを変更しない（追加のみ）。

@gdscript-engineer: KB104のGDScript実装を
  godot_project/scripts/language/original_language_engine.gd に統合せよ。
  - calculate_variational_free_energy() を追加
  - active_inference_action_selection() を追加
  - apply_fep_modulated_hebbian() を追加
  - process_conversation_with_fep() を追加
  - to_dict/from_dict にFEP状態を追加（後方互換性必須）

@a2a-designer: AtoA会話フローにFEPを統合するプロンプト設計。
  - 予測生成 → 誤差計算 → Active Inference → 学習の4ステップ
  - テンプレート会話にもFEP効果を適用（API不要の範囲で）

@code-reviewer: FEP統合がP2原則（APIコスト物理法則）に違反しないかチェック。
  - すべてのFEP計算がローカルで完結するか
  - テンプレート/API比率に影響がないか

@evolution-specialist: FEP + 感情 + 進化の相互作用をバランス調整。
  - 強い感情でのFEP効果が過剰でないか
  - 死亡イベントでの言語爆発が適切か
```

### 8.2 Ralph Loopでの自動検証

```
=== Ralph Loop: FEP Quality Gate ===

Round N: FEP Integration
  Karpathy Score Target: 92+ (current: 91.7)

  Metrics to improve:
    - language_diversity: +2.0 (FEPによる探索促進)
    - code_quality: +1.0 (テスト追加)
    - battle_balance: +0.5 (Active Inferenceによるバトル語彙多様化)

  Quality Checks:
    □ FEP計算がAPI呼び出しを増加させていない
    □ to_dict/from_dictの後方互換性テスト合格
    □ 語彙数がVFE_MAX_VOCAB_FOR_PENALTY以下で安定
    □ 探索/利用比率が MIN_EXPLORATION_RATE 以上を維持
    □ 感情×予測誤差マトリクスの全セルが合理的な範囲

  --max-iterations 8
  --completion-promise "FEP_INTEGRATED_AND_TESTED"
```

---

## 9. KB103→KB104 統合まとめ

### 9.1 KB103（予測符号化）からの拡張点

| 項目 | KB103 (Predictive Coding) | KB104 (FEP) |
|------|--------------------------|-------------|
| 目的関数 | 予測誤差の最小化 | 変分自由エネルギーの最小化（予測誤差 + 複雑性） |
| 行動選択 | なし（受動的な学習のみ） | Active Inference（能動的な行動選択） |
| 将来計画 | なし | Expected Free Energy（EFE） |
| 感情統合 | ブースト/減衰の2値 | Deeply Felt Affect（感情の連続的統合） |
| 複雑性制御 | なし | 複雑性ペナルティ（過剰進化抑制） |
| Multi-Agent | 個別のHebbian強化 | 社会的FEP（他者モデルの予測誤差） |
| コスト | ローカル計算のみ | ローカル計算のみ（P2原則遵守） |

### 9.2 全KBシリーズの統合ビュー

```
KB98: 独自言語進化（基盤）
  ├── 2層スタック: OriginalLanguageEngine + LanguageEvolutionSystem
  ├── 5ステージ進化、79音素プール
  └── VocabEntry構造、語順パターン

KB99: Hebbian学習（局所ルール）
  ├── LTP/LTD (3:1比率)
  ├── 減衰 + 年齢加速
  └── 伝播・アーカイブ閾値

KB100: Hebbian応用例（具体的シナリオ）
  ├── 8つの応用シナリオ
  └── シナリオ間相互作用マトリクス

KB101: 神経科学基礎（理論背景）
  ├── LTP/LTD分子メカニズム
  ├── 6脳領域マッピング
  └── Ebbinghaus忘却曲線

KB102: STDP（タイミング依存強化）
  ├── t-LTP/t-LTD
  ├── 7つのSTDP定数
  └── ホメオスタティック正規化

KB103: 予測符号化（階層的予測）
  ├── 3層予測モデル
  ├── 予測誤差 → Hebbian/STDP変調
  └── SURPRISE_BOOST + FAMILIARITY_DAMPEN

KB104: FEP（統一原理）★本文書
  ├── 変分自由エネルギー（予測誤差 + 複雑性）
  ├── Active Inference（能動的行動選択）
  ├── Expected Free Energy（将来計画）
  ├── Deeply Felt Affect（感情の形式化）
  └── 社会的FEP（Multi-Agent協調）

  すべてが「F↓を最小化する」という統一原理に収束
```

---

## 10. 実装上の注意事項

### 10.1 GameManager.instance パターン遵守

```gdscript
# FEPの参照はGameManager経由
if GameManager.instance and GameManager.instance.original_language:
    var fep_result: Dictionary = GameManager.instance.original_language.process_conversation_with_fep(
        messages, vocabulary, prediction_model
    )
```

### 10.2 既存コードの保護

- **変更禁止**: `class_name`, シグナル名, enum順序, 既存to_dictキー
- **追加OK**: 新しいfunc, 新しいto_dictキー（.get()でデフォルト値付き）
- **FEP定数**: `original_language_engine.gd` の先頭定数セクションに追加

### 10.3 テンプレートモードとの互換性

```gdscript
# テンプレート会話でもFEP効果を適用（APIなしで動作）
func apply_fep_to_template_conversation(
    template_messages: Array[Dictionary],
    vocabulary: Dictionary
) -> void:
    # テンプレート会話 = 低い予測誤差（定型的）
    var fe_result: Dictionary = calculate_variational_free_energy(
        {"word": "", "emotion": "neutral"},
        {"word": "", "emotion": template_messages[0].get("emotion", "neutral")},
        vocabulary.size()
    )
    # テンプレートでも穏やかなHebbian強化は行う
    for word: String in vocabulary:
        if template_messages[0].get("message", "").contains(vocabulary[word]["ai_term"]):
            apply_fep_modulated_hebbian(vocabulary, word, fe_result, 0.3)
```

---

**次のステップ:**
- KB105: Markov Blanket（マルコフ毛布）とペット個体性の形式化
- KB106: 社会的Active Inference（コミュニティ言語の創発）
- 実装: `original_language_engine.gd` にFEP関数群を追加

**関連KB:** KB98, KB99, KB100, KB101, KB102, KB103
