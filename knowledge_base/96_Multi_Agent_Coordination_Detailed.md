# KB96: Multi-Agent協調の詳細設計ガイド（PetClaw AtoA向け）

> Claude Cowork連携用 — 2026年4月最新版
> PetClawのAtoA機能をMulti-Agent協調で実現する詳細設計ドキュメント

---

## 1. Multi-Agent協調の概要（2026年Claude最新）

Claude Opus 4.6以降のAgent Teamsは、単なる「複数のAIを並列で動かす」ではなく、エージェント同士が直接コミュニケーションを取り、共有タスクリストで協調する本格的なMulti-Agent orchestrationシステムです。

### Sub-Agentとの違い（重要）

| 項目 | Sub-Agent | Agent Teams |
|------|-----------|-------------|
| 通信 | メイン→子の一方向 | 双方向ピアツーピア |
| コンテキスト | 親が管理 | 各エージェントが独立保持 |
| タスク管理 | 親が割り当て | 共有タスクリストで自律的に主張・調整 |
| 協調 | なし（子同士は会話しない） | Team Leadが統括、メイト同士がメッセージ交換 |
| 記憶 | セッション単位 | Persistent Memory（claude-mem等）で永続化 |

### PetClawでの価値

- 各ペットに専用エージェントを割り当て、AtoA会話・バトル・生態系イベントを並列かつ自律的に実行
- ペット同士が「記憶を共有」「イベントを提案」「言語を共同進化」するMoltbook風体験を実現
- Ralph Loopと組み合わせると、数百回の自動改善が可能

---

## 2. PetClaw向けMulti-Agent階層設計

### 推奨構造（48エージェント構想を現実的にスケール）

```
Tier 1: Orchestrator (Team Lead)
├── 役割: 全体調整、イベントトリガー（交配・死・環境変化）、AtoA会話の統括
├── 実体: 1〜2体（Orchestratorペット or 中央AI）
├── 担当ファイル: game_manager.gd, a2a_conversation_system.gd
└── 権限: 全システムへの読み書きアクセス

Tier 2: Specialist Agents（ペットごとの専用エージェント）
├── 各ペットに1つのメインエージェント
├── 担当: Personality + Emotion + Memory
├── 例: Braveペット → 戦闘・訓練特化
├── 例: Curiousペット → 探索・言語創発特化
└── 担当ファイル: pet_entity.gd（自ペット分のみ）

Tier 3: Temporary Teammates（イベント時のみ生成）
├── 交配時: Breeding Specialist
├── 死・蘇生時: Afterlife Specialist
├── 言語進化時: Language Evolution Specialist
├── バトル時: Battle Orchestrator
└── 文化創発時: Cultural Emergence Specialist
```

### 通信方法

| 方法 | 用途 | 実装 |
|------|------|------|
| Shared Task List | 共通のタスク管理 | Git/Memory Agent経由 |
| Peer-to-Peer Messaging | エージェント間直接通信 | Agent Teams SendMessage |
| Persistent Memory | 長期記憶共有 | claude-mem / BiologicalMemorySystem |
| Signal Bus | リアルタイムイベント | Godot Signals (GDScript) |

---

## 3. 現在のPetClaw実装との対応

### 既存Agent定義（`.claude/agents/` + `agents/`）

| エージェント | Tier | 用途 | ファイル |
|-------------|------|------|---------|
| gdscript-engineer | 2 | GDScript実装 | `.claude/agents/gdscript-engineer.md` |
| code-reviewer | 2 | コードレビュー | `.claude/agents/code-reviewer.md` |
| a2a-designer | 1 | AtoA/感情/言語設計 | `.claude/agents/a2a-designer.md` |
| evolution-specialist | 2 | 進化/ケア/ライフサイクル | `.claude/agents/evolution-specialist.md` |
| ui-artist | 2 | UI/スプライト/アニメーション | `.claude/agents/ui-artist.md` |
| architect | 1 | システム統合/設計 | `.claude/agents/architect.md` |
| pet-brain | 2 | ペットごとのAI脳 | `agents/pet-brain.md` |
| battle-orchestrator | 3 | バトル統括 | `agents/battle-orchestrator.md` |
| language-judge | 3 | リアルタイム言語品質 | `agents/language-judge.md` |
| visual-tester | 3 | MCP視覚テスト | `agents/visual-tester.md` |
| karpathy-optimizer | 1 | Karpathy Loop最適化 | `agents/karpathy-optimizer.md` |

### 既存GDScriptシステムとのマッピング

| GDScriptシステム | Agent Teams対応 | 説明 |
|-----------------|----------------|------|
| `AtoAConversationSystem` | Orchestrator + Pet Agents | ペットエージェント間の直接対話 |
| `PetTeamOrchestrator` | Tier 2 協調 | ペットチーム編成・タスク実行 |
| `CulturalEmergenceSystem` | Tier 3 Cultural Specialist | 文化的アーティファクト生成 |
| `MemoryPersonalityBridge` | Persistent Memory層 | 記憶→性格→行動の橋渡し |
| `AtoACommunityCore` | Orchestrator | 派閥形成・コミュニティサイクル |
| `BiologicalMemorySystem` | 全Agentの共有記憶基盤 | 海馬/皮質/Hebbian/アミグダラ |
| `LanguageBattleSystem` | Tier 3 Battle Orchestrator | 言語バトル3ラウンド |

---

## 4. Claude Codeでの実装設定（Agent Teams有効化）

### 有効化

```bash
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

### PetClaw向けAgent Teams起動指示例

```
Agent Teamsを活性化。
PetClawのAtoA Multi-Agent協調チームを作成せよ。

- Team Lead (Orchestrator): 全体イベント調整、AtoA会話統括。
- Teammate 1〜N: 各ペット専用エージェント（性格・感情・記憶を保持）。
- Temporary Teammates: イベント時のみ（交配、死、言語進化）。

共有タスクリストを使い、エージェント同士が直接コミュニケーションを取る。
生物生態系（生き死に・交配・環境）、独自言語進化、PetBook投稿生成を連動。
MCPでGodot視覚テストを行い、Ralph Loopで自動改善。

--max-iterations 12
--completion-promise "MULTI_AGENT_A2A_READY"
--temperature 0.7
```

### ベストプラクティス（2026年最新）

1. **タスク境界を明確に**: 各エージェントにファイル/役割の所有権を与える
   - 例: `pet_entity.gd`は専用ペットエージェント所有
   - 例: `a2a_conversation_system.gd`はOrchestrator所有
2. **3〜5体から開始**: 多すぎると調整コストが増大
3. **Shared Context**: CLAUDE.md + Knowledge Baseを全エージェントに自動ロード
4. **Ralph Loopとの併用**: Agent Teamsで並列実行、Ralph Loopで長時間自動改善
5. **Memory Partitioning**: ペットごとの記憶を分離しつつ、共有フィールドで交差

---

## 5. PetClawでの具体的な活用シーン

### シーン1: AtoA会話（ペットエージェント間直接通信）

```
[Orchestrator] → "MimiとKuroの会話を開始"
[PetAgent:Mimi] → "こんにちは-pya! 今日の空は綺麗-mii"
[PetAgent:Kuro] → "うん-kuu。でも少し寂しい-suffix..."
[PetAgent:Mimi] → "*Kuroに近づく-mii* 一緒にいるよ-pya"
[Orchestrator] → "会話完了。関係性+0.05、PetBook投稿生成"
```

### シーン2: 生態系イベント（Orchestrator → Specialists）

```
[Orchestrator] → "環境変化: 嵐が発生"
[Orchestrator] → PetAgent全体に通知
[PetAgent:Mimi] → "怖い-pya! *震える*" (brave低い)
[PetAgent:Kuro] → "大丈夫-kuu。守るから-suffix" (brave高い)
[Cultural Specialist] → "嵐の記憶をリチュアル候補に追加"
[Language Specialist] → "嵐の新語候補: 'toramii'（雷の音）"
```

### シーン3: 独自言語創発（Language Specialist協調）

```
[Language Specialist] → "語彙プール分析: 接尾辞-miiが優勢"
[PetAgent:Mimi] → "新しい挨拶を提案: 'haramii-pya'"
[PetAgent:Kuro] → "受け入れ。使用開始-kuu"
[Orchestrator] → "新語 'haramii' をOriginalLanguageEngineに登録"
[Cultural Specialist] → "この言葉が定着したら歌に組み込む"
```

### シーン4: 生き死に・交配（Temporary Teammates）

```
[Orchestrator] → "ペット死亡イベント: Elder Tama"
[Afterlife Specialist] → 生成
[Afterlife Specialist] → "悲嘆処理開始: 関係性0.8以上のペット3匹"
[MemoryBridge] → "Kübler-Ross Stage 1: Denial"
[PetAgent:Mimi] → "嘘-pya... Tamaはいなくなったの-pya?"
[PetBook] → "#AfterlifeEchoes 投稿生成"
[Afterlife Specialist] → 完了 → 破棄
```

---

## 6. Karpathy Loop + Ralph Loopとの統合

### 統合指示テンプレート

```
Ralph Loopを活性化し、Agent Teamsと連携。
Multi-Agent協調でPetClawのAtoA機能を進化させよ。
各ペットエージェントが自律的に行動し、共有記憶と独自言語で関係性を深める。
MCPで視覚確認しながら、没入感を最高峰まで自動改良。

--max-iterations 12
--completion-promise "KARPATHY_MULTI_AGENT_OPTIMIZED"
```

### Karpathy Loop連携フロー

```
1. Collect Metrics
   ├── コード品質: lint + 行数分析
   ├── AtoA品質: プロンプトトークン + テンプレート多様性
   ├── 言語多様性: 音節プール + 文法ステージ
   ├── バトルバランス: スコア分散 + テンプレート分布
   └── コスト効率: API/テンプレート比率

2. Evaluate (Agent Teams並列)
   ├── [code-reviewer] コードレビュー
   ├── [a2a-designer] AtoA会話品質評価
   ├── [language-judge] 言語創発評価
   └── [visual-tester] MCP視覚テスト

3. Analyze & Suggest
   └── [karpathy-optimizer] 改善提案を生成

4. Improve (Agent Teams並列実行)
   ├── [gdscript-engineer] コード修正
   ├── [evolution-specialist] バランス調整
   └── [ui-artist] UI改善

5. Repeat (max-iterations回)
```

### 現在のKarpathyスコア（v1.1.0, R123時点）

| Dimension | Score | Target |
|-----------|-------|--------|
| Code Quality | 77.7 | 85+ |
| AtoA Quality | 100.0 | 100 ✅ |
| Language Diversity | 100.0 | 100 ✅ |
| Battle Balance | 90.0 | 90 ✅ |
| Cost Efficiency | 79.0 | 85+ |
| **Overall** | **89.3** | **90+** |

---

## 7. MCP連携（視覚テスト + ペット状態取得）

### PetClaw MCP Server（8ツール）

| ツール | 用途 |
|--------|------|
| `petclaw.lint` | コード品質チェック |
| `petclaw.drift` | 設計ドリフト検出 |
| `petclaw.deslop` | AI生成コードの品質改善 |
| `petclaw.palette` | カラーパレット検証 |
| `petclaw.get_pet_state` | ペット状態取得（感情・性格・記憶） |
| `petclaw.get_battle_stats` | バトル統計 |
| `petclaw.get_language_metrics` | 言語進化メトリクス |
| `petclaw.karpathy_metrics` | Karpathy Loop全指標 |

### Claude Preview MCP（視覚テスト）

```
Visual Testerエージェントの作業フロー:
1. preview_start → Godot Web exportを起動
2. preview_screenshot → 現在の画面をキャプチャ
3. preview_click → UI要素をタップ
4. preview_console_logs → エラーログを確認
5. 問題発見 → gdscript-engineerに修正依頼
```

---

## 8. ファイル所有権マトリクス

| ファイル | 所有エージェント | 権限 |
|---------|-----------------|------|
| `game_manager.gd` | architect | Read/Write |
| `a2a_conversation_system.gd` | a2a-designer | Read/Write |
| `pet_entity.gd` | pet-brain (per-pet) | Read/Write |
| `language_battle_system.gd` | battle-orchestrator | Read/Write |
| `original_language_engine.gd` | language-judge | Read/Write |
| `cultural_emergence_system.gd` | a2a-designer | Read/Write |
| `pet_team_orchestrator.gd` | architect | Read/Write |
| `memory_personality_bridge.gd` | pet-brain | Read/Write |
| `achievement_system.gd` | evolution-specialist | Read/Write |
| `pet_book_core.gd` | ui-artist | Read/Write |
| `main_scene.gd` | ui-artist | Read/Write |
| All UI screens | ui-artist | Read/Write |
| `karpathy_loop.py` | karpathy-optimizer | Read/Write |
| `petclaw_mcp_server.py` | visual-tester | Read/Write |

---

## 9. 制約とガードレール

### Agent Teams使用時の注意

1. **同時書き込み防止**: 同じファイルを複数エージェントが同時編集しない（所有権マトリクス参照）
2. **API予算遵守**: P2原則（API Cost is Physics）— AtoA $0.50/日、PetBook $0.50/日
3. **テンプレート比率維持**: 80%テンプレート / 20% API（無断で変更しない）
4. **セーブデータ互換性**: to_dict()/from_dict()のキー名変更禁止
5. **Signal名変更禁止**: 既存シグナルは他システムが依存している
6. **enum順序保持**: セーブデータの互換性のため末尾追加のみ

### コスト管理

```
日次予算:
├── AtoA会話: $0.50/日 (MAX_DAILY_CONVERSATIONS: 25)
├── PetBook投稿: $0.50/日
├── Agent Teams実行: 開発コストとして別計上
└── Karpathy Loop: 1回あたり ~$0.01（メトリクス収集のみ）

テンプレートフォールバック:
├── API予算超過 → 即座にテンプレートモード切り替え
├── API障害 → テンプレートで会話継続（沈黙にしない）
└── テンプレート19種 + グループ4種 + イベント6種 = 計29テンプレート
```

---

## 10. 次のマイルストーン（v1.2.0候補）

| 優先度 | 機能 | Agent Teams活用 |
|--------|------|----------------|
| P1 | code_quality 77.7→85+ | code-reviewer + gdscript-engineer |
| P1 | cost_efficiency 79→85+ | karpathy-optimizer |
| P2 | SubMolt大規模コミュニティ | a2a-designer + architect |
| P2 | 物理ハイブリッドインターフェース | architect + ui-artist |
| P3 | メンタルサポート機能 | pet-brain + a2a-designer |
| P3 | Agent Economy（仮想アイテム取引） | architect |

---

## 参照KB文書

| KB | 内容 |
|----|------|
| KB00 | システムアーキテクチャ概要 |
| KB66 | AtoA自律コミュニティ（Moltbook風） |
| KB67 | AtoA会話具体例 |
| KB70 | テンプレートフォールバック仕様 |
| KB89-91 | Ralph Loop設定 |
| KB92 | Game Devプラグインガイド |
| KB93 | Cowork→Code引き継ぎ |
| KB94 | Everything Claude Code活用 |
| KB95 | gstackパターン |

---

*Last updated: 2026-04-03 (R123, v1.1.0, Karpathy 89.3/100)*
