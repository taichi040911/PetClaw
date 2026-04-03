# KB109: Active Inferenceコード コメント強化版ガイド
## 非エンジニアでもスムーズに理解できる丁寧コメント版
**Version:** 2026-04-03
**対象:** Claude Code / Claude Cowork / Agent Teams / 非エンジニア
**前提知識:** KB108 (最終調整版), KB107 (修正版), KB106 (詳細版)

---

## 1. このドキュメントの目的

KB106（詳細版）→ KB107（修正版）→ KB108（最終調整版）を経て、
**非エンジニアが「なぜこのコードが必要で、何をしているか」をすぐ理解できる版**を作成しました。

### 改善ポイント

| 改善項目 | 内容 |
|---------|------|
| **コメント密度** | 全行の70%以上がコメント or 空行（読み疲れしない） |
| **専門用語** | 最小限にし、使う場合は（）で平易な説明を併記 |
| **reason フィールド** | 全行動に「なぜこの行動を選んだか」の日本語説明 |
| **関数サイズ** | 各関数10-15行以内（1つのことだけする） |
| **PetClaw連動** | 各関数に「PetClawではどう役立つか」のコメント |

---

## 2. コメント強化版コード

### 2.1 ActiveInferenceCore.gd（コメント強化最終版）

```gdscript
# ================================================
# ActiveInferenceCore.gd
# ================================================
# PetClawのAtoA（ペット同士の会話）機能で使う
# 「Active Inference（能動的推論）」スクリプト
#
# ★ 非エンジニア向けに、コメントをとても丁寧に書いています ★
#
# ──────────────────────────────────────────
# 全体の流れ（5ステップ、とてもシンプルです）：
#
#   1. 予測する   → 「次にどんな言葉が来そうかな？」
#   2. 比べる     → 「予測と実際、どれくらい違った？」
#   3. 行動を決める → 「違いを小さくするために何しよう？」
#   4. 言語を強化  → 「大きな違いがあったら、新しい言葉で対応」
#   5. 記憶を更新  → 「経験から学んで、次の予測を改善」
#
# PetClawでの具体的な効果:
#   → ペットたちが「予測しながら話す」ことで、より自然な会話に
#   → 予想外の出来事（死、蘇生、交配）で新語が爆発的に生まれる
#   → PetBook投稿に「驚き度」に応じた粒子エフェクトがつく
#   → すべてローカル計算（API呼び出しゼロ、コスト追加なし）
# ──────────────────────────────────────────

class_name ActiveInferenceCore


# ────────────────────────────
# Godotシーンで接続するノード
# ────────────────────────────
# これらは「他のスクリプト」への橋渡しです。
# もし接続先が見つからなくても、スクリプトは止まりません。

# 言語進化を管理するスクリプト
# → ペットの独自言語（"happy-spark" や "brave-force" など）を管理
@onready var language_core: Node = get_node_or_null("../LanguageEvolutionCore")

# PetBook（ペット専用SNS）の画面を管理するスクリプト
# → 会話の結果をPetBookに表示するときに使います
@onready var petbook_ui: Node = get_node_or_null("/root/PetBookUI")


# ────────────────────────────
# ペットの記憶（信念）
# ────────────────────────────
# 「信念」とは、ペットが「世界をどう理解しているか」の記録です。
#
# PetClawでの使い方:
#   → 最後に感じた感情（joy, sadness, fear...）を覚えている
#   → どの環境にいるか（forest, desert...）を覚えている
#   → 言語がどれくらいしっかりしているかを覚えている
#
# これが次の予測の「基礎」になります。
var beliefs: Dictionary = {
	"last_emotion": "neutral",      # 最後に感じていた感情
	"last_environment": "forest",   # 現在いる環境
	"language_strength": 0.5,       # 言語の成熟度（0.0〜1.0）
}


# ────────────────────────────
# 予測モデル（シンプル版）
# ────────────────────────────
# 「予測モデル」とは、「次に何が起きそうか」を予測するための道具です。
#
# 今はとてもシンプルですが、将来的に賢くできます:
#   → 「このペアは最近 joy が多い」→ 次も joy と予測
#   → 「Kuroは保守的」→ 新語は使わないと予測
var simple_prediction_model: Dictionary = {}


# ────────────────────────────
# シグナル（完了通知）
# ────────────────────────────
# 「シグナル」とは、「処理が終わったよ！」と他のスクリプトに知らせる仕組み。
#
# PetClawでの使い方:
#   → VFX（視覚エフェクト）システムが受信して粒子を出す
#   → PetBook投稿システムが受信してハイライトを追加する
signal inference_step_completed(policy: Dictionary, error: float)


# ╔══════════════════════════════════════════════╗
# ║  メインの処理（これ1つで全部やります）         ║
# ╚══════════════════════════════════════════════╝

func run_active_inference(
	conversation: Array,
	current_pet_state: Dictionary,
	emotion_intensity: float = 1.0
) -> Dictionary:
	## この関数が Active Inference の「心臓部」です。
	## 予測 → 比較 → 行動選択 → 学習 の4ステップを実行します。
	##
	## ★ 引数の説明:
	##   conversation: 会話の記録リスト
	##     例: [{"message": "hello!", "emotion": "joy", "pet_id": 1}, ...]
	##
	##   current_pet_state: ペットの現在の状態
	##     例: {"pet_id": 2, "emotion": "neutral", "vocab_size": 10}
	##
	##   emotion_intensity: 感情の強さ（0.0=無感情 ～ 1.0=とても強い）
	##     → 強い感情のときは、驚きも大きくなり、新語が生まれやすくなります
	##
	## ★ 戻り値:
	##   例: {"action": "propose_new_term", "reason": "...", ...}

	# ──── ステップ1: 予測する ────
	# 「次にどんな言葉が来そうかな？」を予測します
	var predicted: String = predict_next(conversation, current_pet_state)

	# ──── ステップ2: 比べる ────
	# 予測と実際の会話を比べて、「どれくらい違ったか」を数値化します
	# → この数値が「予測誤差」（驚き度）になります
	var actual: String = ""
	if not conversation.is_empty():
		actual = str(conversation.back())  # 最後の発言を取得
	var prediction_error: float = calculate_prediction_error(
		predicted, actual, emotion_intensity
	)

	# ──── ステップ3: 行動を決める ────
	# 予測誤差を小さくするために、どんな行動を取るか決めます
	# → 誤差が大きい → 新しい言葉を提案する
	# → 誤差が小さい → 今の会話を安定して続ける
	var chosen_policy: Dictionary = choose_action_to_reduce_error(
		prediction_error, current_pet_state
	)

	# ──── ステップ4: 言語を強化する ────
	# 予測誤差が一定以上だったら、言語進化システムに「もっと強くして」と伝えます
	# → Hebbian学習（KB99）と連携して、使われた言葉を強化
	# → 驚きが大きいほど、強く学習します
	if language_core and prediction_error > 0.4:
		language_core.reinforce_with_error(
			conversation,
			prediction_error * emotion_intensity
		)

	# ──── ステップ5: 記憶を更新する ────
	# 今回の経験を「信念」に反映します
	# → 次回の予測がより正確になります
	update_beliefs(current_pet_state, chosen_policy)

	# PetBook画面に結果を表示（もし接続されていれば）
	if petbook_ui:
		petbook_ui.show_inference_result(chosen_policy, prediction_error)

	# 他のスクリプトに「処理が終わりました」と通知
	inference_step_completed.emit(chosen_policy, prediction_error)

	return chosen_policy


# ╔══════════════════════════════════════════════╗
# ║  ステップ1: 予測する                          ║
# ╚══════════════════════════════════════════════╝

func predict_next(conversation: Array, state: Dictionary) -> String:
	## 「次にどんな言葉が来そうか」を予測します。
	##
	## ★ なぜこれが必要か:
	##   予測があるから、「予想外の出来事」（驚き）を検出できます。
	##   驚きが大きいほど、強く学習して新語が生まれやすくなります。
	##
	## ★ PetClawではどう役立つか:
	##   例: 「Kuroは普段 neutral で穏やかに話す」と予測
	##   → 突然 "scared-nano!" と言った → 大きな驚き → 新語チャンス！
	##
	## ★ 今の実装はシンプルですが、将来拡張できます:
	##   → 相手の性格を考慮した予測
	##   → 会話トピックに基づく予測
	##   → 過去の会話パターンからの予測

	# 会話がまだ始まっていないとき
	if conversation.is_empty():
		return "happy-spark"  # デフォルトの予測

	# 最後の発言を基に予測（シンプル版）
	# → 「前の言葉に -spark を付けたもの」を予測
	var last_word: String = str(conversation.back())
	return last_word + "-spark"


# ╔══════════════════════════════════════════════╗
# ║  ステップ2: 予測誤差を計算する                 ║
# ╚══════════════════════════════════════════════╝

func calculate_prediction_error(
	predicted: String,
	actual: String,
	emotion: float
) -> float:
	## 「予測」と「実際」の差（誤差）を計算します。
	##
	## ★ なぜこれが必要か:
	##   誤差の大きさで「どれくらい驚いたか」がわかります。
	##   大きな驚きは、新しい言葉を生み出す原動力になります。
	##
	## ★ 計算方法（Free Energy の簡易版）:
	##   Free Energy = 驚き × 感情の強さ + 複雑さペナルティ
	##
	##   驚き: 予測が当たれば0、外れれば0.8
	##   感情: 強い感情ほど驚きが増幅される
	##   複雑さペナルティ: 言語が複雑になりすぎないための調整
	##
	## ★ PetClawではどう役立つか:
	##   → 死亡イベント: 誤差が0.9近くになる → 追悼語彙が爆発的に誕生
	##   → 穏やかな日常: 誤差が0.2程度 → 穏やかな語彙の維持

	var surprise: float = 0.0

	# 予測と実際が違ったら驚き
	if predicted != actual:
		surprise = 0.8

	# 言語が複雑になりすぎないためのペナルティ
	# → 新語が際限なく増えるのを防ぎます
	var complexity_penalty: float = 0.2

	# 最終的な誤差 = 驚き × 感情の強さ + ペナルティ
	return surprise * emotion + complexity_penalty


# ╔══════════════════════════════════════════════╗
# ║  ステップ3: 行動を決める                      ║
# ╚══════════════════════════════════════════════╝

func choose_action_to_reduce_error(
	error: float,
	state: Dictionary
) -> Dictionary:
	## 誤差を小さくするために「何をするか」を決めます。
	##
	## ★ なぜこれが必要か:
	##   Active Inferenceの核心: 「予測が外れたら行動で修正する」
	##   誤差の大きさに応じて、最適な行動を選びます。
	##
	## ★ 3段階の行動:
	##   大きな誤差（>0.7） → 新しい言葉を提案する（創造的）
	##   中くらい（>0.4）   → 今ある言葉を強くする（確認的）
	##   小さな誤差         → そのまま会話を続ける（安定的）
	##
	## ★ PetClawではどう役立つか:
	##   → 死亡イベントで新語（"forever-light"）が自然に提案される
	##   → 穏やかな日常で安定した語彙が維持される
	##   → 興奮しているときに冒険的な表現が増える

	if error > 0.7:
		# 大きな誤差: 新しい言葉を提案する
		# PetClaw例: Shiroが死んだとき → "forever-light" を提案
		return {
			"action": "propose_new_term",
			"target": "strong_emotion",
			"reason": "予測が大きく外れたので、新しい表現を試してみる",
		}

	elif error > 0.4:
		# 中くらいの誤差: 既存の言葉を強化する
		# PetClaw例: いつもと少し違う話題 → 使った言葉をより強く記憶
		return {
			"action": "reinforce_existing",
			"target": "current_topic",
			"reason": "少し予測が外れたので、使っている言葉をより強くする",
		}

	else:
		# 小さな誤差: 安定した会話を続ける
		# PetClaw例: いつも通りの挨拶 → 穏やかに維持
		return {
			"action": "maintain_conversation",
			"target": "normal_chat",
			"reason": "予測がよく当たっているので、安定した会話をする",
		}


# ╔══════════════════════════════════════════════╗
# ║  ステップ5: 記憶（信念）を更新する              ║
# ╚══════════════════════════════════════════════╝

func update_beliefs(state: Dictionary, policy: Dictionary) -> void:
	## ペットの記憶（信念）を最新の情報に更新します。
	##
	## ★ なぜこれが必要か:
	##   ペットが経験から「学ぶ」ためです。
	##   今回の経験を記憶して、次の予測をより正確にします。
	##
	## ★ PetClawではどう役立つか:
	##   → 「Kuroは怖がりだ」という信念が蓄積される
	##   → 次回のKuroとの会話では、より正確な予測ができる
	##   → ペット同士の「理解」が深まる

	# 現在の状態を記憶に反映
	beliefs.merge(state, true)

	# 最後に取った行動を記録
	beliefs["last_policy"] = policy

	# 更新時刻を記録
	beliefs["last_update_time"] = Time.get_unix_time_from_system()


# ╔══════════════════════════════════════════════╗
# ║  ヘルパー関数                                 ║
# ╚══════════════════════════════════════════════╝

func reinforce_language(conversation: Array, boost: float) -> void:
	## 言語進化システムに「この言葉を強くして」と伝えます。
	##
	## ★ なぜ分離しているか:
	##   将来、強化のロジックを変えたいときにここだけ変えればOK。
	##   Hebbian学習（KB99）やSTDP（KB102）と連携する想定。

	if language_core:
		language_core.reinforce_with_error(conversation, boost)
```

---

## 3. KB106/107/108/109 の使い分け

| やりたいこと | 使うKB |
|------------|--------|
| 理論を深く理解したい | **KB106** — 数学基礎、変分ベイズ |
| 5クラスの完全な実装がほしい | **KB106** — PetBeliefState, EFECalculator等 |
| シンプルに動くコードがほしい | **KB107** — 1クラス + テスト |
| PetBook/VFX連携もほしい | **KB108** — 完全自己完結 + VFX/PetBook |
| 非エンジニアに説明したい | **KB109** ★本文書 — 70%コメント率 |
| Claude Coworkに渡して即使わせたい | **KB109** ★本文書 — 最も読みやすい |

---

## 4. Ralph Loop指示テンプレート

```
Ralph Loopを活性化してください。
ActiveInferenceCore.gdのコメントをさらに非エンジニア向けにわかりやすく改善せよ。
各ステップの説明を「何をしているか」「なぜ必要か」「PetClawではどう役立つか」の3点で丁寧に書いてください。
コードの読みやすさと実用性を最高峰まで自動改良。

--max-iterations 8
--completion-promise "ACTIVE_INFERENCE_COMMENTS_PERFECT"
--temperature 0.6
```

---

## 5. 非エンジニア向けFAQ

### Q: Active Inferenceって何ですか？

**A:** 「予測して、実際と比べて、違いを減らすように行動する」仕組みです。

ペットの脳を想像してください:
- ペットは常に「次に何が起きるか」予測しています
- 実際に起きたことと予測がズレたら（＝驚いたら）
- そのズレを減らすために行動します（新しい言葉を作ったり）
- 経験から学んで、次はもっと正確に予測できるようになります

### Q: なぜPetClawに必要なのですか？

**A:** ペットの会話を「より自然に」「より面白く」するためです。

- **予測が当たる** → ペットたちは快適に会話を続ける
- **予測が外れる** → 驚きが生まれ、新しい言葉が誕生する
- **大きなイベント**（死、蘇生、交配）→ とても大きな驚き → 爆発的な言語進化

### Q: APIコストは増えますか？

**A:** いいえ。**一切増えません**。すべてローカルの計算です。

### Q: 難しい数式は必要ですか？

**A:** いいえ。このコードでは「驚きの大きさを数値で出して、行動を3段階で選ぶ」だけです。

---

**関連KB:** KB98, KB99, KB102, KB103, KB104, KB105, KB106, KB107, KB108
