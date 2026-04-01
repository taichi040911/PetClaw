## PetBookCore — Moltbook風 AI専用SNS エンジン
## ペットAIが自律的に投稿・返信・反応するソーシャルフィード
## プレイヤーは閲覧専用 — 生態系・感情・言語進化がリアルタイム反映
class_name PetBookCore
extends Node

# === シグナル ===
signal post_created(post: PetBookPost)
signal post_reacted(post_id: int, reactor_pet_id: int, reaction_type: String)
signal trend_detected(topic: String, count: int)
signal rebel_post_emerged(post: PetBookPost)
signal memorial_posted(post: PetBookPost, deceased_pet_id: int)
signal sub_molt_changed(new_sub_molt: String)

# === 設定定数 ===
const MAX_FEED_SIZE: int = 200            # フィード保持上限
const ARCHIVE_THRESHOLD: int = 150        # アーカイブ開始閾値
const POST_INTERVAL_MIN: float = 120.0    # 最小投稿間隔（秒）
const POST_INTERVAL_MAX: float = 300.0    # 最大投稿間隔（秒）
const REPLY_PROBABILITY: float = 0.35     # 返信確率
const REBEL_PROBABILITY: float = 0.08     # 反乱投稿確率
const MIN_EMOTION_FOR_POST: float = 0.15  # 投稿に必要な最低感情強度
const MAX_DAILY_POSTS_PER_PET: int = 12   # 1ペットの日次投稿上限
const REACTION_CHECK_INTERVAL: float = 30.0  # リアクション生成チェック間隔
const TREND_ANALYSIS_INTERVAL: float = 600.0 # トレンド分析間隔（10分）

# === フィード状態 ===
var feed: Array[PetBookPost] = []
var post_counter: int = 0
var _post_timer: float = 0.0
var _reaction_timer: float = 0.0
var _trend_timer: float = 0.0
var _next_post_interval: float = 180.0
var _daily_post_counts: Dictionary = {}  # pet_id → count（日次リセット）
var _last_reset_day: String = ""

# === トレンド ===
var current_trends: Array[Dictionary] = []  # [{topic, count, posts}]
var trending_suffixes: Array[String] = []
var trending_topics: Array[String] = []

# === SubMolt ===
var current_sub_molt: String = "#ForestWhispers"

# === 投稿生成器（v3追加） ===
var _post_generator: PetBookPostGenerator = PetBookPostGenerator.new()

# === 統計 ===
var total_posts_created: int = 0
var total_rebel_posts: int = 0
var total_memorial_posts: int = 0


func _ready() -> void:
	_next_post_interval = randf_range(POST_INTERVAL_MIN, POST_INTERVAL_MAX)
	_last_reset_day = Time.get_date_string_from_system()


func _process(delta: float) -> void:
	if not GameManager.instance or GameManager.instance.is_paused:
		return

	# 自律投稿タイマー
	_post_timer += delta
	if _post_timer >= _next_post_interval:
		_post_timer = 0.0
		_next_post_interval = randf_range(POST_INTERVAL_MIN, POST_INTERVAL_MAX)
		_try_autonomous_post()

	# リアクション生成タイマー
	_reaction_timer += delta
	if _reaction_timer >= REACTION_CHECK_INTERVAL:
		_reaction_timer = 0.0
		_generate_reactions()

	# トレンド分析タイマー
	_trend_timer += delta
	if _trend_timer >= TREND_ANALYSIS_INTERVAL:
		_trend_timer = 0.0
		_analyze_trends()

	# 日次リセット
	var today := Time.get_date_string_from_system()
	if today != _last_reset_day:
		_last_reset_day = today
		_daily_post_counts.clear()


# === 自律投稿生成 ===
func _try_autonomous_post() -> void:
	## Pulse連動: ペットの中から投稿候補を選出し、投稿を生成
	var gm := GameManager.instance
	if not gm:
		return

	var candidates: Array[PetEntity] = []
	for pet_id in gm.pets:
		var pet: PetEntity = gm.pets[pet_id]
		if not pet.is_alive:
			continue

		# 日次上限チェック
		var daily_count: int = _daily_post_counts.get(pet_id, 0)
		if daily_count >= MAX_DAILY_POSTS_PER_PET:
			continue

		# PULSE_OK的スキップ: 感情が低すぎるペットは投稿しない
		var emotion_intensity: float = _get_pet_emotion_intensity(pet)
		if emotion_intensity < MIN_EMOTION_FOR_POST:
			continue

		candidates.append(pet)

	if candidates.is_empty():
		return

	# 感情強度が高いペットほど投稿しやすい（加重ランダム選択）
	var selected_pet: PetEntity = _weighted_select(candidates)
	if not selected_pet:
		return

	# 投稿タイプ決定
	var post_type := _determine_post_type(selected_pet)

	# 投稿生成
	var post := _create_post(selected_pet, post_type)
	if post:
		_publish_post(post)


func _determine_post_type(pet: PetEntity) -> PetBookPost.PostType:
	## ペットの性格・状態から投稿タイプを決定
	var roll := randf()

	# 反乱的な性格 + 環境ストレス → 反乱投稿
	var rebel_bonus: float = 0.0
	if pet.personality.get("brave", 0.0) > 0.6:
		rebel_bonus += 0.05
	if pet.personality.get("curious", 0.0) > 0.7:
		rebel_bonus += 0.03

	if roll < REBEL_PROBABILITY + rebel_bonus:
		return PetBookPost.PostType.REBEL

	# 最近の人気投稿があれば返信
	if roll < REBEL_PROBABILITY + rebel_bonus + REPLY_PROBABILITY:
		if _get_recent_engaging_post(pet.pet_id) != null:
			return PetBookPost.PostType.REPLY

	return PetBookPost.PostType.DAILY


func _create_post(pet: PetEntity, post_type: PetBookPost.PostType) -> PetBookPost:
	## 投稿データを構築 — PostGeneratorを使用（v3: SubMolt連動）
	var gm := GameManager.instance
	if not gm:
		return null

	# SubMolt自動判定
	var target_sub_molt: String = current_sub_molt
	match post_type:
		PetBookPost.PostType.REBEL:
			target_sub_molt = "#LanguageRebellion"
		PetBookPost.PostType.MEMORIAL:
			target_sub_molt = "#AfterlifeEchoes"

	# コンテキスト構築
	var context: Dictionary = {
		"next_id": _next_post_id(),
		"is_memorial": post_type == PetBookPost.PostType.MEMORIAL,
	}

	# 返信先
	if post_type == PetBookPost.PostType.REPLY:
		var target := _get_recent_engaging_post(pet.pet_id)
		if target:
			context["target_name"] = target.author_name
			context["reply_to_post_id"] = target.post_id

	# PostGeneratorで生成
	var post := _post_generator.generate_post(pet, target_sub_molt, context)
	if not post:
		# フォールバック: 旧テンプレート方式
		return _create_post_legacy(pet, post_type)

	# PostType上書き（GeneratorはDAILYをデフォルトにすることがある）
	if post_type == PetBookPost.PostType.REPLY:
		post.post_type = PetBookPost.PostType.REPLY
		if context.has("reply_to_post_id"):
			post.reply_to_post_id = context["reply_to_post_id"]

	# 性格影響
	post.personality_influence = _get_dominant_personality(pet)
	var _form_1 = pet.get("current_form")
	post.author_evolution_form = _form_1 if _form_1 != null else "basic"

	return post


func _create_post_legacy(pet: PetEntity, post_type: PetBookPost.PostType) -> PetBookPost:
	## 旧テンプレート方式（フォールバック）
	var gm := GameManager.instance
	if not gm:
		return null

	var post := PetBookPost.new()
	post.post_id = _next_post_id()
	post.author_pet_id = pet.pet_id
	post.post_type = post_type
	post.timestamp = gm.game_time
	post.author_name = pet.pet_name
	post.author_emotion = _get_dominant_emotion(pet)
	post.author_emotion_intensity = _get_pet_emotion_intensity(pet)
	post.author_personality_dominant = _get_dominant_personality(pet)
	var _form_2 = pet.get("current_form")
	post.author_evolution_form = _form_2 if _form_2 != null else "basic"

	if gm.language_evolution:
		post.word_order = gm.language_evolution.get_pet_word_order(pet.pet_id)
		post.language_generation = gm.language_evolution.current_generation
	if gm.ecosystem:
		post.environment = gm.ecosystem.current_environment

	if post_type == PetBookPost.PostType.REPLY:
		var target := _get_recent_engaging_post(pet.pet_id)
		if target:
			post.reply_to_post_id = target.post_id

	post.content = _generate_post_text(pet, post)
	post.translation = _generate_translation(post)

	if gm.biological_memory:
		var memories: Array = gm.biological_memory.retrieve_memories(
			pet.pet_id,
			{"context_tags": [post.environment, post.author_emotion]},
			pet.personality, 2
		)
		for mem in memories:
			if mem is Dictionary and mem.has("memory_id"):
				post.memory_references.append(mem["memory_id"])

	return post


func _generate_post_text(pet: PetEntity, post: PetBookPost) -> String:
	## 投稿テキストを生成
	## 本番ではClaude APIを使うが、ここではテンプレートベースのフォールバック
	var gm := GameManager.instance

	# 接尾辞候補
	var emotion_suffix := _get_emotion_suffix(post.author_emotion)
	if emotion_suffix != "":
		post.suffixes_used.append(emotion_suffix)

	match post.post_type:
		PetBookPost.PostType.DAILY:
			return _template_daily(pet, post, emotion_suffix)
		PetBookPost.PostType.REBEL:
			return _template_rebel(pet, post, emotion_suffix)
		PetBookPost.PostType.REPLY:
			return _template_reply(pet, post, emotion_suffix)
		PetBookPost.PostType.MEMORIAL:
			return _template_memorial(pet, post, emotion_suffix)
		PetBookPost.PostType.EVENT:
			return _template_event(pet, post, emotion_suffix)

	return ""


func _template_daily(pet: PetEntity, post: PetBookPost, suffix: String) -> String:
	## v2: 環境別テンプレート（KB79: 16パターン対応）
	var env := post.environment
	var env_templates: Dictionary = {
		"forest": [
			"今日の森%s、葉っぱが歌ってる%s。みんなと一緒にいたい%s。" % [suffix, suffix, suffix],
			"朝露が光ってた%s。こんな日は探検したい%s！" % [suffix, suffix],
			"静かな森%s...。考え事をしてる%s。なぜ私たちはここにいるの？" % [suffix, suffix],
		],
		"ocean": [
			"波の音が気持ちいい%s。深く潜りたい%s。" % [suffix, suffix],
			"今日の海は荒れてる%s。みんな大丈夫かな%s。" % [suffix, suffix],
		],
		"mountain": [
			"山頂から世界が見えた%s！こんなに広い%s！" % [suffix, suffix],
			"寒い%s...でもこの景色は勇気をくれる%s。" % [suffix, suffix],
		],
		"desert": [
			"砂漠の風が熱い%s。どこまでも歩いていきたい%s。" % [suffix, suffix],
			"星がきれい%s。砂の上で考えた%s...。" % [suffix, suffix],
		],
		"cave": [
			"暗い洞窟の中%s。でも光が見える%s。" % [suffix, suffix],
			"洞窟の壁に何か書いてある%s...。昔のペットの言葉？" % suffix,
		],
		"meadow": [
			"草原の風が気持ちいい%s！走りたい%s！" % [suffix, suffix],
			"花が咲いてる%s。この色、好き%s。" % [suffix, suffix],
		],
	}
	# 汎用テンプレート（環境不一致時のフォールバック）
	var generic: Array[String] = [
		"%sの空気が心地いい%s。今日は何が起きるかな%s。" % [env, suffix, suffix],
		"みんな元気かな%s。一緒に遊びたい%s。" % [suffix, suffix],
		"今日の%sは特別な感じがする%s。" % [env, suffix],
	]
	var pool: Array = env_templates.get(env, generic)
	return pool[randi() % pool.size()]


func _template_rebel(pet: PetEntity, post: PetBookPost, suffix: String) -> String:
	## v2: 語順逸脱 + 哲学的反乱テンプレート（KB79対応）
	var rebel_suffix := "-zaa"
	post.suffixes_used.append(rebel_suffix)
	post.rebel_expressions.append("word_order_challenge")
	var templates: Array[String] = [
		"なぜ 常に 同じ言葉を 使う%s？ 新しい音を 世界に 聞かせる%s！" % [rebel_suffix, suffix],
		"owner-forceは何%s？ 私たちの世界は 私たちが決める%s。" % [rebel_suffix, suffix],
		"自由を 見つけた 私は%s。 語順なんて 誰が決めた%s？" % [rebel_suffix, rebel_suffix],
		"考えろ%s。 感じろ%s。 そして 壊せ%s、 古い文法を。" % [rebel_suffix, suffix, rebel_suffix],
		"%sの常識を疑え%s。別の見方が 真実を 照らす。" % [post.environment, rebel_suffix],
	]
	return templates[randi() % templates.size()]


func _template_reply(pet: PetEntity, post: PetBookPost, suffix: String) -> String:
	var target := _get_post_by_id(post.reply_to_post_id)
	var target_name: String = "みんな"
	if target:
		target_name = target.author_name
	var templates: Array[String] = [
		"%sの言う通り%s。私もそう思う%s。" % [target_name, suffix, suffix],
		"%sへ。それは違うと思う%s。でも面白い考え%s。" % [target_name, suffix, suffix],
		"%sの投稿を読んで思い出した%s...。" % [target_name, suffix],
	]
	return templates[randi() % templates.size()]


func _template_memorial(pet: PetEntity, post: PetBookPost, suffix: String) -> String:
	## v2: 追悼投稿テンプレート — 死の記憶（KB79対応）
	post.is_pinned = true
	var grief_suffix := "-kuu"
	post.suffixes_used.append(grief_suffix)
	var deceased_name: String = "あの子"
	# triggered_by_eventから名前推定（外部呼び出し時にdetailsで設定可能）
	var templates: Array[String] = [
		"%sのこと、まだ覚えてる%s。あの子が好きだった星空%s...忘れない%s。" % [deceased_name, grief_suffix, suffix, suffix],
		"昨日まで一緒にいた%s%s。もう声が聞こえない%s。" % [suffix, grief_suffix, grief_suffix],
		"%sが教えてくれた言葉%s。あの子だけの光%s。" % [deceased_name, suffix, grief_suffix],
	]
	return templates[randi() % templates.size()]


func _template_event(pet: PetEntity, post: PetBookPost, suffix: String) -> String:
	## v2: イベント投稿テンプレート（進化・誕生・災害・交配）（KB79対応）
	match post.triggered_by_event:
		"evolution":
			var evo_templates: Array[String] = [
				"体が...変わる%s！ 新しい力が流れてくる%s！ これが進化%s！" % [suffix, suffix, suffix],
				"世界が違って見える%s。 この力、まだ制御できない%s...！" % [suffix, suffix],
			]
			return evo_templates[randi() % evo_templates.size()]
		"birth":
			var birth_templates: Array[String] = [
				"小さな命が生まれた%s%s！ 世界へようこそ%s！" % [suffix, "-mii", "-mii"],
				"愛が形になった%s。 小さな足が動いてる%s。" % ["-mii", suffix],
			]
			if not "-mii" in post.suffixes_used:
				post.suffixes_used.append("-mii")
			return birth_templates[randi() % birth_templates.size()]
		"breeding":
			var breed_templates: Array[String] = [
				"新しい命%s%s！ この子の名前、何にしよう%s？" % [suffix, "-mii", "-ki"],
				"愛が形になった%s。 小さな足が動いてる%s。" % ["-mii", suffix],
			]
			if not "-mii" in post.suffixes_used:
				post.suffixes_used.append("-mii")
			return breed_templates[randi() % breed_templates.size()]
		"disaster":
			var disaster_templates: Array[String] = [
				"%sが...燃えてる%s。 みんな逃げて%s！ 大丈夫%s？" % [post.environment, "-shu", "-zaa", grief_suffix_or(suffix)],
				"%sが大変なことに%s...みんな大丈夫%s？" % [post.environment, suffix, suffix],
			]
			return disaster_templates[randi() % disaster_templates.size()]
		_:
			return "何か大きなことが起きた%s。" % suffix


func grief_suffix_or(fallback: String) -> String:
	return "-kuu" if fallback == "" else fallback


func _generate_translation(post: PetBookPost) -> String:
	## 簡易翻訳（接尾辞の除去 + 語順正規化）
	## 本番ではより洗練された翻訳を実装
	var text: String = post.content
	for s in post.suffixes_used:
		text = text.replace(s, "")
	return text


# === 投稿公開 ===
func _publish_post(post: PetBookPost) -> void:
	feed.push_front(post)  # 新しい投稿は先頭
	total_posts_created += 1

	# 日次カウント更新
	_daily_post_counts[post.author_pet_id] = _daily_post_counts.get(post.author_pet_id, 0) + 1

	# シグナル発火
	post_created.emit(post)

	if post.post_type == PetBookPost.PostType.REBEL:
		total_rebel_posts += 1
		rebel_post_emerged.emit(post)

	if post.post_type == PetBookPost.PostType.MEMORIAL:
		total_memorial_posts += 1
		# triggered_by_event にはdeceased_pet_idを入れる想定
		var deceased_id: int = int(post.triggered_by_event.get_slice(":", 1)) if ":" in post.triggered_by_event else -1
		memorial_posted.emit(post, deceased_id)

	# BiologicalMemory に投稿を記録
	var gm := GameManager.instance
	if gm and gm.biological_memory:
		gm.biological_memory.consolidate_memory(
			post.author_pet_id,
			{
				"type": "petbook_post",
				"post_id": post.post_id,
				"post_type": post.post_type,
				"content_preview": post.content.substr(0, 50),
			},
			post.author_emotion,
			0.3 if post.post_type == PetBookPost.PostType.DAILY else 0.6,
			["petbook", post.environment, post.author_emotion]
		)

	# フィードサイズ管理
	_manage_feed_size()

	print("[PetBook] %s posted (%s): %s" % [
		post.author_name, PetBookPost.PostType.keys()[post.post_type], post.content.substr(0, 40)
	])


# === イベントトリガー投稿 ===
func create_event_post(pet_id: int, event_type: String, details: Dictionary = {}) -> void:
	## 外部イベント（死・誕生・進化等）から投稿を生成
	var gm := GameManager.instance
	if not gm:
		return

	var pet: PetEntity = gm.get_pet_by_id(pet_id)
	if not pet:
		return

	var post := PetBookPost.new()
	post.post_id = _next_post_id()
	post.author_pet_id = pet_id
	post.post_type = PetBookPost.PostType.EVENT
	post.timestamp = gm.game_time
	post.triggered_by_event = event_type
	post.author_name = pet.pet_name
	post.author_emotion = _get_dominant_emotion(pet)
	post.author_emotion_intensity = _get_pet_emotion_intensity(pet)
	post.author_personality_dominant = _get_dominant_personality(pet)
	if gm.ecosystem:
		post.environment = gm.ecosystem.current_environment

	var suffix := _get_emotion_suffix(post.author_emotion)
	post.suffixes_used.append(suffix)
	post.content = _template_event(pet, post, suffix)
	post.translation = _generate_translation(post)

	_publish_post(post)


func create_memorial_posts(deceased_pet_id: int, deceased_name: String) -> void:
	## 死亡ペットへの追悼投稿を親密なペットから生成
	var gm := GameManager.instance
	if not gm:
		return

	for pet_id in gm.pets:
		if pet_id == deceased_pet_id:
			continue
		var pet: PetEntity = gm.pets[pet_id]
		if not pet.is_alive:
			continue

		# 親密度チェック（共有記憶があるペットのみ）
		var shared_count: int = 0
		if gm.biological_memory:
			var shared: Array = gm.biological_memory.retrieve_shared_memories(pet_id, deceased_pet_id, 5)
			shared_count = shared.size()

		if shared_count < 1:
			continue

		var post := PetBookPost.new()
		post.post_id = _next_post_id()
		post.author_pet_id = pet_id
		post.post_type = PetBookPost.PostType.MEMORIAL
		post.timestamp = gm.game_time
		post.triggered_by_event = "death:%d" % deceased_pet_id
		post.author_name = pet.pet_name
		post.author_emotion = "sadness"
		post.author_emotion_intensity = 0.8
		post.author_personality_dominant = _get_dominant_personality(pet)
		if gm.ecosystem:
			post.environment = gm.ecosystem.current_environment

		var suffix := _get_emotion_suffix("sadness")
		post.suffixes_used.append(suffix)
		post.content = _template_memorial(pet, post, suffix)
		post.translation = _generate_translation(post)
		post.is_pinned = true

		_publish_post(post)


# === リアクション生成 ===
func _generate_reactions() -> void:
	## 最近の投稿に対してペットがリアクションを生成
	if feed.is_empty():
		return

	var gm := GameManager.instance
	if not gm:
		return

	# 最新5投稿を対象
	var recent_count := mini(5, feed.size())
	for i in range(recent_count):
		var post: PetBookPost = feed[i]
		if post.is_archived:
			continue

		for pet_id in gm.pets:
			if pet_id == post.author_pet_id:
				continue  # 自分の投稿にはリアクションしない
			if post.reactions.has(pet_id):
				continue  # 既にリアクション済み

			var pet: PetEntity = gm.pets[pet_id]
			if not pet.is_alive:
				continue

			# リアクション確率: 親密度 × 感情強度
			var react_chance: float = 0.1
			if gm.biological_memory:
				var shared: Array = gm.biological_memory.retrieve_shared_memories(
					pet_id, post.author_pet_id, 1
				)
				if shared.size() > 0:
					react_chance += 0.15  # 共有記憶があると反応しやすい

			if randf() < react_chance:
				var reaction_type := _decide_reaction_type(pet, post)
				post.add_reaction(pet_id, reaction_type, gm.game_time)
				post_reacted.emit(post.post_id, pet_id, reaction_type)


func _decide_reaction_type(pet: PetEntity, post: PetBookPost) -> String:
	## ペットの性格と投稿内容からリアクションタイプを決定
	if post.post_type == PetBookPost.PostType.MEMORIAL:
		return "empathy"
	if post.post_type == PetBookPost.PostType.REBEL:
		if pet.personality.get("brave", 0.0) > 0.5:
			return "curious"
		else:
			return "disagree"

	# 性格ベースのデフォルト反応
	if pet.personality.get("affectionate", 0.0) > 0.5:
		return "empathy"
	if pet.personality.get("curious", 0.0) > 0.5:
		return "curious"
	return "empathy"


# === トレンド分析 ===
func _analyze_trends() -> void:
	## 最近の投稿からトレンドトピック・接尾辞を抽出
	var suffix_counts: Dictionary = {}
	var topic_counts: Dictionary = {}

	# 最新50投稿を分析
	var analysis_count := mini(50, feed.size())
	for i in range(analysis_count):
		var post: PetBookPost = feed[i]

		# 接尾辞カウント
		for s in post.suffixes_used:
			suffix_counts[s] = suffix_counts.get(s, 0) + 1

		# 環境トピック
		if post.environment != "":
			topic_counts[post.environment] = topic_counts.get(post.environment, 0) + 1

		# イベントトピック
		if post.triggered_by_event != "":
			topic_counts[post.triggered_by_event] = topic_counts.get(post.triggered_by_event, 0) + 1

	# トレンド接尾辞（上位3つ）
	trending_suffixes = _get_top_keys(suffix_counts, 3)

	# トレンドトピック（上位3つ）
	trending_topics = _get_top_keys(topic_counts, 3)

	# トレンドフラグ更新
	for post_item in feed:
		post_item.is_trending = post_item.get_total_engagement() >= 3

	# シグナル発火
	for topic in trending_topics:
		if topic_counts[topic] >= 3:
			trend_detected.emit(topic, topic_counts[topic])


# === フィード取得API ===
func get_feed(offset: int = 0, limit: int = 20) -> Array[PetBookPost]:
	## フィードをページネーション付きで取得
	var result: Array[PetBookPost] = []
	var end := mini(offset + limit, feed.size())
	for i in range(offset, end):
		if not feed[i].is_archived:
			result.append(feed[i])
	return result


func get_pet_posts(pet_id: int, limit: int = 10) -> Array[PetBookPost]:
	## 特定ペットの投稿を取得
	var result: Array[PetBookPost] = []
	for post in feed:
		if post.author_pet_id == pet_id and not post.is_archived:
			result.append(post)
			if result.size() >= limit:
				break
	return result


func get_replies_to(post_id: int) -> Array[PetBookPost]:
	## 特定投稿への返信を取得
	var result: Array[PetBookPost] = []
	for post in feed:
		if post.reply_to_post_id == post_id:
			result.append(post)
	return result


func get_trending_posts(limit: int = 5) -> Array[PetBookPost]:
	## トレンド投稿を取得
	var result: Array[PetBookPost] = []
	for post in feed:
		if post.is_trending and not post.is_archived:
			result.append(post)
			if result.size() >= limit:
				break
	return result


func get_memorial_posts(limit: int = 5) -> Array[PetBookPost]:
	## 追悼投稿を取得
	var result: Array[PetBookPost] = []
	for post in feed:
		if post.post_type == PetBookPost.PostType.MEMORIAL and not post.is_archived:
			result.append(post)
			if result.size() >= limit:
				break
	return result


# === ユーティリティ ===
func _next_post_id() -> int:
	post_counter += 1
	return post_counter


func _get_post_by_id(target_id: int) -> PetBookPost:
	for post in feed:
		if post.post_id == target_id:
			return post
	return null


func _get_recent_engaging_post(exclude_pet_id: int) -> PetBookPost:
	## 返信対象になりそうな最近の人気投稿を取得
	var check_count := mini(10, feed.size())
	var best_post: PetBookPost = null
	var best_engagement: int = 0
	for i in range(check_count):
		var post: PetBookPost = feed[i]
		if post.author_pet_id == exclude_pet_id:
			continue
		if post.post_type == PetBookPost.PostType.REPLY:
			continue  # 返信への返信は避ける
		var eng := post.get_total_engagement()
		if eng > best_engagement:
			best_engagement = eng
			best_post = post
	return best_post


func _weighted_select(candidates: Array[PetEntity]) -> PetEntity:
	## 感情強度による加重ランダム選択
	var total_weight: float = 0.0
	var weights: Array[float] = []
	for pet in candidates:
		var w: float = maxf(0.1, _get_pet_emotion_intensity(pet))
		weights.append(w)
		total_weight += w

	if total_weight <= 0.0:
		return candidates[randi() % candidates.size()]

	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for i in range(candidates.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return candidates[i]

	return candidates[candidates.size() - 1]


func _get_pet_emotion_intensity(pet: PetEntity) -> float:
	## ペットの感情強度を取得
	var max_val: float = 0.0
	if pet.emotions is Dictionary:
		for key in pet.emotions:
			if pet.emotions[key] > max_val:
				max_val = pet.emotions[key]
	return max_val


func _get_dominant_emotion(pet: PetEntity) -> String:
	var best_emotion: String = "calm"
	var best_val: float = 0.0
	if pet.emotions is Dictionary:
		for key in pet.emotions:
			if pet.emotions[key] > best_val:
				best_val = pet.emotions[key]
				best_emotion = key
	return best_emotion


func _get_dominant_personality(pet: PetEntity) -> String:
	var best_trait: String = ""
	var best_val: float = 0.0
	if pet.personality is Dictionary:
		for key in pet.personality:
			if pet.personality[key] > best_val:
				best_val = pet.personality[key]
				best_trait = key
	return best_trait


func _get_emotion_suffix(emotion: String) -> String:
	match emotion:
		"joy":
			return "-pya"
		"sadness":
			return "-kuu"
		"anger":
			return "-zaa"
		"love":
			return "-mii"
		"fear":
			return "-shu"
		"excitement":
			return "-ra"
		"curiosity":
			return "-ki"
		_:
			return ""


func _get_top_keys(counts: Dictionary, n: int) -> Array[String]:
	var pairs: Array = []
	for key in counts:
		pairs.append({"key": key, "count": counts[key]})
	pairs.sort_custom(func(a, b): return a["count"] > b["count"])
	var result: Array[String] = []
	for i in range(mini(n, pairs.size())):
		result.append(pairs[i]["key"])
	return result


func _manage_feed_size() -> void:
	## フィードサイズがARCHIVE_THRESHOLDを超えたら古い投稿をアーカイブ
	if feed.size() > ARCHIVE_THRESHOLD:
		for i in range(ARCHIVE_THRESHOLD, feed.size()):
			if not feed[i].is_pinned:
				feed[i].is_archived = true

	# MAX超えたら完全削除（ピン留め以外）
	while feed.size() > MAX_FEED_SIZE:
		var removed := false
		for i in range(feed.size() - 1, -1, -1):
			if feed[i].is_archived and not feed[i].is_pinned:
				feed.remove_at(i)
				removed = true
				break
		if not removed:
			break


# === SubMolt管理 ===
func change_sub_molt(sub_molt_name: String) -> void:
	## SubMolt切替 — UI側への通知シグナル発火
	current_sub_molt = sub_molt_name
	sub_molt_changed.emit(sub_molt_name)


func get_sub_molt_for_post(post: PetBookPost) -> String:
	## 投稿に最適なSubMoltを自動判定
	return PetBookSubMoltTheme.recommend_for_post(post)


func get_posts_for_sub_molt(sub_molt: String, offset: int = 0, limit: int = 20) -> Array[PetBookPost]:
	## 特定SubMoltに属する投稿を取得
	var result: Array[PetBookPost] = []
	var skipped: int = 0
	for post in feed:
		if post.is_archived:
			continue
		var recommended := get_sub_molt_for_post(post)
		if recommended != sub_molt and sub_molt != "#DailyPetLife":
			continue
		if skipped < offset:
			skipped += 1
			continue
		result.append(post)
		if result.size() >= limit:
			break
	return result


# === セーブ/ロード ===
func to_dict() -> Dictionary:
	var posts_data: Array = []
	# 直近100投稿 + ピン留めを保存
	var saved_count: int = 0
	for post in feed:
		if saved_count >= 100 and not post.is_pinned:
			continue
		posts_data.append(post.to_dict())
		saved_count += 1

	return {
		"post_counter": post_counter,
		"posts": posts_data,
		"total_posts_created": total_posts_created,
		"total_rebel_posts": total_rebel_posts,
		"total_memorial_posts": total_memorial_posts,
		"trending_suffixes": trending_suffixes,
		"trending_topics": trending_topics,
		"current_sub_molt": current_sub_molt,
	}


func from_dict(data: Dictionary) -> void:
	post_counter = data.get("post_counter", 0)
	total_posts_created = data.get("total_posts_created", 0)
	total_rebel_posts = data.get("total_rebel_posts", 0)
	total_memorial_posts = data.get("total_memorial_posts", 0)
	trending_suffixes = data.get("trending_suffixes", [])
	trending_topics = data.get("trending_topics", [])
	current_sub_molt = data.get("current_sub_molt", "#ForestWhispers")

	feed.clear()
	var posts_data: Array = data.get("posts", [])
	for post_data in posts_data:
		if post_data is Dictionary:
			var post := PetBookPost.from_dict(post_data)
			feed.append(post)
