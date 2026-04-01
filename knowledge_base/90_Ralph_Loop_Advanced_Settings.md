# KB90: Ralph Loop 高度設定例ガイド（非エンジニア向け）

**Document ID**: KB90
**Version**: 1.0
**Last Updated**: 2026-04-01
**対象読者**: 非エンジニア（コーディング経験なし〜初心者）
**前提**: KB89（Ralph Loop 詳細設定ガイド）を読了済み

---

## 1. Ralph Loopの高度設定の基本ルール

| パラメータ | 説明 | おすすめ値 |
|-----------|------|-----------|
| `--max-iterations <数字>` | 最大ループ回数 | 8〜20（多すぎるとコスト増） |
| `--completion-promise "DONE"` | この文字列が出たら自動停止 | 正確に一致させる |
| `--strategy reset\|continue` | `reset`=各イテレーションでコンテキストリセット（安定） | `reset` が初心者向け |
| `--temperature <0.0〜1.0>` | 創造性の度合い | 0.7前後がバランス良い |
| `--safety-mode` | エラー時の自動停止や確認を強化 | 長時間ループ時に推奨 |

---

## 2. PetClaw向け高度設定例（そのままコピーして使用可能）

### 例1: PetBook UI + 粒子エフェクトの高度改善（おすすめ初心者高度版）

```text
/ralph-loop "PetBookのUI全体をより美しく、SubMoltごとに粒子と色をテーマに合わせて最適化。#AfterlifeEchoesは暗い粒子、#BreedingCircleはハート粒子を強化。非エンジニアでもわかりやすい説明を毎回つけて。"
--max-iterations 12
--completion-promise "PETBOOK_VISUAL_DONE"
--strategy reset
--temperature 0.65
```

**ポイント**: `temperature 0.65` で安定しつつ視覚的な改善を引き出す。`reset`戦略で各ループが独立して安全。

---

### 例2: 独自言語・反乱言語の創発を強くする（言語進化特化）

```text
/ralph-loop "AtoA会話の中で独自言語（接尾辞・語順・新語）を自然に進化させる仕組みを強化。生物模倣記憶と連動させ、#LanguageRebellion SubMoltで特に創造的に。毎回の改善点を明確に説明。"
--max-iterations 15
--completion-promise "LANGUAGE_EVOLUTION_READY"
--strategy reset
--temperature 0.8
```

**ポイント**: 言語進化は創造性が重要なので `temperature 0.8` と高め。15回のループで接尾辞（-vex, -sol, -nox）と複合語の自然な定着を目指す。

---

### 例3: 生き死に + 交配システムのバランス調整（生態系特化）

```text
/ralph-loop "生き死にシステムと交配システムのバランスを最高峰に調整。緊張感がありつつ愛着が強く湧くように。MCPでGodotの視覚テストも行い、粒子演出を感情連動で美しく。ステップごとに結果をわかりやすく説明。"
--max-iterations 10
--completion-promise "ECOSYSTEM_BALANCE_OK"
--strategy continue
--temperature 0.6
```

**ポイント**: バランス調整は前回の状態を引き継ぐ必要があるので `strategy continue`。`temperature 0.6` で正確性重視。P1原則（一貫性×記憶=愛着）を守る。

---

### 例4: PetBook全体の自動投稿生成 + SubMolt連動（Moltbook風コミュニティ）

```text
/ralph-loop "PetBookでSubMoltごとに自然で感動的な投稿を自動生成する仕組みを構築。#AfterlifeEchoesは死と再生の詩的表現、#BreedingCircleは温かい家族の喜びを強調。独自言語を適度に混ぜ、Ralph Loop内で改善を繰り返せ。"
--max-iterations 18
--completion-promise "PETBOOK_POST_SYSTEM_COMPLETE"
--temperature 0.75
```

**ポイント**: 18回の長めループで5つのSubMolt全体の投稿品質を底上げ。`temperature 0.75` で創造性と一貫性のバランスを取る。

---

### 例5: 安全重視の長時間ループ（コストを抑えたいとき）

```text
/ralph-loop "PetClawの全体的な品質を少しずつ向上。毎回変更点をリストアップし、私が確認しやすいように説明。エラーが出たらすぐに止めて報告。"
--max-iterations 8
--completion-promise "SAFE_IMPROVEMENT_DONE"
--strategy reset
--temperature 0.5
```

**ポイント**: `temperature 0.5` + `max-iterations 8` + `strategy reset` の安全重視トリプル。初めての高度設定におすすめ。

---

## 3. 高度設定のTips（非エンジニア向け）

### パラメータ選びの目安

| やりたいこと | iterations | temperature | strategy |
|-------------|-----------|-------------|----------|
| 小さなUI修正 | 8〜10 | 0.5〜0.6 | reset |
| 視覚演出改善 | 10〜15 | 0.6〜0.7 | reset |
| 言語・創造系 | 12〜20 | 0.7〜0.8 | reset |
| バランス調整 | 8〜12 | 0.5〜0.6 | continue |
| 全体品質底上げ | 15〜20 | 0.6〜0.7 | reset |

### completion-promise のコツ

- シンプルでユニークな単語を使う（Claudeが誤って出力しにくいもの）
- 良い例: `"PETBOOK_VISUAL_DONE"`, `"LANGUAGE_EVOLUTION_READY"`
- 悪い例: `"done"`, `"OK"` （普通の文中に出やすい）

### 停止と確認

- **停止コマンド**: ループ中に `/cancel-ralph` と入力すれば即停止
- **確認習慣**: ループ終了後、「この変更のポイントを3つにまとめて教えて」と聞く
- **コスト節約**: `--max-iterations` を小さくし、重要な部分だけループを回す

---

## 4. strategy の使い分け

| strategy | 動作 | おすすめ場面 |
|----------|------|-------------|
| `reset` | 各イテレーションでコンテキストをリセット | UI改善・テンプレート生成・独立した改善 |
| `continue` | 前のイテレーションの結果を引き継ぐ | バランス調整・段階的改善・依存関係あり |

**迷ったら `reset` を選んでください**。安定して動作し、一つのループが失敗しても他に影響しません。

---

## 5. temperature の感覚的ガイド

```
0.3 ────── 0.5 ────── 0.7 ────── 0.9 ────── 1.0
 │          │          │          │          │
 正確・安定   バランス    創造的     冒険的     カオス
 バグ修正に   通常の改善   言語進化に   実験に     非推奨
```

PetClawでの推奨範囲: **0.5〜0.8**

---

## 6. すぐに試すおすすめ（コピーしてClaude Codeに貼る）

```text
/ralph-loop "PetBookの#BreedingCircle SubMoltの投稿生成とハート粒子演出を美しく改善。温かさと喜びが伝わるように。"
--max-iterations 10
--completion-promise "BREEDING_VISUAL_DONE"
--temperature 0.7
```

これでRalph Loopが自動で回り、Claudeが自分で何度も改善してくれます。

---

## 7. 高度設定の組み合わせレシピ

### レシピA: 「安全に少しずつ改善」

```text
--max-iterations 8 --strategy reset --temperature 0.5 --safety-mode
```

### レシピB: 「創造的に大胆に改善」

```text
--max-iterations 15 --strategy reset --temperature 0.8
```

### レシピC: 「段階的にバランス調整」

```text
--max-iterations 12 --strategy continue --temperature 0.6
```

### レシピD: 「全力で最高品質を目指す」

```text
--max-iterations 20 --strategy reset --temperature 0.75
```

---

## 8. 関連KB文書

| KB# | タイトル | 関連性 |
|-----|---------|--------|
| KB89 | Ralph Loop 詳細設定ガイド | 基本設定・インストール手順 |
| KB89a | PetBook Ralph Loop指示集 | PetBook機能別コマンド |
| KB89b | 機能別Ralph Loop設定 | 生き死に・言語・交配の詳細 |
| KB89c | ループ対処法ガイド | トラブルシューティング |
| KB88 | 非エンジニア開発ガイド | 全体の開発フロー |
