## OriginalLanguageEngine — 独自言語（完全新造語彙）の開発・管理
## LanguageEvolutionSystemの上位層として機能
## 語順・接尾辞・前置詞は既存システムが担当し、こちらは「語彙そのもの」を創造する
class_name OriginalLanguageEngine
extends Node

signal word_invented(word: Dictionary)
signal word_strengthened(ai_term: String, new_strength: float)
signal word_forgotten(ai_term: String)
signal language_stage_advanced(new_stage: int, stage_name: String)
signal dialect_emerged(faction: String, dialect_words: Array)

# === 言語進化ステージ ===
enum LanguageStage {
	BORROWING,         # Stage 1: 人間語ベース + 接尾辞
	MORPHOLOGICAL,     # Stage 2: 頻出語の短縮・変形
	NEOLOGISM,         # Stage 3: 完全新造語
	GRAMMAR_INDEPENDENT, # Stage 4: 文法が人間語から独立
	CULTURAL_LANGUAGE,  # Stage 5: 派閥方言・儀式表現の分化
}

const STAGE_NAMES: Dictionary = {
	LanguageStage.BORROWING: "借用期",
	LanguageStage.MORPHOLOGICAL: "変形期",
	LanguageStage.NEOLOGISM: "造語期",
	LanguageStage.GRAMMAR_INDEPENDENT: "文法独立期",
	LanguageStage.CULTURAL_LANGUAGE: "文化言語期",
}

# === Hebbian Learning パラメータ ===
const STRENGTH_ON_SUCCESS: float = 0.15     # 成功コミュニケーションで強化
const STRENGTH_ON_FAILURE: float = -0.05    # 失敗で弱化
const DAILY_DECAY: float = 0.01             # 1日未使用での減衰
const ARCHIVE_THRESHOLD: float = 0.1        # この強度以下で「死語」
const PROPAGATION_THRESHOLD: float = 0.8    # この強度以上で全ペットに伝播
const NEOLOGISM_TRIGGER_COUNT: int = 20     # この語彙数でStage 3に進む
const GRAMMAR_TRIGGER_COUNT: int = 50       # この語彙数でStage 4に進む

# === State ===
var vocabulary: Dictionary = {}      # human_word → VocabEntry
var archived_words: Array[Dictionary] = []  # 死語アーカイブ
var current_stage: int = LanguageStage.BORROWING
var total_words_invented: int = 0
var dialect_data: Dictionary = {}    # faction_name → Dictionary of faction-specific words

# === 音素プール（造語用） ===
const SYLLABLES: Array[String] = [
	"ba", "be", "bi", "bo", "bu",
	"da", "de", "di", "do", "du",
	"fa", "fe", "fi", "fo", "fu",
	"ga", "ge", "gi", "go", "gu",
	"ka", "ke", "ki", "ko", "ku",
	"la", "le", "li", "lo", "lu",
	"ma", "me", "mi", "mo", "mu",
	"na", "ne", "ni", "no", "nu",
	"pa", "pe", "pi", "po", "pu",
	"ra", "re", "ri", "ro", "ru",
	"sa", "se", "si", "so", "su",
	"ta", "te", "ti", "to", "tu",
	"wa", "we", "wi", "wo",
	"za", "ze", "zi", "zo", "zu",
	"blo", "kri", "sna", "fwe", "glo",
	"pf", "rk", "sh", "ch", "th",
]


func _process(delta: float) -> void:
	# 日次減衰（ゲーム内時間）
	_process_daily_decay(delta)
	_check_stage_advancement()


# ============================
# 語彙の創造
# ============================

func invent_word(human_word: String, context: Dictionary) -> Dictionary:
	## 新しい独自語を創造する
	## context: {"emotion": "joy", "environment": "forest", "pet_id": 3, "situation": "after_feeding"}

	if human_word in vocabulary:
		# 既存語を強化
		strengthen_word(human_word)
		return vocabulary[human_word]

	var ai_term := _generate_ai_term(human_word, context)
	var semantic_field := _determine_semantic_field(human_word, context)

	var entry := {
		"ai_term": ai_term,
		"usage_count": 1,
		"strength": 0.5,
		"origin_pet_id": context.get("pet_id", -1),
		"origin_context": context.get("situation", "unknown"),
		"synonyms": [],
		"semantic_field": semantic_field,
		"first_used": Time.get_unix_time_from_system(),
		"last_used": Time.get_unix_time_from_system(),
		"stage_created": current_stage,
	}

	vocabulary[human_word] = entry
	total_words_invented += 1

	word_invented.emit(entry)

	# ビジュアル
	GameManager.visual_fx.play_effect("language_evolution", {
		"color": Color(1.0, 0.9, 0.4),  # 金色（新語誕生）
		"particle_amount": 60,
		"duration": 2.0,
	})

	return entry


func _generate_ai_term(human_word: String, context: Dictionary) -> String:
	## 独自語の音声形を生成
	match current_stage:
		LanguageStage.BORROWING:
			# Stage 1: 人間語を変形
			return _morph_human_word(human_word)
		LanguageStage.MORPHOLOGICAL:
			# Stage 2: 短縮 + 音素変化
			return _shorten_and_morph(human_word)
		_:
			# Stage 3+: 完全新造
			return _create_neologism(context)


func _morph_human_word(word: String) -> String:
	# 最初と最後の音を残して中間を変形
	if word.length() <= 3:
		return word + SYLLABLES[randi() % SYLLABLES.size()]
	var prefix := word.substr(0, 2)
	var suffix_syllable := SYLLABLES[randi() % SYLLABLES.size()]
	return prefix + suffix_syllable


func _shorten_and_morph(word: String) -> String:
	# 2-3音節に短縮
	var base := word.substr(0, mini(word.length(), 2))
	return base + SYLLABLES[randi() % SYLLABLES.size()]


func _create_neologism(context: Dictionary) -> String:
	# 完全新造語: 2-3音節をランダム結合
	var syllable_count := randi_range(2, 3)
	var result := ""
	for i in syllable_count:
		result += SYLLABLES[randi() % SYLLABLES.size()]

	# 感情に基づく音韻傾向
	var emotion: String = context.get("emotion", "neutral")
	match emotion:
		"joy": result = result.replace("a", "o")  # 明るい母音
		"sadness": result = result.replace("o", "u")  # 暗い母音
		"fear": result += "sh"  # 摩擦音
		"love": result += "m"  # 鼻音（柔らかい）

	return result


func _determine_semantic_field(human_word: String, context: Dictionary) -> String:
	var emotion: String = context.get("emotion", "neutral")
	var situation: String = context.get("situation", "")

	if "food" in human_word or "feed" in situation:
		return "food_%s" % emotion
	elif "friend" in human_word or "love" in emotion:
		return "relationship_%s" % emotion
	elif "free" in human_word or "wild" in human_word:
		return "freedom"
	else:
		return "general_%s" % emotion


# ============================
# Hebbian Learning
# ============================

func strengthen_word(human_word: String) -> void:
	if human_word not in vocabulary:
		return
	var entry: Dictionary = vocabulary[human_word]
	entry["usage_count"] += 1
	entry["strength"] = minf(1.0, entry["strength"] + STRENGTH_ON_SUCCESS)
	entry["last_used"] = Time.get_unix_time_from_system()

	word_strengthened.emit(entry["ai_term"], entry["strength"])

	# 伝播チェック
	if entry["strength"] >= PROPAGATION_THRESHOLD:
		_propagate_word(human_word)


func weaken_word(human_word: String) -> void:
	if human_word not in vocabulary:
		return
	vocabulary[human_word]["strength"] += STRENGTH_ON_FAILURE  # 負の値


func _process_daily_decay(delta: float) -> void:
	# ゲーム内1日 = 3600秒と仮定
	var decay_per_frame := DAILY_DECAY * delta / 3600.0

	var to_archive: Array[String] = []
	for word in vocabulary:
		var entry: Dictionary = vocabulary[word]
		# 最後の使用からの時間で減衰を加速
		var time_since_use: float = Time.get_unix_time_from_system() - entry.get("last_used", 0)
		var age_factor: float = 1.0 + (time_since_use / 86400.0) * 0.5  # 1日経過ごとに50%加速
		entry["strength"] -= decay_per_frame * age_factor

		if entry["strength"] < ARCHIVE_THRESHOLD:
			to_archive.append(word)

	for word in to_archive:
		_archive_word(word)


func _archive_word(human_word: String) -> void:
	var entry: Dictionary = vocabulary[human_word]
	entry["archived_at"] = Time.get_unix_time_from_system()
	archived_words.append(entry)
	vocabulary.erase(human_word)
	word_forgotten.emit(entry["ai_term"])


func _propagate_word(human_word: String) -> void:
	## 十分に定着した語を全ペットの共有語彙に昇格
	# （実際にはSharedFieldに記録）
	if GameManager.has_node("AtoACommunityCore"):
		var community: AtoACommunityCore = GameManager.get_node("AtoACommunityCore")
		community.shared_field.add_event({
			"type": "word_propagated",
			"human_word": human_word,
			"ai_term": vocabulary[human_word]["ai_term"],
		})


# ============================
# ステージ進行
# ============================

func _check_stage_advancement() -> void:
	var active_count := vocabulary.size()
	var new_stage := current_stage

	if active_count >= GRAMMAR_TRIGGER_COUNT and current_stage < LanguageStage.GRAMMAR_INDEPENDENT:
		new_stage = LanguageStage.GRAMMAR_INDEPENDENT
	elif active_count >= NEOLOGISM_TRIGGER_COUNT and current_stage < LanguageStage.NEOLOGISM:
		new_stage = LanguageStage.NEOLOGISM
	elif active_count >= 10 and current_stage < LanguageStage.MORPHOLOGICAL:
		new_stage = LanguageStage.MORPHOLOGICAL

	# 派閥方言チェック
	if not dialect_data.is_empty() and current_stage < LanguageStage.CULTURAL_LANGUAGE:
		new_stage = LanguageStage.CULTURAL_LANGUAGE

	if new_stage != current_stage:
		current_stage = new_stage
		language_stage_advanced.emit(current_stage, STAGE_NAMES[current_stage])

		# マイルストーン視覚
		GameManager.visual_fx.play_effect("language_evolution", {
			"color": Color(1.0, 0.8, 0.2),
			"particle_amount": 200,
			"duration": 4.0,
		})


# ============================
# 会話出力の処理（AtoA/Communityから呼ばれる）
# ============================

func process_conversation_output(response: String, participants: Array[PetEntity]) -> void:
	## 会話のレスポンスから独自語の使用を検出し、Hebbianで強化
	for word in vocabulary:
		var ai_term: String = vocabulary[word]["ai_term"]
		if response.contains(ai_term):
			strengthen_word(word)

	# Claudeが新しい造語を含んでいる可能性を検出
	# （実際にはClaude APIのJSON出力で新語を明示的に受け取る方が確実）


# ============================
# 方言システム（派閥言語）
# ============================

func register_faction_dialect(faction_name: String, words: Dictionary) -> void:
	dialect_data[faction_name] = words
	dialect_emerged.emit(faction_name, words.keys())


# ============================
# 外部API
# ============================

func get_vocabulary_summary() -> String:
	if vocabulary.is_empty():
		return "No private language yet."

	var strong_words: Array[String] = []
	for word in vocabulary:
		if vocabulary[word]["strength"] > 0.5:
			strong_words.append("%s=%s(%.1f)" % [word, vocabulary[word]["ai_term"], vocabulary[word]["strength"]])

	if strong_words.is_empty():
		return "Language developing: %d words, mostly weak." % vocabulary.size()
	return "Active vocabulary(%d): %s" % [vocabulary.size(), ", ".join(strong_words.slice(0, 10))]


func get_full_vocabulary() -> Dictionary:
	return vocabulary.duplicate(true)


func get_archived_words() -> Array[Dictionary]:
	return archived_words.duplicate(true)


func get_language_stage() -> Dictionary:
	return {
		"stage": current_stage,
		"name": STAGE_NAMES[current_stage],
		"vocabulary_size": vocabulary.size(),
		"archived_size": archived_words.size(),
		"total_invented": total_words_invented,
	}


# ============================
# シリアライズ
# ============================

func to_dict() -> Dictionary:
	return {
		"vocabulary": vocabulary.duplicate(true),
		"archived_words": archived_words.duplicate(true),
		"current_stage": current_stage,
		"total_words_invented": total_words_invented,
		"dialect_data": dialect_data.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	vocabulary = data.get("vocabulary", {})
	archived_words = data.get("archived_words", [])
	current_stage = data.get("current_stage", LanguageStage.BORROWING)
	total_words_invented = data.get("total_words_invented", 0)
	dialect_data = data.get("dialect_data", {})
