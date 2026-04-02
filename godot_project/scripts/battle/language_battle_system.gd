## LanguageBattleSystem — ペット同士の言語バトル（完全テンプレート制、API呼び出しゼロ）
## 3ラウンド制のワードデュエル。語彙力・文法・創造性・感情表現を競う
class_name LanguageBattleSystem
extends Node

signal battle_started(pet1_id: int, pet2_id: int)
signal battle_round_complete(round: int, scores: Dictionary)
signal battle_ended(winner_id: int, final_scores: Dictionary)

# === Battle Constants ===
const TOTAL_ROUNDS: int = 3
const ROUND_DURATION: float = 5.0  # 1ラウンドの演出時間（秒）

const MAX_VOCABULARY_SCORE: float = 30.0
const MAX_GRAMMAR_SCORE: float = 25.0
const MAX_CREATIVITY_SCORE: float = 25.0
const MAX_EMOTION_SCORE: float = 20.0
const MAX_ROUND_SCORE: float = 100.0

# === Reward Constants ===
const WINNER_AFFINITY_BOOST: float = 0.1
const HEBBIAN_BOOST_PER_WORD: float = 0.05
const WINNER_PERSONALITY_BOOST: float = 0.02
const LOSER_DETERMINATION_BOOST: float = 0.15

# === Round Themes ===
enum RoundTheme { GREETING, ARGUMENT, STORYTELLING }

const ROUND_THEMES: Array[int] = [
	RoundTheme.GREETING,
	RoundTheme.ARGUMENT,
	RoundTheme.STORYTELLING,
]

const THEME_NAMES: Dictionary = {
	RoundTheme.GREETING: "greeting",
	RoundTheme.ARGUMENT: "argument",
	RoundTheme.STORYTELLING: "storytelling",
}

# === Battle Templates (3 themes x 12 patterns = 36) ===
# Placeholders: {word}, {suffix}, {emotion}, {name}
const BATTLE_TEMPLATES: Dictionary = {
	RoundTheme.GREETING: [
		# Original 4
		"{word} {word}{suffix}! I feel {emotion} to meet you{suffix}!",
		"Hello{suffix}! My heart says {word} and {word}{suffix}. {emotion} fills me{suffix}!",
		"{word}{suffix}... {word}{suffix}... the {emotion} of a new dawn{suffix}!",
		"With {emotion}{suffix}, I say {word}! {word} {word}{suffix} to all!",
		# Formal
		"Greetings{suffix}. I present {word} and {word}{suffix} with deepest {emotion}{suffix}.",
		# Casual
		"Hey{suffix}! {word} {word}{suffix}! Feeling so {emotion} right now{suffix}!",
		# Excited
		"{word}{suffix}! {word}{suffix}! {word}{suffix}! Oh the {emotion}{suffix}! Amazing{suffix}!",
		# Shy
		"Um{suffix}... {word}{suffix}... I think {word}{suffix}... my {emotion} is quiet{suffix}...",
		# Morning
		"Good morning{suffix}! {word} rises like {word}{suffix}. {emotion} greets the day{suffix}!",
		# Night
		"Under the stars{suffix}, {word} whispers {word}{suffix}. Gentle {emotion}{suffix}...",
		# Seasonal
		"The season brings {word}{suffix} and {word}{suffix}. Nature hums with {emotion}{suffix}!",
		# Group
		"Everyone{suffix}! Let us share {word} and {word}{suffix}! Together in {emotion}{suffix}!",
	],
	RoundTheme.ARGUMENT: [
		# Original 4
		"{word}{suffix}! You don't understand {word}{suffix}! I feel {emotion}{suffix}!",
		"No{suffix}! {word} means {word}{suffix}, not what you think{suffix}! Such {emotion}{suffix}!",
		"Listen{suffix}! {word} and {word}{suffix} prove my point{suffix}! Feel my {emotion}{suffix}!",
		"{word}{suffix}! {word}{suffix}! I won't back down{suffix}! {emotion} burns inside{suffix}!",
		# Philosophical
		"But what IS {word}{suffix}? Can {word}{suffix} truly exist without {emotion}{suffix}?",
		# Practical
		"Facts{suffix}! {word} works better than {word}{suffix}! That is {emotion} truth{suffix}!",
		# Emotional
		"You hurt my {word}{suffix}! How could {word}{suffix} betray such {emotion}{suffix}!",
		# Playful
		"Ha{suffix}! My {word} beats your {word}{suffix} any day{suffix}! Pure {emotion}{suffix}!",
		# Competitive
		"I challenge your {word}{suffix}! My {word}{suffix} is stronger{suffix}! Feel this {emotion}{suffix}!",
		# Nostalgic
		"Remember when {word}{suffix} meant something{suffix}? Now {word}{suffix}... only {emotion}{suffix} remains.",
		# Absurd
		"A {word}{suffix} told me that {word}{suffix} is secretly made of {emotion}{suffix}! Explain that{suffix}!",
		# Intense
		"{word}{suffix}! {word}{suffix}! Enough talk{suffix}! My {emotion}{suffix} will settle this now{suffix}!",
	],
	RoundTheme.STORYTELLING: [
		# Original 4
		"Once upon a {word}{suffix}, there was a {word}{suffix}... full of {emotion}{suffix}...",
		"In the land of {word}{suffix}, the {word} sang with {emotion}{suffix}. Beautiful{suffix}!",
		"{word}{suffix} traveled far to find {word}{suffix}. The journey was {emotion}{suffix}.",
		"They say {word} and {word}{suffix} danced under the moon{suffix}. Such {emotion}{suffix}!",
		# Mystery
		"Nobody knew where {word}{suffix} came from{suffix}. Only {word}{suffix} held the {emotion} secret{suffix}.",
		# Epic
		"The great {word}{suffix} rose against {word}{suffix}! A battle of pure {emotion}{suffix} shook the world{suffix}!",
		# Fable
		"Wise old {word}{suffix} taught young {word}{suffix} that {emotion}{suffix} is the greatest treasure{suffix}.",
		# Dream
		"In a dream{suffix}, {word} became {word}{suffix}... everything shimmered with {emotion}{suffix}...",
		# Comedy
		"So {word}{suffix} walked into {word}{suffix} and said{suffix}: where is the {emotion}{suffix}? Everyone laughed{suffix}!",
		# Tragedy
		"Alas{suffix}, {word}{suffix} was lost forever{suffix}. {word}{suffix} wept with endless {emotion}{suffix}.",
		# Origin
		"Long ago{suffix}, the first {word}{suffix} was born from {word}{suffix} and pure {emotion}{suffix}.",
		# Adventure
		"Beyond the horizon{suffix}, {word} and {word}{suffix} set sail{suffix}. {emotion}{suffix} guided their way{suffix}!",
	],
}

# === Suffix Pool (language flavor) ===
const SUFFIXES: Array[String] = [
	"-na", "-ri", "-ko", "-mu", "-ze",
	"-ba", "-lo", "-fi", "-gu", "-ta",
	"-shi", "-pe", "-wo", "-ni", "-de",
]

# === Emotion Labels ===
const EMOTION_LABELS: Array[String] = [
	"joy", "excitement", "love", "fear", "sadness",
]

# === State ===
var is_battle_active: bool = false
var current_round: int = 0
var round_timer: float = 0.0
var battle_pet1: PetEntity = null
var battle_pet2: PetEntity = null
var pet1_total_score: float = 0.0
var pet2_total_score: float = 0.0
var pet1_round_scores: Array[Dictionary] = []
var pet2_round_scores: Array[Dictionary] = []
var pet1_words_used: Array[String] = []
var pet2_words_used: Array[String] = []

# === Battle History (per pet_id) ===
var battle_history: Dictionary = {}  # pet_id → { total_battles, wins, losses, best_score }


func _process(delta: float) -> void:
	if not is_battle_active:
		return
	round_timer -= delta
	if round_timer <= 0.0 and current_round < TOTAL_ROUNDS:
		_execute_round()


# ============================
# Public API
# ============================

func start_battle(pet1: PetEntity, pet2: PetEntity) -> void:
	## バトルを開始する。3ラウンドのワードデュエル
	if is_battle_active:
		push_warning("LanguageBattleSystem: Battle already active, ignoring start_battle call")
		return
	if not pet1.is_alive or not pet2.is_alive:
		push_warning("LanguageBattleSystem: Cannot battle with dead pet")
		return

	battle_pet1 = pet1
	battle_pet2 = pet2
	pet1_total_score = 0.0
	pet2_total_score = 0.0
	pet1_round_scores.clear()
	pet2_round_scores.clear()
	pet1_words_used.clear()
	pet2_words_used.clear()
	current_round = 0
	is_battle_active = true
	round_timer = ROUND_DURATION

	_ensure_history(pet1.pet_id)
	_ensure_history(pet2.pet_id)

	battle_started.emit(pet1.pet_id, pet2.pet_id)


func get_battle_stats(pet_id: int) -> Dictionary:
	## ペットのバトル統計を返す
	if pet_id in battle_history:
		return battle_history[pet_id].duplicate()
	return {
		"total_battles": 0,
		"wins": 0,
		"losses": 0,
		"best_score": 0.0,
	}


# ============================
# Round Execution
# ============================

func _execute_round() -> void:
	var theme: int = ROUND_THEMES[current_round]
	var theme_name: String = THEME_NAMES[theme]

	# Generate responses for both pets
	var response1: String = _generate_response(battle_pet1, theme)
	var response2: String = _generate_response(battle_pet2, theme)

	# Score both responses
	var score1: Dictionary = _calculate_round_score(battle_pet1, response1)
	var score2: Dictionary = _calculate_round_score(battle_pet2, response2)

	pet1_total_score += score1["total"]
	pet2_total_score += score2["total"]
	pet1_round_scores.append(score1)
	pet2_round_scores.append(score2)

	# Track words used
	_track_words_used(battle_pet1, response1, pet1_words_used)
	_track_words_used(battle_pet2, response2, pet2_words_used)

	var round_scores: Dictionary = {
		"round": current_round + 1,
		"theme": theme_name,
		"pet1_id": battle_pet1.pet_id,
		"pet2_id": battle_pet2.pet_id,
		"pet1_response": response1,
		"pet2_response": response2,
		"pet1_score": score1,
		"pet2_score": score2,
	}

	current_round += 1
	battle_round_complete.emit(current_round, round_scores)

	if current_round >= TOTAL_ROUNDS:
		_end_battle()
	else:
		round_timer = ROUND_DURATION


func _end_battle() -> void:
	is_battle_active = false

	var winner_id: int = -1
	if pet1_total_score > pet2_total_score:
		winner_id = battle_pet1.pet_id
	elif pet2_total_score > pet1_total_score:
		winner_id = battle_pet2.pet_id
	else:
		# Tie: winner is the pet with higher creativity across rounds
		var p1_creativity: float = 0.0
		var p2_creativity: float = 0.0
		for s: Dictionary in pet1_round_scores:
			p1_creativity += s["creativity_score"]
		for s: Dictionary in pet2_round_scores:
			p2_creativity += s["creativity_score"]
		winner_id = battle_pet1.pet_id if p1_creativity >= p2_creativity else battle_pet2.pet_id

	var final_scores: Dictionary = {
		"pet1_id": battle_pet1.pet_id,
		"pet2_id": battle_pet2.pet_id,
		"pet1_total": pet1_total_score,
		"pet2_total": pet2_total_score,
		"pet1_rounds": pet1_round_scores.duplicate(true),
		"pet2_rounds": pet2_round_scores.duplicate(true),
		"winner_id": winner_id,
	}

	# Apply rewards
	_apply_rewards(winner_id, final_scores)

	# Update history
	_update_history(battle_pet1.pet_id, pet1_total_score, winner_id == battle_pet1.pet_id)
	_update_history(battle_pet2.pet_id, pet2_total_score, winner_id == battle_pet2.pet_id)

	battle_ended.emit(winner_id, final_scores)

	# Clean up references
	battle_pet1 = null
	battle_pet2 = null


# ============================
# Response Generation (Template-based, ZERO API cost)
# ============================

func _generate_response(pet: PetEntity, theme: int) -> String:
	## テンプレート + ペットの語彙で応答を生成
	var templates: Array = BATTLE_TEMPLATES[theme]
	var template_idx: int = randi() % templates.size()
	var template: String = templates[template_idx]

	var vocab: Dictionary = _get_pet_vocabulary(pet)
	var suffix: String = _pick_suffix_for_pet(pet)
	var emotion_label: String = _get_dominant_emotion_label(pet)

	# Fill placeholders
	var result: String = template
	# Replace each {word} occurrence individually (GDScript replace() replaces all)
	while result.contains("{word}"):
		var word: String = _pick_random_word(vocab)
		var pos: int = result.find("{word}")
		if pos == -1:
			break
		result = result.substr(0, pos) + word + result.substr(pos + 6)

	result = result.replace("{suffix}", suffix)
	result = result.replace("{emotion}", emotion_label)
	result = result.replace("{name}", pet.pet_name)

	return result


func _get_pet_vocabulary(pet: PetEntity) -> Dictionary:
	## OriginalLanguageEngine から語彙を取得
	if GameManager.instance and GameManager.instance.has_node("OriginalLanguageEngine"):
		var engine: OriginalLanguageEngine = GameManager.instance.get_node("OriginalLanguageEngine")
		var full_vocab: Dictionary = engine.get_full_vocabulary()
		if not full_vocab.is_empty():
			return full_vocab
	# Fallback: generate temporary battle words from syllables
	return _generate_fallback_vocabulary(pet)


func _generate_fallback_vocabulary(pet: PetEntity) -> Dictionary:
	## 語彙がまだない場合のフォールバック（音素プールから生成）
	var fallback: Dictionary = {}
	var syllables: Array[String] = OriginalLanguageEngine.SYLLABLES
	var word_count: int = 5 + (pet.pet_id % 5)  # ペットIDで若干変化

	for i: int in word_count:
		var syllable_count: int = randi_range(2, 3)
		var word: String = ""
		for j: int in syllable_count:
			var idx: int = (pet.pet_id * 7 + i * 13 + j * 3) % syllables.size()
			idx = (idx + randi() % 10) % syllables.size()
			word += syllables[idx]
		fallback["fallback_word_%d" % i] = {
			"ai_term": word,
			"strength": 0.5,
			"usage_count": 1,
		}

	return fallback


func _pick_random_word(vocab: Dictionary) -> String:
	## 語彙からランダムな独自語（ai_term）を1つ選ぶ
	if vocab.is_empty():
		return "???"
	var keys: Array = vocab.keys()
	var key: String = keys[randi() % keys.size()]
	var entry: Dictionary = vocab[key]
	return entry.get("ai_term", key)


func _pick_suffix_for_pet(pet: PetEntity) -> String:
	## ペットの性格に基づいて接尾辞を選ぶ
	# Personality hash でやや固定的な接尾辞を持たせる
	var personality_sum: float = 0.0
	for trait_val: float in pet.personality.values():
		personality_sum += trait_val
	var idx: int = int(personality_sum * 100.0) % SUFFIXES.size()
	return SUFFIXES[idx]


func _get_dominant_emotion_label(pet: PetEntity) -> String:
	## ペットの現在の最も強い感情を返す
	var best_emotion: String = "joy"
	var best_val: float = 0.0
	for emo: String in pet.emotions:
		if pet.emotions[emo] > best_val:
			best_val = pet.emotions[emo]
			best_emotion = emo
	if best_val < 0.1:
		return EMOTION_LABELS[randi() % EMOTION_LABELS.size()]
	return best_emotion


# ============================
# Scoring
# ============================

func _calculate_round_score(pet: PetEntity, response: String) -> Dictionary:
	## レスポンスのスコアを計算（語彙・文法・創造性・感情）
	var vocabulary_score: float = _score_vocabulary(pet, response)
	var grammar_score: float = _score_grammar(response)
	var creativity_score: float = _score_creativity(pet, response)
	var emotion_score: float = _score_emotion(pet, response)

	var total: float = vocabulary_score + grammar_score + creativity_score + emotion_score

	return {
		"vocabulary_score": vocabulary_score,
		"grammar_score": grammar_score,
		"creativity_score": creativity_score,
		"emotion_score": emotion_score,
		"total": total,
	}


func _score_vocabulary(pet: PetEntity, response: String) -> float:
	## 独自語の使用数でスコア（0-30点）
	var vocab: Dictionary = _get_pet_vocabulary(pet)
	if vocab.is_empty():
		return 5.0  # 最低保証

	var unique_words_found: int = 0
	for word: String in vocab:
		var ai_term: String = vocab[word].get("ai_term", "")
		if not ai_term.is_empty() and response.contains(ai_term):
			unique_words_found += 1

	# 基本スコア: 独自語1つあたり7.5点、最大30点
	var base: float = minf(float(unique_words_found) * 7.5, MAX_VOCABULARY_SCORE)

	# 語彙の強さボーナス: 強い語ほど加点
	var strength_bonus: float = 0.0
	for word: String in vocab:
		var entry: Dictionary = vocab[word]
		if response.contains(entry.get("ai_term", "")):
			strength_bonus += entry.get("strength", 0.5) * 2.0
	strength_bonus = minf(strength_bonus, 5.0)

	return minf(base + strength_bonus, MAX_VOCABULARY_SCORE)


func _score_grammar(response: String) -> float:
	## 接尾辞の正しい使用でスコア（0-25点）
	var suffix_count: int = 0
	for suffix: String in SUFFIXES:
		suffix_count += response.count(suffix)

	# 接尾辞使用: 適度な数が高得点（少なすぎても多すぎてもNG）
	var optimal_count: int = 3
	var diff: int = absi(suffix_count - optimal_count)

	if diff == 0:
		return MAX_GRAMMAR_SCORE
	elif diff <= 1:
		return MAX_GRAMMAR_SCORE * 0.85
	elif diff <= 2:
		return MAX_GRAMMAR_SCORE * 0.65
	else:
		return MAX_GRAMMAR_SCORE * 0.4


func _score_creativity(pet: PetEntity, response: String) -> float:
	## 創造性スコア（0-25点）: 語の組み合わせと応答の豊かさ
	var score: float = 0.0

	# 応答の長さ（短すぎると減点、長すぎても加点なし）
	var word_count: int = response.split(" ").size()
	if word_count >= 8:
		score += 10.0
	elif word_count >= 5:
		score += 7.0
	else:
		score += 4.0

	# 性格トレイトによるボーナス
	var curious: float = pet.personality.get("curious", 0.5)
	var playful: float = pet.personality.get("playful", 0.5)
	score += (curious + playful) * 5.0  # 最大10点

	# 語彙の多様性: ユニークな独自語の数
	var vocab: Dictionary = _get_pet_vocabulary(pet)
	var unique_in_response: int = 0
	for word: String in vocab:
		var ai_term: String = vocab[word].get("ai_term", "")
		if not ai_term.is_empty() and response.contains(ai_term):
			unique_in_response += 1
	if unique_in_response >= 3:
		score += 5.0
	elif unique_in_response >= 2:
		score += 3.0

	return minf(score, MAX_CREATIVITY_SCORE)


func _score_emotion(pet: PetEntity, response: String) -> float:
	## 感情表現スコア（0-20点）
	var score: float = 0.0

	# 現在の感情の強さ
	var max_emotion_intensity: float = 0.0
	for emo: String in pet.emotions:
		max_emotion_intensity = maxf(max_emotion_intensity, pet.emotions[emo])
	score += max_emotion_intensity * 10.0  # 最大10点

	# 感情ラベルが応答に含まれているか
	for label: String in EMOTION_LABELS:
		if response.contains(label):
			score += 3.0
			break

	# 感情的な性格トレイト（affectionateが高いほど加点）
	var affectionate: float = pet.personality.get("affectionate", 0.5)
	score += affectionate * 7.0  # 最大7点

	return minf(score, MAX_EMOTION_SCORE)


# ============================
# Word Tracking
# ============================

func _track_words_used(pet: PetEntity, response: String, words_list: Array[String]) -> void:
	var vocab: Dictionary = _get_pet_vocabulary(pet)
	for word: String in vocab:
		var ai_term: String = vocab[word].get("ai_term", "")
		if not ai_term.is_empty() and response.contains(ai_term):
			if ai_term not in words_list:
				words_list.append(ai_term)


# ============================
# Rewards
# ============================

func _apply_rewards(winner_id: int, final_scores: Dictionary) -> void:
	## バトル結果に基づいて報酬を付与
	var winner: PetEntity = null
	var loser: PetEntity = null

	if battle_pet1 and battle_pet1.pet_id == winner_id:
		winner = battle_pet1
		loser = battle_pet2
	elif battle_pet2 and battle_pet2.pet_id == winner_id:
		winner = battle_pet2
		loser = battle_pet1

	if not winner or not loser:
		push_warning("LanguageBattleSystem: Could not determine winner/loser for rewards")
		return

	# 1. Winner: affinity boost with opponent
	_boost_affinity(winner.pet_id, loser.pet_id, WINNER_AFFINITY_BOOST)

	# 2. Both: Hebbian strength boost for words used
	_boost_hebbian_strength(pet1_words_used)
	_boost_hebbian_strength(pet2_words_used)

	# 3. Winner: personality trait boost (dominant trait)
	var dominant_trait: String = _get_dominant_personality_trait(winner)
	winner.evolve_personality(dominant_trait, WINNER_PERSONALITY_BOOST)

	# 4. Loser: determination emotion boost
	loser.blend_emotion("excitement", LOSER_DETERMINATION_BOOST)

	# Add memories for both pets
	winner.add_memory({
		"type": "battle_won",
		"with": loser.pet_id,
		"score": final_scores.get("pet1_total", 0.0) if winner == battle_pet1 else final_scores.get("pet2_total", 0.0),
	})
	loser.add_memory({
		"type": "battle_lost",
		"with": winner.pet_id,
		"score": final_scores.get("pet2_total", 0.0) if loser == battle_pet2 else final_scores.get("pet1_total", 0.0),
	})


func _boost_affinity(pet1_id: int, pet2_id: int, amount: float) -> void:
	## AtoAConversationSystem の関係性にアフィニティを加算
	if not GameManager.instance:
		return
	if GameManager.instance.has_node("AtoAConversationSystem"):
		var a2a: AtoAConversationSystem = GameManager.instance.get_node("AtoAConversationSystem")
		var key: String = "%d_%d" % [mini(pet1_id, pet2_id), maxi(pet1_id, pet2_id)]
		if key in a2a.pet_relationships:
			a2a.pet_relationships[key]["affinity"] = minf(
				1.0,
				a2a.pet_relationships[key].get("affinity", 0.5) + amount
			)


func _boost_hebbian_strength(words_used: Array[String]) -> void:
	## 使用した語のHebbian強度をブースト
	if not GameManager.instance:
		return
	if GameManager.instance.has_node("OriginalLanguageEngine"):
		var engine: OriginalLanguageEngine = GameManager.instance.get_node("OriginalLanguageEngine")
		var vocab: Dictionary = engine.get_full_vocabulary()
		for human_word: String in vocab:
			var ai_term: String = vocab[human_word].get("ai_term", "")
			if ai_term in words_used:
				# Directly boost strength (smaller than normal STRENGTH_ON_SUCCESS)
				if human_word in engine.vocabulary:
					engine.vocabulary[human_word]["strength"] = minf(
						1.0,
						engine.vocabulary[human_word]["strength"] + HEBBIAN_BOOST_PER_WORD
					)


func _get_dominant_personality_trait(pet: PetEntity) -> String:
	## 最も高い性格トレイトを返す
	var best_trait: String = "curious"
	var best_val: float = 0.0
	for trait_name: String in pet.personality:
		if pet.personality[trait_name] > best_val:
			best_val = pet.personality[trait_name]
			best_trait = trait_name
	return best_trait


# ============================
# History Management
# ============================

func _ensure_history(pet_id: int) -> void:
	if pet_id not in battle_history:
		battle_history[pet_id] = {
			"total_battles": 0,
			"wins": 0,
			"losses": 0,
			"best_score": 0.0,
		}


func _update_history(pet_id: int, total_score: float, is_winner: bool) -> void:
	_ensure_history(pet_id)
	var entry: Dictionary = battle_history[pet_id]
	entry["total_battles"] += 1
	if is_winner:
		entry["wins"] += 1
	else:
		entry["losses"] += 1
	entry["best_score"] = maxf(entry["best_score"], total_score)


# ============================
# Serialization
# ============================

func to_dict() -> Dictionary:
	return {
		"battle_history": battle_history.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	battle_history = data.get("battle_history", {})
