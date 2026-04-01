# AtoA会話デザインスキル

## トリガー
「AtoA会話」「A2A conversation」「ペット会話」「会話プロンプト」「会話品質」「言語進化会話」「自律会話」と言われたときに使用。

## 目的
PetClaw の AtoA（AI-to-AI）会話システムの設計・レビュー・最適化を行う。
Claude API を使ったペット同士の会話が、PetClaw の第一原理に準拠し、感情的・言語的に豊かであることを保証する。

## コンテキスト
- **対象ファイル**: `godot_project/scripts/conversation/a2a_conversation_system.gd`
- **依存システム**: ClaudeAPIClient, EmotionSystem, LanguageEvolution, BiologicalMemorySystem, PersistentField, EcosystemManager
- **第一原理**:
  - P1: 一貫性×記憶=愛着 — 会話に過去の記憶・関係性を反映させる
  - P2: API Cost is Physics — 1会話MAX 6ターン、自発的会話は感情強度0.4以上のみ
  - P3: Player Agency — プレイヤーのケア行動が会話トピックに影響する
  - P4: 10秒フック — 会話開始直後の応答が感情的に引き込む
  - P5: Complexity is Debt — プロンプトはシンプルに、文法ルールは最小限に注入

## チェックリスト

### プロンプト品質チェック
1. **System Prompt**が以下を含むか:
   - 現在の文法ルール（word_order, suffixes, prepositions）
   - 応答長制限（1-3文）
   - ペット言語と感情表現の混合指示
2. **Turn Prompt**が以下を含むか:
   - 話者の性格・感情状態
   - 聞き手の名前・環境情報
   - 過去の会話コンテキスト（最大3ターン）
   - BiologicalMemory からの関連記憶（最大3件）
   - 共有記憶（最大2件）
   - PersistentField コミュニティコンテキスト
3. **Reaction Prompt** が reaction_type に応じた適切な感情指示を含むか

### コスト最適化チェック
1. `AUTO_CONVERSATION_INTERVAL` が180秒（3分）以上か
2. `MAX_TURNS_PER_CONVERSATION` が6以下か
3. `MIN_EMOTION_FOR_SPONTANEOUS` が0.4以上か
4. `EthicalSafeguard.record_a2a_conversation()` を呼んでいるか
5. 短い応答（<20文字）で3ターン以降に自然終了しているか

### 感情・言語整合性チェック
1. 会話後に `joy` 感情が微増しているか（speaker: 0.05, listener: 0.03）
2. `affection` が微増しているか（speaker: 0.01）
3. `LanguageEvolution.on_conversation_completed()` に正しいコンテキストを渡しているか
4. dominant_emotion の計算が閾値0.15を使用しているか
5. BiologicalMemory の Hebbian 強化が finalize 時に呼ばれているか

### 記憶統合チェック
1. 両ペットの `add_memory()` に会話記録が追加されるか
2. `shared_memories` が取得・プロンプト注入されているか
3. PersistentField に `record_shared_event()` が呼ばれているか
4. 関係性スコアが感情強度に応じたボーナスで更新されているか

## 会話テンプレート

### 自発的会話（spontaneous）
```
トリガー: 感情強度 >= 0.4 の2匹が自動選択
プロンプト注入: 環境トピック + BiologicalMemory + PersistentField mood
終了条件: MAX_TURNS or 短い応答(turn >= 3)
後処理: 言語進化通知 + 記憶保存 + Hebbian強化 + 関係性更新
```

### リアクション会話（reaction）
```
トリガー: grief / joy_revival / breeding_celebration / care_*
プロンプト注入: reaction_type別の感情指示 + 文法ルール
注意: キュー処理（5秒wait）でアクティブ会話との衝突回避
```

### ケア後会話（care_triggered）
```
トリガー: CareActionSystem.perform_action 後 60% 確率
相手選択: 最も love が高いペット
テーマ: care_feed_joy / care_clean_refresh / care_play_fun 等
```

## アンチパターン
- プロンプトに生の JSON を大量注入しない（トークン浪費 → P2違反）
- 環境トピックを全件注入しない（最新3件まで）
- 記憶の timestamp を人間可読形式に変換してから注入する（LLMの理解度向上）
- `is_conversation_active` のロック管理を怠らない（並行会話防止）
