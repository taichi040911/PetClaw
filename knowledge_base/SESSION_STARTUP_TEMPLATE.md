# PetClaw セッション開始テンプレート集

Claude Code の各セッションで最初に貼り付けて使うテンプレートです。
作業内容に合わせて選び、[ ] 内を自分の状況に書き換えてください。

---

## テンプレート1: 特定フェーズの実装作業

```text
PetClawプロジェクトの開発を続けます。

【今日の作業スコープ】
- Phase: [Phase番号と内容。例: Phase 4 — AtoA会話テンプレート版実装]
- 参照KB: [関連KB番号。例: KB67, KB70]
- 対象ファイル: [触るファイル。例: godot_project/scripts/a2a_conversation_system.gd]

【制約の確認】
- 既存の33ファイルの構造・クラス名・シグナル名は変更しない
- 新コードは既存のGameManager.instanceパターンに従う
- to_dict()/from_dict() を実装してセーブ/ロード対応する

まずHANDOFF_PetClaw.mdと指定KBを読んで、作業計画を提案してください。
実装に入る前に計画を確認させてください。
```

---

## テンプレート2: Ralph Loop による自動改善

```text
PetClawプロジェクトの自動改善を行います。

【改善対象】
- システム: [例: PetBookのAfterlifeEchoes SubMolt投稿生成]
- 改善目標: [例: 生き死にの感動をより強く表現する視覚効果]
- 参照KB: [例: KB83, KB86, KB87]

【制約】
- 最大ループ回数: [例: 12]
- API日次予算を超えない（会話$0.50/日、投稿$1.21/日）
- 既存ファイル構造は維持

/ralph-loop "[上記の改善目標をここに]" --max-iterations [回数] --completion-promise "COMPLETED"
```

---

## テンプレート3: バグ修正・デバッグ

```text
PetClawプロジェクトでバグを修正します。

【症状】
- [何が起きているか。例: ペットが死亡した後、AtoA会話で死亡ペットが話者として登場する]
- [エラーログがあれば貼る]

【期待する動作】
- [正しくはどうなるべきか。例: 死亡ペットはAtoA会話の話者から除外され、追悼投稿のみ生成される]

【関連ファイル（わかれば）】
- [例: life_death_system.gd, a2a_conversation_system.gd]

まず原因を特定して、修正案を提案してください。修正する前に確認させてください。
```

---

## テンプレート4: 新システム追加

```text
PetClawに新しいシステムを追加します。

【追加するシステム】
- 名前: [例: WeatherSystem]
- 概要: [例: ゲーム内の天候が変化し、ペットの体調・感情・AtoA会話に影響を与える]
- 参照KB: [関連があれば]

【実装ルール（CLAUDE.md準拠）】
- class_name を宣言する
- GameManager.instance 経由で他システムを参照
- 型注釈を必ず使用
- to_dict() / from_dict() でセーブ/ロード対応
- シグナルベースで他システムと連携
- GameManager の save_data に to_dict() で埋め込む

【確認ポイント】
- 既存システムとの連携箇所を洗い出してから実装に入る
- 新シグナルを追加する場合、接続先を明示する
- テスト（to_dict往復テスト + 関連システムとの結合テスト）も作成する

まず設計案を提示してください。
```

---

## テンプレート5: コードレビュー・品質チェック

```text
PetClawプロジェクトの品質チェックを行います。

【チェック対象】
- [例: 直近の変更すべて / 特定ファイル / 特定サブシステム]

【実行してほしいチェック】
1. コーディング規約準拠（class_name, 型注釈, to_dict/from_dict）
2. セーブ/ロード整合性（既存セーブデータとの互換性）
3. APIコスト影響（新しいAPI呼び出しが増えていないか）
4. 進化ツリー22形態の到達可能性（変更が影響する場合）
5. 品質ツール実行:
   - python tools/quality/petclaw_agent_lint.py
   - python tools/quality/petclaw_drift.py
   - python tools/quality/petclaw_deslop.py

問題があれば修正案を提案してください。修正する前に確認させてください。
```

---

## テンプレート6: PetBook UI / ビジュアル作業

```text
PetClawのPetBook UIを改善します。

【作業内容】
- [例: ForestWhispers SubMoltのカード表示にGPUParticles2Dエフェクトを追加]
- 参照KB: [例: KB78, KB79, KB81, KB87]

【ビジュアル制約】
- 統一カラーパレット（pet_book_palette.gd の56定数）に準拠
- SubMoltごとのテーマカラーを守る
  - ForestWhispers: #2D5A3D（深緑）
  - AfterlifeEchoes: #6B4C8A（紫）
  - BreedingCircle: #C77D8A（ピンク）
  - LanguageRebellion: #4A9B8E（シアン）
  - EcosystemPulse: #4682B4（ウォーターブルー）
- HSV色計算で感情・環境を視覚表現

まず現在のUI状態を確認して、改善案を提示してください。
```

---

## テンプレート7: 全体状況確認（短いセッション向け）

```text
PetClawプロジェクトの現状を確認します。

HANDOFF_PetClaw.mdとCLAUDE.mdを読んで、以下を簡潔に報告してください:
1. 現在の実装完了状況（サブシステムごと）
2. 次に着手すべき優先タスク（上位3つ）
3. 既知の問題・リスク

長い説明は不要です。箇条書きで簡潔に。
```

---

## 使い方のコツ

- テンプレートはそのままコピーして、[ ] 内を書き換えるだけでOK
- 「修正する前に確認させてください」を入れると、Claude Codeが勝手に大量変更するのを防げる
- 参照KBを絞るほど、Claude Codeの精度が上がる（全部読ませると遅くなる）
- Ralph Loopの回数は10〜20が目安。最初は少なめで試す
