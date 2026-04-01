# PetClaw マルチエージェント開発体制設計
**設計日: 2026-04-01**

## 1. 参照ソース

### Zenn記事: o-m-cc × Agent Teams (kok1eee)
- Agent Teams: peer-to-peer teammate間メッセージング（subagentの「結果を返すだけ」からの進化）
- ディスパッチ戦略: S(直接)/M(2-3 teammates)/L(5+)の3段階
- 相乗効果パターン: 相互レビュー、仮説競合、設計批評、並列実装
- hooks自動化: TeammateIdle → 残タスク再割り当て、TaskCompleted → 進捗通知
- memory: project で判断・学習を永続記憶

### ComposioHQ/agent-orchestrator
- git worktree隔離: 各エージェントが独立worktreeで作業
- CIフィードバック自動ルーティング: 失敗→担当エージェントに自動差し戻し
- 7プラガブルスロット: Runtime, Workspace, Tracker, Notifiers

### nyldn/claude-octopus
- 8モデル並列: 複数LLMによるコンセンサスチェック
- Double Diamond方法論: Discover→Define→Develop→Deliver
- 75%コンセンサスゲート: 過半数一致で品質保証
- 51 skills × 32 agents × 48 slash commands

### awslabs/agent-plugins
- プラグインパッケージパターン: skills + MCP servers + hooks + references
- トリガーフレーズ: 文脈に応じたスキル自動アクティベーション
- 再利用可能な能力定義 > コンテキスト重視プロンプト

### modelcontextprotocol/modelcontextprotocol
- 標準プロトコル: AI → 外部システム接続のオープン仕様
- tools, resources, prompts, sampling の4概念
- TypeScript-first スキーマ定義

---

## 2. PetClaw Agent Teams 体制

### 6エージェント構成

```
Lead（開発者 / メインClaude）
  │
  ├── architect (opus, memory)
  │     └─ システム統合、アーキテクチャ文書、第一原理、技術選定
  │
  ├── gdscript-engineer (sonnet, memory)
  │     └─ GDScript実装、GameManager統合、セーブ/ロード
  │
  ├── a2a-designer (opus, memory)
  │     └─ AtoA会話、言語進化、感情モデル、プロンプト設計
  │
  ├── evolution-specialist (sonnet, memory)
  │     └─ 進化ツリー、ケア、ダーク進化、ライフサイクル
  │
  ├── ui-artist (sonnet, memory)
  │     └─ UIプロトタイプ、スプライト、アニメーション
  │
  └── code-reviewer (sonnet, memory)
        └─ クロスシステム整合性、品質、PetClaw固有ルール
```

### ディスパッチ戦略

| 規模 | 判定基準 | 方式 | 例 |
|------|---------|------|-----|
| **S** | Glob/Grep 1回で済む | Lead直接 | 「このクラスどこ？」 |
| **M** | 単一〜2システム | 2-3 teammates | 新しい感情追加、進化パス追加 |
| **L** | 3+システム横断 | 5+ teammates | バッチ実装（進化+表情+UI+AtoA） |

### コマンド設計

| コマンド | パターン | 出典 | teammates |
|---------|---------|------|----------|
| `/implement` | 設計→実装→レビュー | agent-orchestrator | 3-5 |
| `/review` | 相互レビュー+コンセンサス | o-m-cc + claude-octopus | 2 |
| `/debug` | 仮説競合 | o-m-cc | 2-3 |
| `/ultrawork` | 大規模並列 | o-m-cc + agent-orchestrator | 5+ |

---

## 3. 相乗効果パターン（PetClaw適用）

### パターン1: 相互レビュー
```
code-reviewer: 「evolution_mechanics.gdでget_vocabulary_size()が未定義」
architect: 「original_language_engine.gdにはget_full_vocabulary()がある。.size()で代替」
→ 互いの発見を共有して即座にバグを特定
```

### パターン2: 仮説競合
```
engineer: 「AtoA会話が開始しない → ethical_safeguard の日次上限？」
architect: 「いや、persistent_field の session_resume で adventures処理中にブロック？」
→ 議論して真因を特定: 実は on_new_day() が呼ばれていなかった
```

### パターン3: 設計批評
```
a2a-designer: 「感情スパイク時にフラッシュバルブ記憶を生成する設計」
architect: 「それだとAPIコスト増大。P2に反する。閾値を0.8→0.9に上げてはどうか」
→ 建設的議論で最適閾値を決定
```

### パターン4: 並列実装（/ultrawork）
```
同時spawn:
  gdscript-engineer → 新しいケアアクション実装
  a2a-designer → AtoA会話トリガー追加
  evolution-specialist → 進化条件にケアアクション反映
  ui-artist → UIボタンとアニメーション追加
→ code-reviewer が最後に全体整合性チェック
```

---

## 4. memory: project の活用

### 記憶させるエージェントと内容

| エージェント | 記憶する知見 |
|-------------|-----------|
| gdscript-engineer | PetClaw固有のGDScriptパターン、過去のバグ修正 |
| code-reviewer | プロジェクト固有の整合性ルール、よくある問題 |
| a2a-designer | AtoAプロンプトの改善履歴、効果的な感情表現パターン |
| evolution-specialist | 進化バランス調整の履歴、プレイテスト結果 |
| ui-artist | UIデザインの決定履歴、カラーパレットルール |
| architect | アーキテクチャ判断の履歴、システム間の暗黙の依存 |

### 記憶させないもの
- コードの具体的内容（コードを読めばわかる）
- git履歴（git logで取得可能）
- 一時的なデバッグ状態

---

## 5. ファイル構成

```
.claude/
├── agents/
│   ├── capabilities.md           # ディスパッチ戦略 + 全エージェント能力サマリー
│   ├── gdscript-engineer.md      # GDScript実装者
│   ├── code-reviewer.md          # コードレビュアー
│   ├── a2a-designer.md           # AtoA/感情/言語設計者
│   ├── evolution-specialist.md   # 進化/ケア/ライフサイクル専門家
│   ├── ui-artist.md              # UI/スプライト/アニメーション
│   └── architect.md              # システム設計者
├── commands/
│   ├── implement.md              # 機能実装オーケストレーション
│   ├── review.md                 # 相互レビュー
│   ├── debug.md                  # 仮説競合デバッグ
│   └── ultrawork.md              # 大規模並列実装
└── hooks/                        # (将来: TeammateIdle, TaskCompleted)
CLAUDE.md                          # プロジェクトルール
```
