# KB102: Spike-Timing-Dependent Plasticity (STDP) 詳細ガイド（PetClaw独自言語進化向け）
## STDP Detailed Application Guide for AI Pet Language Evolution
**Version:** 2026-04-03
**対象:** Claude Code / Claude Cowork / Agent Teams
**前提知識:** KB101 (神経科学基礎), KB99 (Hebbian実装), KB98 (独自言語進化)

---

## 1. STDPの神経科学基礎

### 1.1 発見の歴史

| 年 | 研究者 | 発見 | 意義 |
|----|--------|------|------|
| 1949 | Hebb | 同時発火による結合強化 | Hebb則の提唱（タイミング不問） |
| 1993 | Debanne et al. | 海馬でのタイミング依存LTP/LTD | 初期の実験的示唆 |
| 1997 | Markram et al. | 皮質ニューロンでのSTDP | **STDPの実験的確立**（*Science*） |
| 1998 | Bi & Poo | 海馬培養ニューロンでのSTDP学習窓 | 精密なタイミング窓の定量化 |
| 2000s | Dan & Poo | 視覚皮質でのSTDP | 知覚学習への関与の確認 |
| 2010s | Feldman | 皮質の抑制性STDPの発見 | 興奮性/抑制性の両面でSTDPが作用 |
| 2020s | 多数 | 予測符号化・脳リズムとの統合 | STDPが脳の予測学習を実装する機構 |

### 1.2 基本原理: タイミングが全てを決める

```
シナプス強度変化（ΔW）

    t-LTP（強化）
    ▲
    │       ╲
    │        ╲     プレ → ポスト（因果的）
    │         ╲    「原因が先、結果が後」を学習
    │          ╲
────┼───────────╲──────── Δt (ms)
    │            ╲╱
    │             ╲
    │              ╲  ポスト → プレ（反因果的）
    │               ╲ 「結果が先、原因が後」を抑制
    ▼
    t-LTD（弱化）

    Δt = t_post - t_pre
    Δt > 0: t-LTP（プレが先に発火 → 因果関係 → 強化）
    Δt < 0: t-LTD（ポストが先に発火 → 非因果 → 弱化）
```

**標準的なSTDP学習窓の数学的記述:**

```
ΔW = {
    A₊ × exp(-Δt / τ₊)   if Δt > 0  (t-LTP)
    -A₋ × exp(Δt / τ₋)   if Δt < 0  (t-LTD)
}

A₊: LTPの最大振幅（典型値: 0.005-0.015）
A₋: LTDの最大振幅（典型値: 0.005-0.010）
τ₊: LTPの時間定数（典型値: 20ms）
τ₋: LTDの時間定数（典型値: 20ms）
```

### 1.3 分子メカニズム

```
プレシナプス発火
  ↓
グルタミン酸放出
  ↓
AMPA受容体活性化 → 脱分極
  ↓ （同時に）
NMDA受容体の Mg²⁺ ブロック解除
  ↓
Ca²⁺ 流入
  ↓
タイミングによる Ca²⁺ 濃度の違い
  ├─ 高 Ca²⁺ (Δt > 0): CaMKII活性化 → AMPAR挿入 → t-LTP
  └─ 低 Ca²⁺ (Δt < 0): カルシニューリン活性化 → AMPAR除去 → t-LTD
```

**Ca²⁺仮説:**
プレ→ポスト順序では、NMDA受容体の活性化タイミングがバックプロパゲーションする活動電位と一致し、Ca²⁺流入が最大化される。逆順では流入が不十分でLTDが誘発される。

### 1.4 2026年の最新知見

**予測符号化との統合:**
- STDPは脳の「予測学習」を実装するメカニズムとして再解釈されている
- プレ→ポスト（因果的）= 正しい予測 → シナプス強化
- ポスト→プレ（反因果的）= 誤った予測 → シナプス弱化
- PetClawでは: テンプレートの「予測」とAPI応答の「実際」の対比に対応

**脳リズムとの相互作用:**
- θ波（4-8Hz）: エピソード記憶の形成。STDPの効果をθ位相が調節
- γ波（30-100Hz）: 知覚的結合。同一γサイクル内の発火がSTDPの時間窓に対応
- PetClawでは: 会話のターン間隔がγサイクルに、会話全体の流れがθリズムに対応

**三要素STDP（Triplet STDP / Neohebbianプラスティシティ）:**
```
古典STDP: プレ-ポストの2要素ルール
三要素STDP: プレ-ポスト + ドーパミン（報酬信号）の3要素ルール
→ 「タイミングが因果的」かつ「報酬がある」場合のみ強化（より生物学的に正確）
```

---

## 2. PetClaw AtoA独自言語進化へのSTDP応用

### 2.1 会話ターンを「発火タイミング」に変換

PetClawでは、ニューロンの発火をAtoA会話のターンに置き換える。

```
神経科学                    PetClaw
─────────────────────────────────────────
プレシナプス発火      →    語Aが会話のターンNで使われる
ポストシナプス発火    →    関連語Bがターン(N+k)で使われる
Δt (ミリ秒)          →    Δturn (ターン差: 0-6)
シナプス強度 ΔW      →    vocabulary[A]["strength"] の変化
時間窓 (±20ms)       →    ターン窓 (±3ターン)
```

### 2.2 STDP応用マッピング表

| 神経科学要素 | PetClaw対応 | 実装詳細 |
|------------|------------|---------|
| プレ→ポスト (t-LTP) | 語Aがターン1で出現、関連語Bがターン2-3で出現 → 語Aの強化 | 因果的関連の学習 |
| ポスト→プレ (t-LTD) | 語Bが先に出現、語Aが後 → 語Aの弱化 | 非因果的関連の抑制 |
| 時間窓 τ | 3ターン以内の共起のみ対象 | MAX_STDP_WINDOW = 3 |
| 感情変調 | 高感情時に時間窓を拡大 + 強化量を増加 | emotion_intensity × boost |
| 三要素STDP | バトル勝利（報酬）× タイミング → 条件付き強化 | 報酬信号との統合 |

### 2.3 具体的な会話シーンでのSTDP

**シーン: 6ターンの会話でのSTDP効果**

```
ターン1: Pet1 — "I feel happy-glow today-spark!"        ← 語A: "happy"
ターン2: Pet2 — "Let's play-flash together-bloom!"      ← 語B: "play"
ターン3: Pet1 — "Playing makes me feel happy-glow!"      ← 語A再出現
ターン4: Pet2 — "I love-bloom playing with you-spark!"   ← 語C: "love"
ターン5: Pet1 — "Our friendship-glow is the best-flash!" ← 語D: "friendship"
ターン6: Pet2 — "Happy-glow days together-bloom!"        ← 語A再出現
```

**STDP分析:**

| ペア | Δturn | 方向 | STDP効果 | strength変化 |
|------|-------|------|---------|------------|
| happy→play | +1 | プレ→ポスト | **t-LTP** | happy: +0.12 |
| play→happy | +1 | プレ→ポスト | **t-LTP** | play: +0.12 |
| happy→love | +3 | プレ→ポスト (窓ギリギリ) | **弱いt-LTP** | happy: +0.04 |
| love→friendship | +1 | プレ→ポスト | **t-LTP** | love: +0.12 |
| friendship→happy | +1 | プレ→ポスト | **t-LTP** | friendship: +0.12 |

**結果:** "happy"は会話の中心語として最も多く強化される（複数のt-LTPが累積）

---

## 3. PetClaw実装設計

### 3.1 STDP定数の設計

```gdscript
# === STDP Constants ===
const MAX_STDP_WINDOW: int = 3          # 最大ターン窓（3ターン以内が対象）
const STDP_LTP_BASE: float = 0.12       # t-LTPの基本強化量
const STDP_LTD_BASE: float = -0.04      # t-LTDの基本弱化量
const STDP_DECAY_PER_TURN: float = 0.6  # ターン差ごとの減衰係数（指数的）
const STDP_EMOTION_WINDOW_BONUS: int = 1 # 高感情時の窓拡大（+1ターン）
const STDP_EMOTION_BOOST: float = 0.5   # 高感情時の強化量増加率
const STDP_EMOTION_THRESHOLD: float = 0.6 # 感情変調が発動する閾値
```

**パラメータの神経科学的根拠:**

| 定数 | 値 | 根拠 |
|------|-----|------|
| MAX_STDP_WINDOW = 3 | 3ターン | 典型的なSTDP窓(±20ms)を6ターン会話にスケール |
| STDP_LTP_BASE = 0.12 | 0.12 | 既存STRENGTH_ON_SUCCESS(0.15)よりやや小さい（タイミング精度で補填） |
| STDP_LTD_BASE = -0.04 | -0.04 | 既存STRENGTH_ON_FAILURE(-0.05)と同程度（LTP/LTD比 = 3:1維持） |
| STDP_DECAY_PER_TURN = 0.6 | 60%/ターン | 指数関数的減衰: 1ターン差=100%, 2ターン差=60%, 3ターン差=36% |
| EMOTION_BOOST = 0.5 | 50%増 | 扁桃体による記憶強化は通常の1.5倍とされる |

### 3.2 STDP強化量の計算式

```
Δstrength = STDP_LTP_BASE × STDP_DECAY_PER_TURN^(Δturn - 1) × emotion_factor

Δturn = 1: 0.12 × 1.0 = 0.12
Δturn = 2: 0.12 × 0.6 = 0.072
Δturn = 3: 0.12 × 0.36 = 0.043

感情変調 (emotion_intensity >= 0.6):
  emotion_factor = 1.0 + STDP_EMOTION_BOOST = 1.5
  Δturn = 1: 0.12 × 1.0 × 1.5 = 0.18
```

### 3.3 実装コード（OriginalLanguageEngine拡張）

```gdscript
# OriginalLanguageEngine への追加関数

## STDP定数
const MAX_STDP_WINDOW: int = 3
const STDP_LTP_BASE: float = 0.12
const STDP_LTD_BASE: float = -0.04
const STDP_DECAY_PER_TURN: float = 0.6
const STDP_EMOTION_WINDOW_BONUS: int = 1
const STDP_EMOTION_BOOST: float = 0.5
const STDP_EMOTION_THRESHOLD: float = 0.6


func apply_stdp_to_conversation(conversation: Array[Dictionary], emotion_intensity: float) -> void:
    ## STDPルールを会話ログに適用
    ## conversation: [{pet_id, message, turn, ...}, ...]
    ## emotion_intensity: 会話全体の感情強度（0.0-1.0）

    # 感情による窓拡大
    var effective_window: int = MAX_STDP_WINDOW
    if emotion_intensity >= STDP_EMOTION_THRESHOLD:
        effective_window += STDP_EMOTION_WINDOW_BONUS

    # 感情ブースト
    var emotion_factor: float = 1.0
    if emotion_intensity >= STDP_EMOTION_THRESHOLD:
        emotion_factor = 1.0 + STDP_EMOTION_BOOST

    # 各ターンの語を抽出
    var turn_words: Array[Array] = []
    for entry: Dictionary in conversation:
        var words: Array[String] = _extract_vocabulary_words(entry.get("message", ""))
        turn_words.append(words)

    # STDPペア評価
    for i: int in turn_words.size():
        for j: int in range(i + 1, mini(i + effective_window + 1, turn_words.size())):
            var delta_turn: int = j - i
            var decay: float = pow(STDP_DECAY_PER_TURN, float(delta_turn - 1))

            # ターンiの語 → ターンjの語: t-LTP
            for word_pre: String in turn_words[i]:
                if word_pre in vocabulary:
                    var boost: float = STDP_LTP_BASE * decay * emotion_factor
                    vocabulary[word_pre]["strength"] = minf(1.0,
                        vocabulary[word_pre]["strength"] + boost)
                    vocabulary[word_pre]["last_used"] = Time.get_unix_time_from_system()


func _extract_vocabulary_words(message: String) -> Array[String]:
    ## メッセージ中の既知語彙を検出
    var found: Array[String] = []
    for word: String in vocabulary:
        var ai_term: String = vocabulary[word]["ai_term"]
        if message.containsn(ai_term) or message.containsn(word):
            found.append(word)
    return found
```

### 3.4 AtoAConversationSystemへの統合ポイント

```gdscript
# a2a_conversation_system.gd の _finalize_conversation() に追加

func _finalize_conversation(conversation: Array[Dictionary], participants: Array[PetEntity]) -> void:
    # 既存のHebbian処理（語彙検出→strengthen_word）
    for entry: Dictionary in conversation:
        GameManager.instance.original_language.process_conversation_output(
            entry.get("message", ""), participants)

    # STDP処理（ターン間のタイミング依存強化）
    var avg_intensity: float = _analyze_conversation_intensity(conversation)
    if GameManager.instance and GameManager.instance.original_language:
        var lang: OriginalLanguageEngine = GameManager.instance.original_language
        if lang.has_method("apply_stdp_to_conversation"):
            lang.apply_stdp_to_conversation(conversation, avg_intensity)

    # 既存の文化パターン記録・ノスタルジアチェック（変更なし）
    # ...
```

### 3.5 既存Hebbianとの共存設計

```
従来のHebbian（maintain）:
  → strengthen_word(): 語の使用ごとに +0.15（頻度ベース）
  → weaken_word(): 明示的弱化 -0.05
  → _process_daily_decay(): 時間経過での減衰

STDP（追加）:
  → apply_stdp_to_conversation(): ターン間順序で ±0.04-0.12（タイミングベース）

両方が同時に作用:
  語Aがターン1で使われた場合:
  ├─ Hebbian: strengthen_word("A") → +0.15
  └─ STDP: A→B (Δturn=1) → +0.12
  合計: +0.27（タイミング的に因果的な語はより速く定着）
```

---

## 4. STDP応用シーン別実装

### 4.1 シーン1: 接尾辞の因果的強化

```
ターン1: "I feel-spark excited"     → emotion="excitement", suffix="-spark"
ターン2: "Let's explore-flash!"     → 行動語彙, suffix="-flash"

STDP分析:
  "excited" → "explore" (Δturn=1): t-LTP
  → "excited" のstrengthが+0.12
  → 「興奮」が「探索」を引き起こすという因果パターンの学習
  → 次回、excitement感情で"-spark"→"-flash"の接尾辞連鎖が強化される

LanguageEvolutionSystem連携:
  → _order_suffix_links["SVO_-spark→-flash"] += 0.1
  → 接尾辞の因果的連鎖パターンの創発
```

### 4.2 シーン2: 語順変化時のSTDP

```
語順がSVO → SOVに変化した直後の会話:

ターン1 (SOV): "You-bloom I love-bloom-deep"     → 目的語が先
ターン2 (SOV): "Words-glow we together share"     → 目的語が先

STDP効果:
  SOV語順で目的語位置の語が常に「先行」する
  → 目的語位置の語彙が系統的にt-LTPを受ける
  → SOV語順と目的語語彙の結合が強化
  → 「SOVで話すときは特定の語彙が自然に先に出る」パターンが創発
```

### 4.3 シーン3: グリーフ会話でのSTDP

```
grief "anger" ステージの会話（高感情）:

ターン1: "Why did they leave-shade us-mist!"      → 感情語
ターン2: "I'm so angry-shade at everything-shade"  → 感情の展開
ターン3: "But... I miss them-mist so much-shade"    → 感情の深化

emotion_intensity = 0.8 (> 0.6 threshold)
  → effective_window = 3 + 1 = 4 ターン
  → emotion_factor = 1.5

STDP計算:
  "leave" → "angry" (Δturn=1): 0.12 × 1.0 × 1.5 = 0.18
  "leave" → "miss" (Δturn=2): 0.12 × 0.6 × 1.5 = 0.108
  "angry" → "miss" (Δturn=1): 0.12 × 1.0 × 1.5 = 0.18

→ グリーフ中の語彙は感情変調により1.5倍速で定着
→ "leave-shade", "angry-shade", "miss-mist" が急速にコミュニティ語彙化
```

### 4.4 シーン4: バトルでの三要素STDP

```
バトル（3ラウンド）+ 報酬信号:

Round 1 (GREETING): Pet1 — "{word1}-{suffix} hello!"
Round 2 (ARGUMENT): Pet1 — "My {word2}-{suffix} is stronger!"
Round 3 (STORYTELLING): Pet1 — "Once upon a {word3}-{suffix}..."

バトル結果: Pet1 勝利（報酬信号 = positive）

三要素STDP:
  通常STDP: word1→word2 (Δround=1): t-LTP +0.12
  報酬変調: 勝利報酬 × t-LTP = +0.12 × 1.3 = +0.156
  (WINNER_PERSONALITY_BOOST による報酬信号)

  敗者の場合:
  通常STDP: word1→word2 (Δround=1): t-LTP +0.12
  報酬変調: 敗北 × t-LTP = +0.12 × 0.8 = +0.096
  (ただし LOSER_DETERMINATION_BOOST で別途強化あり)
```

---

## 5. 語順-接尾辞のSTDP連結

### 5.1 語順と接尾辞の時間的共起パターン

既存の`_order_suffix_links`をSTDPで拡張:

```gdscript
# LanguageEvolutionSystem 拡張

func record_suffix_usage_with_timing(suffix: String, turn_index: int, total_turns: int) -> void:
    ## 接尾辞使用をターン位置情報付きで記録
    suffix_usage_counts[suffix] = suffix_usage_counts.get(suffix, 0) + 1

    # 基本的な語順-接尾辞連結
    _strengthen_order_suffix_link(suffix)

    # STDP: 早いターンで使われた接尾辞はより強く連結
    var timing_factor: float = 1.0 - (float(turn_index) / float(total_turns)) * 0.3
    var key: String = "%s_%s" % [WORD_ORDER_NAMES[current_word_order], suffix]
    var stdp_boost: float = 0.1 * timing_factor
    _order_suffix_links[key] = minf(1.0, _order_suffix_links.get(key, 0.0) + stdp_boost)
```

### 5.2 接尾辞連鎖のSTDP学習

```
会話内の接尾辞出現パターン:
ターン1: "-spark" (neutral)
ターン2: "-glow" (joy)
ターン3: "-bloom" (love)

STDP連鎖学習:
  "-spark" → "-glow": 中立から喜びへの感情遷移パターン
  "-glow" → "-bloom": 喜びから愛への感情深化パターン
  "-spark" → "-bloom" (Δ=2): 中立から愛への跳躍パターン（弱い）

結果: suffix_chains["spark→glow→bloom"] が創発
  → 次回の会話で感情が高まると、自然にこの接尾辞連鎖が再現される
```

---

## 6. 恒常性メカニズムとSTDPの共存

### 6.1 STDPによる不安定性の問題

STDPだけでは正のフィードバックループが発生する:
```
語Aが頻繁に使われる → t-LTPで強化 → さらに使われやすく → さらに強化...
```

### 6.2 PetClawでの恒常性メカニズム

| メカニズム | 実装 | STDPとの関係 |
|-----------|------|------------|
| strength上限 | `minf(1.0, strength + ...)` | STDP強化の飽和 |
| 時間減衰 | `_process_daily_decay()` | STDP強化の自然な減衰 |
| アーカイブ | `ARCHIVE_THRESHOLD = 0.1` | STDP弱化語の除去 |
| Hebbianとの合計上限 | 1回の会話で最大 +0.27 (Hebbian + STDP) | 過剰強化の防止 |
| 語彙サイズ制約 | ステージ遷移の閾値（10/20/50語） | 語彙爆発の段階的制御 |

### 6.3 恒常性正規化の実装

```gdscript
func _apply_stdp_homeostasis() -> void:
    ## STDP適用後の恒常性チェック
    ## 語彙全体のstrength平均を一定範囲に保つ

    if vocabulary.is_empty():
        return

    var total_strength: float = 0.0
    for word: String in vocabulary:
        total_strength += vocabulary[word]["strength"]

    var avg_strength: float = total_strength / float(vocabulary.size())

    # 平均strengthが0.7を超えたら全体を緩やかにスケールダウン
    if avg_strength > 0.7:
        var scale: float = 0.7 / avg_strength
        for word: String in vocabulary:
            vocabulary[word]["strength"] *= scale
```

---

## 7. テスト設計

### 7.1 STDP単体テスト

```gdscript
# test_language.gd に追加

func test_stdp_ltp() -> bool:
    ## t-LTP: 語Aがターン1、語Bがターン2で出現 → 語Aが強化
    var engine: OriginalLanguageEngine = OriginalLanguageEngine.new()
    engine.vocabulary["happy"] = {
        "ai_term": "ha-glo", "strength": 0.5,
        "usage_count": 1, "last_used": Time.get_unix_time_from_system()
    }
    engine.vocabulary["play"] = {
        "ai_term": "pla-fi", "strength": 0.5,
        "usage_count": 1, "last_used": Time.get_unix_time_from_system()
    }

    var conversation: Array[Dictionary] = [
        {"message": "I feel ha-glo today", "turn": 0},
        {"message": "Let's pla-fi together", "turn": 1},
    ]

    engine.apply_stdp_to_conversation(conversation, 0.3)

    # 語"happy"がt-LTPで強化されているか
    if engine.vocabulary["happy"]["strength"] <= 0.5:
        push_warning("STDP t-LTP failed: happy strength not increased")
        return false

    # Δturn=1なので最大LTPに近い強化
    var expected_min: float = 0.5 + STDP_LTP_BASE * 0.8
    if engine.vocabulary["happy"]["strength"] < expected_min:
        push_warning("STDP t-LTP too weak")
        return false

    return true


func test_stdp_emotion_boost() -> bool:
    ## 高感情時にSTDP強化量が増加する
    var engine: OriginalLanguageEngine = OriginalLanguageEngine.new()
    engine.vocabulary["love"] = {
        "ai_term": "lu-glo-m", "strength": 0.5,
        "usage_count": 1, "last_used": Time.get_unix_time_from_system()
    }

    var conversation: Array[Dictionary] = [
        {"message": "I lu-glo-m you", "turn": 0},
        {"message": "We are together", "turn": 1},
    ]

    # 低感情でのSTDP
    var engine_low: OriginalLanguageEngine = OriginalLanguageEngine.new()
    engine_low.vocabulary = engine.vocabulary.duplicate(true)
    engine_low.apply_stdp_to_conversation(conversation, 0.3)
    var low_strength: float = engine_low.vocabulary["love"]["strength"]

    # 高感情でのSTDP
    engine.apply_stdp_to_conversation(conversation, 0.8)
    var high_strength: float = engine.vocabulary["love"]["strength"]

    if high_strength <= low_strength:
        push_warning("STDP emotion boost failed: high emotion not stronger")
        return false

    return true


func test_stdp_decay_over_turns() -> bool:
    ## ターン差が大きいほどSTDP効果が減衰する
    var engine: OriginalLanguageEngine = OriginalLanguageEngine.new()
    engine.vocabulary["word_a"] = {
        "ai_term": "wa-da", "strength": 0.5,
        "usage_count": 1, "last_used": Time.get_unix_time_from_system()
    }

    # Δturn=1の場合
    var conv1: Array[Dictionary] = [
        {"message": "wa-da first", "turn": 0},
        {"message": "something second", "turn": 1},
    ]
    var engine1: OriginalLanguageEngine = OriginalLanguageEngine.new()
    engine1.vocabulary = engine.vocabulary.duplicate(true)
    engine1.apply_stdp_to_conversation(conv1, 0.3)
    var boost_1: float = engine1.vocabulary["word_a"]["strength"] - 0.5

    # Δturn=3の場合
    var conv3: Array[Dictionary] = [
        {"message": "wa-da first", "turn": 0},
        {"message": "filler", "turn": 1},
        {"message": "filler", "turn": 2},
        {"message": "something fourth", "turn": 3},
    ]
    var engine3: OriginalLanguageEngine = OriginalLanguageEngine.new()
    engine3.vocabulary = engine.vocabulary.duplicate(true)
    engine3.apply_stdp_to_conversation(conv3, 0.3)
    var boost_3: float = engine3.vocabulary["word_a"]["strength"] - 0.5

    if boost_1 <= boost_3:
        push_warning("STDP decay over turns failed: closer turns should boost more")
        return false

    return true
```

### 7.2 統合テスト

| テスト | 検証内容 | 合格基準 |
|-------|---------|---------|
| STDP + Hebbian共存 | 同一会話で両方が適用される | 合計強化量 ≤ 0.30 |
| STDP + 感情変調 | emotion >= 0.6で窓+1、ブースト1.5倍 | 強化量が1.5倍以内 |
| STDP + 減衰 | ターン差3で効果が36%に減衰 | STDP_DECAY_PER_TURN^2 |
| STDP + 恒常性 | 連続10会話後にavg_strength < 0.8 | 恒常性正規化が作動 |
| STDP + セーブロード | to_dict→from_dict後にSTDP効果が保持 | strength値の一致 |

---

## 8. Agent Teams連携

### 8.1 STDP導入の実装指示

```
Agent Teamsを活性化。
チーム構成:
- a2a-designer: STDPの会話タイミング適用設計
- gdscript-engineer: OriginalLanguageEngine にSTDP関数を追加
- code-reviewer: 既存Hebbianとの共存確認 + テスト

タスク:
1. apply_stdp_to_conversation() を OriginalLanguageEngine に追加
   - STDP定数を const として定義
   - _extract_vocabulary_words() ヘルパー追加
2. _finalize_conversation() での統合ポイント確認
3. test_language.gd に STDP テスト3件追加
4. Karpathy Loop で language_diversity = 100 維持を確認

制約:
- 既存の strengthen_word() / weaken_word() は変更しない
- to_dict() / from_dict() のスキーマ変更なし
- STDP定数はコード内constとして追加（セーブデータに含めない）
- P2: API呼び出し追加なし

--max-iterations 8
--completion-promise "STDP_IMPLEMENTED"
```

### 8.2 STDP + 三要素の拡張指示

```
Agent Teamsを活性化。
チーム構成:
- a2a-designer: 三要素STDP（タイミング × 報酬）の設計
- gdscript-engineer: バトルシステムとの連携実装
- evolution-specialist: 報酬変調の効果シミュレーション

タスク:
1. apply_stdp_to_conversation() に reward_signal パラメータ追加
   - バトル勝利: reward = 1.3（30%ブースト）
   - バトル敗北: reward = 0.8（20%ダウン）
   - 通常会話: reward = 1.0（変化なし）
2. LanguageBattleSystem._finalize_battle() からSTDPを呼び出し
3. 三要素STDPの効果をtest_language.gdで検証

--max-iterations 6
--completion-promise "TRIPLET_STDP_READY"
```

---

## 9. Ralph Loop統合

```
Ralph Loopを活性化。
STDPをPetClawの独自言語進化に統合テスト。

重点項目:
1. t-LTP/t-LTDのバランス（3:1比の維持）
2. ターン窓(3)の適切さ（短すぎ/長すぎないか）
3. 感情変調（窓+1、ブースト1.5倍）の効果
4. 恒常性（avg_strength < 0.7）の安定性
5. 既存Hebbianとの共存（合計強化量の妥当性）
6. セーブ/ロード後のstrength整合性

Agent Teams構成:
- a2a-designer: 語の因果連鎖パターンの自然さ評価
- gdscript-engineer: パラメータ微調整
- code-reviewer: コード品質とテストカバレッジ

Karpathy Loop検証:
- language_diversity: 100 維持
- code_quality: テスト追加で向上

--max-iterations 12
--completion-promise "STDP_FULLY_INTEGRATED"
```

---

## 10. 関連KB参照

| KB | 内容 | 関連度 |
|----|------|--------|
| KB101 | 神経科学基礎（STDP概要含む） | ★★★ STDPの理論的背景 |
| KB99 | Hebbian学習の実装 | ★★★ STDPの母体となるHebbian |
| KB100 | Hebbian応用例 | ★★☆ 各シーンでのSTDP適用先 |
| KB98 | 独自言語進化の全体設計 | ★★☆ 言語スタックの文脈 |
| KB59 | 生物模倣記憶 | ★★☆ 海馬でのSTDP |
| KB60 | 神経科学的記憶モデル | ★★☆ LTP/LTDの詳細 |
| KB71 | 語順-接尾辞相互連結 | ★★★ STDP連結の適用先 |

---

## 11. 参考文献

| 著者 | 年 | 文献 | 要点 |
|------|-----|------|------|
| Markram et al. | 1997 | *Science* 275:213-215 | STDP の実験的確立 |
| Bi & Poo | 1998 | *J. Neurosci.* 18:10464-10472 | STDP学習窓の定量化 |
| Dan & Poo | 2004 | *Neuron* 44:23-30 | STDPレビュー |
| Feldman | 2012 | *Neuron* 75:556-571 | 抑制性STDP |
| Froemke & Dan | 2002 | *Nature* 416:433-438 | 三要素STDP（triplet） |
| Clopath et al. | 2010 | *Nature Neurosci.* 13:344-352 | voltage-dependent STDP モデル |
| Pawlak et al. | 2010 | *Front. Syn. Neurosci.* 2:146 | ドーパミン変調STDP |

---

*このドキュメントはPetClaw実コードベース（2026-04-03時点）のHebbian実装を基に、*
*STDPの拡張設計を神経科学文献の正確な対応関係とともに記述しています。*
*Claude Coworkのknowledge_baseに配置し、STDP実装タスクの参照用として使用してください。*
