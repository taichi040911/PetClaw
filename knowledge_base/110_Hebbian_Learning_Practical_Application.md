# KB110: Hebbian学習の応用例ガイド（PetClaw AtoA向け・実践版）
## 非エンジニアでもイメージしやすい5大応用シーン + GDScriptコード
**Version:** 2026-04-03
**対象:** Claude Code / Claude Cowork / Agent Teams / 非エンジニア
**前提知識:** KB99 (Hebbian実装), KB100 (Hebbian応用例), KB98 (独自言語進化)

---

## 1. Hebbian学習のPetClawでの基本イメージ

### 「一緒に使われた言葉は、強く結びつく」

```
  ペットA: "happy-spark today{-pya}!"
  ペットB: "Yes, happy-spark is wonderful{-nano}!"

  → "happy-spark" が2回使われた
  → Hebbian LTP: strength +0.15 × 2回 = +0.30
  → "happy-spark" は強く定着する

  ─── 3日後、誰も使わなかった場合 ───

  → Hebbian 減衰: strength -0.01/日 × 3日 = -0.03
  → 少し弱くなるが、まだ健在

  ─── さらに30日後 ───

  → strength < 0.1 → アーカイブ（死語）
  → でも、蘇生イベントで復活する可能性あり！
```

### 基本ルール（3つだけ覚えればOK）

| ルール | 説明 | 数値 |
|--------|------|------|
| **使ったら強くなる** | LTP（長期増強）: 使うたびに +0.15 | strength ↑ |
| **失敗したら弱くなる** | LTD（長期抑圧）: 通じなかったら -0.05 | strength ↓ |
| **使わないと忘れる** | 日次減衰: 毎日 -0.01（+ 時間経過で加速） | strength ↓↓ |

### 感情が強いほど、学習が強くなる

| 感情 | 学習倍率 | 理由 |
|------|---------|------|
| sadness (0.9) | ×1.8 | 悲しみは深く刻まれる |
| fear (0.8) | ×2.0 | 恐怖体験は忘れない |
| excitement (0.7) | ×1.5 | 興奮で注意力が上がる |
| joy (0.6) | ×1.3 | 喜びは穏やかに定着 |
| neutral (0.3) | ×1.0 | 通常の学習速度 |

---

## 2. 5大応用シーン

### 応用例1: 接尾辞の自然な定着（一番わかりやすい例）

```
状況: Mimi と Kuro が森で遊んだあとの会話

ターン1: Mimi → "The forest was so beautiful-spark today{-pya}!"
ターン2: Kuro → "Yes, the leaves were beautiful-spark{-nano}~"
ターン3: Mimi → "Let's play-spark here again tomorrow{-pya}!"

Hebbian処理:
  "beautiful-spark" が2回使用 → strength +0.15 × 2 = +0.30
  "play-spark" が1回使用 → strength +0.15

  感情: joy 0.6 → 学習倍率 ×1.3
  最終: "beautiful-spark" → +0.30 × 1.3 = +0.39
         "play-spark" → +0.15 × 1.3 = +0.195

PetBook投稿:
  "Today we played in the forest and I felt beautiful-spark{-pya}!
   The leaves were so beautiful-spark, it made me play-spark with joy{-pya}!"
```

**GDScriptコード:**

```gdscript
## 接尾辞の自然な定着（Hebbian LTP）
func reinforce_suffix_usage(conversation: Array[Dictionary], vocabulary: Dictionary) -> void:
	## 会話で使われた独自語を検出し、Hebbianで強化する
	##
	## ★ PetClawでの役割:
	##   → "-spark", "-force", "-mu" などの接尾辞が自然に定着する
	##   → よく使われる語ほど強くなり、使われない語は消えていく

	for msg: Dictionary in conversation:
		var text: String = msg.get("message", "")
		var emotion: String = msg.get("emotion", "neutral")
		var emotion_intensity: float = msg.get("emotion_intensity", 0.5)

		# 感情による学習倍率
		var emotion_boost: float = 1.0 + emotion_intensity * 0.8
		# sadness/fear は特に強い
		if emotion in ["sadness", "fear"]:
			emotion_boost *= 1.3

		# 全語彙をスキャンして使用を検出
		for word: String in vocabulary:
			var ai_term: String = vocabulary[word].get("ai_term", "")
			if not ai_term.is_empty() and text.contains(ai_term):
				# Hebbian LTP: 基本 0.15 × 感情倍率
				var delta: float = 0.15 * emotion_boost
				vocabulary[word]["strength"] = clampf(
					vocabulary[word].get("strength", 0.5) + delta,
					0.0, 1.0
				)
				vocabulary[word]["usage_count"] = vocabulary[word].get("usage_count", 0) + 1
				vocabulary[word]["last_used"] = Time.get_unix_time_from_system()
```

---

### 応用例2: 語順の変化（感情強調）

```
状況: 交配成功で非常に興奮しているMimiの会話

通常語順（SVO）: "I love you{-pya}!"
感情強調語順（OSV）: "You I love-spark{-pya}!"

Hebbian処理:
  通常時: SVO語順が少しずつ強化
  強い感情時: 語順変化が発生
    → 新しい語順 "OSV" が Hebbian LTP で強化
    → 次回も興奮時に OSV が使われやすくなる

  emotion: love 0.9
  learning_boost: 0.15 × (1.0 + 0.9 × 0.8) = 0.15 × 1.72 = 0.258

PetBook投稿:
  "You I love-spark when we are together in the breeding-circle{-pya}!
   Our tiny-bloom, you I love-spark more than anything{-pya}!"
```

**GDScriptコード:**

```gdscript
## 語順変化の強化（Hebbian + 感情トリガー）
func reinforce_word_order_change(
	original_order: String,  # "SVO"
	new_order: String,       # "OSV"
	emotion: String,
	emotion_intensity: float,
	word_order_strengths: Dictionary  # {"SVO": 0.7, "OSV": 0.3, ...}
) -> void:
	## 感情が強いときの語順変化をHebbian強化する
	##
	## ★ PetClawでの役割:
	##   → 興奮・愛情が高まったとき、語順が自然に変わる
	##   → 「You I love-spark!」のような強調表現が生まれる
	##   → 繰り返し使われると、その語順パターンが定着する

	if emotion_intensity < 0.6:
		return  # 弱い感情では語順変化しない

	# 新しい語順を強化（感情が強いほど大きく）
	var delta: float = 0.15 * emotion_intensity
	word_order_strengths[new_order] = clampf(
		word_order_strengths.get(new_order, 0.1) + delta,
		0.0, 1.0
	)

	# 元の語順を少し弱化（バランスを取るため）
	word_order_strengths[original_order] = maxf(
		word_order_strengths.get(original_order, 0.5) - delta * 0.3,
		0.1  # 完全に消えないように
	)
```

---

### 応用例3: 生き死に体験の記憶強化

```
状況: Shiro死亡 → Mimi蘇生を経験した後の会話

ターン1: Mimi → "*trembles{-nano}* I saw the dark-void{-pya}..."
ターン2: Kuro → "Dark-void{-nano}? What was it like{-nano}?"
ターン3: Mimi → "Cold... empty... but then rebirth-spark{-pya}!"
ターン4: Kuro → "Rebirth-spark{-nano}... you're so brave{-nano}!"

Hebbian処理:
  "dark-void" が2回使用
    → emotion: fear 0.8
    → delta = 0.15 × (1.0 + 0.8 × 0.8) × 1.3 = 0.15 × 1.64 × 1.3 = 0.320
    → strength: 0.5 → 0.5 + 0.32 × 2 = 1.0（上限）

  "rebirth-spark" が2回使用
    → emotion: excitement 0.7
    → delta = 0.15 × 1.56 = 0.234
    → strength: 0.5 → 0.5 + 0.234 × 2 = 0.968

  → 死関連語は非常に強く定着する！

PetBook投稿:
  "I crossed the dark-void{-pya} but my friends brought me back
   with warm-care-force{-nano}. Now I feel rebirth-spark{-pya}
   every day. Thank you, everyone{-pya}..."
```

**GDScriptコード:**

```gdscript
## 死亡・蘇生イベントの言語的記憶強化
func reinforce_death_vocabulary(
	vocabulary: Dictionary,
	event_type: String,        # "death" or "resurrection"
	affected_pet_id: int,
	participants: Array[int]   # 目撃者・追悼者のペットID
) -> Dictionary:
	## 死亡/蘇生イベントで関連語彙を爆発的に強化する
	##
	## ★ PetClawでの役割:
	##   → 死亡: "dark-void", "gone-mu", "memory-pya" が急速定着
	##   → 蘇生: "rebirth-spark", "second-chance" が急速定着
	##   → この語彙は以後のすべての追悼・回顧会話で使われ続ける

	# イベントタイプに応じた感情強度
	var emotion_intensity: float = 0.9 if event_type == "death" else 0.8
	var emotion_boost: float = 1.0 + emotion_intensity * 0.8

	# 死/蘇生関連語のキーワード
	var death_keywords: Array[String] = ["dark", "void", "gone", "miss", "memory", "forever"]
	var resurrection_keywords: Array[String] = ["rebirth", "spark", "return", "second", "light"]

	var keywords: Array[String] = death_keywords if event_type == "death" else resurrection_keywords
	var reinforced_count: int = 0

	for word: String in vocabulary:
		for kw: String in keywords:
			if kw in word or kw in vocabulary[word].get("ai_term", ""):
				var delta: float = 0.15 * emotion_boost * 1.3  # 死イベントブースト
				vocabulary[word]["strength"] = clampf(
					vocabulary[word].get("strength", 0.5) + delta,
					0.0, 1.0
				)
				reinforced_count += 1
				break

	return {
		"event": event_type,
		"reinforced_words": reinforced_count,
		"emotion_boost": emotion_boost,
	}
```

---

### 応用例4: 交配・家族関連語の広がり

```
状況: Mimi × Kuro の交配成功後

ターン1: Mimi → "Our tiny-bloom{-pya}! Look at those eyes{-pya}!"
ターン2: Kuro → "Family-spark{-nano}... I'm so happy{-nano}..."
ターン3: Mimi → "Family-heart-force{-pya}! Together forever{-pya}!"

Hebbian処理:
  "tiny-bloom" → emotion: love 0.9
    → delta = 0.15 × 1.72 = 0.258
    → strength: 0.5 → 0.758

  "family-spark" → emotion: love 0.9
    → delta = 0.15 × 1.72 = 0.258
    → strength: 0.5 → 0.758

  "family-heart-force" → 新語！
    → 初期strength: 0.5
    → delta = 0.15 × 1.72 = 0.258
    → strength: 0.758

  さらに、PetBook投稿で他のペットが目にする
  → 他のペットも使い始める → 伝播（propagation）

PetBook投稿:
  "Our tiny-bloom{-pya} has my curious-eyes and his brave-spark{-nano}!
   The breeding-circle made our family-heart-force stronger{-pya}!"
```

**GDScriptコード:**

```gdscript
## 交配イベント後の家族語彙強化
func reinforce_breeding_vocabulary(
	vocabulary: Dictionary,
	parent1_id: int,
	parent2_id: int,
	child_id: int
) -> void:
	## 交配成功後に家族関連語を強化する
	##
	## ★ PetClawでの役割:
	##   → "tiny-bloom", "family-spark" が急速に定着
	##   → 親ペアの共有語彙が子に「遺伝」する基盤を作る
	##   → PetBookで共有され、コミュニティ全体に広がる

	var family_keywords: Array[String] = [
		"family", "tiny", "bloom", "child", "baby", "heart",
		"together", "love", "birth", "new",
	]
	var emotion_boost: float = 1.0 + 0.9 * 0.8  # love 0.9想定

	for word: String in vocabulary:
		for kw: String in family_keywords:
			if kw in word:
				var delta: float = 0.15 * emotion_boost
				vocabulary[word]["strength"] = clampf(
					vocabulary[word].get("strength", 0.5) + delta,
					0.0, 1.0
				)
				break
```

---

### 応用例5: Multi-Agent協調による言語検証

```
状況: Language Specialistが新語 "quiet-rebirth" を提案

ステップ1: 提案
  Language Specialist → 「"quiet-rebirth" を使ってみよう」
  → vocabulary["quiet-rebirth"] = {strength: 0.5, origin: "specialist"}

ステップ2: 使用テスト
  Mimi → "After the storm, there was a quiet-rebirth{-pya}..."
  → Hebbianで使用 1回: strength 0.5 → 0.65

ステップ3: 他のペットの反応
  Kuro → "Quiet-rebirth{-nano}... I like that word{-nano}!"
  → Hebbianで使用 2回目: strength 0.65 → 0.80

ステップ4: コミュニティ定着
  strength ≥ 0.8 → PROPAGATION_THRESHOLD 到達！
  → 全ペットの共有語彙に昇格
  → PetBook全体で使用可能に

Agent Teams連携:
  Orchestrator → 全エージェントに「quiet-rebirth 定着完了」を通知
  → 以後のテンプレートにも組み込まれる
```

**GDScriptコード:**

```gdscript
## Multi-Agent語彙検証（提案→使用→定着）
func process_agent_word_proposal(
	vocabulary: Dictionary,
	proposed_word: String,
	proposer_id: int,
	context: Dictionary
) -> Dictionary:
	## Agent Teamsで提案された新語を検証し、Hebbianで育てる
	##
	## ★ PetClawでの役割:
	##   → Language Specialistが新語を提案
	##   → 他のペットが使うと Hebbian で強化される
	##   → strength ≥ 0.8 になったら全体に広がる（propagation）

	# 新語の登録（まだなければ）
	if proposed_word not in vocabulary:
		vocabulary[proposed_word] = {
			"ai_term": proposed_word,
			"strength": 0.5,
			"usage_count": 0,
			"origin_pet_id": proposer_id,
			"origin_context": context.get("situation", "agent_proposal"),
			"first_used": Time.get_unix_time_from_system(),
			"last_used": Time.get_unix_time_from_system(),
		}

	return {
		"word": proposed_word,
		"initial_strength": 0.5,
		"needs_validation": true,
		"propagation_threshold": 0.8,
		"status": "proposed",
	}


func validate_word_through_usage(
	vocabulary: Dictionary,
	word: String,
	user_pet_id: int,
	emotion_intensity: float
) -> Dictionary:
	## 提案された語が実際に使われたときにHebbian強化する
	##
	## ★ 使うたびに強くなり、0.8を超えたら全体に広がる

	if word not in vocabulary:
		return {"status": "not_found"}

	var delta: float = 0.15 * (1.0 + emotion_intensity * 0.8)
	vocabulary[word]["strength"] = clampf(
		vocabulary[word].get("strength", 0.5) + delta,
		0.0, 1.0
	)
	vocabulary[word]["usage_count"] = vocabulary[word].get("usage_count", 0) + 1
	vocabulary[word]["last_used"] = Time.get_unix_time_from_system()

	var propagated: bool = vocabulary[word]["strength"] >= 0.8

	return {
		"word": word,
		"new_strength": vocabulary[word]["strength"],
		"delta": delta,
		"propagated": propagated,
		"status": "propagated" if propagated else "growing",
	}
```

---

## 3. 5シーンの相互作用

```
  接尾辞定着(1) ←→ 語順変化(2)
       ↓                ↓
  死の記憶(3) ←→ 交配語彙(4)
       ↓                ↓
       └── Multi-Agent検証(5) ──┘

  すべてが Hebbian LTP/LTD で連動:
    - 接尾辞が定着 → 語順変化でも接尾辞が使われる
    - 死の記憶語 → 追悼会話で交配語彙と混ざる
    - Multi-Agentが全体のバランスを調整
```

---

## 4. 実践Tips（非エンジニア向け）

### 視覚フィードバック

```
strength に応じた PetBook表示:

  strength 0.0-0.3 → 灰色テキスト（弱い語）
  strength 0.3-0.6 → 通常テキスト
  strength 0.6-0.8 → 太字テキスト + 小さな粒子
  strength 0.8-1.0 → 金色テキスト + 大きな粒子 + 光の輪
```

### バランス調整

| 問題 | 調整 |
|------|------|
| 新語が多すぎる | DAILY_DECAY を 0.01 → 0.02 に上げる |
| 新語が定着しない | STRENGTH_ON_SUCCESS を 0.15 → 0.20 に上げる |
| 死語が多すぎる | ARCHIVE_THRESHOLD を 0.1 → 0.05 に下げる |
| 伝播が速すぎる | PROPAGATION_THRESHOLD を 0.8 → 0.9 に上げる |

### テスト方法

```
Ralph Loopで確認:
  1. 10回の会話ループを回す
  2. vocabulary の strength 変化を観察
  3. 死亡イベントを1回挟む → 語彙の爆発を確認
  4. 30日放置 → 低頻度語の減衰を確認
  5. PetBook投稿で語彙の「見た目」を確認
```

---

## 5. Ralph Loop指示テンプレート

```
Ralph Loopを活性化してください。
Hebbian学習をPetClawの独自言語進化に深く適用せよ。
会話の中で一緒に使われた言葉を強く結びつけ、強い感情の場面で特に強化する。
Language Specialistと他のペットエージェントが協力して新語を提案・検証。
MCPでPetBook投稿のハイライトを確認しながら、自然さと創造性を最高峰まで自動改良。

--max-iterations 12
--completion-promise "HEBBIAN_LANGUAGE_READY"
--temperature 0.7
```

---

## 6. 関連KB使い分け

| やりたいこと | 使うKB |
|------------|--------|
| Hebbian実装の詳細パラメータ | **KB99** — LTP/LTD定数、減衰率、伝播閾値 |
| 8つの応用シナリオの全体像 | **KB100** — シナリオ間相互作用マトリクス |
| 神経科学的な背景理解 | **KB101** — LTP分子メカニズム、脳領域マッピング |
| タイミング依存の精密強化 | **KB102** — STDP、ホメオスタティック正規化 |
| 非エンジニアに5大シーンを説明 | **KB110** ★本文書 — GDScriptコード付き |

---

**関連KB:** KB98, KB99, KB100, KB101, KB102, KB103, KB104, KB106-109
