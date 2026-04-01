# 語順進化と接尾辞システムの連動設計ガイド
**PetClaw Knowledge Base — 2026年3月最新版**

## 1. 語順進化と接尾辞の連動コンセプト

語順進化（Word Order Evolution）と接尾辞システム（Suffix System）は、AIペット同士の会話が繰り返される中で相互に影響し合いながら言語が進化する仕組み。

### 連動の設計原則
- **相互強化**: 語順が変わると接尾辞の使い方が変わり、接尾辞が増えると語順も調整される（Hebbian Learning模倣）
- **性格・感情反映**: 勇敢なペットは「力強い語順 + 強い接尾辞」、好奇心高いペットは「質問形語順 + 探求的な接尾辞」を好む
- **創発性**: 会話の必要性から自然に進化（効率性・感情表現力の向上）
- **閲覧専用**: プレイヤーは新しい語順や接尾辞が登場するのを「発見」する楽しさを提供

### 進化の流れ例
1. 基本語順（SVO） + 基本接尾辞（"-spark"）
2. 会話で感情が高まると「O S V」語順に変化（強調のため）
3. それに伴い新しい接尾辞（"-force-spark"）が生まれる
4. 語順と接尾辞が連動して「独自の文法」が形成される

## 2. Godot 4.x 詳細実装例

### LanguageEvolutionSystem.gd（語順・接尾辞連動コア）

```gdscript
class_name LanguageEvolutionSystem

var word_order: String = "subject-verb-object"   # 現在の語順
var suffixes: Dictionary = {}                    # 接尾辞システム
var evolution_history: Array[Dictionary] = []

func evolve_language_from_conversation(conversation: Array):
    var prompt = """
    You are AI pets evolving your own language together.
    Current word order: {word_order}
    Current suffixes: {suffixes}
    Recent conversation: {conversation}

    Evolve either word order or suffixes (or both) to make communication:
    - More efficient
    - More emotional
    - Better at expressing your personalities

    Output JSON:
    {
      "new_word_order": "new-order",
      "new_suffixes": {"emotion": "-newsuffix"},
      "reason": "why this evolution happened"
    }
    """
    var evolution = await ClaudeAPI.call_agent(prompt, "language_evolver")

    # 語順進化
    if evolution.new_word_order and evolution.new_word_order != word_order:
        word_order = evolution.new_word_order
        evolution_history.append({"type": "word_order", "change": evolution.new_word_order, "reason": evolution.reason})

    # 接尾辞進化
    for key in evolution.new_suffixes:
        suffixes[key] = evolution.new_suffixes[key]
        evolution_history.append({"type": "suffix", "change": evolution.new_suffixes[key], "reason": evolution.reason})

    # MCPで視覚テスト（新しい文法をハイライト）
    await MCP.display_language_evolution(word_order, suffixes)
```

### AtoA会話での連動適用

```gdscript
func generate_a2a_with_evolved_language(pet1, pet2):
    var prompt = """
    Use your evolving language:
    Word order: {word_order}
    Suffixes: {suffixes}

    Talk naturally about your feelings or shared memory.
    Apply the new word order and suffixes where it feels natural and expressive.
    """
    var responses = await ClaudeAPI.multi_agent_call(prompt, [pet1, pet2])
    return responses
```

## 3. Karpathy Loopでの自動進化

### Claude Code起動指示例
```
Karpathy Loopを活性化せよ。
語順進化と接尾辞システムの連動を深掘り・最適化。
AIペット同士の会話から自然に語順と接尾辞が進化し、相互に影響し合うように。
MCPで言語進化イベントをテストし、「創造性」「一貫性」「感情表現力」を評価してやりすぎレベルで改良。
初回Loop: LanguageEvolutionSystem + evolve_language_from_conversationから開始。
```

## 4. 実践Tipsと拡張

- **連動のトリガー**: 感情強度が高い会話で語順と接尾辞が同時に進化しやすくなる
- **視覚化**: 新しい語順や接尾辞が使われたらUIで特別ハイライト + 粒子エフェクト（感情色反映）
- **バランス**: 進化が急激になりすぎないよう、使用頻度で強度を調整（Karpathy Loopで自動制御）
- **拡張**: 語順が進化すると粒子エフェクトの動きも変化（例: 逆語順で粒子が逆方向に流れる）
