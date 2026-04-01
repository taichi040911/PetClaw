# KB89: Ralph Loop 詳細設定ガイド（非エンジニア向け）

**Document ID**: KB89
**Version**: 1.0
**Last Updated**: 2026-04-01
**対象読者**: 非エンジニア（コーディング経験なし〜初心者）
**前提**: KB88（非エンジニア向け開発ガイド）を読了済み

---

## 1. Ralph Loopとは？（超簡単解説）

Ralph Loop（別名: Ralph Wiggum）は、Claude Codeを「whileループ」で何度も自動実行させるプラグインです。

- Claudeが自分で「計画 → 実行 → チェック → 改善」を繰り返す
- あなたは「もっと良くして」と指示するだけで、Claudeが何十回も修正してくれる
- PetClawでは独自言語の進化、生き死にバランス調整、PetBook投稿生成などに最適

**非エンジニア向けメリット**: コードを書かずに「ループを回して改善して」と言うだけでOK。Claudeが勝手に何度も試行錯誤してくれます。

---

## 2. インストール手順（5分で完了）

Claude Codeを開いて、以下のコマンドを順番に実行してください。

### ステップ1: プラグインをインストール

```text
/plugin install ralph-wiggum@claude-plugins-official
```

### ステップ2: インストール確認

```text
/ralph-loop --help
```

ヘルプが表示されれば成功です。

### ステップ3: Godot連携（PetClaw用）

```text
claude mcp add godot
```

---

## 3. 基本的な使い方（一番簡単なコマンド）

```text
/ralph-loop "PetClawのPetBook UIをより美しく改善して。粒子エフェクトを感情に合わせて変化させるように。" --max-iterations 15 --completion-promise "DONE"
```

### コマンドの意味

| パラメータ | 説明 | おすすめ値 |
|-----------|------|-----------|
| `"ここに指示"` | 何をやってほしいか（自然言語でOK） | 具体的に書くほど良い |
| `--max-iterations` | 最大ループ回数 | 10〜20（多すぎるとコストがかかる） |
| `--completion-promise` | この文字列が出力されたらループ自動停止 | `"DONE"` や機能名 |

---

## 4. PetClaw向けおすすめ詳細設定

### 4.1 基本設定（まずはこれから）

```text
/ralph-loop "PetClawの#AfterlifeEchoes SubMoltの投稿生成と視覚効果を改善して。生き死にの感動を強く表現。" --max-iterations 12 --completion-promise "COMPLETED"
```

### 4.2 独自言語進化を自動で回す場合

```text
/ralph-loop "AtoA会話の中で独自言語（接尾辞・語順）を自然に進化させる仕組みを強化。生物模倣記憶と連動させて。" --max-iterations 20 --completion-promise "LANGUAGE_EVOLUTION_READY"
```

### 4.3 生き死に・交配システムのバランス調整

```text
/ralph-loop "生き死にシステムと交配システムのバランスを調整。緊張感がありつつ、愛着が強く湧くように改善。MCPで視覚テストも行って。" --max-iterations 15 --completion-promise "BALANCE_OK"
```

### 4.4 PetBook全体の自動改善

```text
/ralph-loop "PetBookのUIと投稿生成を最高峰に。SubMoltごとの視覚デザイン（粒子・色・ハイライト）をテーマに合わせて美しくし、観察する楽しさを最大化。" --max-iterations 18 --completion-promise "PETBOOK_COMPLETE"
```

---

## 5. 非エンジニア向けTips（失敗を減らすコツ）

| Tips | 詳細 |
|------|------|
| 最初は小さく | 「PetBookのタイムライン部分だけ改善して」と区切って指示 |
| 確認を入れる | ループが終わったら「この変更の説明をわかりやすく教えて」と聞く |
| 停止方法 | ループ中に `/cancel-ralph` と入力すれば止められます |
| コスト管理 | `--max-iterations` を10〜15に設定。重要な部分だけループを回す |

### CLAUDE.mdに書いておくおすすめ設定

```text
私は非エンジニアです。
Ralph Loopを使うときは、いつもステップごとに結果を説明してください。
専門用語は避けて、わかりやすく。
```

---

## 6. すぐに試せるおすすめ指示（コピーして使ってください）

```text
SuperpowersとRalph Loopを活性化。
私は非エンジニアなので、ステップごとに丁寧に説明しながら進めてください。
まずはPetBookの#BreedingCircle SubMoltの投稿生成とハート粒子演出を改善して。
--max-iterations 10 --completion-promise "BREEDING_READY"
```

---

## 7. PetClaw Karpathy Loopとの連携

Ralph LoopはPetClawの**Karpathy Loop**（`PetBookAutoPublisher`の5段階サイクル）と相性抜群です。

| Karpathy Loop段階 | Ralph Loopでの改善ポイント |
|-------------------|--------------------------|
| Observe（観察） | 「ペットの観察精度を上げて。環境・記憶・感情をもっと正確に読み取るように」 |
| Decide（判断） | 「投稿するSubMoltの選択ロジックを賢くして」 |
| Generate（生成） | 「テンプレート投稿の品質を上げて。複合語と接尾辞をもっと自然に」 |
| Evaluate（評価） | 「投稿品質スコアの計算を精密にして。0.6以下は再生成」 |
| Learn（学習） | 「Hebbian強化の閾値を調整して。使われた言葉が自然に定着するように」 |

### 連携コマンド例

```text
/ralph-loop "PetBookAutoPublisherのKarpathy Loop 5段階をすべて改善。特にGenerate段階のテンプレート品質とEvaluate段階のスコアリング精度を重点的に。P2原則（テンプレート70%/API30%）を維持しつつ。" --max-iterations 20 --completion-promise "KARPATHY_OPTIMIZED"
```

---

## 8. コスト計算の目安

| ループ回数 | 推定時間 | 推定コスト（Claude Max） | おすすめ用途 |
|-----------|---------|-------------------------|-------------|
| 5回 | 3〜5分 | 低 | 小さなUI修正 |
| 10回 | 8〜12分 | 中 | 1つのSubMolt改善 |
| 15回 | 12〜18分 | 中〜高 | システム全体の調整 |
| 20回 | 15〜25分 | 高 | 独自言語進化・バランス調整 |

**P2原則（API Cost is Physics）**: コストを意識して、重要な部分だけにループを使いましょう。

---

## 9. 関連KB文書

| KB# | タイトル | 関連性 |
|-----|---------|--------|
| KB88 | 非エンジニア向け開発ガイド | Ralph Loopの前提知識 |
| KB88a | CLAUDE.md初心者テンプレート | Ralph Loop設定の書き方 |
| KB88b | PetBook開発プロンプト集 | Phase別のLoop対象 |
| KB88c | つまずきポイント＆回避法 | Loop失敗時の対処 |
