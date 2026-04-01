# 生物模倣記憶スキル

## トリガー
「BiologicalMemory」「生物模倣記憶」「記憶システム」「海馬」「記憶固定化」「Hebbian」「記憶検索」「睡眠統合」と言われたときに使用。

## 目的
PetClaw の BiologicalMemorySystem の設計・テスト・最適化を支援する。
神経科学に基づく記憶メカニズム（海馬→大脳皮質の固定化、Hebbian学習、睡眠中統合）が正しく機能し、P1（一貫性×記憶=愛着）を実現することを保証する。

## コンテキスト
- **対象ファイル**: `godot_project/scripts/memory/biological_memory_system.gd`
- **連携システム**:
  - AtoAConversationSystem — 会話時の記憶取得・Hebbian強化
  - PetAutonomySystem — 自律行動時の記憶参照
  - PetLifecycleFSM — 睡眠時の記憶統合トリガー
  - GameManager — save/load（BiologicalMemoryはGameManager.save_data経由？要確認）
- **第一原理**:
  - P1: 一貫性×記憶=愛着 — 記憶が会話・行動に反映されることで愛着が生まれる
  - P2: API Cost is Physics — 記憶検索はローカル処理、API呼び出しは最小限
  - P5: Complexity is Debt — 記憶構造はシンプルに、クエリは直感的に

## 記憶アーキテクチャ

### 記憶の3層構造
```
感覚記憶（Sensory Buffer）
│  寿命: 数秒〜数分
│  全てのイベントが一時格納
│
├── 重要度フィルタ ──→ 破棄（重要度 < 閾値）
│
▼
海馬（Hippocampus）
│  寿命: 数時間〜数日
│  エピソード記憶として格納
│  検索対象: retrieve_memories(), retrieve_shared_memories()
│
├── 睡眠統合 ──→ 大脳皮質への固定化
├── Hebbian強化 ──→ 重要度更新
│
▼
大脳皮質（Cortex）
   寿命: 永続
   意味記憶として固定化
   性格・嗜好への長期的影響
```

### 記憶レコード構造
```gdscript
{
    "pet_id": int,              # 所有ペットID
    "timestamp": float,          # Unix時刻
    "content": {                 # イベント内容
        "type": String,          # "conversation", "care_received", "evolution", etc.
        "trigger": String,       # トリガー情報
        "with_pet_id": int,      # 相手ペット（会話時）
        ...
    },
    "emotion_tag": String,       # 記憶時の dominant emotion
    "importance": float,         # 重要度（0.0〜1.0）
    "retrieval_count": int,      # 検索された回数
    "last_retrieved": float,     # 最後に検索された時刻
    "context_tags": Array,       # 環境・状況タグ
}
```

## チェックリスト

### 記憶格納チェック
1. **重要度計算** が以下の要素を考慮しているか:
   - 感情強度（高感情 = 高重要度）
   - イベントタイプ（death/evolution > care > conversation）
   - 新規性（初めての体験 > 繰り返しの体験）
2. **重複防止**: 同一イベントが複数回格納されないか
3. **容量管理**: ペットあたりの記憶上限が設定されているか（推奨: 海馬100件、皮質50件）

### 記憶検索チェック
1. `retrieve_memories(pet_id, query, personality, limit)` が:
   - クエリの context_tags と記憶の context_tags をマッチングしているか
   - personality による検索バイアスがあるか（curious → 古い記憶も拾う、calm → 最近の記憶優先）
   - importance × recency × relevance のスコアリングが適切か
2. `retrieve_shared_memories(pet1_id, pet2_id, limit)` が:
   - 両ペットに共通する記憶（同一イベント）を返すか
   - with_pet_id による相互参照が正しいか
3. 検索結果が limit 件を超えないか

### Hebbian強化チェック
1. `strengthen_related_memories(pet_id, memory)` が:
   - 会話中に参照された記憶の importance を微増させるか
   - 関連する他の記憶も連想的に強化されるか（context_tags の重複度合いで）
   - 強化量が指数関数的に飽和するか（1.0を超えない）
2. 強化が AtoA 会話の `_finalize_conversation()` で呼ばれているか

### 睡眠統合チェック
1. `trigger_sleep_consolidation(pet_id)` が:
   - PetLifecycleFSM の `sleep_started` シグナルで呼ばれるか
   - 海馬の記憶を重要度順にソートしているか
   - 上位N件を大脳皮質に移動（固定化）しているか
   - 低重要度の記憶を破棄（忘却）しているか
2. `consolidate_memory(pet_id, content, emotion, importance, tags)` が:
   - ライフサイクルマイルストーンで呼ばれているか
   - emotion_tag と importance が適切に設定されているか

### AtoA会話との統合チェック
1. 会話開始時に `retrieve_memories()` が両ペットに対して呼ばれるか
2. `retrieve_shared_memories()` が呼ばれるか
3. 検索結果がプロンプトに注入される形式が適切か:
   - タイムスタンプが人間可読形式（"12h ago"）に変換されるか
   - importance が数値で表示されるか
   - 記憶内容が簡潔に要約されるか
4. 会話終了時に Hebbian 強化が呼ばれるか

## デバッグ手順

### 「記憶が活用されていない」場合
1. `retrieve_memories()` の返り値を確認 → 空配列？
2. 記憶が格納されているか確認 → 海馬に何件ある？
3. クエリの context_tags がマッチしているか
4. personality バイアスが極端すぎないか
5. 対処: retrieve の閾値を下げる or context_tags のマッチング条件を緩和

### 「記憶が古いものばかり」場合
1. recency スコアの重みが低すぎないか
2. 睡眠統合で古い記憶が固定化されすぎていないか
3. 新しい記憶の importance が低く設定されていないか
4. 対処: recency の重みを上げる or 新規記憶の初期 importance を見直す

### 「記憶容量が膨らみすぎ」場合
1. ペットあたりの記憶件数を確認
2. 忘却（garbage collection）が定期的に走っているか
3. 低重要度記憶の破棄閾値が適切か
4. 対処: 睡眠統合の頻度を上げる or 重要度閾値を引き上げ

## パフォーマンス指針
- 記憶検索はフレーム内処理（API呼び出しなし）→ O(n) だが n < 100 なので問題なし
- 睡眠統合はバックグラウンド処理可能（非同期）
- Hebbian強化は会話終了時のみ（低頻度）
- save/load は to_dict()/from_dict() でJSON直列化 → 記憶件数に比例
