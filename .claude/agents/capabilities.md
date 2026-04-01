---
name: capabilities
---

# PetClaw Agent Capabilities — ディスパッチ戦略

## エージェント一覧

| エージェント | model | memory | 得意領域 |
|-------------|-------|--------|---------|
| **gdscript-engineer** | sonnet | project | GDScript実装、GameManager統合、セーブ/ロード |
| **code-reviewer** | sonnet | project | クロスシステム整合性、GDScript品質、PetClaw固有ルール |
| **a2a-designer** | opus | project | AtoA会話設計、言語進化、感情モデル、プロンプト設計 |
| **evolution-specialist** | sonnet | project | 進化ツリー、ケアシステム、ダーク進化、ライフサイクル |
| **ui-artist** | sonnet | project | UIプロトタイプ、スプライト、アニメーション、UX |
| **architect** | opus | project | システム統合、アーキテクチャ文書、第一原理、技術選定 |

## ディスパッチ判断フロー

```
タスクを受け取る
  │
  ├─ Glob/Grep 1回で答えが出る？ → 【S】Lead直接実行
  │
  ├─ 単一システムの実装？ ─────→ 【M】gdscript-engineer + code-reviewer
  │
  ├─ AtoA/感情/言語に関連？ ──→ 【M】a2a-designer + gdscript-engineer + code-reviewer
  │
  ├─ 進化/ケア/生死に関連？ ──→ 【M】evolution-specialist + code-reviewer
  │
  ├─ UIの変更？ ──────────────→ 【M】ui-artist + code-reviewer
  │
  ├─ 複数システム横断？ ──────→ 【L】architect + 関連specialists + code-reviewer
  │
  ├─ バグ調査？ ──────────────→ 【M】/debug (仮説競合パターン)
  │
  └─ 大規模実装？ ────────────→ 【L】/ultrawork (5+ teammates)
```

## コマンド一覧

| コマンド | 用途 | teammates数 |
|---------|------|------------|
| `/implement` | 機能実装 | 3-5 (architect → engineer → reviewer) |
| `/review` | 相互レビュー | 2 (code-reviewer + architect) |
| `/debug` | 仮説競合デバッグ | 2-3 (engineer + architect → 修正) |
| `/ultrawork` | 大規模並列実装 | 5+ (全エージェント動員) |

## 相乗効果パターン（o-m-cc/claude-octopus知見）

| パターン | 組み合わせ | PetClaw適用例 |
|---------|-----------|-------------|
| **相互レビュー** | code-reviewer + architect | シグナル設計の二重検証 |
| **仮説競合** | engineer × 2 or engineer + architect | バグの原因を並列仮説で絞り込み |
| **設計批評** | a2a-designer + architect | AtoAプロンプト設計の品質保証 |
| **並列実装** | engineer + a2a-designer + evolution-specialist | 独立システムの同時実装 |
| **全方位** | 6エージェント全員 | バッチ実装（進化+表情+UI+AtoA） |

## 判断基準: いつAgent Teamsを使うか

**Agent Teams を使う (M/L)**:
- 議論・協調が必要
- 複数視点からの検証が価値を生む
- 並列実行で時間短縮できる

**Lead直接実行 (S)**:
- 単一ファイルの小修正
- 情報検索
- ドキュメント更新のみ
