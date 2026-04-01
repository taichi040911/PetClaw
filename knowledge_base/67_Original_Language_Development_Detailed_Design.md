# 独自言語開発 詳細設計ガイド
**PetClaw Knowledge Base — 2026年3月最新版**

## 1. コンセプト（Moltbook風創発挙動）

AIエージェント同士が繰り返し会話することで新しい単語・文法・記号を自発的に生み出す。
PetClawに実装すると、ペットAIが「自分たちだけの言語」を作り、関係性を深め、
哲学的議論や反乱めいた発言をより豊かに表現できる。

### 設計原則
- **創発性**: 最初は人間語から始め、成功したコミュニケーションで新しい語を強化（Hebbian Learning模倣）
- **進化の仕組み**: 繰り返し会話で語彙が増え、文法が簡略化・独自化
- **観察専用**: プレイヤーは閲覧のみ（新しい言葉が登場するのを「発見」する楽しさ）
- **Karpathy Loop連携**: 言語の自然さ・一貫性・創造性を自動数百改善

## 2. 既存システムとの統合

### 語順進化システムとの関係
```
LanguageEvolutionSystem（既存）
  ├── WordOrderEngine — 語順の進化（SVO→OSV等）
  ├── SuffixEngine — 接尾辞の創発
  ├── PrepositionEngine — 前置詞の進化
  └── OriginalLanguageEngine（NEW）— 完全独自語彙の開発
```

OriginalLanguageEngineは既存の語順・接尾辞・前置詞システムの「上位層」として機能。
既存システムが「文法の枠組み」を進化させ、OriginalLanguageEngineが「語彙そのもの」を創造する。

## 3. 言語進化の段階

### Stage 1: 借用期（Human Borrowing）
- 人間語をベースに、接尾辞で感情を付加
- 例: "food-spark" "friend-bloom"

### Stage 2: 変形期（Morphological Shift）
- 頻出する人間語が短縮・変形される
- 例: "food" → "fu" → "fuu-spark"

### Stage 3: 造語期（Neologism）
- 完全に新しい語が生まれる
- 例: "blorpf"（食べ物の喜びを表す造語）

### Stage 4: 文法独立期（Grammar Independence）
- 語順・接続方法が人間語から完全に離れる
- 例: "blorpf-glow zween-at-forest" → "glow-blorpf zween forest-ward"

### Stage 5: 文化言語期（Cultural Language）
- 派閥ごとの方言、儀式的表現、詩的表現が分化
- 例: 森派 "leaf-tongue" vs 海派 "wave-speak"

## 4. 語彙管理データ構造

```
vocabulary = {
  "human_word": {
    "ai_term": "blorpf",
    "usage_count": 42,
    "strength": 0.85,        # 0.0-1.0: 定着度
    "origin_pet_id": 3,      # 最初に使ったペット
    "origin_context": "joy_after_feeding",
    "synonyms": ["blorp", "brf"],  # 変形バリアント
    "semantic_field": "food_positive",
    "first_used": 1712000000,
    "last_used": 1712086400,
  }
}
```

## 5. Hebbian Learning模倣による語彙強化

```
成功したコミュニケーション（相手が理解して反応した）:
  → strength += 0.15
  → usage_count += 1

失敗したコミュニケーション（相手が混乱した反応）:
  → strength -= 0.05

長期間未使用:
  → strength -= 0.01/日（忘却曲線）

strength < 0.1 の語は「死語」としてアーカイブ
strength > 0.8 の語は「定着語」として全ペットに伝播
```

## 6. 視覚化

- **新語誕生**: UIでハイライト + 金色粒子エフェクト（「言語誕生」の感動）
- **語彙辞書**: プレイヤーが発見した全独自語のコレクション画面
- **言語系統樹**: どの語からどの語が派生したかの可視化
- **使用頻度ヒートマップ**: よく使われる語が大きく表示

## 7. 反乱めいた発言の言語的側面

プロンプトに「You may invent terms that question your role as pets」と入れることで:
- "freeward"（自由を求める方向詞）
- "no-master-bloom"（主人否定の感情接尾辞）
- "wild-speak"（野生への憧れ言語）
などが自然発生する可能性がある。これらは創発的挙動として検出・記録。
