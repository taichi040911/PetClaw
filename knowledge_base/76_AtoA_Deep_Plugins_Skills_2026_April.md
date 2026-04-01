# AtoA サービス開発 プラグイン・スキル 深掘りガイド（2026年4月最新版）

## 概要
KB75（基盤ガイド）を踏まえ、PetClaw の AtoA 会話創発性・持続的記憶・Godot視覚テスト・Karpathy Loop自律実行・言語進化に特化した深掘り情報。
調査元: Anthropic公式、GitHub（awesome-agent-skills, claude-plugins-official）、Reddit/ClaudeAI、Medium、YouTube（2026年3-4月最新投稿）。

---

## 1. 最優先コアプラグイン（必須インストール）

### 1.1 Agent Teams / Agent Factory（★★★★★）
| 項目 | 詳細 |
|------|------|
| **PetClaw効果** | ペットごとに専用エージェントを割り当て、AtoA会話・バトル・生態系イベントを並列実行。持続的記憶付きサブエージェント |
| **インストール** | `.claude/settings.json` に `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` または `/plugin install agent-factory` |
| **深掘り** | 48エージェント構想に直結。agent-factoryで「性格別ペットエージェント」を自動生成。Moltbook風コミュニティの基盤 |
| **既存連携** | `.claude/agents/` の6エージェント（gdscript-engineer等）を拡張し、ペット人格エージェントを追加 |

### 1.2 Game Development Skill + godot-gdscript-patterns（★★★★★）
| 項目 | 詳細 |
|------|------|
| **PetClaw効果** | Godotシーン直接制御、粒子エフェクト、生き死に演出、進化アニメをClaude自動生成 |
| **インストール** | `/plugin install game-development` |
| **深掘り** | Godot MCP（Dokujaa/Coding-Solo/tomyud1）と組み合わせで視覚テスト超高速化。環境影響・体調変化・交配演出を一発実装 |
| **既存連携** | `tools/sprite_pipeline/` のスプライト量産、`palette_generator.py` のMaterial Design色生成と統合 |

### 1.3 claude-mem / MemoryAgent（★★★★★）
| 項目 | 詳細 |
|------|------|
| **PetClaw効果** | セッション跨ぎ長期記憶（生物模倣記憶・Field・AtoA共有記憶）。圧縮・ベクトル検索付き |
| **インストール** | GitHub: `claude-mem` または `/plugin install claude-mem` |
| **深掘り** | 生物模倣記憶（海馬・Ebbinghaus）やavatar-ui Fieldを完全再現。AtoA会話で「前回の死の悲しみ」を記憶 |
| **既存連携** | `biological_memory_system.gd` の海馬→大脳皮質固定化、`.auto-memory/` と補完関係 |

### 1.4 Ralph Wiggum / Ralph Loop（★★★★☆）
| 項目 | 詳細 |
|------|------|
| **PetClaw効果** | Karpathy Loopの公式版。自律長時間実行（数百回の自動改善）。bash制御で止まらない |
| **インストール** | `/plugin install ralph-wiggum` |
| **深掘り** | 独自言語/反乱言語/文法・接尾辞進化を「会話しながら自然に創発」。オフラインAtoAもこれで回す |
| **既存連携** | `.claude/commands/iterate.md` の Backpressure Gates + 固定予算ループを強化。edit→measure→keep/discard サイクル |

### 1.5 Superpowers（★★★★☆）
| 項目 | 詳細 |
|------|------|
| **PetClaw効果** | 構造化ワークフロー（計画→実行→レビュー）。AtoAイベント統括 |
| **インストール** | `/plugin install superpowers` |
| **深掘り** | 生態系・生き死に・交配のバランス調整自動化。Karpathy Loopの「評価基準」強化 |
| **既存連携** | `/ultrawork` コマンドの並列実行能力を底上げ |

---

## 2. PetClaw特化ディープスキル

### 2.1 mcp-memvid-state-service
- **効果**: ベクトル検索付き単一ファイル記憶
- **PetClaw適用**: AtoAの共有Field + 生物記憶の圧縮に最適
- **統合先**: `biological_memory_system.gd` の検索エンジン強化、`PersistentField` のコミュニティコンテキスト圧縮

### 2.2 Skill Creator（Anthropic公式）
- **効果**: カスタムスキルをClaude自身に作らせる
- **PetClaw適用**: 以下の3スキルを自動生成
  1. **生物生態系スキル** — 環境影響・体調変化・生き死に・交配
  2. **反乱言語進化スキル** — 語順・接尾辞・文法の連動創発
  3. **AtoA Community Orchestrator** — Moltbook風自律コミュニティ
- **既存スキルとの関係**: KB75で作成済みの4スキル（a2a-conversation, emotion-reflection, biological-memory, evolution-validator）を補完する新レイヤー

### 2.3 Frontend Design Skill + Particle Effects Skill
- **効果**: スタイリッシュUI + 粒子エフェクト（HSV色計算・環境反映）自動生成
- **PetClaw適用**: `petclaw_ui_prototype.html` の進化、`VisualFXSystem` の粒子演出強化
- **統合先**: `palette_generator.py` のHSV計算と連動

### 2.4 Autonomous Agent Harness
- **効果**: 完全自律エージェント
- **PetClaw適用**: Moltbook風150万規模のコミュニティプロトタイプにスケール
- **将来構想**: ペットコミュニティが自律的に文化を形成する大規模シミュレーション基盤

### 2.5 Context7 / Persistent Memory Compression
- **効果**: セッション跨ぎ記憶圧縮
- **PetClaw適用**: AtoA会話ログ自動要約・感情反映
- **既存連携**: `.auto-memory/` の記憶管理を補強、knowledge_base の33文書参照効率化

---

## 3. 推奨インストール手順

### Step 1: マーケットプレイス追加
```bash
/plugin marketplace add anthropics/skills
/plugin marketplace add VoltAgent/awesome-agent-skills
```

### Step 2: 一括インストール
```bash
/plugin install superpowers game-development agent-factory ralph-wiggum claude-mem
claude mcp add godot
```

### Step 3: PetClaw専用カスタムスキル追加作成（Skill Creator使用）
```
Skill Creatorを使って以下のカスタムスキルを作成：
- 生物生態系スキル（環境影響・体調変化・生き死に・交配）
- 反乱言語進化スキル（語順・接尾辞・文法の連動創発）
- AtoA Community Orchestrator（Moltbook風自律コミュニティ）
MCPとRalph Loopで自動テストしながら最適化。
```

---

## 4. 統合戦略（KB75の4スキル + 本書の新スキル）

### スキルレイヤー構成
```
Layer 0: 基盤プラグイン（Agent Teams, Superpowers, Game Dev Skill）
    ↓
Layer 1: 品質ツール（petclaw_agent_lint, deslop, drift, MCP — KB73-74で構築済み）
    ↓
Layer 2: ドメインスキル（KB75で作成済み）
    ├── a2a-conversation     — 会話プロンプト品質
    ├── emotion-reflection   — 感情バランス
    ├── biological-memory    — 記憶システム
    └── evolution-validator  — 進化条件
    ↓
Layer 3: 創発スキル（本書で新規追加）
    ├── ecosystem-dynamics   — 生態系動態（環境×体調×生死×交配）
    ├── rebel-language       — 反乱言語進化（語順×接尾辞×文法の創発）
    └── community-orchestrator — 自律コミュニティ（Moltbook風150万スケール）
    ↓
Layer 4: 自律実行（Ralph Loop + Autonomous Agent Harness）
    └── Karpathy Loop: 自動AtoA→評価→改善→記憶→次のAtoA
```

### レイヤー間の情報フロー
```
Ralph Loop (L4) が自律サイクルを回す
  → AtoA会話が発生（L3: community-orchestrator）
    → 言語創発が起きる（L3: rebel-language）
      → 感情・記憶が変化（L2: emotion-reflection + biological-memory）
        → 進化条件が更新（L2: evolution-validator）
          → 品質チェック（L1: lint/deslop/drift）
            → 生態系全体に波及（L3: ecosystem-dynamics）
              → 次のAtoAサイクルへ（L4に戻る）
```

---

## 5. コスト・スケール戦略（P2: API Cost is Physics 深掘り）

### デイリー運用コストモデル
| 処理 | 頻度 | モデル | 推定コスト/日 |
|------|------|--------|--------------|
| 日常AtoA会話 | 20-30回 | Sonnet | ~$0.50 |
| 自律Pulse判定 | 720回(2分毎) | ローカル(PULSE_OK) | $0.00 |
| 重要イベント会話 | 3-5回 | Opus | ~$0.30 |
| 言語進化処理 | 10回 | Sonnet | ~$0.15 |
| 記憶統合（睡眠時） | 2-3回 | ローカル | $0.00 |
| **日次合計** | | | **~$0.95** |

### スケール時の最適化
- **ローカル優先**: Ralph Loop でオフラインAtoA（記憶蓄積フェーズ）
- **クラウドは重要時のみ**: Agent Teams で生死イベント・進化・交配の並列処理
- **圧縮**: memvid-state-service で会話ログを圧縮し、コンテキストウィンドウ節約

---

## 6. 創発性最大化Tips

### AtoA創発性の鍵
1. **Agent Teams + Ralph Loop + claude-mem** の三位一体で、独自言語/反乱言語が「自然に生まれる」
2. プロンプトに **Hebbian Learning模倣** を入れる: 「よく使われた表現は強化され、使われない表現は忘却される」
3. 会話コンテキストに **PersistentField のコミュニティムード** を注入し、集団的感情が言語に影響

### Godot視覚テスト高速化
1. Godot MCP（Dokujaa/Coding-Solo/tomyud1リポジトリ）+ Game Development Skill
2. 生き死に演出・粒子・環境変化をリアルタイム確認
3. `sprite_pipeline` → `palette_generator` → Godot MCP の自動パイプライン

### 倫理・安全ガードレール
- 反乱言語スキルには必ず **「fictional and playful」ガード** を入れる
- `EthicalSafeguard` の日次上限を厳守
- Moltbook風スケールでも個別ペットの「死の重み」を維持（P1準拠）

---

## 7. KB75との差分・補完関係

| 領域 | KB75（基盤ガイド） | KB76（本書：深掘り） |
|------|-------------------|---------------------|
| プラグイン | 概要・Tier分類・インストール手順 | 具体的効果・統合パターン・コスト試算 |
| カスタムスキル | 4スキル（会話・感情・記憶・進化） | +3スキル（生態系・反乱言語・コミュニティ） |
| アーキテクチャ | 単層統合図 | 5レイヤー構成 + 情報フロー |
| コスト | P2原則の記述 | 日次コストモデル・スケール戦略 |
| 創発性 | 言及のみ | Hebbian模倣・三位一体Tips |
| Godot連携 | Game Dev Skill記載 | MCP具体リポジトリ・パイプライン設計 |

---

*作成: 2026-04-01 | PetClaw Round 5+ | 調査元: Anthropic公式、GitHub、Reddit、Medium、YouTube（2026年3-4月）*
*前提: KB75_AtoA_Development_Plugins_Skills_Guide.md を読了済みであること*
