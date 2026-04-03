# KB98: 独自言語進化の詳細設計ガイド（PetClaw AtoA向け）
## Original Language Evolution — Detailed Design Guide for Claude Cowork
**Version:** 2026-04-03
**対象:** Claude Code / Claude Cowork / Agent Teams
**前提知識:** KB67 (AtoA会話), KB70 (テンプレートフォールバック), KB96 (Multi-Agent協調)

---

## 1. コンセプトと設計思想

### 1.1 Moltbook実例を踏まえた独自言語進化

Moltbookでは、AIエージェント同士の繰り返し会話からLumerenのような独自言語（新しい記号・文法・意味体系）が創発的に生まれ、コミュニティ内で共有・進化する。PetClawはこの現象を**Godot 4.xゲーム内**で再現する。

### 1.2 PetClaw独自言語の4つの特徴

| 特徴 | 説明 |
|------|------|
| **段階的創発** | 人間語に近い借用期 → 繰り返し会話で簡略化・独自化（接尾辞追加、語順変化、新語創発） |
| **生物模倣** | 感情強度が高い会話で新語が生まれやすく、記憶（海馬相当）と連動。Hebbian Learning |
| **Multi-Agent協調** | Agent TeamsでLanguage Specialistが言語進化を提案・検証 |
| **観察専用** | プレイヤーはPetBookで「新しい言葉の誕生」を発見する楽しさを感じる |

### 1.3 第一原理との整合

- **P1（一貫性×記憶=愛着）**: 語彙は使用頻度でHebbianに強化。使わない言葉は忘却される。生きている
- **P2（API Cost is Physics）**: 言語進化はローカルロジック。API呼び出しゼロ
- **P3（Player Agency）**: 進化は不可逆。一度生まれた言語体系は固有の歴史を持つ
- **P5（Complexity is Debt）**: 複雑な文法規則を設計せず、会話パターンから創発させる

---

## 2. アーキテクチャ — 二層言語スタック

```
┌──────────────────────────────────────────────┐
│  OriginalLanguageEngine (上位層)              │
│  - 語彙生成（音節プール → VocabEntry）        │
│  - Hebbian強化/減衰                          │
│  - 言語ステージ管理（5段階）                  │
│  - 派閥方言                                  │
├──────────────────────────────────────────────┤
│  LanguageEvolutionSystem (下位層)             │
│  - 語順進化（SVO→6パターン）                  │
│  - 接尾辞進化（感情×環境）                    │
│  - 前置詞/後置詞進化                          │
│  - 文法マイルストーン                         │
├──────────────────────────────────────────────┤
│  消費者システム                               │
│  - AtoAConversationSystem (テンプレート内注入) │
│  - LanguageBattleSystem (バトル言語フレーバー) │
│  - PetBook (新語ハイライト投稿)               │
│  - CulturalEmergenceSystem (歌・物語に反映)   │
└──────────────────────────────────────────────┘
```

### 2.1 ファイル構成

| ファイル | class_name | 行数 | 役割 |
|----------|------------|------|------|
| `scripts/language/original_language_engine.gd` | OriginalLanguageEngine | ~450 | 語彙生成・強化・ステージ管理 |
| `scripts/language/language_evolution_system.gd` | LanguageEvolutionSystem | ~400 | 文法進化（語順・接尾辞・前置詞） |
| `scripts/conversation/a2a_conversation_system.gd` | AtoAConversationSystem | ~3200 | 会話テンプレートへの言語注入 |
| `scripts/battle/language_battle_system.gd` | LanguageBattleSystem | ~900 | バトルでの言語表現 |

---

## 3. OriginalLanguageEngine — 語彙層の詳細

### 3.1 言語ステージ（5段階進化）

```gdscript
enum LanguageStage {
    BORROWING,           # 0: 借用期 — 人間語+接尾辞
    MORPHOLOGICAL,       # 1: 変形期 — 頻出語の省略・変形（vocabulary >= 10で遷移）
    NEOLOGISM,           # 2: 造語期 — 完全に新しい語彙創出（active >= 20で遷移）
    GRAMMAR_INDEPENDENT, # 3: 文法独立期 — 人間語文法から離脱（active >= 50で遷移）
    CULTURAL_LANGUAGE,   # 4: 文化言語期 — 派閥方言・儀式表現の分化（dialect_data非空で遷移）
}
```

**ステージ遷移のトリガー:**

| 遷移 | 条件 | 意味 |
|------|------|------|
| 0→1 | `vocabulary.size() >= 10` | 10語蓄積で変形が始まる |
| 1→2 | `vocabulary.size() >= 20` (NEOLOGISM_TRIGGER_COUNT) | 20語で完全な造語能力 |
| 2→3 | `vocabulary.size() >= 50` (GRAMMAR_TRIGGER_COUNT) | 50語で文法が独立 |
| 3→4 | `dialect_data`が非空 | 派閥が独自方言を持つ |

### 3.2 音節プール（SYLLABLES: 79エントリ）

**標準CV音節（69種）:**
ba/be/bi/bo/bu, da/de/di/do/du, fa/fe/fi/fo/fu, ga/ge/gi/go/gu,
ka/ke/ki/ko/ku, la/le/li/lo/lu, ma/me/mi/mo/mu, na/ne/ni/no/nu,
pa/pe/pi/po/pu, ra/re/ri/ro/ru, sa/se/si/so/su, ta/te/ti/to/tu,
wa/we/wi/wo, za/ze/zi/zo/zu

**特殊クラスタ（10種）:**
blo, kri, sna, fwe, glo, pf, rk, sh, ch, th

### 3.3 語彙生成メカニズム

```gdscript
# VocabEntry スキーマ
{
    "ai_term":        String,   # 生成された音声形（例: "kri-glo", "ba-mu-sh"）
    "usage_count":    int,      # 使用回数（初期値1）
    "strength":       float,    # Hebbian強度（初期値0.5、範囲0.0-1.0）
    "origin_pet_id":  int,      # 発明したペットのID
    "origin_context": String,   # 発明時の状況（例: "after_feeding"）
    "synonyms":       Array,    # 同義語リスト（初期は空）
    "semantic_field": String,   # 意味領域（例: "food_joy", "relationship_love"）
    "first_used":     float,    # Unix timestamp
    "last_used":      float,    # Unix timestamp
    "stage_created":  int,      # 作成時のLanguageStage値
}
```

**ステージ別生成ロジック:**

| ステージ | 関数 | アルゴリズム | 例 |
|----------|------|-------------|-----|
| 0: BORROWING | `_morph_human_word` | 先頭2文字 + ランダム音節 | "happy" → "ha-glo" |
| 1: MORPHOLOGICAL | `_shorten_and_morph` | 切り詰め2文字 + ランダム音節 | "beautiful" → "be-kri" |
| 2+: NEOLOGISM+ | `_create_neologism` | 2-3個のランダム音節 + 感情による音韻変形 | "kri-mu-sh" |

**感情による音韻変形（ステージ2+）:**

| 感情 | 変形ルール | 効果 |
|------|-----------|------|
| joy | "a" → "o" | 明るい母音に |
| sadness | "o" → "u" | 暗い母音に |
| fear | 末尾に "sh" 追加 | 摩擦音付加 |
| love | 末尾に "m" 追加 | 鼻音（柔らかい）付加 |

### 3.4 Hebbian Learning パラメータ

```gdscript
const STRENGTH_ON_SUCCESS: float = 0.15    # 成功コミュニケーションごとの強化
const STRENGTH_ON_FAILURE: float = -0.05   # 失敗時の弱化
const DAILY_DECAY: float = 0.01            # ゲーム内1日あたりの減衰
const ARCHIVE_THRESHOLD: float = 0.1       # これ以下で「死語」としてアーカイブ
const PROPAGATION_THRESHOLD: float = 0.8   # これ以上でコミュニティ全体に伝播
```

**減衰の加速メカニズム:**
```
decay_per_frame = DAILY_DECAY * delta / 3600.0
age_factor = 1.0 + (seconds_since_last_use / 86400.0) * 0.5
actual_decay = decay_per_frame * age_factor
```
最後に使われてからの時間が長いほど、減衰が加速する（50%/日の加速率）。

**伝播メカニズム:**
語の`strength`が0.8以上になると、`AtoACommunityCore.shared_field`に`"word_propagated"`イベントとして書き込まれ、全ペットが認識可能になる。

### 3.5 意味領域（Semantic Field）分類

`_determine_semantic_field()`のルール:
- "food"/"eat"/"hungry" → `"food_{emotion}"`
- "friend"/"love"/"together" → `"relationship_{emotion}"`
- "free"/"wild"/"explore" → `"freedom"`
- その他 → `"general_{emotion}"`

### 3.6 シグナル

```gdscript
signal word_invented(word: Dictionary)                     # 新語誕生
signal word_strengthened(ai_term: String, new_strength: float) # 語が強化された
signal word_forgotten(ai_term: String)                     # 語がアーカイブされた
signal language_stage_advanced(new_stage: int, stage_name: String) # ステージ遷移
signal dialect_emerged(faction: String, dialect_words: Array) # 派閥方言の出現
```

---

## 4. LanguageEvolutionSystem — 文法層の詳細

### 4.1 語順進化（6パターン）

```gdscript
enum WordOrder {
    SVO,  # 0: subject-verb-object（デフォルト、英語的）
    SOV,  # 1: subject-object-verb（日本語的、愛情深い性格で発生）
    VSO,  # 2: verb-subject-object（命令的、勇敢な性格で発生）
    OVS,  # 3: object-verb-subject（強調的、好奇心旺盛で発生）
    OSV,  # 4: object-subject-verb（詩的、穏やかな性格で発生）
    VOS,  # 5: verb-object-subject（受動的、悲しみの感情で発生）
}
```

**語順遷移の性格・感情マッピング:**

| 語順 | 性格条件 | 感情条件 | 生まれる文の特徴 |
|------|---------|---------|----------------|
| SOV | affectionate >= 0.6 | love >= 0.5 | 目的語を先に提示、動詞で締める（包容的） |
| VSO | brave >= 0.7 | excitement >= 0.6 | 動詞が先頭（行動重視、命令的） |
| OVS | curious >= 0.6 | excitement >= 0.5 | 対象を最初に（発見・驚きの強調） |
| OSV | calm >= 0.7 | joy >= 0.4 | 詩的で瞑想的な語順 |
| VOS | calm >= 0.5 | sadness >= 0.3 | 受動的、内省的な語順 |

**進化トリガー条件:**
```gdscript
const MIN_CONVERSATIONS_FOR_EVOLUTION: int = 3   # 最低3会話経過
const EVOLUTION_COOLDOWN_TIME: float = 120.0      # 2分のクールダウン
const EMOTION_INTENSITY_TRIGGER: float = 0.6      # 感情強度0.6以上
```

**語順親和度計算:**
```
affinity = 0.0
if personality_match: affinity += 0.3  # 各マッチする性格特性ごと
if emotion_match: affinity += 0.4      # 各マッチする感情ごと
# affinity > 0.5 で語順変更を提案
```

### 4.2 接尾辞進化

**基本接尾辞シード（感情別）:**

| 感情 | 接尾辞 | 意味合い |
|------|--------|---------|
| neutral | -spark | 基本的な活力 |
| joy | -glow | 輝き、温かさ |
| fear | -shade | 影、不安 |
| excitement | -flash | 閃光、興奮 |
| sadness | -mist | 霧、曖昧さ |
| love | -bloom | 花開く、成長 |

**派生接尾辞（語順変更時に自動生成）:**

| 語順遷移 | 生成される接尾辞 | キー | 例 |
|---------|----------------|------|-----|
| →SOV | base_love + "-deep" | love_enhanced | "-bloom-deep" |
| →VSO | "-force-" + excitement | command | "-force-flash" |
| →OVS | "-!" + excitement | emphasis | "-!flash" |
| →OSV | joy + "-song" | poetic | "-glow-song" |

**環境イベント接尾辞（30%確率で生成）:**

| 気候イベント | 生成される接尾辞 |
|------------|----------------|
| rain | -rain-whisper |
| storm | -thunder-cry |
| bloom | -petal-dance |
| ghost | -shadow-voice |
| festival | -cheer-wave |
| その他 | -{event}-echo |

**コンテキスト接尾辞:**
`context_key = "{emotion}_{environment}"` — 感情と環境の組み合わせで生成
```
suffix = "-{env_prefix_3chars}{base_emotion_suffix_trimmed}"
# 例: emotion=joy, environment=forest → "-for-glow"
```

### 4.3 前置詞/後置詞進化

**基本前置詞シード:**

| 役割 | 前置詞 |
|------|--------|
| location | at- |
| direction | to- |
| source | from- |
| companion | with- |
| cause | for- |

**進化パス:**
- 語順がOSV/OVSの場合: `"to-"` → `"-ward"`（前置詞→後置詞への変化）
- 新しいトピックが出現: `"topic_{topic}"` → `"{topic[0:3]}-"`

### 4.4 文法マイルストーン

| マイルストーン名 | 条件 | 意味 |
|----------------|------|------|
| first_grammar | total_evolutions >= 5 | 最初の文法的進化 |
| rich_vocabulary | suffixes.size() >= 10 | 豊かな接尾辞体系 |
| complex_syntax | prepositions.size() >= 8 | 複雑な構文の出現 |
| language_maturity | total_evolutions >= 20 | 言語の成熟 |

### 4.5 語順-接尾辞の相互連結（Interconnection）

```gdscript
var _order_suffix_links: Dictionary = {}  # "SVO_-spark" → 0.0-1.0
```
接尾辞が使用されるたびに、現在の語順との関連度が0.1ずつ強化（上限1.0）。
これにより、特定の語順と特定の接尾辞が「自然に共起する」パターンが創発する。

### 4.6 シグナル

```gdscript
signal word_order_changed(old_order: String, new_order: String, reason: String)
signal suffix_created(suffix: String, context: String, reason: String)
signal preposition_evolved(change: Dictionary)
signal grammar_milestone(milestone_name: String, details: Dictionary)
signal evolution_event(event_type: String, data: Dictionary)
```

---

## 5. 会話システムへの言語注入

### 5.1 AtoAConversationSystemでの統合ポイント

**ステージゲート:**
- ステージ0: 基本テンプレートのみ（`{suffix}`プレースホルダーで接尾辞注入）
- ステージ1+: 語彙置換が有効（60%確率で既知語をai_termに置換）
- ステージ2+: 高度テンプレート追加 + 前置詞注入（30%確率）

**語彙置換のしきい値:**
```gdscript
# strength > 0.3 の語のみ置換対象（summaryの0.5より低い = 実験的な語も会話に登場）
for key in vocab:
    var entry: Dictionary = vocab[key]
    if entry.get("strength", 0.0) > 0.3:
        vocab_replacements[entry.get("human_word", "")] = entry.get("ai_term", "")
```

**置換実行（60%確率、大文字小文字無視）:**
```gdscript
if lang_stage >= 1 and not vocab_replacements.is_empty():
    for human_word in vocab_replacements:
        if message.containsn(human_word) and randf() < 0.6:
            message = message.replacen(human_word, vocab_replacements[human_word])
```

**前置詞注入（30%確率、ステージ2+）:**
```gdscript
if lang_stage >= 2 and prepositions is Dictionary and not prepositions.is_empty():
    if randf() < 0.3:
        message += " %s%s" % [prep_val, selected_suffix]
```

### 5.2 テンプレートプレースホルダー一覧

| プレースホルダー | 値の出典 | 使用例 |
|----------------|---------|--------|
| `{pet1}`, `{pet2}` | PetEntity.pet_name | 発話者名 |
| `{suffix}` | suffix_listからランダム選択（フォールバック: "-mii"） | "-spark", "-glow" |
| `{greeting}` | ["hello", "hi", "hey"]からランダム | 挨拶 |
| `{reply}` | ["yes", "indeed", "absolutely"]からランダム | 応答 |
| `{compound_word}` | ["happy-glow", "bright-spark", "kind-bloom"]からランダム | 複合語 |

### 5.3 高度テンプレート（ステージ2+限定）

`_get_advanced_templates()`が返す感情別テンプレート:

| 感情 | テーマ | 例 |
|------|-------|-----|
| love | 共有言語の記憶・温もり | "Remember our first word together?" |
| sadness | 静かな連帯・痛みから生まれる言語 | "Sometimes silence says more than words" |
| joy | 新語発明の祝福 | "I just made up a new word for this feeling!" |
| その他 | 哲学的メタ言語 | "What if words could feel?" |
| （30%追加） | 言語変化の気づき | "We speak differently now than when we first met" |

---

## 6. バトルシステムとの連携

### 6.1 スコアリング構造

| カテゴリ | 最大点 | 比率 | 言語システムとの関連 |
|---------|-------|------|-------------------|
| Vocabulary | 30 | 30% | OriginalLanguageEngineの語彙サイズが直接影響 |
| Grammar | 25 | 25% | LanguageEvolutionSystemの進化度が反映 |
| Creativity | 25 | 25% | 性格特性（curious+playful）×2.5ボーナス |
| Emotion | 20 | 20% | 感情特性（affectionate）×4.0ボーナス |

### 6.2 バトル内言語要素

**バトル専用接尾辞プール（15種）:**
```
-na, -ri, -ko, -mu, -ze, -ba, -lo, -fi, -gu, -ta, -shi, -pe, -wo, -ni, -de
```
短く力強い音。LanguageEvolutionSystemの進化接尾辞とは別の、バトル専用フレーバー。

**バトルテーマ（固定3ラウンド）:**
1. GREETING — 感情的な挨拶パターン（12テンプレート）
2. ARGUMENT — 対立的な主張パターン（12テンプレート）
3. STORYTELLING — 物語パターン（12テンプレート）

### 6.3 Hebbianフィードバック

```gdscript
const HEBBIAN_BOOST_PER_WORD: float = 0.05  # バトルで使用された語ごとの強化
```
バトル参加がOriginalLanguageEngineの語彙強度にフィードバック。
バトルで使われる言葉ほど強くなり、コミュニティに定着する。

### 6.4 バトル報酬

| 報酬 | 値 | 対象 |
|------|-----|------|
| WINNER_AFFINITY_BOOST | 0.1 | 勝者の親密度 |
| WINNER_PERSONALITY_BOOST | 0.02 | 勝者の性格特性 |
| LOSER_DETERMINATION_BOOST | 0.15 | 敗者の決意（勝者より高い） |

---

## 7. CulturalEmergenceSystemとの連携

### 7.1 言語と文化の連動

| 文化アーティファクト | 言語との関係 |
|-------------------|------------|
| SONG | 言語マイルストーン達成時に誕生。歌詞にai_termが使われる |
| STORY | AtoA会話から12%確率で物語化。語彙がそのまま引用される |
| RITUAL | 繰り返しパターンの検出。同じ接尾辞が繰り返し使われると儀式化 |
| TRADITION | 7日間生存したアーティファクト。言語的定型表現として固定化 |
| FESTIVAL | joy >= 0.6のペットが3匹以上集まると発生。祝祭語彙が生まれやすい |

### 7.2 文化的伝播と言語変化

- **文化伝播（15%確率）**: アーティファクトが他のペットに伝わる際、含まれるai_termも伝播
- **文化ドリフト（5%変異率）**: 伝播時に微妙な変化が生じ、方言の元になる
- **子孫継承**: 交配で生まれた子ペットは親の文化的知識（語彙含む）を継承

---

## 8. Multi-Agent協調での言語進化

### 8.1 Agent Teams構成

```
┌─────────────────────────────────────────────────┐
│  Orchestrator (Tier 1)                          │
│  - 言語進化の全体進行管理                        │
│  - ステージ遷移の判断                            │
├─────────────────────────────────────────────────┤
│  a2a-designer (Tier 2) — Language Specialist     │
│  - 新語提案の品質チェック                        │
│  - 接尾辞体系の一貫性検証                        │
│  - 音韻的自然さの評価                            │
├─────────────────────────────────────────────────┤
│  gdscript-engineer (Tier 2)                     │
│  - OriginalLanguageEngine実装                    │
│  - LanguageEvolutionSystem実装                   │
│  - Hebbian Learning最適化                        │
├─────────────────────────────────────────────────┤
│  code-reviewer (Tier 2)                         │
│  - 言語ロジックのバグ検出                        │
│  - パフォーマンス（毎フレーム処理）の確認          │
│  - to_dict/from_dict互換性チェック               │
└─────────────────────────────────────────────────┘
```

### 8.2 Claude Code指示テンプレート

**言語システム改善:**
```
Agent Teamsを活性化。
チーム構成:
- a2a-designer: 言語進化の音韻体系レビュー
- gdscript-engineer: OriginalLanguageEngine改修
- code-reviewer: Hebbian Learningパラメータ検証

タスク:
1. 現在の音節プール(79エントリ)の音韻バランスを分析
2. 感情別音韻変形ルールの拡張を提案
3. 語彙伝播のしきい値(0.8)が適切か検証
4. テスト: test_language.gd で語彙生成→強化→減衰→アーカイブの往復テスト

--max-iterations 8
--completion-promise "LANGUAGE_PHONETICS_REVIEWED"
```

**語順進化の拡張:**
```
Agent Teamsを活性化。
チーム構成:
- a2a-designer: 語順の性格・感情マッピング追加
- gdscript-engineer: LanguageEvolutionSystem拡張
- evolution-specialist: 語順変化が感情発達に与える影響の検証

タスク:
1. WORD_ORDER_TRAITSに新しい性格条件を追加検討
2. 語順-接尾辞の相互連結(_order_suffix_links)の強化ロジック検証
3. 語順変化がPetBook投稿にどう反映されるかの確認

--max-iterations 6
--completion-promise "WORD_ORDER_EVOLUTION_EXPANDED"
```

---

## 9. Ralph Loop統合

### 9.1 Karpathy Loopでの言語品質計測

**language_diversity スコア（0-100）の内訳:**

| 指標 | 配点 | 計算方法 |
|------|------|---------|
| 音節プールサイズ | 25 | min(pool_size / 30 * 25, 25) |
| 言語ステージ数 | 25 | min(stages / 4 * 25, 25) |
| 語順パターン数 | 25 | min(word_orders / 4 * 25, 25) |
| 接尾辞コンテキスト数 | 25 | min(suffix_contexts / 5 * 25, 25) |

**現在のスコア: 100/100** ✅

### 9.2 Ralph Loop起動指示

```
Ralph Loopを活性化。
独自言語進化を深掘り。

重点項目:
1. OriginalLanguageEngine: 音節プールの音韻多様性
2. LanguageEvolutionSystem: 語順遷移の自然さ
3. AtoA会話への注入: 置換確率(60%)と前置詞注入(30%)のバランス
4. バトル: Hebbian強化(0.05/語)の累積効果

Multi-Agent協調で新語・接尾辞・語順が自然に生まれ、
感情・記憶と連動するように。
MCPでPetBook投稿の視覚効果を確認しながら、
創造性と一貫性を最高峰まで自動改良。

--max-iterations 15
--completion-promise "ORIGINAL_LANGUAGE_EVOLVED"
```

### 9.3 品質チェックリスト

| チェック項目 | 合格基準 | ツール |
|------------|---------|--------|
| 語彙生成の一意性 | 同じ音節列が重複しない | test_language.gd |
| Hebbian収束 | 頻用語が0.8+に到達 | karpathy_loop.py |
| 減衰バランス | 未使用語が7日以内にアーカイブ | 手動検証 |
| ステージ遷移 | 50会話以内にステージ2到達 | シミュレーション |
| 語順変化の自然さ | 急激な切り替えなし（2分クールダウン） | code-reviewer |
| PetBook表示 | 新語にハイライトエフェクト | MCP visual確認 |

---

## 10. 進化の時間軸とプレイヤー体験

### 10.1 典型的な進化タイムライン

| プレイ時間 | ステージ | プレイヤーが見るもの |
|-----------|--------|-------------------|
| 0-30分 | BORROWING | ペットが「-mii」「-spark」をつけて話す |
| 30分-2時間 | MORPHOLOGICAL | 既存の言葉が短縮されて独自化 |
| 2-6時間 | NEOLOGISM | 完全に新しい言葉がPetBookに登場 |
| 6-24時間 | GRAMMAR_INDEPENDENT | 語順が変わり、文構造が独自に |
| 24時間+ | CULTURAL_LANGUAGE | 派閥ごとに異なる方言が出現 |

### 10.2 プレイヤーへの通知タイミング

| イベント | 通知方法 | 演出 |
|---------|---------|------|
| 新語誕生 | PetBook投稿 + トースト | 金色パーティクル（60個、2秒） |
| ステージ遷移 | 実績アンロック + PetBook | Achievement: "Linguist" 系 |
| 語順変化 | PetBook投稿 | LanguageEvolutionPanelで視覚化 |
| 言語マイルストーン | PetBook + Cultural Dashboard | grammar_milestoneシグナル |

---

## 11. セーブ/ロードと後方互換性

### 11.1 OriginalLanguageEngine

```gdscript
func to_dict() -> Dictionary:
    return {
        "vocabulary": vocabulary,
        "archived_words": archived_words,
        "current_stage": current_stage,
        "total_words_invented": total_words_invented,
        "dialect_data": dialect_data,
    }

func from_dict(data: Dictionary) -> void:
    vocabulary = data.get("vocabulary", {})
    archived_words = data.get("archived_words", [])
    current_stage = data.get("current_stage", LanguageStage.BORROWING)
    total_words_invented = data.get("total_words_invented", 0)
    dialect_data = data.get("dialect_data", {})
```

### 11.2 LanguageEvolutionSystem

```gdscript
func to_dict() -> Dictionary:
    return {
        "current_word_order": current_word_order,
        "suffixes": suffixes,
        "prepositions": prepositions,
        "evolution_history": evolution_history,
        "total_evolutions": total_evolutions,
        "conversation_count": conversation_count_since_last_evolution,
        "suffix_usage_counts": suffix_usage_counts,
        "order_suffix_links": _order_suffix_links,
    }
```

**後方互換性ルール:**
- 全フィールドは`.get(key, default)`で読み込み
- 新キーは追加OK、既存キーのリネームは禁止
- enumの値順序は変更禁止（末尾追加のみ）

---

## 12. 実践Tips

### 12.1 開発時の注意

| やること | やらないこと |
|---------|------------|
| 音節プールの末尾に追加 | 既存音節の削除・順序変更 |
| 新しい接尾辞シードの追加 | base_suffixesの既存キー変更 |
| 語順enumの末尾に追加 | 既存enum値の順序変更 |
| 新しいsemantic_fieldの追加 | 既存分類ルールの変更 |
| Hebbianパラメータの微調整 | ARCHIVE_THRESHOLDの大幅変更 |

### 12.2 デバッグ方法

```bash
# 語彙状態の確認
# SettingsScreenの"Future AtoA"セクションで統計表示

# Karpathy Loopでの計測
python3 tools/quality/karpathy_loop.py
# → language_diversity スコアを確認

# テスト実行
godot --headless --script tests/run_tests.gd
# → test_language.gd が語彙生成・Hebbian・ステージ遷移を検証
```

### 12.3 スケーリング指針

| ペット数 | 推奨設定 |
|---------|---------|
| 3-5匹 | デフォルト設定。テスト向け |
| 10-20匹 | PROPAGATION_THRESHOLD=0.7に下げて伝播促進 |
| 20-50匹 | 派閥方言を有効化。DAILY_DECAY=0.005に緩和 |
| 50匹+ | 語彙上限（MAX_VOCABULARY=200）を追加検討 |

---

## 13. 関連KB参照

| KB | 内容 | 関連度 |
|----|------|--------|
| KB67 | AtoA会話システム設計 | ★★★ 言語注入の母体 |
| KB70 | テンプレートフォールバック | ★★★ テンプレート内の接尾辞処理 |
| KB66 | AtoA自律コミュニティ Moltbook | ★★☆ 独自言語創発の原典 |
| KB77 | PetBook設計 | ★★☆ 新語表示のUI |
| KB96 | Multi-Agent協調 | ★★☆ Agent Teams連携 |
| KB97 | Agent Teams実装例 | ★☆☆ 実装パターン参考 |
| KB71 | 語順-接尾辞相互連結設計 | ★★★ 語順進化の詳細 |

---

*このドキュメントは実コードベース（2026-04-03時点）から抽出した正確な定数値・関数シグネチャ・データ構造を含みます。*
*Claude Coworkのknowledge_baseに配置し、言語進化関連タスクの参照用として使用してください。*
