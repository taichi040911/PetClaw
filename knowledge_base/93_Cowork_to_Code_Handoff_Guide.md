# KB93: Claude CoworkからClaude Codeへの引き継ぎ方（非エンジニア向け実践ガイド）

## 概要

Claude Desktopアプリ内でCowork（企画・ドキュメント・ファイル管理向き）とCode（本格的なGodotコード実装・ループ改善向き）の棲み分けは明確です。
Coworkでアイデアや設計を固め、Codeに移行して実際の開発・自動改善を行うのがPetClawのようなゲーム開発の効率的な流れです。

---

## 1. 基本的な引き継ぎの流れ（一番簡単な方法）

### ステップ1: Coworkで「Handoff Document」を作成させる

Coworkのチャットで以下のように指示してください（そのままコピー推奨）：

```text
私は非エンジニアです。
現在のPetClawプロジェクト（AtoAペットアプリ、PetBook UI、生物生態系、生き死に・交配システム、独自言語進化など）の状況をまとめた「Handoff Document」を作成してください。

以下の内容を明確に含めて：
- これまでの主な決定事項と設計概要
- 重要なファイル一覧（CLAUDE.md、Knowledge Baseファイル、Godotシーンなど）
- 次にCodeで実装すべき優先タスク
- Ralph LoopやMCPで使うべき指示の例
- 注意点（非エンジニアなので説明を丁寧に）

Markdownファイルとして出力し、プロジェクトフォルダに保存できるようにしてください。
```

→ ClaudeがNEXT-STEPS.mdやHandoff_PetClaw.mdのようなファイルを作成してくれます。

### ステップ2: 作成されたファイルをローカルフォルダに保存

- Coworkが生成したファイルをデスクトップのプロジェクトフォルダ（例: PetClaw_Project）に保存。
- 既存のKnowledge Base MDファイル（73_PetBook_UI_...mdなど）も同じフォルダにまとめておく。

### ステップ3: Claude Codeを起動して引き継ぐ

Claude DesktopアプリでCodeモードに切り替え、以下の手順：

1. 新しいプロジェクトフォルダを開く（または既存のPetClaw_Projectフォルダを選択）。
2. Code内で以下を入力：

```text
/init
```

または

```text
プロジェクトフォルダ内のHandoff_PetClaw.mdとすべてのKnowledge Baseファイルを読み込んで、現在の状況を理解してください。
これからGodotコードの実装とRalph Loopによる自動改善を進めます。
```

これでCoworkで蓄積した文脈がCodeに引き継がれます。

---

## 2. よりスムーズな引き継ぎの高度テクニック

### 方法A: CLAUDE.mdを活用（最もおすすめ）

Coworkで以下の指示を出してCLAUDE.mdを更新：

```text
現在のプロジェクト状況をCLAUDE.mdに詳細にまとめて更新してください。
PetClawの全体像、SubMolt設計、生き死にシステム、独自言語進化、PetBook UIなどを含めて。
```

- Code起動時にこのCLAUDE.mdが自動で読み込まれるので、文脈が途切れにくい。

### 方法B: プロジェクトフォルダを直接共有

- Coworkで作業したフォルダをそのままCodeで開く。
- Code内で「このフォルダのすべてのMDファイルとGodotファイルを読み込んで状況を把握して」と指示。

### 方法C: Handoff + Ralph Loopの組み合わせ

CoworkでHandoffを作成後、Codeで即Ralph Loopを回す：

```text
Handoff_PetClaw.mdを読み込んだ上で、PetBookの視覚デザインをRalph Loopで改善してください。
--max-iterations 10 --completion-promise "PETBOOK_VISUAL_DONE"
```

---

## 3. 注意点（非エンジニアが失敗しないために）

| ポイント | 説明 |
|---------|------|
| Coworkはファイル操作が強い | 企画・ドキュメントはCoworkで |
| Codeはコード実装が強い | GodotのGDScript、粒子、MCP連携はCodeで |
| 引き継ぎ漏れ防止 | 必ず「Handoff Document」や「CLAUDE.md更新」をCoworkで先に作る |
| MCP連携 | Codeで `claude mcp add godot` を実行すると、Godotシーンを直接見ながら修正可能 |
| Ralph Loop | Code内で回すのが基本。CoworkからCodeに移行したらRalph Loopで自動改善を活用 |

---

## 4. すぐに試せる引き継ぎ指示（Coworkで実行）

```text
現在のPetClawプロジェクトの全状況をまとめたHandoff Documentを作成してください。
特にPetBook UI、SubMoltバリエーション、生物生態系・生き死にシステム、独自言語進化について詳細に。
Codeモードで続きを開発できるように、明確なNext Stepsも記載してください。
ファイルとしてプロジェクトフォルダに保存できる形式で。
```

この指示を実行したら、生成されたファイルをCodeに引き継いでください。

---

## Next Action提案

- A. 上記のHandoff Document作成指示を今すぐ実行したい
- B. あなたの現在の進捗を教えてくれれば、それに合わせたカスタム引き継ぎ指示を作成
- C. Code側でRalph Loopを回すための具体的なコマンド例

---

> Claude Coworkで設計を固め、Codeで実装・自動改善する流れがPetClaw開発の最強パターンです。
> あなたはアイデアを出すだけでOK。一緒に進めましょう！
