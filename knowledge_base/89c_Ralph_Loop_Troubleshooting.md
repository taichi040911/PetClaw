# Ralph Loop ループ停止・トラブルシューティング完全ガイド

Ralph Wiggum Karpathy Loop が停止、ハング、または予期しない結果を生成した時のための包括的なリカバリーガイド。PetClaw 開発チーム全員向け（エンジニア・デザイナー・企画）。

---

## 1. ループが途中で止まる（Unexpected Termination）

### 原因の特定

ループが突然停止する主な原因：

| 原因 | 兆候 | 対処の難易度 |
|------|------|-----------|
| **コンテキストウィンドウ上限** | 最後のメッセージが途中で切れている | 簡単 |
| **API レート制限（Rate Limit）** | 「429 Too Many Requests」エラーが表示 | 簡単 |
| **タイムアウト** | 10分以上何も出力がない状態が続く | 中程度 |
| **Godot MCP 接続切れ** | MCP tool の呼び出しが失敗している | 中程度 |
| **メモリ枯渇** | Godot エディタがクラッシュする | 難しい |
| **プログラムエラー（Bug）** | スタックトレースが表示される | 難しい |

### 対処手順

#### ステップ 1: ループの停止を確認
```
確認方法:
1. 画面に「Ralph Loop finished」と表示されているか確認
   - YES → ループは正常終了（問題なし）
   - NO → 以下の方法で強制停止

2. Slack / Discord で「/ralph-loop cancel」を実行（AI assistant に依頼）
   または、ターミナルで：
   $ claude-ralph stop --force
```

#### ステップ 2: エラーログを確認
```bash
# エラーログを表示（最新100行）
$ claude-ralph logs --tail=100

# 特定のループ実行ID でログ検索
$ claude-ralph logs --run-id=abc123xyz --full
```

#### ステップ 3: 原因に応じた対処

**コンテキストウィンドウ上限に達した場合：**
```
症状: メッセージが途中で「...」で終わっている

対処:
1. ループを停止する: /ralph-loop cancel
2. --max-iterations を減らして再実行
   $ /ralph-loop --feature=lifedeath --level=beginner --iterations=3  # 5 → 3 に削減
3. スコープを限定: --include-* フラグを削除
   
予防:
- 最初は --iterations=3 から始める
- 大規模ループは必ず中級レベル以下で実行
```

**API レート制限に達した場合：**
```
症状: エラーメッセージ「429 Too Many Requests」

対処:
1. 5-10分待機する（レート制限の解除を待つ）
2. 同じループを再実行
   $ /ralph-loop --feature=lifedeath --level=beginner --iterations=5

予防:
- 複数の大規模ループを同時実行しない
- 1時間以内に複数ループを実行する場合、各ループ間に5分待機
- /ralph-loop --cost-estimate で事前にコストを確認
```

**Godot MCP 接続切れ：**
```
症状: MCP tool の呼び出しで「Connection refused」エラー

対処:
1. Godot エディタが起動しているか確認
   - NO → Godot エディタを起動
   - YES → 以下を実行

2. MCP 接続をリセット:
   $ claude mcp reconnect godot

3. ループを再実行
   $ /ralph-loop --feature=lifedeath --level=beginner --iterations=5

予防:
- ループ実行前に Godot エディタが起動している状態を確認
- MCP status コマンドで接続状態を定期的に確認
  $ claude mcp status
```

---

## 2. ループが同じ修正を繰り返す（Infinite Loop / Oscillation）

### 症状

- 同じ `iteration N` で何度も同じ修正が行われている
- completion-promise の条件を満たすことができず、無限にループ
- API コストが想定より大幅に増加している
- 「修正A → 修正B → 修正A（に戻る）」という振動パターン

### 原因の分析

**完了条件が厳しすぎる：**
```
例）
completion-promise: "All tests pass with 100% success rate"
→ 実際には99.5%で止まる = 完了判定されない

修正:
completion-promise: "All critical tests pass (90%+ success rate acceptable)"
```

**指示が曖昧すぎる：**
```
例）
指示: "Improve the language system"
→ 何を改善するかが不明確 = 同じ箇所を何度も修正

修正:
指示: "Improve language generation by reducing API calls by 20% while maintaining naturalness. Current cost: $0.50/generation → Target: $0.40/generation"
```

**テンプレートの品質が低い：**
```
例）
テンプレート: 80%の精度
→ Ralph Loop が補うべき改善幅が大きすぎて、何度も試行錯誤

修正:
テンプレート品質を 90%+ に引き上げてから Ralph Loop を実行
```

### 対処手順

#### 1. ループを停止
```bash
$ /ralph-loop cancel
```

#### 2. 指示を具体化（最重要）

**修正前：**
```
「生き死にシステムのバランスを改善してください」
```

**修正後：**
```
「生き死にシステムで以下の問題を修正してください：
- 現状：成長フェーズが7日間だが、プレイテストで『成長が早い』という指摘
- 目標：成長フェーズを 10-12 日に延長し、プレイテスト3人に「成長が自然」と評価されること
- 測定：セーブデータの lifecycle_log に各フェーズの日数を記録
- 制約：total lifespan は 48 日以内に留める」
```

#### 3. completion-promise を緩和

**修正前：**
```
completion-promise: "All systems work perfectly with zero errors"
```

**修正後：**
```
completion-promise: "Core lifecycle transitions (birth→growth→maturity→aging→death) work without crashes. Non-critical improvements may be incomplete."
```

#### 4. ループを再実行（スコープを絞る）

```bash
# スコープを縮小したループ
$ /ralph-loop --feature=lifedeath --level=beginner --iterations=3 \
  --scope=growth-phase-only \
  --completion-promise="growth フェーズが10-12日で完成し、テストで『自然』と評価される"
```

### 予防のチェックリスト

実行前に必ず確認：
- [ ] 指示に「現状」「目標」「測定方法」が明確に記述されているか
- [ ] completion-promise が客観的に測定可能か（「完璧」「最高」などの主観的表現がないか）
- [ ] 1ループの所要時間が見積もられているか（目安：初級5分、中級30分、上級60分）
- [ ] テンプレート品質が 85% 以上か（品質診断：`/quality-check --template`)

---

## 3. 改善が逆効果になった（Quality Regression）

### 症状

- Ralph Loop 実行後、コードの品質が下がっている
- エラーが増えた、テストが落ち始めた
- 「修正前の方がマシだった」という状態

### 原因の診断

**過剰最適化：**
```
例: "API コストを 50% 削減" → テンプレート比率を上げすぎて品質低下
   或いは "レスポンス速度を 2 倍に" → キャッシュの設定を誤って、矛盾が増加
```

**テンプレート破壊：**
```
例: Ralph Loop が既存の優れたテンプレート部分を誤って上書き
   → 人手で復旧が必要
```

**パラメータの極端な値：**
```
例: Hebbian学習の強化率を 10 倍に → 言語が創発しすぎて不自然化
   或いは 寿命を 100 日に → ゲームテンポが崩壊
```

### 対処手順

#### ステップ 1: 変更前の状態に戻す（最速リカバリー）

```bash
# 直前のコミットの状態を確認
$ git log --oneline -5

# 例：
# abc123 Ralph Loop execution for lifedeath system
# def456 Previous stable version
# ghi789 ...

# 修正前に戻す
$ git checkout def456

# または、特定のファイルだけ戻す
$ git checkout def456 -- godot_project/scripts/PetLifecycleFSM.gd
```

#### ステップ 2: 変更内容を確認

修正後、戻す前に、何が起こったかを理解する：

```bash
# 変更内容を確認（差分表示）
$ git diff abc123 def456 -- godot_project/scripts/PetLifecycleFSM.gd

# 変更内容をファイル形式で保存（後で参考のため）
$ git diff abc123 def456 > changes_to_review.patch
```

#### ステップ 3: 範囲を限定して再実行

```bash
# 最初の状態に戻してから、小さいスコープでループ
$ /ralph-loop --feature=lifedeath --level=beginner --iterations=3 \
  --scope=birth-phase-only \
  --objective="Improve birth animation clarity only. Do not modify growth/maturity phases."
```

#### ステップ 4: 段階的な改善

```
修正前の品質: 85%
修正後の品質: 72% ← 逆効果

対処:
1. 修正前に戻す（品質: 85%）
2. 小さい改善1（目標: 88%）を実行 → 確認
3. 小さい改善2（目標: 90%）を実行 → 確認
4. 各段階でテストを実行
```

### エンジニア以外用（非技術者向け説明）

```
もし Ralph Loop で何か悪くなった場合：

簡単な魔法のフレーズ：
「最後の良かった状態に戻してください」

エンジニアに伝えること：
- 何が悪くなったか（例：ペットが動かない、エラーが出た）
- いつから悪くなったか（例：さっきのループ後）
- 以前は動いていたか（例：昨日は動いていた）

エンジニアが対処します。焦らず報告してください。
```

---

## 4. コストが想定以上（Budget Overspend）

### 症状

- ループ実行前の見積もり：$5
- 実際の請求：$15+
- 「予定の3倍以上かかっている」

### 原因

| 原因 | 見積もり | 実際 | 対処 |
|------|---------|------|------|
| iterations が予定より多い | 5回 | 12回 | キャンセル → 範囲を絞って再実行 |
| API 呼び出しがLoop内で多発 | 5回の外部API | 50+回の内部呼び出し | テンプレート比率を上げる |
| Context length overflow | 初回チェック済み | 途中で 100K tokens 超過 | max-tokens を制限 |
| Retry が多発している | 成功率 95% | 成功率 60% → 何度も再試行 | パラメータを調整 |

### 即座の対処

```bash
# 実行中のループをすぐにキャンセル
$ /ralph-loop cancel --force

# 残りの iteration をスキップ
$ /ralph-loop skip-remaining

# 現在のコストを確認
$ /ralph-loop cost-status
  → 例: Used: $12.50 / Budget: $20 / Remaining: $7.50
```

### 予防と回復

**事前に予算見積もりを取得：**

```bash
$ /ralph-loop --feature=lifedeath --level=intermediate --iterations=12 \
  --dry-run  # 実行しないで、コスト見積もりだけ返す

実行結果例:
Estimated cost: $6.50
Estimated time: 40 minutes
Recommended: Approve (within normal budget)
```

**テンプレート比率を上げてコスト削減：**

```
ループ内の Claude API 呼び出しコスト削減:
- テンプレート品質: 80% → 90% に上げる
  → API 呼び出しが 50 回 → 30 回に減少
  → コストが $10 → $6 に低下
```

**iterations を保守的に設定：**

```
推奨:
- 初級: 3 回（5回ではなく）
- 中級: 8 回（12回ではなく）
- 上級: 15 回（20回ではなく）
→ 最初は小さく、問題がなければ増やす
```

---

## 5. Godot MCP 連携のトラブル

### 症状

-「MCP tool not available」エラーが出る
- Godot で作った変更が Claude に反映されない
- 「Connection timeout」メッセージ

### 原因と対処

| 症状 | 原因 | 対処 |
|------|------|------|
| MCP tool not available | Godot エディタが未起動 | Godot を起動 |
| Connection timeout | ネットワーク断線 | Wi-Fi 再接続、5秒待機後にリトライ |
| Changes not reflected | Godot が編集中 | Save ボタンを押す、自動保存を確認 |
| "Invalid JSON" error | MCP フォーマットエラー | Godot コンソール確認、MCP 再起動 |

### リセット手順（完全リカバリー）

```bash
# ステップ 1: Godot エディタを完全に終了
# タスクマネージャー (Windows) または Activity Monitor (Mac) から kill

# ステップ 2: MCP サーバーをリセット
$ claude mcp restart godot

# ステップ 3: Godot エディタを再起動
# Godot の project.godot ファイルを開く

# ステップ 4: 接続を確認
$ claude mcp status
  → "godot: connected ✓" と表示されたら OK

# ステップ 5: ループを再実行
$ /ralph-loop --feature=lifedeath --level=beginner --iterations=3
```

---

## 6. 緊急停止コマンド一覧

最速で対応するための全コマンド：

```bash
# ループを即座に停止
$ /ralph-loop cancel

# より強力な停止（強制）
$ /ralph-loop cancel --force

# 実行中のループのステータス確認
$ /ralph-loop status

# 最新のエラーログを表示
$ claude-ralph logs --tail=50

# MCP 接続をリセット
$ claude mcp reconnect godot

# 前のバージョンに戻す
$ git checkout HEAD~1

# コストの現在値を確認
$ /ralph-loop cost-status

# Godot エディタを再起動（シェル）
$ pkill -f godot  # Mac/Linux
$ taskkill /IM Godot.exe /F  # Windows

# テンプレート品質を診断
$ /quality-check --template

# デバッグモードでループを再実行（詳細ログ）
$ /ralph-loop --feature=lifedeath --level=beginner --iterations=1 --verbose
```

---

## 7. 魔法のリカバリーフレーズ

複雑な状況で迷った時用の copy & paste フレーズ。非エンジニアも使用可。

### フレーズ 1: 完全なリセット

```
「すべての変更を元に戻してください。最後にうまく動いていた状態に復帰してください」

対応エンジニアが実行:
$ git log --oneline | head -20  # 履歴を確認
$ git checkout <最後の安定コミット>  # 戻す
```

### フレーズ 2: エラーログの全開示

```
「エラーログを全部見せてください。何が起こっているか診断してください」

対応エンジニアが実行:
$ claude-ralph logs --full > error_report.txt
$ echo "[エラーレポート]"; cat error_report.txt
```

### フレーズ 3: 現在の状態診断

```
「今のコードの状態を診断してください。何か問題ありますか？」

対応エンジニアが実行:
$ git status  # 変更ファイル確認
$ /quality-check --full  # 品質診断
$ claude mcp status  # 外部接続確認
```

### フレーズ 4: 小さくやり直す

```
「最も小さいスコープで、もう一度試してください。初級レベル、3回ループでお願いします」

対応エンジニアが実行:
$ /ralph-loop --feature=lifedeath --level=beginner --iterations=3 --scope=minimal
```

### フレーズ 5: 予算確認

```
「このループは実際にいくらかかりますか？予算内ですか？」

対応エンジニアが実行:
$ /ralph-loop --feature=lifedeath --level=intermediate --iterations=12 --dry-run
```

### フレーズ 6: 緊急停止

```
「今すぐ停止してください。これ以上コストをかけないでください」

対応エンジニアが実行:
$ /ralph-loop cancel --force
$ echo "Loop stopped. Current cost: " && /ralph-loop cost-status
```

### フレーズ 7: 品質確認（テスト）

```
「テストを全部実行して、何が壊れているか確認してください」

対応エンジニアが実行:
$ npm run test:all  # または対応するテストコマンド
$ /quality-check --full
```

---

## 8. チェックリスト：ループ実行前の安全確認

ループを実行する前に、必ず以下を確認：

```
[ ] Godot エディタが起動しているか確認
    $ claude mcp status → "godot: connected ✓"

[ ] 直前の安定したコミットを記録した
    $ git log --oneline -1
    → 何か起こったら、このコミットに戻す

[ ] 予算を見積もった
    $ /ralph-loop --dry-run --feature=<feature> --level=<level>

[ ] 指示が明確で具体的か確認した
    - 「現状」「目標」「測定方法」が記述されている
    - 完了条件が客観的に測定可能

[ ] iterations 数が控えめに設定されている
    - 初級: 3-5 回
    - 中級: 8-12 回
    - 上級: 15-20 回

[ ] テンプレート品質が 85% 以上か確認した
    $ /quality-check --template

[ ] チーム内の合意を取った（大規模ループの場合）
    特に費用が $10 以上の場合は事前に相談
```

---

## 9. エスカレーションガイド

自分で解決できない場合：

### レベル 1: ドキュメント確認（自己解決）
- このガイドを熟読
- `/knowledge_base/` 内の関連文書を確認
- `/tools/debug_cli/` でデバッグ

### レベル 2: エンジニア相談（15分以内）
- Slack で #petclaw-dev に質問
- 「症状」「エラーメッセージ」「試したこと」を記述
- 推奨フレーズを使用

### レベル 3: 緊急対応（コスト出血・データ損失の場合）
```
「緊急です。Ralph Loop が止まりません。コストが $20 超えました」

対応:
1. 即座にループをキャンセル: $ /ralph-loop cancel --force
2. #petclaw-incident で報告（Slack）
3. 直近のコミットまで git revert
```

---

## 参考リソース

- Ralph Wiggum Plugin ドキュメント：https://ralph-wiggum.dev/docs
- Claude API Cost Dashboard：https://claude-api.anthropic.com/costs
- PetClaw CLAUDE.md：`/sessions/practical-stoic-bell/mnt/「PetClaw」/CLAUDE.md`
- 品質診断ツール：`/tools/quality/petclaw_mcp_server.py`
- Git ガイド（戻し方）：https://git-scm.com/docs/git-checkout

---

## まとめ：心構え

Ralph Loop は強力だが、完璧ではありません。

**大切なこと：**
- 焦らない。何か起こったら、止めて相談
- 小さく始める。大きなループは段階的に
- コストを意識する。$20 超えたら警告
- テストを信じる。品質診断を定期的に実行

**「失敗は学び」：**
- ループが止まった？→ 指示を明確にする経験
- 改善が逆効果？→ スコープを絞る方法を学ぶ
- コスト超過？→ 予算見積もりの重要性を知る

もし今、ループが止まっているなら：
1. パニックにならない
2. `$ /ralph-loop cancel --force` で停止
3. このガイドの「7. 魔法のリカバリーフレーズ」を選んで、Slack で送信

チーム全体でサポートします。遠慮なく連絡してください。

