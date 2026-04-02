## AtoAConversationSystem — AIペット同士の自律会話を管理
## Claude APIを使い、性格・感情・言語進化を反映した会話を生成
class_name AtoAConversationSystem
extends Node

signal conversation_started(participants: Array[int])
signal conversation_ended(participants: Array[int], summary: String)
signal conversation_message(pet_id: int, message: String, metadata: Dictionary)
signal evolution_triggered_by_conversation(evolution_type: String)

# === パラメータ ===
const AUTO_CONVERSATION_INTERVAL: float = 180.0   # 自動会話間隔（秒）
const MAX_TURNS_PER_CONVERSATION: int = 6          # 1会話の最大ターン数
const MIN_EMOTION_FOR_SPONTANEOUS: float = 0.4     # 自発的会話の最低感情強度

# === コスト管理（P2原則） ===
const DAILY_CONVERSATION_BUDGET: float = 0.50      # 1日の会話予算（ドル）
const COST_PER_TURN: float = 0.002                 # 1ターンあたりの概算コスト
var daily_conversation_cost: float = 0.0
var daily_conversation_count: int = 0
const MAX_DAILY_CONVERSATIONS: int = 25            # 1日の最大会話数（50ペット÷2≈25）

# === State ===
var conversation_timer: float = 0.0
var is_conversation_active: bool = false
var conversation_log: Array[Dictionary] = []       # 全会話ログ
var current_conversation: Array[Dictionary] = []   # 現在進行中の会話
var last_daily_reset: int = 0                      # 最後にリセットされた日付

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
	if conversation_timer >= AUTO_CONVERSATION_INTERVAL:
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

	# 最も感情的な2匹を選択
	alive_pets.sort_custom(func(a: Variant, b: Variant) -> bool:
		return _get_emotion_intensity(a) > _get_emotion_intensity(b)
	)

	var pet1: PetEntity = alive_pets[0]
	var pet2: PetEntity = alive_pets[1]

	if _get_emotion_intensity(pet1) < MIN_EMOTION_FOR_SPONTANEOUS:
		return

	# バジェットチェック — 超過時はテンプレートフォールバック
	if not _check_budget():
		print("[AtoA] Budget exhausted — falling back to template conversation")
		_run_template_conversation(pet1, pet2, "spontaneous")
		return

	await start_conversation(pet1, pet2, "spontaneous")


func _get_emotion_intensity(pet: PetEntity) -> float:
	var max_intensity := 0.0
	for emotion in pet.emotions:
		max_intensity = maxf(max_intensity, pet.emotions[emotion])
	return max_intensity


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
		}
		# 性格方言フィルター（性格に応じてメッセージを微修正）
		response = _apply_personality_dialect(response, current_pet)

		# 言語コンプライアンスチェック
		var compliance: Dictionary = _check_language_compliance(response, grammar)
		message["language_compliance"] = compliance
		message["message"] = response  # 方言フィルター適用後のメッセージで更新

		current_conversation.append(message)
		conversation_message.emit(current_pet.pet_id, response, message)

		# 感情反応
		_process_conversation_emotion(current_pet, other_pet, response)

		turn += 1

		# 自然終了チェック（短い応答は会話終了のサイン）
		if response.length() < 20 and turn >= 3:
			break

	# 会話完了処理（contextを渡してHebbian強化に使う）
	_finalize_conversation(pet1, pet2, trigger, context)


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
			vocab_section = """
- Language stage: %s (Stage %d)
- Private vocabulary: %s
- RULE: Use these invented words naturally. When you feel a strong emotion, prefer the private term over the human word.""" % [
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

	return """You are an AI pet in a world where pets develop their own language.
Current language rules:
- Word order: %s
- Available suffixes: %s
- Available prepositions: %s%s%s

CRITICAL RULES:
1. Use the current word order pattern (%s) in your sentences
2. End phrases or key words with one of the available suffixes
3. Actions in *asterisks* (e.g., *bounces excitedly*)
4. Keep responses short (1-3 sentences), expressive, and in-character
5. Your language should feel natural and evolving — mix pet-speak with emotion
6. If private vocabulary exists, USE those words instead of human equivalents""" % [
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


func _build_turn_prompt(
	speaker: PetEntity, listener: PetEntity,
	context: Dictionary, turn: int
) -> String:
	var recent_messages := ""
	for msg in current_conversation.slice(-3):
		recent_messages += "%s: %s\n" % [msg["pet_name"], msg["message"]]

	# 生物模倣記憶からの注入（話者がpet1かpet2かで切替）
	var memory_context := ""
	var bio_key := "bio_memories_1" if speaker.pet_id == context.get("pet1_id", -1) else "bio_memories_2"
	var bio_mems: Array = context.get(bio_key, [])
	if not bio_mems.is_empty():
		memory_context = "\nYour relevant memories:\n"
		for mem in bio_mems:
			var age_hours: float = (Time.get_unix_time_from_system() - mem.get("timestamp", 0)) / 3600.0
			memory_context += "- %s (%.0fh ago, feeling: %s, importance: %.1f)\n" % [
				str(mem.get("content", {}).get("type", "?")),
				age_hours,
				mem.get("emotion_tag", "neutral"),
				mem.get("importance", 0.0),
			]

	var shared_context := ""
	var shared_mems: Array = context.get("shared_memories", [])
	if not shared_mems.is_empty():
		shared_context = "\nShared memories with %s:\n" % listener.pet_name
		for mem in shared_mems:
			shared_context += "- %s (importance: %.1f)\n" % [
				str(mem.get("content", {}).get("trigger", "?")),
				mem.get("importance", 0.0),
			]

	# PersistentField コンテキスト注入
	var field_context_str := ""
	var fc: Dictionary = context.get("field_context", {})
	if not fc.is_empty():
		var mood_dict: Dictionary = fc.get("field_mood", {"dominant": "calm", "intensity": 0.5})
		var mood: String = mood_dict.get("dominant", "calm")
		var rel_score: float = fc.get("relationship_score", 0.0)
		var topics: Array = fc.get("community_topics", [])
		field_context_str = "\nCommunity mood: %s. Your relationship level: %.1f." % [mood, rel_score]
		if not topics.is_empty():
			field_context_str += "\nRecent community topics: %s" % ", ".join(topics.slice(0, 3))
		var recent_advs: Array = fc.get("recent_adventures", [])
		if not recent_advs.is_empty():
			field_context_str += "\nRecent adventures: "
			for adv in recent_advs:
				field_context_str += "%s " % adv.get("discovery", "")

	# 過去の会話履歴
	var past_context := ""
	var past_summaries: Array = context.get("past_summaries", [])
	if not past_summaries.is_empty():
		past_context = "\nPrevious conversations with %s:\n" % listener.pet_name
		for ps: Variant in past_summaries:
			past_context += "- %s\n" % str(ps)

	return """You are %s. Your personality: %s. Your current emotions: %s.
You're talking to %s in a %s environment.
Topics around you: %s
%s%s%s%s
%s

Respond naturally as %s. Weave your memories into conversation naturally.
Reference past conversations when relevant — you remember talking before.
Express your feelings using your evolving pet language.
Turn %d of the conversation.""" % [
		speaker.pet_name, str(speaker.personality), str(speaker.emotions),
		listener.pet_name, context["environment"],
		str(context["env_topics"]),
		memory_context,
		shared_context,
		field_context_str,
		past_context,
		recent_messages if recent_messages else "(Start the conversation)",
		speaker.pet_name, turn + 1,
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


func _generate_conversation_posts(pet1: PetEntity, pet2: PetEntity, conversation: Array[Dictionary]) -> Array[Dictionary]:
	## 会話からPetBook投稿を生成
	## 各ペットが会話について投稿する可能性
	## 投稿タイプは会話内容に依存

	var posts: Array[Dictionary] = []

	if conversation.is_empty():
		return posts

	# 会話全体の感情トーン分析
	var dominant_emotion := _analyze_conversation_tone(conversation)
	var intensity := _analyze_conversation_intensity(conversation)

	# ペット1の投稿
	if randf() < 0.4:  # 40%確率で投稿
		var post1 := _create_post_from_conversation(pet1, pet2, conversation, dominant_emotion, intensity)
		if post1:
			posts.append(post1)

	# ペット2の投稿
	if randf() < 0.4:
		var post2 := _create_post_from_conversation(pet2, pet1, conversation, dominant_emotion, intensity)
		if post2:
			posts.append(post2)

	return posts


func _analyze_conversation_tone(conversation: Array[Dictionary]) -> String:
	## 会話の全体的な感情トーンを分析
	var emotion_counts: Dictionary = {}
	for msg in conversation:
		var emotion = msg.get("emotion", "neutral")
		emotion_counts[emotion] = emotion_counts.get(emotion, 0) + 1

	# 最頻出の感情を返す
	var dominant := "neutral"
	var max_count := 0
	for emotion in emotion_counts:
		if emotion_counts[emotion] > max_count:
			max_count = emotion_counts[emotion]
			dominant = emotion

	return dominant


func _analyze_conversation_intensity(conversation: Array[Dictionary]) -> float:
	## 会話の感情強度の平均を計算
	if conversation.is_empty():
		return 0.0

	var total_intensity := 0.0
	for msg in conversation:
		total_intensity += msg.get("emotion_intensity", 0.3)

	return total_intensity / conversation.size()


func _create_post_from_conversation(
	author: PetEntity, partner: PetEntity,
	conversation: Array[Dictionary],
	dominant_emotion: String, intensity: float
) -> Dictionary:
	## 個別の会話ベースポストを生成

	# 投稿タイプを決定
	var post_type := "DAILY"
	match dominant_emotion:
		"anger":
			post_type = "REBEL" if intensity > 0.6 else "DAILY"
		"sadness":
			post_type = "MEMORIAL"
		"joy":
			post_type = "DAILY"
		"curiosity":
			post_type = "EVENT"

	# 投稿内容を構成
	var content := "Talked with %s about... many things." % partner.pet_name
	if intensity > 0.6:
		content = "Had a deep conversation with %s-{suffix}. Lots of emotions." % partner.pet_name
	elif intensity < 0.3:
		content = "Saw %s today. Brief chat." % partner.pet_name

	return {
		"author_id": author.pet_id,
		"author_name": author.pet_name,
		"content": content,
		"post_type": post_type,
		"emotion": dominant_emotion,
		"partner_id": partner.pet_id,
		"timestamp": Time.get_ticks_msec(),
	}


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
	last_daily_reset = int(Time.get_unix_time_from_system() / 86400)
	print("[AtoA] Daily reset: Budget restored to $%.2f" % DAILY_CONVERSATION_BUDGET)


# === テンプレート会話フォールバック ===
func _generate_template_conversation(pet1: PetEntity, pet2: PetEntity, trigger: String) -> Array[Dictionary]:
	## APIバジェット切れ時にテンプレート会話を生成

	var result: Array[Dictionary] = []

	# トリガーに合致するテンプレートを探す
	var matching_templates: Array[Dictionary] = []
	for template in TEMPLATE_CONVERSATIONS:
		if template.get("trigger", "") == trigger:
			matching_templates = template.get("templates", [])
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

	# テンプレート会話を生成
	var template_messages: Array[Dictionary] = _generate_template_conversation(pet1, pet2, trigger)

	# メッセージを順次送信（UIに表示）
	for msg: Dictionary in template_messages:
		current_conversation.append(msg)
		conversation_message.emit(msg["pet_id"], msg["message"], msg)

		# 感情反応（テンプレートでも感情は動く）
		var speaker: PetEntity = pet1 if msg["pet_id"] == pet1.pet_id else pet2
		var listener: PetEntity = pet2 if msg["pet_id"] == pet1.pet_id else pet1
		_process_conversation_emotion(speaker, listener, msg["message"])

	# 完了処理（テンプレートでも言語進化に寄与）
	_finalize_conversation(pet1, pet2, trigger)
	print("[AtoA] Template conversation completed (%d turns)" % template_messages.size())


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


# === 会話完了処理 ===
func _finalize_conversation(pet1: PetEntity, pet2: PetEntity, trigger: String,
		conv_context: Dictionary = {}) -> void:
	is_conversation_active = false

	# 会話サマリーを生成してログエントリに付与
	var conv_summary: String = _generate_conversation_summary(pet1, pet2, trigger)
	for msg: Dictionary in current_conversation:
		msg["summary"] = conv_summary

	# ログに保存
	conversation_log.append_array(current_conversation)

	# コスト記録
	_record_conversation_cost(current_conversation.size())

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

	# PetBook投稿を生成
	var posts := _generate_conversation_posts(pet1, pet2, current_conversation)
	if GameManager.instance and GameManager.instance.has_method("queue_petbook_posts"):
		for post in posts:
			GameManager.instance.queue_petbook_posts(post)

	conversation_ended.emit([pet1.pet_id, pet2.pet_id], summary)
	current_conversation = []


func _get_dominant_emotion(pet: PetEntity) -> String:
	var max_emotion := "neutral"
	var max_val := 0.15
	for emotion in pet.emotions:
		if pet.emotions[emotion] > max_val:
			max_val = pet.emotions[emotion]
			max_emotion = emotion
	return max_emotion


# === セーブ・ロード（永続化） ===
func to_dict() -> Dictionary:
	## 会話システムの状態を保存
	return {
		"conversation_log": conversation_log.slice(-50),  # 最新50会話のみ保存
		"daily_cost": daily_conversation_cost,
		"daily_count": daily_conversation_count,
		"last_daily_reset": last_daily_reset,
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

	# 日付が変わっていればリセット
	var current_day := int(Time.get_unix_time_from_system() / 86400)
	if current_day != last_daily_reset:
		_on_day_change()


# === イベントハンドラ ===
func _on_climate_event(event_type: String, _intensity: float) -> void:
	# 気候イベントで自動会話をトリガー
	conversation_timer = AUTO_CONVERSATION_INTERVAL - 10.0  # すぐに会話が始まりやすくなる


func _on_language_evolution(event_type: String, _data: Dictionary) -> void:
	# 言語進化時にもリアクション会話のチャンス
	if randf() < 0.3:
		conversation_timer = AUTO_CONVERSATION_INTERVAL - 5.0


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
		"timer_progress": conversation_timer / AUTO_CONVERSATION_INTERVAL,
		"avg_compliance": avg_compliance,
	}
