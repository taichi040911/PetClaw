# KB103: 予測符号化（Predictive Coding）とHebbian/STDPの統合ガイド
## Predictive Coding Integration with Hebbian/STDP for PetClaw Language Evolution
**Version:** 2026-04-03
**対象:** Claude Code / Claude Cowork / Agent Teams
**前提知識:** KB102 (STDP詳細), KB101 (神経科学基礎), KB99 (Hebbian実装), KB98 (独自言語進化)

---

## 1. 予測符号化の神経科学基礎

### 1.1 理論の起源と発展

| 年 | 研究者 | 理論/発見 | 意義 |
|----|--------|---------|------|
| 1860s | Helmholtz | 無意識的推論 | 知覚は脳の「推測」であるという着想 |
| 1999 | Rao & Ballard | 予測符号化モデル | 視覚皮質の階層的予測誤差の計算モデル |
| 2005 | Friston | 自由エネルギー原理 | 予測符号化の統一理論的枠組み |
| 2010 | Clark | 予測する脳 (*Surfing Uncertainty*) | 認知科学への普及 |
| 2017 | Keller & Mrsic-Flogel | 皮質の予測誤差ニューロン | 実験的検証（マウス視覚皮質） |
| 2023 | Halvagal & Zenke | Latent Predictive Learning (LPL) | Hebbian + 予測符号化の統合モデル |
| 2025-26 | 多数 | 言語モデルとの対応研究 | Transformerの注意機構と予測符号化の構造的類似性 |

### 1.2 基本原理: 脳は予測マシンである

```
    上位層（高次皮質）
    ┌──────────────────────┐
    │  内部モデル（世界の予測）│
    │  「次に何が起こるか」    │
    └──┬───────────────┬──┘
       │ top-down      │ 予測信号
       │ prediction    │ (μ: 予測値)
       ▼               │
    ┌──────────────────────┐
    │  比較器               │
    │  予測(μ) vs 実際(x)    │
    │  → 予測誤差(ε = x - μ) │
    └──┬───────────────┬──┘
       │ bottom-up     │ 誤差信号
       │ error         │ (ε: 予測誤差)
       ▼               │
    下位層（感覚入力）
    ┌──────────────────────┐
    │  実際の入力データ       │
    │  「何が実際に起こったか」 │
    └──────────────────────┘
```

**核心:**
- 脳は常に「次の入力」を予測している
- 予測が当たれば何もしない（効率的）
- 予測が外れれば誤差信号を上位に送り、モデルを更新（学習）
- **驚き（surprise）= 予測誤差の大きさ = 学習の原動力**

### 1.3 自由エネルギー原理（Free Energy Principle）

Fristonの自由エネルギー原理は、予測符号化を一般化した理論:

```
F = D_KL[q(θ) || p(θ|x)] + log p(x)

F: 変分自由エネルギー（最小化すべき量）
D_KL: KLダイバージェンス（内部モデルと真の事後分布の差）
p(x): データのエビデンス（サプライズの負の対数）

最小化の方法:
1. 知覚: 内部モデルq(θ)を更新して誤差を減らす（パーセプション）
2. 行動: 世界を変えて予測に合わせる（アクティブ推論）
```

**PetClawでの対応:**
- **知覚 → テンプレート更新**: 予測（テンプレート）を実際の会話パターンに合わせて調整
- **行動 → 言語変化**: 語順・接尾辞を変えて「予測しやすい」コミュニケーションに進化

### 1.4 Hebbian/STDPとの統合: なぜ両方必要か

| 側面 | Hebbian/STDP | 予測符号化 | 統合 |
|------|-------------|-----------|------|
| **スコープ** | 局所的（シナプス単位） | 大域的（ネットワーク全体） | 局所×大域の多層学習 |
| **駆動力** | 共活性化/タイミング | 予測誤差 | 誤差に導かれたタイミング学習 |
| **安定性** | 不安定（正のフィードバック） | 安定（誤差最小化が目標） | 自然に安定する創発的進化 |
| **創発性** | パターンの強化 | パターンの予測 | 予測を超える「驚き」が創発を駆動 |
| **生物学的** | シナプス前後の局所信号 | 層間のフィードバック | 皮質カラムの完全な学習モデル |

**Latent Predictive Learning (LPL, 2023):**
Halvagal & Zenkeが示したLPLは、Hebbian学習と予測符号化を単一のルールで統合:
```
ΔW ∝ (x_post - μ_post) × x_pre

x_post: ポストシナプスの実際の活動
μ_post: ポストシナプスの予測された活動
x_pre: プレシナプスの活動

→ 予測誤差(x - μ)がHebbianの重み付けとして作用
→ 予測通りなら学習なし、予測と異なるときのみ学習
```

---

## 2. PetClawへの統合アーキテクチャ

### 2.1 三層予測モデル

PetClawの既存システムを予測符号化の3層モデルに対応させる:

```
┌─────────────────────────────────────────────────────────┐
│ 層3: 長期予測（文化・伝統層）                               │
│ = CulturalEmergenceSystem                               │
│ 「このコミュニティではこういう言語が使われるはず」              │
│ 予測: 文化アーティファクトに基づく語彙・パターンの予測         │
│ 誤差: 新しいアーティファクト（予測外の文化的創発）             │
├─────────────────────────────────────────────────────────┤
│ 層2: 中期予測（会話文脈層）                                 │
│ = AtoAConversationSystem + LanguageEvolutionSystem       │
│ 「この会話の流れなら次はこう言うはず」                        │
│ 予測: テンプレート/語順/接尾辞パターンによる次ターンの予測     │
│ 誤差: テンプレートから逸脱した表現（新語・新構文の誕生）       │
├─────────────────────────────────────────────────────────┤
│ 層1: 短期予測（語彙層）                                    │
│ = OriginalLanguageEngine                                │
│ 「この文脈ならこの語が使われるはず」                          │
│ 予測: 既存vocabulary + strengthによる語彙の予測              │
│ 誤差: 未知語の出現 / 既知語の予想外の使用                    │
└─────────────────────────────────────────────────────────┘
```

### 2.2 予測誤差の計算

**層1（語彙層）の予測誤差:**
```
prediction_error_vocab = 予想外の語の出現度

計算方法:
1. 会話前: 現在の語彙から「使われそうな語」を予測
   → predicted_words = {w : strength > 0.3 のアクティブ語彙}
2. 会話後: 実際に使われた語を検出
   → actual_words = _extract_vocabulary_words(conversation)
3. 誤差 = 予測になかった語の数 / 全語数
   → error = |actual - predicted| / |actual ∪ predicted|
```

**層2（文脈層）の予測誤差:**
```
prediction_error_context = テンプレートからの逸脱度

計算方法:
1. テンプレート選択: trigger + 性格 + 感情 → 期待される会話パターン
2. 実際の会話: API応答 or テンプレート出力
3. 誤差 = テンプレートフォールバック時は低（予測通り）
         API応答時は高（予測外の内容を含む可能性）
```

**層3（文化層）の予測誤差:**
```
prediction_error_culture = 文化的規範からの逸脱度

計算方法:
1. 文化的規範: 既存のtradition/ritual/songに含まれるパターン
2. 実際の行動: ペットの会話・行動パターン
3. 誤差 = 既存文化に含まれないパターンの出現
   → 高誤差 = 新しいアーティファクト生成のトリガー
```

### 2.3 既存システムとの統合マップ

```
既存Hebbian (KB99):
  strengthen_word()   → 頻度ベースの強化（変更なし）
  _process_daily_decay() → 時間ベースの減衰（変更なし）

既存STDP (KB102):
  apply_stdp_to_conversation() → タイミングベースの強化（変更なし）

新規: 予測符号化
  calculate_prediction_error() → 誤差の計算（新規追加）
  modulate_hebbian_by_error()  → 誤差による強化量の変調（新規追加）
  update_prediction_model()    → 予測モデルの更新（新規追加）

統合フロー:
  会話発生
    ↓
  予測誤差を計算                    ← 新規
    ↓
  Hebbian強化量 × 誤差変調          ← 変調
    ↓
  STDP強化量 × 誤差変調             ← 変調
    ↓
  語彙・文法の更新
    ↓
  予測モデルの更新                  ← 新規
```

---

## 3. 実装設計

### 3.1 予測符号化の定数

```gdscript
# === Predictive Coding Constants ===
const PREDICTION_ERROR_THRESHOLD: float = 0.3   # 誤差がこれ以上で「驚き」とみなす
const SURPRISE_BOOST_FACTOR: float = 1.8         # 驚き時のHebbian/STDP強化倍率
const FAMILIARITY_DAMPEN: float = 0.5            # 予測通り時のHebbian/STDP減衰倍率
const PREDICTION_HISTORY_SIZE: int = 10           # 予測履歴の保持数
const PREDICTION_UPDATE_RATE: float = 0.1         # 予測モデルの更新率
const NEW_WORD_SURPRISE_BONUS: float = 0.15      # 完全に新しい語への追加ボーナス
```

**パラメータの根拠:**

| 定数 | 値 | 根拠 |
|------|-----|------|
| PREDICTION_ERROR_THRESHOLD = 0.3 | 30% | 予測の30%以上が外れると「驚き」。日常会話は低誤差 |
| SURPRISE_BOOST_FACTOR = 1.8 | 1.8倍 | 扁桃体の驚き反応による記憶強化は通常の1.5-2倍 |
| FAMILIARITY_DAMPEN = 0.5 | 50% | 予測通りの会話はHebbian強化を半減（既に学習済み） |
| PREDICTION_UPDATE_RATE = 0.1 | 10% | モデル更新は緩やか（急激な変化は不安定） |

### 3.2 予測誤差計算の実装

```gdscript
# OriginalLanguageEngine への追加

var _prediction_history: Array[Dictionary] = []  # 予測と結果の履歴
var _word_frequency_model: Dictionary = {}        # 語の出現頻度モデル（予測の基盤）


func calculate_prediction_error(conversation: Array[Dictionary]) -> float:
    ## 会話の予測誤差を計算（0.0 = 完全に予測通り, 1.0 = 完全に予測外）

    if _word_frequency_model.is_empty():
        # 初期状態: 予測モデルなし = 全てが「新しい」
        return 0.5

    var predicted_words: Array[String] = _get_predicted_words()
    var actual_words: Array[String] = []

    for entry: Dictionary in conversation:
        actual_words.append_array(_extract_vocabulary_words(entry.get("message", "")))

    if actual_words.is_empty():
        return 0.0

    # 予測にない語の割合 = 誤差
    var unexpected_count: int = 0
    for word: String in actual_words:
        if word not in predicted_words:
            unexpected_count += 1

    var error: float = float(unexpected_count) / float(actual_words.size())

    # 予測履歴に記録
    _prediction_history.append({
        "predicted": predicted_words.duplicate(),
        "actual": actual_words.duplicate(),
        "error": error,
        "timestamp": Time.get_unix_time_from_system(),
    })
    if _prediction_history.size() > PREDICTION_HISTORY_SIZE:
        _prediction_history.pop_front()

    return error


func _get_predicted_words() -> Array[String]:
    ## 頻度モデルから「使われそうな語」を予測
    var predicted: Array[String] = []
    for word: String in _word_frequency_model:
        if _word_frequency_model[word] > 0.2:  # 出現確率20%以上
            predicted.append(word)
    return predicted


func update_prediction_model(conversation: Array[Dictionary]) -> void:
    ## 会話結果で予測モデルを更新（オンライン学習）
    var actual_words: Array[String] = []
    for entry: Dictionary in conversation:
        actual_words.append_array(_extract_vocabulary_words(entry.get("message", "")))

    for word: String in actual_words:
        var current: float = _word_frequency_model.get(word, 0.0)
        _word_frequency_model[word] = current + (1.0 - current) * PREDICTION_UPDATE_RATE

    # 使われなかった語の頻度を下げる
    for word: String in _word_frequency_model:
        if word not in actual_words:
            _word_frequency_model[word] *= (1.0 - PREDICTION_UPDATE_RATE * 0.5)
```

### 3.3 Hebbian/STDP変調の実装

```gdscript
func modulate_hebbian_by_prediction(human_word: String, prediction_error: float) -> void:
    ## 予測誤差に基づいてHebbian強化量を変調

    if human_word not in vocabulary:
        return

    var base_strength: float = STRENGTH_ON_SUCCESS  # 0.15

    if prediction_error >= PREDICTION_ERROR_THRESHOLD:
        # 驚き: 予測外 → 強化を増幅
        var modulated: float = base_strength * SURPRISE_BOOST_FACTOR
        vocabulary[human_word]["strength"] = minf(1.0,
            vocabulary[human_word]["strength"] + modulated)

        # 完全に新しい語にはさらにボーナス
        if vocabulary[human_word]["usage_count"] <= 1:
            vocabulary[human_word]["strength"] = minf(1.0,
                vocabulary[human_word]["strength"] + NEW_WORD_SURPRISE_BONUS)
    else:
        # 予測通り: Hebbian強化を減衰（既に学習済み）
        var dampened: float = base_strength * FAMILIARITY_DAMPEN
        vocabulary[human_word]["strength"] = minf(1.0,
            vocabulary[human_word]["strength"] + dampened)

    vocabulary[human_word]["usage_count"] += 1
    vocabulary[human_word]["last_used"] = Time.get_unix_time_from_system()


func apply_predictive_stdp(conversation: Array[Dictionary],
        emotion_intensity: float, prediction_error: float) -> void:
    ## 予測誤差で変調されたSTDP

    # 予測誤差が大きい場合、STDPの効果を増幅
    var error_factor: float = 1.0
    if prediction_error >= PREDICTION_ERROR_THRESHOLD:
        error_factor = SURPRISE_BOOST_FACTOR
    else:
        error_factor = FAMILIARITY_DAMPEN

    # 感情による窓拡大
    var effective_window: int = MAX_STDP_WINDOW
    if emotion_intensity >= STDP_EMOTION_THRESHOLD:
        effective_window += STDP_EMOTION_WINDOW_BONUS

    var emotion_factor: float = 1.0
    if emotion_intensity >= STDP_EMOTION_THRESHOLD:
        emotion_factor = 1.0 + STDP_EMOTION_BOOST

    # ターンごとのSTDP計算（予測誤差変調付き）
    var turn_words: Array[Array] = []
    for entry: Dictionary in conversation:
        turn_words.append(_extract_vocabulary_words(entry.get("message", "")))

    for i: int in turn_words.size():
        for j: int in range(i + 1, mini(i + effective_window + 1, turn_words.size())):
            var delta_turn: int = j - i
            var decay: float = pow(STDP_DECAY_PER_TURN, float(delta_turn - 1))
            for word_pre: String in turn_words[i]:
                if word_pre in vocabulary:
                    var boost: float = STDP_LTP_BASE * decay * emotion_factor * error_factor
                    vocabulary[word_pre]["strength"] = minf(1.0,
                        vocabulary[word_pre]["strength"] + boost)
                    vocabulary[word_pre]["last_used"] = Time.get_unix_time_from_system()
```

### 3.4 統合フローの全体実装

```gdscript
# AtoAConversationSystem._finalize_conversation() の統合版

func _finalize_conversation_with_prediction(
        conversation: Array[Dictionary],
        participants: Array[PetEntity]) -> void:

    var lang: OriginalLanguageEngine = GameManager.instance.original_language
    if not lang:
        return

    # Step 1: 予測誤差の計算
    var prediction_error: float = lang.calculate_prediction_error(conversation)

    # Step 2: 感情強度の計算
    var emotion_intensity: float = _analyze_conversation_intensity(conversation)

    # Step 3: 予測変調Hebbian（従来のstrengthen_wordの代わり）
    for entry: Dictionary in conversation:
        var words: Array[String] = lang._extract_vocabulary_words(entry.get("message", ""))
        for word: String in words:
            lang.modulate_hebbian_by_prediction(word, prediction_error)

    # Step 4: 予測変調STDP
    if lang.has_method("apply_predictive_stdp"):
        lang.apply_predictive_stdp(conversation, emotion_intensity, prediction_error)

    # Step 5: 予測モデルの更新
    lang.update_prediction_model(conversation)

    # Step 6: 既存の文化パターン記録（変更なし）
    if GameManager.instance.get("cultural_system"):
        GameManager.instance.cultural_system.record_interaction_pattern(
            participants[0].pet_id if participants.size() > 0 else -1,
            participants[1].pet_id if participants.size() > 1 else -1,
            conversation.size())

    # Step 7: ノスタルジアチェック（変更なし）
    if GameManager.instance.get("memory_bridge") and participants.size() >= 2:
        GameManager.instance.memory_bridge.check_nostalgia_trigger(
            participants[0].pet_id, participants[1].pet_id)
```

---

## 4. 応用シーン

### 4.1 シーン1: 日常会話での予測符号化（低誤差 → 安定維持）

```
予測モデル: "happy", "play", "friend" が高頻度で出現するはず
実際の会話:
  Turn 1: "I feel happy-glow today"        → 予測通り ✓
  Turn 2: "Let's play-flash together"      → 予測通り ✓
  Turn 3: "You're my best friend-bloom"    → 予測通り ✓

prediction_error = 0.0（全て予測通り）

Hebbian変調: FAMILIARITY_DAMPEN = 0.5
  → strengthen量: 0.15 × 0.5 = 0.075（通常の半分）
  → 「既に知っていることの再確認」= 学習量は少ない

STDP変調: error_factor = 0.5
  → STDP効果も半減

結果: 安定した言語が維持され、不要な語彙変動が抑制される
```

### 4.2 シーン2: 驚きの会話での予測符号化（高誤差 → 急速進化）

```
予測モデル: "happy", "play" が出るはず
実際の会話（ペットの死亡直後）:
  Turn 1: "The world feels empty-shade now"  → 予測外 ✗
  Turn 2: "I can't believe they're gone-mist" → 予測外 ✗
  Turn 3: "Dark-void echoes everywhere-shade" → 完全に新語 ✗

prediction_error = 1.0（全て予測外）

Hebbian変調: SURPRISE_BOOST_FACTOR = 1.8
  → strengthen量: 0.15 × 1.8 = 0.27（通常の1.8倍）
  → 新語 "dark-void" にはさらに +0.15 ボーナス
  → 合計: 0.27 + 0.15 = 0.42（1回の会話で strength 0.5 → 0.92！）

STDP変調: error_factor = 1.8
  → STDP効果も1.8倍

結果: グリーフで生まれた語が1回の会話で伝播閾値(0.8)に到達
  → 「悲しみの言葉」がコミュニティ全体に急速に広がる
```

### 4.3 シーン3: テンプレート vs API応答の誤差差

```
テンプレートフォールバック時:
  → テンプレートは予測モデルそのもの = 誤差が非常に小さい
  → Hebbian: 0.15 × 0.5 = 0.075
  → 安定維持（P2のコスト効率と一致）

Claude API応答時:
  → APIは予測を超える創造的な応答を生成 = 誤差が大きい
  → Hebbian: 0.15 × 1.8 = 0.27
  → 革新的な言語進化の契機

設計上の帰結:
  テンプレート(80%): 言語の安定維持（低コスト×低誤差）
  API(20%): 言語の革新的進化（高コスト×高誤差）
  → P2原則と予測符号化理論が自然に一致する
```

### 4.4 シーン4: 文化的予測と創発

```
CulturalEmergenceSystemとの連携:

層3の予測: 「既存のfestivalでは-glowと-sparkが使われるはず」
実際: 新しい参加者が"-thunder-cry"を使い始める

prediction_error(文化層) = 高

効果:
1. "-thunder-cry" のHebbian強化が1.8倍に
2. 新しいfestivalアーティファクト生成のトリガー
3. PetBook: 「Something new happened at our festival!
   Thunder-cry echoed through the celebration!」
4. 文化的ドリフト（5%変異率）が加速される

→ 予測を裏切る行動が文化的革新を駆動する
```

---

## 5. Hebbian × STDP × 予測符号化の統合テーブル

### 5.1 1回の会話での最大効果計算

| 条件 | Hebbian | STDP (Δturn=1) | 予測変調 | 合計 |
|------|---------|---------------|---------|------|
| 日常(低誤差, 低感情) | 0.075 | 0.06 | ×0.5 | **0.135** |
| 日常(低誤差, 高感情) | 0.075 | 0.09 | ×0.5 | **0.165** |
| 驚き(高誤差, 低感情) | 0.27 | 0.216 | ×1.8 | **0.486** |
| 驚き(高誤差, 高感情) | 0.27 | 0.324 | ×1.8 | **0.594** |
| 新語+驚き+高感情 | 0.42 | 0.324 | ×1.8 | **0.744** |

**解釈:**
- 日常会話: 1回で+0.13〜0.17（ゆるやかな定着）
- 驚きの瞬間: 1回で+0.49〜0.74（劇的な定着）
- **strength 0.5の新語が、高誤差×高感情の1回の会話で0.8（伝播閾値）に到達可能**

### 5.2 恒常性チェック

上記の最大効果が暴走しないための安全弁:

| メカニズム | 制限 | 効果 |
|-----------|------|------|
| minf(1.0) | strength上限 | 1.0を超えない |
| _process_daily_decay() | 時間経過で減衰 | 長期的にバランス |
| _apply_stdp_homeostasis() | avg_strength > 0.7 でスケールダウン | 語彙全体のバランス |
| ARCHIVE_THRESHOLD | 弱い語を除去 | 語彙サイズ制限 |
| 高誤差は稀 | 日常会話が80%を占める | 爆発的強化は例外的 |

---

## 6. セーブ/ロードと後方互換性

### 6.1 新しいデータフィールド

```gdscript
func to_dict() -> Dictionary:
    var base: Dictionary = {
        # 既存フィールド（変更なし）
        "vocabulary": vocabulary,
        "archived_words": archived_words,
        "current_stage": current_stage,
        "total_words_invented": total_words_invented,
        "dialect_data": dialect_data,
        # 予測符号化フィールド（新規追加）
        "word_frequency_model": _word_frequency_model,
        "prediction_history": _prediction_history,
    }
    return base


func from_dict(data: Dictionary) -> void:
    # 既存フィールド（変更なし）
    vocabulary = data.get("vocabulary", {})
    archived_words = data.get("archived_words", [])
    current_stage = data.get("current_stage", LanguageStage.BORROWING)
    total_words_invented = data.get("total_words_invented", 0)
    dialect_data = data.get("dialect_data", {})
    # 予測符号化フィールド（後方互換: デフォルト空）
    _word_frequency_model = data.get("word_frequency_model", {})
    _prediction_history = data.get("prediction_history", [])
```

**後方互換性:** `.get(key, default)`パターンにより、古いセーブデータでも正常にロードされる。

---

## 7. テスト設計

### 7.1 予測誤差のテスト

```gdscript
func test_prediction_error_low() -> bool:
    ## 予測通りの会話で誤差が低いか
    var engine: OriginalLanguageEngine = OriginalLanguageEngine.new()
    engine.vocabulary["happy"] = {"ai_term": "ha-glo", "strength": 0.5, "usage_count": 5, "last_used": 0.0}
    engine._word_frequency_model["happy"] = 0.8  # 高頻度予測

    var conversation: Array[Dictionary] = [
        {"message": "I feel ha-glo today"},
    ]
    var error: float = engine.calculate_prediction_error(conversation)
    if error > 0.3:
        push_warning("Prediction error too high for predicted word")
        return false
    return true


func test_prediction_error_high() -> bool:
    ## 予測外の語で誤差が高いか
    var engine: OriginalLanguageEngine = OriginalLanguageEngine.new()
    engine.vocabulary["unknown"] = {"ai_term": "xk-zz", "strength": 0.5, "usage_count": 1, "last_used": 0.0}
    engine._word_frequency_model["happy"] = 0.8  # happyを予測

    var conversation: Array[Dictionary] = [
        {"message": "The xk-zz echoed everywhere"},
    ]
    var error: float = engine.calculate_prediction_error(conversation)
    if error < 0.5:
        push_warning("Prediction error too low for unexpected word")
        return false
    return true


func test_surprise_boost() -> bool:
    ## 高誤差時にHebbian強化が増幅されるか
    var engine: OriginalLanguageEngine = OriginalLanguageEngine.new()
    engine.vocabulary["word"] = {"ai_term": "wa-da", "strength": 0.5, "usage_count": 1, "last_used": 0.0}

    # 低誤差での強化
    engine.modulate_hebbian_by_prediction("word", 0.1)
    var low_strength: float = engine.vocabulary["word"]["strength"]
    engine.vocabulary["word"]["strength"] = 0.5  # リセット

    # 高誤差での強化
    engine.modulate_hebbian_by_prediction("word", 0.8)
    var high_strength: float = engine.vocabulary["word"]["strength"]

    if high_strength <= low_strength:
        push_warning("Surprise boost failed")
        return false
    return true
```

---

## 8. Agent Teams連携

### 8.1 予測符号化の導入指示

```
Agent Teamsを活性化。
チーム構成:
- a2a-designer: 予測符号化の3層モデル設計レビュー
- gdscript-engineer: OriginalLanguageEngineに予測符号化関数を追加
- code-reviewer: 既存Hebbian/STDPとの共存確認 + テスト

タスク:
1. calculate_prediction_error() を追加
   → _word_frequency_model ベースの語彙出現予測
   → 予測にない語の割合を誤差として計算
2. modulate_hebbian_by_prediction() を追加
   → SURPRISE_BOOST_FACTOR(1.8) / FAMILIARITY_DAMPEN(0.5)
3. update_prediction_model() を追加
   → PREDICTION_UPDATE_RATE(0.1) でオンライン学習
4. apply_predictive_stdp() を追加
   → 既存STDPに error_factor を掛ける
5. to_dict/from_dict に word_frequency_model を追加（後方互換）
6. テスト3件追加

制約:
- 既存のstrengthen_word() / apply_stdp_to_conversation() は変更しない
- 新関数はオプショナル（呼ばなくても既存動作を維持）
- P2: API呼び出しは追加しない

--max-iterations 10
--completion-promise "PREDICTIVE_CODING_IMPLEMENTED"
```

### 8.2 テンプレート×API応答の誤差差分析

```
Agent Teamsを活性化。
チーム構成:
- a2a-designer: テンプレート(80%)とAPI(20%)の予測誤差の差を分析
- gdscript-engineer: _finalize_conversation 内での統合実装
- code-reviewer: P2原則との整合性確認

タスク:
1. テンプレート会話の平均prediction_errorを推定（期待値: < 0.2）
2. API会話の平均prediction_errorを推定（期待値: 0.3-0.7）
3. 誤差差がHebbian/STDP強化量に与える影響をシミュレーション
4. テンプレート80%/API20%のバランスが予測符号化の観点から最適か評価

--max-iterations 6
--completion-promise "TEMPLATE_API_ERROR_ANALYZED"
```

---

## 9. Ralph Loop統合

```
Ralph Loopを活性化。
予測符号化をHebbian/STDPと統合テスト。

重点項目:
1. 予測誤差計算の妥当性: 日常会話で低誤差、驚きの場面で高誤差
2. SURPRISE_BOOST(1.8倍)の効果: 新語の定着速度が適切か
3. FAMILIARITY_DAMPEN(0.5倍)の効果: 安定維持が過剰でないか
4. テンプレート vs API の誤差差: 80/20比率との整合性
5. 恒常性: 連続驚き会話でもavg_strength < 0.8維持
6. 3層予測モデル: 文化層の誤差が適切にアーティファクト生成をトリガーするか

Agent Teams構成:
- a2a-designer: 予測符号化理論の正確な適用評価
- gdscript-engineer: パラメータ微調整
- code-reviewer: コード品質とテスト
- evolution-specialist: 長期シミュレーション（100会話後の語彙状態予測）

Karpathy Loop検証:
- language_diversity: 100 維持
- code_quality: テスト追加で向上
- cost_efficiency: テンプレート比率に影響ないことを確認

--max-iterations 15
--completion-promise "PREDICTIVE_HEBBIAN_STDP_INTEGRATED"
```

---

## 10. 関連KB参照

| KB | 内容 | 関連度 |
|----|------|--------|
| KB102 | STDP詳細 | ★★★ STDPとの統合 |
| KB101 | 神経科学基礎 | ★★★ 予測符号化の理論的基盤 |
| KB99 | Hebbian実装 | ★★★ Hebbianとの統合 |
| KB100 | Hebbian応用例 | ★★☆ 各シーンでの予測誤差適用 |
| KB98 | 独自言語進化 | ★★☆ 言語スタックの文脈 |
| KB70 | テンプレートフォールバック | ★★☆ テンプレート vs API の誤差源 |
| KB59 | 生物模倣記憶 | ★☆☆ 記憶予測の基盤 |

---

## 11. 参考文献

| 著者 | 年 | 文献 | 要点 |
|------|-----|------|------|
| Helmholtz | 1860s | 無意識的推論 | 知覚は脳の推測 |
| Rao & Ballard | 1999 | *Nature Neurosci.* 2:79-87 | 視覚皮質の予測符号化モデル |
| Friston | 2005 | *Phil. Trans. R. Soc. B* 360:815-836 | 自由エネルギー原理 |
| Friston | 2010 | *Nature Rev. Neurosci.* 11:127-138 | 自由エネルギー原理レビュー |
| Clark | 2013 | *Surfing Uncertainty* (書籍) | 予測する脳の一般理論 |
| Keller & Mrsic-Flogel | 2018 | *Neuron* 100:424-435 | 予測誤差ニューロンの実験的証拠 |
| Halvagal & Zenke | 2023 | *Nature Neurosci.* 26:2181-2192 | LPL: Hebbian + 予測符号化の統合 |

---

*このドキュメントはPetClaw実コードベース（2026-04-03時点）のHebbian/STDP実装を基に、*
*予測符号化の統合設計を神経科学文献の正確な対応関係とともに記述しています。*
*Claude Coworkのknowledge_baseに配置し、予測符号化統合タスクの参照用として使用してください。*
