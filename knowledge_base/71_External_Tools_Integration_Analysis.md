# PetClaw 外部ツール統合分析
**分析日: 2026-04-01**

## 1. 分析対象リポジトリ

### GameDev-Resources (github.com/Kavex/GameDev-Resources)
- ゲーム開発リソースのキュレーション集
- カテゴリ: Assets(2D/3D/Audio), Code(Engine/API), Design, Tools, Tutorials
- 凡例: 💲有料 / 🚩限定無料 / 🆓完全無料 / 🅾️オープンソース

### CLI-Anything (github.com/HKUDS/CLI-Anything)
- あらゆるソフトウェアにCLIハーネスを自動生成 → AIエージェントが操作可能に
- 7フェーズ方法論: Analyze → Design → Implement → Plan Tests → Write Tests → Document → Publish
- Claude Code / OpenCode / Codex 等のAIコーディングエージェントと統合
- Click(≥8.0) + Python(≥3.10) + Jinja2テンプレートベース

---

## 2. PetClaw直接活用マッピング

### 2.1 ピクセルアート素材・ツール（最優先）

| リソース | 種別 | PetClaw用途 | 優先度 |
|----------|------|------------|--------|
| Aseprite | ツール🅾️ | 進化フォームスプライトシート制作、表情パターン量産 | ★★★★★ |
| 420 Pixel Art Icons for RPGs | 素材🆓 | ケアアクション・アイテムアイコン | ★★★★ |
| Kenney Assets | 素材🚩 | UI部品、ボタン、バー、環境タイル | ★★★★ |
| OpenGameArt | 素材🆓 | パーティクルFX素材、環境タイルセット | ★★★★ |
| Time Fantasy | 素材🚩 | SNES風環境背景（forest/sea/ruins/city） | ★★★ |

### 2.2 サウンド素材

| リソース | 種別 | PetClaw用途 |
|----------|------|------------|
| FreeSFX | 効果音🆓 | 進化エフェクト音、ケアアクション音、AtoA会話ポップ音 |
| Freesound | 効果音🆓 | 環境アンビエント（森、海、遺跡、街） |
| FreePD | BGM🆓 | 環境ごとのBGMベース |
| Musopen | BGM🆓 | クラシカルなアレンジ素材 |
| Octave | UI音🆓 | UIインタラクション音 |

### 2.3 CLI-Anything統合ポイント

**A. Aseprite CLIハーネス（スプライト量産パイプライン）**
```
CLI-Anything → Aseprite CLI生成 → Claude Codeから:
- スプライトシートの自動スライス
- 表情パターンのバッチ生成（12目×10口 = 120組み合わせ）
- 進化フォームの色調変換（ダークルートは暗色自動変換）
- アニメーションフレームのエクスポート（.png → Godot SpriteFrames）
```

**B. Godot Editor CLIハーネス（開発ワークフロー）**
```
CLI-Anything → Godot CLI生成 → Claude Codeから:
- .tscnシーンファイルの操作
- リソースインポート/エクスポート
- GDScript静的解析
- ヘッドレステスト実行（--headless --script）
```

**C. PetClaw デバッグCLI（テスト用）**
```
petclaw evolution check --pet-id 1     # 進化条件デバッグ
petclaw field status                    # PersistentField状態
petclaw a2a simulate --pet1 1 --pet2 2  # AtoA会話ドライラン
petclaw ethics report                   # 倫理セーフガード状態
petclaw expression show --pet-id 1      # 現在の表情状態
```

---

## 3. 統合実装ロードマップ

### Phase 1: アセットパイプライン構築（即座に着手可能）
1. Aseprite + CLI-Anythingでスプライト量産パイプライン構築
2. Kenney/OpenGameArtからUI素材選定・インポート
3. 進化フォーム20+体のベーススプライト制作開始

### Phase 2: サウンドデザイン基盤
1. FreeSFX/Freesoundから効果音セット選定
2. 環境別アンビエントサウンドの設計
3. GodotのAudioStreamPlayer統合

### Phase 3: 開発効率化
1. Godot CLIハーネスで自動テスト環境構築
2. PetClawデバッグCLI実装
3. CI/CDパイプラインへの組み込み

---

## 4. ExpressionSystem × Aseprite スプライト設計

### スプライトシート構成（1体あたり）
```
expression_sheet_[form_id].png
├── Row 0: EyeShape × 12種（各16×16px）
├── Row 1: MouthShape × 10種（各16×8px）
├── Row 2: ExpressionEffect × 12種（各16×16px）
└── Row 3: 組み合わせプリセット × 8種（よく使う表情の完成版 32×32px）
```

### Asepriteバッチ処理コマンド例
```bash
# スプライトシートからフレーム抽出
aseprite -b expression_sheet.aseprite --split-layers --save-as {layer}_{frame}.png

# ダークルート色調変換
aseprite -b base_form.aseprite --color-mode rgb \
  --script "app.command.HueSaturation({hue=-30, saturation=-20, lightness=-25})" \
  --save-as dark_form.png

# 全フォームの一括エクスポート
for form in forest_infant sea_infant ruins_infant city_infant; do
  aseprite -b ${form}.aseprite --sheet ${form}_sheet.png --data ${form}.json
done
```

---

## 5. 競合優位性への貢献

| PetClaw強み | GameDev-Resources貢献 | CLI-Anything貢献 |
|------------|---------------------|-----------------|
| ピクセルアート表情 | Aseprite + 素材ライブラリ | スプライト量産自動化 |
| 環境多様性 | タイルセット + アンビエント音 | — |
| 開発速度 | — | Godot CLIハーネス |
| テスト品質 | — | デバッグCLI + 自動テスト |
| プロダクション品質 | Kenney UI素材 | アセット変換パイプライン |
