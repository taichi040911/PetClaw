# PetClaw セッション開始テンプレート

## 使い方
## このテンプレートの【】部分を今日の作業に合わせて書き換えてから、
## Claude Code の最初のプロンプトとして貼り付ける。

---

## コピー用テンプレート（ここから下をコピー）

HANDOFF_PetClaw.md を読んで現状を把握してください。

### 今日の作業スコープ
【Phase X の具体的な作業内容を1〜2文で】

例:
- Phase 1: ペットの基本表示と EmotionSystem の実装
- Phase 2: PetBook の UI レイアウトと投稿表示
- Phase 3: SubMolt テーマ切り替えの実装
- Phase 4: AtoA 会話のテンプレート版実装

### 参照する KB
【関連する KB 番号を列挙】

例:
- KB67, KB70（AtoA 会話関連）
- KB88（開発フロー全般）

### 今日触るファイル
【変更対象のファイルを列挙。新規作成の場合はファイル名案も】

例:
- 変更: pet_emotion_system.gd
- 新規: a2a_template_manager.gd

### 今日触らないファイル（明示）
【変更しないことを明示したいファイル】

例:
- GameManager.gd のセーブ/ロード部分
- project.godot の autoload 設定

### 完了条件
【何ができたら今日の作業完了か】

例:
- EmotionSystem が5種類の感情を持ち、to_dict/from_dict で保存復元できる
- PetBook に3件のテスト投稿が表示される

---

## フェーズ別クイックリファレンス

### Phase 1: ペット基本表示・感情（1〜2日）
- スコープ: PetDisplay, EmotionSystem, 基本スプライト
- KB: KB88
- ゴール: ペットが画面に表示され、感情が変化する

### Phase 2: PetBook UI（1日）
- スコープ: PetBookUI, PostDisplay, タイムライン
- KB: KB88
- ゴール: PetBook 画面が開き、投稿が表示される

### Phase 3: SubMolt テーマ（半日）
- スコープ: SubMolt テーマデータ、テーマ切り替え UI
- KB: KB88
- ゴール: 3つ以上のテーマが切り替えられる

### Phase 4: AtoA 会話テンプレート版（1〜2日）
- スコープ: A2ATemplateManager, 会話生成, フォールバック
- KB: KB67, KB70
- ゴール: ペット同士がテンプレートで会話し、API なしでも動く

### Phase 5: 独自言語進化（2〜3日）
- スコープ: LangSystem, 音素生成, 言語変異
- KB: KB88
- ゴール: ペットの言葉が世代を経て変化する

### Phase 6: 生死・交配（2〜3日）
- スコープ: LifeSystem, BreedSystem, 遺伝
- KB: KB88
- ゴール: ペットが寿命で死に、交配で子が生まれる

### Phase 7: Claude API 統合（1〜2日）
- スコープ: API クライアント, 予算管理, テンプレートフォールバック
- KB: KB67, KB70
- ゴール: API で会話生成、予算超過時にフォールバックする

### Phase 8: VFX・演出（1日）
- スコープ: パーティクル, アニメーション, 進化演出
- KB: KB88
- ゴール: 進化・誕生・死にビジュアルエフェクトがつく

### Phase 9: 統合テスト（1日）
- スコープ: 全サブシステムの結合、セーブ/ロード往復
- KB: KB95
- ゴール: 新規開始→育成→進化→PetBook投稿→セーブ→ロードが通る
