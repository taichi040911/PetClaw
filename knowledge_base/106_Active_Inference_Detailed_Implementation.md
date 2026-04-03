# KB106: Active Inference 詳細実装ガイド
## PetClaw AtoA独自言語進化 × Multi-Agent協調 × 生物模倣記憶向け
**Version:** 2026-04-03
**対象:** Claude Code / Claude Cowork / Agent Teams
**前提知識:** KB105 (AXIOM), KB104 (FEP), KB103 (予測符号化), KB102 (STDP), KB99 (Hebbian実装), KB98 (独自言語進化)

---

## 1. Active Inferenceの神経科学・情報理論的基礎

### 1.1 理論の位置づけと発展

| 年 | 研究者 | 理論/発見 | PetClawへの意義 |
|----|--------|---------|----------------|
| 2006 | Friston | Active Inference初期定式化 | 行動選択の理論的基盤 |
| 2009 | Friston et al. | Reinforcement Learning or Active Inference | DRLとの統合理論 |
| 2015 | Friston et al. | Active Inference and Epistemic Value | 探索行動の形式化 |
| 2017 | Parr & Friston | Working Memory, Attention, and Salience | 注意と作業記憶のActive Inference |
| 2019 | Da Costa et al. | Active Inference on Discrete State-Spaces | 離散空間での実装（ターンベースに最適） |
| 2020 | Sajid et al. | Active Inference: Demystified and Compared | 実装ガイド（pymdpライブラリ） |
| 2022 | Hesp et al. | Deeply Felt Affect | 感情のActive Inference形式化 |
| 2023 | Verses AI | AXIOM v1 | Active Inferenceの産業実装 |
| 2024 | Friston et al. | Shared Protentions | Multi-Agent Active Inference |
| 2025 | Verses AI | AXIOM v2 + Gameworld 10k | ロボティクス・ゲーム環境での実証 |
| 2026 | 多数 | Language Emergence via Active Inference | 言語創発研究への応用加速 |

### 1.2 Active Inferenceの数学的基礎

```
Active Inferenceの核心方程式:

  ═══════════════════════════════════════════════
  知覚（Perception）: 信念の更新
  ═══════════════════════════════════════════════

    q*(s) = argmin_q F(q, o)

    F = E_q[ln q(s) - ln p(o, s)]
      = KL[q(s) || p(s|o)] + (-ln p(o))

    → 信念 q(s) を更新して自由エネルギー F を最小化
    → PetClaw: 会話を聞いて「相手の意図」の信念を更新

  ═══════════════════════════════════════════════
  行動（Action）: 政策の選択
  ═══════════════════════════════════════════════

    π* = argmin_π G(π)

    G(π) = E_q(o,s|π) [ln q(s|π) - ln p(o, s)]
                                    ↑
                       Expected Free Energy (EFE)

    G(π) = -E_q(o|π) [H[q(s|o,π)]]  +  E_q(o|π) [KL[q(o|π) || p̃(o)]]
            ├── Epistemic value ──┤     ├── Pragmatic value ──────────┤
            (情報獲得: 不確実性↓)        (目的達成: 望ましい観測)

    → 政策 π* を選択してEFE G を最小化
    → PetClaw: 「新語を提案する」vs「既存語を使う」を選択

  ═══════════════════════════════════════════════
  学習（Learning）: モデルのパラメータ更新
  ═══════════════════════════════════════════════

    θ* = argmin_θ F(q, o; θ)

    → 生成モデルのパラメータ θ を更新
    → PetClaw: 語彙の強度、遷移プロトタイプ、因果リンクの更新
    → Hebbian/STDPがこの学習ルールの局所近似
```

### 1.3 Perception-Action Loop（知覚-行動ループ）

```
  ┌── 世界（PetClawゲーム世界） ──────────────────────────┐
  │                                                        │
  │   環境状態: ペット、天候、イベント、言語状態             │
  │                                                        │
  └──┬─────────────────────────────────────────────────┬──┘
     │ 観測 o                                          │ 行動 a
     │ (会話の聞き取り、                                │ (新語提案、
     │  イベント認識)                                   │  行動選択)
     ▼                                                 │
  ┌── エージェント（ペット脳） ──────────────────────────┐
  │                                                      │
  │  1. 知覚 (Perception)                                │
  │     ┌───────────────────────────────────┐           │
  │     │ 予測誤差 ε = o - g(s)              │           │
  │     │ → 信念更新: q(s) ← q(s) + κ·ε     │           │
  │     │ → Hebbian/STDP強化 (KB99/102)      │           │
  │     │ → 予測符号化 (KB103)               │           │
  │     └───────────────────────────────────┘           │
  │                                                      │
  │  2. 計画 (Planning)                                  │
  │     ┌───────────────────────────────────┐           │
  │     │ 各政策 π_i のEFE G(π_i) を計算     │           │
  │     │ → epistemic: 「何を学べるか？」     │           │
  │     │ → pragmatic: 「何を達成できるか？」 │           │
  │     │ → π* = argmin G (最良の行動選択)   │           │
  │     └───────────────────────────────────┘           │
  │                                                      │
  │  3. 行動 (Action)                                    │──→ 行動 a
  │     ┌───────────────────────────────────┐           │
  │     │ 選択した政策を実行                  │           │
  │     │ → 新語を提案 / 既存語を使用         │           │
  │     │ → 感情表現の選択                    │           │
  │     │ → 環境への働きかけ                  │           │
  │     └───────────────────────────────────┘           │
  │                                                      │
  │  4. 学習 (Learning)                                  │
  │     ┌───────────────────────────────────┐           │
  │     │ 結果を観測して生成モデルを更新       │           │
  │     │ → Hebbian LTP/LTD (KB99)           │           │
  │     │ → STDP タイミング強化 (KB102)       │           │
  │     │ → 予測モデルパラメータ更新 (KB103)   │           │
  │     │ → FEP: VFE最小化確認 (KB104)       │           │
  │     │ → AXIOM: プロトタイプ更新 (KB105)   │           │
  │     └───────────────────────────────────┘           │
  └──────────────────────────────────────────────────────┘
```

### 1.4 Hebbian/STDP/予測符号化との統合位置づけ

```
  Active Inference（全体フレームワーク）
  │
  ├── 知覚（Perception）
  │   ├── Predictive Coding (KB103): 階層的予測誤差の計算・伝播
  │   ├── Hebbian (KB99): 成功した予測 → 結合強化（LTP）
  │   └── STDP (KB102): タイミング依存の精密強化
  │
  ├── 行動（Action）
  │   ├── EFE計算: 各候補行動の期待自由エネルギー
  │   ├── Epistemic: 新しい情報を獲得する価値
  │   └── Pragmatic: 目的を達成する価値
  │
  └── 学習（Learning）
      ├── Hebbian/STDP: 局所的パラメータ更新
      ├── FEP (KB104): 全体の目的関数に対する勾配
      └── AXIOM (KB105): オブジェクト中心のモデル更新

  統合の鍵:
    Active Inference = 何をするか（行動選択）
    Predictive Coding = 何を知覚するか（信念更新）
    Hebbian/STDP = どう学ぶか（局所学習ルール）
    FEP = なぜそうするか（統一目的関数 F↓）
    AXIOM = どう世界を表現するか（オブジェクト中心）
```

---

## 2. PetClaw AtoAへのActive Inference実装

### 2.1 Active Inferenceコンポーネント → PetClawシステム対応

| AI概念 | PetClawコンポーネント | 実装先 | 役割 |
|--------|---------------------|--------|------|
| **Generative Model** | `GenerativeLanguageModel` | OriginalLanguageEngine内 | 会話の「次の言葉」を予測 |
| **Beliefs** | `PetBeliefState` | PetEntity拡張 | ペットの「世界の理解」を保持 |
| **Prediction Error** | `calculate_prediction_error()` | KB103実装 | 予測と実際のズレ |
| **EFE Calculator** | `EFECalculator` | 新クラス | 各行動の期待自由エネルギー |
| **Policy Selector** | `PolicySelector` | 新クラス | 最適行動の選択 |
| **Epistemic Drive** | 探索促進 | PolicySelector内 | 新語を試す動機 |
| **Pragmatic Drive** | 目的達成 | PolicySelector内 | 確立語を使う動機 |
| **Precision Weighting** | 感情×文脈 | KB104実装 | 重要情報への選択的注意 |
| **Shared Protentions** | `SharedProtentionModel` | AtoA拡張 | ペット間の共同予測 |

### 2.2 Active Inference会話フロー

```
  会話開始: Mimi ↔ Kuro
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ターン1: Mimiの番
  ──────────────────
  1. 知覚 (Perception)
     → Kuroの前の発言を受信
     → 予測誤差: 「Kuroがこんなに活発な表現を使うとは予想外」
     → 信念更新: 「Kuroは今日は元気」

  2. 計画 (Planning)
     → 政策候補:
       π1: "happy-spark{-pya}!" (既存語で応答)
         EFE = 0.6 × 0.1 - 0.4 × 0.05 = 0.04
       π2: "brave-force{-pya}!" (新語で応答)
         EFE = 0.6 × 0.3 - 0.4 × 0.6 = -0.06 ← 最小
       π3: テンプレート応答
         EFE = 0.6 × 0.05 - 0.4 × 0.0 = 0.03

     → π2を選択（EFE最小: 情報獲得の価値が高い）

  3. 行動 (Action)
     → "I feel brave-force{-pya} today!"

  4. 学習 (Learning)
     → Kuroの反応を待つ → 次のターンで評価

  ターン2: Kuroの番
  ──────────────────
  1. 知覚
     → Mimiが新語 "brave-force" を使った
     → 予測誤差: 0.75 (高い: 初めて聞く語)
     → 信念更新: 「Mimiは新しい表現を開拓中」

  2. 計画
     → π1: 新語を採用して使う → EFE = -0.08 (epistemic value高)
     → π2: 従来語で応答 → EFE = 0.02
     → π1を選択

  3. 行動
     → "Brave-force{-nano}! I like that word{-nano}!"

  4. 学習
     → "brave-force" が2者間で使用された
     → Hebbian LTP: +0.15 × 1.8 (surprise boost) = +0.27
     → STDP: Δt=1ターン → timing_factor=0.6
     → 因果記録: Mimi.propose → Kuro.adopt (rMM更新)
```

---

## 3. GDScript実装

### 3.1 定数とパラメータ

```gdscript
## Active Inference Constants for PetClaw Language System
## KB106: Active Inference Detailed Implementation

# === Expected Free Energy (EFE) ===
const EFE_EPISTEMIC_WEIGHT: float = 0.4       # 情報獲得（探索）の重み
const EFE_PRAGMATIC_WEIGHT: float = 0.6       # 目的達成（利用）の重み
const EFE_DISCOUNT_FACTOR: float = 0.9        # 将来報酬の割引率
const EFE_PLANNING_HORIZON: int = 3           # 先読みターン数

# === 政策選択 ===
const POLICY_SOFTMAX_TEMPERATURE: float = 0.5  # ソフトマックス温度（高い→探索的）
const MIN_POLICY_PROBABILITY: float = 0.05     # 最低政策選択確率
const MAX_CANDIDATE_POLICIES: int = 8          # 候補政策の最大数

# === 信念更新 ===
const BELIEF_UPDATE_RATE: float = 0.15         # 信念の更新率
const BELIEF_DECAY_RATE: float = 0.02          # 信念の自然減衰率
const PRIOR_CONFIDENCE: float = 0.3            # 事前信念の確信度

# === 精密重み付け (Precision) ===
const BASE_PRECISION: float = 0.5              # ベース精密度
const EMOTION_PRECISION_SCALE: float = 1.5     # 感情による精密度変調
const SOCIAL_PRECISION_BONUS: float = 0.2      # 社会的文脈での精密度ボーナス

# === Shared Protentions ===
const PROTENTION_WINDOW: int = 2               # 共同予測の先読みターン数
const PROTENTION_CONSENSUS_THRESHOLD: float = 0.6  # 合意閾値
```

### 3.2 PetBeliefState（ペットの信念状態）

```gdscript
## PetBeliefState — ペットエージェントの内部信念
## Active Inferenceの q(s) に対応
## KB106: Active Inference Detailed Implementation

class_name PetBeliefState
extends RefCounted

# === 信念の状態 ===
# 各キーは「信じている世界の状態」、値は確信度（0.0-1.0）
var beliefs: Dictionary = {}

# === 他者モデル（Theory of Mind） ===
# { pet_id: { "personality_estimate": {}, "emotion_estimate": "",
#              "language_style": "", "relationship_to_self": float } }
var other_models: Dictionary = {}

# === 予測キャッシュ ===
var last_prediction: Dictionary = {}
var prediction_history: Array[Dictionary] = []
const MAX_PREDICTION_HISTORY: int = 20


func update_belief(key: String, observed_value: Variant, precision: float = 0.5) -> void:
	## 観測に基づいて信念を更新（ベイズ更新の簡易版）
	##
	## key: 信念のキー（例: "kuro_emotion", "weather", "conversation_topic"）
	## observed_value: 観測された値
	## precision: 観測の精密度（信頼性）

	var current: Dictionary = beliefs.get(key, {
		"value": null,
		"confidence": PRIOR_CONFIDENCE,
		"last_updated": 0.0,
	})

	# ベイズ更新: 新しい信念 = 古い信念 × (1-rate) + 観測 × rate × precision
	var update_rate: float = BELIEF_UPDATE_RATE * precision
	current["value"] = observed_value
	current["confidence"] = clampf(
		current["confidence"] * (1.0 - update_rate) + precision * update_rate,
		0.0, 1.0
	)
	current["last_updated"] = Time.get_unix_time_from_system()

	beliefs[key] = current


func get_belief(key: String) -> Dictionary:
	## 信念を取得（存在しない場合はデフォルト）
	return beliefs.get(key, {
		"value": null,
		"confidence": 0.0,
		"last_updated": 0.0,
	})


func update_other_model(pet_id: int, observation: Dictionary) -> void:
	## 他のペットのモデルを更新（Theory of Mind）
	if pet_id not in other_models:
		other_models[pet_id] = {
			"personality_estimate": {},
			"emotion_estimate": "neutral",
			"language_style": "standard",
			"relationship_to_self": 0.5,
			"word_preferences": [],
		}

	var model: Dictionary = other_models[pet_id]
	if observation.has("emotion"):
		model["emotion_estimate"] = observation["emotion"]
	if observation.has("language_novelty"):
		# 新語を使う傾向を追跡
		model["language_style"] = "innovative" if observation["language_novelty"] > 0.5 else "conservative"
	if observation.has("word_used"):
		if model["word_preferences"].size() < 20:
			model["word_preferences"].append(observation["word_used"])
		else:
			model["word_preferences"].pop_front()
			model["word_preferences"].append(observation["word_used"])


func predict_other_action(pet_id: int) -> Dictionary:
	## 他のペットの次の行動を予測（信念ベース）
	if pet_id not in other_models:
		return {"predicted_action": "unknown", "confidence": 0.1}

	var model: Dictionary = other_models[pet_id]
	var predicted_action: String = "use_existing_word"
	var confidence: float = 0.3

	match model.get("language_style", "standard"):
		"innovative":
			predicted_action = "propose_new_word"
			confidence = 0.5
		"conservative":
			predicted_action = "use_existing_word"
			confidence = 0.6
		_:
			predicted_action = "use_existing_word"
			confidence = 0.3

	return {
		"predicted_action": predicted_action,
		"predicted_emotion": model.get("emotion_estimate", "neutral"),
		"confidence": confidence,
	}


func decay_beliefs(delta: float) -> void:
	## 信念の自然減衰（時間経過で確信度が下がる）
	var decay: float = BELIEF_DECAY_RATE * delta / 3600.0  # 1時間あたり
	for key: String in beliefs:
		beliefs[key]["confidence"] = maxf(
			beliefs[key]["confidence"] - decay, 0.0
		)


func to_dict() -> Dictionary:
	return {
		"beliefs": beliefs.duplicate(true),
		"other_models": other_models.duplicate(true),
		"prediction_history": prediction_history.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	beliefs = data.get("beliefs", {})
	other_models = data.get("other_models", {})
	prediction_history = data.get("prediction_history", [])
```

### 3.3 EFECalculator（期待自由エネルギー計算機）

```gdscript
## EFECalculator — Expected Free Energy の計算
## 各候補行動の「情報獲得価値」と「目的達成価値」を評価
## KB106: Active Inference Detailed Implementation

class_name EFECalculator
extends RefCounted


func calculate_efe(
	policy: Dictionary,
	belief_state: PetBeliefState,
	vocabulary: Dictionary,
	context: Dictionary
) -> float:
	## 単一政策のExpected Free Energyを計算
	##
	## policy: {"action": "propose_new_word", "target_word": "brave-force", ...}
	## belief_state: 現在のペットの信念
	## vocabulary: OriginalLanguageEngine.vocabulary
	## context: {"turn": 3, "emotion": "joy", "emotion_intensity": 0.7,
	##           "listener_id": 2, "conversation_length": 6}
	##
	## Returns: EFE値（低いほど良い政策）

	var action: String = policy.get("action", "")
	var turn: int = context.get("turn", 0)
	var emotion_intensity: float = context.get("emotion_intensity", 0.5)
	var listener_id: int = context.get("listener_id", -1)

	# === Epistemic Value（情報獲得価値）===
	# 「この行動でどれだけ不確実性が減るか」
	var epistemic: float = _calculate_epistemic_value(
		action, belief_state, vocabulary, context
	)

	# === Pragmatic Value（目的達成価値）===
	# 「この行動でどれだけ望ましい状態に近づくか」
	var pragmatic: float = _calculate_pragmatic_value(
		action, belief_state, vocabulary, context
	)

	# === Precision Weighting ===
	var precision: float = BASE_PRECISION + emotion_intensity * EMOTION_PRECISION_SCALE
	if listener_id >= 0 and listener_id in belief_state.other_models:
		precision += SOCIAL_PRECISION_BONUS

	# === EFE = Pragmatic Risk - Epistemic Value ===
	# 低いEFE = 良い行動（リスクが低く、情報獲得が高い）
	var efe: float = EFE_PRAGMATIC_WEIGHT * pragmatic - EFE_EPISTEMIC_WEIGHT * epistemic

	# 将来の割引
	var discount: float = pow(EFE_DISCOUNT_FACTOR, float(turn))
	efe *= discount

	return efe


func _calculate_epistemic_value(
	action: String,
	belief_state: PetBeliefState,
	vocabulary: Dictionary,
	context: Dictionary
) -> float:
	## 情報獲得の価値を計算
	## 「この行動で新しいことを学べるか？」

	match action:
		"propose_new_word":
			# 新語提案: 高い情報獲得（リスナーの反応を学べる）
			var vocab_size: int = vocabulary.size()
			var novelty_bonus: float = 1.0 - clampf(float(vocab_size) / 50.0, 0.0, 0.8)
			# 語彙が少ないほど新語の価値が高い
			return 0.6 + novelty_bonus * 0.3

		"use_rare_word":
			# レア語使用: 中程度の情報獲得（相手が知っているか確認）
			var word: String = context.get("target_word", "")
			var word_strength: float = vocabulary.get(word, {}).get("strength", 0.5)
			return 0.4 * (1.0 - word_strength)  # 弱い語ほど情報獲得が高い

		"use_established_word":
			# 確立語使用: 低い情報獲得（既知の情報）
			return 0.05

		"use_template":
			# テンプレート: 情報獲得なし
			return 0.0

		"ask_question":
			# 質問: 高い情報獲得（相手の状態を直接学べる）
			return 0.7

		"express_emotion":
			# 感情表現: 中程度の情報獲得（相手の共感反応を学べる）
			return 0.3

		_:
			return 0.1


func _calculate_pragmatic_value(
	action: String,
	belief_state: PetBeliefState,
	vocabulary: Dictionary,
	context: Dictionary
) -> float:
	## 目的達成のリスクを計算（高い値 = 高いリスク）
	## 「この行動でコミュニケーションが失敗するリスクは？」

	var listener_id: int = context.get("listener_id", -1)
	var listener_model: Dictionary = belief_state.other_models.get(listener_id, {})
	var listener_style: String = listener_model.get("language_style", "standard")

	match action:
		"propose_new_word":
			# 新語提案: リスクは相手の保守性に依存
			var base_risk: float = 0.3
			if listener_style == "conservative":
				base_risk = 0.5  # 保守的な相手にはリスク高
			elif listener_style == "innovative":
				base_risk = 0.15  # 革新的な相手にはリスク低
			# 会話後半ではリスク上昇（まとめフェーズ）
			var turn: int = context.get("turn", 0)
			var conv_length: int = context.get("conversation_length", 6)
			if turn > conv_length * 0.7:
				base_risk *= 1.5
			return base_risk

		"use_rare_word":
			# レア語: 相手が知らない可能性
			return 0.25

		"use_established_word":
			# 確立語: 低リスク
			return 0.1

		"use_template":
			# テンプレート: 最低リスク
			return 0.05

		"ask_question":
			# 質問: 低リスク（自然な行動）
			return 0.1

		"express_emotion":
			# 感情表現: 感情強度に依存
			var emotion_intensity: float = context.get("emotion_intensity", 0.5)
			return 0.15 * emotion_intensity  # 強い感情ほどリスク

		_:
			return 0.2


func rank_policies(
	candidate_policies: Array[Dictionary],
	belief_state: PetBeliefState,
	vocabulary: Dictionary,
	context: Dictionary
) -> Array[Dictionary]:
	## 候補政策をEFE順にランキング
	## Returns: EFE付きの政策リスト（低い順 = 良い順）

	var ranked: Array[Dictionary] = []

	for policy: Dictionary in candidate_policies:
		var efe: float = calculate_efe(policy, belief_state, vocabulary, context)
		var ranked_policy: Dictionary = policy.duplicate()
		ranked_policy["efe"] = efe
		ranked.append(ranked_policy)

	# EFEが低い順にソート
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["efe"] < b["efe"]
	)

	return ranked
```

### 3.4 PolicySelector（政策選択器）

```gdscript
## PolicySelector — Active Inferenceの行動選択
## EFEに基づきソフトマックス確率で政策を選択
## KB106: Active Inference Detailed Implementation

class_name PolicySelector
extends RefCounted

var efe_calculator: EFECalculator
var _selection_history: Array[Dictionary] = []


func _init() -> void:
	efe_calculator = EFECalculator.new()


func select_policy(
	belief_state: PetBeliefState,
	vocabulary: Dictionary,
	context: Dictionary
) -> Dictionary:
	## 最適な政策を選択する（Active Inference のπ*選択）
	##
	## Returns: {"action": String, "target_word": String, "efe": float,
	##           "selection_type": String, "probabilities": Dictionary}

	# 1. 候補政策の生成
	var candidates: Array[Dictionary] = _generate_candidate_policies(
		vocabulary, context
	)

	if candidates.is_empty():
		return {"action": "use_template", "efe": 0.0, "selection_type": "fallback"}

	# 2. EFEでランキング
	var ranked: Array[Dictionary] = efe_calculator.rank_policies(
		candidates, belief_state, vocabulary, context
	)

	# 3. ソフトマックス確率に変換
	var probabilities: Array[float] = _softmax_probabilities(ranked)

	# 4. 確率的選択
	var selected_idx: int = _sample_from_distribution(probabilities)
	var selected: Dictionary = ranked[selected_idx]

	# 5. 選択履歴に記録
	_selection_history.append({
		"action": selected.get("action", ""),
		"efe": selected.get("efe", 0.0),
		"turn": context.get("turn", 0),
		"timestamp": Time.get_unix_time_from_system(),
	})
	if _selection_history.size() > 50:
		_selection_history.pop_front()

	selected["selection_type"] = "softmax"
	selected["probabilities"] = {}
	for i in ranked.size():
		ranked[i]["probability"] = probabilities[i]
		if i < 3:  # 上位3つだけ記録
			selected["probabilities"][ranked[i].get("action", "")] = probabilities[i]

	return selected


func _generate_candidate_policies(
	vocabulary: Dictionary,
	context: Dictionary
) -> Array[Dictionary]:
	## 候補政策を生成

	var candidates: Array[Dictionary] = []
	var emotion: String = context.get("emotion", "neutral")
	var emotion_intensity: float = context.get("emotion_intensity", 0.5)

	# 政策1: テンプレート使用（常に候補に含む: 安全策）
	candidates.append({"action": "use_template"})

	# 政策2: 確立語を使用（強い語から選択）
	var strong_words: Array[String] = []
	for word: String in vocabulary:
		if vocabulary[word].get("strength", 0.0) > 0.6:
			strong_words.append(word)

	if not strong_words.is_empty():
		var selected_word: String = strong_words[randi() % strong_words.size()]
		candidates.append({
			"action": "use_established_word",
			"target_word": selected_word,
		})

	# 政策3: レア語を使用（弱い語を試す）
	var rare_words: Array[String] = []
	for word: String in vocabulary:
		var strength: float = vocabulary[word].get("strength", 0.0)
		if strength > 0.2 and strength < 0.5:
			rare_words.append(word)

	if not rare_words.is_empty():
		var rare_word: String = rare_words[randi() % rare_words.size()]
		candidates.append({
			"action": "use_rare_word",
			"target_word": rare_word,
		})

	# 政策4: 新語提案（感情が強い場合により候補に入りやすい）
	if emotion_intensity > 0.3 or vocabulary.size() < 10:
		candidates.append({
			"action": "propose_new_word",
			"target_emotion": emotion,
		})

	# 政策5: 感情表現
	if emotion_intensity > 0.5:
		candidates.append({
			"action": "express_emotion",
			"target_emotion": emotion,
		})

	# 政策6: 質問（会話の前半で有効）
	var turn: int = context.get("turn", 0)
	if turn < 3:
		candidates.append({"action": "ask_question"})

	# 最大数に制限
	if candidates.size() > MAX_CANDIDATE_POLICIES:
		candidates = candidates.slice(0, MAX_CANDIDATE_POLICIES)

	return candidates


func _softmax_probabilities(ranked_policies: Array[Dictionary]) -> Array[float]:
	## EFE値をソフトマックス確率に変換
	## σ(π_i) = exp(-G_i / τ) / Σ exp(-G_j / τ)

	var probs: Array[float] = []
	var exp_values: Array[float] = []
	var max_neg_efe: float = -INF

	# 数値安定性のためmax値を事前計算
	for policy: Dictionary in ranked_policies:
		var neg_efe: float = -policy.get("efe", 0.0) / POLICY_SOFTMAX_TEMPERATURE
		if neg_efe > max_neg_efe:
			max_neg_efe = neg_efe

	var sum_exp: float = 0.0
	for policy: Dictionary in ranked_policies:
		var neg_efe: float = -policy.get("efe", 0.0) / POLICY_SOFTMAX_TEMPERATURE
		var exp_val: float = exp(neg_efe - max_neg_efe)  # 安定化
		exp_values.append(exp_val)
		sum_exp += exp_val

	for exp_val: float in exp_values:
		var prob: float = exp_val / maxf(sum_exp, 0.0001)
		prob = maxf(prob, MIN_POLICY_PROBABILITY)
		probs.append(prob)

	# 正規化
	var total: float = 0.0
	for p: float in probs:
		total += p
	for i in probs.size():
		probs[i] /= maxf(total, 0.0001)

	return probs


func _sample_from_distribution(probabilities: Array[float]) -> int:
	## 確率分布からサンプリング
	var r: float = randf()
	var cumulative: float = 0.0
	for i in probabilities.size():
		cumulative += probabilities[i]
		if r <= cumulative:
			return i
	return probabilities.size() - 1  # 浮動小数点誤差対策


func get_exploration_ratio() -> float:
	## 最近の探索率を計算
	if _selection_history.is_empty():
		return 0.5
	var explore_count: int = 0
	var recent: Array[Dictionary] = _selection_history.slice(-20)
	for entry: Dictionary in recent:
		if entry.get("action", "") in ["propose_new_word", "use_rare_word", "ask_question"]:
			explore_count += 1
	return float(explore_count) / float(recent.size())


func to_dict() -> Dictionary:
	return {"selection_history": _selection_history.duplicate(true)}


func from_dict(data: Dictionary) -> void:
	_selection_history = data.get("selection_history", [])
```

### 3.5 SharedProtentionModel（共同予測モデル）

```gdscript
## SharedProtentionModel — Multi-Agent Active Inferenceの共同予測
## Friston et al. (2024) "Shared Protentions" のPetClaw実装
## ペット間で「未来の予測」を共有し、言語の協調的進化を促進
## KB106: Active Inference Detailed Implementation

class_name SharedProtentionModel
extends RefCounted

# === 共同予測の状態 ===
# { "conversation_id": { participants, shared_predictions, consensus_level, history } }
var active_protentions: Dictionary = {}


func create_protention(
	conversation_id: int,
	participant_ids: Array[int]
) -> void:
	## 新しい共同予測セッションを開始
	active_protentions[conversation_id] = {
		"participants": participant_ids.duplicate(),
		"shared_predictions": {},
		"consensus_level": 0.0,
		"turn_predictions": [],
		"created_at": Time.get_unix_time_from_system(),
	}


func submit_prediction(
	conversation_id: int,
	pet_id: int,
	prediction: Dictionary
) -> void:
	## 個別ペットの予測を提出
	## prediction: {"next_emotion": "joy", "next_word": "happy-spark",
	##              "conversation_direction": "deepening", "confidence": 0.6}
	if conversation_id not in active_protentions:
		return

	active_protentions[conversation_id]["shared_predictions"][pet_id] = {
		"prediction": prediction,
		"submitted_at": Time.get_unix_time_from_system(),
	}

	# 全員の予測が揃ったらコンセンサス計算
	var protention: Dictionary = active_protentions[conversation_id]
	if protention["shared_predictions"].size() == protention["participants"].size():
		_calculate_consensus(conversation_id)


func _calculate_consensus(conversation_id: int) -> void:
	## 参加者の予測間のコンセンサスレベルを計算
	var protention: Dictionary = active_protentions[conversation_id]
	var predictions: Dictionary = protention["shared_predictions"]

	if predictions.size() < 2:
		protention["consensus_level"] = 1.0  # 1人なら完全合意
		return

	# 感情予測の一致度
	var emotion_predictions: Array[String] = []
	for pid: int in predictions:
		var pred: Dictionary = predictions[pid].get("prediction", {})
		emotion_predictions.append(pred.get("next_emotion", "neutral"))

	var emotion_agreement: float = 0.0
	var pairs: int = 0
	for i in range(emotion_predictions.size()):
		for j in range(i + 1, emotion_predictions.size()):
			pairs += 1
			if emotion_predictions[i] == emotion_predictions[j]:
				emotion_agreement += 1.0
	emotion_agreement /= maxf(float(pairs), 1.0)

	# 方向予測の一致度
	var direction_predictions: Array[String] = []
	for pid: int in predictions:
		var pred: Dictionary = predictions[pid].get("prediction", {})
		direction_predictions.append(pred.get("conversation_direction", ""))

	var direction_agreement: float = 0.0
	pairs = 0
	for i in range(direction_predictions.size()):
		for j in range(i + 1, direction_predictions.size()):
			pairs += 1
			if direction_predictions[i] == direction_predictions[j]:
				direction_agreement += 1.0
	direction_agreement /= maxf(float(pairs), 1.0)

	protention["consensus_level"] = emotion_agreement * 0.5 + direction_agreement * 0.5

	# 履歴に記録
	protention["turn_predictions"].append({
		"consensus": protention["consensus_level"],
		"predictions": predictions.duplicate(true),
	})


func get_consensus(conversation_id: int) -> Dictionary:
	## 現在のコンセンサス状態を取得
	if conversation_id not in active_protentions:
		return {"consensus_level": 0.0, "exists": false}

	var protention: Dictionary = active_protentions[conversation_id]
	return {
		"consensus_level": protention["consensus_level"],
		"participant_count": protention["participants"].size(),
		"predictions_submitted": protention["shared_predictions"].size(),
		"exists": true,
	}


func get_surprise_from_protention(
	conversation_id: int,
	actual_outcome: Dictionary
) -> float:
	## 共同予測と実際の結果のズレ（集団的驚き）を計算
	## 高い値 = コミュニティにとって予想外 → 強い学習トリガー
	if conversation_id not in active_protentions:
		return 0.5

	var protention: Dictionary = active_protentions[conversation_id]
	var predictions: Dictionary = protention["shared_predictions"]

	if predictions.is_empty():
		return 0.5

	var total_surprise: float = 0.0
	var count: int = 0

	for pid: int in predictions:
		var pred: Dictionary = predictions[pid].get("prediction", {})
		var emotion_match: float = 1.0 if pred.get("next_emotion", "") == actual_outcome.get("emotion", "") else 0.0
		var word_match: float = 1.0 if pred.get("next_word", "") == actual_outcome.get("word", "") else 0.0

		var individual_surprise: float = 1.0 - (emotion_match * 0.4 + word_match * 0.6)
		total_surprise += individual_surprise
		count += 1

	return total_surprise / maxf(float(count), 1.0)


func close_protention(conversation_id: int) -> void:
	## 共同予測セッションを終了
	active_protentions.erase(conversation_id)


func to_dict() -> Dictionary:
	return {"active_protentions": active_protentions.duplicate(true)}


func from_dict(data: Dictionary) -> void:
	active_protentions = data.get("active_protentions", {})
```

### 3.6 ActiveInferenceCore（統合コントローラー）

```gdscript
## ActiveInferenceCore — Active Inferenceの統合制御
## Perception → Planning → Action → Learning のループを管理
## KB106: Active Inference Detailed Implementation
## KB99-105の全知識を統合

class_name ActiveInferenceCore
extends RefCounted

var belief_states: Dictionary = {}  # { pet_id: PetBeliefState }
var policy_selector: PolicySelector
var shared_protention: SharedProtentionModel
var _conversation_counter: int = 0


func _init() -> void:
	policy_selector = PolicySelector.new()
	shared_protention = SharedProtentionModel.new()


func register_pet(pet_id: int) -> void:
	## ペットをActive Inferenceシステムに登録
	if pet_id not in belief_states:
		belief_states[pet_id] = PetBeliefState.new()


func process_perception(
	pet_id: int,
	observation: Dictionary
) -> Dictionary:
	## Step 1: 知覚 — 観測から信念を更新
	##
	## observation: {"message": "...", "speaker_id": 2, "emotion": "joy",
	##               "emotion_intensity": 0.7, "words_used": ["happy-spark"]}
	##
	## Returns: {"prediction_error": float, "belief_updates": int,
	##           "surprise_level": String}

	if pet_id not in belief_states:
		register_pet(pet_id)

	var belief: PetBeliefState = belief_states[pet_id]
	var speaker_id: int = observation.get("speaker_id", -1)
	var updates: int = 0

	# 感情の予測と更新
	var predicted_emotion: String = belief.predict_other_action(speaker_id).get("predicted_emotion", "neutral")
	var actual_emotion: String = observation.get("emotion", "neutral")
	var emotion_error: float = 0.0 if predicted_emotion == actual_emotion else 0.7

	# 信念更新
	var precision: float = BASE_PRECISION + observation.get("emotion_intensity", 0.5) * EMOTION_PRECISION_SCALE
	belief.update_belief(
		"speaker_%d_emotion" % speaker_id,
		actual_emotion,
		precision
	)
	updates += 1

	# 他者モデル更新
	belief.update_other_model(speaker_id, {
		"emotion": actual_emotion,
		"language_novelty": observation.get("language_novelty", 0.0),
		"word_used": observation.get("words_used", [""])[0] if not observation.get("words_used", []).is_empty() else "",
	})
	updates += 1

	# 語彙観測の信念更新
	for word: String in observation.get("words_used", []):
		belief.update_belief("word_%s_active" % word, true, 0.8)
		updates += 1

	# 予測誤差の集計
	var total_error: float = emotion_error * 0.6
	# 語彙の予測誤差
	var predicted_action: Dictionary = belief.predict_other_action(speaker_id)
	if predicted_action.get("predicted_action", "") == "propose_new_word":
		if observation.get("language_novelty", 0.0) < 0.3:
			total_error += 0.3  # 新語を予想したが使わなかった
	else:
		if observation.get("language_novelty", 0.0) > 0.7:
			total_error += 0.4  # 新語を予想しなかったが使った

	total_error = clampf(total_error, 0.0, 1.0)

	# 予測履歴に記録
	belief.prediction_history.append({
		"predicted": predicted_emotion,
		"actual": actual_emotion,
		"error": total_error,
		"turn": observation.get("turn", 0),
	})
	if belief.prediction_history.size() > PetBeliefState.MAX_PREDICTION_HISTORY:
		belief.prediction_history.pop_front()

	var surprise_level: String = "low"
	if total_error > 0.6:
		surprise_level = "high"
	elif total_error > 0.3:
		surprise_level = "medium"

	return {
		"prediction_error": total_error,
		"belief_updates": updates,
		"surprise_level": surprise_level,
	}


func process_planning(
	pet_id: int,
	vocabulary: Dictionary,
	context: Dictionary
) -> Dictionary:
	## Step 2: 計画 — EFEに基づき最適な政策を選択
	##
	## Returns: PolicySelectorの選択結果

	if pet_id not in belief_states:
		register_pet(pet_id)

	return policy_selector.select_policy(
		belief_states[pet_id],
		vocabulary,
		context
	)


func process_learning(
	pet_id: int,
	action_result: Dictionary,
	vocabulary: Dictionary
) -> Dictionary:
	## Step 4: 学習 — 行動結果からモデルを更新
	##
	## action_result: {"action_taken": "propose_new_word", "word": "brave-force",
	##                 "listener_reaction": "adopted", "emotion_response": "joy"}
	##
	## Returns: {"hebbian_delta": float, "model_updated": bool}

	if pet_id not in belief_states:
		return {"hebbian_delta": 0.0, "model_updated": false}

	var belief: PetBeliefState = belief_states[pet_id]
	var action: String = action_result.get("action_taken", "")
	var reaction: String = action_result.get("listener_reaction", "")

	# 行動の結果から学習
	var hebbian_delta: float = 0.0

	if action == "propose_new_word":
		if reaction == "adopted":
			# 新語が採用された → 強い正の学習
			hebbian_delta = 0.15 * 1.5  # Hebbian LTP × 成功ブースト
			# 信念更新: 「この文脈で新語提案は効果的」
			belief.update_belief("new_word_success_rate", 0.7, 0.8)
		elif reaction == "ignored":
			# 無視された → 弱い負の学習
			hebbian_delta = -0.05
			belief.update_belief("new_word_success_rate", 0.3, 0.5)

	elif action == "use_established_word":
		if reaction in ["positive", "adopted"]:
			hebbian_delta = 0.15  # 標準Hebbian LTP
		else:
			hebbian_delta = 0.05  # 弱い強化

	# 語彙への反映
	var word: String = action_result.get("word", "")
	if word in vocabulary and hebbian_delta != 0.0:
		vocabulary[word]["strength"] = clampf(
			vocabulary[word].get("strength", 0.5) + hebbian_delta,
			0.0, 1.0
		)
		if hebbian_delta > 0:
			vocabulary[word]["usage_count"] = vocabulary[word].get("usage_count", 0) + 1
			vocabulary[word]["last_used"] = Time.get_unix_time_from_system()

	return {
		"hebbian_delta": hebbian_delta,
		"model_updated": true,
		"action": action,
		"reaction": reaction,
	}


func run_full_cycle(
	pet_id: int,
	observation: Dictionary,
	vocabulary: Dictionary,
	context: Dictionary
) -> Dictionary:
	## Perception → Planning → Action → Learning の完全サイクル
	##
	## Returns: {"perception": Dict, "planning": Dict, "action": String,
	##           "learning": Dict}

	# 1. Perception
	var perception: Dictionary = process_perception(pet_id, observation)

	# 2. Planning（予測誤差をコンテキストに追加）
	var planning_context: Dictionary = context.duplicate()
	planning_context["prediction_error"] = perception["prediction_error"]
	planning_context["surprise_level"] = perception["surprise_level"]
	var planning: Dictionary = process_planning(pet_id, vocabulary, planning_context)

	# 3. Action（選択結果を返す — 実行は呼び出し元が行う）
	var action: String = planning.get("action", "use_template")

	return {
		"perception": perception,
		"planning": planning,
		"action": action,
		"selected_word": planning.get("target_word", ""),
		"efe": planning.get("efe", 0.0),
	}


func to_dict() -> Dictionary:
	var belief_data: Dictionary = {}
	for pid: int in belief_states:
		belief_data[pid] = belief_states[pid].to_dict()

	return {
		"belief_states": belief_data,
		"policy_selector": policy_selector.to_dict(),
		"shared_protention": shared_protention.to_dict(),
		"conversation_counter": _conversation_counter,
	}


func from_dict(data: Dictionary) -> void:
	var belief_data: Dictionary = data.get("belief_states", {})
	for pid_str: String in belief_data:
		var pid: int = int(pid_str) if pid_str.is_valid_int() else 0
		var bs: PetBeliefState = PetBeliefState.new()
		bs.from_dict(belief_data[pid_str])
		belief_states[pid] = bs

	if data.has("policy_selector"):
		policy_selector.from_dict(data["policy_selector"])
	if data.has("shared_protention"):
		shared_protention.from_dict(data["shared_protention"])
	_conversation_counter = data.get("conversation_counter", 0)
```

---

## 4. 応用シーン

### 4.1 シーン1: 探索と利用のトレードオフ（日常会話）

```
状況: Mimi (探索的) ↔ Kuro (保守的) の5回目の会話

Mimiの信念状態:
  other_models[Kuro] = {
    language_style: "conservative",
    emotion_estimate: "neutral",
    relationship_to_self: 0.6,
  }

Mimiの政策候補:
  π1: propose_new_word "dance-ku"
    epistemic = 0.6 + 0.3 × 0.7 = 0.81
    pragmatic_risk = 0.5 (Kuroは保守的)
    EFE = 0.6 × 0.5 - 0.4 × 0.81 = -0.024 ← 最小！

  π2: use_established_word "happy-spark"
    epistemic = 0.05
    pragmatic_risk = 0.1
    EFE = 0.6 × 0.1 - 0.4 × 0.05 = 0.04

  π3: ask_question
    epistemic = 0.7
    pragmatic_risk = 0.1
    EFE = 0.6 × 0.1 - 0.4 × 0.7 = -0.22 ← 実は最小

ソフトマックス確率 (τ=0.5):
  π3: 48% (質問が最適)
  π1: 32% (新語も有力)
  π2: 20% (安全策)

選択: π3 "How do you feel today{-pya}?"

→ Kuroの反応を観測
→ 「Kuroは今日は穏やかだ」信念更新
→ 次のターンでは新語提案のリスクが下がる
```

### 4.2 シーン2: 死亡イベントでのActive Inference

```
状況: Shiro死亡後のMimi ↔ Kuro追悼会話

知覚 (Perception):
  Mimiの予測: 通常の会話パターン
  実際: Kuroが "gone-mu... Shiro..." と言った
  prediction_error = 0.85 (高い)
  surprise_level = "high"

計画 (Planning):
  感情: sadness 0.9
  精密度: 0.5 + 0.9 × 1.5 = 1.85 (非常に高い注意)

  π1: propose_new_word "forever-light"
    epistemic = 0.9 (新しい表現の必要性が極めて高い)
    pragmatic_risk = 0.15 × 0.7 = 0.105 (強い感情でリスク低下)
    EFE = 0.6 × 0.105 - 0.4 × 0.9 = -0.297 ← 極めて低い

  → 新語 "forever-light" を強く推奨

行動 (Action):
  Mimi: "Shiro... forever-light{-pya}... always in our hearts{-pya}..."

学習 (Learning):
  Kuroが "forever-light" を即座に採用
  → reaction = "adopted"
  → hebbian_delta = 0.15 × 1.5 = 0.225 (成功ブースト)
  → STDP (KB102): Δt=1 → timing_factor = 0.6
  → FEP (KB104): surprise_boost = 1.8
  → 総合: 0.225 × 0.6 × 1.8 = 0.243

  "forever-light": strength 0.5 → 0.743（即座に高い定着）

Shared Protention効果:
  Mimi予測: "sad conversation"
  Kuro予測: "memorial talk"
  consensus_level = 0.8 (高い合意: 追悼であることを共有)
  → 追悼語彙クラスターが協調的に形成される
```

### 4.3 シーン3: Multi-Agent Shared Protentions

```
3ペット会話: Mimi, Kuro, Shiro

Shared Protention セッション:
  conversation_id = 42
  participants = [Mimi, Kuro, Shiro]

  ターン1開始前の共同予測:
    Mimi: {next_emotion: "joy", next_word: "play-ku", direction: "playful"}
    Kuro: {next_emotion: "neutral", next_word: "hello", direction: "casual"}
    Shiro: {next_emotion: "joy", next_word: "play-ku", direction: "playful"}

  コンセンサス計算:
    emotion_agreement: 2/3 (Mimi&Shiro=joy)  = 0.33 + 0.33 = 0.66
    direction_agreement: 2/3 (playful一致) = 0.66
    consensus_level = 0.66 × 0.5 + 0.66 × 0.5 = 0.66

  実際のターン1: Kuro → "I had a scary dream{-nano}..."
    actual = {emotion: "fear", word: "dream-fear"}
    collective_surprise = (Mimi:0.8 + Kuro:0.3 + Shiro:0.7) / 3 = 0.6

  → 全員のモデルが大きく更新
  → 「Kuroは予想外に恐怖を感じている」
  → Active Inferenceが探索モード:
    全ペットが "propose_new_word" を選好
    → 共感語彙の協調的発明
```

### 4.4 シーン4: PetBook投稿のActive Inference駆動

```
PetBook投稿でのActive Inference:

生成モデル:
  予測: 「この投稿は3いいねぐらい」
  精密度: 投稿経験に基づく（10投稿以上 → 高精密度）

政策候補:
  π1: 通常テキスト投稿 → EFE = 0.02
  π2: 新語入り投稿 → EFE = -0.15 (epistemic value高)
  π3: 因果物語投稿 (AXIOM風) → EFE = -0.08

選択: π2 (新語入り投稿)

結果:
  いいね×7 (予想の2倍以上)
  → prediction_error = 0.6
  → 信念更新: 「新語入り投稿は人気」
  → 次回以降、新語入り投稿の pragmatic_risk が低下
  → 言語進化とPetBookが正のフィードバックループ
```

---

## 5. パラメータチューニングガイド

### 5.1 ペット数 × 性格タイプ別パラメータ

| パラメータ | 探索的ペット | 保守的ペット | 社交的ペット |
|-----------|------------|------------|------------|
| POLICY_SOFTMAX_TEMPERATURE | 0.7 | 0.3 | 0.5 |
| MIN_POLICY_PROBABILITY | 0.08 | 0.03 | 0.05 |
| BELIEF_UPDATE_RATE | 0.20 | 0.10 | 0.15 |
| PRIOR_CONFIDENCE | 0.2 | 0.5 | 0.3 |
| EMOTION_PRECISION_SCALE | 1.8 | 1.2 | 1.5 |

### 5.2 スケーリング表

| パラメータ | 3ペット | 10ペット | 30ペット | 50+ペット |
|-----------|---------|----------|----------|-----------|
| MAX_CANDIDATE_POLICIES | 6 | 8 | 8 | 6 |
| EFE_PLANNING_HORIZON | 3 | 3 | 2 | 2 |
| PROTENTION_WINDOW | 3 | 2 | 2 | 1 |
| MAX_PREDICTION_HISTORY | 30 | 20 | 15 | 10 |
| belief_states メモリ | ~5KB | ~20KB | ~60KB | ~100KB |

### 5.3 感情 × Active Inference効果マトリクス

| 感情状態 | 探索促進度 | リスク許容度 | 新語提案確率 | 学習率ブースト |
|---------|----------|------------|------------|-------------|
| joy (高) | ★★★ | ★★★★ | 45% | ×1.3 |
| excitement | ★★★★ | ★★★ | 55% | ×1.5 |
| love | ★★ | ★★★★★ | 30% | ×1.2 |
| neutral | ★★ | ★★★ | 20% | ×1.0 |
| sadness | ★★★★★ | ★★ | 60% | ×1.8 |
| fear | ★ | ★ | 10% | ×2.0 |

**解説:**
- **sadness**: 高い探索促進 + 高い学習率 = 悲しみが言語革新を駆動（追悼語彙の急速形成）
- **fear**: 低い探索だが最高の学習率 = 恐怖体験は深く刻まれる（安全語彙を強く強化）
- **excitement**: 高い探索 + 中程度のリスク = バランスの取れた革新

### 5.4 コスト分析（P2原則遵守）

```
Active Inference処理のコスト:

  process_perception():
    - 信念更新: O(1) per belief key
    - 他者モデル更新: O(1) per observation
    - 合計: < 0.1ms / ターン
    - API: 0呼び出し

  process_planning():
    - 候補生成: O(v) — v=語彙数（for word selection）
    - EFE計算: O(c) — c=候補政策数（最大8）
    - ソフトマックス: O(c)
    - 合計: < 0.5ms / ターン
    - API: 0呼び出し

  process_learning():
    - Hebbian更新: O(1)
    - 信念更新: O(1)
    - 合計: < 0.1ms / ターン
    - API: 0呼び出し

  SharedProtention:
    - submit_prediction: O(p) — p=参加者数
    - calculate_consensus: O(p²)
    - 合計: < 0.2ms / ターン
    - API: 0呼び出し

  1会話あたり合計: < 5ms（6ターン）
  APIコスト追加: $0.00
  P2原則: 完全遵守
```

---

## 6. to_dict/from_dict 拡張

### 6.1 既存システムへの統合パターン

```gdscript
# AtoAConversationSystem に Active Inference を追加する場合:

# 新しいメンバー変数
var _active_inference: ActiveInferenceCore

func _ready() -> void:
	# ... 既存の初期化 ...
	_active_inference = ActiveInferenceCore.new()

# to_dict() への追加
func to_dict() -> Dictionary:
	var base: Dictionary = {
		# ... 既存キー（変更禁止） ...
		"conversation_log": conversation_log.slice(-50),
		# KB106: Active Inference state
		"active_inference": _active_inference.to_dict() if _active_inference else {},
	}
	return base

# from_dict() への追加
func from_dict(data: Dictionary) -> void:
	# ... 既存のfrom_dict処理 ...
	# KB106: Active Inference (backward compatible)
	if data.has("active_inference") and _active_inference:
		_active_inference.from_dict(data["active_inference"])
```

---

## 7. テスト実装

### 7.1 PetBeliefStateテスト

```gdscript
func test_belief_state() -> bool:
	print("Test: PetBeliefState...")
	var belief: PetBeliefState = PetBeliefState.new()

	# 信念更新
	belief.update_belief("weather", "sunny", 0.8)
	var weather: Dictionary = belief.get_belief("weather")
	assert(weather["value"] == "sunny", "Belief value should be 'sunny'")
	assert(weather["confidence"] > 0.0, "Confidence should be positive")

	# 他者モデル
	belief.update_other_model(2, {
		"emotion": "joy",
		"language_novelty": 0.8,
	})
	var prediction: Dictionary = belief.predict_other_action(2)
	assert(prediction["predicted_action"] == "propose_new_word",
		"Innovative pet should predict new words")

	# Round-trip
	var saved: Dictionary = belief.to_dict()
	var restored: PetBeliefState = PetBeliefState.new()
	restored.from_dict(saved)
	assert(restored.beliefs.has("weather"), "Restored beliefs should have weather")
	assert(restored.other_models.has(2), "Restored should have other model")

	print("  PASS")
	return true
```

### 7.2 EFE計算テスト

```gdscript
func test_efe_calculator() -> bool:
	print("Test: EFECalculator...")
	var calc: EFECalculator = EFECalculator.new()
	var belief: PetBeliefState = PetBeliefState.new()
	belief.update_other_model(2, {"emotion": "neutral", "language_novelty": 0.3})

	var vocabulary: Dictionary = {
		"happy": {"strength": 0.8, "ai_term": "happy-spark"},
	}
	var context: Dictionary = {
		"turn": 2, "emotion": "joy", "emotion_intensity": 0.7,
		"listener_id": 2, "conversation_length": 6,
	}

	# 新語提案 vs 確立語
	var efe_new: float = calc.calculate_efe(
		{"action": "propose_new_word"}, belief, vocabulary, context
	)
	var efe_established: float = calc.calculate_efe(
		{"action": "use_established_word"}, belief, vocabulary, context
	)

	# 新語提案はepistemic valueが高いのでEFEが低い（良い）可能性
	assert(efe_new != efe_established, "Different actions should have different EFE")
	print("  PASS (new=%.3f, established=%.3f)" % [efe_new, efe_established])
	return true
```

### 7.3 PolicySelectorテスト

```gdscript
func test_policy_selector() -> bool:
	print("Test: PolicySelector...")
	var selector: PolicySelector = PolicySelector.new()
	var belief: PetBeliefState = PetBeliefState.new()
	var vocabulary: Dictionary = {
		"happy": {"strength": 0.8, "ai_term": "happy-spark"},
		"sad": {"strength": 0.3, "ai_term": "sad-mu"},
	}
	var context: Dictionary = {
		"turn": 1, "emotion": "joy", "emotion_intensity": 0.6,
		"listener_id": 2, "conversation_length": 6,
	}

	var result: Dictionary = selector.select_policy(belief, vocabulary, context)
	assert(result.has("action"), "Should return an action")
	assert(result.has("efe"), "Should return EFE value")
	assert(result.has("selection_type"), "Should indicate selection type")

	# 探索率チェック
	var ratio: float = selector.get_exploration_ratio()
	assert(ratio >= 0.0 and ratio <= 1.0, "Exploration ratio should be 0-1")

	# Round-trip
	var saved: Dictionary = selector.to_dict()
	var restored: PolicySelector = PolicySelector.new()
	restored.from_dict(saved)

	print("  PASS (action='%s', efe=%.3f)" % [result["action"], result["efe"]])
	return true
```

### 7.4 SharedProtentionテスト

```gdscript
func test_shared_protention() -> bool:
	print("Test: SharedProtentionModel...")
	var model: SharedProtentionModel = SharedProtentionModel.new()

	# セッション作成
	model.create_protention(1, [10, 20, 30])

	# 各ペットの予測を提出
	model.submit_prediction(1, 10, {
		"next_emotion": "joy", "next_word": "play-ku",
		"conversation_direction": "playful",
	})
	model.submit_prediction(1, 20, {
		"next_emotion": "joy", "next_word": "happy-spark",
		"conversation_direction": "playful",
	})
	model.submit_prediction(1, 30, {
		"next_emotion": "neutral", "next_word": "hello",
		"conversation_direction": "casual",
	})

	# コンセンサスチェック
	var consensus: Dictionary = model.get_consensus(1)
	assert(consensus["exists"] == true, "Protention should exist")
	assert(consensus["consensus_level"] > 0.0, "Should have some consensus")

	# 集団的驚き
	var surprise: float = model.get_surprise_from_protention(1, {
		"emotion": "fear", "word": "scary-thing",
	})
	assert(surprise > 0.5, "Unexpected outcome should cause high collective surprise")

	# Round-trip
	var saved: Dictionary = model.to_dict()
	var restored: SharedProtentionModel = SharedProtentionModel.new()
	restored.from_dict(saved)
	assert(restored.active_protentions.has(1), "Should restore protention session")

	print("  PASS (consensus=%.2f, surprise=%.2f)" % [
		consensus["consensus_level"], surprise])
	return true
```

### 7.5 ActiveInferenceCoreテスト

```gdscript
func test_active_inference_core() -> bool:
	print("Test: ActiveInferenceCore full cycle...")
	var core: ActiveInferenceCore = ActiveInferenceCore.new()
	core.register_pet(1)

	var vocabulary: Dictionary = {
		"happy": {"strength": 0.7, "ai_term": "happy-spark", "usage_count": 5,
			"last_used": Time.get_unix_time_from_system()},
	}

	# Full cycle
	var result: Dictionary = core.run_full_cycle(
		1,
		{  # observation
			"message": "hello happy-spark!",
			"speaker_id": 2,
			"emotion": "joy",
			"emotion_intensity": 0.6,
			"words_used": ["happy"],
			"language_novelty": 0.2,
			"turn": 1,
		},
		vocabulary,
		{  # context
			"turn": 2,
			"emotion": "joy",
			"emotion_intensity": 0.6,
			"listener_id": 2,
			"conversation_length": 6,
		}
	)

	assert(result.has("perception"), "Should return perception result")
	assert(result.has("planning"), "Should return planning result")
	assert(result.has("action"), "Should return selected action")
	assert(result["perception"]["prediction_error"] >= 0.0, "Error should be non-negative")

	# Learning
	var learn_result: Dictionary = core.process_learning(1, {
		"action_taken": result["action"],
		"word": result.get("selected_word", "happy"),
		"listener_reaction": "positive",
		"emotion_response": "joy",
	}, vocabulary)
	assert(learn_result["model_updated"] == true, "Model should be updated")

	# Round-trip
	var saved: Dictionary = core.to_dict()
	var restored: ActiveInferenceCore = ActiveInferenceCore.new()
	restored.from_dict(saved)
	assert(restored.belief_states.size() == core.belief_states.size())

	print("  PASS (action='%s', error=%.2f)" % [
		result["action"], result["perception"]["prediction_error"]])
	return true
```

---

## 8. Agent Teams統合テンプレート

### 8.1 Active Inference実装タスク

```
=== Agent Teams Active Inference Integration Task ===

@architect: Active Inferenceの5クラスをPetClawアーキテクチャに統合する設計。
  - PetBeliefState → PetEntity拡張 or 独立RefCounted
  - EFECalculator → PolicySelector → ActiveInferenceCore の依存関係
  - AtoAConversationSystem._build_turn_prompt() での政策反映
  - 制約: 既存class_name/signal/to_dictキー変更禁止

@gdscript-engineer: KB106の5クラスを実装:
  - pet_belief_state.gd (RefCounted)
  - efe_calculator.gd (RefCounted)
  - policy_selector.gd (RefCounted)
  - shared_protention_model.gd (RefCounted)
  - active_inference_core.gd (RefCounted)
  配置: godot_project/scripts/language/ ディレクトリ

@a2a-designer: Active Inference政策をAtoA会話テンプレートに反映する設計:
  - テンプレート選択にEFE値を考慮
  - 新語提案テンプレートの追加
  - 質問テンプレートの追加

@code-reviewer: 実装レビュー:
  - ソフトマックスの数値安定性
  - メモリ使用量が50ペット時に100KB以内か
  - P2原則（API 0呼び出し）遵守
  - 信念の減衰が適切な速度か

@evolution-specialist: Active Inferenceと進化システムの連携:
  - 進化イベントでの大きな予測誤差の処理
  - 進化形態ごとのPOLICY_SOFTMAX_TEMPERATUREの差別化
```

### 8.2 Ralph Loop自動検証

```
=== Ralph Loop: Active Inference Quality Gate ===

Round N: Active Inference Integration
  Karpathy Score Target: 93+ (current: 91.7)

  Metrics to improve:
    - language_diversity: +2.5 (EFE駆動の探索的言語選択)
    - code_quality: +1.0 (5新クラス + テスト)
    - atoa_quality: +1.0 (Active Inference駆動の自然な会話)

  Quality Checks:
    □ 全5クラスのto_dict/from_dict往復テスト合格
    □ ソフトマックスが数値オーバーフローしない
    □ 探索率が MIN_EXPLORATION_RATE 以上を維持
    □ 50ペット時のメモリ < 100KB
    □ 1会話の処理時間 < 10ms
    □ API呼び出し追加なし（P2原則完全遵守）
    □ Shared Protentionのconsensus計算が正確

  --max-iterations 10
  --completion-promise "ACTIVE_INFERENCE_FULLY_INTEGRATED"
```

---

## 9. KB98-106 全シリーズ統合ビュー

```
KB98:  独自言語進化（基盤）     — 2層スタック、5ステージ
KB99:  Hebbian学習（局所ルール） — LTP/LTD、伝播閾値
KB100: 応用例（8シナリオ）      — 具体的な適用パターン
KB101: 神経科学基礎             — 分子メカニズム、脳マッピング
KB102: STDP（タイミング依存）   — t-LTP/t-LTD、正規化
KB103: 予測符号化（階層的予測） — 3層モデル、誤差変調
KB104: FEP（統一原理）          — VFE、Active Inference概要
KB105: AXIOM（実装アーキテクチャ）— Object-centric、因果推論
KB106: Active Inference（詳細実装）★本文書
  ├── PetBeliefState: ペットの信念状態管理
  ├── EFECalculator: 期待自由エネルギー計算
  ├── PolicySelector: 確率的行動選択
  ├── SharedProtentionModel: Multi-Agent共同予測
  └── ActiveInferenceCore: Perception→Planning→Action→Learningループ

  完全な統合パス:
    世界の観測
      → AXIOM (KB105): Object-centric表現
      → Predictive Coding (KB103): 予測誤差計算
      → Active Inference (KB106): 行動選択
        → EFE: epistemic vs pragmatic
        → Shared Protention: 社会的協調
      → Hebbian (KB99) + STDP (KB102): 局所学習
      → FEP (KB104): VFE最小化確認
    → 次のサイクルへ
```

---

## 10. 実践Tips（非エンジニア向け）

### 10.1 開始規模

- **最初**: Orchestrator + 2-3ペットエージェントでテスト
- **中期**: 10ペットまでスケール、Shared Protentionを有効化
- **本番**: 30-50ペット、全パラメータチューニング済み

### 10.2 視覚フィードバック

```
予測誤差に応じたVFX:
  prediction_error < 0.3 → 穏やかな青い粒子（安定）
  prediction_error 0.3-0.6 → 黄色の粒子（注意）
  prediction_error > 0.6 → 赤い粒子（驚き！新語誕生の可能性）

Active Inferenceの探索:
  explore行動 → 虹色の粒子エフェクト
  exploit行動 → 緑色の安定エフェクト

Shared Protention:
  consensus > 0.7 → 参加者全員に「共鳴」の光
  consensus < 0.3 → 「混乱」のモヤモヤエフェクト
```

### 10.3 バランス調整のポイント

- **探索しすぎ**: POLICY_SOFTMAX_TEMPERATURE を下げる (0.5→0.3)
- **保守すぎ**: EFE_EPISTEMIC_WEIGHT を上げる (0.4→0.5)
- **新語が定着しない**: 成功時のhebbian_deltaを上げる (0.225→0.30)
- **言語がカオス**: VFE_COMPLEXITY_WEIGHT を上げる (0.3→0.5)

---

**次のステップ:**
- KB107: Markov Blanketとペット個体性の形式化
- KB108: 社会的Active Inference（コミュニティ言語の創発）
- 実装: 5つのActive Inferenceクラスを .gd ファイルとして作成

**関連KB:** KB98, KB99, KB100, KB101, KB102, KB103, KB104, KB105
