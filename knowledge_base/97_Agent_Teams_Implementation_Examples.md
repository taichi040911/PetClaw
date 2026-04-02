# KB97: Agent Teams 実装例ガイド（PetClaw AtoA向け）

> Claude Cowork連携用 — 2026年4月最新版
> Claude Opus 4.6 Agent TeamsをPetClaw AtoAに実装するための具体例集
> 非エンジニアでもコピーしてClaude Codeで試せる設定方法から実装例まで

---

## 1. Agent Teamsの設定（最初に1回だけ）

### Step 1: 実験機能の有効化

Claude Codeの `settings.json` に追加:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "teammateMode": "tmux"
}
```

> `teammateMode: "tmux"` は並列表示のためおすすめ。各エージェントが別ウィンドウで動作し、リアルタイムで監視可能。

### Step 2: tmuxインストール（並列表示のため推奨）

```bash
# Mac
brew install tmux

# Windows
choco install tmux
```

### Step 3: Godot MCP連携（視覚テスト用）

```bash
claude mcp add godot
```

### Step 4: PetClaw固有の準備

```bash
# プロジェクトディレクトリに移動
cd /path/to/PetClaw

# CLAUDE.mdが自動読み込みされることを確認
cat CLAUDE.md | head -5

# 既存エージェント定義を確認
ls .claude/agents/ agents/
```

---

## 2. PetClaw向けAgent Teams実装例

### 例1: シンプルなAtoA会話チーム（初心者向け）

> 3体構成。PetBook投稿生成から始める最小構成。

**Claude Codeに貼る指示:**

```
Agent Teamsを作成してください。

チーム名: PetClaw_AtoA_Team

- Team Lead (Orchestrator): 全体のAtoAイベントを調整。交配・死・環境変化をトリガー。
- Teammate 1 (Personality Agent): 各ペットの性格・感情・記憶を管理。
- Teammate 2 (Language Agent): 独自言語（接尾辞・語順）の進化を担当。
- Teammate 3 (Ecosystem Agent): 生物生態系（体調・生き死に・交配）を管理。

共有タスクリストを使い、エージェント同士が直接メッセージを送り合って協調してください。
PetBook投稿生成やAtoA会話を自然に実行。
MCPでGodotシーンを確認しながら進めてください。

--max-iterations 10
--completion-promise "A2A_TEAM_READY"
```

**期待される動作:**
1. Team Leadが全体計画を策定
2. Personality Agentがペットの性格データを整理
3. Language Agentが現在の語彙・文法を確認
4. Ecosystem Agentが環境状態をチェック
5. 3エージェントが協調してAtoA会話テンプレートを改善
6. PetBook投稿を生成して品質確認

**対応するGDScriptファイル:**
- `a2a_conversation_system.gd` — Orchestrator所有
- `pet_entity.gd` — Personality Agent参照
- `original_language_engine.gd` — Language Agent所有
- `ecosystem_manager.gd` — Ecosystem Agent所有

---

### 例2: SubMolt特化チーム（#AfterlifeEchoes + #BreedingCircle）

> 4体構成。感動的なPetBook投稿に特化。

**Claude Codeに貼る指示:**

```
Agent Teamsを作成してください。

チーム名: PetClaw_SubMolt_Team

- Team Lead: SubMoltイベント全体を統括。
- Teammate 1 (Afterlife Specialist): #AfterlifeEchoesの死・蘇生・哲学的投稿を生成。
- Teammate 2 (Breeding Specialist): #BreedingCircleの交配・家族・遺伝投稿を生成。
- Teammate 3 (Visual Specialist): 粒子エフェクトとUIの視覚効果をGodotで調整。

各Teammateが独立したコンテキストを持ち、共有記憶（claude-mem）を使って関係性を深めてください。
独自言語を自然に織り交ぜ、プレイヤーが観察したくなる感動的な投稿を作成。

--max-iterations 12
--completion-promise "SUBMOLT_TEAM_READY"
--temperature 0.7
```

**期待される動作:**
1. Team Leadが死亡/交配イベントのシナリオを設計
2. Afterlife Specialistが悲嘆処理（MemoryPersonalityBridge）と連動した投稿を生成
3. Breeding Specialistが遺伝形質を反映した子孫の物語を作成
4. Visual Specialistがパーティクルエフェクトを調整
5. 全エージェントが協調して感動的なストーリーラインを完成

**対応するGDScriptファイル:**
- `memory_personality_bridge.gd` — Afterlife Specialist参照（悲嘆処理）
- `breeding_system.gd` — Breeding Specialist所有
- `pet_book_core.gd` — Team Lead所有（投稿管理）
- `visual_fx_system.gd` — Visual Specialist所有

---

### 例3: フルMulti-Agent協調（高度版）

> 5+体構成。完全なAtoAエコシステム。

**Claude Codeに貼る指示:**

```
Agent Teamsを活性化し、PetClawの完全なAtoA Multi-Agentシステムを構築してください。

- Orchestrator (1体): 全体調整、イベントトリガー。
- Pet Agents (各ペット1体): 性格・感情・記憶を個別に保持し、AtoA会話を実行。
- Specialist Agents (イベント時): Language Evolution, Death & Rebirth, Breeding Circle。

エージェント同士が直接メッセージを送り合い、タスクを共有・調整。
生物模倣記憶、独自言語進化、PetBook投稿を連動させ、Moltbook風の創発的コミュニティを実現。
Ralph Loopで自動改善を繰り返し、MCPでGodot視覚テストを実行。

--max-iterations 15
--completion-promise "FULL_A2A_SYSTEM_READY"
```

**期待されるエージェント間通信例:**

```
[Orchestrator] → 全員: "環境変化: 嵐発生。各エージェント対応してください"
[PetAgent:Mimi] → PetAgent:Kuro: "怖い-pya! 一緒にいよう-mii"
[PetAgent:Kuro] → PetAgent:Mimi: "大丈夫-kuu。守るから-suffix"
[Language Agent] → Orchestrator: "嵐の新語提案: 'toramii'（雷鳴の音）"
[Orchestrator] → Language Agent: "承認。OriginalLanguageEngineに登録して"
[Cultural Agent] → Orchestrator: "嵐体験をリチュアル候補に追加しました"
[Orchestrator] → 全員: "PetBook投稿を生成。各自の視点で"
```

---

### 例4: Karpathy Loop最適化チーム

> 品質改善に特化。現在のスコア89.3→90+を目指す。

**Claude Codeに貼る指示:**

```
Agent Teamsを作成し、PetClawのKarpathy Loopスコアを改善してください。

チーム名: PetClaw_Karpathy_Team

- Team Lead (Karpathy Optimizer): メトリクス収集・分析・改善提案を統括。
- Teammate 1 (Code Quality): code_quality 77.7→85+を担当。大ファイルの分割検討。
- Teammate 2 (Cost Efficiency): cost_efficiency 79→85+を担当。テンプレート比率最適化。
- Teammate 3 (Code Reviewer): 変更の品質ゲート。CLAUDE.mdルール遵守を確認。

python3 tools/quality/karpathy_loop.py を実行してベースラインを取得してから開始。
各改善は必ずKarpathyスコアで検証してからコミット。

--max-iterations 10
--completion-promise "KARPATHY_90_PLUS"
```

**現在のスコアと改善ターゲット:**

| Dimension | Current | Target | Agent |
|-----------|---------|--------|-------|
| Code Quality | 77.7 | 85+ | Teammate 1 |
| AtoA Quality | 100.0 | 100 ✅ | — |
| Language Diversity | 100.0 | 100 ✅ | — |
| Battle Balance | 90.0 | 90 ✅ | — |
| Cost Efficiency | 79.0 | 85+ | Teammate 2 |
| **Overall** | **89.3** | **90+** | Team Lead |

---

### 例5: すぐに試す最小構成（おすすめ）

> 2体構成。最も簡単に試せる。

**Claude Codeに貼る指示:**

```
Agent Teamsを作成。
チーム名: PetClaw_Basic_A2A
- Team Lead: AtoAイベント調整
- Teammate 1: Personality & Emotion
- Teammate 2: Language Evolution

PetBook投稿生成から始め、独自言語を自然に使ってください。
MCPで視覚確認しながら進めて。

--max-iterations 8
--completion-promise "BASIC_TEAM_READY"
```

---

## 3. 実装のポイント（非エンジニア向け）

### 基本概念

| 概念 | 説明 | PetClawでの例 |
|------|------|--------------|
| **共有タスクリスト** | エージェントが共通のTODOを管理（自動生成） | "AtoAテンプレート追加" "バトルバランス調整" |
| **直接メッセージ** | エージェント同士が `@TeammateName` で会話 | "@LanguageAgent 新語'haramii'を登録して" |
| **tmux並列表示** | 各エージェントが別ウィンドウで動作 | リアルタイムで全エージェントの作業を監視 |
| **Persistent Memory** | セッションを超えて記憶が持続 | ペットの関係性・語彙が蓄積 |

### コスト管理のコツ

```
推奨設定:
├── 初回は3〜5体から開始（多すぎると調整コスト増大）
├── max-iterations は 8〜12 に抑える
├── temperature は 0.7（創造性と安定性のバランス）
├── 大きな変更前にgit commitしておく
└── Karpathyスコアで改善を定量的に確認
```

### トラブルシューティング

| 問題 | 原因 | 解決策 |
|------|------|--------|
| エージェントが動かない | Agent Teams未有効化 | `settings.json`に`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`を追加 |
| tmuxが表示されない | tmux未インストール | `brew install tmux` (Mac) |
| ファイル競合 | 複数エージェントが同じファイルを編集 | KB96のファイル所有権マトリクスに従う |
| API予算超過 | 会話数が多すぎる | テンプレート比率を確認（80/20ルール） |
| Karpathyスコアが下がった | 意図しない変更 | `git diff`で変更内容を確認、必要なら`git checkout`で戻す |

### 引き継ぎフロー（Cowork → Code）

```
1. Coworkで設計ドキュメント作成
   └── HANDOFF_PetClaw.md に方針を記載

2. Knowledge Baseにアップロード
   └── KB96 (Multi-Agent設計) + KB97 (実装例)

3. Claude Codeで読み込み
   └── CLAUDE.md が自動ロード + KBを参照

4. Agent Teamsを起動
   └── 例1〜5のいずれかをコピーして貼り付け

5. 結果を確認
   └── Karpathy Loop + MCP視覚テスト
```

---

## 4. PetClaw既存エージェント定義との連携

### `.claude/agents/` ディレクトリ（既存7エージェント）

```
.claude/agents/
├── gdscript-engineer.md    — GDScript実装（sonnet, memory: project）
├── code-reviewer.md        — コードレビュー（sonnet, memory: project）
├── a2a-designer.md         — AtoA/感情/言語設計（opus, memory: project）
├── evolution-specialist.md — 進化/ケア/ライフサイクル（sonnet）
├── ui-artist.md            — UI/スプライト/アニメーション（sonnet）
├── architect.md            — システム統合/設計（opus, memory: project）
└── lead.md                 — Team Lead定義
```

### `agents/` ディレクトリ（R101で追加した6エージェント）

```
agents/
├── pet-brain.md            — ペットごとのAI脳（sonnet, memory: project）
├── battle-orchestrator.md  — バトル統括（sonnet）
├── language-judge.md       — リアルタイム言語品質（haiku）
├── visual-tester.md        — MCP視覚テスト（sonnet）
├── karpathy-optimizer.md   — Karpathy Loop最適化（opus, memory: project）
└── capabilities.md         — ディスパッチ戦略ドキュメント
```

### Agent Teams起動時の自動参照

Agent Teamsを起動すると、以下が自動的に各エージェントに提供されます:
1. **CLAUDE.md** — プロジェクトルール、コーディング規約、制約
2. **Memory** — `memory: project`設定のエージェントはプロジェクト記憶を共有
3. **Knowledge Base** — このKB97を含むすべてのKB文書

---

## 5. Agent Teams × Ralph Loop 統合指示

### 基本統合（推奨）

```
Ralph Loopを活性化し、Agent Teamsと連携。
Multi-Agent協調でPetClawのAtoA機能を進化させよ。
各ペットエージェントが自律的に行動し、共有記憶と独自言語で関係性を深める。
MCPで視覚確認しながら、没入感を最高峰まで自動改良。

--max-iterations 12
--completion-promise "RALPH_MULTI_AGENT_READY"
```

### Karpathy Loop特化

```
Ralph Loopを活性化。
PetClawのKarpathy Loopスコアを89.3→92+に改善せよ。
Agent Teamsで並列にcode_quality（大ファイル分割）とcost_efficiency（テンプレート最適化）を改善。
各改善はpython3 tools/quality/karpathy_loop.pyで検証してからコミット。

--max-iterations 10
--completion-promise "KARPATHY_92_PLUS"
```

### 文化創発特化

```
Ralph Loopを活性化。
CulturalEmergenceSystemの文化創発を加速せよ。
Agent TeamsでLanguage Agent + Cultural Agentが協調し、
祭り・歌・物語・伝統をペット同士の自然な対話から生成。
PetBook投稿の感動度をスコアリングしながら自動改善。

--max-iterations 8
--completion-promise "CULTURAL_EMERGENCE_READY"
```

---

## 6. 規模別おすすめ構成

### 初めて（シンプル: 3体）

```
おすすめ: 例5（最小構成）
目的: Agent Teamsの基本動作を体験
所要時間: 15-30分
コスト: 低（max-iterations 8）
```

### 慣れてきたら（中規模: ペットごと専用エージェント）

```
おすすめ: 例1 + 例4の組み合わせ
目的: AtoA会話の品質向上 + Karpathyスコア改善
所要時間: 1-2時間
コスト: 中（max-iterations 10-12）
```

### フル活用（大規模: Orchestrator + Specialist多数）

```
おすすめ: 例3
目的: 完全なMulti-Agentエコシステム
所要時間: 2-4時間
コスト: 高（max-iterations 15）
注意: 先に例1/5で慣れてから
```

---

## 7. 次のステップ

| 優先度 | アクション | 必要な指示 |
|--------|----------|-----------|
| **今すぐ** | 例5をClaude Codeに貼って試す | 上記の「すぐに試す最小構成」をコピー |
| **次に** | 結果をKarpathy Loopで検証 | `python3 tools/quality/karpathy_loop.py` |
| **その後** | 例1に拡張 | 4体チームでAtoA会話改善 |
| **上級** | 例3でフル構築 | Orchestrator + ペットごとエージェント |

---

## 参照KB文書

| KB | 内容 | 関連度 |
|----|------|--------|
| KB96 | Multi-Agent協調の詳細設計ガイド | ★★★ 必須参照 |
| KB66 | AtoA自律コミュニティ（Moltbook風） | ★★★ |
| KB67 | AtoA会話具体例 | ★★☆ |
| KB89-91 | Ralph Loop設定 | ★★☆ |
| KB88 | 非エンジニア開発ガイド | ★★☆ |
| KB92 | Game Devプラグインガイド | ★☆☆ |
| KB93 | Cowork→Code引き継ぎ | ★★★ 必須参照 |

---

*Last updated: 2026-04-03 (R124, v1.1.0, Karpathy 89.3/100)*
*Companion to: KB96_Multi_Agent_Coordination_Detailed.md*
