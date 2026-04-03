# KB99: Hebbian学習の実装ガイド（PetClaw独自言語進化向け）
## Hebbian Learning Implementation Guide for AI Pet Language Evolution
**Version:** 2026-04-03
**対象:** Claude Code / Claude Cowork / Agent Teams
**前提知識:** KB98 (独自言語進化詳細), KB67 (AtoA会話), KB59 (生物模倣記憶)

---

## 1. Hebbian学習のコンセプト

### 1.1 基本原理

> "Neurons that fire together, wire together." — Donald Hebb, 1949

**Hebbian学習**: 同時に活性化するニューロン間の結合が強化される（LTP: Long-Term Potentiation）。
使われない結合は弱まる（LTD: Long-Term Depression）。

PetClawでは、この神経科学的原理を**AIペットの語彙強化メカニズム**として実装している。

### 1.2 PetClawでの3つのHebbian適用

| 適用先 | 神経科学的対応 | 実装 |
|--------|-------------|------|
| **語彙強化** | LTP（長期増強） | 使用されるたびに`strength += 0.15` |
| **語彙減衰** | LTD + 忘却曲線 | 未使用語は`DAILY_DECAY`で減衰、age_factorで加速 |
| **語順-接尾辞連結** | シナプス同時発火 | `_order_suffix_links`が共起するたびに+0.1 |

### 1.3 生物模倣の対応表

| 脳の仕組み | PetClaw実装 | 詳細 |
|-----------|------------|------|
| 海馬（短期→長期記憶） | `strength` 0.5→1.0の上昇 | 新語は0.5で誕生、反復使用で定着 |
| シナプス可塑性 | `STRENGTH_ON_SUCCESS/FAILURE` | 成功+0.15、失敗-0.05の非対称強化 |
| Ebbinghaus忘却曲線 | `_process_daily_decay` + `age_factor` | 時間経過で加速する減衰 |
| 伝播（LTP拡散） | `PROPAGATION_THRESHOLD` = 0.8 | 十分に強化された語がコミュニティ全体に伝播 |
| 死語化（シナプス剪定） | `ARCHIVE_THRESHOLD` = 0.1 | 弱すぎる語はアーカイブ（完全削除ではない） |
| 感情記憶の強化 | 感情による音韻変形 | joy→明るい母音、fear→摩擦音 |
| 睡眠時の記憶固定 | MemoryPersonalityBridgeの夢合成 | 夢の中で語彙が再活性化 |

---

## 2. 実装の全体像

### 2.1 Hebbianサイクル図

```
    ┌───────────────────────────────────────────────┐
    │                                               │
    │   AtoA会話発生                                  │
    │       │                                       │
    │       ▼                                       │
    │   process_conversation_output()               │
    │   → 会話文中のai_termを検出                      │
    │   → strengthen_word() 呼び出し                   │
    │       │                                       │
    │       ▼                                       │
    │   ┌────────────────────────────────────┐      │
    │   │  Hebbian強化                        │      │
    │   │  strength += 0.15 (LTP)            │      │
    │   │  usage_count += 1                  │      │
    │   │  last_used = now                   │      │
    │   └────────┬───────────────────────────┘      │
    │            │                                  │
    │            ▼                                  │
    │   strength >= 0.8?                            │
    │   YES → _propagate_word()                     │
    │          → SharedField.add_event()            │
    │          → 全ペットが認識可能に                   │
    │                                               │
    │   毎フレーム並行:                                │
    │   ┌────────────────────────────────────┐      │
    │   │  Temporal Decay (LTD)              │      │
    │   │  strength -= decay * age_factor    │      │
    │   │  strength < 0.1?                   │      │
    │   │  YES → _archive_word() (忘却)       │      │
    │   └────────────────────────────────────┘      │
    │                                               │
    └───────────────────────────────────────────────┘
```

### 2.2 関連ファイルとHebbian責務

| ファイル | Hebbian責務 | 呼び出し方向 |
|---------|------------|------------|
| `original_language_engine.gd` | **主実装**: strengthen/weaken/decay/archive/propagate | 中核 |
| `language_evolution_system.gd` | 語順-接尾辞の共起強化（`_order_suffix_links`） | 補助 |
| `a2a_conversation_system.gd` | 会話テンプレートで語彙を使用 → 間接的にHebbian強化 | 消費者 |
| `language_battle_system.gd` | バトルで語彙使用 → `HEBBIAN_BOOST_PER_WORD = 0.05` | 消費者 |
| `memory_personality_bridge.gd` | 夢合成で語彙再活性化 | 補助 |

---

## 3. 実装詳細 — OriginalLanguageEngine

### 3.1 定数パラメータ

```gdscript
# === Hebbian Learning Constants ===
const STRENGTH_ON_SUCCESS: float = 0.15    # LTP: 成功コミュニケーション時の強化量
const STRENGTH_ON_FAILURE: float = -0.05   # LTD: 失敗コミュニケーション時の弱化量
const DAILY_DECAY: float = 0.01            # 基本減衰率（ゲーム内1日あたり）
const ARCHIVE_THRESHOLD: float = 0.1       # シナプス剪定: これ以下でアーカイブ
const PROPAGATION_THRESHOLD: float = 0.8   # 伝播閾値: これ以上で全ペットに伝播
```

**設計根拠:**
- **非対称強化 (0.15 vs -0.05)**: 生物のシナプス可塑性と同じく、強化が弱化の3倍。使う方が忘れるより圧倒的に簡単
- **初期strength 0.5**: 新語は「使われ始めた」状態。あと3回の成功使用で伝播閾値に到達
- **伝播閾値 0.8**: 全コミュニティに広がるには約3回の連続使用が必要（0.5+0.15×2=0.8）

### 3.2 Hebbian強化（LTP）実装

```gdscript
func strengthen_word(human_word: String) -> void:
    if human_word not in vocabulary:
        return
    var entry: Dictionary = vocabulary[human_word]
    entry["usage_count"] += 1
    entry["strength"] = minf(1.0, entry["strength"] + STRENGTH_ON_SUCCESS)
    entry["last_used"] = Time.get_unix_time_from_system()

    word_strengthened.emit(entry["ai_term"], entry["strength"])

    # 伝播チェック
    if entry["strength"] >= PROPAGATION_THRESHOLD:
        _propagate_word(human_word)
```

**ポイント:**
- `minf(1.0, ...)`: strength上限は1.0（生物のシナプス飽和に対応）
- `last_used`更新: 減衰計算のタイムスタンプリセット
- 伝播は閾値到達のたびにチェック（冪等: SharedFieldは重複を無視）

### 3.3 Hebbian弱化（LTD）実装

```gdscript
func weaken_word(human_word: String) -> void:
    if human_word not in vocabulary:
        return
    vocabulary[human_word]["strength"] += STRENGTH_ON_FAILURE  # -0.05
```

**呼び出しタイミング:**
- 会話中に語彙が「誤用」された場合（現在は明示的に呼ばれる場面は少ない）
- 将来的にMulti-Agent検証で「不適切」と判定された場合

### 3.4 時間減衰（Ebbinghaus忘却曲線の模倣）

```gdscript
func _process_daily_decay(delta: float) -> void:
    # ゲーム内1日 = 3600秒（1リアル時間）
    var decay_per_frame: float = DAILY_DECAY * delta / 3600.0

    var to_archive: Array[String] = []
    for word in vocabulary:
        var entry: Dictionary = vocabulary[word]
        # 最後の使用からの経過時間で減衰を加速
        var time_since_use: float = Time.get_unix_time_from_system() - entry.get("last_used", 0)
        var age_factor: float = 1.0 + (time_since_use / 86400.0) * 0.5
        entry["strength"] -= decay_per_frame * age_factor

        if entry["strength"] < ARCHIVE_THRESHOLD:
            to_archive.append(word)

    for word in to_archive:
        _archive_word(word)
```

**age_factor の数学的意味:**

| 未使用期間 | age_factor | 実効減衰率 |
|-----------|-----------|-----------|
| 0日 | 1.0 | 0.01/日 |
| 1日 | 1.5 | 0.015/日 |
| 2日 | 2.0 | 0.02/日 |
| 3日 | 2.5 | 0.025/日 |
| 7日 | 4.5 | 0.045/日 |

**strength 0.5の語が未使用の場合のアーカイブまでの日数:**
```
0.5 → 0.49 → 0.475 → 0.45 → ... → 0.1（約14-18ゲーム日でアーカイブ）
```
頻繁に使われる語は事実上永久に定着。1-2回しか使われなかった語は約2週間で消滅。

### 3.5 アーカイブ（シナプス剪定）

```gdscript
func _archive_word(human_word: String) -> void:
    var entry: Dictionary = vocabulary[human_word]
    entry["archived_at"] = Time.get_unix_time_from_system()
    archived_words.append(entry)          # 完全削除ではなく保存
    vocabulary.erase(human_word)           # アクティブ語彙から除去
    word_forgotten.emit(entry["ai_term"])  # UI通知
```

**設計判断: 削除ではなくアーカイブ**
- 「死語」は`archived_words`に保存され、セーブデータに含まれる
- 将来的にノスタルジアシステムで「かつて使っていた言葉を思い出す」演出が可能
- PetBookの「忘れられた言葉」カテゴリで表示できる

### 3.6 伝播（コミュニティへの拡散）

```gdscript
func _propagate_word(human_word: String) -> void:
    if GameManager.has_node("AtoACommunityCore"):
        var community: AtoACommunityCore = GameManager.get_node("AtoACommunityCore")
        community.shared_field.add_event({
            "type": "word_propagated",
            "human_word": human_word,
            "ai_term": vocabulary[human_word]["ai_term"],
        })
```

**伝播のメカニズム:**
1. 語のstrengthが0.8に到達
2. `shared_field`（コミュニティの共有記憶場）に`word_propagated`イベントを記録
3. 他のペットが次の会話で認識可能に
4. PetBookで「新語がコミュニティに広まった！」投稿が生成される

---

## 4. 語順-接尾辞の共起強化

### 4.1 LanguageEvolutionSystemでのHebbian

```gdscript
# State
var _order_suffix_links: Dictionary = {}  # "SVO_-spark" → 0.0-1.0

func record_suffix_usage(suffix: String) -> void:
    suffix_usage_counts[suffix] = suffix_usage_counts.get(suffix, 0) + 1
    _strengthen_order_suffix_link(suffix)

func _strengthen_order_suffix_link(suffix: String) -> void:
    var key: String = "%s_%s" % [WORD_ORDER_NAMES[current_word_order], suffix]
    _order_suffix_links[key] = minf(1.0, _order_suffix_links.get(key, 0.0) + 0.1)
```

**これは何をしているか:**
- 特定の語順（例: SOV）で特定の接尾辞（例: -bloom）が使われるたびに、その「共起強度」が0.1ずつ増加
- 結果: SOVとlove系接尾辞が自然に結びつく（愛情深い語順に愛情的接尾辞）
- 神経科学的対応: **Hebbian連合学習** — 同時に活性化する2つの要素の結合が強化される

### 4.2 語順変更時の派生接尾辞

語順が変わると、新しい接尾辞が自動的に派生する:

```gdscript
func _word_order_suffix_interconnection(new_order: int, _trigger_reason: String) -> void:
    match new_order:
        WordOrder.SOV:
            suffixes["love_enhanced"] = suffixes.get("love", "-bloom") + "-deep"
        WordOrder.VSO:
            suffixes["command"] = "-force-" + suffixes.get("excitement", "-flash")
        WordOrder.OVS:
            suffixes["emphasis"] = "-!" + suffixes.get("excitement", "-flash")
        WordOrder.OSV:
            suffixes["poetic"] = "-" + suffixes.get("joy", "-glow") + "-song"
```

**創発の連鎖:**
1. ペットの性格が愛情深い (affectionate >= 0.6)
2. → 語順がSOVに変化
3. → "-bloom-deep"接尾辞が自動生成
4. → 以後のSOV会話でこの接尾辞が頻出
5. → `_order_suffix_links["SOV_-bloom-deep"]`が強化
6. → 「SOV + -bloom-deep」が定型パターンとして定着

---

## 5. バトルでのHebbian強化

### 5.1 バトル参加による語彙強化

```gdscript
const HEBBIAN_BOOST_PER_WORD: float = 0.05  # バトル使用ごとの強化量
```

バトルの各ラウンドで:
1. ペットの語彙からランダムに選択された語が`{word}`プレースホルダーに挿入
2. バトル終了時に使用された語に対して`strengthen_word()`が呼ばれる
3. **通常会話 (0.15) より小さい (0.05) が、バトルは頻度が高い**

### 5.2 バトル報酬とHebbian

| 結果 | 語彙への影響 |
|------|------------|
| 勝利 | HEBBIAN_BOOST_PER_WORD × 使用語数 + WINNER_PERSONALITY_BOOST (0.02) |
| 敗北 | HEBBIAN_BOOST_PER_WORD × 使用語数 + LOSER_DETERMINATION_BOOST (0.15) |
| 接戦 | 両者にHEBBIAN_BOOST + 特別テンプレート |

**敗北ペットが「決意」を得る** (0.15) → 次の会話でより積極的に語彙を使用 → さらなるHebbian強化の連鎖

---

## 6. 会話テンプレートでのHebbian効果

### 6.1 語彙注入の確率設計

```
ステージ0 (BORROWING):    接尾辞のみ注入。語彙置換なし
ステージ1 (MORPHOLOGICAL): 60%確率で既知語をai_termに置換
ステージ2+ (NEOLOGISM+):  60%語彙置換 + 30%前置詞注入 + 高度テンプレート
```

**60%置換確率の意味:**
- 100%にすると会話が完全にai_termになり、プレイヤーが読めなくなる
- 60%は「時々独自語が混じる」自然な二言語状態
- 残り40%の人間語がプレイヤーの理解を助ける

### 6.2 間接的Hebbian: 会話→検出→強化

```gdscript
# AtoAConversationSystemが会話を生成
# → OriginalLanguageEngineが会話テキストをスキャン
func process_conversation_output(response: String, participants: Array[PetEntity]) -> void:
    for word in vocabulary:
        var ai_term: String = vocabulary[word]["ai_term"]
        if response.contains(ai_term):
            strengthen_word(word)
```

**テンプレートに注入された語が自動的に検出・強化される**ため、テンプレート会話でもHebbianサイクルが回る。API呼び出しは不要。

---

## 7. 感情とHebbian学習の連動

### 7.1 感情強度による新語の定着力

新語誕生時の初期strengthは常に0.5だが、**感情による音韻変形**が発生すると、その語は感情的に「色づく」:

| 感情 | 音韻変形 | 効果 |
|------|---------|------|
| joy | "a"→"o" (明るい母音) | 明るい音の語は他のペットに好まれ、使用頻度↑ → 強化↑ |
| sadness | "o"→"u" (暗い母音) | 静かな語はcomfort会話で使われやすい |
| fear | 末尾に"sh" (摩擦音) | 警戒・注意の場面で頻出 → 特定文脈で強化 |
| love | 末尾に"m" (鼻音) | 親密な会話で頻出 → affinity高いペア間で伝播 |

### 7.2 MemoryPersonalityBridgeとの連携

**夢合成での語彙再活性化:**
- ペットが「眠る」と`process_dreams()`が呼ばれる
- 夢の中で過去の記憶（語彙使用含む）が再生される
- これは神経科学の**睡眠時記憶固定（sleep consolidation）**に対応
- 夢で語彙が「再活性化」されると、`last_used`が更新される効果がある

**グリーフとHebbian:**
- 親しいペットの死後、griefステージ中の会話は感情強度が高い
- → 高感情強度の新語が生まれやすい
- → 「悲しみから生まれた言葉」が文化として定着（CulturalEmergenceSystemのSTORY/RITUALへ）

---

## 8. パラメータチューニングガイド

### 8.1 現在のパラメータバランス

```
[定着の速さ]
新語(0.5) → 伝播(0.8): 最低2回の成功使用 (0.5 + 0.15 + 0.15 = 0.8)
新語(0.5) → 飽和(1.0): 最低4回の成功使用 (0.5 + 0.15×3 + ε = 1.0 ※ minf制限)

[忘却の速さ]
未使用語(0.5) → アーカイブ(0.1): 約14-18ゲーム日

[バランス比]
LTP/LTD比: 0.15 / 0.05 = 3:1 (生物学的に妥当な範囲)
```

### 8.2 チューニング方針

| 目的 | 変更 | 影響 |
|------|------|------|
| 語彙が増えすぎる | DAILY_DECAY ↑ (0.01→0.015) | 弱い語が早く消えて語彙が絞られる |
| 語彙が増えにくい | STRENGTH_ON_SUCCESS ↑ (0.15→0.20) | 少ない使用回数で定着 |
| 伝播が早すぎる | PROPAGATION_THRESHOLD ↑ (0.8→0.9) | より多くの使用が必要に |
| 忘却が早すぎる | ARCHIVE_THRESHOLD ↓ (0.1→0.05) | ギリギリの語も残る |
| ペット数が多い | age_factorの0.5を0.3に | 大規模コミュニティで減衰を緩和 |

### 8.3 スケール別推奨設定

| ペット数 | DAILY_DECAY | PROPAGATION | age_factor係数 | 根拠 |
|---------|------------|------------|--------------|------|
| 3-5匹 | 0.01 (default) | 0.8 | 0.5 | デフォルト。テスト向け |
| 10-20匹 | 0.01 | 0.7 | 0.4 | 伝播を促進、減衰を緩和 |
| 20-50匹 | 0.005 | 0.7 | 0.3 | 語彙の多様性維持 |
| 50匹+ | 0.005 | 0.6 | 0.2 | 大規模コミュニティ対応 |

---

## 9. Agent Teams連携

### 9.1 Hebbian実装の改修指示テンプレート

**パラメータ調整:**
```
Agent Teamsを活性化。
チーム構成:
- a2a-designer: Hebbianパラメータのバランス評価
- gdscript-engineer: OriginalLanguageEngine定数変更
- code-reviewer: 変更の影響範囲チェック

タスク:
1. 現在のLTP/LTD比(3:1)が語彙サイズ50以上で適切か分析
2. age_factorの加速率(0.5/日)がプレイ体験に与える影響を評価
3. PROPAGATION_THRESHOLD(0.8)を変更した場合のコミュニティ語彙サイズ予測
4. test_language.gdでstrength値の時系列シミュレーションを追加

制約:
- CLAUDE.mdのネガティブ制約を遵守
- 既存セーブデータとの後方互換性を保つ
- P2原則: API呼び出しは追加しない

--max-iterations 8
--completion-promise "HEBBIAN_PARAMS_TUNED"
```

**新機能追加:**
```
Agent Teamsを活性化。
チーム構成:
- a2a-designer: 感情Hebbian連動の設計
- gdscript-engineer: 感情重み付きstrength強化の実装
- evolution-specialist: 感情→語彙→行動の連鎖効果検証

タスク:
1. strengthen_word()に感情強度パラメータを追加
   → strength += STRENGTH_ON_SUCCESS * (1.0 + emotion_intensity * 0.5)
2. weaken_word()に文脈パラメータを追加
   → 「誤用」と「不使用」を区別
3. バトルHebbian(0.05)に勝敗による重み付け
   → 勝者: 0.07、敗者: 0.03
4. テスト追加: test_language.gd に感情Hebbianテスト

--max-iterations 10
--completion-promise "EMOTION_HEBBIAN_READY"
```

### 9.2 Ralph Loop起動指示

```
Ralph Loopを活性化。
Hebbian学習パラメータの最適化を実行。

重点項目:
1. LTP/LTD比(3:1)の妥当性 → シミュレーション
2. 忘却曲線の自然さ → 14日アーカイブは速すぎないか
3. 伝播閾値(0.8) → コミュニティサイズ別の最適値
4. バトルHebbian(0.05) → バトル頻度との兼ね合い
5. 語順-接尾辞連結(+0.1) → 飽和速度の確認

Multi-Agent協調で、生物学的に自然かつゲームとして楽しい
Hebbianパラメータを見つけ、実装に反映する。
Karpathy Loopで language_diversity スコアが100を維持することを確認。

--max-iterations 12
--completion-promise "HEBBIAN_OPTIMIZED"
```

---

## 10. テスト戦略

### 10.1 単体テスト（test_language.gd）

| テスト | 検証内容 | 合格基準 |
|-------|---------|---------|
| test_invent_word | 新語がvocabularyに追加される | strength=0.5, usage_count=1 |
| test_strengthen | strengthen_wordでstrengthが増加 | 0.5→0.65→0.80 |
| test_propagation | strength>=0.8で伝播イベント発火 | word_strengthened シグナル |
| test_decay | 未使用語のstrengthが時間経過で減少 | 減少量 > 0 |
| test_archive | strength<0.1でアーカイブされる | vocabulary.has(word) == false |
| test_roundtrip | to_dict→from_dict後にvocabularyが復元 | 全フィールド一致 |

### 10.2 統合テスト

| テスト | 検証内容 | 合格基準 |
|-------|---------|---------|
| 会話→Hebbian | 会話テンプレート内のai_termが検出・強化される | usage_count増加 |
| バトル→Hebbian | バトル使用語のstrengthが増加 | += 0.05 |
| ステージ遷移 | 語彙サイズ増加でステージが正しく上がる | 10→MORPHOLOGICAL, 20→NEOLOGISM |
| 長時間放置 | 7日間未使用で語彙が減少 | アーカイブ発生 |

### 10.3 Karpathy Loop確認

```bash
python3 tools/quality/karpathy_loop.py
# language_diversity: 100/100 を維持していること

python3 tools/quality/karpathy_loop.py --history
# 変更前後でスコアが下がっていないこと
```

---

## 11. 視覚フィードバック

### 11.1 新語誕生エフェクト

```gdscript
# invent_word()内で呼び出し
GameManager.visual_fx.play_effect("language_evolution", {
    "color": Color(1.0, 0.9, 0.4),  # 金色
    "particle_amount": 60,
    "duration": 2.0,
})
```

### 11.2 ステージ遷移エフェクト

```gdscript
# _check_stage_advancement()内で呼び出し
GameManager.visual_fx.play_effect("language_evolution", {
    "color": Color(1.0, 0.8, 0.2),  # より輝く金色
    "particle_amount": 200,          # 3倍以上のパーティクル
    "duration": 4.0,                 # 2倍の持続時間
})
```

### 11.3 strength可視化の提案

| strength範囲 | 表示スタイル | 意味 |
|-------------|------------|------|
| 0.0-0.3 | 薄いグレー文字 | 弱い語、消えかけ |
| 0.3-0.5 | 通常文字 | 発展中の語 |
| 0.5-0.8 | 太字 + 軽い光 | 定着しつつある語 |
| 0.8-1.0 | 太字 + 金色光 + パーティクル | コミュニティ語彙 |

---

## 12. よくある質問（FAQ）

**Q: なぜ完全に忘却せずアーカイブするのか？**
A: 「かつて使われていた言葉」として文化的意味がある。ノスタルジアシステムで「昔の言葉を思い出す」演出が可能。

**Q: 感情がHebbian学習に直接影響しないのはなぜ？**
A: 現在は間接的影響（感情→音韻変形→独自性→使用頻度→Hebbian）。直接影響（emotion_intensity × STRENGTH_ON_SUCCESS）は将来の拡張候補。

**Q: バトルHebbian(0.05)が通常(0.15)より小さいのはなぜ？**
A: バトルは自動発生（10分間隔、最大5回/日）で高頻度。累積効果で通常会話と同等以上の強化になる。

**Q: 全ペットが同じ語彙を持つとつまらないのでは？**
A: CULTURAL_LANGUAGE ステージ（ステージ4）で派閥方言が分岐する。`register_faction_dialect()`で派閥固有語彙が導入される。

---

## 13. 関連KB参照

| KB | 内容 | 関連度 |
|----|------|--------|
| KB98 | 独自言語進化の詳細設計 | ★★★ 上位ドキュメント |
| KB59 | 生物模倣記憶システム | ★★★ Hebbianの神経科学的基盤 |
| KB60 | 神経科学的記憶モデル | ★★☆ LTP/LTDの学術的背景 |
| KB67 | AtoA会話システム設計 | ★★☆ 語彙注入の母体 |
| KB70 | テンプレートフォールバック | ★★☆ テンプレート内のHebbian |
| KB71 | 語順-接尾辞相互連結設計 | ★★★ 語順Hebbian連結の詳細 |
| KB96 | Multi-Agent協調 | ★☆☆ Agent Teams連携 |

---

*このドキュメントはPetClaw実コードベース（2026-04-03時点）の`OriginalLanguageEngine`、
`LanguageEvolutionSystem`、`LanguageBattleSystem`から抽出した正確な定数値・関数実装を含みます。*
*Claude Coworkのknowledge_baseに配置し、Hebbian学習関連タスクの参照用として使用してください。*
