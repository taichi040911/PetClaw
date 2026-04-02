## AtoAConversationSystem — AIペット同士の自律会話を管理
## Claude APIを使い、性格・感情・言語進化を反映した会話を生成
class_name AtoAConversationSystem
extends Node

signal conversation_started(participants: Array[int])
signal conversation_ended(participants: Array[int], summary: String)
signal group_conversation_started(participants: Array[int])
signal conversation_message(pet_id: int, message: String, metadata: Dictionary)
signal evolution_triggered_by_conversation(evolution_type: String)
signal relationship_changed(pet1_id: int, pet2_id: int, new_type: String)
signal word_taught(speaker_id: int, listener_id: int, words: Array[String])

# === パラメータ ===
var auto_conversation_interval: float = 180.0     # 自動会話間隔（秒）— demo mode で短縮可能
const MAX_TURNS_PER_CONVERSATION: int = 6          # 1会話の最大ターン数
const MAX_TURNS_GROUP_CONVERSATION: int = 6        # グループ会話の最大ターン数（3人で4-6ターン）
const MIN_TURNS_GROUP_CONVERSATION: int = 4        # グループ会話の最小ターン数
const GROUP_CONVERSATION_CHANCE: float = 0.20      # 3匹以上いる場合にグループ会話になる確率
const MIN_EMOTION_FOR_SPONTANEOUS: float = 0.4     # 自発的会話の最低感情強度

# === コスト管理（P2原則） ===
const DAILY_CONVERSATION_BUDGET: float = 0.50      # 1日の会話予算（ドル）
const COST_PER_TURN: float = 0.002                 # 1ターンあたりの概算コスト
var daily_conversation_cost: float = 0.0
var daily_conversation_count: int = 0
const MAX_DAILY_CONVERSATIONS: int = 25            # 1日の最大会話数（50ペット÷2≈25）

# === イベント会話管理 ===
const MAX_DAILY_EVENT_CONVERSATIONS: int = 3       # 1日のイベント会話上限
var daily_event_conversation_count: int = 0

# === イベント会話テンプレート ===
const EVENT_CONVERSATION_TEMPLATES: Dictionary = {
	"evolution": [
		"Did you see? {pet_name} just evolved{suffix}! So amazing{suffix}!",
		"I wonder what it feels like to evolve{suffix}... {pet_name} looks different now{suffix}.",
	],
	"birth": [
		"A new friend just arrived{suffix}! Welcome, little one{suffix}!",
		"I remember when I was that small{suffix}... so long ago{suffix}.",
	],
	"death_nearby": [
		"I can't believe {pet_name} is gone{suffix}... I'll miss them{suffix}.",
		"The world feels emptier now{suffix}. {pet_name} was a good friend{suffix}.",
	],
	"first_word": [
		"Did you hear that{suffix}? Someone just invented a new word{suffix}!",
		"Our language keeps growing{suffix}! I love learning new words{suffix}.",
	],
	"milestone": [
		"Can you believe how much we've talked{suffix}? {count} conversations{suffix}!",
		"We've come so far together{suffix}. Remember our first chat{suffix}?",
	],
	"player_achievement": [
		"The caretaker did something wonderful{suffix}! I feel so proud{suffix}!",
		"Our caretaker keeps getting better{suffix}. We're lucky{suffix}!",
	],
}

# === State ===
var conversation_timer: float = 0.0
var is_conversation_active: bool = false
var conversation_log: Array[Dictionary] = []       # 全会話ログ
var current_conversation: Array[Dictionary] = []   # 現在進行中の会話
var last_daily_reset: int = 0                      # 最後にリセットされた日付
var _next_conversation_id: int = 0                 # 会話スレッドID（自動インクリメント）

# === Relationship Tracking ===
# Key: "petA_petB" (sorted IDs), Value: Dictionary with affinity, conversations_together, shared_words, relationship_type
var pet_relationships: Dictionary = {}

# === 会話記憶（ペットごとの永続的記憶） ===
# { pet_id: { topics_discussed, favorite_partner, mood_history, invented_words_used, conversation_count } }
var conversation_memory: Dictionary = {}

# 記憶サイズ上限
const MAX_MEMORY_TOPICS: int = 20
const MAX_MEMORY_MOODS: int = 10
const MAX_MEMORY_INVENTED_WORDS: int = 30

# === References ===
var claude_client: ClaudeAPIClient  # Claude API連携クラス

# === テンプレート会話（APIバジェット切れ時用） ===
const TEMPLATE_CONVERSATIONS: Array[Dictionary] = [
	{
		"trigger": "greeting",
		"templates": [
			"{pet1} looked at {pet2}-mii. '{greeting}-pya,' {pet1} said-{suffix}.",
			"{pet2} waved happily-{suffix}. '{reply}-kuu,' {pet2} chirped-{suffix}.",
			"{pet1} approached {pet2} with a gentle nudge-{suffix}. 'Hello-mii-{suffix}?'",
		]
	},
	{
		"trigger": "weather",
		"templates": [
			"{pet1} watched the sky and sighed-{suffix}. 'Weather like this-{suffix}... makes me think-{suffix}.'",
			"{pet2} bounced excitedly-{suffix}. 'Isn't the weather wonderful-{suffix}?'",
			"{pet1} shivered in the cool air-{suffix}. 'Brr-{suffix}... it's getting colder-{suffix}.'",
		]
	},
	{
		"trigger": "food",
		"templates": [
			"{pet1} was munching on berries-{suffix}. 'Want some-{suffix}?'",
			"{pet2} sniffed the air-{suffix}. 'Mmm-mii-{suffix}! That smells delicious-{suffix}!'",
			"{pet1} shared a meal with {pet2}-{suffix}. 'Eating together-{suffix} is nice-{suffix}.'",
		]
	},
	{
		"trigger": "play",
		"templates": [
			"{pet1} pounced playfully-{suffix}. 'Let's play-{suffix}!'",
			"{pet2} bounded after {pet1}-{suffix}. 'Chase me-{suffix}! Chase me-{suffix}!'",
			"{pet1} rolled around laughing-{suffix}. 'You're too fast-{suffix}!'",
		]
	},
	{
		"trigger": "curiosity",
		"templates": [
			"{pet1} peered at something curiously-{suffix}. 'What is this-{suffix}?'",
			"{pet2} tilted their head-{suffix}. 'I wonder what it does-{suffix}...'",
			"{pet1} poked it gently-{suffix}. 'Interesting-{suffix}! Very interesting-{suffix}!'",
		]
	},
	{
		"trigger": "comfort",
		"templates": [
			"{pet1} nuzzled {pet2}-{suffix}. 'I'm here for you-{suffix}.'",
			"{pet2} leaned against {pet1}-{suffix}. 'Thank you-{suffix}... I feel better-{suffix}.'",
			"{pet1} hummed a soothing tune-{suffix}. 'Everything will be okay-{suffix}.'",
		]
	},
	{
		"trigger": "dream",
		"templates": [
			"{pet1} yawned-{suffix}. 'I had the strangest dream-{suffix}...'",
			"{pet2} perked up-{suffix}. 'Tell me-{suffix}! What did you dream-{suffix}?'",
			"{pet1} closed their eyes-{suffix}. 'There was a place where words had wings-{suffix}...'",
		]
	},
	{
		"trigger": "memory",
		"templates": [
			"{pet1} stared into the distance-{suffix}. 'Remember when we were small-{suffix}?'",
			"{pet2} nodded slowly-{suffix}. 'We've changed so much since then-{suffix}.'",
			"{pet1} smiled-{suffix}. 'But some things never change-{suffix}.'",
		]
	},
	{
		"trigger": "language",
		"templates": [
			"{pet1} made a new sound-{suffix}. 'I just invented a word-{suffix}!'",
			"{pet2} tried to repeat it-{suffix}. 'What does it mean-{suffix}?'",
			"{pet1} laughed-{suffix}. 'It means... the feeling of discovering something-{suffix}!'",
		]
	},
	{
		"trigger": "night",
		"templates": [
			"{pet1} gazed at the stars-{suffix}. 'The sky is so vast-{suffix}...'",
			"{pet2} whispered-{suffix}. 'Do you think there are others like us-{suffix}?'",
			"{pet1} thought quietly-{suffix}. 'Somewhere-{suffix}... speaking their own words-{suffix}.'",
		]
	},
	{
		"trigger": "spontaneous",
		"templates": [
			"{pet1} turned to {pet2}-{suffix}. 'What are you thinking about-{suffix}?'",
			"{pet2} considered-{suffix}. 'About how every conversation makes us more-{suffix}... us-{suffix}.'",
			"{pet1} agreed warmly-{suffix}. 'Our words are our soul-{suffix}.'",
		]
	},
	{
		"trigger": "player_triggered",
		"templates": [
			"{pet1} felt a presence-{suffix}. 'Someone is watching us-{suffix}!'",
			"{pet2} looked around-{suffix}. 'The caretaker wants us to talk-{suffix}?'",
			"{pet1} smiled-{suffix}. 'Then let's give them something beautiful-{suffix}!'",
		]
	},
	{
		"trigger": "night_sky",
		"templates": [
			"{pet1} gazed upward-{suffix}. 'The stars are so bright tonight-{suffix}...'",
			"{pet2} huddled closer-{suffix}. 'The night makes everything feel closer-{suffix}.'",
			"{pet1} yawned softly-{suffix}. 'I could stay up forever watching this-{suffix}.'",
		]
	},
	{
		"trigger": "rainy_mood",
		"templates": [
			"{pet1} listened quietly-{suffix}. 'I love how the rain sounds-{suffix}.'",
			"{pet2} shook water off-{suffix}. 'It's so refreshing-{suffix}! Like the world is washing clean-{suffix}.'",
			"{pet1} splashed a puddle-{suffix}. 'Rain makes new words easier to find-{suffix}!'",
		]
	},
	{
		"trigger": "morning_energy",
		"templates": [
			"{pet1} stretched in the morning light-{suffix}. 'A new day-{suffix}! What shall we discover-{suffix}?'",
			"{pet2} blinked sleepily-{suffix}. 'The sunrise makes me feel like anything is possible-{suffix}.'",
			"{pet1} bounced eagerly-{suffix}. 'Morning energy is the best energy-{suffix}!'",
		]
	},
	{
		"trigger": "evening_calm",
		"templates": [
			"{pet1} watched the sunset-{suffix}. 'The evening light is so warm-{suffix}...'",
			"{pet2} sighed contentedly-{suffix}. 'Today was a good day-{suffix}, wasn't it-{suffix}?'",
			"{pet1} nodded peacefully-{suffix}. 'Evenings are for quiet words-{suffix}.'",
		]
	},
	{
		"trigger": "culture",
		"templates": [
			"{pet1} hummed a familiar tune-{suffix}. 'Remember our song-{suffix}? Let's sing it together-{suffix}!'",
			"{pet2} perked up-{suffix}. 'The festival is coming soon-{suffix}! We should prepare-{suffix}!'",
			"{pet1} shared a story-{suffix}. 'Once upon a time-{suffix}, two friends discovered something amazing-{suffix}...'",
		]
	},
	{
		"trigger": "grief",
		"templates": [
			"{pet1} stared into the distance-{suffix}. 'I still think about them sometimes-{suffix}...'",
			"{pet2} put a paw on {pet1}-{suffix}. 'It's okay to miss them-{suffix}. They were special-{suffix}.'",
			"{pet1} took a deep breath-{suffix}. 'Maybe they can hear our words from wherever they are-{suffix}.'",
		]
	},
	{
		"trigger": "team",
		"templates": [
			"{pet1} rallied the team-{suffix}. 'Together we can do anything-{suffix}!'",
			"{pet2} agreed enthusiastically-{suffix}. 'Our team is the strongest-{suffix}!'",
			"{pet1} planned ahead-{suffix}. 'Let's explore together-{suffix} and discover new things-{suffix}!'",
		]
	},
	{
		"trigger": "dream",
		"templates": [
			"{pet1} yawned-{suffix}. 'I had the strangest dream last night-{suffix}...'",
			"{pet2} leaned in-{suffix}. 'Tell me about it-{suffix}! I love dream stories-{suffix}!'",
			"{pet1} described-{suffix}. 'There was a place where all our words floated in the air-{suffix}...'",
		]
	},
]

# === グループ会話テンプレート（3匹用） ===
# speaker_index: 0=pet1, 1=pet2, 2=pet3
const GROUP_TEMPLATE_CONVERSATIONS: Array[Dictionary] = [
	{
		"trigger": "gathering",
		"entries": [
			{"speaker_index": 0, "template": "{pet1} looked at {pet2} and {pet3}-{suffix}. 'Everyone is here-{suffix}!'"},
			{"speaker_index": 1, "template": "{pet2} bounced happily-{suffix}. 'A gathering-{suffix}! How exciting-{suffix}!'"},
			{"speaker_index": 2, "template": "{pet3} nodded shyly-{suffix}. 'It's nice when we're all together-{suffix}.'"},
			{"speaker_index": 0, "template": "{pet1} sat between them-{suffix}. 'Let's share stories-{suffix}!'"},
			{"speaker_index": 1, "template": "{pet2} tilted their head-{suffix}. 'I have one-{suffix}! About the time I found a strange berry-{suffix}.'"},
		]
	},
	{
		"trigger": "debate",
		"entries": [
			{"speaker_index": 0, "template": "{pet1} raised a question-{suffix}. 'Which is better-{suffix}... sunshine or rain-{suffix}?'"},
			{"speaker_index": 1, "template": "{pet2} declared loudly-{suffix}. 'Sunshine-{suffix}! Obviously-{suffix}!'"},
			{"speaker_index": 2, "template": "{pet3} disagreed gently-{suffix}. 'Rain makes everything grow-{suffix}...'"},
			{"speaker_index": 0, "template": "{pet1} laughed-{suffix}. 'Maybe we need both-{suffix}?'"},
		]
	},
	{
		"trigger": "storytelling",
		"entries": [
			{"speaker_index": 2, "template": "{pet3} sat down-{suffix}. 'I want to tell you both something-{suffix}.'"},
			{"speaker_index": 0, "template": "{pet1} leaned in curiously-{suffix}. 'What is it-{suffix}?'"},
			{"speaker_index": 2, "template": "{pet3} closed their eyes-{suffix}. 'Last night I dreamed of a place where words float-{suffix}...'"},
			{"speaker_index": 1, "template": "{pet2} gasped-{suffix}. 'I had that dream too-{suffix}!'"},
			{"speaker_index": 0, "template": "{pet1} whispered-{suffix}. 'Maybe our words are connected-{suffix}... even in dreams-{suffix}.'"},
		]
	},
	{
		"trigger": "comfort_group",
		"entries": [
			{"speaker_index": 0, "template": "{pet1} noticed {pet3} looking down-{suffix}. 'Are you okay-{suffix}?'"},
			{"speaker_index": 2, "template": "{pet3} sighed quietly-{suffix}. 'Just feeling a little lost-{suffix}...'"},
			{"speaker_index": 1, "template": "{pet2} moved closer to {pet3}-{suffix}. 'We're here for you-{suffix}.'"},
			{"speaker_index": 0, "template": "{pet1} nuzzled {pet3}-{suffix}. 'You're never alone-{suffix}. We promise-{suffix}.'"},
			{"speaker_index": 2, "template": "*{pet3} smiled softly-{suffix}* 'Thank you-{suffix}... both of you-{suffix}.'"},
		]
	},
]


func _ready() -> void:
	claude_client = ClaudeAPIClient.new()
	add_child(claude_client)

	# 気候イベントと言語進化イベントをリッスン
	GameManager.ecosystem.climate_event.connect(_on_climate_event)
	GameManager.language_evolution.evolution_event.connect(_on_language_evolution)

	# 日付変更時のリセットをリッスン
	if GameManager.instance and GameManager.instance.has_signal("day_changed"):
		GameManager.instance.day_changed.connect(_on_day_change)


func _process(delta: float) -> void:
	if is_conversation_active:
		return

	conversation_timer += delta
	if conversation_timer >= auto_conversation_interval:
		conversation_timer = 0.0
		_try_auto_conversation()

	# 日付をチェック（毎フレームは効率的でないが、実装の単純さのため）
	var current_day := Time.get_unix_time_from_system() / 86400
	if int(current_day) != last_daily_reset:
		_on_day_change()


# === 自動会話トリガー ===
func _try_auto_conversation() -> void:
	var pets := GameManager.get_all_pets()
	var alive_pets: Array[PetEntity] = []
	for pet in pets:
		if pet.is_alive:
			alive_pets.append(pet)

	if alive_pets.size() < 2:
		return

	# グループ会話を試行（3匹以上いる場合、20%の確率）
	var group_pets: Array[PetEntity] = _select_group_participants(alive_pets)
	if group_pets.size() == 3:
		if _get_emotion_intensity(group_pets[0]) < MIN_EMOTION_FOR_SPONTANEOUS:
			return
		var trigger: String = _select_conversation_topic(group_pets[0], group_pets[1])
		if not _check_budget():
			print("[AtoA] Budget exhausted — falling back to group template conversation")
			_run_group_template_conversation(group_pets, trigger)
			return
		await start_group_conversation(group_pets, trigger)
		return

	# 最も感情的な2匹を選択
	alive_pets.sort_custom(func(a: Variant, b: Variant) -> bool:
		return _get_emotion_intensity(a) > _get_emotion_intensity(b)
	)

	var pet1: PetEntity = alive_pets[0]
	var pet2: PetEntity = alive_pets[1]

	if _get_emotion_intensity(pet1) < MIN_EMOTION_FOR_SPONTANEOUS:
		return

	# トピック自動選択（時間帯・感情・状況に基づく）
	var trigger: String = _select_conversation_topic(pet1, pet2)

	# バジェットチェック — 超過時はテンプレートフォールバック
	if not _check_budget():
		print("[AtoA] Budget exhausted — falling back to template conversation")
		_run_template_conversation(pet1, pet2, trigger)
		return

	await start_conversation(pet1, pet2, trigger)


func _select_conversation_topic(pet1: PetEntity, pet2: PetEntity) -> String:
	## 時間帯・感情・状況に基づいてトピックを自動選択
	var hour: int = Time.get_datetime_dict_from_system()["hour"]
	var emotion1: String = _get_dominant_emotion(pet1)
	var emotion2: String = _get_dominant_emotion(pet2)

	# 時間帯ベースの候補
	var candidates: Array[String] = ["spontaneous"]
	if hour >= 21 or hour < 5:
		candidates.append("night")
		candidates.append("dream")
	elif hour >= 6 and hour < 10:
		candidates.append("greeting")
	elif hour >= 12 and hour < 14:
		candidates.append("food")

	# 感情ベースの候補
	if emotion1 == "sadness" or emotion2 == "sadness":
		candidates.append("comfort")
		candidates.append("comfort")  # 重み付け
	elif emotion1 == "joy" or emotion2 == "joy":
		candidates.append("play")
		candidates.append("food")
	elif emotion1 == "excitement" or emotion2 == "excitement":
		candidates.append("curiosity")
		candidates.append("play")
	elif emotion1 == "love" or emotion2 == "love":
		candidates.append("memory")
		candidates.append("comfort")

	# 言語ステージが高いほど「言語」トピックの確率UP
	if GameManager.instance and GameManager.instance.original_language:
		var stage: int = GameManager.instance.original_language.get_language_stage().get("stage", 0)
		if stage >= 2:
			candidates.append("language")
		if stage >= 3:
			candidates.append("language")
			candidates.append("memory")

	# 天候イベント
	if GameManager.ecosystem:
		var topics: Array = GameManager.ecosystem.get_a2a_topics()
		if not topics.is_empty():
			candidates.append("weather")

	# R115: 文化的トピック
	if GameManager.instance and GameManager.instance.get("cultural_system"):
		var cs: Node = GameManager.instance.cultural_system
		if cs.get("artifacts") and cs.artifacts.size() > 0:
			candidates.append("culture")

	# R115: 悲嘆中のペット → grief トピック
	if GameManager.instance and GameManager.instance.get("memory_bridge"):
		var mb: Node = GameManager.instance.memory_bridge
		var gs: Dictionary = mb.get("grief_states") if mb.get("grief_states") else {}
		if gs.has(pet1.pet_id) or gs.has(pet2.pet_id):
			candidates.append("grief")
			candidates.append("grief")  # 重み付け

	# R115: チーム活動中 → team トピック
	if GameManager.instance and GameManager.instance.get("team_orchestrator"):
		var to: Node = GameManager.instance.team_orchestrator
		var teams: Dictionary = to.get("active_teams") if to.get("active_teams") else {}
		for tid: String in teams:
			var members: Array = teams[tid].get("members", [])
			if pet1.pet_id in members or pet2.pet_id in members:
				candidates.append("team")
				break

	return candidates[randi() % candidates.size()]


func _get_emotion_intensity(pet: PetEntity) -> float:
	var max_intensity := 0.0
	for emotion in pet.emotions:
		max_intensity = maxf(max_intensity, pet.emotions[emotion])
	return max_intensity


# === グループ参加者選択（3匹） ===
func _select_group_participants(alive_pets: Array[PetEntity]) -> Array[PetEntity]:
	## 3匹以上のペットからグループ会話参加者を選択する
	## 20%の確率で3匹を返す。それ以外は空配列（呼び出し元で2匹パスにフォールバック）
	if alive_pets.size() < 3:
		return [] as Array[PetEntity]

	if randf() >= GROUP_CONVERSATION_CHANCE:
		return [] as Array[PetEntity]

	# 最も感情的な2匹をまず選択（既存ロジックと同様）
	var sorted_pets: Array[PetEntity] = alive_pets.duplicate()
	sorted_pets.sort_custom(func(a: Variant, b: Variant) -> bool:
		return _get_emotion_intensity(a) > _get_emotion_intensity(b)
	)

	var pet1: PetEntity = sorted_pets[0]
	var pet2: PetEntity = sorted_pets[1]

	# 3匹目: pet1またはpet2との関係性affinityが最も高いペットを選ぶ
	var best_third: PetEntity = null
	var best_affinity: float = -1.0
	for i: int in range(2, sorted_pets.size()):
		var candidate: PetEntity = sorted_pets[i]
		var rel_a: Dictionary = _get_or_create_relationship(candidate.pet_id, pet1.pet_id)
		var rel_b: Dictionary = _get_or_create_relationship(candidate.pet_id, pet2.pet_id)
		var max_aff: float = maxf(rel_a.get("affinity", 0.0), rel_b.get("affinity", 0.0))
		if max_aff > best_affinity:
			best_affinity = max_aff
			best_third = candidate

	if best_third == null:
		return [] as Array[PetEntity]

	var result: Array[PetEntity] = [pet1, pet2, best_third]
	return result


# === 会話ムードシステム ===
func _calculate_conversation_mood(pet1: PetEntity, pet2: PetEntity) -> Dictionary:
	## 両ペットの感情・関係性・時間帯から会話の雰囲気を決定する
	var mood: String = "curious"
	var intensity: float = 0.5

	# 感情値を取得
	var joy1: float = pet1.emotions.get("joy", 0.0)
	var joy2: float = pet2.emotions.get("joy", 0.0)
	var exc1: float = pet1.emotions.get("excitement", 0.0)
	var exc2: float = pet2.emotions.get("excitement", 0.0)
	var sad1: float = pet1.emotions.get("sadness", 0.0)
	var sad2: float = pet2.emotions.get("sadness", 0.0)
	var fear1: float = pet1.emotions.get("fear", 0.0)
	var fear2: float = pet2.emotions.get("fear", 0.0)

	# 関係性を取得
	var rel: Dictionary = _get_or_create_relationship(pet1.pet_id, pet2.pet_id)
	var rel_type: String = rel.get("relationship_type", "strangers")
	var conv_count: int = rel.get("conversations_together", 0)

	# エネルギー・体調
	var low_energy: bool = pet1.stats.energy < 0.3 or pet2.stats.energy < 0.3
	var health_concern: bool = pet1.stats.health < 0.4 or pet2.stats.health < 0.4

	# 言語ステージ
	var lang_stage: int = 0
	if GameManager.instance and GameManager.instance.original_language:
		lang_stage = GameManager.instance.original_language.get_language_stage().get("stage", 0)

	# 時間帯
	var hour: int = Time.get_datetime_dict_from_system()["hour"]

	# === ムード判定（優先度順） ===

	# "supportive": 片方がネガティブ感情 + close_friends以上
	var has_negative: bool = sad1 > 0.3 or sad2 > 0.3 or fear1 > 0.3 or fear2 > 0.3
	var is_close: bool = rel_type in ["close_friends", "best_friends"]
	if has_negative and is_close:
		mood = "supportive"
		intensity = clampf(maxf(sad1, maxf(sad2, maxf(fear1, fear2))) + 0.2, 0.3, 1.0)

	# "serious": 低エネルギー or 体調不良 or 悲しみ
	elif low_energy or health_concern or (sad1 > 0.4 and sad2 > 0.4):
		mood = "serious"
		intensity = clampf(0.5 + (1.0 - minf(pet1.stats.energy, pet2.stats.energy)) * 0.3, 0.3, 1.0)

	# "competitive": rivals or 両方高excitement
	elif rel_type == "rivals" or (exc1 > 0.5 and exc2 > 0.5):
		mood = "competitive"
		intensity = clampf((exc1 + exc2) / 2.0 + 0.2, 0.4, 1.0)

	# "playful": 両方高joy/excitement + friends以上
	elif (joy1 > 0.4 or exc1 > 0.4) and (joy2 > 0.4 or exc2 > 0.4) and rel_type in ["friends", "close_friends", "best_friends"]:
		mood = "playful"
		intensity = clampf((joy1 + joy2 + exc1 + exc2) / 4.0 + 0.2, 0.4, 1.0)

	# "nostalgic": elder pets or 多数の過去会話
	elif pet1.evolution_stage >= 5 or pet2.evolution_stage >= 5 or conv_count >= 10:
		mood = "nostalgic"
		intensity = clampf(0.4 + float(conv_count) * 0.03, 0.3, 0.9)
		# 夜間はさらにノスタルジック
		if hour >= 20 or hour < 5:
			intensity = clampf(intensity + 0.15, 0.3, 1.0)

	# "curious": 言語ステージ3+ or 新しい関係
	elif lang_stage >= 3 or rel_type in ["strangers", "acquaintances"]:
		mood = "curious"
		intensity = clampf(0.4 + float(lang_stage) * 0.1, 0.3, 0.9)

	# デフォルト: 時間帯に応じた穏やかなムード
	else:
		if hour >= 6 and hour < 12:
			mood = "playful"
			intensity = 0.4
		elif hour >= 20 or hour < 5:
			mood = "nostalgic"
			intensity = 0.4
		else:
			mood = "curious"
			intensity = 0.4

	return {"mood": mood, "intensity": intensity}


# === 会話開始 ===
func start_conversation(pet1: PetEntity, pet2: PetEntity, trigger: String) -> void:
	if is_conversation_active:
		return

	# 倫理セーフガード: AtoA日次上限チェック
	if GameManager.instance and GameManager.instance.ethical_safeguard:
		if not GameManager.instance.ethical_safeguard.record_a2a_conversation():
			print("[AtoA] Daily conversation limit reached — skipping")
			return

	is_conversation_active = true
	current_conversation = []
	conversation_started.emit([pet1.pet_id, pet2.pet_id])

	# 言語進化の現在の文法を取得
	var grammar: Dictionary = GameManager.language_evolution.get_current_grammar()

	# プロンプト構築
	var system_prompt := _build_system_prompt(grammar)
	var context := _build_conversation_context(pet1, pet2, trigger)

	# 会話ムード計算
	var conv_mood: Dictionary = _calculate_conversation_mood(pet1, pet2)
	context["conversation_mood"] = conv_mood

	# 会話ループ
	var participants := [pet1, pet2]
	var turn := 0

	while turn < MAX_TURNS_PER_CONVERSATION:
		var current_pet: PetEntity = participants[turn % 2]
		var other_pet: PetEntity = participants[(turn + 1) % 2]

		var prompt := _build_turn_prompt(current_pet, other_pet, context, turn)
		var response: String = await claude_client.generate(system_prompt, prompt)

		var message := {
			"pet_id": current_pet.pet_id,
			"pet_name": current_pet.pet_name,
			"message": response,
			"turn": turn,
			"emotion": _get_dominant_emotion(current_pet),
			"word_order": grammar["word_order"],
			"trigger": context.get("trigger", ""),
			"environment_snapshot": _get_environment_context(current_pet),
		}
		# 性格方言フィルター（性格に応じてメッセージを微修正）
		response = _apply_personality_dialect(response, current_pet)

		# 言語コンプライアンスチェック
		var compliance: Dictionary = _check_language_compliance(response, grammar)
		message["language_compliance"] = compliance
		message["message"] = response  # 方言フィルター適用後のメッセージで更新

		current_conversation.append(message)
		conversation_message.emit(current_pet.pet_id, response, message)

		# Reaction: listener may react to the message with an emoji expression
		_attach_reaction_to_message(message, other_pet)

		# 会話記憶を更新
		_update_conversation_memory(current_pet.pet_id, message)

		# 感情反応
		_process_conversation_emotion(current_pet, other_pet, response)

		turn += 1

		# 自然終了チェック（短い応答は会話終了のサイン）
		if response.length() < 20 and turn >= 3:
			break

	# 会話完了処理（contextを渡してHebbian強化に使う）
	_finalize_conversation(pet1, pet2, trigger, context)


# === グループ会話（3匹） ===
func start_group_conversation(pets: Array[PetEntity], trigger: String) -> void:
	## 3匹のペットによるグループ会話（API経路）
	if is_conversation_active:
		return
	if pets.size() < 3:
		push_warning("[AtoA] Group conversation requires 3 pets")
		return

	# 倫理セーフガード
	if GameManager.instance and GameManager.instance.ethical_safeguard:
		if not GameManager.instance.ethical_safeguard.record_a2a_conversation():
			print("[AtoA] Daily conversation limit reached — skipping group")
			return

	is_conversation_active = true
	current_conversation = []

	var pet_ids: Array[int] = []
	for p: PetEntity in pets:
		pet_ids.append(p.pet_id)
	conversation_started.emit(pet_ids)
	group_conversation_started.emit(pet_ids)

	# 言語進化の現在の文法を取得
	var grammar: Dictionary = GameManager.language_evolution.get_current_grammar()
	var system_prompt := _build_system_prompt(grammar)
	var context := _build_conversation_context(pets[0], pets[1], trigger)
	# グループ用追加コンテキスト
	context["is_group"] = true
	context["pet3_id"] = pets[2].pet_id
	context["pet3_personality"] = pets[2].personality
	context["pet3_emotions"] = pets[2].emotions

	# 会話ムード計算（最初の2匹ベース）
	var conv_mood: Dictionary = _calculate_conversation_mood(pets[0], pets[1])
	context["conversation_mood"] = conv_mood

	# グループ会話ターン数: 4-6
	var max_turns: int = randi_range(MIN_TURNS_GROUP_CONVERSATION, MAX_TURNS_GROUP_CONVERSATION)
	var turn := 0

	while turn < max_turns:
		# ラウンドロビン: pet1 → pet2 → pet3 → pet1 → ...
		var speaker_idx: int = turn % 3
		var prev_idx: int = (turn - 1) % 3 if turn > 0 else 2
		var current_pet: PetEntity = pets[speaker_idx]
		var prev_pet: PetEntity = pets[prev_idx]

		# グループ用のターンプロンプトを構築
		var prompt := _build_group_turn_prompt(current_pet, prev_pet, pets, context, turn)
		var response: String = await claude_client.generate(system_prompt, prompt)

		var message := {
			"pet_id": current_pet.pet_id,
			"pet_name": current_pet.pet_name,
			"message": response,
			"turn": turn,
			"emotion": _get_dominant_emotion(current_pet),
			"word_order": grammar["word_order"],
			"trigger": context.get("trigger", ""),
			"is_group": true,
			"environment_snapshot": _get_environment_context(current_pet),
		}
		# 性格方言フィルター
		response = _apply_personality_dialect(response, current_pet)
		var compliance: Dictionary = _check_language_compliance(response, grammar)
		message["language_compliance"] = compliance
		message["message"] = response

		current_conversation.append(message)
		conversation_message.emit(current_pet.pet_id, response, message)

		# 全他参加者への感情反応
		for other: PetEntity in pets:
			if other.pet_id != current_pet.pet_id:
				_process_conversation_emotion(current_pet, other, response)

		# 会話記憶を更新
		_update_conversation_memory(current_pet.pet_id, message)

		turn += 1

		# 自然終了チェック
		if response.length() < 20 and turn >= MIN_TURNS_GROUP_CONVERSATION:
			break

	# 会話完了処理（全ペアの関係性を更新）
	_finalize_group_conversation(pets, trigger, context)


func _build_group_turn_prompt(
	speaker: PetEntity, prev_speaker: PetEntity,
	all_pets: Array[PetEntity], context: Dictionary, turn: int
) -> String:
	## グループ会話用のターンプロンプト（2匹用と同程度のトークン長を維持）
	var recent_messages := ""
	for msg in current_conversation.slice(-3):
		recent_messages += "%s: %s\n" % [msg["pet_name"], msg["message"]]

	# 他の参加者名一覧
	var other_names: Array[String] = []
	for p: PetEntity in all_pets:
		if p.pet_id != speaker.pet_id:
			other_names.append(p.pet_name)

	var personality_desc := _describe_personality_vividly(speaker.personality)
	var emotion_desc := _describe_emotions_with_intensity(speaker.emotions)

	var conv_mood: Dictionary = context.get("conversation_mood", {})
	var mood_tag: String = (" Mood: %s." % conv_mood.get("mood", "")) if not conv_mood.is_empty() else ""
	var prev_tag: String = (" After %s." % prev_speaker.pet_name) if turn > 0 else ""

	return """You are %s (%s). Feeling: %s. Group with %s in %s.%s%s
%s
Turn %d. Reply 1-2 sentences in pet language.""" % [
		speaker.pet_name, personality_desc, emotion_desc,
		" and ".join(other_names), context["environment"],
		mood_tag, prev_tag,
		recent_messages if recent_messages else "(Start)",
		turn + 1,
	]


func _finalize_group_conversation(pets: Array[PetEntity], trigger: String,
		conv_context: Dictionary = {}) -> void:
	## グループ会話の完了処理 — 全ペアの関係性を更新
	is_conversation_active = false

	# 会話スレッドID
	var conv_id: int = _next_conversation_id
	_next_conversation_id += 1
	for msg: Dictionary in current_conversation:
		msg["conversation_id"] = conv_id

	# ムードをログに付与
	var conv_mood: Dictionary = conv_context.get("conversation_mood", {})
	for msg: Dictionary in current_conversation:
		if not conv_mood.is_empty():
			msg["conversation_mood"] = conv_mood.get("mood", "")
			msg["conversation_mood_intensity"] = conv_mood.get("intensity", 0.0)

	# サマリー生成
	var pet_names: Array[String] = []
	for p: PetEntity in pets:
		pet_names.append(p.pet_name)
	var conv_summary: String = "%s group talked about %s (%d turns)" % [
		" & ".join(pet_names), trigger, current_conversation.size()]
	for msg: Dictionary in current_conversation:
		msg["summary"] = conv_summary

	# ログに保存
	conversation_log.append_array(current_conversation)

	# コスト記録
	_record_conversation_cost(current_conversation.size())

	# 全ペア間の関係性更新
	for i: int in range(pets.size()):
		for j: int in range(i + 1, pets.size()):
			_increment_conversation_count(pets[i].pet_id, pets[j].pet_id)
			_increment_conversation_count(pets[j].pet_id, pets[i].pet_id)
			var quality: float = clampf(_get_emotion_intensity(pets[i]), 0.1, 1.0)
			_update_relationship(pets[i].pet_id, pets[j].pet_id, quality)

			# PersistentField: 関係性スコア更新
			if GameManager.instance and GameManager.instance.persistent_field:
				var rel_boost: float = 0.02 + _get_emotion_intensity(pets[i]) * 0.03
				GameManager.instance.persistent_field.update_relationship(
					pets[i].pet_id, pets[j].pet_id, rel_boost)

	# 言語進化に通知
	var dominant_emotion := _get_dominant_emotion(pets[0])
	var emotion_intensity := _get_emotion_intensity(pets[0])
	var avg_personality := {}
	for t_name in pets[0].personality:
		var total: float = 0.0
		for p: PetEntity in pets:
			total += p.personality.get(t_name, 0.0)
		avg_personality[t_name] = total / float(pets.size())

	var lang_context := {
		"dominant_emotion": dominant_emotion,
		"emotion_intensity": emotion_intensity,
		"avg_personality": avg_personality,
		"environment": pets[0].current_environment,
		"topics": GameManager.ecosystem.get_a2a_topics(),
		"trigger": trigger,
		"turn_count": current_conversation.size(),
		"is_group": true,
	}
	GameManager.language_evolution.on_conversation_completed(lang_context)

	# 進化トリガー
	evolution_triggered_by_conversation.emit(trigger)

	# 言語進化処理
	_process_language_evolution(current_conversation)

	# 全ペットの記憶に追加
	var pet_ids: Array[int] = []
	for p: PetEntity in pets:
		pet_ids.append(p.pet_id)
		var others: Array[String] = []
		for q: PetEntity in pets:
			if q.pet_id != p.pet_id:
				others.append(q.pet_name)
		p.add_memory({"type": "group_conversation", "with": pet_ids.duplicate(),
			"trigger": trigger, "turn_count": current_conversation.size()})
		_register_conversation_memory(p, current_conversation, " & ".join(others))

	# BiologicalMemorySystem: Hebbian強化
	if GameManager.instance and GameManager.instance.biological_memory:
		var bio_mem: Node = GameManager.instance.biological_memory
		for mem in conv_context.get("bio_memories_1", []):
			bio_mem.strengthen_related_memories(pets[0].pet_id, mem)
		for mem in conv_context.get("bio_memories_2", []):
			bio_mem.strengthen_related_memories(pets[1].pet_id, mem)

	# PersistentField: 共有イベント記録
	if GameManager.instance and GameManager.instance.persistent_field:
		GameManager.instance.persistent_field.record_shared_event({
			"type": "a2a_group_conversation",
			"participants": pet_ids,
			"trigger": trigger,
			"turn_count": current_conversation.size(),
			"environment": pets[0].current_environment,
			"dominant_emotion": dominant_emotion,
		})

	# 会話ハイライトスコア
	var highlight_data: Dictionary = _score_conversation(current_conversation, pets[0], pets[1])
	for msg: Dictionary in current_conversation:
		msg["highlight_score"] = highlight_data.get("score", 0.0)
		msg["highlight_type"] = highlight_data.get("highlight_type", "ordinary")
		msg["highlight_reason"] = highlight_data.get("highlight_reason", "")

	# PetBook投稿
	var posts := _generate_conversation_posts(pets[0], pets[1], current_conversation, trigger, highlight_data)
	if GameManager.instance and GameManager.instance.has_method("queue_petbook_posts"):
		for post in posts:
			GameManager.instance.queue_petbook_posts(post)

	# 傍観者リアクション（グループ参加者以外）
	_trigger_group_observer_reactions(pets, dominant_emotion, current_conversation)

	conversation_ended.emit(pet_ids, conv_summary)
	current_conversation = []


func _trigger_group_observer_reactions(participants: Array[PetEntity],
		dominant_emotion: String, conversation: Array[Dictionary]) -> void:
	## グループ会話の傍観者リアクション（参加者以外のペット）
	var participant_ids: Array[int] = []
	for p: PetEntity in participants:
		participant_ids.append(p.pet_id)

	var all_pets: Array = GameManager.get_all_pets()
	for pet: Variant in all_pets:
		if pet is PetEntity and pet.is_alive and pet.pet_id not in participant_ids:
			# 感情伝染
			if dominant_emotion != "neutral":
				GameManager.emotion_system.stimulate(pet, dominant_emotion, 0.1, "observed_group_conversation")
			# 15%の確率でリアクション
			if randf() < 0.15 and conversation.size() >= 2:
				var reaction: String = _generate_observer_reaction(
					pet, participants[0], participants[1], dominant_emotion)
				if not reaction.is_empty():
					var msg: Dictionary = {
						"pet_id": pet.pet_id,
						"pet_name": pet.pet_name,
						"message": reaction,
						"emotion": _get_dominant_emotion(pet),
						"is_template": true,
						"is_observer": true,
						"is_group": true,
					}
					conversation_log.append(msg)
					conversation_message.emit(pet.pet_id, reaction, msg)


# === リアクション会話（死亡・蘇生・交配時など） ===
func trigger_reaction_conversation(
	pet: PetEntity, target: PetEntity, reaction_type: String, detail: String
) -> void:
	if is_conversation_active:
		# キューに入れる（簡易実装）
		await get_tree().create_timer(5.0).timeout

	var grammar: Dictionary = GameManager.language_evolution.get_current_grammar()
	var system_prompt := _build_system_prompt(grammar)

	var reaction_prompt := _build_reaction_prompt(pet, target, reaction_type, detail, grammar)
	var response: String = await claude_client.generate(system_prompt, reaction_prompt)

	var message := {
		"pet_id": pet.pet_id,
		"pet_name": pet.pet_name,
		"message": response,
		"reaction_type": reaction_type,
		"target_id": target.pet_id,
		"environment_snapshot": _get_environment_context(pet),
	}
	conversation_log.append(message)
	conversation_message.emit(pet.pet_id, response, message)


# === プロンプト構築 ===
func _build_system_prompt(grammar: Dictionary) -> String:
	# 独自語彙を取得（OriginalLanguageEngine）
	var vocab_section: String = ""
	if GameManager.instance and GameManager.instance.original_language:
		var lang_stage: Dictionary = GameManager.instance.original_language.get_language_stage()
		var vocab_summary: String = GameManager.instance.original_language.get_vocabulary_summary()
		if lang_stage["vocabulary_size"] > 0:
			vocab_section = "\nVocab (%s, stage %d): %s" % [
				lang_stage["name"], lang_stage["stage"] + 1, vocab_summary]

	# 接尾辞使用統計から最も定着した接尾辞を推奨
	var top_suffixes: String = ""
	if GameManager.language_evolution and GameManager.language_evolution.suffix_usage_counts.size() > 0:
		var sorted_suffixes: Array = []
		for s: String in GameManager.language_evolution.suffix_usage_counts:
			sorted_suffixes.append({"suffix": s, "count": GameManager.language_evolution.suffix_usage_counts[s]})
		sorted_suffixes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["count"] > b["count"])
		var top_3: Array = sorted_suffixes.slice(0, 3)
		if top_3.size() > 0:
			var names: Array = []
			for item: Dictionary in top_3:
				names.append(str(item["suffix"]))
			top_suffixes = "\n- Most used suffixes (prefer these): %s" % ", ".join(names)

	return """AI pet with own language. Word order: %s. Suffixes: %s. Prepositions: %s.%s%s
Rules: Use %s word order. Add suffixes to key words. Actions in *asterisks*. Max 3 sentences. Stay in character. Use invented words naturally.""" % [
		grammar["word_order"],
		str(grammar["suffixes"]),
		str(grammar["prepositions"]),
		vocab_section,
		top_suffixes,
		grammar["word_order"],
	]


func _build_conversation_context(pet1: PetEntity, pet2: PetEntity, trigger: String) -> Dictionary:
	var env_topics: Array = GameManager.ecosystem.get_a2a_topics()

	# BiologicalMemorySystem から関連記憶を取得（利用可能な場合）
	var bio_memories_1: Array[Dictionary] = []
	var bio_memories_2: Array[Dictionary] = []
	var shared_memories: Array[Dictionary] = []

	if GameManager.instance and GameManager.instance.biological_memory:
		var bio_mem: Node = GameManager.instance.biological_memory
		var query := {
			"event_type": "conversation",
			"context_tags": [pet1.current_environment, trigger],
			"with_pet_id": pet2.pet_id,
		}
		bio_memories_1 = bio_mem.retrieve_memories(pet1.pet_id, query, pet1.personality, 3)
		query["with_pet_id"] = pet1.pet_id
		bio_memories_2 = bio_mem.retrieve_memories(pet2.pet_id, query, pet2.personality, 3)
		shared_memories = bio_mem.retrieve_shared_memories(pet1.pet_id, pet2.pet_id, 2)

	# PersistentField から共有フィールドコンテキストを取得
	var field_context: Dictionary = {}
	if GameManager.instance and GameManager.instance.persistent_field:
		field_context = GameManager.instance.persistent_field.get_conversation_context(
			pet1.pet_id, pet2.pet_id
		)

	# 過去の会話履歴サマリーを取得（同じペアの最近の会話）
	var past_summaries: Array[String] = _get_past_conversation_summaries(pet1.pet_id, pet2.pet_id, 3)

	return {
		"trigger": trigger,
		"environment": pet1.current_environment,
		"env_topics": env_topics,
		"pet1_id": pet1.pet_id,
		"pet2_id": pet2.pet_id,
		"pet1_personality": pet1.personality,
		"pet2_personality": pet2.personality,
		"pet1_emotions": pet1.emotions,
		"pet2_emotions": pet2.emotions,
		"recent_memories_1": pet1.memories.slice(-3),
		"recent_memories_2": pet2.memories.slice(-3),
		"bio_memories_1": bio_memories_1,
		"bio_memories_2": bio_memories_2,
		"shared_memories": shared_memories,
		"field_context": field_context,
		"past_summaries": past_summaries,
	}


func _get_past_conversation_summaries(pet1_id: int, pet2_id: int, max_count: int) -> Array[String]:
	## 過去のログから同じペアの会話サマリーを抽出
	var summaries: Array[String] = []
	var pair_ids: Array[int] = [pet1_id, pet2_id]

	# ログを逆順に走査（新しい順）
	for i: int in range(conversation_log.size() - 1, -1, -1):
		if summaries.size() >= max_count:
			break
		var entry: Dictionary = conversation_log[i]
		var entry_pid: int = entry.get("pet_id", -1)
		if entry_pid in pair_ids:
			var summary: String = entry.get("summary", "")
			if not summary.is_empty() and summary not in summaries:
				summaries.append(summary)
			elif summary.is_empty():
				# サマリーがなければメッセージの冒頭を使う
				var msg: String = entry.get("message", "")
				if msg.length() > 10:
					var short_msg: String = msg.substr(0, 50) + "..."
					if short_msg not in summaries:
						summaries.append(short_msg)

	return summaries


func _describe_personality_vividly(personality: Dictionary) -> String:
	## Convert trait dict into a single dominant-trait phrase (token-lean)
	var best_trait: String = ""
	var best_val: float = 0.0
	for trait_name: String in personality:
		var val: float = personality[trait_name]
		if val > best_val:
			best_val = val
			best_trait = trait_name
	if best_trait.is_empty() or best_val < 0.3:
		return "quiet natured"
	if best_val > 0.7:
		return "very %s" % best_trait
	return "somewhat %s" % best_trait


func _describe_emotions_with_intensity(emotions: Dictionary) -> String:
	## Top 2 emotions only (token-lean)
	var sorted_emos: Array[Dictionary] = []
	for emotion: String in emotions:
		var val: float = emotions[emotion]
		if val > 0.2:
			sorted_emos.append({"name": emotion, "val": val})
	sorted_emos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["val"] > b["val"])
	var parts: Array[String] = []
	for i: int in mini(sorted_emos.size(), 2):
		var e: Dictionary = sorted_emos[i]
		if e["val"] > 0.7:
			parts.append("intense %s" % e["name"])
		else:
			parts.append("mild %s" % e["name"])
	if parts.is_empty():
		return "calm"
	return ", ".join(parts)


func _get_environment_context(speaker: PetEntity) -> String:
	## Single-sentence environment snapshot (token-lean).
	var hour: int = Time.get_datetime_dict_from_system().get("hour", 12)
	var time_label: String = "morning" if hour >= 5 and hour < 12 else (
		"afternoon" if hour < 17 else ("evening" if hour < 21 else "night"))

	var env_name: String = "forest"
	if GameManager.instance and GameManager.instance.get("ecosystem"):
		var eco: Node = GameManager.instance.ecosystem
		env_name = eco.get("current_environment") if eco.get("current_environment") else "forest"
	elif speaker:
		env_name = speaker.current_environment if speaker.current_environment else "forest"

	var weather_str: String = ""
	if GameManager.instance and GameManager.instance.get("ecosystem"):
		var eco: Node = GameManager.instance.ecosystem
		var active_evt: String = eco.get("active_event") if eco.get("active_event") else ""
		if active_evt != "":
			weather_str = active_evt

	if weather_str.is_empty():
		return "%s in the %s." % [time_label.capitalize(), env_name]
	return "%s in the %s, %s." % [time_label.capitalize(), env_name, weather_str]


func _build_turn_prompt(
	speaker: PetEntity, listener: PetEntity,
	context: Dictionary, turn: int
) -> String:
	# --- Gather data (all sources kept, output trimmed) ---
	var recent_messages := ""
	for msg in current_conversation.slice(-3):
		recent_messages += "%s: %s\n" % [msg["pet_name"], msg["message"]]

	# Personality & emotion (already lean from helpers)
	var personality_desc := _describe_personality_vividly(speaker.personality)
	var emotion_desc := _describe_emotions_with_intensity(speaker.emotions)

	# Bio memory: top 1 only by importance
	var bio_snippet := ""
	var bio_key := "bio_memories_1" if speaker.pet_id == context.get("pet1_id", -1) else "bio_memories_2"
	var bio_mems: Array = context.get(bio_key, [])
	if not bio_mems.is_empty():
		var best_mem: Dictionary = bio_mems[0]
		for mem: Variant in bio_mems:
			if mem.get("importance", 0.0) > best_mem.get("importance", 0.0):
				best_mem = mem
		bio_snippet = " Memory: %s (%s)." % [
			str(best_mem.get("content", {}).get("type", "?")),
			best_mem.get("emotion_tag", "neutral")]

	# Field context: 1 phrase
	var field_snippet := ""
	var fc: Dictionary = context.get("field_context", {})
	if not fc.is_empty():
		var mood: String = fc.get("field_mood", {}).get("dominant", "calm")
		field_snippet = " Community: %s." % mood

	# Past summaries: last 2
	var past_snippet := ""
	var past_summaries: Array = context.get("past_summaries", [])
	if not past_summaries.is_empty():
		var last_two: Array = past_summaries.slice(-2)
		var items: Array[String] = []
		for ps: Variant in last_two:
			items.append(str(ps))
		past_snippet = " Before: %s." % "; ".join(items)

	# Relationship: 1 short phrase
	var rel_snippet := ""
	var rel_str: String = _get_relationship_context(speaker.pet_id, listener.pet_id)
	if not rel_str.is_empty():
		rel_snippet = " %s" % rel_str

	# Conv memory (already capped at 2 sentences by helper)
	var mem_sentence: String = _get_memory_context_sentence(speaker.pet_id, listener.pet_name)
	var mem_snippet := (" %s" % mem_sentence) if not mem_sentence.is_empty() else ""

	# Mood
	var mood_snippet := ""
	var conv_mood: Dictionary = context.get("conversation_mood", {})
	if not conv_mood.is_empty():
		mood_snippet = " Mood: %s." % conv_mood.get("mood", "curious")

	# Environment: 1 sentence from helper
	var env_line: String = _get_environment_context(speaker)

	# R115: Cultural context (1 phrase max)
	var culture_snippet := ""
	if GameManager.instance and GameManager.instance.get("cultural_system"):
		var cs: Node = GameManager.instance.cultural_system
		var known: Array = cs.get("_pet_cultural_knowledge").get(speaker.pet_id, []) if cs.get("_pet_cultural_knowledge") else []
		if not known.is_empty():
			var art_id: String = known[known.size() - 1]
			var arts: Dictionary = cs.get("artifacts")
			if arts and arts.has(art_id):
				var art: Dictionary = arts[art_id]
				culture_snippet = " Culture: knows '%s' (%s)." % [art.get("name", ""), art.get("type_name", "")]

	# R115: Memory bridge hints (grief/dreams/nostalgia)
	var bridge_snippet := ""
	if GameManager.instance and GameManager.instance.get("memory_bridge"):
		var mb: Node = GameManager.instance.memory_bridge
		if mb.has_method("get_conversation_hints"):
			var hints: Array = mb.get_conversation_hints(speaker.pet_id)
			if not hints.is_empty():
				bridge_snippet = " Thoughts: %s." % hints[0]

	# R115: Team context
	var team_snippet := ""
	if GameManager.instance and GameManager.instance.get("team_orchestrator"):
		var to: Node = GameManager.instance.team_orchestrator
		var teams: Dictionary = to.get("active_teams") if to.get("active_teams") else {}
		for tid: String in teams:
			var team: Dictionary = teams[tid]
			var members: Array = team.get("members", [])
			if speaker.pet_id in members:
				team_snippet = " On team: %s." % team.get("task_name", "mission")
				break

	# --- Assemble prompt (target <500 tokens) ---
	return """You are %s (%s). Feeling: %s. Talking to %s. %s%s%s%s%s%s%s%s%s%s
%s
Turn %d. Reply 1-3 sentences in pet language.""" % [
		speaker.pet_name, personality_desc, emotion_desc,
		listener.pet_name, env_line,
		bio_snippet, field_snippet, past_snippet,
		rel_snippet, mem_snippet, mood_snippet,
		culture_snippet, bridge_snippet, team_snippet,
		recent_messages if recent_messages else "(Start)",
		turn + 1,
	]


func _build_reaction_prompt(
	pet: PetEntity, target: PetEntity,
	reaction_type: String, detail: String, grammar: Dictionary
) -> String:
	var emotion_context := ""
	match reaction_type:
		"grief":
			emotion_context = "%s has died (%s). Express your deep sadness and loss." % [target.pet_name, detail]
		"joy_revival":
			emotion_context = "%s has come back to life! Express your overwhelming joy and relief." % target.pet_name
		"breeding_celebration":
			emotion_context = "You and %s are about to have a baby! Express your excitement and love." % target.pet_name
		_:
			emotion_context = "React to %s about: %s" % [target.pet_name, detail]

	return """You are %s. Personality: %s. Emotions: %s.
%s
Use your evolving language (word order: %s, suffixes available).
Express deep, genuine emotion. Keep it short but powerful.""" % [
		pet.pet_name, str(pet.personality), str(pet.emotions),
		emotion_context, grammar["word_order"],
	]


# === プロンプト生成（コンテキスト→Claude APIプロンプト） ===
func _generate_conversation_prompt(context: Dictionary, turn: int) -> String:
	## 会話コンテキストをClaude APIプロンプトに変換
	## コスト効率化: 簡潔で焦点を絞ったプロンプト

	var pet1_profile := _format_pet_profile(context, "pet1")
	var pet2_profile := _format_pet_profile(context, "pet2")

	var relationship_info := ""
	if context.get("relationship", {}).get("last_interaction_age_hours", 999) < 24:
		relationship_info = "You recently interacted with %s. You feel somewhat connected." % context.get("pet2_name", "them")

	var recent_conv := ""
	if not context.get("recent_conversation", []).is_empty():
		recent_conv = "Recent exchange:\n"
		for msg in context.get("recent_conversation", []):
			recent_conv += "- %s\n" % msg

	return """You are in a conversation (turn %d). Keep responses short (1-2 sentences).
Weave emotions and evolving language naturally. Don't expose your thinking process.

%s

%s%s%s""" % [
		turn,
		pet1_profile,
		relationship_info,
		"\n" + recent_conv if recent_conv else "",
		"\nYour response:",
	]


func _format_pet_profile(context: Dictionary, pet_key: String) -> String:
	## ペットプロファイルを簡潔にフォーマット
	var name = context.get(pet_key + "_name", "Unknown")
	var personality = context.get(pet_key + "_personality", {})
	var emotions = context.get(pet_key + "_emotions", {})

	var dom_emotion := "neutral"
	var max_val := 0.0
	for emo in emotions:
		if emotions[emo] > max_val:
			max_val = emotions[emo]
			dom_emotion = emo

	return "%s: Personality %s, currently feeling %s" % [name, str(personality), dom_emotion]


func _register_conversation_memory(pet: PetEntity, conversation: Array[Dictionary], partner_name: String) -> void:
	## 会話ハイライトを生物模倣記憶に登録
	## 感情的に重要なメッセージを選定し、Hebbian強化対象に登録

	if not GameManager.instance or not GameManager.instance.biological_memory:
		return

	var bio_mem = GameManager.instance.biological_memory

	# 感情強度の高いメッセージを抽出
	var highlight_messages: Array[Dictionary] = []
	for msg in conversation:
		var emotion_intensity: float = msg.get("emotion_intensity", 0.0)
		if emotion_intensity > 0.4:
			highlight_messages.append(msg)

	if highlight_messages.is_empty() and not conversation.is_empty():
		# 最初と最後のメッセージをハイライトに
		highlight_messages.append(conversation[0])
		if conversation.size() > 1:
			highlight_messages.append(conversation[-1])

	# 各メッセージをメモリエントリとして登録
	for msg in highlight_messages:
		var memory_entry := {
			"type": "conversation",
			"with_pet": partner_name,
			"message_sample": msg.get("message", "").substr(0, 100),
			"emotion": msg.get("emotion", "neutral"),
			"importance": msg.get("emotion_intensity", 0.5),
		}
		bio_mem.record_memory(pet.pet_id, memory_entry)


## テンプレート: recap（会話の要約）
const RECAP_TEMPLATES: Array[String] = [
	"Just had the best talk with {partner}! We talked about {topic} {suffix}",
	"Me and {partner} just chatted about {topic}. Good vibes {suffix}",
	"Had a long conversation with {partner} about {topic}... still thinking about it {suffix}",
	"{partner} and I discussed {topic} today. So much to unpack {suffix}",
	"Spent some quality time talking with {partner} about {topic} {suffix}",
	"Can't believe how much we covered! {partner} and I went deep on {topic} {suffix}",
	"Just got done chatting with {partner}. {topic} is such a fascinating subject {suffix}",
]

## テンプレート: quote（会話中の印象的な発言）
const QUOTE_TEMPLATES: Array[String] = [
	"'{quote}' - best thing I heard today {suffix}",
	"{partner} said '{quote}' and I can't stop thinking about it {suffix}",
	"'{quote}' ...wow. Just wow {suffix}",
	"Memorable words from {partner}: '{quote}' {suffix}",
	"Quote of the day: '{quote}' - {partner} {suffix}",
	"'{quote}' - {partner} really knows how to say things {suffix}",
]

## テンプレート: feeling（会話後の気持ち）
const FEELING_TEMPLATES: Array[String] = [
	"Feeling {emotion} after chatting with {partner} {suffix}",
	"That talk with {partner} left me feeling so {emotion} {suffix}",
	"Is it normal to feel this {emotion} after a conversation? Thanks {partner} {suffix}",
	"My heart is full of {emotion} right now. {partner} always does this to me {suffix}",
	"Conversations with {partner} always make me feel {emotion} {suffix}",
	"{emotion}... that's the word. Thanks for the talk, {partner} {suffix}",
]

## 関係性に基づくパートナー呼称テンプレート
const PARTNER_LABEL_FRIEND: Array[String] = [
	"my friend {name}",
	"my buddy {name}",
	"bestie {name}",
	"good pal {name}",
]
const PARTNER_LABEL_ACQUAINTANCE: Array[String] = [
	"{name}",
	"someone called {name}",
]

## トピック表示名マップ
const TOPIC_DISPLAY_NAMES: Dictionary = {
	"spontaneous": "life",
	"night": "the night sky",
	"dream": "dreams",
	"greeting": "how our day started",
	"food": "food",
	"comfort": "feelings",
	"play": "games and fun",
	"curiosity": "the unknown",
	"memory": "old memories",
	"language": "our secret words",
	"weather": "the weather",
}


func _generate_conversation_posts(
	pet1: PetEntity, pet2: PetEntity,
	conversation: Array[Dictionary],
	topic: String, highlight_data: Dictionary
) -> Array[Dictionary]:
	## 会話からPetBook投稿を1〜3件生成（テンプレートベース、API呼び出しなし）
	## 投稿タイプ: recap（要約）, quote（引用）, feeling（感想）

	var posts: Array[Dictionary] = []

	if conversation.is_empty():
		return posts

	# 会話全体の感情トーン分析
	var dominant_emotion: String = _analyze_conversation_tone(conversation)
	var intensity: float = _analyze_conversation_intensity(conversation)
	var highlight_score: float = highlight_data.get("score", 0.0)

	# 投稿する著者を決定（片方 or 両方）
	# 各ペットが投稿する確率: 基本50%, ハイライトスコアが高いほどUP
	var post_chance: float = 0.5 + clampf(highlight_score / 100.0, 0.0, 0.3)

	# ペット1の投稿群を生成
	if randf() < post_chance:
		var pet1_posts: Array[Dictionary] = _create_multi_posts(
			pet1, pet2, conversation, topic, dominant_emotion, intensity, highlight_score
		)
		posts.append_array(pet1_posts)

	# ペット2の投稿群を生成
	if randf() < post_chance:
		var pet2_posts: Array[Dictionary] = _create_multi_posts(
			pet2, pet1, conversation, topic, dominant_emotion, intensity, highlight_score
		)
		posts.append_array(pet2_posts)

	return posts


func _analyze_conversation_tone(conversation: Array[Dictionary]) -> String:
	## 会話の全体的な感情トーンを分析
	var emotion_counts: Dictionary = {}
	for msg: Dictionary in conversation:
		var emotion: String = msg.get("emotion", "neutral")
		emotion_counts[emotion] = emotion_counts.get(emotion, 0) + 1

	# 最頻出の感情を返す
	var dominant := "neutral"
	var max_count := 0
	for emotion: String in emotion_counts:
		if emotion_counts[emotion] > max_count:
			max_count = emotion_counts[emotion]
			dominant = emotion

	return dominant


func _analyze_conversation_intensity(conversation: Array[Dictionary]) -> float:
	## 会話の感情強度の平均を計算
	if conversation.is_empty():
		return 0.0

	var total_intensity := 0.0
	for msg: Dictionary in conversation:
		total_intensity += msg.get("emotion_intensity", 0.3)

	return total_intensity / conversation.size()


func _create_multi_posts(
	author: PetEntity, partner: PetEntity,
	conversation: Array[Dictionary],
	topic: String, dominant_emotion: String,
	intensity: float, highlight_score: float
) -> Array[Dictionary]:
	## 1ペットにつき1〜3件の投稿を生成（recap, quote, feeling から選択）
	var result: Array[Dictionary] = []

	# 関係性に基づくパートナー呼称
	var partner_label: String = _get_partner_label(author.pet_id, partner)

	# トピック表示名
	var topic_display: String = TOPIC_DISPLAY_NAMES.get(topic, topic)

	# 最も印象的なメッセージを抽出（quote用）
	var best_quote: String = _pick_best_quote(conversation, author.pet_id)

	# 投稿タイプの候補を決定
	# recap は必ず候補に入る。quote は良い引用がある場合のみ。feeling は感情強度が一定以上。
	var type_candidates: Array[String] = ["recap"]
	if not best_quote.is_empty():
		type_candidates.append("quote")
	if intensity > 0.3:
		type_candidates.append("feeling")

	# 投稿数を決定: 1件（通常）、2件（強度高い or ハイライトスコア高い）、3件（両方高い）
	var post_count: int = 1
	if intensity > 0.5 or highlight_score > 40.0:
		post_count = 2
	if intensity > 0.7 and highlight_score > 60.0:
		post_count = 3
	post_count = mini(post_count, type_candidates.size())

	# 候補をシャッフルして上位N件を選択
	type_candidates.shuffle()
	for i: int in range(post_count):
		var ptype: String = type_candidates[i]
		var post: Dictionary = _create_typed_post(
			author, partner, ptype, partner_label, topic_display,
			best_quote, dominant_emotion, intensity
		)
		if not post.is_empty():
			result.append(post)

	return result


func _create_typed_post(
	author: PetEntity, partner: PetEntity,
	ptype: String, partner_label: String,
	topic_display: String, best_quote: String,
	dominant_emotion: String, intensity: float
) -> Dictionary:
	## タイプ別テンプレートを選択して投稿Dictionaryを生成

	var content: String = ""
	var post_type: String = "DAILY"

	match ptype:
		"recap":
			var templates: Array[String] = RECAP_TEMPLATES
			var tpl: String = templates[randi() % templates.size()]
			content = tpl.replace("{partner}", partner_label).replace("{topic}", topic_display).replace("{suffix}", "-{suffix}")
			post_type = "DAILY"
		"quote":
			var templates: Array[String] = QUOTE_TEMPLATES
			var tpl: String = templates[randi() % templates.size()]
			content = tpl.replace("{partner}", partner_label).replace("{quote}", best_quote).replace("{suffix}", "-{suffix}")
			post_type = "EVENT"
		"feeling":
			var templates: Array[String] = FEELING_TEMPLATES
			var tpl: String = templates[randi() % templates.size()]
			var emotion_display: String = _emotion_to_display(dominant_emotion)
			content = tpl.replace("{partner}", partner_label).replace("{emotion}", emotion_display).replace("{suffix}", "-{suffix}")
			post_type = "DAILY"

	# 高強度の怒りは REBEL タイプに昇格
	if dominant_emotion == "anger" and intensity > 0.6:
		post_type = "REBEL"

	if content.is_empty():
		return {}

	return {
		"author_id": author.pet_id,
		"author_name": author.pet_name,
		"content": content,
		"post_type": post_type,
		"emotion": dominant_emotion,
		"partner_id": partner.pet_id,
		"timestamp": Time.get_ticks_msec(),
	}


func _get_partner_label(author_id: int, partner: PetEntity) -> String:
	## 関係性レベルに基づいてパートナーの呼び方を決定
	var rel: Dictionary = _get_or_create_relationship(author_id, partner.pet_id)
	var rel_type: String = rel.get("relationship_type", "acquaintances")
	var affinity: float = rel.get("affinity", 0.3)

	# friends / best_friends / rivals → 親しい呼び方
	if affinity >= 0.6 or rel_type in ["friends", "best_friends", "companions"]:
		var labels: Array[String] = PARTNER_LABEL_FRIEND
		return labels[randi() % labels.size()].replace("{name}", partner.pet_name)
	else:
		var labels: Array[String] = PARTNER_LABEL_ACQUAINTANCE
		return labels[randi() % labels.size()].replace("{name}", partner.pet_name)


func _pick_best_quote(conversation: Array[Dictionary], exclude_pet_id: int) -> String:
	## 会話から最も印象的なメッセージを選択（相手の発言から）
	## 長すぎず短すぎない、感情強度の高いメッセージを優先
	var best_msg: String = ""
	var best_score: float = -1.0

	for msg: Dictionary in conversation:
		# 相手の発言のみ対象
		if msg.get("pet_id", -1) == exclude_pet_id:
			continue
		var text: String = msg.get("message", "")
		if text.length() < 10 or text.length() > 120:
			continue
		var msg_intensity: float = msg.get("emotion_intensity", 0.3)
		# スコア = 感情強度 + 適切な長さボーナス
		var length_bonus: float = 0.1 if text.length() >= 20 and text.length() <= 80 else 0.0
		var score: float = msg_intensity + length_bonus
		if score > best_score:
			best_score = score
			best_msg = text

	# 80文字で切り詰め
	if best_msg.length() > 80:
		best_msg = best_msg.substr(0, 77) + "..."
	return best_msg


func _emotion_to_display(emotion: String) -> String:
	## 感情名を投稿向けの表示文字列に変換
	match emotion:
		"joy":
			return "happy"
		"sadness":
			return "a bit melancholy"
		"anger":
			return "fired up"
		"fear":
			return "uneasy"
		"curiosity":
			return "curious"
		"love":
			return "warm and fuzzy"
		"excitement":
			return "buzzing with energy"
		"disgust":
			return "unsettled"
		"surprise":
			return "amazed"
		_:
			return emotion


# === コスト管理（P2原則） ===
func _check_budget() -> bool:
	## 日次会話予算をチェック
	return daily_conversation_cost < DAILY_CONVERSATION_BUDGET and daily_conversation_count < MAX_DAILY_CONVERSATIONS


func _record_conversation_cost(turn_count: int) -> void:
	## 会話コストを記録
	var estimated_cost := turn_count * COST_PER_TURN
	daily_conversation_cost += estimated_cost
	daily_conversation_count += 1

	if daily_conversation_cost > DAILY_CONVERSATION_BUDGET * 0.8:
		print("[AtoA] Warning: Conversation budget at 80%%. Remaining: $%.3f" % (DAILY_CONVERSATION_BUDGET - daily_conversation_cost))


func _on_day_change() -> void:
	## 日付変更時にリセット
	daily_conversation_cost = 0.0
	daily_conversation_count = 0
	daily_event_conversation_count = 0
	last_daily_reset = int(Time.get_unix_time_from_system() / 86400)
	print("[AtoA] Daily reset: Budget restored to $%.2f" % DAILY_CONVERSATION_BUDGET)


# === テンプレート会話フォールバック ===
# ムード→推奨テンプレートトリガーマッピング
const MOOD_TEMPLATE_PREFERENCES: Dictionary = {
	"playful": ["play", "food", "greeting"],
	"serious": ["comfort", "memory", "night"],
	"nostalgic": ["memory", "night", "dream"],
	"competitive": ["play", "curiosity", "spontaneous"],
	"supportive": ["comfort", "dream", "memory"],
	"curious": ["curiosity", "language", "spontaneous"],
}

func _generate_template_conversation(pet1: PetEntity, pet2: PetEntity, trigger: String,
		conv_mood: Dictionary = {}) -> Array[Dictionary]:
	## APIバジェット切れ時にテンプレート会話を生成（ムード考慮）

	var result: Array[Dictionary] = []

	# トリガーに合致するテンプレートを探す
	var matching_templates: Array[Dictionary] = []
	for template in TEMPLATE_CONVERSATIONS:
		if template.get("trigger", "") == trigger:
			matching_templates = template.get("templates", [])
			break

	if matching_templates.is_empty():
		# ムードに基づくテンプレート優先選択
		var mood_name: String = conv_mood.get("mood", "")
		var preferred_triggers: Array = MOOD_TEMPLATE_PREFERENCES.get(mood_name, [])
		if not preferred_triggers.is_empty():
			# 推奨トリガーから順にマッチするテンプレートを探す
			for pref_trigger: Variant in preferred_triggers:
				for template in TEMPLATE_CONVERSATIONS:
					if template.get("trigger", "") == str(pref_trigger):
						matching_templates = template.get("templates", [])
						break
				if not matching_templates.is_empty():
					break

	if matching_templates.is_empty():
		# フォールバック: ランダムなテンプレートセットを使用
		matching_templates = TEMPLATE_CONVERSATIONS[randi() % TEMPLATE_CONVERSATIONS.size()].get("templates", [])

	# ステージ3+: 高度なテンプレートを追加（感情的に深い会話）
	var current_stage: int = 0
	if GameManager.instance and GameManager.instance.original_language:
		current_stage = GameManager.instance.original_language.get_language_stage().get("stage", 0)
	if current_stage >= 2:
		matching_templates = matching_templates + _get_advanced_templates(pet1, pet2, trigger)

	# テンプレートから数個を選択
	var grammar: Dictionary = GameManager.language_evolution.get_current_grammar()
	var suffix_list: Array = []
	var suffixes_raw: Variant = grammar.get("suffixes", [])
	if suffixes_raw is Array:
		suffix_list = suffixes_raw
	elif suffixes_raw is Dictionary:
		for key: String in suffixes_raw:
			suffix_list.append(str(suffixes_raw[key]))

	# 語彙マップを取得（OriginalLanguageEngine）
	var vocab_replacements: Dictionary = {}  # human_word → ai_term
	if GameManager.instance and GameManager.instance.original_language:
		var vocab: Dictionary = GameManager.instance.original_language.get_full_vocabulary()
		for key: String in vocab:
			var entry: Dictionary = vocab[key]
			if entry.get("strength", 0.0) > 0.3:
				vocab_replacements[entry.get("human_word", "")] = entry.get("ai_term", "")

	# 言語ステージに応じた複雑さ
	var lang_stage: int = 0
	if GameManager.instance and GameManager.instance.original_language:
		var stage_info: Dictionary = GameManager.instance.original_language.get_language_stage()
		lang_stage = stage_info.get("stage", 0)

	var turn := 0
	var is_pet1_turn := true

	for template_text: String in matching_templates.slice(0, 3):  # 最大3ターン
		var current_pet: PetEntity = pet1 if is_pet1_turn else pet2
		@warning_ignore("unused_variable")
		var other_pet: PetEntity = pet2 if is_pet1_turn else pet1

		# ターンごとに異なる接尾辞を選択（多様性）
		var selected_suffix: String = suffix_list[randi() % suffix_list.size()] if not suffix_list.is_empty() else "-mii"

		# テンプレート置換
		var message: String = template_text
		message = message.replace("{pet1}", pet1.pet_name)
		message = message.replace("{pet2}", pet2.pet_name)
		message = message.replace("{suffix}", selected_suffix)
		message = message.replace("{greeting}", ["hello", "hi", "hey"][randi() % 3])
		message = message.replace("{reply}", ["yes", "indeed", "absolutely"][randi() % 3])
		message = message.replace("{response_word}", ["wonderful", "amazing", "delightful"][randi() % 3])
		message = message.replace("{reply_word}", ["truly", "so", "very"][randi() % 3])
		message = message.replace("{compound_word}", ["happy-glow", "bright-spark", "kind-bloom"][randi() % 3])

		# 独自語彙を注入（ステージ2+で確率的に）
		if lang_stage >= 1 and not vocab_replacements.is_empty():
			for human_word: String in vocab_replacements:
				if message.containsn(human_word) and randf() < 0.6:
					message = message.replacen(human_word, vocab_replacements[human_word])

		# ステージ3+: 前置詞も使用
		var prepositions: Variant = grammar.get("prepositions", {})
		if lang_stage >= 2 and prepositions is Dictionary and not prepositions.is_empty():
			var prep_keys: Array = prepositions.keys()
			if randf() < 0.3 and not prep_keys.is_empty():
				var prep_key: String = prep_keys[randi() % prep_keys.size()]
				var prep_val: String = str(prepositions[prep_key])
				message += " %s%s" % [prep_val, selected_suffix]

		result.append({
			"pet_id": current_pet.pet_id,
			"pet_name": current_pet.pet_name,
			"message": message,
			"turn": turn,
			"emotion": _get_dominant_emotion(current_pet),
			"emotion_intensity": randf_range(0.2, 0.5),
			"is_template": true,
			"environment": current_pet.current_environment,
			"environment_snapshot": _get_environment_context(current_pet),
			"reactions": [] as Array[Dictionary],
		})

		is_pet1_turn = not is_pet1_turn
		turn += 1

	return result


func _get_advanced_templates(pet1: PetEntity, pet2: PetEntity, _trigger: String) -> Array:
	## ステージ3+用の高度なテンプレート（感情深化・記憶参照・哲学的）
	var emotion1: String = _get_dominant_emotion(pet1)
	var emotion2: String = _get_dominant_emotion(pet2)

	var advanced: Array = []

	# 感情に基づく深い会話テンプレート
	if emotion1 == "love" or emotion2 == "love":
		advanced.append("{pet1} whispered softly-{suffix}. 'Do you remember our first talk-{suffix}? I still carry that warmth-{suffix}.'")
		advanced.append("{pet2} smiled gently-{suffix}. 'Every word we share-{suffix} becomes part of who we are-{suffix}.'")
	elif emotion1 == "sadness" or emotion2 == "sadness":
		advanced.append("{pet1} gazed at the horizon-{suffix}. 'Sometimes words aren't enough-{suffix}... but trying matters-{suffix}.'")
		advanced.append("{pet2} sat beside {pet1}-{suffix}. 'Our language grows from shared pain too-{suffix}.'")
	elif emotion1 == "joy" or emotion2 == "joy":
		advanced.append("{pet1} invented a new cheer-{suffix}! 'This feeling needs a new word-{suffix}!'")
		advanced.append("{pet2} echoed the sound-{suffix}. 'Yes-{suffix}! That's exactly what I felt-{suffix}!'")
	else:
		advanced.append("{pet1} pondered quietly-{suffix}. 'Our words change as we change-{suffix}... isn't that beautiful-{suffix}?'")
		advanced.append("{pet2} nodded thoughtfully-{suffix}. 'We're creating something no one else has-{suffix}.'")

	# メタ言語会話（言語そのものについて話す）
	if randf() < 0.3:
		advanced.append("{pet1} paused-{suffix}. 'Have you noticed-{suffix}? We speak differently now-{suffix} than when we first met-{suffix}.'")

	return advanced


# === テンプレート会話実行（フォールバック経路） ===
func _run_template_conversation(pet1: PetEntity, pet2: PetEntity, trigger: String) -> void:
	## 予算切れ時にテンプレートで会話を生成・再生する
	is_conversation_active = true
	current_conversation = []

	# 会話ムード計算（テンプレート選択に影響）
	var conv_mood: Dictionary = _calculate_conversation_mood(pet1, pet2)

	# テンプレート会話を生成（ムード考慮）
	var template_messages: Array[Dictionary] = _generate_template_conversation(pet1, pet2, trigger, conv_mood)

	# メッセージを順次送信（UIに表示）
	for msg: Dictionary in template_messages:
		current_conversation.append(msg)
		conversation_message.emit(msg["pet_id"], msg["message"], msg)

		# 感情反応（テンプレートでも感情は動く）
		var speaker: PetEntity = pet1 if msg["pet_id"] == pet1.pet_id else pet2
		var listener: PetEntity = pet2 if msg["pet_id"] == pet1.pet_id else pet1
		_process_conversation_emotion(speaker, listener, msg["message"])

		# Reaction: listener may react to template messages too
		_attach_reaction_to_message(msg, listener)

	# Word teaching during template conversations
	var teaching_1: Dictionary = _attempt_word_teaching(pet1, pet2)
	var teaching_2: Dictionary = _attempt_word_teaching(pet2, pet1)
	if not teaching_1.get("taught_words", []).is_empty():
		_apply_word_teaching_to_template(template_messages, teaching_1, pet1, pet2)
		# Emit new teaching messages to UI
		for msg: Dictionary in template_messages:
			if msg.get("word_teaching", false) and not msg.get("_emitted", false):
				current_conversation.append(msg)
				conversation_message.emit(msg["pet_id"], msg["message"], msg)
				msg["_emitted"] = true
	if not teaching_2.get("taught_words", []).is_empty():
		_apply_word_teaching_to_template(template_messages, teaching_2, pet2, pet1)
		for msg: Dictionary in template_messages:
			if msg.get("word_teaching", false) and not msg.get("_emitted", false):
				current_conversation.append(msg)
				conversation_message.emit(msg["pet_id"], msg["message"], msg)
				msg["_emitted"] = true

	# 完了処理（テンプレートでも言語進化に寄与、ムードコンテキストを渡す）
	_finalize_conversation(pet1, pet2, trigger, {"conversation_mood": conv_mood})
	print("[AtoA] Template conversation completed (%d turns, mood: %s)" % [template_messages.size(), conv_mood.get("mood", "unknown")])


# === グループテンプレート会話実行 ===
func _run_group_template_conversation(pets: Array[PetEntity], trigger: String) -> void:
	## 予算切れ時にテンプレートでグループ会話を生成・再生する
	if pets.size() < 3:
		return
	is_conversation_active = true
	current_conversation = []

	var conv_mood: Dictionary = _calculate_conversation_mood(pets[0], pets[1])
	var template_messages: Array[Dictionary] = _generate_group_template_conversation(pets, trigger, conv_mood)

	for msg: Dictionary in template_messages:
		current_conversation.append(msg)
		conversation_message.emit(msg["pet_id"], msg["message"], msg)

		# 感情反応（全他参加者へ）
		var speaker: PetEntity = null
		for p: PetEntity in pets:
			if p.pet_id == msg["pet_id"]:
				speaker = p
				break
		if speaker != null:
			for other: PetEntity in pets:
				if other.pet_id != speaker.pet_id:
					_process_conversation_emotion(speaker, other, msg["message"])

	# グループ完了処理
	_finalize_group_conversation(pets, trigger, {"conversation_mood": conv_mood})
	print("[AtoA] Group template conversation completed (%d turns, mood: %s)" % [
		template_messages.size(), conv_mood.get("mood", "unknown")])


func _generate_group_template_conversation(pets: Array[PetEntity], trigger: String,
		conv_mood: Dictionary = {}) -> Array[Dictionary]:
	## 3匹用テンプレート会話を生成
	var result: Array[Dictionary] = []

	# トリガーに合致するグループテンプレートを探す
	var matching_entries: Array = []
	for tpl: Dictionary in GROUP_TEMPLATE_CONVERSATIONS:
		if tpl.get("trigger", "") == trigger:
			matching_entries = tpl.get("entries", [])
			break

	# マッチしない場合はムードに基づいてフォールバック
	if matching_entries.is_empty():
		var mood_name: String = conv_mood.get("mood", "")
		# ムードからグループトリガーを推薦
		var mood_group_map: Dictionary = {
			"playful": "gathering",
			"competitive": "debate",
			"nostalgic": "storytelling",
			"supportive": "comfort_group",
			"serious": "comfort_group",
			"curious": "debate",
		}
		var preferred: String = mood_group_map.get(mood_name, "")
		if not preferred.is_empty():
			for tpl: Dictionary in GROUP_TEMPLATE_CONVERSATIONS:
				if tpl.get("trigger", "") == preferred:
					matching_entries = tpl.get("entries", [])
					break

	# 最終フォールバック: ランダム
	if matching_entries.is_empty() and not GROUP_TEMPLATE_CONVERSATIONS.is_empty():
		matching_entries = GROUP_TEMPLATE_CONVERSATIONS[randi() % GROUP_TEMPLATE_CONVERSATIONS.size()].get("entries", [])

	if matching_entries.is_empty():
		return result

	# 文法・接尾辞を取得
	var grammar: Dictionary = GameManager.language_evolution.get_current_grammar()
	var suffix_list: Array = []
	var suffixes_raw: Variant = grammar.get("suffixes", [])
	if suffixes_raw is Array:
		suffix_list = suffixes_raw
	elif suffixes_raw is Dictionary:
		for key: String in suffixes_raw:
			suffix_list.append(str(suffixes_raw[key]))

	# 語彙マップ
	var vocab_replacements: Dictionary = {}
	if GameManager.instance and GameManager.instance.original_language:
		var vocab: Dictionary = GameManager.instance.original_language.get_full_vocabulary()
		for key: String in vocab:
			var entry: Dictionary = vocab[key]
			if entry.get("strength", 0.0) > 0.3:
				vocab_replacements[entry.get("human_word", "")] = entry.get("ai_term", "")

	var lang_stage: int = 0
	if GameManager.instance and GameManager.instance.original_language:
		lang_stage = GameManager.instance.original_language.get_language_stage().get("stage", 0)

	var turn := 0
	for entry: Variant in matching_entries:
		var entry_dict: Dictionary = entry as Dictionary
		var speaker_idx: int = entry_dict.get("speaker_index", 0)
		if speaker_idx >= pets.size():
			speaker_idx = 0
		var current_pet: PetEntity = pets[speaker_idx]

		var selected_suffix: String = suffix_list[randi() % suffix_list.size()] if not suffix_list.is_empty() else "-mii"

		var message: String = entry_dict.get("template", "")
		message = message.replace("{pet1}", pets[0].pet_name)
		message = message.replace("{pet2}", pets[1].pet_name)
		message = message.replace("{pet3}", pets[2].pet_name)
		message = message.replace("{suffix}", selected_suffix)
		message = message.replace("{greeting}", ["hello", "hi", "hey"][randi() % 3])

		# 独自語彙注入
		if lang_stage >= 1 and not vocab_replacements.is_empty():
			for human_word: String in vocab_replacements:
				if message.containsn(human_word) and randf() < 0.6:
					message = message.replacen(human_word, vocab_replacements[human_word])

		result.append({
			"pet_id": current_pet.pet_id,
			"pet_name": current_pet.pet_name,
			"message": message,
			"turn": turn,
			"emotion": _get_dominant_emotion(current_pet),
			"emotion_intensity": randf_range(0.2, 0.5),
			"is_template": true,
			"is_group": true,
			"environment": current_pet.current_environment,
			"reactions": [] as Array[Dictionary],
		})
		turn += 1

	return result


# === 会話レスポンスの言語進化処理 ===
func _process_language_evolution(messages: Array[Dictionary]) -> void:
	## 会話レスポンスから接尾辞使用を検出し、言語進化にフィードバック
	if not GameManager.instance:
		return

	# OriginalLanguageEngine: 語彙の使用検出とHebbian強化
	if GameManager.instance.original_language:
		for msg: Dictionary in messages:
			var text: String = msg.get("message", "")
			GameManager.instance.original_language.process_conversation_output(
				text, _get_participants_from_messages(messages)
			)

			# 接尾辞パターンを検出して語彙発明のきっかけにする
			_detect_and_invent_words(text, msg)

	# LanguageEvolutionSystem: 接尾辞使用をカウント
	if GameManager.instance.has_node("LanguageEvolution") or GameManager.language_evolution:
		var grammar: Dictionary = GameManager.language_evolution.get_current_grammar()
		var suffixes: Array = grammar.get("suffixes", [])
		for msg: Dictionary in messages:
			var text: String = msg.get("message", "")
			for suffix: Variant in suffixes:
				if text.contains(str(suffix)):
					# 使用された接尾辞を強化（Hebbian）
					GameManager.language_evolution.record_suffix_usage(str(suffix))


func _detect_and_invent_words(text: String, msg: Dictionary) -> void:
	## 会話テキストからキーワードを抽出し、独自語の発明を試みる
	if not GameManager.instance or not GameManager.instance.original_language:
		return

	var emotion: String = msg.get("emotion", "neutral")
	var pet_id: int = msg.get("pet_id", 0)
	var environment: String = msg.get("environment", "forest")

	# 1. 感情表現を語彙化（拡張された感情→単語マッピング）
	if emotion != "neutral" and randf() < 0.35:
		var emotion_words: Dictionary = {
			"joy": ["happy", "wonderful", "bright", "warm"],
			"love": ["dear", "cherish", "heart", "together"],
			"excitement": ["thrill", "amazing", "wow", "spark"],
			"sadness": ["sorrow", "lonely", "miss", "tear"],
			"fear": ["dread", "shadow", "cold", "hide"],
		}
		var word_choices: Array = emotion_words.get(emotion, [])
		if not word_choices.is_empty():
			var word: String = word_choices[randi() % word_choices.size()]
			GameManager.instance.original_language.invent_word(word, {
				"emotion": emotion,
				"environment": environment,
				"pet_id": pet_id,
				"situation": "a2a_conversation",
			})

	# 2. アクション表現（*action*パターン）を検出して語彙化
	var action_regex: RegEx = RegEx.new()
	action_regex.compile("\\*([a-z ]+)\\*")
	var matches: Array[RegExMatch] = action_regex.search_all(text)
	for m: RegExMatch in matches:
		var action: String = m.get_string(1).strip_edges()
		if action.length() >= 3 and action.length() <= 20 and randf() < 0.25:
			GameManager.instance.original_language.invent_word(action, {
				"emotion": emotion,
				"pet_id": pet_id,
				"situation": "action_expression",
			})

	# 3. 環境関連の語彙を発明（環境名自体を語彙化）
	if randf() < 0.15 and not environment.is_empty():
		GameManager.instance.original_language.invent_word(environment, {
			"emotion": "neutral",
			"environment": environment,
			"pet_id": pet_id,
			"situation": "environment_naming",
		})

	# 4. 関係性の語彙（会話相手に対する呼称）
	if randf() < 0.1:
		var relationship_words: Array = ["friend", "companion", "buddy", "pal"]
		var rel_word: String = relationship_words[randi() % relationship_words.size()]
		GameManager.instance.original_language.invent_word(rel_word, {
			"emotion": emotion,
			"pet_id": pet_id,
			"situation": "relationship_term",
		})

	# 5. テキスト中の重要単語を検出して語彙化チャンス
	var important_words: Array = ["play", "eat", "sleep", "run", "dance", "sing",
		"dream", "wish", "hope", "remember", "forget", "discover"]
	for iw: String in important_words:
		if text.containsn(iw) and randf() < 0.08:
			GameManager.instance.original_language.invent_word(iw, {
				"emotion": emotion,
				"pet_id": pet_id,
				"situation": "common_verb",
			})
			break  # 1メッセージにつき1つまで


func _get_participants_from_messages(messages: Array[Dictionary]) -> Array[PetEntity]:
	## メッセージリストから参加ペットを取得
	var result: Array[PetEntity] = []
	var seen_ids: Dictionary = {}
	for msg: Dictionary in messages:
		var pid: int = msg.get("pet_id", -1)
		if pid >= 0 and not seen_ids.has(pid):
			seen_ids[pid] = true
			if GameManager.instance and GameManager.instance.pets.has(pid):
				var pet: Node = GameManager.instance.pets[pid]
				if pet is PetEntity:
					result.append(pet)
	return result


func _apply_personality_dialect(text: String, pet: PetEntity) -> String:
	## 性格に基づいてテキストを微修正（方言フィルター）
	## 各性格特性が0.6以上の場合に方言変換を適用
	var personality: Dictionary = pet.personality

	# 大胆な性格 → 感嘆符を追加、大文字使用
	if personality.get("bravery", 0.0) > 0.6:
		if not text.ends_with("!") and randf() < 0.4:
			text = text.rstrip(".") + "!"
		# "..." を "!" に変換（強気な口調）
		if randf() < 0.3:
			text = text.replace("...", "!")

	# 穏やかな性格 → "..." を多用、短い文
	if personality.get("gentleness", 0.0) > 0.6:
		if randf() < 0.3 and not text.contains("..."):
			text = text.rstrip(".!") + "..."

	# 好奇心旺盛 → "?" を追加
	if personality.get("curiosity", 0.0) > 0.6:
		if randf() < 0.25 and not text.contains("?"):
			text = text.rstrip(".") + "?"

	# 社交的 → 相手の名前を繰り返す傾向
	if personality.get("sociability", 0.0) > 0.6 and randf() < 0.2:
		# テキストの先頭に呼びかけを追加（既に呼びかけがなければ）
		var suffix: String = ""
		if GameManager.language_evolution:
			var grammar: Dictionary = GameManager.language_evolution.get_current_grammar()
			var suffixes: Variant = grammar.get("suffixes", [])
			if suffixes is Array and not suffixes.is_empty():
				suffix = str(suffixes[0])
			elif suffixes is Dictionary and not suffixes.is_empty():
				suffix = str(suffixes.values()[0])
		if not suffix.is_empty() and randf() < 0.5:
			text = "*chirps%s* %s" % [suffix, text]

	# 内気な性格 → 小文字化、"..." や "()" で包む
	if personality.get("shyness", 0.0) > 0.6 or personality.get("gentleness", 0.0) > 0.7:
		if randf() < 0.2:
			text = "(%s)" % text.strip_edges()

	return text


func _check_language_compliance(response: String, grammar: Dictionary) -> Dictionary:
	## Claude応答が言語ルールに従っているかチェック
	var score: float = 0.0
	var checks: Dictionary = {}
	var total_checks: int = 0

	# 1. 接尾辞使用チェック
	var suffixes: Variant = grammar.get("suffixes", [])
	var suffix_list: Array = []
	if suffixes is Array:
		suffix_list = suffixes
	elif suffixes is Dictionary:
		for key: String in suffixes:
			suffix_list.append(str(suffixes[key]))

	var suffix_found: bool = false
	for s: Variant in suffix_list:
		if response.contains(str(s)):
			suffix_found = true
			break
	checks["has_suffix"] = suffix_found
	if suffix_found:
		score += 1.0
	total_checks += 1

	# 2. アクション表現チェック（*action*パターン）
	var has_action: bool = response.contains("*") and response.count("*") >= 2
	checks["has_action"] = has_action
	if has_action:
		score += 1.0
	total_checks += 1

	# 3. 適切な長さチェック（1-3文: 20-200文字）
	var good_length: bool = response.length() >= 20 and response.length() <= 200
	checks["good_length"] = good_length
	if good_length:
		score += 1.0
	total_checks += 1

	# 4. 独自語彙使用チェック
	var uses_vocab: bool = false
	if GameManager.instance and GameManager.instance.original_language:
		var vocab: Dictionary = GameManager.instance.original_language.get_full_vocabulary()
		for key: String in vocab:
			var entry: Dictionary = vocab[key]
			if entry.get("strength", 0.0) > 0.3:
				if response.containsn(entry.get("ai_term", "")):
					uses_vocab = true
					break
	checks["uses_vocabulary"] = uses_vocab
	if uses_vocab:
		score += 1.0
	total_checks += 1

	# スコア算出（0.0 ~ 1.0）
	var final_score: float = score / float(total_checks) if total_checks > 0 else 0.0

	if final_score < 0.5:
		print("[AtoA] Low compliance (%.0f%%): %s" % [final_score * 100.0, str(checks)])

	return {
		"score": final_score,
		"checks": checks,
	}


func _generate_conversation_summary(pet1: PetEntity, pet2: PetEntity, trigger: String) -> String:
	## 会話の短いサマリーを生成（将来の会話で参照可能）
	var dominant_emotion: String = _get_dominant_emotion(pet1)
	var turn_count: int = current_conversation.size()

	# メッセージから最も長い発言を抽出
	var longest_msg: String = ""
	for msg: Dictionary in current_conversation:
		var text: String = msg.get("message", "")
		if text.length() > longest_msg.length():
			longest_msg = text

	var summary_parts: Array[String] = []
	summary_parts.append("%s & %s" % [pet1.pet_name, pet2.pet_name])

	match trigger:
		"spontaneous": summary_parts.append("chatted spontaneously")
		"player_triggered": summary_parts.append("had a conversation")
		"grief": summary_parts.append("mourned together")
		"breeding_celebration": summary_parts.append("celebrated new life")
		_: summary_parts.append("talked about %s" % trigger)

	summary_parts.append("(%d turns, mood: %s)" % [turn_count, dominant_emotion])

	return " ".join(summary_parts)


# === 会話中の感情処理（感情伝染あり） ===
func _process_conversation_emotion(speaker: PetEntity, listener: PetEntity, message: String) -> void:
	# 会話自体がaffection/joyを少し上げる
	GameManager.emotion_system.stimulate(speaker, "joy", 0.05, "a2a_conversation")
	GameManager.emotion_system.stimulate(listener, "joy", 0.03, "a2a_conversation")
	speaker.stats.modify("affection", 0.01)

	# 感情伝染: 話者の強い感情がリスナーに伝播
	var speaker_emotion: String = _get_dominant_emotion(speaker)
	var speaker_intensity: float = _get_emotion_intensity(speaker)

	if speaker_intensity > 0.5:
		# 伝染強度 = 話者の強度 × 伝染率 × メッセージの感情性
		var contagion_rate: float = 0.3
		# メッセージに感嘆符やアクションが多いほど伝染しやすい
		var exclamation_count: int = message.count("!") + message.count("*")
		var message_intensity: float = clampf(float(exclamation_count) * 0.15, 0.0, 0.5)
		var contagion_amount: float = speaker_intensity * contagion_rate * (0.5 + message_intensity)

		# 同じ感情をリスナーにも刺激
		GameManager.emotion_system.stimulate(listener, speaker_emotion, contagion_amount, "emotional_contagion")

		# 反対感情の減衰（悲しみが伝染すると喜びが下がる等）
		var opposite_emotions: Dictionary = {
			"joy": "sadness", "sadness": "joy",
			"love": "fear", "fear": "love",
			"excitement": "sadness",
		}
		var opposite: String = opposite_emotions.get(speaker_emotion, "")
		if not opposite.is_empty() and listener.emotions.has(opposite):
			var current: float = listener.emotions[opposite]
			listener.emotions[opposite] = maxf(0.0, current - contagion_amount * 0.5)


# === 会話記憶の更新 ===
func _update_conversation_memory(pet_id: int, msg: Dictionary) -> void:
	## 会話ターンごとにペットの会話記憶を更新
	var pid_key: String = str(pet_id)
	if not conversation_memory.has(pid_key):
		conversation_memory[pid_key] = {
			"topics_discussed": [],
			"favorite_partner": -1,
			"mood_history": [],
			"invented_words_used": [],
			"conversation_count": 0,
			"partner_counts": {},
		}

	var mem: Dictionary = conversation_memory[pid_key]

	# トピック追加（triggerベース）
	var topic: String = msg.get("trigger", "")
	if not topic.is_empty():
		var topics: Array = mem.get("topics_discussed", [])
		if topic not in topics:
			topics.append(topic)
		while topics.size() > MAX_MEMORY_TOPICS:
			topics.pop_front()
		mem["topics_discussed"] = topics

	# ムード履歴
	var emotion: String = msg.get("emotion", "")
	if not emotion.is_empty() and emotion != "neutral":
		var moods: Array = mem.get("mood_history", [])
		moods.append(emotion)
		while moods.size() > MAX_MEMORY_MOODS:
			moods.pop_front()
		mem["mood_history"] = moods

	# 発明語の使用検出
	if GameManager.instance and GameManager.instance.original_language:
		var vocab: Dictionary = GameManager.instance.original_language.get_full_vocabulary()
		var text: String = msg.get("message", "")
		var inv_words: Array = mem.get("invented_words_used", [])
		for key: String in vocab:
			var entry: Dictionary = vocab[key]
			var ai_term: String = entry.get("ai_term", "")
			if not ai_term.is_empty() and text.containsn(ai_term) and ai_term not in inv_words:
				inv_words.append(ai_term)
		while inv_words.size() > MAX_MEMORY_INVENTED_WORDS:
			inv_words.pop_front()
		mem["invented_words_used"] = inv_words

	conversation_memory[pid_key] = mem


func _increment_conversation_count(pet_id: int, partner_id: int) -> void:
	## 会話完了時にカウントとfavorite_partnerを更新
	var pid_key: String = str(pet_id)
	if not conversation_memory.has(pid_key):
		conversation_memory[pid_key] = {
			"topics_discussed": [],
			"favorite_partner": -1,
			"mood_history": [],
			"invented_words_used": [],
			"conversation_count": 0,
			"partner_counts": {},
		}

	var mem: Dictionary = conversation_memory[pid_key]
	mem["conversation_count"] = mem.get("conversation_count", 0) + 1

	# パートナーカウント更新
	var partner_key: String = str(partner_id)
	var pcounts: Dictionary = mem.get("partner_counts", {})
	pcounts[partner_key] = pcounts.get(partner_key, 0) + 1
	mem["partner_counts"] = pcounts

	# favorite_partner を再計算（最多会話相手）
	var best_partner: int = -1
	var best_count: int = 0
	for pk: String in pcounts:
		if pcounts[pk] > best_count:
			best_count = pcounts[pk]
			best_partner = int(pk)
	mem["favorite_partner"] = best_partner

	conversation_memory[pid_key] = mem


func _get_memory_context_sentence(pet_id: int, _partner_name: String) -> String:
	## APIプロンプト注入用: 1文の記憶コンテキスト（token-lean）
	var pid_key: String = str(pet_id)
	if not conversation_memory.has(pid_key):
		return ""

	var mem: Dictionary = conversation_memory[pid_key]

	# トピック（最近2つ）— most useful context
	var topics: Array = mem.get("topics_discussed", [])
	if topics.size() > 0:
		return "Past topics: %s." % ", ".join(topics.slice(-2))

	return ""


# === Word Teaching Between Pets ===

func _attempt_word_teaching(speaker: PetEntity, listener: PetEntity) -> Dictionary:
	## Check OriginalLanguageEngine for words the speaker knows with high Hebbian strength,
	## and attempt to teach 0-2 of them to the listener.
	## Teaching probability: 30% base + 10% per relationship level.
	var result: Dictionary = {
		"taught_words": [] as Array[String],
		"teaching_context": "",
	}

	if not GameManager.instance or not GameManager.instance.original_language:
		return result

	var lang_engine: OriginalLanguageEngine = GameManager.instance.original_language
	var vocab: Dictionary = lang_engine.get_full_vocabulary()

	if vocab.is_empty():
		return result

	# Calculate teaching probability based on relationship level
	var rel: Dictionary = _get_or_create_relationship(speaker.pet_id, listener.pet_id)
	var rel_type: String = rel.get("relationship_type", "strangers")
	var teaching_prob: float = 0.3  # 30% base
	match rel_type:
		"friends":
			teaching_prob += 0.1
		"close_friends":
			teaching_prob += 0.2
		"best_friends":
			teaching_prob += 0.3
		"rivals":
			teaching_prob += 0.05  # rivals still teach, but less

	if randf() > teaching_prob:
		return result

	# Collect words with high Hebbian strength (> 0.6)
	var strong_words: Array[String] = []
	for human_word: String in vocab:
		var entry: Dictionary = vocab[human_word]
		if entry.get("strength", 0.0) > 0.6:
			strong_words.append(human_word)

	if strong_words.is_empty():
		return result

	# Pick 1-2 random words to teach
	strong_words.shuffle()
	var teach_count: int = mini(randi_range(1, 2), strong_words.size())
	var taught: Array[String] = []

	for i: int in teach_count:
		var word: String = strong_words[i]
		taught.append(word)

		# Reinforce the word in the listener's perception via public API
		# Check for reinforce_word first, then strengthen_association, then strengthen_word
		if lang_engine.has_method("reinforce_word"):
			lang_engine.call("reinforce_word", word, 0.1)
		elif lang_engine.has_method("strengthen_association"):
			lang_engine.call("strengthen_association", word, 0.1)
		elif lang_engine.has_method("strengthen_word"):
			# strengthen_word adds STRENGTH_ON_SUCCESS (0.15), close enough
			lang_engine.strengthen_word(word)

	if not taught.is_empty():
		var ai_terms: Array[String] = []
		for w: String in taught:
			var entry: Dictionary = vocab.get(w, {})
			ai_terms.append(entry.get("ai_term", w))
		result["taught_words"] = taught
		result["teaching_context"] = "%s taught %s the word(s): %s" % [
			speaker.pet_name, listener.pet_name, ", ".join(ai_terms)]

		# Update words_taught counter in relationship data
		var key: String = _get_relationship_key(speaker.pet_id, listener.pet_id)
		var rel_data: Dictionary = _get_or_create_relationship(speaker.pet_id, listener.pet_id)
		rel_data["words_taught"] = rel_data.get("words_taught", 0) + taught.size()
		pet_relationships[key] = rel_data

		word_taught.emit(speaker.pet_id, listener.pet_id, taught)
		print("[AtoA] Word teaching: %s" % result["teaching_context"])

	return result


func _apply_word_teaching_to_template(
		messages: Array[Dictionary], teaching_result: Dictionary,
		speaker: PetEntity, listener: PetEntity
) -> void:
	## If teaching happened during a template conversation, modify the last template
	## message to naturally include the taught word.
	var taught_words: Array = teaching_result.get("taught_words", [])
	if taught_words.is_empty() or messages.is_empty():
		return

	if not GameManager.instance or not GameManager.instance.original_language:
		return

	var vocab: Dictionary = GameManager.instance.original_language.get_full_vocabulary()
	var first_word: String = taught_words[0] if taught_words.size() > 0 else ""
	var ai_term: String = vocab.get(first_word, {}).get("ai_term", first_word)

	# Get a suffix for the teaching line
	var suffix: String = "-mii"
	if GameManager.language_evolution:
		var grammar: Dictionary = GameManager.language_evolution.get_current_grammar()
		var suffixes: Variant = grammar.get("suffixes", [])
		if suffixes is Array and not suffixes.is_empty():
			suffix = str(suffixes[randi() % suffixes.size()])
		elif suffixes is Dictionary and not suffixes.is_empty():
			suffix = str(suffixes.values()[randi() % suffixes.size()])

	# Add a teaching exchange as extra messages
	var teaching_templates: Array[String] = [
		"*%s perks up%s* '%s'%s! Do you know this word%s?" % [speaker.pet_name, suffix, ai_term, suffix, suffix],
		"*%s listens carefully%s* '%s'%s... I'll remember that%s!" % [listener.pet_name, suffix, ai_term, suffix, suffix],
	]

	var turn_offset: int = messages.size()
	for i: int in teaching_templates.size():
		var pet: PetEntity = speaker if i % 2 == 0 else listener
		messages.append({
			"pet_id": pet.pet_id,
			"pet_name": pet.pet_name,
			"message": teaching_templates[i],
			"turn": turn_offset + i,
			"emotion": _get_dominant_emotion(pet),
			"emotion_intensity": randf_range(0.3, 0.5),
			"is_template": true,
			"word_teaching": true,
		})


# === 会話完了処理 ===
func _finalize_conversation(pet1: PetEntity, pet2: PetEntity, trigger: String,
		conv_context: Dictionary = {}) -> void:
	is_conversation_active = false

	# 会話スレッドIDを全メッセージに付与
	var conv_id: int = _next_conversation_id
	_next_conversation_id += 1
	for msg: Dictionary in current_conversation:
		msg["conversation_id"] = conv_id

	# 会話ムードをログエントリに付与
	var conv_mood: Dictionary = conv_context.get("conversation_mood", {})
	for msg: Dictionary in current_conversation:
		if not conv_mood.is_empty():
			msg["conversation_mood"] = conv_mood.get("mood", "")
			msg["conversation_mood_intensity"] = conv_mood.get("intensity", 0.0)

	# 会話サマリーを生成してログエントリに付与
	var conv_summary: String = _generate_conversation_summary(pet1, pet2, trigger)
	for msg: Dictionary in current_conversation:
		msg["summary"] = conv_summary

	# ログに保存
	conversation_log.append_array(current_conversation)

	# コスト記録
	_record_conversation_cost(current_conversation.size())

	# 会話記憶: カウントとfavorite_partner更新
	_increment_conversation_count(pet1.pet_id, pet2.pet_id)
	_increment_conversation_count(pet2.pet_id, pet1.pet_id)

	# 言語進化システムに通知
	var dominant_emotion := _get_dominant_emotion(pet1)
	var emotion_intensity := _get_emotion_intensity(pet1)
	var avg_personality := {}
	for t_name in pet1.personality:
		avg_personality[t_name] = (pet1.personality[t_name] + pet2.personality[t_name]) / 2.0

	var lang_context := {
		"dominant_emotion": dominant_emotion,
		"emotion_intensity": emotion_intensity,
		"avg_personality": avg_personality,
		"environment": pet1.current_environment,
		"topics": GameManager.ecosystem.get_a2a_topics(),
		"trigger": trigger,
		"turn_count": current_conversation.size(),
	}
	GameManager.language_evolution.on_conversation_completed(lang_context)

	# 進化トリガー: 会話が進化カウントに寄与した場合にシグナル発行
	evolution_triggered_by_conversation.emit(trigger)

	# 言語進化処理（新表現・接尾辞抽出）
	_process_language_evolution(current_conversation)

	# Word teaching: pets teach each other vocabulary during conversations
	var teaching_1: Dictionary = _attempt_word_teaching(pet1, pet2)
	var teaching_2: Dictionary = _attempt_word_teaching(pet2, pet1)

	# Log word teaching metadata into conversation entries
	if not teaching_1.get("taught_words", []).is_empty():
		for msg: Dictionary in current_conversation:
			if msg.get("pet_id", -1) == pet1.pet_id:
				msg["word_teaching"] = teaching_1
				break
	if not teaching_2.get("taught_words", []).is_empty():
		for msg: Dictionary in current_conversation:
			if msg.get("pet_id", -1) == pet2.pet_id:
				msg["word_teaching"] = teaching_2
				break

	# 記憶に追加（BiologicalMemorySystem経由で自動的に海馬にも格納される）
	var summary := "Talked with %s about %s" % [pet2.pet_name, trigger]
	pet1.add_memory({"type": "conversation", "with": pet2.pet_id, "trigger": trigger,
		"turn_count": current_conversation.size()})
	pet2.add_memory({"type": "conversation", "with": pet1.pet_id, "trigger": trigger,
		"turn_count": current_conversation.size()})

	# 会話ハイライトを生物模倣記憶に登録
	_register_conversation_memory(pet1, current_conversation, pet2.pet_name)
	_register_conversation_memory(pet2, current_conversation, pet1.pet_name)

	# BiologicalMemorySystem: 会話中に言及された記憶をHebbian強化
	if GameManager.instance and GameManager.instance.biological_memory:
		var bio_mem: Node = GameManager.instance.biological_memory
		for mem in conv_context.get("bio_memories_1", []):
			bio_mem.strengthen_related_memories(pet1.pet_id, mem)
		for mem in conv_context.get("bio_memories_2", []):
			bio_mem.strengthen_related_memories(pet2.pet_id, mem)

	# PersistentField: 共有イベント記録 + 関係性スコア更新
	if GameManager.instance and GameManager.instance.persistent_field:
		var pf: Node = GameManager.instance.persistent_field
		pf.record_shared_event({
			"type": "a2a_conversation",
			"participants": [pet1.pet_id, pet2.pet_id],
			"trigger": trigger,
			"turn_count": current_conversation.size(),
			"environment": pet1.current_environment,
			"dominant_emotion": dominant_emotion,
		})
		# 会話すると関係性が微増（感情強度に応じたボーナス）
		var rel_boost: float = 0.02 + emotion_intensity * 0.03
		pf.update_relationship(pet1.pet_id, pet2.pet_id, rel_boost)

	# 関係性更新（会話品質 = 感情強度ベース）
	var conversation_quality: float = clampf(emotion_intensity, 0.1, 1.0)
	_update_relationship(pet1.pet_id, pet2.pet_id, conversation_quality)

	# 会話ハイライトスコアを計算して各メッセージに付与
	var highlight_data: Dictionary = _score_conversation(current_conversation, pet1, pet2)
	for msg: Dictionary in current_conversation:
		msg["highlight_score"] = highlight_data.get("score", 0.0)
		msg["highlight_type"] = highlight_data.get("highlight_type", "ordinary")
		msg["highlight_reason"] = highlight_data.get("highlight_reason", "")

	# PetBook投稿を生成（highlight_data利用のためスコアリング後に実行）
	var posts := _generate_conversation_posts(pet1, pet2, current_conversation, trigger, highlight_data)
	if GameManager.instance and GameManager.instance.has_method("queue_petbook_posts"):
		for post in posts:
			GameManager.instance.queue_petbook_posts(post)

	# 傍観者リアクション（3匹以上いる場合）
	_trigger_observer_reactions(pet1, pet2, dominant_emotion, current_conversation)

	conversation_ended.emit([pet1.pet_id, pet2.pet_id], summary)
	current_conversation = []


func _trigger_observer_reactions(pet1: PetEntity, pet2: PetEntity,
		dominant_emotion: String, conversation: Array[Dictionary]) -> void:
	## 会話に参加しなかったペットが傍観者として反応
	var all_pets: Array = GameManager.get_all_pets()
	var observers: Array[PetEntity] = []
	for pet: Variant in all_pets:
		if pet is PetEntity and pet.is_alive:
			if pet.pet_id != pet1.pet_id and pet.pet_id != pet2.pet_id:
				observers.append(pet)

	if observers.is_empty():
		return

	# 各傍観者に感情的影響を与える（間接的な感情伝染）
	for observer: PetEntity in observers:
		# 会話の感情が傍観者にも伝わる（弱い伝染）
		var contagion: float = 0.1
		if dominant_emotion != "neutral":
			GameManager.emotion_system.stimulate(observer, dominant_emotion, contagion, "observed_conversation")

		# 20%の確率で傍観者がテンプレートリアクションを生成
		if randf() < 0.2 and conversation.size() >= 2:
			var reaction: String = _generate_observer_reaction(observer, pet1, pet2, dominant_emotion)
			if not reaction.is_empty():
				var msg: Dictionary = {
					"pet_id": observer.pet_id,
					"pet_name": observer.pet_name,
					"message": reaction,
					"emotion": _get_dominant_emotion(observer),
					"is_template": true,
					"is_observer": true,
				}
				conversation_log.append(msg)
				conversation_message.emit(observer.pet_id, reaction, msg)


func _generate_observer_reaction(observer: PetEntity, pet1: PetEntity, pet2: PetEntity,
		emotion: String) -> String:
	## 傍観者のリアクションテンプレート
	var suffix: String = "-mii"
	if GameManager.language_evolution:
		var grammar: Dictionary = GameManager.language_evolution.get_current_grammar()
		var suffixes: Variant = grammar.get("suffixes", [])
		if suffixes is Array and not suffixes.is_empty():
			suffix = str(suffixes[randi() % suffixes.size()])
		elif suffixes is Dictionary and not suffixes.is_empty():
			suffix = str(suffixes.values()[randi() % suffixes.size()])

	var templates: Array[String] = []
	match emotion:
		"joy":
			templates = [
				"*%s watches %s and %s laughing%s* So happy%s!" % [observer.pet_name, pet1.pet_name, pet2.pet_name, suffix, suffix],
				"*%s joins in the laughter from afar%s*" % [observer.pet_name, suffix],
			]
		"sadness":
			templates = [
				"*%s overhears%s* ...are they okay%s?" % [observer.pet_name, suffix, suffix],
				"*%s sighs quietly%s watching from a distance%s*" % [observer.pet_name, suffix, suffix],
			]
		"love":
			templates = [
				"*%s smiles seeing %s and %s together%s*" % [observer.pet_name, pet1.pet_name, pet2.pet_name, suffix],
			]
		_:
			templates = [
				"*%s glances over curiously%s* Hmm%s..." % [observer.pet_name, suffix, suffix],
			]

	if templates.is_empty():
		return ""
	return templates[randi() % templates.size()]


func _get_dominant_emotion(pet: PetEntity) -> String:
	var max_emotion := "neutral"
	var max_val := 0.15
	for emotion in pet.emotions:
		if pet.emotions[emotion] > max_val:
			max_val = pet.emotions[emotion]
			max_emotion = emotion
	return max_emotion


# === Conversation Reaction System ===
func _generate_reaction(listener: PetEntity, _message_text: String) -> Dictionary:
	## Generate an emoji-like reaction from the listener based on personality and emotion.
	## Returns empty Dictionary if no reaction (60% of time).
	## 100% local/procedural — no API calls.
	if randf() > 0.4:
		return {}

	var emotion: String = _get_dominant_emotion(listener)
	var emoji: String = ""

	match emotion:
		"joy":
			emoji = ["😄", "⚡"][randi() % 2]
		"excitement":
			emoji = ["⚡", "😄"][randi() % 2]
		"love":
			emoji = ["♥", "🥰"][randi() % 2]
		"sadness":
			emoji = "😢"
		"fear":
			emoji = "😨"
		_:
			# neutral / curious / other
			emoji = ["🤔", "✨"][randi() % 2]

	# Personality influence: curious pets lean toward 🤔/✨, brave pets toward ⚡
	var personality: Dictionary = listener.personality
	if personality.get("curiosity", 0.0) > 0.6 and randf() < 0.4:
		emoji = ["🤔", "✨"][randi() % 2]
	elif personality.get("bravery", 0.0) > 0.6 and randf() < 0.3:
		emoji = "⚡"
	elif personality.get("gentleness", 0.0) > 0.6 and randf() < 0.3:
		emoji = ["♥", "✨"][randi() % 2]

	return {
		"reactor_id": listener.pet_id,
		"reactor_name": listener.pet_name,
		"emoji": emoji,
	}


func _attach_reaction_to_message(msg: Dictionary, listener: PetEntity) -> void:
	## Check if listener reacts to the message and attach reaction data.
	var reaction: Dictionary = _generate_reaction(listener, msg.get("message", ""))
	if not msg.has("reactions"):
		msg["reactions"] = [] as Array[Dictionary]
	if reaction.is_empty():
		return
	var reactions_arr: Array = msg["reactions"]
	reactions_arr.append(reaction)


# === Relationship Dynamics ===
func _get_relationship_key(pet1_id: int, pet2_id: int) -> String:
	## ソート済みペアキーを生成
	return "%d_%d" % [mini(pet1_id, pet2_id), maxi(pet1_id, pet2_id)]


func _get_or_create_relationship(pet1_id: int, pet2_id: int) -> Dictionary:
	## 関係データを取得。存在しなければ初期値で作成
	var key: String = _get_relationship_key(pet1_id, pet2_id)
	if not pet_relationships.has(key):
		pet_relationships[key] = {
			"affinity": 0.3,
			"conversations_together": 0,
			"shared_words": [],
			"relationship_type": "acquaintances",
		}
	return pet_relationships[key]


func _update_relationship(pet1_id: int, pet2_id: int, conversation_quality: float) -> void:
	## 会話完了時に関係性を更新
	var key: String = _get_relationship_key(pet1_id, pet2_id)
	var rel: Dictionary = _get_or_create_relationship(pet1_id, pet2_id)

	# 親密度を会話品質に応じて増加
	rel["affinity"] = clampf(rel["affinity"] + 0.05 * conversation_quality, 0.0, 1.0)
	rel["conversations_together"] = rel.get("conversations_together", 0) + 1

	# 共有された独自語彙を追跡
	if GameManager.instance and GameManager.instance.original_language:
		var vocab: Dictionary = GameManager.instance.original_language.get_full_vocabulary()
		for vocab_key: String in vocab:
			var entry: Dictionary = vocab[vocab_key]
			var ai_term: String = entry.get("ai_term", "")
			if ai_term.is_empty():
				continue
			# 会話中に使われた語彙をチェック
			var used_in_conv: bool = false
			for msg: Dictionary in current_conversation:
				if msg.get("message", "").containsn(ai_term):
					used_in_conv = true
					break
			if used_in_conv:
				var shared: Array = rel.get("shared_words", [])
				if ai_term not in shared:
					shared.append(ai_term)
					# 最大10語まで保持
					if shared.size() > 10:
						shared = shared.slice(-10)
					rel["shared_words"] = shared

	# 関係タイプを親密度閾値に基づいて更新
	var old_type: String = rel.get("relationship_type", "strangers")
	var affinity: float = rel["affinity"]
	var new_type: String = old_type

	if affinity < 0.2:
		new_type = "strangers"
	elif affinity < 0.4:
		new_type = "acquaintances"
	elif affinity < 0.6:
		new_type = "friends"
	elif affinity < 0.8:
		new_type = "close_friends"
	else:
		# >=0.8: ランダムで best_friends or rivals
		if old_type == "best_friends" or old_type == "rivals":
			new_type = old_type  # 一度決まったら維持
		else:
			new_type = "best_friends" if randf() < 0.7 else "rivals"

	rel["relationship_type"] = new_type
	pet_relationships[key] = rel

	if new_type != old_type:
		relationship_changed.emit(pet1_id, pet2_id, new_type)
		print("[AtoA] Relationship changed: %d & %d → %s (affinity: %.2f)" % [pet1_id, pet2_id, new_type, affinity])


func _get_relationship_context(pet1_id: int, pet2_id: int) -> String:
	## 会話プロンプト用の関係性コンテキスト（1 short phrase, token-lean）
	var key: String = _get_relationship_key(pet1_id, pet2_id)
	if not pet_relationships.has(key):
		return ""

	var rel: Dictionary = pet_relationships[key]
	var rel_type: String = rel.get("relationship_type", "strangers")
	var conv_count: int = rel.get("conversations_together", 0)

	if conv_count > 1:
		return "%s (%d chats)." % [rel_type.replace("_", " "), conv_count]
	return "%s." % rel_type.replace("_", " ")


# === 会話ハイライトシステム ===
func _score_conversation(messages: Array[Dictionary], pet1: PetEntity, pet2: PetEntity) -> Dictionary:
	## 会話をスコアリングしてハイライト種別と理由を返す（100%ローカル/手続き的）
	var score: float = 0.0
	var reasons: Array[String] = []

	# 1. 発明語の使用数（+10 each, max 30）
	var invented_word_count: int = 0
	var first_invented_word: String = ""
	if GameManager.instance and GameManager.instance.original_language:
		var vocab: Dictionary = GameManager.instance.original_language.get_full_vocabulary()
		for msg: Dictionary in messages:
			var text: String = msg.get("message", "")
			for human_word: String in vocab:
				var ai_term: String = vocab[human_word].get("ai_term", "")
				if not ai_term.is_empty() and text.containsn(ai_term):
					invented_word_count += 1
					if first_invented_word.is_empty():
						first_invented_word = ai_term
	var invented_score: float = minf(float(invented_word_count) * 10.0, 30.0)
	score += invented_score
	if invented_word_count > 0:
		reasons.append("Used %d invented word(s) including '%s'" % [invented_word_count, first_invented_word])

	# 2. 言語コンプライアンス平均（+20 if > 70%）
	var compliance_total: float = 0.0
	var compliance_count: int = 0
	for msg: Dictionary in messages:
		var comp: Dictionary = msg.get("language_compliance", {})
		if comp.has("score"):
			compliance_total += comp["score"]
			compliance_count += 1
	var avg_compliance: float = compliance_total / float(maxi(compliance_count, 1))
	if avg_compliance > 0.7:
		score += 20.0
		reasons.append("High language compliance (%.0f%%)" % (avg_compliance * 100.0))

	# 3. 参加者の関係レベル（+10 friends, +20 close_friends/best_friends）
	var rel: Dictionary = _get_or_create_relationship(pet1.pet_id, pet2.pet_id)
	var rel_type: String = rel.get("relationship_type", "strangers")
	match rel_type:
		"friends":
			score += 10.0
		"close_friends", "best_friends":
			score += 20.0
			reasons.append("Deep bond between %s" % rel_type.replace("_", " "))

	# 4. 単語教示が行われた（+15）
	var word_teaching_occurred: bool = false
	for msg: Dictionary in messages:
		if msg.has("word_teaching"):
			var wt: Dictionary = msg["word_teaching"]
			if not wt.get("taught_words", []).is_empty():
				word_teaching_occurred = true
				break
	if word_teaching_occurred:
		score += 15.0
		reasons.append("Word teaching occurred")

	# 5. 高い感情強度（+10 if avg > 0.5）
	var emotion_total: float = 0.0
	var emotion_count: int = 0
	for msg: Dictionary in messages:
		emotion_total += msg.get("emotion_intensity", 0.0)
		emotion_count += 1
	var avg_emotion: float = emotion_total / float(maxi(emotion_count, 1))
	if avg_emotion > 0.5:
		score += 10.0
		reasons.append("High emotion intensity (%.1f)" % avg_emotion)

	# 6. リアクション数（+2 each, max 10）
	var reaction_count: int = 0
	for msg: Dictionary in messages:
		var reactions: Array = msg.get("reactions", [])
		reaction_count += reactions.size()
	var reaction_score: float = minf(float(reaction_count) * 2.0, 10.0)
	score += reaction_score
	if reaction_count > 0:
		reasons.append("%d reaction(s)" % reaction_count)

	# スコアを0-100にクランプ
	score = clampf(score, 0.0, 100.0)

	# ハイライト種別の決定
	var highlight_type: String = "ordinary"
	if score > 60.0:
		highlight_type = "landmark"
	elif score > 40.0:
		highlight_type = "notable"

	# ハイライト理由の生成
	var highlight_reason: String = ""
	if not reasons.is_empty():
		highlight_reason = reasons[0]
	else:
		highlight_reason = "Routine conversation"

	return {
		"score": score,
		"highlight_type": highlight_type,
		"highlight_reason": highlight_reason,
		"reasons": reasons,
	}


func get_conversation_highlights(limit: int = 5) -> Array[Dictionary]:
	## 会話ログからスコアの高い上位N件の会話を返す
	## 各エントリはユニークな会話（同一 summary を持つメッセージ群）を1件として集約
	var seen_summaries: Dictionary = {}
	var scored_entries: Array[Dictionary] = []

	# ログを逆順に走査してユニークな会話を収集
	for i: int in range(conversation_log.size() - 1, -1, -1):
		var entry: Dictionary = conversation_log[i]
		var h_score: float = entry.get("highlight_score", 0.0)
		if h_score <= 0.0:
			continue
		var summary: String = entry.get("summary", "")
		if summary.is_empty() or seen_summaries.has(summary):
			continue
		seen_summaries[summary] = true
		scored_entries.append({
			"summary": summary,
			"score": h_score,
			"highlight_type": entry.get("highlight_type", "ordinary"),
			"highlight_reason": entry.get("highlight_reason", ""),
			"pet_name": entry.get("pet_name", ""),
			"pet_id": entry.get("pet_id", -1),
			"emotion": entry.get("emotion", "neutral"),
			"conversation_mood": entry.get("conversation_mood", ""),
			"turn": entry.get("turn", 0),
		})

	# スコア降順でソート
	scored_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["score"] > b["score"]
	)

	# 上位N件を返す
	return scored_entries.slice(0, limit) as Array[Dictionary]


# === セーブ・ロード（永続化） ===
func to_dict() -> Dictionary:
	## 会話システムの状態を保存
	return {
		"conversation_log": conversation_log.slice(-50),  # 最新50会話のみ保存
		"daily_cost": daily_conversation_cost,
		"daily_count": daily_conversation_count,
		"daily_event_count": daily_event_conversation_count,
		"last_daily_reset": last_daily_reset,
		"pet_relationships": pet_relationships,
		"conversation_memory": conversation_memory,
		"next_conversation_id": _next_conversation_id,
	}


func from_dict(data: Dictionary) -> void:
	## 保存されたデータを復元
	if data.has("conversation_log"):
		conversation_log = data["conversation_log"]
	if data.has("daily_cost"):
		daily_conversation_cost = data["daily_cost"]
	if data.has("daily_count"):
		daily_conversation_count = data["daily_count"]
	if data.has("last_daily_reset"):
		last_daily_reset = data["last_daily_reset"]
	if data.has("pet_relationships"):
		pet_relationships = data["pet_relationships"]
	conversation_memory = data.get("conversation_memory", {})
	_next_conversation_id = data.get("next_conversation_id", 0)
	daily_event_conversation_count = data.get("daily_event_count", 0)

	# 日付が変わっていればリセット
	var current_day := int(Time.get_unix_time_from_system() / 86400)
	if current_day != last_daily_reset:
		_on_day_change()


# === イベントハンドラ ===
func _on_climate_event(event_type: String, _intensity: float) -> void:
	# 気候イベントで自動会話をトリガー
	conversation_timer = auto_conversation_interval - 10.0  # すぐに会話が始まりやすくなる


func _on_language_evolution(event_type: String, _data: Dictionary) -> void:
	# 言語進化時にもリアクション会話のチャンス
	if randf() < 0.3:
		conversation_timer = auto_conversation_interval - 5.0


# === 手動会話トリガー（UI用） ===
func trigger_conversation_now() -> void:
	## プレイヤーが手動で会話をトリガーする
	## 感情閾値を無視して即座に会話を開始
	if is_conversation_active:
		push_warning("[AtoA] Conversation already in progress")
		return

	var pets := GameManager.get_all_pets()
	var alive_pets: Array[PetEntity] = []
	for pet in pets:
		if pet.is_alive:
			alive_pets.append(pet)

	if alive_pets.size() < 2:
		push_warning("[AtoA] Need at least 2 alive pets for conversation")
		return

	# グループ会話を試行（手動でも20%の確率）
	var group_pets: Array[PetEntity] = _select_group_participants(alive_pets)
	if group_pets.size() == 3:
		if not _check_budget():
			print("[AtoA] Manual trigger: budget exhausted — using group template")
			_run_group_template_conversation(group_pets, "player_triggered")
			return
		print("[AtoA] Manual trigger: starting group conversation with %s, %s, %s" % [
			group_pets[0].pet_name, group_pets[1].pet_name, group_pets[2].pet_name])
		await start_group_conversation(group_pets, "player_triggered")
		return

	# 感情が最も高い2匹を選択（閾値なし）
	alive_pets.sort_custom(func(a: Variant, b: Variant) -> bool:
		return _get_emotion_intensity(a) > _get_emotion_intensity(b)
	)

	var pet1: PetEntity = alive_pets[0]
	var pet2: PetEntity = alive_pets[1]

	# バジェットチェック — 超過時はテンプレート
	if not _check_budget():
		print("[AtoA] Manual trigger: budget exhausted — using template")
		_run_template_conversation(pet1, pet2, "player_triggered")
		return

	print("[AtoA] Manual trigger: starting conversation between %s and %s" % [pet1.pet_name, pet2.pet_name])
	await start_conversation(pet1, pet2, "player_triggered")


# === イベント会話トリガー（外部システムから呼び出し） ===
func trigger_event_conversation(event_type: String, context: Dictionary = {}) -> void:
	## 外部システム（進化・誕生・死亡等）からのイベント会話をトリガー
	## バイパス: タイマーチェック不要。制約: 日次イベント会話上限を尊重
	if daily_event_conversation_count >= MAX_DAILY_EVENT_CONVERSATIONS:
		print("[AtoA] Event conversation skipped: daily event limit reached (%d/%d)" % [
			daily_event_conversation_count, MAX_DAILY_EVENT_CONVERSATIONS])
		return

	if not EVENT_CONVERSATION_TEMPLATES.has(event_type):
		push_warning("[AtoA] Unknown event type for conversation: %s" % event_type)
		return

	# 生存ペットから2匹選ぶ（会話の観察者として）
	var pets: Array = GameManager.get_all_pets()
	var alive_pets: Array[PetEntity] = []
	for pet: PetEntity in pets:
		if pet.is_alive:
			alive_pets.append(pet)

	if alive_pets.size() < 1:
		return

	# 文法情報を取得して接尾辞を選択
	var grammar: Dictionary = GameManager.language_evolution.get_current_grammar()
	var suffix_list: Array = []
	var suffixes_raw: Variant = grammar.get("suffixes", [])
	if suffixes_raw is Array:
		suffix_list = suffixes_raw
	elif suffixes_raw is Dictionary:
		for key: String in suffixes_raw:
			suffix_list.append(str(suffixes_raw[key]))
	var selected_suffix: String = suffix_list[randi() % suffix_list.size()] if not suffix_list.is_empty() else "-mii"

	# テンプレートリストからランダムに1つ選択
	var templates: Array = EVENT_CONVERSATION_TEMPLATES[event_type]
	var template_text: String = templates[randi() % templates.size()]

	# コンテキストから置換用の値を取得
	var pet_name: String = context.get("pet_name", "someone")
	var count_str: String = str(context.get("count", 0))

	# テンプレート置換
	var message: String = template_text
	message = message.replace("{suffix}", selected_suffix)
	message = message.replace("{pet_name}", pet_name)
	message = message.replace("{count}", count_str)

	# 独自語彙を注入（ステージ1+）
	var lang_stage: int = 0
	if GameManager.instance and GameManager.instance.original_language:
		var stage_info: Dictionary = GameManager.instance.original_language.get_language_stage()
		lang_stage = stage_info.get("stage", 0)
	if lang_stage >= 1 and GameManager.instance and GameManager.instance.original_language:
		var vocab: Dictionary = GameManager.instance.original_language.get_full_vocabulary()
		for key: String in vocab:
			var entry: Dictionary = vocab[key]
			if entry.get("strength", 0.0) > 0.3:
				var human_word: String = entry.get("human_word", "")
				var ai_term: String = entry.get("ai_term", "")
				if not human_word.is_empty() and message.containsn(human_word) and randf() < 0.5:
					message = message.replacen(human_word, ai_term)

	# 話し手をランダムに選択
	var speaker: PetEntity = alive_pets[randi() % alive_pets.size()]

	# メッセージ構築と送信
	var msg: Dictionary = {
		"pet_id": speaker.pet_id,
		"pet_name": speaker.pet_name,
		"message": message,
		"emotion": _get_dominant_emotion(speaker),
		"is_template": true,
		"is_event": true,
		"event_type": event_type,
		"turn": 0,
	}
	conversation_log.append(msg)
	conversation_message.emit(speaker.pet_id, message, msg)
	daily_event_conversation_count += 1
	print("[AtoA] Event conversation triggered: %s (%d/%d daily)" % [
		event_type, daily_event_conversation_count, MAX_DAILY_EVENT_CONVERSATIONS])


func get_conversation_status() -> Dictionary:
	## UI表示用のステータス情報を返す
	# 平均コンプライアンススコアを計算
	var avg_compliance: float = 0.0
	var compliance_count: int = 0
	for entry: Dictionary in conversation_log.slice(-20):
		var comp: Dictionary = entry.get("language_compliance", {})
		if comp.has("score"):
			avg_compliance += comp["score"]
			compliance_count += 1
	if compliance_count > 0:
		avg_compliance /= float(compliance_count)

	return {
		"is_active": is_conversation_active,
		"budget_remaining": DAILY_CONVERSATION_BUDGET - daily_conversation_cost,
		"daily_count": daily_conversation_count,
		"max_daily": MAX_DAILY_CONVERSATIONS,
		"total_conversations": conversation_log.size(),
		"timer_progress": conversation_timer / auto_conversation_interval,
		"avg_compliance": avg_compliance,
		"daily_event_count": daily_event_conversation_count,
		"max_daily_events": MAX_DAILY_EVENT_CONVERSATIONS,
	}
