# 進化ビジュアルリファレンス分析

2026年4月 — たまごっち/デジモン/ポケモン/Lo-Fiモンスターの進化チャート・表情システム分析。PetClawの進化ツリーと表情設計のリファレンス。

---

## 1. たまごっち進化システム分析

### たまごっち 4U チートシート分析
- **段階数**: Baby → Child → Teen → Adult（4段階）
- **分岐条件**: Care Misses数、Happiness、スキルレベル、特定アイテム使用
- **特徴**: 同じ条件でも性別で異なるルート（Female Line / Male Line）
- **キーインサイト**: Care Misses 0-1で最良進化、4-5で中間、6+で最低ランク

### たまごっち Pix グロースチャート
- **段階**: Baby → Child → Teen → Adult
- **分岐要因**: Happiness（20+, 10-19, 0-9）、Friendship Level、Care Misses
- **Smart/Charming/Creative**: 性格タイプで初期分岐
- **PetClaw適用**: personalityの`curious/brave/affectionate`で初期分岐

### たまごっち Version 4 キャリカチャーチャート
- **特徴**: 男女別のBaby→Toddler→Teen→Adult→Special Adult
- **Oldies枠**: 長寿ペットの特別形態
- **PetClaw適用**: Stage 5に「長寿特別形態」を追加可能

---

## 2. デジモン進化システム分析

### アグモン進化ライン
- **段階**: Digitama → Baby I (Botamon) → Baby II (Koromon) → Child (Agumon) → Adult (Greymon) → Perfect (MetalGreymon) → Ultimate (WarGreymon)
- **分岐**: Greymon → SkullGreymon（ダーク進化）vs MetalGreymon（正統進化）
- **条件**: 育て方・バトル結果・パートナーとの絆
- **PetClaw適用**: 世話の質で「光」と「闇」の分岐ルートを持つ

### パタモン進化ライン
- Tokomon → Patamon → Angemon → HolyAngemon → Seraphimon
- **天使系**: 一貫した進化テーマ（聖なる存在への昇華）

### テイルモン進化ライン
- Nyaromon → Plotmon → Tailmon → Angewomon → Holydramon
- **聖獣系**: 小さな猫→大天使→聖竜という劇的変化

### ビヨモン進化ライン
- Pyocomon → Piyomon → Birdramon → Garudamon → Hououmon
- **鳥→炎鳳凰**: サイズと威厳が段階的に増加

**デジモン共通パターン**:
1. 初期形態は小さく丸い
2. 中間形態で種族特徴が明確化
3. 最終形態は人型または巨大化
4. ダーク分岐は色が暗く、フォルムが攻撃的

---

## 3. ポケモンビジュアル分析

### ピカチュウ36表情シート
- **表情パターン**: 通常/喜び/怒り/悲しみ/驚き/眠り/食事/ハート/怒りマーク/汗/...
- **特徴**: 目と口の組み合わせだけで36種類の表情を表現
- **感情記号**: ♥ ♪ ! ? 💢 💦 など、記号で補助
- **PetClaw適用**: 基本目パターン×口パターンの組み合わせで表情を動的生成

### ピカチュウドット絵進化（世代別）
- 赤緑→金銀→ルビサファ→DPt で微妙にデザインが洗練
- 初期は太め → 後期はスリム化
- **PetClaw適用**: 同一ペットでも世代（プレイ時間）で微妙にデザイン変化

### PokéMinis 全151匹ドット絵
- 極小ピクセルでも識別可能なデザイン
- **シルエットの明確さ**が最重要
- **PetClaw適用**: 小さいスプライトでもシルエットで識別できる設計

### ポケモンタイプ相性チャート（Fraquezas e Resistências）
- 18タイプの相性マトリクス
- **PetClaw適用**: 環境×性格の相性システムの参考

---

## 4. Lo-Fi Monsters グロースチャート分析

- **スタイル**: Gameboy風2色ピクセルアート
- **段階**: 4×4グリッドで段階的成長
- **特徴**: 丸い幼体 → パーツ追加 → 角張った成体
- **色**: 2色（黄/ターコイズ）のみでキャラクター性を表現
- **PetClaw適用**: 最小色数でのキャラクター表現。モバイルでの視認性重視

---

## 5. Digimon World UI分析（Sir. Potato画面）

### ステータス画面構成:
- **左パネル**: ペット画像 + 名前 + DIGI名 + AGE + WEIGHT + TYPE + ACTIVE + SPECIAL
- **右パネル上**: TECHSET（技セット）+ POWER/MP/RANG/SPEC
- **右パネル下**: STATUS（HP/MP/OFF/SPD/DEF/INT）
- **左下**: HAPPINESS ゲージ / DISCIPLINE ゲージ / VIRUS アイコン

**PetClaw適用**:
- ステータス画面のレイアウトリファレンス
- HAPPINESS/DISCIPLINE の2ゲージシステム → PetClawのMood/Affectionに相当
- 技セット → 進化段階で解放される能力

---

## 6. PetClaw 5段階進化設計への適用

### リファレンスからの統合設計

| PetClaw Stage | たまごっち相当 | デジモン相当 | ビジュアル特徴 |
|---|---|---|---|
| Stage 1 (Egg/Blob) | Baby | Baby I-II | 丸い塊、目だけ、色淡い |
| Stage 2 (Infant) | Child | Child | 小さな体、特徴出始め、耳/尻尾出現 |
| Stage 3 (Youth) | Teen | Adult | IPの顔、性格が視覚化、体つき明確 |
| Stage 4 (Adult) | Adult | Perfect | 完成形、アクセサリー、威厳 |
| Stage 5 (Elder/Legend) | Special | Ultimate | 特別エフェクト、光/オーラ、到達感 |

### 分岐条件設計

| 条件カテゴリ | 具体例 | 影響 |
|---|---|---|
| **Care Quality** | Care Misses 0-1 → 最良ルート | たまごっち直系 |
| **Personality** | brave > 0.7 → 戦士系 | デジモン的分岐 |
| **Environment** | forest長期 → 自然系進化 | PetClawオリジナル |
| **Relationship** | 親密度 > 0.8 → 絆進化 | デジモン的パートナー進化 |
| **AtoA History** | 会話回数多い → 社交系 | PetClawオリジナル |
| **Dark Route** | Care Misses 6+ / 孤立 → ダーク進化 | デジモンSkullGreymon的 |
