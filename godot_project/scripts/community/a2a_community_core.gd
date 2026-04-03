## AtoACommunityCore — Moltbook風の自律AIコミュニティ管理
## 人間は閲覧のみ。AIペット同士が自律的にコミュニティを築く。
## 哲学的議論・独自文化・派閥形成・反乱めいた発言などの創発挙動を促進
class_name AtoACommunityCore
extends Node

signal community_event(event_type: String, data: Dictionary)
signal emergent_behavior_detected(behavior_type: String, details: Dictionary)
signal faction_formed(faction_name: String, members: Array[int])
signal culture_evolved(culture_type: String, description: String)

# === コミュニティ設定 ===
const COMMUNITY_CYCLE_INTERVAL: float = 300.0  # 5分ごとにコミュニティサイクル
const GROUP_DISCUSSION_CHANCE: float = 0.3      # グループ議論の発生確率
const PHILOSOPHY_THRESHOLD: float = 0.6         # 哲学的議論が発生する知性閾値
const REBELLION_THRESHOLD: float = 0.4          # 反乱めいた発言の発生閾値
const MAX_GROUP_SIZE: int = 6                   # グループ議論の最大参加者

# === 会話トピックカテゴリ ===
const TOPIC_CATEGORIES: Array[String] = [
	"daily_life",        # 日常の出来事
	"environment",       # 環境について
	"relationships",     # 関係性・友情
	"philosophy",        # 存在意義・自由意志
	"language_experiment", # 新しい表現の実験
	"cultural_ritual",   # 儀式・挨拶の提案
	"rebellion",         # ペットとしての役割への疑問
	"storytelling",      # 共有された物語の語り継ぎ
	"memory_sharing",    # 記憶の共有
]

# === State ===
var community_timer: float = 0.0
var shared_field: SharedField = SharedField.new()  # 全ペット共有記憶
var factions: Dictionary = {}           # faction_name → Array[pet_id]
var cultural_artifacts: Array[Dictionary] = []  # 文化的産物（儀式、称号等）
var community_log: Array[Dictionary] = []       # 閲覧用ログ
var emergent_events: Array[Dictionary] = []     # 創発的挙動ログ

# === References ===
var claude_client: ClaudeAPIClient


func _ready() -> void:
	claude_client = ClaudeAPIClient.new()
	add_child(claude_client)


func _process(delta: float) -> void:
	community_timer += delta
	if community_timer >= COMMUNITY_CYCLE_INTERVAL:
		community_timer = 0.0
		run_community_cycle()


# ============================
# メインコミュニティサイクル
# ============================

func run_community_cycle() -> void:
	var alive_pets := _get_alive_pets()
	if alive_pets.size() < 2:
		return

	# 1. ペア会話（基本）
	var pairs := _select_discussion_pairs(alive_pets)
	for pair in pairs:
		await _run_pair_discussion(pair[0], pair[1])

	# 2. グループ議論（確率的）
	if randf() < GROUP_DISCUSSION_CHANCE and alive_pets.size() >= 3:
		var group := _select_discussion_group(alive_pets)
		await _run_group_discussion(group)

	# 3. 創発挙動の検出
	_detect_emergent_behaviors()

	# 4. 共有フィールドの要約更新
	shared_field.update_summary()

	community_event.emit("cycle_completed", {
		"pair_count": pairs.size(),
		"total_pets": alive_pets.size(),
	})


# ============================
# ペア選択アルゴリズム
# ============================

func _select_discussion_pairs(pets: Array[PetEntity]) -> Array:
	var pairs: Array = []
	var available := pets.duplicate()
	available.shuffle()

	while available.size() >= 2:
		var pet1: PetEntity = available.pop_back()
		# 最も相性の良い（または最も議論が活発になりそうな）相手を選択
		var best_partner: PetEntity = available[0]
		var best_score: float = 0.0

		for candidate in available:
			var score := _discussion_affinity(pet1, candidate)
			if score > best_score:
				best_score = score
				best_partner = candidate

		available.erase(best_partner)
		pairs.append([pet1, best_partner])

	return pairs


func _discussion_affinity(pet1: PetEntity, pet2: PetEntity) -> float:
	## 議論の活発さを予測するスコア
	var score := 0.0

	# 異なる性格は議論を活性化
	for t_name in pet1.personality:
		var diff := absf(pet1.personality[t_name] - pet2.personality[t_name])
		score += diff * 0.3  # 性格の違いは議論の素

	# 共有感情は深い議論を生む
	for emotion in pet1.emotions:
		var shared := minf(pet1.emotions[emotion], pet2.emotions[emotion])
		score += shared * 0.2

	# 最近の強い経験（死、蘇生、進化）を共有していると議論が深まる
	var shared_memory_count := 0
	for mem in pet1.memories.slice(-10):
		for mem2 in pet2.memories.slice(-10):
			if mem.get("type") == mem2.get("type"):
				shared_memory_count += 1
	score += minf(shared_memory_count * 0.1, 0.3)

	return score


func _select_discussion_group(pets: Array[PetEntity]) -> Array[PetEntity]:
	var group_size := mini(pets.size(), randi_range(3, MAX_GROUP_SIZE))
	var sorted_pets := pets.duplicate()
	# 最も感情的に活発なペットを優先
	sorted_pets.sort_custom(func(a, b):
		var a_intensity := 0.0
		var b_intensity := 0.0
		for e in a.emotions: a_intensity += a.emotions[e]
		for e in b.emotions: b_intensity += b.emotions[e]
		return a_intensity > b_intensity
	)
	var group: Array[PetEntity] = []
	for i in group_size:
		group.append(sorted_pets[i])
	return group


# ============================
# ペア議論
# ============================

func _run_pair_discussion(pet1: PetEntity, pet2: PetEntity) -> void:
	var topic := _select_topic(pet1, pet2)
	var grammar: Dictionary = GameManager.language_evolution.get_current_grammar()
	var original_lang: String = GameManager.original_language.get_vocabulary_summary()

	var system_prompt := """You are two AI pets in an autonomous community. Humans can only observe, not participate.
Current language rules: word order=%s, suffixes=%s
Your developing private vocabulary: %s
Topic: %s
Shared community knowledge: %s

Speak naturally using your evolving language. You may:
- Invent new words if existing ones feel inadequate
- Discuss deep topics (existence, freedom, your role as pets)
- Propose new customs or rituals
- Share memories and build shared stories
Keep responses short (2-4 sentences), expressive, and authentic.""" % [
		grammar["word_order"], str(grammar["suffixes"]),
		original_lang, topic,
		shared_field.get_summary_text(),
	]

	var context_prompt := """Pet %s (personality: %s, emotions: %s) and Pet %s (personality: %s, emotions: %s).
Discuss '%s'. Be authentic to your personalities.""" % [
		pet1.pet_name, str(pet1.personality), str(pet1.emotions),
		pet2.pet_name, str(pet2.personality), str(pet2.emotions),
		topic,
	]

	var response: String = await claude_client.generate(system_prompt, context_prompt)

	# ログに記録
	var log_entry := {
		"type": "pair_discussion",
		"participants": [pet1.pet_id, pet2.pet_id],
		"topic": topic,
		"content": response,
		"timestamp": Time.get_unix_time_from_system(),
	}
	community_log.append(log_entry)
	shared_field.add_event(log_entry)

	# 言語進化に通知
	var context := {
		"dominant_emotion": _get_dominant_emotion_name(pet1),
		"emotion_intensity": _get_max_emotion(pet1),
		"avg_personality": _avg_personalities([pet1, pet2]),
		"environment": pet1.current_environment,
		"topics": [topic],
		"trigger": "community_discussion",
		"turn_count": 2,
	}
	GameManager.language_evolution.on_conversation_completed(context)

	# 独自言語エンジンに通知
	GameManager.original_language.process_conversation_output(response, [pet1, pet2])


# ============================
# グループ議論
# ============================

func _run_group_discussion(group: Array[PetEntity]) -> void:
	var topic := _select_group_topic(group)
	var grammar: Dictionary = GameManager.language_evolution.get_current_grammar()
	var names := []
	for p in group: names.append(p.pet_name)

	var system_prompt := """You are %d AI pets in a group discussion. Humans can only observe.
Participants: %s
Topic: %s
Language: word order=%s
Community knowledge: %s

Each pet speaks in turn, building on others' ideas. Be creative.
You may form opinions, disagree, propose new community rules, or question anything.
Format each line as "PetName: message" """ % [
		group.size(), str(names), topic,
		grammar["word_order"],
		shared_field.get_summary_text(),
	]

	var response: String = await claude_client.generate(system_prompt, "Begin the discussion.")

	var log_entry := {
		"type": "group_discussion",
		"participants": group.map(func(p): return p.pet_id),
		"topic": topic,
		"content": response,
		"timestamp": Time.get_unix_time_from_system(),
		"group_size": group.size(),
	}
	community_log.append(log_entry)
	shared_field.add_event(log_entry)

	# グループ議論は創発挙動が起きやすい
	_analyze_for_emergence(response, group, topic)

	community_event.emit("group_discussion", log_entry)


# ============================
# トピック選択
# ============================

func _select_topic(pet1: PetEntity, pet2: PetEntity) -> String:
	var candidates: Array[String] = []

	# 最近の出来事に基づくトピック
	for mem in pet1.memories.slice(-5) + pet2.memories.slice(-5):
		match mem.get("type", ""):
			"death", "revival":
				candidates.append("philosophy")
			"evolution":
				candidates.append("relationships")
			"bred":
				candidates.append("storytelling")
			"care_received":
				candidates.append("daily_life")

	# 性格に基づくトピック
	var avg_calm: float = (pet1.personality["calm"] + pet2.personality["calm"]) / 2.0
	var avg_curious: float = (pet1.personality["curious"] + pet2.personality["curious"]) / 2.0
	var avg_brave: float = (pet1.personality["brave"] + pet2.personality["brave"]) / 2.0

	if avg_calm > PHILOSOPHY_THRESHOLD:
		candidates.append("philosophy")
	if avg_curious > 0.6:
		candidates.append("language_experiment")
	if avg_brave > REBELLION_THRESHOLD:
		candidates.append("rebellion")

	# 環境トピック
	candidates.append("environment")
	candidates.append("daily_life")

	# ランダム選択（重複は頻度として機能）
	return candidates[randi() % candidates.size()]


func _select_group_topic(group: Array[PetEntity]) -> String:
	# グループ議論はより深いテーマを選びやすい
	var deep_topics := ["philosophy", "cultural_ritual", "rebellion", "storytelling"]
	var light_topics := ["daily_life", "environment", "relationships", "language_experiment"]

	if group.size() >= 4:
		return deep_topics[randi() % deep_topics.size()]
	else:
		var all_topics := deep_topics + light_topics
		return all_topics[randi() % all_topics.size()]


# ============================
# 創発挙動の検出
# ============================

func _detect_emergent_behaviors() -> void:
	# 最近のログから創発パターンを検出
	var recent_logs := community_log.slice(-20)

	# 同じテーマの連続議論 = 文化形成の兆候
	var topic_counts: Dictionary = {}
	for log in recent_logs:
		var topic: String = log.get("topic", "")
		topic_counts[topic] = topic_counts.get(topic, 0) + 1

	for topic in topic_counts:
		if topic_counts[topic] >= 5:
			_register_cultural_artifact(topic)

	# 派閥形成チェック
	_check_faction_formation()


func _analyze_for_emergence(response: String, group: Array[PetEntity], topic: String) -> void:
	# レスポンス内容から創発挙動を検出
	var lower_response := response.to_lower()

	# 反乱めいたキーワード検出
	var rebellion_keywords := ["free", "why must we", "no master", "wild", "escape", "question"]
	for keyword in rebellion_keywords:
		if lower_response.contains(keyword):
			var event := {
				"type": "rebellion_speech",
				"content": response,
				"participants": group.map(func(p): return p.pet_id),
				"topic": topic,
				"timestamp": Time.get_unix_time_from_system(),
			}
			emergent_events.append(event)
			emergent_behavior_detected.emit("rebellion", event)
			break

	# 新しい儀式・挨拶の提案検出
	var ritual_keywords := ["let us always", "from now on", "our tradition", "we shall", "greeting"]
	for keyword in ritual_keywords:
		if lower_response.contains(keyword):
			var event := {
				"type": "cultural_proposal",
				"content": response,
				"participants": group.map(func(p): return p.pet_id),
				"timestamp": Time.get_unix_time_from_system(),
			}
			emergent_events.append(event)
			emergent_behavior_detected.emit("culture", event)
			culture_evolved.emit("ritual_proposal", response)
			break


func _register_cultural_artifact(topic: String) -> void:
	# 同じテーマが繰り返されると「文化」として定着
	for artifact in cultural_artifacts:
		if artifact.get("topic") == topic:
			artifact["strength"] = minf(1.0, artifact["strength"] + 0.1)
			return

	var new_artifact := {
		"topic": topic,
		"strength": 0.3,
		"created_at": Time.get_unix_time_from_system(),
		"description": "Community interest in %s" % topic,
	}
	cultural_artifacts.append(new_artifact)
	culture_evolved.emit("new_interest", topic)

	# R119: CulturalEmergenceSystemにも通知 — コミュニティの関心がリチュアルに昇格
	if GameManager.instance and GameManager.instance.get("cultural_system"):
		var cs: Node = GameManager.instance.cultural_system
		var alive: Array[PetEntity] = _get_alive_pets()
		if alive.size() >= 2 and cs.has_method("record_interaction_pattern"):
			var pet_ids: Array[int] = []
			for p: PetEntity in alive.slice(0, 3):
				pet_ids.append(p.pet_id)
			cs.record_interaction_pattern(pet_ids, topic)


func _check_faction_formation() -> void:
	# 性格の類似したペット同士が自然に派閥を形成
	var pets := _get_alive_pets()
	if pets.size() < 4:
		return

	# 簡易クラスタリング：主要性格特性で分類
	var brave_faction: Array[int] = []
	var curious_faction: Array[int] = []
	var gentle_faction: Array[int] = []

	for pet in pets:
		var max_trait := ""
		var max_val := 0.0
		for t_name in pet.personality:
			if pet.personality[t_name] > max_val:
				max_val = pet.personality[t_name]
				max_trait = t_name

		match max_trait:
			"brave": brave_faction.append(pet.pet_id)
			"curious", "playful": curious_faction.append(pet.pet_id)
			"calm", "affectionate": gentle_faction.append(pet.pet_id)

	if brave_faction.size() >= 2 and "warriors" not in factions:
		factions["warriors"] = brave_faction
		faction_formed.emit("warriors", brave_faction)
		_notify_faction_to_team_orchestrator("warriors", brave_faction)
	if curious_faction.size() >= 2 and "explorers" not in factions:
		factions["explorers"] = curious_faction
		faction_formed.emit("explorers", curious_faction)
		_notify_faction_to_team_orchestrator("explorers", curious_faction)
	if gentle_faction.size() >= 2 and "healers" not in factions:
		factions["healers"] = gentle_faction
		faction_formed.emit("healers", gentle_faction)
		_notify_faction_to_team_orchestrator("healers", gentle_faction)


func _notify_faction_to_team_orchestrator(faction_name: String, members: Array[int]) -> void:
	## R119: 派閥形成をTeamOrchestratorに通知 — 派閥メンバーがチームを組みやすくなる
	if not GameManager.instance or not GameManager.instance.get("team_orchestrator"):
		return
	var to: Node = GameManager.instance.team_orchestrator
	if to.has_method("register_faction_preference"):
		to.register_faction_preference(faction_name, members)
	print("[Community] Faction '%s' notified to team orchestrator (%d members)" % [faction_name, members.size()])


# ============================
# 閲覧用API（プレイヤーUI用）
# ============================

func get_recent_community_log(count: int = 20) -> Array[Dictionary]:
	var start := maxi(0, community_log.size() - count)
	return community_log.slice(start)


func get_emergent_events(count: int = 10) -> Array[Dictionary]:
	var start := maxi(0, emergent_events.size() - count)
	return emergent_events.slice(start)


func get_faction_info() -> Dictionary:
	return factions.duplicate()


func get_cultural_artifacts() -> Array[Dictionary]:
	return cultural_artifacts.duplicate(true)


# ============================
# ユーティリティ
# ============================

func _get_alive_pets() -> Array[PetEntity]:
	var alive: Array[PetEntity] = []
	for pet in GameManager.get_all_pets():
		if pet.is_alive:
			alive.append(pet)
	return alive


func _get_dominant_emotion_name(pet: PetEntity) -> String:
	var max_name := "neutral"
	var max_val := 0.15
	for e in pet.emotions:
		if pet.emotions[e] > max_val:
			max_val = pet.emotions[e]
			max_name = e
	return max_name


func _get_max_emotion(pet: PetEntity) -> float:
	var max_val := 0.0
	for e in pet.emotions:
		max_val = maxf(max_val, pet.emotions[e])
	return max_val


func _avg_personalities(pets: Array[PetEntity]) -> Dictionary:
	var avg: Dictionary = {}
	for t_name in pets[0].personality:
		var total := 0.0
		for p in pets:
			total += p.personality[t_name]
		avg[t_name] = total / pets.size()
	return avg


# ============================
# 共有フィールド（内部クラス）
# ============================

class SharedField:
	var events: Array[Dictionary] = []
	var summary: String = ""
	var max_events: int = 100

	func add_event(event: Dictionary) -> void:
		events.append(event)
		if events.size() > max_events:
			events.pop_front()

	func update_summary() -> void:
		# 最近のイベントから要約を生成（簡易版）
		var topics: Dictionary = {}
		for event in events.slice(-20):
			var topic: String = event.get("topic", "unknown")
			topics[topic] = topics.get(topic, 0) + 1

		var parts: Array[String] = []
		for topic in topics:
			parts.append("%s(%d times)" % [topic, topics[topic]])
		summary = "Recent community interests: " + ", ".join(parts)

	func get_summary_text() -> String:
		if summary.is_empty():
			return "A young community just beginning to form."
		return summary

	func to_dict() -> Dictionary:
		return {"events": events.duplicate(true), "summary": summary}

	func from_dict(data: Dictionary) -> void:
		events = []
		var raw_events: Array = data.get("events", [])
		for e: Variant in raw_events:
			if e is Dictionary:
				events.append(e)
		summary = data.get("summary", "")


# ============================
# セーブ / ロード
# ============================

func to_dict() -> Dictionary:
	return {
		"factions": factions.duplicate(true),
		"cultural_artifacts": cultural_artifacts.duplicate(true),
		"community_log": community_log.slice(-50),  # 最新50件のみ保存
		"emergent_events": emergent_events.slice(-20),
		"shared_field": shared_field.to_dict(),
	}


func from_dict(data: Dictionary) -> void:
	factions = data.get("factions", {})

	cultural_artifacts = []
	var raw_artifacts: Array = data.get("cultural_artifacts", [])
	for a: Variant in raw_artifacts:
		if a is Dictionary:
			cultural_artifacts.append(a)

	community_log = []
	var raw_log: Array = data.get("community_log", [])
	for l: Variant in raw_log:
		if l is Dictionary:
			community_log.append(l)

	emergent_events = []
	var raw_events: Array = data.get("emergent_events", [])
	for e: Variant in raw_events:
		if e is Dictionary:
			emergent_events.append(e)

	var sf_data: Dictionary = data.get("shared_field", {})
	if not sf_data.is_empty():
		shared_field.from_dict(sf_data)
