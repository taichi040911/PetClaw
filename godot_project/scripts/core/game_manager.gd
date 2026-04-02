## GameManager — ゲーム全体のシステム統合・参照管理
## 全サブシステムのシングルトンアクセスポイント
## Godot AutoLoad として登録: Project Settings → AutoLoad → GameManager
## NOTE: No class_name — GameManager is registered as AutoLoad singleton.
extends Node

# === System References (AutoLoad or子ノード) ===
static var instance: Node  # typed as Node to avoid circular reference

var biological_memory: Node  # BiologicalMemorySystem
var emotion_system: Node  # EmotionSystem
var ecosystem: Node  # EcosystemManager
var life_death: Node  # LifeDeathSystem
var breeding: Node  # BreedingSystem
var language_evolution: Node  # LanguageEvolutionSystem
var original_language: Node  # OriginalLanguageEngine
var a2a_system: Node  # AtoAConversationSystem
var a2a_community: Node  # AtoACommunityCore
var care_system: Node  # CareActionSystem
var evolution_mechanics: Node  # EvolutionMechanics
var visual_fx: Node  # VisualFXSystem
var persistent_field: Node  # PersistentField
var ethical_safeguard: Node  # EthicalSafeguard
var pet_autonomy: Node  # PetAutonomySystem
var lifecycle_fsm: RefCounted  # PetLifecycleFSM (extends RefCounted)
var pet_book: Node  # PetBookCore

# === Pet Registry ===
var pets: Dictionary = {}  # pet_id → PetEntity
var next_pet_id: int = 1

# === Game State ===
var game_time: float = 0.0
var is_paused: bool = false
var save_timer: float = 0.0
const AUTO_SAVE_INTERVAL: float = 300.0  # 5分ごと自動セーブ

# === Care Miss Detection ===
var _care_last_action_time: Dictionary = {}  # pet_id → last care time (game_time)
const CARE_MISS_CHECK_INTERVAL: float = 60.0  # 60秒ごとにミスチェック
const CARE_MISS_THRESHOLD: float = 300.0  # 5分以上世話なし → ミス判定
var _care_miss_timer: float = 0.0


func _ready() -> void:
	instance = self
	# Defer initialization to allow all class_names to register first
	call_deferred("_deferred_init")


func _deferred_init() -> void:
	_initialize_systems()
	_connect_signals()
	_load_game_data()


func _process(delta: float) -> void:
	if is_paused:
		return

	game_time += delta

	# 自動セーブ
	save_timer += delta
	if save_timer >= AUTO_SAVE_INTERVAL:
		save_timer = 0.0
		save_game()

	# ケアミス自動検出
	_care_miss_timer += delta
	if _care_miss_timer >= CARE_MISS_CHECK_INTERVAL:
		_care_miss_timer = 0.0
		_check_care_misses()


# === システム初期化 ===
# NOTE: load() を使用して循環依存を回避（autoload スクリプトは class_name を直接参照できない）
func _initialize_systems() -> void:
	biological_memory = _create_system("res://scripts/memory/biological_memory_system.gd", "BiologicalMemorySystem")
	emotion_system = _create_system("res://scripts/core/emotion_system.gd", "EmotionSystem")
	ecosystem = _create_system("res://scripts/ecosystem/ecosystem_manager.gd", "EcosystemManager")
	life_death = _create_system("res://scripts/life/life_death_system.gd", "LifeDeathSystem")
	breeding = _create_system("res://scripts/life/breeding_system.gd", "BreedingSystem")
	language_evolution = _create_system("res://scripts/language/language_evolution_system.gd", "LanguageEvolutionSystem")
	original_language = _create_system("res://scripts/language/original_language_engine.gd", "OriginalLanguageEngine")
	a2a_system = _create_system("res://scripts/conversation/a2a_conversation_system.gd", "AtoAConversationSystem")
	a2a_community = _create_system("res://scripts/community/a2a_community_core.gd", "AtoACommunityCore")
	care_system = _create_system("res://scripts/care/care_action_system.gd", "CareActionSystem")
	evolution_mechanics = _create_system("res://scripts/evolution/evolution_mechanics.gd", "EvolutionMechanics")
	visual_fx = _create_system("res://scripts/visual/visual_fx_system.gd", "VisualFXSystem")
	persistent_field = _create_system("res://scripts/field/persistent_field.gd", "PersistentField")
	ethical_safeguard = _create_system("res://scripts/ethics/ethical_safeguard.gd", "EthicalSafeguard")
	pet_autonomy = _create_system("res://scripts/autonomy/pet_autonomy_system.gd", "PetAutonomySystem")
	var fsm_script: GDScript = load("res://scripts/life/pet_lifecycle_fsm.gd")
	lifecycle_fsm = fsm_script.new(0)  # default pet_id=0, reassigned on pet load
	pet_book = _create_system("res://scripts/social/pet_book_core.gd", "PetBookCore")


func _create_pet_entity() -> Node:
	var script: GDScript = load("res://scripts/core/pet_entity.gd")
	return script.new()


func _create_system(script_path: String, node_name: String) -> Node:
	var script: GDScript = load(script_path)
	var node: Node = script.new()
	node.name = node_name
	add_child(node)
	return node


# === シグナル接続 ===
func _connect_signals() -> void:
	# 気候イベント → 言語進化
	ecosystem.climate_event.connect(language_evolution.on_climate_event)

	# 死亡/蘇生 → ログ
	life_death.pet_died.connect(_on_pet_died)
	life_death.pet_revived.connect(_on_pet_revived)

	# 進化完了 → ログ
	evolution_mechanics.evolution_completed.connect(_on_evolution_completed)

	# 交配 → ペット登録
	breeding.offspring_born.connect(_on_offspring_born)

	# 言語進化マイルストーン → ログ
	language_evolution.grammar_milestone.connect(_on_grammar_milestone)

	# 独自言語の進化
	original_language.word_invented.connect(_on_word_invented)
	original_language.language_stage_advanced.connect(_on_language_stage_advanced)

	# 生物模倣記憶
	biological_memory.memory_promoted.connect(_on_memory_promoted)
	biological_memory.flashbulb_memory_created.connect(_on_flashbulb_memory)
	biological_memory.memory_forgotten.connect(_on_memory_forgotten)

	# PersistentField
	persistent_field.offline_adventure_completed.connect(_on_offline_adventure)
	persistent_field.community_mood_shifted.connect(_on_community_mood_shifted)

	# 倫理セーフガード
	ethical_safeguard.dependency_warning.connect(_on_dependency_warning)
	ethical_safeguard.real_world_suggestion.connect(_on_real_world_suggestion)
	ethical_safeguard.session_limit_reached.connect(_on_session_limit)

	# コミュニティ創発挙動
	a2a_community.emergent_behavior_detected.connect(_on_emergent_behavior)
	a2a_community.faction_formed.connect(_on_faction_formed)
	a2a_community.culture_evolved.connect(_on_culture_evolved)

	# ===  Evolution ← Care / AtoA 統合接続 ===
	# AtoA会話完了 → 進化メカニクスにカウント記録
	a2a_system.conversation_ended.connect(_on_a2a_for_evolution)
	# ケア実行 → 進化メカニクスのケアミスウィンドウリセット（世話した＝ミスじゃない）
	care_system.care_performed.connect(_on_care_for_evolution)

	# === ラウンド4: 自律行動 + ライフサイクルFSM 統合接続 ===
	# 自律行動完了 → ログ + 進化チェック
	pet_autonomy.autonomous_action_completed.connect(_on_autonomous_action)
	# ライフサイクル状態変化 → ログ + システム連携
	if lifecycle_fsm:
		lifecycle_fsm.state_changed.connect(_on_lifecycle_state_changed)
		lifecycle_fsm.lifecycle_milestone.connect(_on_lifecycle_milestone)
		lifecycle_fsm.sleep_started.connect(_on_pet_sleep_started)
		lifecycle_fsm.sleep_ended.connect(_on_pet_sleep_ended)

	# === ラウンド5: PetBook 統合接続 ===
	# 死亡 → 追悼投稿
	life_death.pet_died.connect(_on_pet_died_for_petbook)
	# 進化 → イベント投稿
	evolution_mechanics.evolution_completed.connect(_on_evolution_for_petbook)
	# 交配 → イベント投稿
	breeding.offspring_born.connect(_on_birth_for_petbook)
	# PetBook反乱投稿 → 言語進化に通知
	pet_book.rebel_post_emerged.connect(_on_rebel_post_for_language)
	# PetBookトレンド → PersistentFieldに反映
	pet_book.trend_detected.connect(_on_petbook_trend)


# === ペット管理 ===
func register_pet(pet: Node) -> void:  # PetEntity
	pets[pet.pet_id] = pet
	biological_memory.register_pet(pet.pet_id)
	emotion_system.register_pet(pet)
	life_death.register_pet(pet)


func unregister_pet(pet: Node) -> void:  # PetEntity
	pets.erase(pet.pet_id)
	biological_memory.unregister_pet(pet.pet_id)
	emotion_system.unregister_pet(pet)


func get_all_pets() -> Array:
	var result: Array = []
	for pet_id in pets:
		result.append(pets[pet_id])
	return result


func get_pet_by_id(pet_id: int) -> Node:  # PetEntity
	return pets.get(pet_id, null)


func generate_pet_id() -> int:
	var id := next_pet_id
	next_pet_id += 1
	return id


# === シグナルハンドラ ===
func _on_pet_died(pet_id: int, cause: String) -> void:
	print("[GameManager] Pet %d died: %s" % [pet_id, cause])


func _on_pet_revived(pet_id: int, method: String) -> void:
	print("[GameManager] Pet %d revived via: %s" % [pet_id, method])


func _on_evolution_completed(pet_id: int, form: String, reason: String) -> void:
	print("[GameManager] Pet %d evolved to %s: %s" % [pet_id, form, reason])


func _on_offspring_born(parent1_id: int, parent2_id: int, child: Node) -> void:  # PetEntity
	register_pet(child)
	print("[GameManager] New pet born! Parents: %d & %d → Child: %d" % [parent1_id, parent2_id, child.pet_id])


func _on_grammar_milestone(milestone: String, details: Dictionary) -> void:
	print("[GameManager] Language milestone: %s (%s)" % [milestone, str(details)])


func _on_word_invented(word: Dictionary) -> void:
	print("[GameManager] New word invented: %s = %s" % [word.get("ai_term", "?"), word.get("semantic_field", "?")])


func _on_language_stage_advanced(new_stage: int, stage_name: String) -> void:
	print("[GameManager] Language stage advanced to: %s (stage %d)" % [stage_name, new_stage])


func _on_emergent_behavior(behavior_type: String, details: Dictionary) -> void:
	print("[GameManager] Emergent behavior detected: %s" % behavior_type)


func _on_faction_formed(faction_name: String, members: Array[int]) -> void:
	print("[GameManager] Faction formed: %s with %d members" % [faction_name, members.size()])


func _on_culture_evolved(culture_type: String, description: String) -> void:
	print("[GameManager] Culture evolved: %s - %s" % [culture_type, description])


func _on_memory_promoted(pet_id: int, memory_id: int) -> void:
	print("[GameManager] Pet %d memory %d promoted to cortex (long-term)" % [pet_id, memory_id])


func _on_flashbulb_memory(pet_id: int, memory_id: int, emotion: String) -> void:
	print("[GameManager] Pet %d flashbulb memory %d (%s) — instant cortex storage" % [pet_id, memory_id, emotion])
	# フラッシュバルブ記憶の視覚効果
	if visual_fx:
		visual_fx.play_effect("flashbulb_memory", pet_id)


func _on_memory_forgotten(pet_id: int, memory_id: int) -> void:
	print("[GameManager] Pet %d forgot memory %d" % [pet_id, memory_id])


# --- PersistentField ハンドラ ---
func _on_offline_adventure(pet_id: int, adventure: Dictionary) -> void:
	print("[GameManager] Pet %d returned from offline adventure: %s" % [pet_id, adventure.get("type", "unknown")])
	# 冒険の記憶をBiologicalMemoryに記録
	if biological_memory:
		var memory := {
			"type": "offline_adventure",
			"adventure_type": adventure.get("type", ""),
			"discovery": adventure.get("discovery", ""),
			"environment": adventure.get("environment", ""),
		}
		biological_memory.consolidate_memory(
			pet_id, memory, "curiosity", 0.6, ["offline", adventure.get("type", "")]
		)


func _on_community_mood_shifted(old_mood: String, new_mood: String) -> void:
	print("[GameManager] Community mood shifted: %s → %s" % [old_mood, new_mood])
	# 雰囲気変化を全ペットの感情システムに反映
	if emotion_system:
		var mood_emotion_map := {
			"joyful": "joy",
			"tense": "anxiety",
			"calm": "calm",
			"excited": "excitement",
			"melancholy": "sadness",
		}
		var emotion: String = mood_emotion_map.get(new_mood, "calm")
		for pet_id in pets:
			emotion_system.stimulate(pets[pet_id], emotion, 0.2, "community_mood")


# --- EthicalSafeguard ハンドラ ---
func _on_dependency_warning(score: float, message: String) -> void:
	print("[GameManager] ⚠ Dependency warning (%.2f): %s" % [score, message])
	# UI通知システムに転送（将来実装）


func _on_real_world_suggestion(suggestion: String) -> void:
	print("[GameManager] 💡 Real-world suggestion: %s" % suggestion)
	# UI通知システムに転送（将来実装）


# --- Care Miss 自動検出 ---
func _check_care_misses() -> void:
	## 一定時間世話されていないペットのケアミスを記録
	## たまごっち直系: 空腹・不衛生・病気を放置 → ミス
	for pet_id in pets:
		var pet: Node = pets[pet_id]  # PetEntity
		if not pet.is_alive:
			continue

		var last_care: float = _care_last_action_time.get(pet_id, 0.0)
		var time_since_care: float = game_time - last_care

		# 5分以上世話なし、かつペットが困っている状態
		if time_since_care >= CARE_MISS_THRESHOLD:
			var needs_care := false
			if pet.stats.hunger < 0.3:
				needs_care = true  # 空腹
			if pet.stats.health < 0.4:
				needs_care = true  # 体調不良
			if pet.stats.energy < 0.2:
				needs_care = true  # 疲弊

			if needs_care:
				evolution_mechanics.record_care_miss(pet_id)
				# リセット: 次のミス判定まで猶予
				_care_last_action_time[pet_id] = game_time


# --- Evolution ← Care/AtoA 統合ハンドラ ---
func _on_a2a_for_evolution(participants: Array[int], _summary: String) -> void:
	## AtoA会話が完了 → 両参加者の進化カウントを記録
	for pet_id in participants:
		evolution_mechanics.record_a2a_conversation(pet_id)
	# 会話後に進化チェック
	for pet_id in participants:
		var pet := get_pet_by_id(pet_id)
		if pet and pet.is_alive:
			evolution_mechanics.check_evolution(pet)


func _on_care_for_evolution(pet_id: int, action: String, _effectiveness: float) -> void:
	## ケアが実行された → ケアミスタイマーをリセット（この子は世話されている）
	_care_last_action_time[pet_id] = game_time
	# trainやexplore後は進化チェックのタイミング
	if action in ["train", "explore"]:
		var pet := get_pet_by_id(pet_id)
		if pet and pet.is_alive:
			evolution_mechanics.check_evolution(pet)


# --- ラウンド4: 自律行動 + ライフサイクルFSM ハンドラ ---
func _on_autonomous_action(pet_id: int, action: String, result: Dictionary) -> void:
	print("[GameManager] Pet %d autonomous action '%s' completed: %s" % [pet_id, action, str(result)])
	# 自律行動後に進化チェック（explore等は進化準備度に影響）
	if action in ["explore_area", "practice_language", "seek_companion"]:
		var pet := get_pet_by_id(pet_id)
		if pet and pet.is_alive:
			evolution_mechanics.check_evolution(pet)


func _on_lifecycle_state_changed(pet_id: int, old_state: int, new_state: int) -> void:
	print("[GameManager] Pet %d lifecycle: %d → %d" % [pet_id, old_state, new_state])


func _on_lifecycle_milestone(pet_id: int, milestone: String) -> void:
	print("[GameManager] Pet %d milestone: %s" % [pet_id, milestone])
	# マイルストーンをフラッシュバルブ記憶として記録
	if biological_memory:
		biological_memory.consolidate_memory(
			pet_id,
			{"type": "lifecycle_milestone", "milestone": milestone},
			"joy", 0.8, ["milestone", milestone]
		)


func _on_pet_sleep_started(pet_id: int) -> void:
	print("[GameManager] Pet %d fell asleep" % pet_id)
	# 睡眠中の記憶整理をトリガー
	if biological_memory:
		biological_memory.trigger_sleep_consolidation(pet_id)


func _on_pet_sleep_ended(pet_id: int) -> void:
	print("[GameManager] Pet %d woke up" % pet_id)


func _on_session_limit(limit_type: String) -> void:
	print("[GameManager] 🛑 Session limit reached: %s" % limit_type)
	match limit_type:
		"hourly_interaction":
			print("[GameManager]   → Interaction rate limit active. Cool down.")
		"daily_a2a":
			print("[GameManager]   → Daily AtoA conversation limit reached.")
		"session_duration":
			print("[GameManager]   → Extended session detected. Break suggested.")


# --- ラウンド5: PetBook 統合ハンドラ ---
func _on_pet_died_for_petbook(pet_id: int, _cause: String) -> void:
	var pet := get_pet_by_id(pet_id)
	if pet and pet_book:
		pet_book.create_memorial_posts(pet_id, pet.pet_name)


func _on_evolution_for_petbook(pet_id: int, form: String, _reason: String) -> void:
	if pet_book:
		pet_book.create_event_post(pet_id, "evolution", {"form": form})


func _on_birth_for_petbook(_parent1_id: int, _parent2_id: int, child: Node) -> void:  # PetEntity
	if pet_book:
		pet_book.create_event_post(child.pet_id, "birth", {"child_name": child.pet_name})


func queue_petbook_posts(post_data: Dictionary) -> void:
	## AtoA会話システムからの投稿をPetBookCoreに橋渡し
	## AtoAConversationSystem._generate_conversation_posts() から呼ばれる
	if pet_book:
		pet_book.publish_conversation_post(post_data)


func _on_rebel_post_for_language(post: Variant) -> void:  # PetBookPost
	## 反乱投稿の言語パターンを言語進化システムに通知
	if language_evolution and not post.rebel_expressions.is_empty():
		for expr in post.rebel_expressions:
			print("[GameManager] Rebel expression detected in PetBook: %s" % expr)
		# 反乱表現が言語進化に影響（将来: language_evolution.on_rebel_expression()）


func _on_petbook_trend(topic: String, count: int) -> void:
	## PetBookのトレンドをPersistentFieldに反映
	if persistent_field:
		persistent_field.record_shared_event({
			"type": "petbook_trend",
			"topic": topic,
			"count": count,
			"timestamp": game_time,
		})
	print("[GameManager] PetBook trend: '%s' (%d mentions)" % [topic, count])


# === セーブ/ロード ===
func save_game() -> void:
	var save_data := {
		"game_time": game_time,
		"next_pet_id": next_pet_id,
		"pets": {},
		"language": language_evolution.to_dict(),
		"original_language": original_language.to_dict(),
		"biological_memory": biological_memory.to_dict(),
		"ecosystem": ecosystem.to_dict(),
		"ethical_safeguard": ethical_safeguard.to_dict(),
		"evolution_mechanics": evolution_mechanics.to_dict(),
		"pet_autonomy": pet_autonomy.to_dict(),
		"lifecycle_fsm": lifecycle_fsm.to_dict(),
		"pet_book": pet_book.to_dict(),
		"breeding": breeding.to_dict(),
		"life_death": life_death.to_dict(),
	}

	for pet_id in pets:
		save_data["pets"][pet_id] = pets[pet_id].to_dict()

	var json_string := JSON.stringify(save_data, "\t")
	var file := FileAccess.open("user://petclaw_save.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("[GameManager] Game saved")

	# PersistentField は独自 atomic write で別ファイルに保存
	persistent_field.save_field()


func _load_game_data() -> void:
	var file_path := "user://petclaw_save.json"
	if not FileAccess.file_exists(file_path):
		_create_starter_pets()
		return

	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		_create_starter_pets()
		return

	var json := JSON.new()
	var result := json.parse(file.get_as_text())
	file.close()

	if result != OK:
		_create_starter_pets()
		return

	var data: Dictionary = json.data
	game_time = data.get("game_time", 0.0)
	next_pet_id = data.get("next_pet_id", 1)

	# 言語システム復元
	language_evolution.from_dict(data.get("language", {}))
	original_language.from_dict(data.get("original_language", {}))

	# 生物模倣記憶復元（オフライン整理も自動実行）
	biological_memory.from_dict(data.get("biological_memory", {}))

	# 環境復元（後方互換: 旧フォーマット対応）
	var eco_data: Dictionary = data.get("ecosystem", {})
	if eco_data.has("current_environment"):
		ecosystem.from_dict(eco_data)
	else:
		# 旧セーブ形式
		ecosystem.current_environment = eco_data.get("environment", "forest")
		ecosystem.climate_intensity = eco_data.get("climate", 0.5)

	# 倫理セーフガード復元
	ethical_safeguard.from_dict(data.get("ethical_safeguard", {}))

	# 進化メカニクス復元（care_misses, a2a_counts, forms, history）
	evolution_mechanics.from_dict(data.get("evolution_mechanics", {}))

	# ラウンド4: 自律行動 + ライフサイクルFSM復元
	pet_autonomy.from_dict(data.get("pet_autonomy", {}))
	lifecycle_fsm.from_dict(data.get("lifecycle_fsm", {}))

	# ラウンド5: PetBook復元
	pet_book.from_dict(data.get("pet_book", {}))

	# ラウンド23: Breeding + LifeDeath復元
	breeding.from_dict(data.get("breeding", {}))
	life_death.from_dict(data.get("life_death", {}))

	# ペット復元
	for pet_id_str in data.get("pets", {}):
		var pet := _create_pet_entity()
		pet.from_dict(data["pets"][pet_id_str])
		register_pet(pet)

	# PersistentField セッション復帰（オフライン冒険・関係減衰を処理）
	# ※ PersistentField は _ready() で独自ファイルから自動ロード済み
	var pet_array: Array = get_all_pets()
	var adventures: Array = persistent_field.on_session_resume(pet_array)
	for adv in adventures:
		var adv_pet_id: int = adv.get("pet_id", -1)
		if adv_pet_id > 0:
			_on_offline_adventure(adv_pet_id, adv)

	# 日付チェック → 倫理セーフガードの日次リセット
	var today := Time.get_date_string_from_system()
	ethical_safeguard.on_new_day(today)

	print("[GameManager] Game loaded (%d pets, %d offline adventures)" % [pets.size(), adventures.size()])


func _create_starter_pets() -> void:
	## 初回起動時のスターターペット
	var pet1 := _create_pet_entity()
	pet1.pet_id = generate_pet_id()
	pet1.pet_name = "Mimi"
	pet1.age = 2.0
	pet1.evolution_stage = 1
	pet1.personality["curious"] = 0.7
	pet1.personality["playful"] = 0.6

	var pet2 := _create_pet_entity()
	pet2.pet_id = generate_pet_id()
	pet2.pet_name = "Kuro"
	pet2.age = 2.0
	pet2.evolution_stage = 1
	pet2.personality["brave"] = 0.7
	pet2.personality["calm"] = 0.5

	register_pet(pet1)
	register_pet(pet2)
	print("[GameManager] Created starter pets: Mimi & Kuro")
