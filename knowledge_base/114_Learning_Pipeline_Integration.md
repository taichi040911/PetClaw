# KB114: 学習パイプライン統合ガイド（Active Inference + BCM + Oja + Bridge）
## 3段階学習パイプラインの統合アーキテクチャと実装詳細
**Version:** 2026-04-03
**対象:** Claude Code / Claude Cowork / Agent Teams / 非エンジニア
**前提知識:** KB99 (Hebbian), KB108 (Active Inference), KB112 (BCM), KB113 (Oja)

---

## 1. 概要 — 3段階学習パイプライン

### 1.1 パイプラインの目的

PetClawのAtoA会話における語彙学習は、3つの神経科学モデルを直列に連携させることで実現する。
各段階が異なる役割を持ち、協調して語彙の「成長」と「安定」を両立させる。

```
Stage 1: Active Inference  — 予測誤差に基づく語彙強化（何を学ぶか決める）
Stage 2: BCM Theory        — スライディング閾値で安定化（暴走を止める）
Stage 3: Oja's Rule        — 正規化で分布を健全に保つ（バランスを取る）
```

### 1.2 設計哲学

| 原則 | 実装 |
|------|------|
| 完全ローカル | API呼び出しゼロ。全処理がGDScript内で完結 |
| 低レイテンシ | 全3段階合計 < 2ms（実測 < 1.5ms） |
| ゼロAPIコスト | Claude API不要。日次予算に影響なし |
| 生物模倣 | 神経科学のHebbian/BCM/Oja理論を忠実に実装 |
| 自動安定化 | 語彙爆発・一極集中・停滞を自動的に防止 |

### 1.3 対応ファイル

| ファイル | class_name | 役割 |
|----------|------------|------|
| `scripts/inference/active_inference_core.gd` | ActiveInferenceCore | Stage 1: 予測→比較→行動選択→学習 |
| `scripts/inference/bcm_language_core.gd` | BCMLanguageCore | Stage 2: LTP/LTD + sliding threshold |
| `scripts/inference/oja_language_core.gd` | OjaLanguageCore | Stage 3: Hebbian + 二次項 + 正規化 |
| `scripts/inference/learning_model_bridge.gd` | LearningModelBridge | 統合ブリッジ（3段階オーケストレーション） |

---

## 2. アーキテクチャ図

### 2.1 全体構成

```
┌─────────────────────────────────────────────────────────────────┐
│                    LearningModelBridge                          │
│                 （統合オーケストレーター）                        │
│                                                                 │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐        │
│  │   Stage 1    │   │   Stage 2    │   │   Stage 3    │        │
│  │  Active      │──▶│  BCM         │──▶│  Oja's       │        │
│  │  Inference   │   │  Theory      │   │  Rule        │        │
│  │  Core        │   │  Core        │   │  Core        │        │
│  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘        │
│         │                  │                   │                │
│    予測誤差計算       LTP/LTD判定          正規化処理          │
│    行動選択          閾値自動更新         コントラスト増強     │
│    Hebbian強化       イベント閾値調整     平均strength維持     │
│                                                                 │
│  ┌─────────────────────────────────────────────────┐            │
│  │              共有 vocabulary Dictionary           │            │
│  │  {word: {strength, ai_term, usage_count, ...}}   │            │
│  └─────────────────────────────────────────────────┘            │
│                                                                 │
│  signals: learning_completed(result), vocabulary_warning(str)   │
└─────────────────────────────────────────────────────────────────┘
        ▲                    ▲                    ▼
        │                    │                    │
   conversation         pet_state           PetBook/VFX
   (AtoA System)       (GameManager)        (演出データ)
```

### 2.2 Stage間の依存関係

```
conversation + pet_state + emotion_intensity
        │
        ▼
┌─── Stage 1: ActiveInferenceCore.run() ───┐
│  予測 → 比較 → 行動選択 → 学習            │
│  → ai_result: {action, error, surprise,   │
│     learning_boost, target_emotion}        │
│                                            │
│  ActiveInferenceCore.apply_to_words()      │
│  → vocabulary[word].strength に直接反映    │
└────────────┬───────────────────────────────┘
             │ ai_result
             ▼
┌─── Stage 2: BCMLanguageCore ─────────────┐
│  分岐:                                    │
│  ├─ event != "daily"                      │
│  │  → apply_bcm_with_event()              │
│  ├─ ai_result あり                        │
│  │  → integrate_with_active_inference()   │
│  └─ それ以外                              │
│     → apply_bcm_learning()                │
│                                            │
│  → bcm_result: {ltp_count, ltd_count,     │
│     threshold, avg_strength}               │
└────────────┬───────────────────────────────┘
             │ bcm_result
             ▼
┌─── Stage 3: OjaLanguageCore ─────────────┐
│  分岐:                                    │
│  ├─ bcm_result あり                       │
│  │  → apply_after_bcm()（正規化のみ）    │
│  └─ bcm_result なし                       │
│     → apply_oja_learning()（フル処理）    │
│                                            │
│  → oja_result: {normalized, scale_factor, │
│     avg_before, avg_after}                 │
└────────────────────────────────────────────┘
```

---

## 3. データフロー詳細

### 3.1 エントリポイント

LearningModelBridgeの `process_conversation()` が唯一のエントリポイント。
AtoA会話完了時にこのメソッドが呼ばれ、3段階の学習処理が自動実行される。

```gdscript
# 呼び出し例
var bridge := LearningModelBridge.new()
var result := bridge.process_conversation(
    vocabulary,          # {word: {strength, ai_term, usage_count, ...}}
    conversation,        # [{message, emotion, pet_id}, ...]
    pet_state,           # {pet_id, emotion, vocab_size, ...}
    emotion_intensity,   # 0.0〜1.0
    event_type           # "daily", "death", "evolution", etc.
)
```

### 3.2 Stage 1: Active Inference — 予測誤差に基づく行動選択

4ステップで構成される。

**Step 1: 予測 (`_step1_predict`)**
- 前回の発言の感情が続くと予測
- 信頼度: `0.2 + conversation.size() * 0.08`（最大0.8）
- model["common_word"] を予測単語として使用

**Step 2: 比較 (`_step2_compare`)**
- 予測 vs 実際の感情・単語を比較
- surprise = `1.0 - (emotion_match * 0.4 + word_match * 0.6)`
- 感情強度で増幅: `surprise *= (0.5 + emotion_strength * 0.5)`
- Variational Free Energy = `surprise + COMPLEXITY_COST * complexity`

**Step 3: 行動選択 (`_step3_choose_action`)**

| 条件 | 行動 | learning_boost |
|------|------|----------------|
| error > HIGH_ERROR (0.6) | `propose_new_word` | 1.5 |
| error > MEDIUM_ERROR (0.3) | `reinforce_existing` | 1.0 |
| error <= MEDIUM_ERROR | `maintain` | 0.5 |
| ランダム25% | `explore` | 1.0 |

感情別の閾値調整:
- `sadness`: HIGH_ERROR -0.20（追悼語彙の創出促進）
- `excitement`: HIGH_ERROR -0.10（冒険的）
- `fear`: HIGH_ERROR +0.10（安全志向）
- 強い感情(>0.7): HIGH_ERROR -0.15, MEDIUM_ERROR -0.10

**Step 4: 学習 (`_step4_learn`)**
- 記憶(memory)の更新: pet_stateを記憶に反映
- 予測モデルの改善: emotion_accuracy を +0.05（的中時） / -0.03（外れ時）

**語彙への反映 (`apply_to_words`)**
- Hebbian LTP基本値: 0.15
- surprise別の乗数:

| surprise level | multiplier |
|---------------|------------|
| high (>0.6)   | 1.8 * learning_boost |
| medium (>0.3) | 1.2 * learning_boost |
| low            | 0.8 |

### 3.3 Stage 2: BCM Theory — スライディング閾値による安定化

**閾値の自動更新 (`_update_threshold`)**
```
sliding_threshold = avg_strength * 0.8
                  + threshold_drift_accumulated
                  + avg_squared_strength * 0.1
```
- 範囲: [0.15, 0.90]
- drift: 会話ごとに +0.02 蓄積（最大0.3）

**BCMルール本体 (`_apply_bcm_rule`)**
```
activity > threshold → LTP: +0.18 * (activity - threshold)
activity < threshold → LTD: -0.08 * (threshold - activity)
```
- strength範囲: [0.05, 1.0]

**活動レベル計算**
```
activity = base_strength + (0.15 if used) + (emotion_intensity * 0.5 if used)
```

**Active Inference連携 (`integrate_with_active_inference`)**
- AI予測誤差が0.6超 → emotion_intensityを増幅
- learning_boostを乗算
- 結果にai_error, ai_actionを付加

### 3.4 Stage 3: Oja's Rule — 正規化による分布健全化

**BCM後の正規化モード (`apply_after_bcm`)**
- BCMの結果を受けて、正規化のみを実行
- 全語彙のstrengthをTARGET_AVG_STRENGTH (0.55) 付近に収束

**フル処理モード (`apply_oja_learning`)**
1. Hebbian強化/弱化: LTP +0.15*(1+emotion*0.5), LTD -0.03
2. Oja二次項: `decay = s^2 * 0.02`（使用中の語は半減）
3. 正規化: `scale = 1.0 + 0.1 * (target_total/current_total - 1.0)`

**正規化の判定**
- 現在の平均strength vs TARGET_AVG_STRENGTH (0.55) の差が0.03以上で発動
- scale範囲: [0.5, 2.0]
- OJA_RATE (0.1) で緩やかに適用（急激な変動を防止）

---

## 4. イベント別処理

### 4.1 イベント特化メソッド（LearningModelBridge）

LearningModelBridgeは4つのイベント特化メソッドを提供。
内部的にはすべて `process_conversation()` に `event_type` と適切な `emotion_intensity` を渡して委譲する。

| メソッド | event_type | emotion_intensity | 用途 |
|----------|------------|-------------------|------|
| `process_death_event()` | `"death"` | 0.9 | 死亡時の追悼語彙定着促進 |
| `process_evolution_event()` | `"evolution"` | 0.8 | 進化時の新語彙創出促進 |
| `process_resurrection_event()` | `"resurrection"` | 0.95 | 復活時の語彙再活性化 |
| `process_breeding_event()` | `"breeding"` | 0.7 | 交配時の親語彙継承促進 |

### 4.2 BCM閾値調整（EVENT_THRESHOLD_ADJ）

イベント時はBCMの `threshold_drift_accumulated` を一時的に調整し、
LTPが発生しやすい状態を作る。イベント処理後は元の値に復帰。

| event_type | 閾値調整 | 効果 |
|------------|---------|------|
| `death` | -0.20 | 追悼語が強く定着する（大幅にLTP促進） |
| `resurrection` | -0.25 | 復活関連語が最も定着しやすい |
| `breeding` | -0.15 | 親の語彙が子に伝わりやすい |
| `evolution` | -0.10 | 新しい形態に関連する語が生まれやすい |
| `first_meeting` | -0.08 | 初対面の語彙が少し定着しやすい |
| `daily` | 0.0 | 通常処理（調整なし） |

### 4.3 Active Inference側の感情調整

`_step3_choose_action()` では感情の種類によってHIGH_ERRORの閾値が変わる。
これにより、イベントに関連する感情が `propose_new_word` を発動しやすくなる。

```
death event:
  → emotion = "sadness"
  → HIGH_ERROR -= 0.20 （AI側）
  → threshold_drift -= 0.20 （BCM側）
  → 二重の促進効果で追悼語彙が確実に定着
```

---

## 5. AtoA会話システムとの統合

### 5.1 呼び出しタイミング

AtoA会話システム（`AtoAConversationSystem`）が会話を完了した後、
LearningModelBridgeの `process_conversation()` が呼ばれる。

```
AtoA会話完了
  │
  ▼
LearningModelBridge.process_conversation(
    vocabulary = pet.vocabulary,
    conversation = atoa_result.messages,
    pet_state = {pet_id, emotion, vocab_size},
    emotion_intensity = atoa_result.final_emotion_intensity,
    event_type = current_event_type
)
  │
  ▼
vocabulary が直接更新される（参照渡し）
  │
  ▼
learning_completed シグナルで後続処理へ通知
```

### 5.2 Multi-Agent連携（Shared Protention）

複数ペットが同時に会話している場合、ActiveInferenceCoreの `merge_predictions()` を使って予測の合意形成を行う。

```gdscript
# LearningModelBridge経由
var consensus := bridge.merge_multi_agent_predictions(
    my_pet_state,
    other_pet_predictions  # [{emotion, word, confidence}, ...]
)
# consensus.consensus: 0.0〜1.0（合意度）
# consensus.prediction.confidence: 自分の信頼度 * 合意度
```

**投票方式:**
- 各ペットの予測感情を集計
- 最多得票の感情が採用される
- 合意度 = 最多得票数 / 全投票数
- 自分の信頼度に合意度を乗算 → 合意が低いと慎重になる

### 5.3 会話データ構造

```gdscript
# conversation の各要素
{
    "message": "kirakira mofumofu",  # ペットの発言テキスト
    "emotion": "joy",                 # 発言時の感情
    "pet_id": 1,                      # 発言したペットのID
}

# pet_state
{
    "pet_id": 1,
    "emotion": "joy",
    "vocab_size": 15,
}
```

---

## 6. PetBook / VFX データ生成

### 6.1 PetBookデータ統合（LearningModelBridge.get_petbook_data）

3つのモデルがそれぞれPetBook用データを生成し、Bridgeが最も「派手な」ものを採用する。
判定基準は `particle_amount` の最大値。

**ActiveInferenceCore — 驚きベース:**

| 条件 | color | particles | text |
|------|-------|-----------|------|
| propose_new_word | 金色 (1.0, 0.8, 0.2) | 200 | "A brand new word was born!" |
| error > 0.6 | 赤 (1.0, 0.4, 0.3) | 120 | "A surprising conversation!" |
| error > 0.3 | 黄 (1.0, 0.9, 0.3) | 60 | "An interesting chat!" |
| else | 緑 (0.4, 0.8, 0.6) | 30 | "A peaceful conversation" |

**BCMLanguageCore — LTP/LTDベース:**

| 条件 | color | particles | text |
|------|-------|-----------|------|
| ltp > 3 | 金色 | 150 | "Language is evolving rapidly!" |
| ltp > 0, ltd == 0 | 緑 | 60 | "Words growing stronger" |
| ltd > ltp | 紫 | 40 | "Language is refining itself" |
| else | 緑 | 20 | "Language patterns stable" |

**OjaLanguageCore — 正規化ベース:**

| 条件 | color | particles | text |
|------|-------|-----------|------|
| normalized, scale < 0.9 | 青 (0.4, 0.6, 1.0) | 50 | "Language finding its balance" |
| normalized, scale > 1.1 | 橙 (0.9, 0.7, 0.3) | 80 | "Words gaining new life" |
| strengthened > 3 | 金色 | 120 | "Vocabulary blooming!" |
| else | 緑 | 25 | "Language patterns balanced" |

### 6.2 VFXデータ生成（LearningModelBridge.get_vfx_data）

`GameManager.visual_fx.play_effect()` 用のデータを生成。
AI結果があればsurprise levelベース、なければBCMのLTP数ベースで判定。

**Active Inference VFX:**

| surprise level | effect | color | particles | duration |
|---------------|--------|-------|-----------|----------|
| high | language_evolution | 赤 | 150 | 4.0s |
| medium | language_evolution | 黄 | 80 | 2.5s |
| low | language_evolution | 緑 | 30 | 1.5s |

**BCMフォールバックVFX:**

| 条件 | particles | duration |
|------|-----------|----------|
| ltp > 3 | 150 | 4.0s |
| ltp > 0 | 60 | 2.0s |
| else | 25 | 1.5s |

---

## 7. 健全性モニタリングと警告

### 7.1 二段階ヘルスチェック

LearningModelBridgeの `_check_health()` は毎サイクル自動実行され、
BCMとOja両方の視点から語彙の健全性を監視する。

**BCM側チェック (`check_vocabulary_health`):**

| 警告条件 | 警告メッセージ | 意味 |
|----------|---------------|------|
| max > 0.95 かつ avg > 0.7 | `vocabulary_too_strong` | 全体が強すぎて差別化できない |
| dead_count > 50% | `too_many_dead_words` | 語彙の半分以上が死語化 |
| avg < 0.2 | `vocabulary_too_weak` | 全体が弱すぎて会話に使えない |
| threshold > 0.85 | `threshold_too_high` | 閾値が高すぎてLTPが起きない |

**Oja側チェック (`analyze_contrast`):**

| health状態 | 条件 | 意味 |
|------------|------|------|
| `good` | 1.2 < contrast < 10.0, std_dev > 0.05 | 健全 |
| `too_uniform` | contrast < 1.2 | 全語彙が同じ強さ — 個性がない |
| `too_extreme` | contrast > 10.0 | 最強語と最弱語の差が大きすぎる |
| `stagnant` | std_dev < 0.05 | 語彙が変化しなくなっている |

### 7.2 警告の伝達

```gdscript
# Bridge内部
for warning in health.get("warnings", []):
    vocabulary_warning.emit(warning)  # シグナルで外部に通知

# 外部での受信例
bridge.vocabulary_warning.connect(func(w: String):
    push_warning("[Learning] " + w)
)
```

### 7.3 包括的分析（analyze_vocabulary）

`analyze_vocabulary()` はBCMとOja両方のチェック結果を統合して返す。
デバッグや定期チェックに使用。

```gdscript
var analysis := bridge.analyze_vocabulary(vocabulary)
# analysis.overall_healthy: bool
# analysis.avg_strength: float
# analysis.contrast_ratio: float
# analysis.bcm_threshold: float
# analysis.total_cycles: int
```

---

## 8. セーブ/ロード アーキテクチャ

### 8.1 データ構造

LearningModelBridgeの `to_dict()` は3つのコアすべての状態を1つのDictionaryにまとめる。

```gdscript
# to_dict() の出力構造
{
    "active_inference": {
        "memory": {...},                    # ペットの記憶（信念）
        "model": {                          # 予測モデル
            "emotion_accuracy": 0.45,
            "common_word": "kirakira",
            "conversation_count": 23,
        },
        "history": [{...}, ...],            # 最新10件のみ保存
    },
    "bcm_core": {
        "sliding_threshold": 0.52,          # 現在の閾値
        "threshold_drift_accumulated": 0.08, # 蓄積ドリフト
        "conversation_count": 23,
    },
    "oja_core": {
        "conversation_count": 23,
        "last_normalization": {             # 最後の正規化結果
            "applied": true,
            "scale_factor": 1.03,
            "avg_before": 0.58,
            "avg_after": 0.55,
        },
    },
    "total_cycles": 23,
    "cumulative_stats": {
        "total_ltp": 87,
        "total_ltd": 45,
        "total_normalizations": 12,
        "total_new_word_proposals": 5,
    },
}
```

### 8.2 復元時の後方互換性

すべての `from_dict()` は `.get(key, default)` パターンを使用。
セーブデータに新しいキーがなくても安全にデフォルト値で復元される。

```gdscript
# ActiveInferenceCore.from_dict() の例
model = data.get("model", {
    "emotion_accuracy": 0.3,
    "common_word": "",
    "conversation_count": 0,
})
```

### 8.3 履歴の制限

- ActiveInferenceCore: 実行時は最新20件保持、保存時は最新10件のみ
- BCM/Oja: 内部状態のみ（履歴は保存しない）
- cumulative_stats: 累積統計は永続保存

### 8.4 GameManagerとの統合

```
GameManager.save_game()
  → bridge.to_dict()
  → save_data["learning_bridge"] = bridge_dict

GameManager.load_game()
  → bridge.from_dict(save_data.get("learning_bridge", {}))
```

---

## 9. パラメータチューニングガイド

### 9.1 Active Inference パラメータ

| パラメータ | デフォルト | 調整ガイド |
|-----------|-----------|-----------|
| `HIGH_ERROR` | 0.6 | 新語が多すぎる → 上げる(0.8)、少なすぎる → 下げる(0.4) |
| `MEDIUM_ERROR` | 0.3 | reinforce頻度の調整。下げるとreinforceが増える |
| `EXPLORE_CHANCE` | 0.25 | ランダム探索の確率。下げると行動が予測的になる |
| `COMPLEXITY_COST` | 0.3 | 語彙数のペナルティ。上げると大語彙のペットが保守的に |
| `HEBBIAN_LTP` | 0.15 | 語彙強化の基本値。上げると学習が速い |
| `HIGH_SURPRISE_MULTIPLIER` | 1.8 | 高驚き時の強化倍率 |
| `MEDIUM_SURPRISE_MULTIPLIER` | 1.2 | 中驚き時の強化倍率 |
| `LOW_SURPRISE_MULTIPLIER` | 0.8 | 低驚き時の強化倍率 |

### 9.2 BCM パラメータ

| パラメータ | デフォルト | 調整ガイド |
|-----------|-----------|-----------|
| `LTP_RATE` | 0.18 | 強化速度。上げると語彙が速く強くなる |
| `LTD_RATE` | 0.08 | 弱化速度。上げると使われない語がすぐ弱くなる |
| `THRESHOLD_BASE_FACTOR` | 0.8 | 閾値の基本倍率。下げるとLTPが起きやすい |
| `THRESHOLD_DRIFT` | 0.02 | 会話ごとの閾値ドリフト。上げると長期的に閾値が上がる |
| `THRESHOLD_MIN` / `MAX` | 0.15 / 0.90 | 閾値の範囲 |
| `STRENGTH_FLOOR` / `CEILING` | 0.05 / 1.0 | strength値の範囲 |
| `EMOTION_AMPLIFICATION` | 0.5 | 感情による活動レベル増幅 |
| `QUADRATIC_FEEDBACK` | 0.1 | 二次フィードバック係数 |

### 9.3 Oja パラメータ

| パラメータ | デフォルト | 調整ガイド |
|-----------|-----------|-----------|
| `HEBBIAN_LTP_RATE` | 0.15 | Oja内のHebbian強化率 |
| `HEBBIAN_LTD_RATE` | 0.03 | 不使用語の弱化率 |
| `OJA_RATE` | 0.1 | 正規化の適用速度。上げると急激に正規化される |
| `TARGET_AVG_STRENGTH` | 0.55 | 目標平均strength。語彙全体がこの値に収束 |
| `QUADRATIC_DECAY` | 0.02 | 二次項の減衰率。コントラスト増強の強さ |
| `SCALE_MIN` / `MAX` | 0.5 / 2.0 | 正規化スケールの範囲 |
| `EMOTION_BOOST` | 0.5 | 感情による強化ボーナス |

### 9.4 よくあるチューニングシナリオ

**語彙が増えすぎる:**
1. `HIGH_ERROR` を上げる (0.6 → 0.8) — 新語提案の閾値を上げる
2. `LTP_RATE` を下げる (0.18 → 0.12) — 強化を穏やかにする
3. `TARGET_AVG_STRENGTH` を下げる (0.55 → 0.45) — 正規化の目標を下げる

**語彙が停滞する:**
1. `HIGH_ERROR` を下げる (0.6 → 0.4) — 新語提案しやすくする
2. `EXPLORE_CHANCE` を上げる (0.25 → 0.35) — 探索を増やす
3. `THRESHOLD_DRIFT` を下げる (0.02 → 0.01) — 閾値の上昇を抑える

**特定の語だけ極端に強い:**
1. `OJA_RATE` を上げる (0.1 → 0.2) — 正規化を強くする
2. `QUADRATIC_DECAY` を上げる (0.02 → 0.04) — 強い語ほど減衰
3. `STRENGTH_CEILING` を下げる (1.0 → 0.9) — 上限を制限

**追悼語彙が定着しない:**
1. `EVENT_THRESHOLD_ADJ["death"]` を下げる (-0.20 → -0.30)
2. death eventのemotion_intensityを上げる (0.9 → 0.95)
3. sadnessのHIGH_ERROR調整を確認 (-0.20が適用されているか)

---

## 10. パフォーマンス特性

### 10.1 処理時間

| Stage | 処理時間 | 備考 |
|-------|---------|------|
| Active Inference (run + apply_to_words) | < 1.0ms | 4ステップ + 語彙走査 |
| BCM Theory | < 0.5ms | 閾値計算 + LTP/LTD判定 |
| Oja's Rule | < 0.3ms | Hebbian + 二次項 + 正規化 |
| Health Check | < 0.2ms | BCM + Oja両方のチェック |
| **合計** | **< 2.0ms** | 実測では通常1.0〜1.5ms |

### 10.2 メモリ使用量

| データ | サイズ目安 |
|--------|-----------|
| vocabulary (100語) | ~50KB |
| AI history (最新20件) | ~5KB |
| BCM内部状態 | ~0.1KB |
| Oja内部状態 | ~0.1KB |
| cumulative_stats | ~0.1KB |

### 10.3 コスト

```
APIコスト: $0.00 / cycle
APIコスト: $0.00 / day
APIコスト: $0.00 / month

全処理はGDScript内のローカル計算。
Claude APIは一切使用しない。
日次予算 (AtoA $0.50, PetBook $0.50) に影響なし。
```

### 10.4 スケーラビリティ

| 語彙サイズ | 処理時間 | 状態 |
|-----------|---------|------|
| 10語 | < 0.3ms | 問題なし |
| 50語 | < 0.8ms | 問題なし |
| 100語 | < 1.5ms | 問題なし |
| 200語 | < 3.0ms | 要注意（1フレームに収まるが余裕が減る） |
| 500語+ | 未検証 | 実運用では到達しない想定 |

---

## 11. テストカバレッジ

### 11.1 テスト概要

52テストが4ファイルにわたって学習パイプラインをカバー。

| テストファイル | テスト数 | 対象 |
|---------------|---------|------|
| `test_active_inference_core.gd` | 15 | ActiveInferenceCore単体 |
| `test_bcm_language_core.gd` | 14 | BCMLanguageCore単体 |
| `test_oja_language_core.gd` | 12 | OjaLanguageCore単体 |
| `test_learning_model_bridge.gd` | 11 | LearningModelBridge統合 |

### 11.2 ActiveInferenceCore テスト (15)

| テスト名 | 検証内容 |
|----------|---------|
| test_empty_conversation | 空会話での予測（デフォルト値の確認） |
| test_prediction_confidence | 会話長による信頼度の増加 |
| test_emotion_match | 感情予測の一致判定 |
| test_word_match | 単語予測の一致判定 |
| test_free_energy_calculation | Free Energy = surprise + complexity_cost |
| test_high_error_action | 高誤差 → propose_new_word |
| test_medium_error_action | 中誤差 → reinforce_existing |
| test_low_error_action | 低誤差 → maintain |
| test_emotion_threshold_sadness | sadness時のHIGH_ERROR閾値調整 |
| test_learning_emotion_accuracy | 予測的中時のaccuracy更新 |
| test_apply_to_words_hebbian | Hebbian語彙強化の適用 |
| test_surprise_multiplier | surprise level別の強化倍率 |
| test_merge_predictions | Multi-Agent予測合意 |
| test_save_load | to_dict / from_dict 往復 |
| test_petbook_data | PetBook用データ生成 |

### 11.3 BCMLanguageCore テスト (14)

| テスト名 | 検証内容 |
|----------|---------|
| test_threshold_update | 閾値の自動更新 |
| test_ltp_above_threshold | 閾値超過時のLTP |
| test_ltd_below_threshold | 閾値以下のLTD |
| test_used_word_activity | 使用語の活動レベル計算 |
| test_emotion_amplification | 感情による活動増幅 |
| test_event_death | 死亡イベントの閾値調整 |
| test_event_resurrection | 復活イベントの閾値調整 |
| test_event_breeding | 交配イベントの閾値調整 |
| test_ai_integration | Active Inference連携 |
| test_health_check_healthy | 健全語彙の判定 |
| test_health_check_too_strong | 過度に強い語彙の警告 |
| test_health_check_dead_words | 死語過多の警告 |
| test_save_load | to_dict / from_dict 往復 |
| test_petbook_data | PetBook BCMデータ生成 |

### 11.4 OjaLanguageCore テスト (12)

| テスト名 | 検証内容 |
|----------|---------|
| test_hebbian_ltp | 使用語のHebbian強化 |
| test_hebbian_ltd | 未使用語のHebbian弱化 |
| test_oja_quadratic | 二次項によるコントラスト増強 |
| test_normalization_trigger | 正規化の発動条件 |
| test_normalization_target | TARGET_AVG_STRENGTHへの収束 |
| test_scale_limits | スケール範囲の制限 |
| test_apply_after_bcm | BCM後の正規化モード |
| test_contrast_analysis_good | 健全なコントラスト判定 |
| test_contrast_analysis_extreme | 極端なコントラスト判定 |
| test_contrast_analysis_stagnant | 停滞判定 |
| test_save_load | to_dict / from_dict 往復 |
| test_petbook_data | PetBook Ojaデータ生成 |

### 11.5 LearningModelBridge テスト (11)

| テスト名 | 検証内容 |
|----------|---------|
| test_full_pipeline_daily | 通常会話の3段階パイプライン |
| test_full_pipeline_death | 死亡イベントパイプライン |
| test_full_pipeline_evolution | 進化イベントパイプライン |
| test_full_pipeline_resurrection | 復活イベントパイプライン |
| test_full_pipeline_breeding | 交配イベントパイプライン |
| test_empty_conversation | 空会話での動作（Stage 1スキップ） |
| test_health_monitoring | 健全性チェックの統合 |
| test_petbook_integration | PetBookデータ統合（最派手選択） |
| test_vfx_generation | VFXデータ生成 |
| test_cumulative_stats | 累積統計の更新 |
| test_save_load | to_dict / from_dict 往復（3コア含む） |

### 11.6 テスト実行

```bash
# 全テスト実行
godot --headless --script tests/run_tests.gd

# 個別実行
godot --headless --script tests/test_active_inference_core.gd
godot --headless --script tests/test_bcm_language_core.gd
godot --headless --script tests/test_oja_language_core.gd
godot --headless --script tests/test_learning_model_bridge.gd
```

---

## 12. 実装上の注意点

### 12.1 vocabularyは参照渡し

3段階すべてが同じ `vocabulary` Dictionary を直接変更する。
コピーは作成しない。これは意図的な設計で、各Stageの変更が次のStageに即座に反映される。

```
Stage 1: vocabulary[word].strength += hebbian_delta    ← 直接変更
Stage 2: vocabulary[word].strength = bcm_new_strength  ← Stage 1の結果を上書き
Stage 3: vocabulary[word].strength *= oja_scale         ← Stage 2の結果をスケール
```

### 12.2 BCMの分岐ロジック

Stage 2のBCM処理は3つのパスがある。priority順に:

1. **event != "daily"** → `apply_bcm_with_event()` — イベント閾値調整あり
2. **ai_result あり** → `integrate_with_active_inference()` — AI誤差を感情に反映
3. **それ以外** → `apply_bcm_learning()` — 基本BCM処理

### 12.3 Ojaの分岐ロジック

Stage 3のOja処理は2つのパスがある:

1. **bcm_result あり** → `apply_after_bcm()` — 正規化のみ（Hebbian部分はStage 1,2で済み）
2. **bcm_result なし** → `apply_oja_learning()` — Hebbian + 二次項 + 正規化のフル処理

### 12.4 ENABLE_* フラグ

```gdscript
const ENABLE_AI: bool = true
const ENABLE_BCM: bool = true
const ENABLE_OJA: bool = true
```

各Stageを個別に無効化できる。デバッグやA/Bテスト用。
現在はすべて `true` で固定（constのため実行時変更不可）。

### 12.5 デバッグログ

`OS.is_debug_build()` が `true` の場合、各Stageが処理結果をprintする。

```
[ActiveInference] action=propose_new_word error=0.72 fe=0.87 reason=high prediction error
[BCM] θ=0.480 LTP=3 LTD=2 vocab=15
[Oja] LTP=3 LTD=2 scale=1.030 avg=0.580→0.553
[Bridge] cycle=24 AI=propose_new_word BCM_LTP=3 BCM_LTD=2 Oja_norm=true avg=0.553 health=true
```

---

## 13. 関連KBドキュメント

| KB | タイトル | 関連 |
|----|---------|------|
| KB99 | Hebbian Learning Implementation | Hebbian学習の基礎実装 |
| KB100 | Hebbian Learning Application Examples | 語彙強化の具体例 |
| KB101 | Hebbian Learning Neuroscientific Foundations | 神経科学的基盤 |
| KB104 | Free Energy Principle Application | FEPの理論的背景 |
| KB106 | Active Inference Detailed Implementation | AI実装の詳細設計 |
| KB107 | Active Inference Corrected Implementation | AI実装の修正版 |
| KB108 | Active Inference Final Adjusted Code | AI最終調整版コード |
| KB111 | Similar Biological Learning Models | 類似生物学習モデル概要 |
| KB112 | BCM Theory Detailed Implementation | BCM理論の詳細実装 |
| KB113 | Oja's Rule Implementation | Ojaルールの詳細実装 |
