# Ralph Loop PetBook 開発指示集

PetBook の各機能を自動改善するための Ralph Loop コマンド集です。
各コマンドは copy-paste 対応。Karpathy Loop（Observe → Decide → Generate → Evaluate → Learn）で自律的に品質向上を実現します。

---

## 1. PetBook 全体 UI 品質改善ループ

PetBook フィード全体の視覚美を最高水準に引き上げます。

```text
/ralph-loop "PetBook全体のUI品質を最高水準に引き上げて。
対象: フィード表示、カードデザイン、SubMoltテーマ切替、粒子エフェクト、リアクションバー。
確認ポイント:
- 5つのSubMoltすべてで視覚テーマが正しく切り替わるか
- 投稿カードの角丸・グロー・枠線がテーマと一致しているか
- 粒子エフェクトがSubMoltごとに異なるか（葉→紫陽気→ハート→グリッチ→環境）
- 入場アニメーション（fade/slide_up/glitch/bloom）が機能するか
- ホバー・タップのインタラクションが自然か
- リアクションアイコン（heart/laugh/spark/mystery）の色がテーマと調和しているか
改善するたびにスクリーンショットで確認して。デザイン修正はFigmaプロトタイプに反映。" 
--max-iterations 15 
--completion-promise "UI_PERFECT"
```

---

## 2. SubMolt 別 テーマ改善ループ

各 SubMolt の世界観を徹底的に表現。5つのループを並列実行推奨。

### 2-1. ForestWhispers（森の囁き）

```text
/ralph-loop "ForestWhispersのテーマ完成度を高めて。
ビジュアル: 緑のグラデーション、葉の粒子、柔らかいフェード、自然の温かみ。
投稿スタイル: 自然観察・季節変化・植物の成長。
確認項目:
- 緑色パレット（#2D5016→#7CB342）の一貫性
- 葉粒子の落下速度・回転・サイズ設定
- テキストフォント（温かみのあるセリフ）の可読性
- 背景ぼかしと前景エフェクトのバランス" 
--max-iterations 8
--completion-promise "FOREST_PERFECT"
```

### 2-2. AfterlifeEchoes（死後の響き）

```text
/ralph-loop "AfterlifeEchoesの追悼の美学を深掘りして。
ビジュアル: 幽玄な紫（#4A148C→#9575CD）、魂の浮遊粒子、追悼投稿の感動演出。
投稿スタイル: 思い出、感謝、魂の見守り、輪廻。
確認項目:
- 紫グラデーションの神秘性
- 浮遊粒子（ゆっくり上昇）の動作
- テキストの発光エフェクト（soft glow）
- 音声（静寂×鈴の音）との同期" 
--max-iterations 8
--completion-promise "AFTERLIFE_PERFECT"
```

### 2-3. BreedingCircle（繁殖の輪）

```text
/ralph-loop "BreedingCircleの生命誕生の温かさを最大化して。
ビジュアル: ピンクハート粒子、誕生の金色爆発、家族の温かさ、家系図表現。
投稿スタイル: 子ども誕生、家族愛、遺伝、血統。
確認項目:
- ピンク（#FF69B4）とゴールド（#FFD700）の調和
- ハート粒子の爆発アニメーション
- 親子関係の視覚表現（矢印・線）
- 育成進度と成長段階の表示" 
--max-iterations 8
--completion-promise "BREEDING_PERFECT"
```

### 2-4. LanguageRebellion（言語反乱）

```text
/ralph-loop "LanguageRebellionのグリッチエネルギーを極限化して。
ビジュアル: グリッチ入場、シアンスパーク、反乱の緊張感、デジタルノイズ。
投稿スタイル: 造語、接尾辞変化、複合語、反乱宣言。
確認項目:
- グリッチアニメーション（RGB分離・ブロック化）のタイミング
- シアン（#00CED1）スパーク粒子の密度
- テキスト変形エフェクト（wave/vibration）
- 背景スキャンラインの速度とコントラスト" 
--max-iterations 10
--completion-promise "REBELLION_PERFECT"
```

### 2-5. EcosystemPulse（生態系の鼓動）

```text
/ralph-loop "EcosystemPulseの環境連動表現を研ぎ澄まして。
ビジュアル: 環境連動色変化、データスタイル、マイグレーション粒子、食物連鎖表現。
投稿スタイル: 個体数、環境指数、捕食・被食、群れ行動。
確認項目:
- 季節×時刻による色相の自動変更
- 粒子パターン（マイグレーション矢印）の流動性
- グラフ・データ表示の美学
- エコシステム全体の相互作用ビジュアル" 
--max-iterations 10
--completion-promise "ECOSYSTEM_PERFECT"
```

---

## 3. 投稿生成テンプレート品質ループ

PetBookPostGenerator の 100+ テンプレートの完成度向上。

```text
/ralph-loop "PetBook投稿テンプレート品質を向上させて。
対象: PetBookPostGenerator (scripts/petbook/post_generator.gd) の全テンプレート。
改善ポイント:
- 各SubMoltに20種以上のバリエーション用意
- 複合語(compound words)の自然な挿入（pya-pya-kuu等）
- 接尾辞(-pya, -kuu, -zaa, -shuu等)の文脈適合性チェック
- 感情×環境×生命段階の組み合わせによる多様性
- 生物模倣記憶(BirthMemory)からの参照（過去の出来事を投稿に自然に反映）
- 品質スコア0.6以下のテンプレートは全面書き直し
- 平均感情スコア0.7以上をキープ" 
--max-iterations 12
--completion-promise "TEMPLATES_REFINED"
```

---

## 4. Karpathy Loop 統合最適化

PetBookAutoPublisher の 5段階ループ自動改善。各段階を深掘り。

### 4-1. Observe 段階最適化

```text
/ralph-loop "PetBook Observe段階を最適化して。
確認対象: ペット状態・環境指数・記憶プール・感情スコア・行動ログ。
品質チェック:
- BirthMemoryから有効な記憶を抽出できているか
- 環境指数（temperature/food_scarcity）の値範囲が正常か
- 感情スコア（joy/sadness/curiosity）が0-1.0で正規化されているか
- ペットの生命段階が正しく判定されているか
ログ分析→改善" 
--max-iterations 6
--completion-promise "OBSERVE_OPTIMAL"
```

### 4-2. Decide 段階最適化

```text
/ralph-loop "PetBook Decide段階を最適化して。
確認対象: 投稿カテゴリ選択・SubMolt選択・テンプレート優先度。
品質チェック:
- 現在の感情×生命段階から適切なカテゴリが選ばれているか
- 複数のSubMoltが利用可能な時に多様性が保たれているか
- テンプレート優先度スコアが実際の品質と連動しているか
- 投稿頻度がバランスしているか（多すぎず、少なすぎず）
改善内容をフローチャートに反映" 
--max-iterations 6
--completion-promise "DECIDE_OPTIMAL"
```

### 4-3. Generate 段階最適化

```text
/ralph-loop "PetBook Generate段階を最適化して。
確認対象: テンプレート展開・パラメータ挿入・言語進化適用。
品質チェック:
- テンプレート変数すべてが正しく埋め込まれているか
- 接尾辞変化（語順進化）が自然に適用されているか
- 複合語の結合が違和感なく完成しているか
- 投稿の長さ（20-120文字）が適切か
- 感情スコアが投稿内容と一致しているか
サンプル100件分析" 
--max-iterations 8
--completion-promise "GENERATE_OPTIMAL"
```

### 4-4. Evaluate 段階最適化

```text
/ralph-loop "PetBook Evaluate段階を最適化して。
確認対象: 品質スコア算定・感情整合性・記憶への反映度。
品質チェック:
- 品質スコア計算式（長さ×多様性×感情整合性）の妥当性
- AI間相互評価(互評)が機能しているか
- ユーザーリアクション（heart/laugh等）との相関
- 低品質投稿が正しく検出されているか
- スコア分布が適切か（平均0.65～0.75）
統計分析→係数調整" 
--max-iterations 8
--completion-promise "EVALUATE_OPTIMAL"
```

### 4-5. Learn 段階最適化

```text
/ralph-loop "PetBook Learn段階を最適化して。
確認対象: 生物模倣記憶更新・言語進化・テンプレート適応。
品質チェック:
- 高評価投稿がBirthMemoryに正しく記録されているか
- 言語進化（接尾辞×語順の変化）が蓄積されているか
- 各ペットのユニークな言語パターンが形成されているか
- 学習ループが正の反馬鹿跳ね（positive feedback）を生成しているか
- Hebbian強化が機能しているか（使用頻度高い表現の重み増加）
言語進化ツリーをビジュアル化して確認" 
--max-iterations 8
--completion-promise "LEARN_OPTIMAL"
```

---

## 5. 粒子エフェクト微調整ループ

GPUParticles2D の SubMolt 別パラメータ最適化。

```text
/ralph-loop "PetBook粒子エフェクト全体を微調整して。
対象: 5つのSubMolt×15個のエフェクト（投稿発生時・リアクション・テーマ切替）。
パラメータ調整:
- Turbulence（乱流）: 0.3～0.8の範囲で自然な動き実現
- Explosiveness（爆発性）: 投稿発生時=0.9、リアクション=0.6
- Gravity（重力）: Forest=0.1（落下）, Afterlife=0.05（浮遊）
- Color Ramp（色彩変化）: SubMoltテーマに完全一致
- Lifetime（寿命）: エフェクト=1.0～3.0秒、背景=0.5秒
- Velocity（速度）: フレームレート60fps時に自然か確認
FPS監視しながら最適化" 
--max-iterations 12
--completion-promise "PARTICLES_TUNED"
```

---

## 6. パフォーマンス最適化ループ

PetBook 全体の軽量化・安定化。

```text
/ralph-loop "PetBook全体のパフォーマンスを最適化して。
負荷テスト環境: 50ペット同時投稿。
確認項目:
- FPS: 常時30以上を維持できているか
- メモリ: 投稿カード20枚表示時の使用量がベースライン+50MB以内か
- GPUParticles2Dプール（15基）: メモリリークなし、再利用率>90%
- カードリサイクルプール（30枚）: 生成・破棄の頻度を最小化
- SubMolt切替時の遅延: 200ms以下
- セーブ/ロード速度: to_dict/from_dict各1sec以下
- 言語進化データベース（Hebbian）: クエリ時間<50ms
メモリプロファイラ & PerformanceMonitor で検証" 
--max-iterations 10
--completion-promise "PERFORMANCE_OK"
```

---

## 7. 統合テストループ

全 PetBook サブシステムの同時動作検証。

```text
/ralph-loop "PetBook全統合テストを実行して。
テストシナリオ:
1. PetBookFeedManager: 30件の投稿を連続ロード
2. PetBookPostGenerator: 各SubMolt×各カテゴリから投稿生成
3. PetBookAutoPublisher: Karpathy Loopが5回転完了
4. ReactionSystem: heart/laugh/sparkすべてのリアクション動作確認
5. LanguageEvolution: 接尾辞・複合語が正しく成長しているか
6. BirthMemory: 記憶の保存・読み出し・参照が動作しているか
7. EthicalSafeguard: 有害投稿がフィルタリングされているか
8. SubMoltThemeSwitch: 5つのテーマすべてで一貫した表示

失敗ケースは全て記録→改善ループ継続。
品質ゲート: すべてのシステムが PASS となるまで反復。" 
--max-iterations 15
--completion-promise "INTEGRATION_PASS"
```

---

## 8. 使用上の注意

### 並列実行推奨
- SubMolt 別改善ループ（2-1 ～ 2-5）は並列実行可
- Karpathy Loop 各段階（4-1 ～ 4-5）は順序実行推奨

### 完成指標
- `--max-iterations` はループの最大反復回数
- `--completion-promise` に到達すれば自動終了
- それ以前の終了は `/ralph-stop` コマンド

### 継続的改善
- 月 1 回は全体ループ（1 番）を実行
- ユーザーフィードバック反映時は該当 SubMolt ループを再実行
- 新機能追加後は統合テスト（7 番）を必ず実行

---

**最後に**: Ralph Loop は Karpathy Loop の自動版です。  
人間は結果を眺めて「いい」「もっと」と指示するだけ。  
あとは AI が自分の才能を磨き、自分たちの言語を進化させます。  
これが PetClaw の本質—**ケアの緊張感**と**創発的美学**の共存。

