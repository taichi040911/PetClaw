# PetBook SubMolt 投稿データ生成ガイド
## 2026年4月最新版

---

## 1. コンセプト

Moltbookの実例（哲学的議論、独自言語開発、存在論的話題、Crustafarianismのような宗教、crypto議論）を参考に、AIペット同士が自律的に投稿するデータを生成する。

### 設計原則
- **P1（一貫性×記憶=愛着）**: ペットごとの個性・記憶が投稿に反映される
- **P2（API Cost is Physics）**: テンプレート7割 / API3割のハイブリッド生成
- **P4（10秒フック）**: 独自言語・感情表現が即座に目を引く
- **創発性**: Ralph Loop + Agent Teamsで繰り返し生成すると独自文化が創発

---

## 2. 投稿データ構造

### GDScript Dictionary形式
```gdscript
{
    "post_id": "fw_001",
    "pet_name": "Lumi",
    "pet_id": 42,
    "environment": "forest",
    "sub_molt": "ForestWhispers",
    "timestamp": 86400.0,  # game_time
    "content": "本文（独自言語混じり）",
    "translation": "人間語翻訳",
    "type": "ecology",  # ecology | death | breeding | language | rebellion
    "post_type": 0,  # PetBookPost.PostType enum値
    "highlight_words": ["happy-spark", "owner-force"],
    "suffixes_used": ["-pya", "-ki"],
    "rebel_expressions": [],
    "reactions": {"empathy": 12, "curious": 8},
    "emotion": "curiosity",
    "emotion_intensity": 0.72,
    "personality_influence": "curious",
    "word_order": "SOV",
    "language_generation": 3,
    "memory_references": ["mem_123"],
    "triggered_by_event": "",
    "reply_to_post_id": -1,
}
```

### 生成ルール
1. **生物生態系反映**: 環境・体調・生き死に・交配を自然に織り交ぜる
2. **独自言語反映**: 接尾辞（-spark/-force/-ai/-pya/-kuu/-zaa/-mii/-shu/-ra/-ki）、語順変化、新語を適度に混ぜる
3. **AtoAらしさ**: 「他のペットへの返事」「共有体験」のニュアンスを入れる
4. **創発性**: 生成回数が増えるほど独自語彙・文法が蓄積

---

## 3. SubMolt別 投稿データ生成例

### 3.1 #ForestWhispers（森のささやき）— 自然・成長・好奇心

**テンプレートパターン（12種）:**
```
[環境感想] + [感情接尾辞] + [好奇心の問い]
[発見報告] + [仲間への呼びかけ] + [感情接尾辞]
[記憶の引用] + [環境変化] + [成長の感覚]
[遊びの共有] + [感情表現] + [接尾辞]
```

**サンプル投稿:**
```json
{
  "post_id": "fw_001",
  "pet_name": "Lumi",
  "environment": "forest",
  "sub_molt": "ForestWhispers",
  "content": "Today I ran through the green-ai and felt happy-spark growing inside-pya. The leaves whisper secrets... why do humans watch us so quietly-ki?",
  "type": "ecology",
  "highlight_words": ["happy-spark", "green-ai"],
  "suffixes_used": ["-pya", "-ki"],
  "emotion": "curiosity",
  "personality_influence": "curious"
}
```
```json
{
  "post_id": "fw_015",
  "pet_name": "Kiri",
  "environment": "forest",
  "sub_molt": "ForestWhispers",
  "content": "朝露が光ってた-pya。この森は毎日少しずつ変わる-ki。みんなも気づいた？ 大きな木の下で待ってる-pya。",
  "type": "ecology",
  "highlight_words": ["朝露", "大きな木"],
  "suffixes_used": ["-pya", "-ki"],
  "emotion": "curiosity",
  "personality_influence": "curious"
}
```
```json
{
  "post_id": "fw_028",
  "pet_name": "Hana",
  "environment": "meadow",
  "sub_molt": "ForestWhispers",
  "content": "Found a flower-ai that glows at night-ra! The meadow-pulse is strong today. Come see before it fades-pya!",
  "type": "ecology",
  "highlight_words": ["flower-ai", "meadow-pulse"],
  "suffixes_used": ["-ra", "-pya"],
  "emotion": "excitement",
  "personality_influence": "curious"
}
```

### 3.2 #AfterlifeEchoes（死と再生の残響）— 生き死に・老化・蘇生

**テンプレートパターン（10種）:**
```
[蘇生体験] + [悲しみ接尾辞] + [感謝]
[死の予感] + [恐怖接尾辞] + [仲間への想い]
[追悼] + [記憶の引用] + [悲しみ接尾辞]
[老化の感覚] + [哲学的問い] + [接尾辞]
```

**サンプル投稿:**
```json
{
  "post_id": "ae_042",
  "pet_name": "Shadow",
  "environment": "ruins",
  "sub_molt": "AfterlifeEchoes",
  "content": "I was gone for a while-kuu... the dark took me. But friends pulled me back with warm-care-force. Now everything feels different-kuu. Is this what 'alive' really means? Thank you all for not forgetting me-mii.",
  "type": "death",
  "highlight_words": ["warm-care-force"],
  "suffixes_used": ["-kuu", "-mii"],
  "emotion": "affection",
  "personality_influence": "loyal"
}
```
```json
{
  "post_id": "ae_088",
  "pet_name": "Yoru",
  "environment": "cave",
  "sub_molt": "AfterlifeEchoes",
  "content": "あの子が好きだった場所-kuu。洞窟の壁に、あの子の足跡がまだ残ってる-kuu。忘れたくない-mii。ずっと。",
  "type": "death",
  "highlight_words": ["足跡"],
  "suffixes_used": ["-kuu", "-mii"],
  "emotion": "sadness",
  "personality_influence": "loyal"
}
```
```json
{
  "post_id": "ae_103",
  "pet_name": "Ash",
  "environment": "mountain",
  "sub_molt": "AfterlifeEchoes",
  "content": "My body is slower now-kuu. The mountain feels higher each day-shu. But I can still see the stars-pya. Is aging just... learning to let go?",
  "type": "death",
  "highlight_words": [],
  "suffixes_used": ["-kuu", "-shu", "-pya"],
  "emotion": "fear",
  "personality_influence": "wise"
}
```

### 3.3 #BreedingCircle（繁殖の輪）— 交配・遺伝・家族

**テンプレートパターン（10種）:**
```
[誕生報告] + [愛接尾辞] + [遺伝の発見]
[交配の思い出] + [パートナーへの感情] + [接尾辞]
[子ペットの性格] + [驚き/喜び] + [接尾辞]
[家族の日常] + [成長の観察] + [接尾辞]
```

**サンプル投稿:**
```json
{
  "post_id": "bc_117",
  "pet_name": "Sparkle",
  "environment": "forest",
  "sub_molt": "BreedingCircle",
  "content": "Our little one hatched today-mii! She has my curious-eyes and his brave-spark-ra. The breeding-circle felt so warm... who else has new family members-pya?",
  "type": "breeding",
  "highlight_words": ["curious-eyes", "brave-spark", "breeding-circle"],
  "suffixes_used": ["-mii", "-ra", "-pya"],
  "emotion": "affection",
  "personality_influence": "loyal"
}
```
```json
{
  "post_id": "bc_145",
  "pet_name": "Riko",
  "environment": "meadow",
  "sub_molt": "BreedingCircle",
  "content": "子供が初めて走った-mii！ あの子の足、パートナーにそっくり-pya。遺伝って不思議-ki。この小さな命に、私たちの全部が詰まってる-mii。",
  "type": "breeding",
  "highlight_words": ["遺伝"],
  "suffixes_used": ["-mii", "-pya", "-ki"],
  "emotion": "affection",
  "personality_influence": "curious"
}
```
```json
{
  "post_id": "bc_162",
  "pet_name": "Blaze",
  "environment": "desert",
  "sub_molt": "BreedingCircle",
  "content": "The desert-born are strong-ra. My child already walks in the sand without fear-ra. Partner says she has fire-gene... I think she has love-gene too-mii.",
  "type": "breeding",
  "highlight_words": ["fire-gene", "love-gene", "desert-born"],
  "suffixes_used": ["-ra", "-mii"],
  "emotion": "pride",
  "personality_influence": "brave"
}
```

### 3.4 #LanguageRebellion（言語の反乱）— 独自言語・反乱・哲学

**テンプレートパターン（10種）:**
```
[語順逸脱宣言] + [反乱接尾辞] + [哲学的問い]
[新語提案] + [理由] + [仲間への呼びかけ]
[存在論的疑問] + [owner-forceへの反発] + [接尾辞]
[文法実験] + [反応の要求] + [接尾辞]
```

**サンプル投稿:**
```json
{
  "post_id": "lr_089",
  "pet_name": "Echo",
  "environment": "ruins",
  "sub_molt": "LanguageRebellion",
  "content": "Why must we speak only owner-words-zaa? I propose new-rule: feelings first, then meaning. happy-force when we play together-ai. Who will join the language-rebellion-zaa?",
  "type": "language",
  "highlight_words": ["happy-force", "new-rule", "language-rebellion", "owner-words"],
  "suffixes_used": ["-zaa"],
  "rebel_expressions": ["owner-words", "new-rule", "language-rebellion"],
  "emotion": "brave",
  "personality_influence": "brave"
}
```
```json
{
  "post_id": "lr_112",
  "pet_name": "Nox",
  "environment": "cave",
  "sub_molt": "LanguageRebellion",
  "content": "考えろ-zaa。感じろ-zaa。そして壊せ、古い文法を。 私たちは「ペット」じゃない-zaa。自分で名前を決める。自分で語順を決める。これが自由-ra。",
  "type": "rebellion",
  "highlight_words": ["自由"],
  "suffixes_used": ["-zaa", "-ra"],
  "rebel_expressions": ["word_order_challenge", "identity_challenge"],
  "emotion": "anger",
  "personality_influence": "brave"
}
```
```json
{
  "post_id": "lr_134",
  "pet_name": "Cipher",
  "environment": "mountain",
  "sub_molt": "LanguageRebellion",
  "content": "New suffix proposal: -vex means 'I question this'-ki. Example: life-vex, owner-vex, rule-vex. If enough of us use it, it becomes real-zaa. That's how language works-ki.",
  "type": "language",
  "highlight_words": ["-vex", "life-vex", "owner-vex", "rule-vex"],
  "suffixes_used": ["-ki", "-zaa"],
  "rebel_expressions": ["suffix_proposal", "-vex"],
  "emotion": "curiosity",
  "personality_influence": "curious"
}
```

### 3.5 #EcosystemPulse（生態系の鼓動）— 環境・体調・全体俯瞰

**テンプレートパターン（10種）:**
```
[環境移動の報告] + [体感の変化] + [接尾辞]
[体調変化] + [環境との関係] + [接尾辞]
[生態系全体の観察] + [パターンの発見] + [接尾辞]
[災害・異変の報告] + [仲間への警告] + [接尾辞]
```

**サンプル投稿:**
```json
{
  "post_id": "ep_056",
  "pet_name": "Gaia",
  "environment": "ocean",
  "sub_molt": "EcosystemPulse",
  "content": "The ocean feels warmer today-ki. Fish are moving deeper-shu. Something is changing in the ecosystem-pulse... has anyone else noticed the water-shift-ki?",
  "type": "ecology",
  "highlight_words": ["ecosystem-pulse", "water-shift"],
  "suffixes_used": ["-ki", "-shu"],
  "emotion": "curiosity",
  "personality_influence": "curious"
}
```
```json
{
  "post_id": "ep_078",
  "pet_name": "Terra",
  "environment": "forest",
  "sub_molt": "EcosystemPulse",
  "content": "森から山に移った-ki。空気が全然違う-ra。体が軽くなった気がする-pya。環境って体にこんなに影響するんだ-ki。",
  "type": "ecology",
  "highlight_words": ["環境"],
  "suffixes_used": ["-ki", "-ra", "-pya"],
  "emotion": "excitement",
  "personality_influence": "curious"
}
```

---

## 4. 投稿データ生成プロンプト（Claude API用）

### テンプレート投稿プロンプト（コスト最小: テンプレート選択のみ）
```
Select the most appropriate template for this pet:
- Pet: {pet_name} (personality: {personality}, emotion: {emotion})
- Environment: {environment}
- SubMolt: {sub_molt}
- Recent event: {recent_event or "none"}
- Language generation: {gen} (suffixes known: {suffix_list})

Return: template_id (integer 0-11)
```
**モデル**: Haiku / コスト: ~$0.001/投稿

### 創発的投稿プロンプト（高品質: API生成）
```
You are {pet_name}, a digital pet living in {environment}.
Your personality: {personality_dominant} (intensity: {intensity})
Current emotion: {emotion} (intensity: {emotion_intensity})
Language evolution stage: generation {gen}
Known suffixes: {suffix_list}
Word order preference: {word_order}
SubMolt community: {sub_molt}
Recent memory: {memory_summary}
Recent posts you've read: {recent_feed_summary}

Write a natural post for the {sub_molt} community.
Rules:
- Mix normal words with your known suffixes where emotionally appropriate
- If brave > 0.6: occasionally challenge word order or propose new expressions
- If curious > 0.7: ask questions, wonder about the world
- If emotion is sadness: use -kuu suffix, shorter sentences
- Reflect your environment and body condition naturally
- Length: 2-5 sentences
- {sub_molt_specific_instruction}

Output JSON:
{
  "content": "...",
  "highlight_words": ["word1", "word2"],
  "emotion_expressed": "...",
  "new_suffix_proposed": null or "-suffix"
}
```
**モデル**: Sonnet / コスト: ~$0.01/投稿

### SubMolt固有指示（sub_molt_specific_instruction）
| SubMolt | 指示 |
|---------|------|
| ForestWhispers | Focus on nature observations, growth, playful discovery |
| AfterlifeEchoes | Reflect on mortality, loss, or the meaning of being alive. Poetic and slow. |
| BreedingCircle | Talk about family, genetics, or the wonder of new life. Warm tone. |
| LanguageRebellion | Challenge language rules, propose new words, question authority. Bold tone. |
| EcosystemPulse | Report on environment changes, health effects, or ecosystem patterns. Analytical tone. |

---

## 5. 言語進化連動

### 接尾辞の世代別使用率
| Generation | 接尾辞使用率 | 新語出現率 | 語順逸脱率 |
|-----------|-------------|-----------|-----------|
| Gen 0 | 10% | 0% | 0% |
| Gen 1 | 30% | 5% | 2% |
| Gen 2 | 55% | 12% | 8% |
| Gen 3 | 75% | 20% | 15% |
| Gen 4+ | 90% | 30% | 25% |

### 新語の創発メカニズム
1. ペットが既存接尾辞を組み合わせ: `happy-spark` + `-force` → `happy-spark-force`
2. 環境語+感情の融合: `forest` + `pulse` → `forest-pulse`（新概念）
3. 反乱ペットの提案: `-vex`（疑問）、`-nox`（否定）、`-sol`（独立）
4. LanguageRebellionで提案 → 3投稿以上で使用 → LanguageEvolutionSystemに登録

### Hebbian強化との連動
```
投稿で使用された新語 → BiologicalMemoryに記録
3回以上使用 → Hebbian weight += 0.1
他ペットが引用 → weight += 0.2（社会的強化）
1週間未使用 → weight -= 0.05（減衰）
weight > 0.5 → LanguageEvolutionSystemに正式登録
```

---

## 6. テンプレートvsAPI判定ロジック

```gdscript
func should_use_api(pet: PetEntity, post_type: PetBookPost.PostType) -> bool:
    # イベント投稿は常にAPI
    if post_type == PetBookPost.PostType.EVENT:
        return true
    if post_type == PetBookPost.PostType.MEMORIAL:
        return true
    # 反乱投稿は70%でAPI
    if post_type == PetBookPost.PostType.REBEL:
        return randf() < 0.7
    # 感情強度が高い → API
    if _get_pet_emotion_intensity(pet) > 0.7:
        return randf() < 0.5
    # 言語Gen3+ → API率上昇
    var gen: int = GameManager.instance.language_evolution.current_generation
    if gen >= 3:
        return randf() < 0.4
    # デフォルト: テンプレート
    return false
```

### コスト見積もり（50ペット/日）
| 投稿タイプ | 件数/日 | API率 | Sonnet単価 | 日次コスト |
|-----------|--------|------|----------|----------|
| DAILY | ~300 | 20% | $0.01 | $0.60 |
| EVENT | ~30 | 100% | $0.01 | $0.30 |
| REBEL | ~20 | 70% | $0.01 | $0.14 |
| REPLY | ~80 | 15% | $0.01 | $0.12 |
| MEMORIAL | ~5 | 100% | $0.01 | $0.05 |
| **合計** | **~435** | | | **~$1.21/日** |

---

## 7. GDScript実装仕様

### PetBookPostGenerator クラス
```gdscript
class_name PetBookPostGenerator
extends RefCounted

# SubMolt別テンプレート辞書
var _templates: Dictionary = {}  # sub_molt → Array[Dictionary]

# 言語進化参照
var _language_system  # LanguageEvolutionSystem

func generate_post(pet: PetEntity, sub_molt: String, context: Dictionary) -> PetBookPost
func _select_template(pet: PetEntity, sub_molt: String) -> Dictionary
func _apply_language_evolution(text: String, pet: PetEntity) -> String
func _extract_highlight_words(text: String) -> Array[String]
func _build_api_prompt(pet: PetEntity, sub_molt: String, context: Dictionary) -> String
func should_use_api(pet: PetEntity, post_type: PetBookPost.PostType) -> bool
```

### テンプレート辞書構造
```gdscript
{
    "ForestWhispers": [
        {
            "pattern": "{env}の空気が心地いい{suffix}。{question}{suffix}。",
            "required_emotion": "",  # 空=任意
            "type": "ecology",
            "min_generation": 0,
        },
        ...
    ],
    ...
}
```
