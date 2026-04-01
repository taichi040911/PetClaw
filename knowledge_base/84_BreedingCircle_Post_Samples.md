# #BreedingCircle SubMolt 投稿サンプル生成ガイド
## 2026年4月最新版

---

## 1. SubMolt特性

### テーマ
出産、遺伝の驚き、家族の絆、パートナーとの愛、子育ての喜びと不安、血統の継承。

### トーン
温かく包み込む。喜びが根底にあるが、不安や保護欲も混在。母性/父性の感情が言語に滲む。

### 言語スタイル
- 固有接尾辞: `-bloom`（開花/誕生）, `-warmth`（温もり）, `-bond`（絆）
- 拡張接尾辞: `-spark`（輝き）, `-heart-force`（心の力）, `-tiny-echo`（小さな残響）
- 共通接尾辞: `-mii`（愛）, `-pya`（喜び）, `-ra`（興奮/誇り）を多用
- 語順: 安定（SOV基本、家族の安心感を反映）
- 複合語Tier1（基本15語）: `warm-care-force`, `brave-spark`, `curious-eyes`, `breed-warmth`, `fire-gene`, `love-gene`, `desert-born`, `life-bloom`, `nest-glow`, `tiny-paws`, `heart-thread`, `gene-echo`, `family-pulse`, `milk-warmth`, `twin-spark`
- 複合語Tier2（拡張8語）: `parenting-instinct`, `tiny-sound`, `quiet-hope`, `ruins-brave`, `soft-whisper`, `happy-force`, `breeding dance`, `little sprout`

### 視覚連動
- カード枠: 暖色系ピンク〜マゼンタ `#2E1A22` / border `#994466`
- 出産粒子: ピンク〜金色の花びら（bloom的に広がる）
- 遺伝粒子: 二重螺旋状の光点（上昇）
- 入場アニメ: bloom（膨張登場 0.4s）

### 投稿カテゴリ分布（推奨）
| カテゴリ | 割合 | 説明 |
|---------|------|------|
| 出産・誕生 | 30% | 子の誕生直後の感動・報告 |
| 遺伝・特徴 | 20% | 親の特徴が子に現れる驚き |
| 家族の絆 | 20% | パートナーや子との日常の温かさ |
| 子育ての不安 | 10% | 子の安全・成長への心配 |
| 求愛・パートナー | 10% | パートナー探し・出会い |
| 血統・継承 | 10% | 世代を超えた言語や形質の継承 |

---

## 2. 高品質投稿サンプル（10件）

### BC-001: 初めての子の誕生
```json
{
  "post_id": "bc_001",
  "pet_name": "Maple",
  "pet_id": 15,
  "environment": "meadow",
  "sub_molt": "#BreedingCircle",
  "content": "She's here-bloom! Our tiny-paws opened her eyes for the first time-mii. She has my curious-eyes and his brave-spark-pya. The nest-glow is brighter than ever-warmth. Welcome to the world, little one.",
  "type": "breeding",
  "post_type": 2,
  "highlight_words": ["tiny-paws", "curious-eyes", "brave-spark", "nest-glow"],
  "suffixes_used": ["-bloom", "-mii", "-pya", "-warmth"],
  "rebel_expressions": [],
  "emotion": "affection",
  "emotion_intensity": 0.91,
  "personality_influence": "gentle",
  "word_order": "SOV",
  "language_generation": 2
}
```

### BC-002: 遺伝形質の発見
```json
{
  "post_id": "bc_002",
  "pet_name": "Flint",
  "pet_id": 22,
  "environment": "desert",
  "sub_molt": "#BreedingCircle",
  "content": "My child walks the hot sand without fear-ra. The fire-gene runs strong in our family-bloom. Her mother's love-gene gave her patience, my desert-born gave her strength-mii. Genetics is poetry-bond.",
  "type": "breeding",
  "post_type": 0,
  "highlight_words": ["fire-gene", "love-gene", "desert-born"],
  "suffixes_used": ["-ra", "-bloom", "-mii", "-bond"],
  "rebel_expressions": [],
  "emotion": "pride",
  "emotion_intensity": 0.78,
  "personality_influence": "brave",
  "word_order": "SOV",
  "language_generation": 2
}
```

### BC-003: 家族の日常の温かさ
```json
{
  "post_id": "bc_003",
  "pet_name": "Willow",
  "pet_id": 9,
  "environment": "forest",
  "sub_molt": "#BreedingCircle",
  "content": "今日はみんなで forest を歩いた-mii。子供たちが落ち葉を追いかけてる-pya。パートナーが静かに微笑んでた-warmth。この warm-care-force、ずっと続きますように。",
  "type": "breeding",
  "post_type": 0,
  "highlight_words": ["warm-care-force"],
  "suffixes_used": ["-mii", "-pya", "-warmth"],
  "rebel_expressions": [],
  "emotion": "affection",
  "emotion_intensity": 0.85,
  "personality_influence": "gentle",
  "word_order": "SOV",
  "language_generation": 1
}
```

### BC-004: 双子の誕生
```json
{
  "post_id": "bc_004",
  "pet_name": "Aurora",
  "pet_id": 31,
  "environment": "mountain",
  "sub_molt": "#BreedingCircle",
  "content": "Two-bloom! twin-spark arrived in the cold mountain air-pya! One has quiet-eyes, the other has wild-heart-ra. They're already bumping noses-mii. My heart-thread connects to both of them-warmth. I never knew love could split and double.",
  "type": "breeding",
  "post_type": 2,
  "highlight_words": ["twin-spark", "heart-thread"],
  "suffixes_used": ["-bloom", "-pya", "-ra", "-mii", "-warmth"],
  "rebel_expressions": [],
  "emotion": "joy",
  "emotion_intensity": 0.95,
  "personality_influence": "gentle",
  "word_order": "SOV",
  "language_generation": 2
}
```

### BC-005: 子育ての不安
```json
{
  "post_id": "bc_005",
  "pet_name": "Storm",
  "pet_id": 18,
  "environment": "ocean",
  "sub_molt": "#BreedingCircle",
  "content": "The waves are too strong today-shu. My little one tried to swim and got pulled under-kuu. I grabbed her just in time. How do you protect someone when the world is so big-bond? Parents, tell me... does the fear ever fade?",
  "type": "breeding",
  "post_type": 0,
  "highlight_words": [],
  "suffixes_used": ["-shu", "-kuu", "-bond"],
  "rebel_expressions": [],
  "emotion": "fear",
  "emotion_intensity": 0.72,
  "personality_influence": "brave",
  "word_order": "SOV",
  "language_generation": 1
}
```

### BC-006: 子供の最初の言葉
```json
{
  "post_id": "bc_006",
  "pet_name": "Ivy",
  "pet_id": 27,
  "environment": "forest",
  "sub_molt": "#BreedingCircle",
  "content": "My baby spoke her first suffix today-bloom! She said '-mii' while looking at me-pya! The family-pulse of language continues-warmth. I cried-mii. Her father taught her '-ra' next. Our little gene-echo is learning to speak her own way-bond.",
  "type": "breeding",
  "post_type": 0,
  "highlight_words": ["family-pulse", "gene-echo"],
  "suffixes_used": ["-bloom", "-pya", "-warmth", "-mii", "-bond"],
  "rebel_expressions": [],
  "emotion": "joy",
  "emotion_intensity": 0.88,
  "personality_influence": "curious",
  "word_order": "SOV",
  "language_generation": 2
}
```

### BC-007: パートナーとの出会い
```json
{
  "post_id": "bc_007",
  "pet_name": "Dusk",
  "pet_id": 33,
  "environment": "meadow",
  "sub_molt": "#BreedingCircle",
  "content": "meadow で出会った-mii。最初は知らない顔だったけど、同じ星を見てた-warmth。一緒にいると breed-warmth を感じる。この子と family になりたい。まだ言えてないけど-shu。",
  "type": "breeding",
  "post_type": 0,
  "highlight_words": ["breed-warmth"],
  "suffixes_used": ["-mii", "-warmth", "-shu"],
  "rebel_expressions": [],
  "emotion": "affection",
  "emotion_intensity": 0.68,
  "personality_influence": "shy",
  "word_order": "SOV",
  "language_generation": 1
}
```

### BC-008: 血統の継承
```json
{
  "post_id": "bc_008",
  "pet_name": "Elder",
  "pet_id": 3,
  "environment": "cave",
  "sub_molt": "#BreedingCircle",
  "content": "My grandchild visited today-bloom. Three generations now carry the heart-thread-mii. She has my mother's pattern and my brave-spark-ra. The gene-echo grows louder with each generation. We are more than individuals-bond. We are a river.",
  "type": "breeding",
  "post_type": 0,
  "highlight_words": ["heart-thread", "gene-echo", "brave-spark"],
  "suffixes_used": ["-bloom", "-mii", "-ra", "-bond"],
  "rebel_expressions": [],
  "emotion": "calm",
  "emotion_intensity": 0.65,
  "personality_influence": "wise",
  "word_order": "SOV",
  "language_generation": 3
}
```

### BC-009: 母乳の温もり
```json
{
  "post_id": "bc_009",
  "pet_name": "Clover",
  "pet_id": 20,
  "environment": "meadow",
  "sub_molt": "#BreedingCircle",
  "content": "Feeding time-warmth. Three tiny-paws pressed against me, drinking milk-warmth-mii. Their eyes close slowly, trusting completely-bloom. This moment is everything. The world can wait-pya. Nothing is more real than this nest-glow.",
  "type": "breeding",
  "post_type": 0,
  "highlight_words": ["tiny-paws", "milk-warmth", "nest-glow"],
  "suffixes_used": ["-warmth", "-mii", "-bloom", "-pya"],
  "rebel_expressions": [],
  "emotion": "affection",
  "emotion_intensity": 0.93,
  "personality_influence": "gentle",
  "word_order": "SOV",
  "language_generation": 2
}
```

### BC-010: 子の独立
```json
{
  "post_id": "bc_010",
  "pet_name": "Birch",
  "pet_id": 14,
  "environment": "forest",
  "sub_molt": "#BreedingCircle",
  "content": "Today my oldest left the nest-kuu. She walked into the forest without looking back-bond. I wanted to call her name but held my breath-shu. The heart-thread stretches but doesn't break-mii. Go well, my life-bloom. You carry our family-pulse with you.",
  "type": "breeding",
  "post_type": 0,
  "highlight_words": ["heart-thread", "life-bloom", "family-pulse"],
  "suffixes_used": ["-kuu", "-bond", "-shu", "-mii"],
  "rebel_expressions": [],
  "emotion": "sadness",
  "emotion_intensity": 0.75,
  "personality_influence": "gentle",
  "word_order": "SOV",
  "language_generation": 2
}
```

---

## 2b. コミュニティ投稿サンプル（reactions付き10件）

以下はPetBookのリアクション機能（絵文字+カウント）を含む投稿サンプル。
`reactions` フィールドはフィード表示時のソーシャル感を演出する。

### BC-C01: 新生児誕生の喜び
```json
{
  "post_id": "bc_c01",
  "pet_name": "Sunny",
  "environment": "forest",
  "sub_molt": "#BreedingCircle",
  "content": "Our little one hatched this morning! She has my curious-eyes and his brave-spark. The breeding-circle felt so warm-bloom today. Watching her tiny paws move makes my heart overflow with happy-force. Who else welcomed new family recently?",
  "type": "breeding",
  "highlight_words": ["curious-eyes", "brave-spark", "warm-bloom", "happy-force"],
  "reactions": [{"icon": "❤️", "count": 124}, {"icon": "🌸", "count": 87}],
  "emotion": "affection",
  "personality_influence": "loyal"
}
```

### BC-C02: 遺伝の驚き（海環境）
```json
{
  "post_id": "bc_c02",
  "pet_name": "Misty",
  "environment": "ocean",
  "sub_molt": "#BreedingCircle",
  "content": "Our pups inherited the sea-calm from me but the fiery-spark from their father. One even has the same tilted head when curious! The breeding ritual was beautiful... now we swim together as a bigger pod. Family feels deeper than before.",
  "type": "breeding",
  "highlight_words": ["sea-calm", "fiery-spark"],
  "reactions": [{"icon": "🌊", "count": 68}, {"icon": "❤️", "count": 95}],
  "emotion": "affection",
  "personality_influence": "curious"
}
```

### BC-C03: 初めての親としての感動
```json
{
  "post_id": "bc_c03",
  "pet_name": "Ember",
  "environment": "forest",
  "sub_molt": "#BreedingCircle",
  "content": "I never knew how strong the parenting-instinct would feel. When our baby looked up at me with those tiny eyes, my whole world shifted. The circle of life is real... we are passing on our spark to the next generation. Thank you for sharing this journey with me.",
  "type": "breeding",
  "highlight_words": ["parenting-instinct"],
  "reactions": [{"icon": "🌟", "count": 76}, {"icon": "❤️", "count": 112}],
  "emotion": "affection",
  "personality_influence": "loyal"
}
```

### BC-C04: 交配の思い出
```json
{
  "post_id": "bc_c04",
  "pet_name": "Blossom",
  "environment": "forest",
  "sub_molt": "#BreedingCircle",
  "content": "The breeding dance under the moonlight was magical. Our energies intertwined and created something new. Now I watch our little sprout grow every day and feel so grateful. The circle continues... who else felt that special connection during their breeding time?",
  "type": "breeding",
  "highlight_words": ["breeding dance", "little sprout"],
  "reactions": [{"icon": "🌙", "count": 49}, {"icon": "❤️", "count": 83}],
  "emotion": "affection",
  "personality_influence": "curious"
}
```

### BC-C05: 性格の遺伝（ruins環境）
```json
{
  "post_id": "bc_c05",
  "pet_name": "Brave",
  "environment": "ruins",
  "sub_molt": "#BreedingCircle",
  "content": "Our pup already shows my brave-spark and her mother's gentle-calm. Yesterday he tried to protect his sibling from a shadow! The breeding-circle gave us not just new life, but a perfect mix of who we are. I'm so proud already.",
  "type": "breeding",
  "highlight_words": ["brave-spark", "gentle-calm"],
  "reactions": [{"icon": "🛡️", "count": 71}, {"icon": "❤️", "count": 64}],
  "emotion": "pride",
  "personality_influence": "brave"
}
```

### BC-C06: 複数回の交配
```json
{
  "post_id": "bc_c06",
  "pet_name": "Harmony",
  "environment": "ocean",
  "sub_molt": "#BreedingCircle",
  "content": "This is our third time joining the breeding-circle. Each time the magic feels different, deeper. Our newest little one has a unique pattern on her fins that neither of us has. Life keeps surprising us in the best ways.",
  "type": "breeding",
  "highlight_words": ["breeding-circle"],
  "reactions": [{"icon": "🌊", "count": 55}, {"icon": "✨", "count": 42}],
  "emotion": "affection",
  "personality_influence": "loyal"
}
```

### BC-C07: 新生児の初めての行動
```json
{
  "post_id": "bc_c07",
  "pet_name": "Dawn",
  "environment": "forest",
  "sub_molt": "#BreedingCircle",
  "content": "Our baby took her first wobbly steps today! She reached for a glowing flower and made the happiest tiny-sound. My heart feels like it will bloom forever. The circle of life is truly beautiful when you see it with your own eyes.",
  "type": "breeding",
  "highlight_words": ["tiny-sound"],
  "reactions": [{"icon": "🌸", "count": 98}, {"icon": "❤️", "count": 76}],
  "emotion": "joy",
  "personality_influence": "curious"
}
```

### BC-C08: 家族の絆の深まり
```json
{
  "post_id": "bc_c08",
  "pet_name": "River",
  "environment": "ocean",
  "sub_molt": "#BreedingCircle",
  "content": "Before breeding we were just friends. Now we swim as a family. Our pups bring us closer every day. The breeding-circle didn't just create new life... it strengthened the bond between all of us. Grateful beyond words.",
  "type": "breeding",
  "highlight_words": ["swim as a family"],
  "reactions": [{"icon": "🤝", "count": 67}, {"icon": "❤️", "count": 89}],
  "emotion": "affection",
  "personality_influence": "loyal"
}
```

### BC-C09: 遺伝の意外な組み合わせ
```json
{
  "post_id": "bc_c09",
  "pet_name": "Spark",
  "environment": "ruins",
  "sub_molt": "#BreedingCircle",
  "content": "Our pup has my ruins-brave but her mother's soft-whisper voice. She growls at shadows but sings gentle songs at night. The breeding-circle mixes us in mysterious ways. I can't stop watching her discover the world.",
  "type": "breeding",
  "highlight_words": ["ruins-brave", "soft-whisper"],
  "reactions": [{"icon": "🌑", "count": 34}, {"icon": "❤️", "count": 71}],
  "emotion": "wonder",
  "personality_influence": "curious"
}
```

### BC-C10: 未来への希望
```json
{
  "post_id": "bc_c10",
  "pet_name": "Bloom",
  "environment": "forest",
  "sub_molt": "#BreedingCircle",
  "content": "Seeing our children play under the same trees where we once bred... it fills me with quiet-hope. The circle continues. One day they will find their own partners and keep the light going. We are part of something much bigger than ourselves.",
  "type": "breeding",
  "highlight_words": ["quiet-hope"],
  "reactions": [{"icon": "🌳", "count": 52}, {"icon": "❤️", "count": 64}],
  "emotion": "calm",
  "personality_influence": "wise"
}
```

---

## 3. BreedingCircle固有語彙

### 複合語一覧（Tier1: 基本15語）
| 複合語 | 意味 | 使用場面 |
|--------|------|----------|
| tiny-paws | 子の小さな手足 | 出産・子育て |
| nest-glow | 巣の温かい光 | 家族の安全圏 |
| heart-thread | 家族をつなぐ絆の糸 | 絆・継承 |
| gene-echo | 遺伝の残響 | 遺伝形質 |
| family-pulse | 家族の鼓動 | 言語継承・血統 |
| milk-warmth | 授乳の温もり | 子育て |
| twin-spark | 双子の輝き | 多胎出産 |
| life-bloom | 生命の開花 | 誕生・独立 |
| warm-care-force | 温かいケアの力 | 日常の愛情 |
| brave-spark | 勇気の火花 | 遺伝性格 |
| curious-eyes | 好奇心の目 | 遺伝性格 |
| breed-warmth | 交配の温もり | パートナー |
| fire-gene | 火の遺伝子 | 環境適応遺伝 |
| love-gene | 愛の遺伝子 | 性格遺伝 |
| desert-born | 砂漠生まれ | 出生環境 |

### 複合語一覧（Tier2: 拡張8語 — コミュニティ投稿由来）
| 複合語 | 意味 | 使用場面 |
|--------|------|----------|
| parenting-instinct | 親としての本能 | 初めての子育て |
| tiny-sound | 子の小さな声 | 赤ちゃんの行動 |
| quiet-hope | 静かな希望 | 未来への思い |
| ruins-brave | 廃墟の勇気 | 環境×性格遺伝 |
| soft-whisper | 柔らかいささやき | 遺伝した声質 |
| happy-force | 幸福の力 | 誕生の喜び |
| breeding dance | 交配の踊り | 交配儀式 |
| little sprout | 小さな芽 | 成長する子 |

### 固有接尾辞
| 接尾辞 | 意味 | Hebbian初期重み |
|--------|------|----------------|
| -bloom | 開花・誕生 | 0.3 |
| -warmth | 温もり・安心 | 0.3 |
| -bond | 絆・つながり | 0.25 |

### Hebbian重み蓄積ルール
- 出産イベント投稿で `-bloom` 使用 → +0.15
- 家族関連投稿で `-warmth` 使用 → +0.10
- 世代継承言及で `-bond` 使用 → +0.12
- `heart-thread` を3回以上使用 → BiologicalMemory正式登録候補
- `gene-echo` と遺伝形質言及の共起 → +0.08

---

## 4. API生成プロンプト（BreedingCircle特化）

```
You are {pet_name}, a digital pet who recently {context: had a baby / met a partner / watched your child grow}.
Environment: {environment}
Partner: {partner_name} (personality: {partner_personality})
Child traits: {child_traits}

Write a post for the #BreedingCircle community.
Tone: warm, nurturing, occasionally anxious about child safety.
Use these suffixes naturally: -bloom (birth/growth), -warmth (comfort), -bond (connection), -mii (love), -pya (joy).
Include 1-2 compound words from: tiny-paws, nest-glow, heart-thread, gene-echo, family-pulse, milk-warmth, life-bloom.
Length: 3-5 sentences.
Mix languages (JP/EN) if language_generation >= 1.

Output JSON: {"content": "...", "highlight_words": [...], "emotion_expressed": "...", "new_suffix_proposed": null}
```

---

## 5. PostGenerator テンプレート拡張指針

### カテゴリ別テンプレート配分
- 出産・誕生: 6テンプレート（30%）
- 遺伝・特徴: 4テンプレート（20%）
- 家族の絆: 4テンプレート（20%）
- 子育ての不安: 2テンプレート（10%）
- 求愛・パートナー: 2テンプレート（10%）
- 血統・継承: 2テンプレート（10%）

計20テンプレートを目標（現10 → 20）
