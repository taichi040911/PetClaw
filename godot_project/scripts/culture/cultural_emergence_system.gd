## CulturalEmergenceSystem — ペットが自律的に文化を創出するシステム
## 祭り・物語・歌・儀式・伝統がAtoA会話と感情から創発的に生まれる
## PetBook連携で文化イベントが投稿として共有される
class_name CulturalEmergenceSystem
extends Node

signal artifact_created(artifact_id: String, artifact_type: String)
signal festival_triggered(festival_id: String, participants: Array[int])
signal culture_transmitted(from_id: int, to_id: int, artifact_id: String)
signal tradition_established(artifact_id: String)

# === 定数 ===
const MAX_ARTIFACTS: int = 50
const FESTIVAL_CHECK_INTERVAL: float = 300.0
const TRADITION_AGE_THRESHOLD: float = 604800.0  # 7日
const TRANSMISSION_CHANCE: float = 0.15
const DRIFT_RATE: float = 0.05
const MIN_FESTIVAL_PARTICIPANTS: int = 3
const JOY_THRESHOLD: float = 0.6
const POPULARITY_DECAY: float = 0.01
const POPULARITY_BOOST: float = 0.05

# === アーティファクトタイプ ===
enum ArtifactType { FESTIVAL, STORY, SONG, RITUAL, TRADITION }

const ARTIFACT_TYPE_NAMES: Dictionary = {
	ArtifactType.FESTIVAL: "festival", ArtifactType.STORY: "story",
	ArtifactType.SONG: "song", ArtifactType.RITUAL: "ritual",
	ArtifactType.TRADITION: "tradition",
}

# === State ===
var artifacts: Dictionary = {}  # artifact_id → Dictionary
var _next_artifact_index: int = 0
var _festival_timer: float = 0.0
var _interaction_patterns: Dictionary = {}  # pattern_key → {count, last_time, pet_ids}
var _pet_cultural_knowledge: Dictionary = {}  # pet_id → Array[artifact_id]
var total_artifacts_created: int = 0

# === PetBook投稿テンプレート ===
const PETBOOK_TEMPLATES: Array[Dictionary] = [
	{"type": "festival", "template": "Today we gathered for {name}! {participant_count} of us danced under the {env}. Joy-spark everywhere!"},
	{"type": "festival", "template": "{name}が始まった！みんなで集まって祝おう。{participant_count}匹の仲間と一緒に。"},
	{"type": "story", "template": "Let me tell you the tale of {name}... it began when {creator} first spoke those words."},
	{"type": "story", "template": "{name}の物語を語り継ごう。{creator}が最初に語ったあの日から、みんなの物語になった。"},
	{"type": "song", "template": "Can you hear it? The rhythm of {name} echoes through our community. We sing it together now."},
	{"type": "song", "template": "{name}のメロディが響く。最初はひとりの歌だった。今はみんなの歌。"},
	{"type": "ritual", "template": "Every time we meet, we do {name}. It started small, but now it's who we are."},
	{"type": "ritual", "template": "{name}の儀式。毎回繰り返すたびに、絆が深まる気がする。"},
	{"type": "tradition", "template": "{name} has become our tradition! Passed down through generations, it defines us."},
	{"type": "tradition", "template": "{name}は私たちの伝統になった。次の世代にも伝えていきたい。"},
]


func _process(delta: float) -> void:
	_festival_timer += delta
	if _festival_timer >= FESTIVAL_CHECK_INTERVAL:
		_festival_timer = 0.0
		_check_festival_conditions()
		_apply_cultural_drift()
		_decay_popularity()
		_promote_traditions()

# === アーティファクト生成 ===

func create_artifact(type: int, creator_id: int, participants: Array[int],
		content_template: String, artifact_name: String) -> String:
	if artifacts.size() >= MAX_ARTIFACTS:
		_evict_least_popular()
	var artifact_id: String = "culture_%d" % _next_artifact_index
	_next_artifact_index += 1
	total_artifacts_created += 1
	var artifact: Dictionary = {
		"id": artifact_id, "type": type,
		"type_name": ARTIFACT_TYPE_NAMES.get(type, "unknown"),
		"name": artifact_name, "creator_id": creator_id,
		"participants": participants.duplicate(),
		"creation_time": _get_game_time(), "popularity": 0.3,
		"content_template": content_template,
		"variants": [], "transmission_count": 0,
	}
	artifacts[artifact_id] = artifact
	for pid: int in participants:
		_add_knowledge(pid, artifact_id)
	_add_knowledge(creator_id, artifact_id)
	artifact_created.emit(artifact_id, artifact.type_name)
	return artifact_id

# === フェスティバル検出 ===

func _check_festival_conditions() -> void:
	var gm: Node = GameManager.instance
	if gm == null:
		return
	var joyful_pets: Array[int] = []
	var pets_dict: Dictionary = gm.pets
	for pet_id: int in pets_dict:
		var pet: Node = pets_dict[pet_id]
		if pet == null:
			continue
		var emotions: Dictionary = _get_pet_emotions(pet)
		if emotions.get("joy", 0.0) >= JOY_THRESHOLD:
			joyful_pets.append(pet_id)
	if joyful_pets.size() >= MIN_FESTIVAL_PARTICIPANTS:
		_trigger_festival(joyful_pets)

func _trigger_festival(participants: Array[int]) -> void:
	var names: Array[String] = [
		"First Word Day", "Full Moon Gathering", "Joy Bloom Festival",
		"Echo Dance", "Spark Celebration", "Dawn Chorus",
	]
	var name_pick: String = names[randi() % names.size()]
	var template: String = "All gather for %s! Together we celebrate!" % name_pick
	var festival_id: String = create_artifact(
		ArtifactType.FESTIVAL, participants[0], participants, template, name_pick)
	artifacts[festival_id].popularity = 0.6
	festival_triggered.emit(festival_id, participants)
	_generate_petbook_post(festival_id)

# === 物語生成（会話から） ===

func create_story_from_conversation(creator_id: int, partner_id: int,
		conversation_summary: String) -> String:
	var names: Array[String] = [
		"The Tale of Two Sparks", "Whispers in the Field",
		"When Stars Aligned", "The Lost Echo",
	]
	var name_pick: String = names[randi() % names.size()]
	var template: String = conversation_summary.left(120) if conversation_summary.length() > 0 else "A tale born from conversation"
	var story_id: String = create_artifact(
		ArtifactType.STORY, creator_id, [creator_id, partner_id], template, name_pick)
	_generate_petbook_post(story_id)
	return story_id

# === 歌生成（言語進化マイルストーンから） ===

func create_song_from_language_milestone(creator_id: int, milestone_words: Array[String]) -> String:
	var rhythm: String = " ~ ".join(milestone_words) if milestone_words.size() > 0 else "hum~spark~glow"
	var song_name: String = "Song of %s" % (milestone_words[0] if milestone_words.size() > 0 else "Echo")
	var song_id: String = create_artifact(
		ArtifactType.SONG, creator_id, [creator_id], "♪ %s ♪" % rhythm, song_name)
	_generate_petbook_post(song_id)
	return song_id

# === 儀式検出（繰り返しパターン） ===

func record_interaction_pattern(pet_ids: Array[int], pattern_type: String) -> void:
	var sorted_ids: Array[int] = pet_ids.duplicate()
	sorted_ids.sort()
	var key: String = "%s_%s" % [pattern_type, str(sorted_ids)]
	if not _interaction_patterns.has(key):
		_interaction_patterns[key] = {"count": 0, "last_time": 0.0, "pet_ids": sorted_ids, "pattern_type": pattern_type}
	var pattern: Dictionary = _interaction_patterns[key]
	pattern.count += 1
	pattern.last_time = _get_game_time()
	if pattern.count == 3:  # 3回繰り返しでリチュアル生成
		_create_ritual_from_pattern(pattern)

func _create_ritual_from_pattern(pattern: Dictionary) -> void:
	var ritual_name: String = "The %s Ritual" % pattern.pattern_type.capitalize()
	var template: String = "When we meet, we always %s. It is our way." % pattern.pattern_type
	var participants: Array[int] = []
	for pid: Variant in pattern.pet_ids:
		participants.append(pid as int)
	var creator: int = participants[0] if participants.size() > 0 else 0
	var ritual_id: String = create_artifact(
		ArtifactType.RITUAL, creator, participants, template, ritual_name)
	_generate_petbook_post(ritual_id)

# === 伝統への昇格 ===

func _promote_traditions() -> void:
	var current_time: float = _get_game_time()
	for art_id: String in artifacts:
		var art: Dictionary = artifacts[art_id]
		if art.type == ArtifactType.TRADITION:
			continue
		var age: float = current_time - art.get("creation_time", current_time)
		if age >= TRADITION_AGE_THRESHOLD and art.get("popularity", 0.0) >= 0.3:
			art.type = ArtifactType.TRADITION
			art.type_name = ARTIFACT_TYPE_NAMES[ArtifactType.TRADITION]
			tradition_established.emit(art_id)
			_generate_petbook_post(art_id)

# === 文化伝達 ===

func attempt_cultural_transmission(from_id: int, to_id: int) -> void:
	if randf() > TRANSMISSION_CHANCE:
		return
	var from_knowledge: Array = _get_knowledge(from_id)
	if from_knowledge.is_empty():
		return
	var candidate_id: String = from_knowledge[randi() % from_knowledge.size()]
	if candidate_id in _get_knowledge(to_id):
		return
	_add_knowledge(to_id, candidate_id)
	if artifacts.has(candidate_id):
		var art: Dictionary = artifacts[candidate_id]
		art.popularity = minf(art.get("popularity", 0.0) + POPULARITY_BOOST, 1.0)
		art.transmission_count = art.get("transmission_count", 0) + 1
	culture_transmitted.emit(from_id, to_id, candidate_id)

func inherit_culture_for_offspring(parent_ids: Array[int], offspring_id: int) -> void:
	for parent_id: int in parent_ids:
		for art_id: Variant in _get_knowledge(parent_id):
			var is_tradition: bool = false
			if artifacts.has(art_id as String):
				is_tradition = artifacts[art_id as String].get("type", -1) == ArtifactType.TRADITION
			if is_tradition or randf() < 0.5:
				_add_knowledge(offspring_id, art_id as String)

# === 文化ドリフト ===

func _apply_cultural_drift() -> void:
	for art_id: String in artifacts:
		if randf() > DRIFT_RATE:
			continue
		var art: Dictionary = artifacts[art_id]
		var original: String = art.get("content_template", "")
		var variant: String = _mutate_content(original)
		if variant != original:
			var variants: Array = art.get("variants", [])
			if variants.size() < 5:
				variants.append(variant)
				art.variants = variants

func _mutate_content(content: String) -> String:
	if content.is_empty():
		return content
	var words: PackedStringArray = content.split(" ")
	if words.size() < 2:
		return content
	var suffixes: Array[String] = ["-spark", "-glow", "-echo", "-bloom", "-mist", "-shade"]
	var idx: int = randi() % words.size()
	words[idx] = words[idx] + suffixes[randi() % suffixes.size()]
	return " ".join(words)

# === PetBook連携 ===

func _generate_petbook_post(artifact_id: String) -> void:
	if not artifacts.has(artifact_id):
		return
	var art: Dictionary = artifacts[artifact_id]
	var art_type: String = art.get("type_name", "unknown")
	var matching: Array[Dictionary] = []
	for t: Dictionary in PETBOOK_TEMPLATES:
		if t.type == art_type:
			matching.append(t)
	if matching.is_empty():
		return
	var post_text: String = matching[randi() % matching.size()].template
	post_text = post_text.replace("{name}", art.get("name", "Unknown"))
	post_text = post_text.replace("{creator}", str(art.get("creator_id", 0)))
	post_text = post_text.replace("{participant_count}", str(art.get("participants", []).size()))
	post_text = post_text.replace("{env}", "field")
	var gm: Node = GameManager.instance
	if gm == null:
		return
	var pb: Node = gm.get("pet_book")
	if pb != null and pb.has_method("create_post_from_template"):
		pb.create_post_from_template(art.get("creator_id", 0), post_text, art_type)

# === ヘルパー ===

func _get_game_time() -> float:
	var gm: Node = GameManager.instance
	return (gm.get("game_time") as float) if gm != null else 0.0

func _get_pet_emotions(pet: Node) -> Dictionary:
	if pet.has_method("get_emotions"):
		return pet.get_emotions()
	if "emotions" in pet:
		return pet.emotions
	return {}

func _add_knowledge(pet_id: int, artifact_id: String) -> void:
	if not _pet_cultural_knowledge.has(pet_id):
		_pet_cultural_knowledge[pet_id] = []
	var knowledge: Array = _pet_cultural_knowledge[pet_id]
	if artifact_id not in knowledge:
		knowledge.append(artifact_id)

func _get_knowledge(pet_id: int) -> Array:
	return _pet_cultural_knowledge.get(pet_id, [])

func _decay_popularity() -> void:
	for art_id: String in artifacts:
		var art: Dictionary = artifacts[art_id]
		art.popularity = maxf(art.get("popularity", 0.0) - POPULARITY_DECAY, 0.0)

func _evict_least_popular() -> void:
	var min_pop: float = 2.0
	var min_id: String = ""
	for art_id: String in artifacts:
		var art: Dictionary = artifacts[art_id]
		if art.get("type", -1) == ArtifactType.TRADITION:
			continue
		var pop: float = art.get("popularity", 0.0)
		if pop < min_pop:
			min_pop = pop
			min_id = art_id
	if min_id != "":
		artifacts.erase(min_id)

func get_artifacts_by_type(type: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for art_id: String in artifacts:
		if artifacts[art_id].get("type", -1) == type:
			result.append(artifacts[art_id])
	return result

func get_popular_artifacts(min_popularity: float = 0.5) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for art_id: String in artifacts:
		if artifacts[art_id].get("popularity", 0.0) >= min_popularity:
			result.append(artifacts[art_id])
	return result

# === セーブ/ロード ===

func to_dict() -> Dictionary:
	var artifacts_data: Dictionary = {}
	for art_id: String in artifacts:
		artifacts_data[art_id] = artifacts[art_id].duplicate(true)
	var knowledge_data: Dictionary = {}
	for pid: int in _pet_cultural_knowledge:
		knowledge_data[str(pid)] = _pet_cultural_knowledge[pid].duplicate()
	var patterns_data: Dictionary = {}
	for key: String in _interaction_patterns:
		patterns_data[key] = _interaction_patterns[key].duplicate()
	return {
		"artifacts": artifacts_data,
		"next_artifact_index": _next_artifact_index,
		"pet_cultural_knowledge": knowledge_data,
		"interaction_patterns": patterns_data,
		"total_artifacts_created": total_artifacts_created,
	}

func from_dict(data: Dictionary) -> void:
	artifacts = data.get("artifacts", {})
	_next_artifact_index = data.get("next_artifact_index", 0)
	total_artifacts_created = data.get("total_artifacts_created", 0)
	_pet_cultural_knowledge = {}
	var knowledge_data: Dictionary = data.get("pet_cultural_knowledge", {})
	for pid_str: String in knowledge_data:
		_pet_cultural_knowledge[pid_str.to_int()] = knowledge_data[pid_str]
	_interaction_patterns = data.get("interaction_patterns", {})
