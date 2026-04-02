## AchievementSystem — Pet milestone tracking and badge unlocking
## Standalone system: other systems call check_achievement() to trigger unlocks.
## Persistence via to_dict() / from_dict() embedded in GameManager save_data.
class_name AchievementSystem
extends Node

# === Signals ===
signal achievement_unlocked(achievement_id: String, title: String)

# === Constants ===
const CATEGORY_LANGUAGE: StringName = &"language"
const CATEGORY_SOCIAL: StringName = &"social"
const CATEGORY_BATTLE: StringName = &"battle"
const CATEGORY_CARE: StringName = &"care"

# === Achievement Data ===
var _achievements: Dictionary = {}  # achievement_id → Dictionary
var _unlock_count: int = 0
var _total_play_time: float = 0.0  # accumulated play time in seconds


func _ready() -> void:
	_define_achievements()


# === Achievement Definitions ===
func _define_achievements() -> void:
	# --- Language achievements ---
	_register("first_word", "First Word", "Invent the first word in pet language.",
		CATEGORY_LANGUAGE, "scroll")
	_register("polyglot", "Polyglot", "Build a vocabulary of 20+ words.",
		CATEGORY_LANGUAGE, "book_open")
	_register("linguist", "Linguist", "Reach language stage 3 (Creole).",
		CATEGORY_LANGUAGE, "feather")
	_register("cultural_speaker", "Cultural Speaker", "Reach language stage 5 (Cultural Language).",
		CATEGORY_LANGUAGE, "globe")
	_register("word_teacher", "Word Teacher", "Teach 5 words to other pets.",
		CATEGORY_LANGUAGE, "graduation_cap")

	# --- Social achievements ---
	_register("first_conversation", "First Chat", "Have the first AtoA conversation.",
		CATEGORY_SOCIAL, "speech_bubble")
	_register("chatterbox", "Chatterbox", "Complete 50 total conversations.",
		CATEGORY_SOCIAL, "megaphone")
	_register("best_friends", "Best Friends", "Reach close_friends relationship with any pet.",
		CATEGORY_SOCIAL, "heart")
	_register("rivalry", "Rivalry", "Reach rivals relationship with any pet.",
		CATEGORY_SOCIAL, "crossed_swords")
	_register("group_chat", "Group Chat", "Have a group conversation with 3+ pets.",
		CATEGORY_SOCIAL, "users")

	# --- Battle achievements ---
	_register("first_blood", "First Victory", "Win your first battle.",
		CATEGORY_BATTLE, "trophy_bronze")
	_register("champion", "Champion", "Win 10 battles.",
		CATEGORY_BATTLE, "trophy_gold")
	_register("underdog", "Underdog", "Win a battle with a smaller vocabulary.",
		CATEGORY_BATTLE, "lightning")
	_register("perfect_score", "Perfect Score", "Score 90+ in any battle.",
		CATEGORY_BATTLE, "star")
	_register("word_warrior", "Word Warrior", "Use 5+ unique words in one battle.",
		CATEGORY_BATTLE, "shield")

	# --- Care achievements ---
	_register("first_pet", "First Pet", "Hatch your first egg.",
		CATEGORY_CARE, "egg")
	_register("breeder", "Breeder", "Successfully breed pets.",
		CATEGORY_CARE, "dna")
	_register("elder", "Elder", "Raise a pet to Elder stage.",
		CATEGORY_CARE, "crown")
	_register("collector", "Collector", "Have 5+ pets alive simultaneously.",
		CATEGORY_CARE, "grid")
	_register("dedicated", "Dedicated", "Play for 24+ hours total.",
		CATEGORY_CARE, "clock")


func _register(id: String, title: String, description: String,
		category: StringName, icon: String) -> void:
	_achievements[id] = {
		"id": id,
		"title": title,
		"description": description,
		"category": category,
		"icon": icon,
		"unlocked": false,
		"unlock_time": 0.0,
	}


# === Core API ===

func check_achievement(id: String, context: Dictionary = {}) -> bool:
	## Check and unlock an achievement if conditions are met.
	## Returns true if newly unlocked, false if already unlocked or not found.
	if not _achievements.has(id):
		push_warning("[AchievementSystem] Unknown achievement: %s" % id)
		return false

	var achievement: Dictionary = _achievements[id]
	if achievement["unlocked"]:
		return false

	var should_unlock: bool = _evaluate_condition(id, context)
	if not should_unlock:
		return false

	achievement["unlocked"] = true
	achievement["unlock_time"] = _total_play_time
	_unlock_count += 1
	achievement_unlocked.emit(id, achievement["title"])
	print("[AchievementSystem] Unlocked: %s — %s" % [id, achievement["title"]])
	return true


func get_all_achievements() -> Array[Dictionary]:
	## Returns all achievements with their unlock status.
	var result: Array[Dictionary] = []
	for id in _achievements:
		result.append(_achievements[id].duplicate())
	return result


func get_achievement(id: String) -> Dictionary:
	## Returns a single achievement's data, or empty dict if not found.
	if _achievements.has(id):
		return _achievements[id].duplicate()
	return {}


func get_unlocked_achievements() -> Array[Dictionary]:
	## Returns only unlocked achievements.
	var result: Array[Dictionary] = []
	for id in _achievements:
		if _achievements[id]["unlocked"]:
			result.append(_achievements[id].duplicate())
	return result


func get_unlock_count() -> int:
	return _unlock_count


func get_total_count() -> int:
	return _achievements.size()


func is_unlocked(id: String) -> bool:
	if _achievements.has(id):
		return _achievements[id]["unlocked"]
	return false


func update_play_time(delta: float) -> void:
	## Called externally (e.g. from GameManager._process) to track total play time.
	_total_play_time += delta


# === Condition Evaluation ===

func _evaluate_condition(id: String, context: Dictionary) -> bool:
	## Evaluate unlock conditions for a specific achievement.
	## context provides relevant data from the calling system.
	match id:
		# --- Language ---
		"first_word":
			return true  # Caller triggers only when a word is invented
		"polyglot":
			var vocab_size: int = context.get("vocab_size", 0)
			return vocab_size >= 20
		"linguist":
			var stage: int = context.get("language_stage", 0)
			return stage >= 3
		"cultural_speaker":
			var stage: int = context.get("language_stage", 0)
			return stage >= 5
		"word_teacher":
			var words_taught: int = context.get("words_taught", 0)
			return words_taught >= 5

		# --- Social ---
		"first_conversation":
			return true  # Caller triggers on first conversation
		"chatterbox":
			var total_conversations: int = context.get("total_conversations", 0)
			return total_conversations >= 50
		"best_friends":
			var relationship: String = context.get("relationship", "")
			return relationship == "close_friends"
		"rivalry":
			var relationship: String = context.get("relationship", "")
			return relationship == "rivals"
		"group_chat":
			var participant_count: int = context.get("participant_count", 0)
			return participant_count >= 3

		# --- Battle ---
		"first_blood":
			return true  # Caller triggers on first win
		"champion":
			var total_wins: int = context.get("total_wins", 0)
			return total_wins >= 10
		"underdog":
			var winner_vocab: int = context.get("winner_vocab", 0)
			var loser_vocab: int = context.get("loser_vocab", 0)
			return winner_vocab < loser_vocab
		"perfect_score":
			var score: float = context.get("score", 0.0)
			return score >= 90.0
		"word_warrior":
			var unique_words: int = context.get("unique_words", 0)
			return unique_words >= 5

		# --- Care ---
		"first_pet":
			return true  # Caller triggers on first hatch
		"breeder":
			return true  # Caller triggers on successful breed
		"elder":
			var life_stage: String = context.get("life_stage", "")
			return life_stage == "elder"
		"collector":
			var alive_count: int = context.get("alive_count", 0)
			return alive_count >= 5
		"dedicated":
			return _total_play_time >= 86400.0  # 24 hours in seconds

	return false


# === Persistence ===

func to_dict() -> Dictionary:
	var unlocked_data: Dictionary = {}
	for id in _achievements:
		var ach: Dictionary = _achievements[id]
		if ach["unlocked"]:
			unlocked_data[id] = {
				"unlock_time": ach["unlock_time"],
			}

	return {
		"unlocked": unlocked_data,
		"total_play_time": _total_play_time,
	}


func from_dict(data: Dictionary) -> void:
	_total_play_time = data.get("total_play_time", 0.0)
	_unlock_count = 0

	var unlocked_data: Dictionary = data.get("unlocked", {})
	for id in unlocked_data:
		if _achievements.has(id):
			_achievements[id]["unlocked"] = true
			_achievements[id]["unlock_time"] = unlocked_data[id].get("unlock_time", 0.0)
			_unlock_count += 1
