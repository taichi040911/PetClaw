# 58. 持続的記憶システム 深掘りガイド

## 1. avatar-uiのField実装分析

### 永続化メカニズム
- **state.json**: atomic write + 1-generation backup + corruption recovery
- **Long-term Memory**: xAI Collections API（RAG対応）
- **Avatar Space**: ~/Avatar/space ファイルシステム
- **Reciprocity Loop**: シリアライズドキューで時間的一貫性

### Field状態遷移
```
generated → active → paused → resumed → terminated
```

### 設計上の制約
- 単一ユーザー設計（複数アバター間記憶共有は未サポート）
- Electron GUI + Headlessサーバー両対応

## 2. 類似プロジェクト比較

| プロジェクト | 特徴 | PetClaw参考度 |
|-----------|------|-------------|
| memodb-io/memobase | ユーザープロファイルベース長期記憶、RAG統合 | ★★★★★ |
| oceanbase/powermem | AI駆動長期記憶、マルチエージェント対応 | ★★★★ |
| Kiyoraka/Project-AI-MemoryCore | Markdownベース軽量永続記憶 | ★★★ |
| NevaMind-AI/memU | 3層メモリ（短期・長期・プロファイル）、自動構造化 | ★★★★★ |
| Rotoslider/long-term-memory-mcp | SQLite + ChromaDB、生物的time-based lazy decay | ★★★★★ |
| Jenova.ai | 無制限チャット履歴 + クロスセッション記憶 | ★★★ |

## 3. PetClaw PersistentField 設計仕様

### 責務
1. **共有記憶フィールド**: 全ペットがアクセスできる「場」の記憶
2. **セッション永続化**: atomic write + backup でstate.json保存
3. **オフライン自律行動**: 非アクティブ時間にペットが「冒険」→ 帰還報告
4. **BiologicalMemoryとの連携**: Field記憶 = 全ペット共通の長期記憶層

### データ構造
```gdscript
var field_state: Dictionary = {
    "shared_events": Array[Dictionary],     # 全ペット共有のイベント記録
    "community_topics": Array[String],       # コミュニティの話題
    "relationship_graph": Dictionary,        # ペット間関係性マップ
    "offline_adventures": Array[Dictionary], # オフライン時の冒険ログ
    "cultural_artifacts": Array[Dictionary], # コミュニティ文化
    "field_mood": Dictionary,               # フィールド全体の雰囲気
    "last_save_time": float,
    "session_count": int,
}
```

### atomic write プロトコル
1. 新データを `.tmp` ファイルに書き込み
2. 現行ファイルを `.bak` にリネーム（1世代バックアップ）
3. `.tmp` を正式ファイルにリネーム
4. 破損検出時は `.bak` から自動復旧
