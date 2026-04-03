# KB101: Hebbian学習の神経科学基礎ガイド（PetClaw独自言語進化向け）
## Hebbian Learning Neuroscientific Foundations for AI Pet Language Evolution
**Version:** 2026-04-03
**対象:** Claude Code / Claude Cowork / Agent Teams
**前提知識:** KB99 (Hebbian実装), KB100 (Hebbian応用例), KB59 (生物模倣記憶), KB60 (神経科学的記憶モデル)

---

## 1. Hebbian学習の神経科学的起源

### 1.1 Donald Hebbの理論（1949）

> "When an axon of cell A is near enough to excite a cell B and repeatedly or
> persistently takes part in firing it, some growth process or metabolic change
> takes place in one or both cells such that A's efficiency, as one of the cells
> firing B, is increased."
> — Donald Hebb, *The Organization of Behavior* (1949)

**簡約形:** "Cells that fire together, wire together."
（一緒に発火する細胞は、つながる）

この原理は、学習と記憶の神経基盤としてシナプス可塑性（Synaptic Plasticity）を初めて理論化した。

### 1.2 歴史的位置づけ

| 年 | 発見・理論 | PetClawへの影響 |
|-----|---------|---------------|
| 1949 | Hebb則の提唱 | 基本原理: 共起する語の結合強化 |
| 1973 | LTPの実験的発見（Bliss & Lømo） | strengthen_word()の実装根拠 |
| 1982 | LTDの発見 | weaken_word()の実装根拠 |
| 1990s | STDP（Spike-Timing-Dependent Plasticity）の発見 | 会話内の語の出現順序の重要性 |
| 2000s | Homeostatic Plasticity（恒常性可塑性） | 語彙サイズの自動調整機構 |
| 2010s | 予測符号化（Predictive Coding）との統合 | テンプレートフォールバックの予測的生成 |
| 2020s | Hebbian + Transformer理論の接点 | AI言語モデルとの対応関係 |

---

## 2. 神経科学的メカニズムの詳細

### 2.1 シナプス可塑性（Synaptic Plasticity）

シナプス可塑性は、ニューロン間の接続強度が経験によって変化する現象。
Hebb則はこの可塑性の最も基本的なルールを記述する。

```
プレシナプスニューロン (A)
    │
    │ シナプス結合（可変強度）
    ▼
ポストシナプスニューロン (B)

A と B が同時に活性化 → 結合が強化 (LTP)
A が活性化しても B が不活性 → 結合が弱化 (LTD)
```

**PetClaw対応:**
```
語A（例: "happy"のai_term）
    │
    │ strength（可変: 0.0-1.0）
    ▼
語B（例: "-spark"接尾辞）

同じ会話で両方が使われる → strength += 0.15 (LTP)
語Aが使われず放置 → strength -= decay × age_factor (LTD + 忘却)
```

### 2.2 LTP（Long-Term Potentiation: 長期増強）

**分子メカニズム:**
1. プレシナプスからグルタミン酸が放出
2. ポストシナプスのNMDA受容体が活性化
3. Ca²⁺イオンがポストシナプスに流入
4. CaMKII（カルシウム/カルモジュリン依存性キナーゼII）が活性化
5. AMPA受容体がシナプス後膜に挿入される
6. → シナプス伝達効率が長期的に向上

**PetClawでのLTP実装:**

| 分子メカニズム | PetClaw対応 | 実装箇所 |
|-------------|------------|---------|
| グルタミン酸放出 | 会話テンプレートでai_termが使用される | `_generate_template_conversation()` |
| NMDA受容体活性化 | `process_conversation_output()`がai_termを検出 | `original_language_engine.gd` |
| Ca²⁺流入 | `strengthen_word()`が呼ばれる | `original_language_engine.gd:182` |
| AMPAR挿入 | `strength += STRENGTH_ON_SUCCESS (0.15)` | Hebbian定数 |
| シナプス効率向上 | 次回の会話でai_termがより選ばれやすくなる | 語彙置換確率（60%） |

```gdscript
# PetClawでのLTP（実コード）
func strengthen_word(human_word: String) -> void:
    if human_word not in vocabulary:
        return
    var entry: Dictionary = vocabulary[human_word]
    entry["usage_count"] += 1                                    # 活性化カウント
    entry["strength"] = minf(1.0, entry["strength"] + STRENGTH_ON_SUCCESS)  # LTP
    entry["last_used"] = Time.get_unix_time_from_system()        # タイムスタンプ
    word_strengthened.emit(entry["ai_term"], entry["strength"])  # シグナル発火
    if entry["strength"] >= PROPAGATION_THRESHOLD:               # 伝播チェック
        _propagate_word(human_word)
```

### 2.3 LTD（Long-Term Depression: 長期抑圧）

**分子メカニズム:**
1. 低頻度のシナプス刺激
2. 低濃度のCa²⁺流入（LTPの場合より少ない）
3. カルシニューリン（タンパク質脱リン酸化酵素）が活性化
4. AMPA受容体がシナプス後膜から除去（エンドサイトーシス）
5. → シナプス伝達効率が長期的に低下

**PetClawでのLTD実装:**

| 分子メカニズム | PetClaw対応 | 実装箇所 |
|-------------|------------|---------|
| 低頻度刺激 | 語が長期間使用されない | `_process_daily_decay()` |
| 低Ca²⁺ | `time_since_use`が増加 | age_factorの計算 |
| AMPAR除去 | `strength -= decay × age_factor` | 毎フレーム処理 |
| シナプス効率低下 | 語が会話で選ばれにくくなる | strength < 0.3 で置換対象外 |
| シナプス消失 | `strength < 0.1` → `_archive_word()` | アーカイブ処理 |

```gdscript
# PetClawでのLTD + 忘却曲線（実コード）
func _process_daily_decay(delta: float) -> void:
    var decay_per_frame: float = DAILY_DECAY * delta / 3600.0    # 基本減衰
    var to_archive: Array[String] = []
    for word in vocabulary:
        var entry: Dictionary = vocabulary[word]
        var time_since_use: float = Time.get_unix_time_from_system() - entry.get("last_used", 0)
        var age_factor: float = 1.0 + (time_since_use / 86400.0) * 0.5  # 加速減衰
        entry["strength"] -= decay_per_frame * age_factor        # LTD
        if entry["strength"] < ARCHIVE_THRESHOLD:                # シナプス剪定
            to_archive.append(word)
    for word in to_archive:
        _archive_word(word)
```

### 2.4 STDP（Spike-Timing-Dependent Plasticity）

**原理:**
ニューロンの発火タイミングの前後関係がシナプス可塑性の方向を決定する。

```
プレシナプス → ポストシナプス（数ms以内）: LTP（強化）
ポストシナプス → プレシナプス（逆順）: LTD（弱化）

    LTP
    ▲
    │    ╱
    │   ╱
    │  ╱
────┼─╱────────── Δt (ms)
    │╱
    │
    ▼
    LTD
```

**PetClawでの対応:**

| STDP要素 | PetClaw実装 | 効果 |
|---------|------------|------|
| 先行発火→強化 | 会話の最初のターンで使われた語がより強化される | `matching_templates.slice(0, 3)`の先頭が優先 |
| タイミング窓 | 同一会話内（6ターン以内）の共起が対象 | `MAX_TURNS_PER_CONVERSATION = 6` |
| 逆順→弱化 | （現在は未実装）将来的に「文脈にそぐわない語の使用」で弱化 | `weaken_word()`の拡張候補 |

**将来的なSTDP拡張の設計案:**
```gdscript
# 将来の拡張候補: 会話内の出現順序による重み付け
func strengthen_with_timing(human_word: String, turn_index: int, total_turns: int) -> void:
    var timing_factor: float = 1.0 - (float(turn_index) / float(total_turns)) * 0.3
    # 会話の早いターンほど強化が大きい（先行発火ボーナス）
    var boost: float = STRENGTH_ON_SUCCESS * timing_factor
    vocabulary[human_word]["strength"] = minf(1.0, vocabulary[human_word]["strength"] + boost)
```

### 2.5 Homeostatic Plasticity（恒常性可塑性）

**原理:**
Hebbianだけでは正のフィードバックループにより、ネットワーク活動が制御不能になる。
恒常性可塑性は全体の活動レベルを一定範囲に保つ安定化機構。

**主なメカニズム:**
- **シナプススケーリング**: 全シナプス強度の比例的な調整
- **メタ可塑性（BCM理論）**: LTPの閾値自体が活動レベルに応じて変動
- **内在的可塑性**: ニューロン自体の興奮性の調整

**PetClawでの恒常性メカニズム:**

| 神経科学メカニズム | PetClaw実装 | 定数 |
|----------------|------------|------|
| シナプススケーリング | `minf(1.0, strength + ...)` — 上限キャップ | 上限: 1.0 |
| メタ可塑性 | age_factorによる減衰加速 — 古い語ほど維持コストが高い | 加速率: 0.5/日 |
| 内在的可塑性 | `ARCHIVE_THRESHOLD` — 弱すぎる語は除去 | 閾値: 0.1 |
| ネットワーク安定化 | ステージ遷移の語彙サイズ閾値 | 10/20/50語で段階的 |

```
恒常性の効果（語彙サイズの自動調整）:

    語彙サイズ
    ▲
    │         ┌──────── 均衡点（20-40語）
    │        ╱│
    │       ╱ │  ← 新語生成（Hebbian LTP）
    │      ╱  │
    │     ╱   │  → 忘却・アーカイブ（LTD + Homeostatic）
    │    ╱    │
    │   ╱     │
    │──╱──────┘
    └──────────────── 時間
```

---

## 3. Ebbinghaus忘却曲線とPetClawの対応

### 3.1 Ebbinghausの実験（1885）

Hermann Ebbinghausは、無意味音節の記憶保持率が時間の対数関数で減少することを発見。

**忘却曲線の公式:**
```
R = e^(-t/S)

R: 保持率（Retention）
t: 経過時間
S: 記憶強度（Stability） — 復習回数で増加
```

### 3.2 PetClawでの忘却曲線の実装

```gdscript
# PetClawの実装（_process_daily_decay内）
decay_per_frame = DAILY_DECAY * delta / 3600.0
age_factor = 1.0 + (time_since_use / 86400.0) * 0.5
strength -= decay_per_frame * age_factor
```

**Ebbinghausとの対応:**

| Ebbinghaus | PetClaw | 対応関係 |
|-----------|---------|---------|
| R (保持率) | strength (0.0-1.0) | 直接対応 |
| t (経過時間) | time_since_use | 秒単位 |
| S (記憶強度) | usage_count × STRENGTH_ON_SUCCESS | 使用回数が多いほど忘れにくい |
| e^(-t/S) | strength -= decay × age_factor | 線形近似（計算効率のため） |

**なぜ指数関数ではなく線形近似か:**
- `_process_daily_decay()`は**毎フレーム実行**される（60fps = 秒間60回）
- 指数関数の計算コストを避け、`delta`ベースの線形減算で近似
- `age_factor`の加速により、結果的にEbbinghausの曲線に似た挙動になる

### 3.3 間隔反復（Spaced Repetition）との対応

Ebbinghausの研究から派生した**間隔反復効果**: 復習の間隔を徐々に広げると記憶が効率的に定着する。

**PetClawでの自然な間隔反復:**

| 復習タイミング | PetClaw対応 | 効果 |
|-------------|------------|------|
| 1回目の復習 | 次のAtoA会話（180秒後） | strength 0.5 → 0.65 |
| 2回目の復習 | バトルでの使用（600秒後） | strength 0.65 → 0.70 |
| 3回目の復習 | ノスタルジアトリガー（数日後） | age_factorリセット + strength回復 |
| 4回目の復習 | 夢合成での再生（睡眠時） | 間接的な記憶固定 |

会話・バトル・ノスタルジア・夢の4つのメカニズムが、異なるタイムスケールで語彙を「復習」する。
これはAnkiのような間隔反復アルゴリズムを、ゲームの自然なイベントで再現している。

---

## 4. 脳領域とPetClawシステムの対応

### 4.1 主要脳領域マッピング

```
┌─────────────────────────────────────────────────────┐
│  大脳皮質（言語野）                                     │
│  = OriginalLanguageEngine + LanguageEvolutionSystem  │
│  語彙・文法の長期保持と処理                              │
├─────────────────────────────────────────────────────┤
│  海馬                                                │
│  = MemoryPersonalityBridge                           │
│  短期→長期記憶の変換、文脈的記憶                         │
├─────────────────────────────────────────────────────┤
│  扁桃体                                              │
│  = PetEmotionSystem                                  │
│  感情的記憶の強化（emotion_intensity → Hebbian boost）  │
├─────────────────────────────────────────────────────┤
│  前頭前皮質                                           │
│  = AtoAConversationSystem                            │
│  会話の計画・文脈判断・テンプレート選択                    │
├─────────────────────────────────────────────────────┤
│  基底核                                              │
│  = LanguageBattleSystem                              │
│  報酬学習・バトル報酬→Hebbian強化                       │
├─────────────────────────────────────────────────────┤
│  小脳                                                │
│  = CulturalEmergenceSystem                           │
│  パターンの自動化・儀式化・伝統化                        │
└─────────────────────────────────────────────────────┘
```

### 4.2 各脳領域の詳細対応

**海馬（MemoryPersonalityBridge）:**

| 海馬の機能 | PetClaw実装 | 関連関数 |
|-----------|------------|---------|
| エピソード記憶の形成 | 会話ログの記録 | `conversation_memory` |
| 短期→長期記憶変換 | strength 0.5 → 0.8+ への上昇 | `strengthen_word()` |
| パターン分離 | 異なるsemantic_fieldへの分類 | `_determine_semantic_field()` |
| パターン完成 | 不完全な入力から語彙を想起 | `process_conversation_output()` |
| 空間記憶 | 環境コンテキストと語彙の紐付け | `context_key = "{emotion}_{env}"` |
| 睡眠時リプレイ | 夢合成での記憶再生 | `_compose_dream()` |

**扁桃体（PetEmotionSystem）:**

| 扁桃体の機能 | PetClaw実装 | 効果 |
|------------|------------|------|
| 恐怖記憶の急速形成 | fear感情での摩擦音付加 | "sh"が追加される |
| 正の感情記憶 | love/joyでの音韻変形 | 明るい母音、鼻音 |
| 記憶の感情的タグ付け | semantic_fieldに感情を含む | `"food_joy"`, `"general_sadness"` |
| ストレス応答 | グリーフ中の急速な語彙形成 | 高感情会話での新語 |

**基底核（LanguageBattleSystem）:**

| 基底核の機能 | PetClaw実装 | 効果 |
|------------|------------|------|
| 報酬予測誤差 | バトル勝敗の結果 | 勝: personality+0.02, 負: determination+0.15 |
| ドーパミン報酬信号 | HEBBIAN_BOOST_PER_WORD | +0.05/語 |
| 習慣の形成 | バトルでの語彙の反復使用 | 定着促進 |
| 運動学習の類推 | バトル「技術」としての言語能力 | vocabulary/grammar/creativity/emotionスコア |

---

## 5. 2026年現在の神経科学知見との対応

### 5.1 予測符号化（Predictive Coding）

**理論:**
脳は常に次の入力を「予測」し、予測誤差のみを上位に伝達する（Karl Friston, 2005-）。

**PetClawでの対応:**

| 予測符号化要素 | PetClaw実装 |
|-------------|------------|
| トップダウン予測 | テンプレートフォールバック — 過去のパターンから会話を「予測生成」 |
| ボトムアップ誤差 | Claude API応答 — テンプレートからの逸脱が「新情報」 |
| 予測誤差の最小化 | 語彙置換（60%確率） — 既知語で「予測を埋める」 |
| 予測モデルの更新 | Hebbian強化 — 成功パターンの学習 |

### 5.2 情報ボトルネック理論

**理論:**
深層学習における情報ボトルネック（Tishby, 2015）は、ネットワークが入力の冗長性を圧縮しながら、タスクに必要な情報のみを保持することを示す。

**PetClawでの対応:**

| ボトルネック要素 | PetClaw実装 |
|---------------|------------|
| 情報圧縮 | 人間語→独自語への変換（"beautiful"→"be-kri"） |
| 冗長性削除 | ステージ1(MORPHOLOGICAL)での短縮 |
| タスク関連情報の保持 | 感情・文脈に関連するsemantic_fieldの保持 |
| ボトルネック層 | LanguageStage — 各ステージが異なる圧縮レベル |

### 5.3 社会的学習と言語獲得

**理論:**
Tomasello（2003）の「使用基盤モデル」: 言語は社会的相互作用を通じて構築される。

**PetClawでの対応:**

| 社会的学習要素 | PetClaw実装 |
|-------------|------------|
| 共同注意 | AtoA会話のトピック共有 |
| 模倣学習 | process_conversation_output() — 他者の語を検出して自分も使う |
| 文化的伝達 | PROPAGATION_THRESHOLD — 語がコミュニティに伝播 |
| 社会的強化 | affinityが高いペア間での語彙共有が加速 |
| 世代間伝達 | 交配時の文化的知識継承 |

---

## 6. PetClawのHebbian定数の神経科学的根拠

### 6.1 各定数の生物学的妥当性

| PetClaw定数 | 値 | 神経科学的根拠 | 妥当性 |
|------------|-----|-------------|--------|
| STRENGTH_ON_SUCCESS | 0.15 | LTPの初期相は数分で発現。1回の共活性化で測定可能な強化 | ✅ 適切 |
| STRENGTH_ON_FAILURE | -0.05 | LTDはLTPより小さい（非対称性は実験的に確認済み） | ✅ 適切（3:1比は生物学的範囲内） |
| DAILY_DECAY | 0.01 | Ebbinghausの忘却曲線で1日後の保持率は約33%低下 | ✅ やや緩やか（ゲーム体験優先） |
| ARCHIVE_THRESHOLD | 0.1 | シナプス剪定は発達期に活発。成体でも不要シナプスは除去される | ✅ 適切 |
| PROPAGATION_THRESHOLD | 0.8 | 頻繁に使用されるシナプスは構造変化を起こし永続化 | ✅ 適切 |
| age_factor加速 | 0.5/日 | 長期不使用でのシナプス弱化は加速する（「用不用の法則」） | ✅ 適切 |
| HEBBIAN_BOOST_PER_WORD | 0.05 | ドーパミン報酬信号による追加的LTPは通常LTPより弱い | ✅ 適切 |
| 初期strength | 0.5 | 新しいシナプスは中程度の強度で形成 | ✅ 適切 |

### 6.2 改善の余地がある領域

| 領域 | 現状 | 神経科学的に理想的 | 拡張案 |
|------|------|----------------|--------|
| STDP（タイミング依存性） | 未実装 | 発火順序による強化/弱化の差 | turn_indexによる重み付け |
| メタ可塑性（BCM） | 固定閾値 | LTP閾値が活動レベルに応じて変動 | 語彙サイズに応じたSTRENGTH_ON_SUCCESSの動的調整 |
| タグ&キャプチャ | 未実装 | 弱いLTPが後の強い刺激で永続化 | ノスタルジアによる弱い語の「救出」 |
| ドーパミン変調 | 固定値 | 報酬予測誤差に比例した変調 | バトル勝敗予測からのboost調整 |
| 睡眠リプレイ | 間接的 | シャープウェーブリプルによる記憶固定 | 夢合成時のstrength直接強化 |

---

## 7. Agent Teams連携: 神経科学的改善の実装指示

### 7.1 STDPの導入

```
Agent Teamsを活性化。
チーム構成:
- a2a-designer: STDP（タイミング依存可塑性）の言語進化への適用設計
- gdscript-engineer: strengthen_wordにturn_index重み付けを追加
- code-reviewer: 既存テストとの互換性確認

タスク:
1. strengthen_word()にオプショナルなtiming_factorパラメータ追加
   → 会話の早いターンで使われた語ほど強化量が大きい
   → timing_factor = 1.0 - (turn_index / total_turns) * 0.3
2. weaken_word()に文脈不適合パラメータ追加
   → 「語が使われたが文脈にそぐわない」場合の弱化
3. 既存のto_dict/from_dictに影響がないことを確認
4. test_language.gdにSTDPテスト追加

制約:
- 既存のHebbian定数は変更しない
- 新パラメータはオプショナル（デフォルトで既存動作を維持）
- P2: API呼び出しは追加しない

--max-iterations 8
--completion-promise "STDP_IMPLEMENTED"
```

### 7.2 メタ可塑性（BCM理論）の導入

```
Agent Teamsを活性化。
チーム構成:
- a2a-designer: BCM理論（Bienenstock-Cooper-Munro）の語彙サイズ適応設計
- gdscript-engineer: 動的STRENGTH_ON_SUCCESSの実装
- evolution-specialist: 語彙サイズ変動のシミュレーション

タスク:
1. STRENGTH_ON_SUCCESSを語彙サイズに応じて動的に調整
   → 語彙が少ない時: 0.20（新語が定着しやすい）
   → 語彙が多い時: 0.10（過剰な語彙増加を抑制）
   → 公式: success_rate = 0.15 * (30.0 / max(vocabulary.size(), 15))
2. DAILY_DECAYも同様に調整（語彙が多い時に減衰を加速）
3. Karpathy Loopでlanguage_diversity=100を維持することを確認

--max-iterations 8
--completion-promise "BCM_METAPLASTICITY_READY"
```

### 7.3 睡眠リプレイの強化

```
Agent Teamsを活性化。
チーム構成:
- a2a-designer: 睡眠時記憶固定メカニズムの設計
- gdscript-engineer: MemoryPersonalityBridge.process_dreams()でHebbian直接強化
- code-reviewer: 強化量のバランス確認

タスク:
1. process_dreams()で夢に登場した語彙のstrengthを直接+0.05
   → DREAM_REPLAY_BOOST = 0.05（バトルHebbian同等）
2. 夢の内容にai_termが含まれる確率を30%に設定
3. 夢合成時にlast_usedをリセット（ノスタルジアと同等の効果）
4. to_dict/from_dictに新定数を含めない（コード内定数で十分）

--max-iterations 6
--completion-promise "SLEEP_REPLAY_HEBBIAN_READY"
```

---

## 8. Ralph Loop統合

### 8.1 神経科学的妥当性の自動検証

```
Ralph Loopを活性化。
PetClawのHebbian実装が神経科学的に妥当かを自動検証。

検証項目:
1. LTP/LTD比（3:1）が語彙の安定的な成長を実現しているか
2. 忘却曲線がEbbinghaus的な形状になっているか
3. 恒常性メカニズム（上限キャップ+age_factor）が語彙爆発を防いでいるか
4. 伝播閾値（0.8）が「十分な反復使用」を要求しているか
5. バトルHebbian（0.05）が報酬学習として適切な強度か

Agent Teams構成:
- a2a-designer: 各パラメータの神経科学的妥当性評価
- gdscript-engineer: パラメータ変更のシミュレーション
- code-reviewer: 変更の安全性確認

Karpathy Loop検証:
- language_diversity: 100 を維持
- code_quality: 悪化しないこと

--max-iterations 12
--completion-promise "NEUROSCIENCE_VALIDATION_COMPLETE"
```

---

## 9. よくある質問（FAQ）

### Q: PetClawのHebbianは本当の脳のHebb則と同じか？

**A:** 本質的な原理（共起する要素の結合強化、不使用の弱化）は同じ。ただし:
- 脳のHebbianはアナログ（連続的な電気信号）、PetClawはデジタル（離散的なイベント）
- 脳のシナプス数は約100兆、PetClawの語彙は数十〜数百
- 脳のHebb則は無意識・自動的、PetClawは`_process(delta)`による明示的計算
- **しかし、創発的な効果（パターンの自己組織化、使用頻度による定着）は十分に再現されている**

### Q: なぜ`exp()`を使わず線形近似しているのか？

**A:** パフォーマンス上の理由。`_process_daily_decay()`は60fpsで毎フレーム実行され、全語彙を走査する。`exp()`は`-=`より約10倍のCPUコストがかかる。語彙サイズ50の場合、毎秒3000回の`exp()`計算を避けている。

### Q: Hebbianだけで十分か？他の学習則は必要か？

**A:** 現在の実装では十分。ただし将来的には:
- **STDP**: 会話内のタイミングで重み付け → 自然な語順定着
- **BCMメタ可塑性**: 語彙サイズに応じた動的閾値 → 自動バランス
- **ドーパミン変調**: バトル報酬による条件付き強化 → ゲーミフィケーション

これらはKB99のセクション6.2で拡張候補として記載済み。

---

## 10. 関連KB参照

| KB | 内容 | 関連度 |
|----|------|--------|
| KB99 | Hebbian学習の実装詳細 | ★★★ 実装コードの詳細 |
| KB100 | Hebbian学習の応用例 | ★★★ 具体的シーンでの適用 |
| KB98 | 独自言語進化の全体設計 | ★★☆ 言語スタックの文脈 |
| KB59 | 生物模倣記憶システム | ★★★ 海馬・記憶の生物学的基盤 |
| KB60 | 神経科学的記憶モデル | ★★★ LTP/LTDの学術的詳細 |
| KB66 | Moltbook風自律コミュニティ | ★☆☆ 社会的学習の文脈 |
| KB71 | 語順-接尾辞相互連結 | ★★☆ Hebbian連合学習の実例 |

---

## 11. 参考文献

| 著者 | 年 | 文献 | PetClawとの関連 |
|------|-----|------|---------------|
| Hebb, D.O. | 1949 | *The Organization of Behavior* | Hebb則の原典 |
| Bliss & Lømo | 1973 | "Long-lasting potentiation..." *J. Physiol.* | LTPの実験的発見 |
| Ebbinghaus, H. | 1885 | *Über das Gedächtnis* | 忘却曲線の原典 |
| Markram et al. | 1997 | STDP発見 *Science* | タイミング依存可塑性 |
| Turrigiano et al. | 1998 | シナプススケーリング *Nature* | 恒常性可塑性 |
| Bienenstock et al. | 1982 | BCM理論 | メタ可塑性の数理モデル |
| Tomasello, M. | 2003 | *Constructing a Language* | 使用基盤の言語獲得 |
| Friston, K. | 2005 | 予測符号化理論 | テンプレートフォールバックの理論的基盤 |
| Tishby, N. | 2015 | 情報ボトルネック理論 | 言語の情報圧縮機能 |

---

*このドキュメントはPetClaw実コードベース（2026-04-03時点）のHebbian実装と*
*神経科学文献の対応関係を体系的に整理したものです。*
*Claude Coworkのknowledge_baseに配置し、言語進化の神経科学的妥当性の参照用として使用してください。*
