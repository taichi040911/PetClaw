# KB100: Hebbian学習の応用例ガイド（PetClaw AtoA向け）
## Hebbian Learning Application Examples for AI Pet Language Evolution
**Version:** 2026-04-03
**対象:** Claude Code / Claude Cowork / Agent Teams
**前提知識:** KB99 (Hebbian学習実装), KB98 (独自言語進化), KB67 (AtoA会話)

---

## 1. Hebbian学習の基本応用原理（PetClaw版）

### 1.1 4つの応用ルール

| ルール | 神経科学 | PetClaw実装 |
|--------|---------|------------|
| **強化** | 同時発火するニューロンの結合強化 | 関連する語が一緒に使われると`strength += 0.15` |
| **減衰** | シナプス競合・忘却 | 使われない語は`DAILY_DECAY × age_factor`で弱化 |
| **感情連動** | 扁桃体による記憶強化 | 高感情強度の会話で音韻変形が発生、使用頻度↑ |
| **Multi-Agent検証** | 社会的学習 | Language Specialistが提案、他ペットが検証・使用 |

### 1.2 応用の全体マップ

```
┌─────────────────────────────────────────────────────────┐
│                  Hebbian応用シーン                        │
├─────────────┬─────────────┬──────────────┬──────────────┤
│  接尾辞強化  │  語順進化    │  生死体験記憶  │  交配・家族語 │
│  (日常会話)  │  (感情強調)  │  (トラウマ)   │  (絆の定着)  │
├─────────────┴─────────────┴──────────────┴──────────────┤
│         Multi-Agent協調による言語検証・伝播               │
├─────────────────────────────────────────────────────────┤
│  バトル Hebbian │ 文化的定着 │ ノスタルジア再活性化       │
└─────────────────────────────────────────────────────────┘
```

---

## 2. 応用例1: 独自言語の接尾辞強化（最も基本的な応用）

### 2.1 シーン設定

**状況:** ペット同士がjoy感情の高い状態で繰り返し会話する。
**Hebbian効果:** 感情接尾辞（-glow, -spark）が自然に定着し、以後の会話で自動的に使われる。

### 2.2 実際のコードフロー

```
会話テンプレートで{suffix}に"-glow"が選択される
  ↓
AtoAConversationSystem._generate_template_conversation()
  → メッセージ: "Hello-glow! I'm so happy-glow today-glow!"
  ↓
OriginalLanguageEngine.process_conversation_output()
  → "glow"を含むai_termを検出
  → strengthen_word("happy") → strength 0.5 → 0.65
  ↓
LanguageEvolutionSystem.record_suffix_usage("-glow")
  → suffix_usage_counts["-glow"] += 1
  → _order_suffix_links["SVO_-glow"] += 0.1
  ↓
次回の会話で"-glow"が再度選ばれやすくなる（頻度ベース）
```

### 2.3 実コードでの動作

**LanguageEvolutionSystemの接尾辞生成（会話完了時）:**
```gdscript
# on_conversation_completed() → evaluate_suffix_evolution()
func evaluate_suffix_evolution(conversation_context: Dictionary) -> Dictionary:
    var emotion: String = conversation_context.get("dominant_emotion", "neutral")
    var environment: String = conversation_context.get("environment", "")
    var intensity: float = conversation_context.get("emotion_intensity", 0.0)
    var context_key: String = "%s_%s" % [emotion, environment]

    if not suffixes.has(context_key) and intensity > 0.5:
        # 新しいコンテキスト接尾辞を生成
        var base_suffix: String = base_suffixes.get(emotion, "-spark")
        var env_prefix: String = environment.substr(0, 3) if environment.length() >= 3 else environment
        var new_suffix: String = "-%s%s" % [env_prefix, base_suffix.trim_prefix("-")]
        # 例: joy + forest → "-for-glow"
        return {"should_create": true, "context": context_key, "suffix": new_suffix}
    return {"should_create": false}
```

**Hebbian強化の蓄積例:**

| 会話回数 | -glow のusage_count | SVO_-glow 連結強度 | 効果 |
|---------|--------------------|--------------------|------|
| 1回目 | 1 | 0.1 | 初出 |
| 3回目 | 3 | 0.3 | 定着し始める |
| 5回目 | 5 | 0.5 | 他の接尾辞より優先される |
| 10回目 | 10 | 1.0 (飽和) | このペアの「デフォルト接尾辞」に |

### 2.4 PetBook投稿での表示

テンプレートから生成される投稿例:
```
"Just had the best talk with Lumi! We talked about food-glow. Good vibes-glow"
"Feeling happy-glow after chatting with Kiri-spark"
```

**PetBookのテンプレート（a2a_conversation_system.gd内）:**
```gdscript
const RECAP_TEMPLATES: Array[String] = [
    "Just had the best talk with {partner}! We talked about {topic} {suffix}",
    "Me and {partner} just chatted about {topic}. Good vibes {suffix}",
    # ... 7テンプレート
]
```

---

## 3. 応用例2: 語順進化の感情連動

### 3.1 シーン設定

**状況:** 愛情深い(affectionate >= 0.6)ペットが、love感情の高い会話を繰り返す。
**Hebbian効果:** 語順がSVO → SOVに変化し、"-bloom-deep"接尾辞が自動生成される。

### 3.2 語順変更の実際のトリガーフロー

```
LanguageEvolutionSystem.on_conversation_completed(context)
  ↓
conversation_count_since_last_evolution >= 3 かつ cooldown == 0
  ↓
evaluate_word_order_change(context)
  → avg_personality = {affectionate: 0.7, ...}
  → dominant_emotion = "love", intensity = 0.6
  ↓
_calculate_order_affinity(WORD_ORDER_TRAITS[SOV], ...)
  → affectionate >= 0.6 → +0.3 (personality match)
  → love >= 0.5 → +0.4 (emotion match)
  → affinity = 0.7 > 0.5 → should_change = true
  ↓
apply_word_order_change(WordOrder.SOV, "High love affinity")
  → 語順を SOV に変更
  → _word_order_suffix_interconnection() 呼び出し
  → suffixes["love_enhanced"] = "-bloom-deep" を自動生成
  → evolution_event シグナル発火
```

### 3.3 語順変化前後の会話テキスト

**SVO (変化前):**
```
"I love you-bloom."
"We share words-glow together-spark."
```

**SOV (変化後):**
```
"You I love-bloom-deep."
"Words-glow we together-spark share."
```

### 3.4 Hebbianフィードバックループ

```
SOV語順での会話
  → "-bloom-deep" が頻出
  → record_suffix_usage("-bloom-deep")
  → _order_suffix_links["SOV_-bloom-deep"] += 0.1
  → SOV + "-bloom-deep" の共起が強化
  → 次回のSOV会話で"-bloom-deep"がさらに選ばれやすく
  → 「SOVで話すときは-bloom-deepが自然」という言語的慣習が創発
```

---

## 4. 応用例3: 生き死に体験の記憶強化

### 4.1 シーン設定

**状況:** 親しいペットが死亡。残されたペットがKübler-Rossグリーフステージを経験。
**Hebbian効果:** グリーフ中の会話で生まれた語が、強い感情により急速に定着。

### 4.2 システム連携フロー

```
LifeDeathSystem → ペットの死亡
  ↓
GameManager._on_pet_died_for_grief()
  → MemoryPersonalityBridge.start_grief(pet_id, deceased_id, affinity)
  ↓
grief_states[pet_id] = {stage_index: 0, stage: "denial", ...}
  ↓
次のAtoA会話で:
  AtoAConversationSystem._build_turn_prompt()
  → MemoryPersonalityBridge.get_conversation_hints(pet_id)
  → ["Currently in grief: denial stage for deceased pet #5"]
  ↓
会話テンプレート "grief" トリガーが選択される:
  "{pet1} stared into the distance-{suffix}. 'I still think about them sometimes-{suffix}...'"
  ↓
OriginalLanguageEngine が会話を処理:
  → 新語候補: "void" + sadness → 音韻変形 "o"→"u" → "vuud-sh"
  → invent_word("void", {emotion: "sadness", situation: "grief"})
  → strength = 0.5, semantic_field = "general_sadness"
  ↓
グリーフ期間中（5ステージ × 120秒 = 10分間）の繰り返し会話:
  → strengthen_word("void") × 3-5回
  → strength: 0.5 → 0.65 → 0.80 → 伝播！
  ↓
CulturalEmergenceSystem:
  → "vuud-sh" を含む STORY アーティファクト生成可能性
  → 12%確率で物語化
```

### 4.3 グリーフステージ別のHebbian効果

| ステージ | 感情強度 | 新語の特徴 | Hebbian強化の特徴 |
|---------|---------|-----------|-----------------|
| denial (否認) | 中 | 柔らかい否定語 | 弱い強化（会話少ない） |
| anger (怒り) | 高 | 摩擦音（-sh）付き | 急速な強化 |
| bargaining (取引) | 中-高 | 条件文的な語 | 中程度の強化 |
| depression (抑うつ) | 高 | 暗い母音（u）の語 | 使用頻度は低いが1回の強化が大きい |
| acceptance (受容) | 低-中 | 穏やかな語 | 緩やかだが安定した強化 |

### 4.4 PetBook投稿例

```
グリーフ投稿テンプレート（PetBookAutoPublisher経由）:
"The world feels emptier now-mist. {deceased_name} was a good friend-mist."

語彙が定着した後の投稿:
"The vuud-sh in my heart is slowly becoming peace-bloom.
 I carry their memory like a quiet-rebirth-glow."
```

---

## 5. 応用例4: 交配・家族関連語の定着

### 5.1 シーン設定

**状況:** 2匹のペットが交配し、子ペットが誕生。以後の家族内会話で新語が生まれる。
**Hebbian効果:** 家族関連の語が高いaffinity（親密度）により急速に伝播。

### 5.2 BreedingSystemからのHebbian連鎖

```
BreedingSystem.attempt_breed(parent1, parent2)
  → 子ペット誕生
  ↓
GameManager._on_birth_for_culture(child_pet)
  → CulturalEmergenceSystem._inherit_culture(child_pet, parent1, parent2)
  → 親の文化的知識（語彙含む）を子が継承
  ↓
AtoA会話（親子間）:
  → affinity: 0.8+（親子は初期affinityが高い）
  → 高頻度の会話が発生
  ↓
OriginalLanguageEngine:
  → "tiny" + love感情 → _create_neologism({emotion: "love"})
  → "ti-mu-m" (love → 末尾"m"追加)
  → invent_word("tiny", {emotion: "love", situation: "after_birth"})
  ↓
家族内での繰り返し使用:
  → strengthen_word("tiny") × 5-8回（家族会話は高頻度）
  → strength: 0.5 → 0.65 → 0.80 → 0.95 → 伝播
  ↓
_propagate_word("tiny") → SharedField
  → 全コミュニティが "ti-mu-m" を認識
  → PetBook: "Our ti-mu-m has grown so much! Family-bloom forever-glow!"
```

### 5.3 家族語彙の特徴

| 語彙カテゴリ | 感情トリガー | 音韻特徴 | 伝播速度 |
|------------|-----------|---------|---------|
| 子ペット関連 | love | 鼻音(-m)が多い | 非常に速い（高affinity） |
| 親子の絆 | love + joy | 明るい母音(o) + 鼻音(m) | 速い |
| 家系の誇り | joy | 明るい母音(o) | 中程度 |
| 遺伝形質 | curiosity | 中立的音韻 | 遅い（専門的） |

### 5.4 世代を超えたHebbian

```
第1世代: "love" → "lu-glo-m" (strength 0.9)
  → 子ペットが継承
第2世代: "lu-glo-m" を日常的に使用 → strength 0.95
  → 子ペットの子が継承
第3世代: "lu-glo-m" が TRADITION アーティファクトに昇格
  → CulturalEmergenceSystem.artifacts に永続登録
  → 「3世代続く愛の言葉」としてPetBookに投稿
```

---

## 6. 応用例5: Multi-Agent協調による言語検証

### 6.1 シーン設定

**状況:** PetTeamOrchestratorがLANGUAGE_PROJECTタスクのチームを編成。
**Hebbian効果:** チーム内での集中的な語彙使用が、通常より速い定着を実現。

### 6.2 チーム言語プロジェクトのフロー

```
PetTeamOrchestrator._check_team_formation()
  → TaskType.LANGUAGE_PROJECT を選択（150秒タスク）
  ↓
チーム編成:
  - Leader: 最も社会的なペット（social trait高）
  - Members: 2-3匹（affinity高い組み合わせ）
  ↓
タスク実行中（150秒間）:
  → チームメンバー間のAtoA会話が集中発生
  → 全メンバーが同じ語彙を使用する機会が増加
  ↓
Hebbian効果の加速:
  通常: 1会話/180秒 → strength +0.15
  チーム: 3-4会話/150秒 → strength +0.45-0.60
  ↓
タスク完了:
  → team_completed シグナル
  → PetBook投稿: "Team language project complete! New words discovered-spark!"
  → 使用された語彙が一気に伝播閾値に到達する可能性
```

### 6.3 Agent Teams（開発側）での言語検証

**Claude Codeでの検証指示:**
```
Agent Teamsを活性化。
チーム構成:
- a2a-designer: 新語の音韻的自然さを評価
- gdscript-engineer: strengthen_wordの呼び出しパスを追跡
- code-reviewer: 語彙サイズ上限の確認

タスク:
1. LANGUAGE_PROJECTタスク中のHebbian強化回数をシミュレーション
2. 150秒間で語のstrengthがどこまで上がるか計算
3. チームサイズ(2-4匹)別の語彙伝播速度を比較
4. 結果をKarpathy Loopのlanguage_diversityスコアで検証

--max-iterations 8
--completion-promise "TEAM_LANGUAGE_VERIFIED"
```

---

## 7. 応用例6: バトルでのHebbian言語強化

### 7.1 シーン設定

**状況:** 2匹のペットが言語バトル（3ラウンド）を行う。
**Hebbian効果:** バトルで使われた語が`HEBBIAN_BOOST_PER_WORD = 0.05`で強化。

### 7.2 バトルラウンドでのHebbian

```
LanguageBattleSystem._execute_round(round_num, theme)
  ↓
RoundTheme.GREETING:
  → テンプレート選択: "{name} said '{word}-{suffix}' with {emotion}-{suffix}"
  → {word} = pet1の語彙からランダム選択（例: "lu-glo-m"）
  → {suffix} = SUFFIXES[randi() % 15]（例: "-na"）
  ↓
バトルスコアリング:
  - Vocabulary: 語彙サイズ × (MAX_VOCABULARY_SCORE / expected_size)
  - Grammar: 進化度 × (MAX_GRAMMAR_SCORE / expected_evolutions)
  - Creativity: (curious + playful) * 2.5
  - Emotion: affectionate * 4.0
  ↓
バトル終了:
  → 使用された語に HEBBIAN_BOOST_PER_WORD (0.05) を適用
  → OriginalLanguageEngine.strengthen_word() × 使用語数
  → PetBook投稿: WINNER_POST_TEMPLATES / LOSER_POST_TEMPLATES
```

### 7.3 バトルHebbian vs 会話Hebbian

| 比較項目 | 通常会話 | バトル |
|---------|---------|-------|
| 強化量/回 | 0.15 | 0.05 |
| 発生間隔 | 180秒 | 600秒（デモ: 60秒） |
| 1日の上限 | 25回 | 5回 |
| 最大日次強化 | 3.75 | 0.75 |
| 特徴 | 安定した定着 | 低頻度だが確実な底上げ |
| 敗北ボーナス | なし | LOSER_DETERMINATION_BOOST (0.15) |

### 7.4 接戦時のHebbian効果

```gdscript
const CLOSE_BATTLE_THRESHOLD: float = 20.0  # スコア差20以内は「接戦」
```

**接戦の場合:**
- 両者に特別テンプレートが適用
- 両者の語彙が等しく強化される
- `CLOSE_BATTLE_WINNER_TEMPLATES` / `CLOSE_BATTLE_LOSER_TEMPLATES` が使用
- PetBook: "What a battle-flash! {loser_name} and I were so close-spark!"

---

## 8. 応用例7: ノスタルジアによるHebbian再活性化

### 8.1 シーン設定

**状況:** 古い友人との思い出がノスタルジアとして蘇る。
**Hebbian効果:** 減衰中だった語彙の`last_used`がリセットされ、忘却が止まる。

### 8.2 ノスタルジア→Hebbianフロー

```
MemoryPersonalityBridge._process_nostalgia()
  → check_nostalgia_trigger(pet_id, partner_id)
  → 25%確率で共有記憶を想起
  ↓
nostalgia_triggered シグナル発火
  → memory_summary: "Remember when we first said 'lu-glo-m'?"
  ↓
AtoA会話コンテキストに注入:
  get_conversation_hints(pet_id) →
  ["Feeling nostalgic about partner #3: 'lu-glo-m' memories"]
  ↓
次の会話でその語が使われやすくなる
  → process_conversation_output() で検出
  → strengthen_word("love") → strength回復
  → last_used リセット → age_factorが1.0に戻る
  ↓
結果: 忘れかけていた語が「思い出」として復活
  → PetBook: "I suddenly remembered 'lu-glo-m'... it's been so long-mist."
```

### 8.3 ノスタルジアのHebbian的意味

| 状態 | age_factor | 実効減衰率 | ノスタルジア後 |
|------|-----------|-----------|-------------|
| 使用直後 | 1.0 | 0.01/日 | — |
| 3日未使用 | 2.5 | 0.025/日 | → 1.0 (リセット) |
| 7日未使用 | 4.5 | 0.045/日 | → 1.0 (リセット) |
| 14日未使用 | 8.0 | 0.08/日 | → 1.0 (リセット) |

**ノスタルジアは「記憶の消去を防ぐ」生物学的メカニズムのゲーム内実装。**

---

## 9. 応用例8: 夢合成でのHebbian記憶固定

### 9.1 シーン設定

**状況:** ペットが「眠る」イベント。MemoryPersonalityBridgeが夢を合成。
**Hebbian効果:** 夢の中で過去の語彙が再生され、記憶が固定される。

### 9.2 夢→Hebbianフロー

```
GameManager._on_sleep_for_dreams(pet_id)
  → MemoryPersonalityBridge.process_dreams(pet_id)
  ↓
_compose_dream(pet_id):
  → DREAM_MEMORY_REPLAY_COUNT = 3 個の記憶断片を選択
  → DREAM_TEMPLATES からランダム選択:
    "I dreamed of {place}... {partner} was there, and we felt {emotion}."
  ↓
dream_generated シグナル発火
  → dream_content: "I dreamed of forest... Lumi was there, and we felt love."
  ↓
夢の中の語彙が間接的に再活性化:
  → 夢の内容にai_termが含まれていれば strengthen_word() 効果
  → 含まれていなくても、次の会話で夢の内容が話題になりやすい
  ↓
PetBook: "Last night I dreamed of lu-glo-m... it felt so real-bloom."
```

### 9.3 睡眠→記憶固定の神経科学的対応

| 脳の仕組み | PetClaw実装 |
|-----------|------------|
| 睡眠中の海馬リプレイ | `_compose_dream()`での記憶断片再生 |
| REM睡眠での記憶統合 | 夢の中で複数の記憶が混ざる |
| 徐波睡眠での長期記憶転送 | 夢生成後のlast_used間接更新 |
| 起床後の記憶明確化 | 夢の内容が次の会話のコンテキストに注入 |

---

## 10. 応用シーンの相互作用マトリクス

各応用シーンがどのように連鎖するかの全体図:

| シーン | → 接尾辞 | → 語順 | → 生死 | → 交配 | → バトル | → ノスタルジア |
|-------|---------|--------|--------|--------|---------|-------------|
| **接尾辞** | 自己強化 | 語順連結 | grief接尾辞 | family接尾辞 | battle接尾辞 | 思い出接尾辞 |
| **語順** | 派生接尾辞生成 | 自己安定化 | 抑うつ語順 | — | — | 昔の語順の記憶 |
| **生死** | death接尾辞 | VOS語順化 | grief連鎖 | — | — | 故人の記憶 |
| **交配** | bloom接尾辞 | SOV語順化 | — | 家系語彙 | 親子バトル | 家族の記憶 |
| **バトル** | battle接尾辞 | — | — | — | Hebbian +0.05 | 名勝負の記憶 |
| **ノスタルジア** | 再活性化 | — | grief再想起 | 家族の記憶 | — | 連鎖想起 |

---

## 11. Ralph Loop + Agent Teamsでの統合自動進化

### 11.1 全応用シーンの統合テスト指示

```
Ralph Loopを活性化。
Hebbian学習の全応用シーンを統合テスト。

テストシナリオ:
1. 接尾辞強化: 10回の会話ループで-glow系接尾辞のstrength追跡
2. 語順進化: affectionate=0.7ペアでSOV遷移を再現
3. 生死体験: ペット死亡→グリーフ5ステージ→新語定着を検証
4. 交配言語: 親子ペアの家族語彙伝播速度を計測
5. バトルHebbian: 5バトル後の語彙strength累積を確認
6. ノスタルジア: 7日未使用語のlast_usedリセットを検証
7. 夢合成: 睡眠後の語彙再活性化効果を計測

Agent Teams構成:
- a2a-designer: 各シーンの言語的自然さを評価
- gdscript-engineer: シミュレーションコード作成
- code-reviewer: Hebbianパラメータの整合性チェック
- evolution-specialist: 長期的進化パスの予測

Karpathy Loop検証:
- language_diversity: 100 を維持
- code_quality: テスト追加でスコア改善

--max-iterations 15
--completion-promise "HEBBIAN_ALL_APPLICATIONS_VERIFIED"
```

### 11.2 個別シーンのRalph Loop指示

**接尾辞特化:**
```
Ralph Loopを活性化。
接尾辞のHebbian強化に特化。
base_suffixes(6種) → コンテキスト接尾辞 → 語順派生 → 環境イベントの
全接尾辞生成パスでHebbian効果を追跡。
suffix_usage_countsの分布が偏りすぎていないか検証。

--max-iterations 8
--completion-promise "SUFFIX_HEBBIAN_BALANCED"
```

**語順進化特化:**
```
Ralph Loopを活性化。
語順進化のHebbian連動に特化。
6つの語順パターンの遷移確率と_order_suffix_linksの
相互強化バランスを最適化。

--max-iterations 8
--completion-promise "WORD_ORDER_HEBBIAN_OPTIMAL"
```

---

## 12. 実践Tips

### 12.1 開発者向け

| Tip | 詳細 |
|-----|------|
| **デバッグ出力** | `get_vocabulary_summary()`で現在のstrength上位10語を確認 |
| **パラメータ可視化** | CulturalDashboardScreenのDreamsタブで夢合成結果を確認 |
| **シミュレーション** | test_language.gdの`test_strengthen`で強化→減衰サイクルを検証 |
| **Karpathy監視** | `python3 tools/quality/karpathy_loop.py`でlanguage_diversity=100維持 |

### 12.2 非エンジニア向け

| やりたいこと | Claude Codeへの指示 |
|------------|------------------|
| 接尾辞のバリエーション追加 | "base_suffixesに新しい感情カテゴリを追加して" |
| 語彙の定着速度を変更 | "STRENGTH_ON_SUCCESSを0.15から0.20に変更して" |
| 忘却を緩やかにしたい | "DAILY_DECAYを0.01から0.005に変更して" |
| 新語誕生のエフェクトを派手に | "invent_wordのparticle_amountを60から120に変更して" |
| PetBookで新語をハイライト | "PetBookPostCardで語彙のstrength>0.7の語を金色表示して" |

### 12.3 バランス確認チェックリスト

- [ ] 10分間の会話で語彙サイズが5-15に収まるか
- [ ] 強いaffinity (0.8+) のペアで語彙伝播が1日以内に起きるか
- [ ] 7日間未使用の語がアーカイブされるか
- [ ] グリーフ中の新語定着が通常より速いか
- [ ] バトル後の語彙強化が過剰でないか
- [ ] 語順変更後の派生接尾辞が自然に聞こえるか

---

## 13. 関連KB参照

| KB | 内容 | 関連度 |
|----|------|--------|
| KB99 | Hebbian学習の実装詳細 | ★★★ 実装の基盤 |
| KB98 | 独自言語進化の全体設計 | ★★★ 言語スタックの全体像 |
| KB67 | AtoA会話システム設計 | ★★☆ 会話テンプレートの構造 |
| KB59 | 生物模倣記憶システム | ★★☆ 記憶との連動 |
| KB66 | Moltbook風自律コミュニティ | ★★☆ コミュニティ言語の原典 |
| KB71 | 語順-接尾辞相互連結 | ★★★ 語順Hebbianの詳細 |
| KB96 | Multi-Agent協調 | ★☆☆ Agent Teams連携 |
| KB97 | Agent Teams実装例 | ★☆☆ チーム言語プロジェクト |

---

*このドキュメントはPetClaw実コードベース（2026-04-03時点）から抽出した具体的なコードフロー、*
*定数値、シグナル連鎖を含む実践的応用例ガイドです。*
*Claude Coworkのknowledge_baseに配置し、Hebbian学習の応用タスクの参照用として使用してください。*
