# KB95: gstack — ソフトウェアファクトリー PetClaw活用ガイド

## リポジトリ概要

**gstack** — https://github.com/garrytan/gstack
- 作者: Garry Tan（Y Combinator CEO）
- 哲学: Claude Codeを「仮想エンジニアリングチーム」に変える
- 実績: 60日で60万行+、35%テスト、362コミット（パートタイム）
- 構成: 31専門スキル + ヘッドレスブラウザCLI + テスト評価フレームワーク
- 核心思想: **"Boil the Lake"** — AIの限界費用≒0なら、常に完全なことをやれ（100%テストカバレッジ、全エッジケース、全エラーパス）

---

## gstack vs ECC 比較

| 観点 | gstack | ECC (KB94) |
|------|--------|------------|
| 哲学 | 1人で10,000-20,000行/日出す実戦工場 | プラグインエコシステム（147スキル） |
| スキル数 | 31（深い） | 147（広い） |
| エージェント | なし（スキルルーティング） | 36専門エージェント |
| テスト | 4段階Tier（Gate/Periodic/LLM-Judge/E2E） | 997テスト |
| 学習 | Learnings JSONL自動蓄積 | continuous-learning-v2 |
| ブラウザ | 自前ヘッドレス（Playwright） | なし |
| 対象 | プロダクション開発者 | Claude Code全ユーザー |

**PetClaw最適戦略**: 両方の良いとこ取り。ECCのエージェント構成 + gstackの実戦パターン。

---

## PetClawに採用すべきgstackパターン

### 1. "Boil the Lake" 原則（最重要）

gstackの核心哲学。PetClawの第一原理と直接対応：

| gstack原則 | PetClaw対応 |
|-----------|------------|
| 100%テストカバレッジ | 進化22形態すべての到達可能性テスト |
| 全エッジケース | 死亡→復活→再交配のフルパス検証 |
| 全エラーパス | API障害時テンプレートフォールバック |
| 限界費用≒0 | P2: API Cost is Physics（でもテスト自体はローカルで無料） |

**実践**: コードを書いたら必ずテストも書く。AIにとってテスト作成のコストは低い。

### 2. SKILL.mdテンプレートパイプライン

gstackの最も洗練されたパターン：

```
SKILL.md.tmpl（テンプレート — 人間が編集）
    ↓
{{PLACEHOLDER}} 解決（scripts/resolvers/）
    ↓
SKILL.md（生成物 — 直接編集しない）
```

**PetClaw応用:**

```
.claude/skills/a2a-conversation/SKILL.md.tmpl
    ↓
{{EVOLUTION_STATE}} → 現在の進化ツリー状態を注入
{{COST_BUDGET}} → 残り日次予算を注入
{{ACTIVE_PETS}} → アクティブペット一覧を注入
    ↓
.claude/skills/a2a-conversation/SKILL.md（自動生成）
```

利点: スキルが常に最新のゲーム状態を反映する。手動更新不要。

### 3. プリアンブル・ティアシステム

gstackはスキル実行前に「プリアンブル」を注入する：

```
Tier 1: 初回のみ（セットアップ）
Tier 2: ブランチ変更時
Tier 3: 重要スキル実行時
Tier 4: 毎回必ず（セッション追跡、テレメトリ）
```

**PetClaw応用:**

```
Tier 1（初回のみ）:
  - CLAUDE.md読み込み
  - Agent Teams構成確認
  - Knowledge Base索引構築

Tier 2（ブランチ変更時）:
  - 変更ファイルに関連するサブシステム検出
  - 影響範囲の自動判定

Tier 3（重要操作時）:
  - 進化ツリー整合性チェック
  - セーブ/ロード互換性確認
  - API予算残高確認

Tier 4（毎回）:
  - セッションID追跡
  - アクティブペット状態ログ
  - 前回セッションのLearnings注入
```

### 4. Learnings自動蓄積（運用的自己改善）

gstackの最も実用的な仕組み：

```
~/.gstack/projects/{SLUG}/learnings.jsonl
```

各セッション後にClaudeが失敗を振り返り、次回のプリアンブルに自動注入。

**PetClaw実装:**

```
~/.petclaw/learnings.jsonl

# 例:
{"ts":"2026-04-01","skill":"a2a-conversation","learning":"テンプレート会話でemotion_intensityが0.2以下だと投稿品質が低下する。閾値を0.3に引き上げるべき","severity":"medium"}
{"ts":"2026-04-01","skill":"evolution","learning":"TEEN→ADULT遷移でcare_qualityが0.4未満だとダークルートに入るが、0.35-0.4のグレーゾーンでは挙動が不安定","severity":"high"}
{"ts":"2026-04-02","skill":"breeding","learning":"twin_probabilityの5%ベースは低すぎる。プレイヤーは双子イベントを期待している。8%に引き上げ検討","severity":"low"}
```

次回セッションで自動サーフェス:
```
## 前回のLearnings（自動注入）
⚠️ TEEN→ADULT遷移のグレーゾーン（care_quality 0.35-0.4）に注意
ℹ️ テンプレート会話のemotion_intensity閾値は0.3以上を推奨
```

### 5. 4段階テスト戦略

gstackのTier制をPetClawに：

```
Tier 1 — Gate（無料、<1秒、CI必須）:
  - GDScript構文チェック（class_name, 型注釈）
  - to_dict/from_dict整合性
  - 進化ツリー到達可能性（静的解析）
  - カラーパレット重複チェック

Tier 2 — Gate（無料、<30秒、CI必須）:
  - セーブ/ロードラウンドトリップテスト
  - FSM状態遷移テスト（全8状態）
  - 交配遺伝子計算テスト
  - 悲嘆カスケード強度テスト

Tier 3 — Periodic（有料、~$0.15/回、LLM判定）:
  - AtoA会話品質スコアリング（Opus判定）
  - 感情リフレクション自然さ評価
  - 言語進化パターンの創発性評価
  - PetBook投稿の魅力度評価

Tier 4 — Periodic（有料、~$4/回、E2E）:
  - フルライフサイクルE2E（EGG→DEAD→ETERNAL）
  - 交配3世代シミュレーション
  - AtoA会話50ターン耐久テスト
  - コスト予算消費シミュレーション
```

**Diff-based selection（gstack方式）:**
- `ui/` 変更 → UIテストのみ
- `life/` 変更 → 生死+交配テストのみ
- `conversation/` 変更 → AtoAテスト + コストテスト
- `CLAUDE.md` 変更 → 全テスト

### 6. スキルルーティング（プロアクティブ起動）

gstackのプリアンブルがユーザー意図を検出して適切なスキルを起動：

```
ユーザー: "PetBookのUIを改善したい"
  → 検出: UI関連 → /implement → ui-artist エージェント起動

ユーザー: "AtoA会話が不自然"
  → 検出: 会話品質 → /debug → a2a-designer エージェント起動

ユーザー: "進化ツリーにバグ"
  → 検出: 進化関連 → /debug → evolution-specialist 起動

ユーザー: "リリースしたい"
  → 検出: 出荷 → /ship → 品質ゲート + コミット自動化
```

### 7. セッション追跡

gstackは各セッションを一意に追跡：

```bash
_SESSION_ID="$$-$(date +%s)"
# → "12345-1711929600"
```

**PetClaw応用:**
```gdscript
# ゲーム内セッション追跡（デバッグ用）
var session_id: String = str(OS.get_process_id()) + "-" + str(Time.get_unix_time_from_system())
```

開発セッションとゲーム内セッションの両方を追跡し、「この会話品質低下は何番目のセッションで発生したか」を特定できる。

### 8. 安全スキル（careful / freeze / guard）

gstackの安全3層：

| スキル | 機能 | PetClaw相当 |
|--------|------|------------|
| careful | 破壊的コマンド前に警告 | セーブデータ上書き前確認 |
| freeze | ディレクトリ編集ロック | コアシステム変更防止 |
| guard | careful + freeze同時 | リリース前の全面ロック |

**PetClaw実装例:**
```
# .claude/skills/petclaw-guard/SKILL.md
以下のファイルは変更禁止（freeze）:
- godot_project/scripts/core/game_manager.gd
- godot_project/scripts/ethics/ethical_safeguard.gd

以下の操作は確認必須（careful）:
- セーブデータ形式の変更
- 進化ツリー形態の追加・削除
- API予算定数の変更
```

---

## gstack 31スキル → PetClaw対応表

| gstack スキル | 機能 | PetClaw活用 |
|-------------|------|------------|
| office-hours | 対話的設計相談 | 企画・設計フェーズ |
| plan-ceo-review | CEO視点レビュー | プレイヤー体験視点レビュー |
| plan-eng-review | エンジニア視点レビュー | GDScript品質レビュー |
| plan-design-review | デザインレビュー | UI/UXレビュー |
| review | PR前レビュー | /review コマンド |
| ship | マージ+テスト+バージョン | /ship コマンド |
| investigate | 根本原因調査 | /debug コマンド |
| qa | ブラウザでバグ探し | Godotエディタでのテスト |
| canary | デプロイ後監視 | ビルド後動作確認 |
| cso | セキュリティ監査 | APIキー・倫理チェック |
| careful | 破壊操作警告 | コアファイル保護 |
| freeze | 編集ロック | リリース前ロック |
| guard | careful + freeze | 全面保護 |
| retro | 週次振り返り | 開発振り返り |
| document-release | リリース後ドキュメント | KB自動更新 |
| design-consultation | デザインシステム構築 | PetBookデザインシステム |
| design-review | デザイン監査 | UI一貫性チェック |
| codex | セカンドオピニオン（OpenAI） | 代替LLM品質比較 |
| land-and-deploy | マージ→デプロイ→監視 | ビルド→テスト→確認 |

---

## すぐに試せるアクション

### A. Learningsシステム導入
```text
gstackのlearnings.jsonlパターンを参考に、PetClaw用のセッション学習システムを作成してください。
.claude/skills/ 以下に petclaw-learnings スキルを追加し、
セッション終了時に失敗・成功パターンを自動記録→次回プリアンブルに注入する仕組みを。
```

### B. テストTier制導入
```text
gstackの4段階テスト戦略をPetClawに適用してください。
Tier 1（静的検証）: class_name, 型注釈, to_dict整合性
Tier 2（ユニットテスト）: FSM遷移, 遺伝子計算, 悲嘆カスケード
Tier 3（LLM判定）: AtoA会話品質, 感情自然さ
Tier 4（E2E）: フルライフサイクル
```

### C. SKILLテンプレートパイプライン
```text
gstackのSKILL.md.tmpl→SKILL.md生成パイプラインを参考に、
PetClawの8カスタムスキルにテンプレート化を導入してください。
{{EVOLUTION_STATE}}, {{COST_BUDGET}}, {{ACTIVE_PETS}} のプレースホルダーを設計して。
```

### D. 安全スキル3層
```text
gstackのcareful/freeze/guardパターンをPetClawに導入してください。
game_manager.gdとethical_safeguard.gdをfreeze対象に、
セーブデータ形式変更と進化ツリー変更をcareful対象に設定。
```

---

## gstack必読ファイル

| ファイル | 内容 | PetClaw関連度 |
|---------|------|-------------|
| ETHOS.md | "Boil the Lake"哲学、Search Before Building | ★★★ |
| ARCHITECTURE.md | デーモンモデル、Refシステム、セキュリティ | ★★ |
| CONTRIBUTING.md | 運用的自己改善、Learningsシステム | ★★★ |
| CLAUDE.md | プロジェクトレベル設定の実例 | ★★★ |
| scripts/gen-skill-docs.ts | テンプレート→生成パイプライン | ★★★ |
| test/skill-validation.test.ts | Tier 1テストの実装例 | ★★ |

---

> gstack は「1人で巨大なものを出荷する」ための実戦システム。
> PetClawにとっての最大の学びは:
> **"Boil the Lake" + Learnings自動蓄積 + 4段階テスト**。
> この3つを導入すれば、非エンジニアでも品質を維持しながら開発を加速できる。
