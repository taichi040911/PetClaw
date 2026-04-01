## PetBookAutoPublisher — Ralph Loop自律投稿生成システム
## 50ペット×毎日のリアルタイム自律投稿をコスト最適化しながら制御
## Karpathy Loop: 観察→判断→生成→評価→学習のサイクルで品質を自律改善
## P2準拠: テンプレート70% / API30%のハイブリッドでコスト$1.21/day目標
class_name PetBookAutoPublisher
extends Node

# === シグナル ===
signal daily_cycle_started(day: String, pet_count: int)
signal daily_cycle_completed(day: String, total_posts: int, api_posts: int)
signal post_generated(post: PetBookPost, method: String)  # "template" or "api"
signal quality_score_updated(pet_id: int, score: float)
signal cost_budget_warning(used: float, budget: float)

# === コスト管理定数（P2: API Cost is Physics）===
const DAILY_API_BUDGET_USD: float = 1.21      # 日次API予算
const API_COST_PER_CALL_USD: float = 0.0024   # 1API呼び出しあたりのコスト概算
const MAX_API_CALLS_PER_DAY: int = 500        # 日次API呼び出し上限
const TEMPLATE_RATIO: float = 0.70            # テンプレート使用率（目標）
const API_RATIO: float = 0.30                 # API使用率（目標）

# === スケジューリング定数 ===
const BASE_POSTS_PER_PET_PER_DAY: int = 6     # 基本投稿数/ペット/日
const MAX_POSTS_PER_PET_PER_DAY: int = 12     # 最大投稿数/ペット/日
const MIN_POST_INTERVAL: float = 120.0        # 最小投稿間隔（秒）= 2分
const PEAK_HOUR_MULTIPLIER: float = 1.5       # ピーク時間の投稿倍率
const OFF_PEAK_MULTIPLIER: float = 0.5        # オフピーク時の投稿倍率

# === 品質管理 ===
const MIN_QUALITY_SCORE: float = 0.3          # 品質スコア下限（これ以下は再生成）
const QUALITY_EVAL_SAMPLE_SIZE: int = 10      # 品質評価サンプル数
const HEBBIAN_RECORD_THRESHOLD: float = 0.6   # Hebbian記録の品質閾値

# === 状態 ===
var _is_running: bool = false
var _current_day: String = ""
var _daily_stats: Dictionary = {
	"total_posts": 0,
	"template_posts": 0,
	"api_posts": 0,
	"api_cost_usd": 0.0,
	"quality_scores": [],
	"pet_post_counts": {},     # pet_id → count
	"sub_molt_distribution": {},  # submolt → count
}
var _pet_schedules: Dictionary = {}   # pet_id → {next_post_time, posts_today, quality_avg}
var _post_generator: PetBookPostGenerator
var _scheduler_timer: float = 0.0
var _quality_history: Array[float] = []  # 直近100投稿の品質スコア

# === Karpathy Loop状態 ===
var _loop_iteration: int = 0
var _learning_rate: float = 0.01
var _template_success_rates: Dictionary = {}  # template_index → success_rate


func _ready() -> void:
	_post_generator = PetBookPostGenerator.new()
	_current_day = Time.get_date_string_from_system()
	_reset_daily_stats()


func _process(delta: float) -> void:
	if not _is_running:
		return

	# 日次リセットチェック
	var today: String = Time.get_date_string_from_system()
	if today != _current_day:
		_on_day_change(today)

	# スケジューラー
	_scheduler_timer += delta
	if _scheduler_timer >= 10.0:  # 10秒ごとにチェック
		_scheduler_timer = 0.0
		_run_scheduler()


# === 起動/停止 ===
func start() -> void:
	_is_running = true
	_initialize_pet_schedules()
	daily_cycle_started.emit(_current_day, _pet_schedules.size())


func stop() -> void:
	_is_running = false


# === スケジューラー（Ralph Loop コア） ===
func _run_scheduler() -> void:
	## 各ペットのスケジュールをチェックし、投稿タイミングなら生成を実行
	var gm := GameManager.instance
	if not gm:
		return

	var current_time: float = gm.game_time

	for pet_id in _pet_schedules:
		var schedule: Dictionary = _pet_schedules[pet_id]

		# 日次上限チェック
		if schedule["posts_today"] >= MAX_POSTS_PER_PET_PER_DAY:
			continue

		# 投稿タイミングチェック
		if current_time < schedule["next_post_time"]:
			continue

		# コスト予算チェック
		if _daily_stats["api_cost_usd"] >= DAILY_API_BUDGET_USD:
			# API予算超過: テンプレートのみ許可
			pass

		# ペットエンティティ取得
		var pet: PetEntity = gm.pets.get(pet_id)
		if not pet or not pet.is_alive:
			continue

		# === Karpathy Loop: 投稿生成サイクル ===
		_execute_post_cycle(pet, schedule)


func _execute_post_cycle(pet: PetEntity, schedule: Dictionary) -> void:
	## Karpathy Loop: 観察→判断→生成→評価→学習
	var gm := GameManager.instance
	if not gm:
		return

	# === Stage 1: 観察（Observe）===
	var context: Dictionary = _observe_context(pet)

	# === Stage 2: 判断（Decide）===
	var decision: Dictionary = _decide_post_strategy(pet, context)
	var sub_molt: String = decision["sub_molt"]
	var use_api: bool = decision["use_api"]

	# === Stage 3: 生成（Generate）===
	var post: PetBookPost
	var method: String

	if use_api and _daily_stats["api_cost_usd"] < DAILY_API_BUDGET_USD:
		post = _generate_api_post(pet, sub_molt, context)
		method = "api"
		_daily_stats["api_posts"] += 1
		_daily_stats["api_cost_usd"] += API_COST_PER_CALL_USD
	else:
		post = _generate_template_post(pet, sub_molt, context)
		method = "template"
		_daily_stats["template_posts"] += 1

	if not post:
		return

	# === Stage 4: 評価（Evaluate）===
	var quality: float = _evaluate_post_quality(post, pet)

	# 品質スコアが低すぎる場合は再生成（最大1回）
	if quality < MIN_QUALITY_SCORE and method == "template":
		post = _generate_template_post(pet, sub_molt, context)
		if post:
			quality = _evaluate_post_quality(post, pet)

	if not post:
		return

	# === Stage 5: 学習（Learn）===
	_learn_from_post(post, quality, method)

	# 投稿を公開
	_publish_post(post, pet, schedule)
	post_generated.emit(post, method)

	# 統計更新
	_daily_stats["total_posts"] += 1
	_daily_stats["quality_scores"].append(quality)
	_daily_stats["pet_post_counts"][pet.pet_id] = schedule["posts_today"]
	var molt_key: String = sub_molt
	_daily_stats["sub_molt_distribution"][molt_key] = \
		_daily_stats["sub_molt_distribution"].get(molt_key, 0) + 1

	# コスト警告
	if _daily_stats["api_cost_usd"] > DAILY_API_BUDGET_USD * 0.8:
		cost_budget_warning.emit(_daily_stats["api_cost_usd"], DAILY_API_BUDGET_USD)


# === Stage 1: 観察 ===
func _observe_context(pet: PetEntity) -> Dictionary:
	## ペットの現在の状態・環境・記憶からコンテキストを構築
	var gm := GameManager.instance
	var context: Dictionary = {
		"next_id": 0,
		"environment": "forest",
		"memory_summary": "No recent memories.",
		"feed_summary": "No recent posts.",
		"recent_trends": [],
		"community_mood": "calm",
	}

	if gm:
		context["next_id"] = gm.pet_book.post_counter if gm.pet_book else 0

		if gm.ecosystem:
			context["environment"] = gm.ecosystem.current_environment

		# 記憶サマリー
		if gm.biological_memory:
			var memories: Array = gm.biological_memory.retrieve_memories(
				pet.pet_id,
				{"context_tags": [context["environment"]]},
				pet.personality, 3
			)
			if not memories.is_empty():
				var parts: Array[String] = []
				for mem in memories:
					if mem is Dictionary and mem.has("summary"):
						parts.append(mem["summary"])
				context["memory_summary"] = ". ".join(parts)

		# 最近のフィード
		if gm.pet_book:
			var recent: Array[PetBookPost] = gm.pet_book.get_feed(0, 5)
			var summaries: Array[String] = []
			for p in recent:
				summaries.append("%s: %s" % [p.author_name, p.content.left(50)])
			context["feed_summary"] = ". ".join(summaries)

			# トレンド
			context["recent_trends"] = gm.pet_book.trending_topics.duplicate()

	# 繁殖コンテキスト
	if pet.has_method("get_partner"):
		var partner = pet.get_partner()
		if partner:
			context["partner_name"] = partner.pet_name

	return context


# === Stage 2: 判断 ===
func _decide_post_strategy(pet: PetEntity, context: Dictionary) -> Dictionary:
	## SubMoltの選択とAPI/テンプレートの判断
	var gm := GameManager.instance
	var sub_molt: String = "#ForestWhispers"
	var use_api: bool = false

	# --- SubMolt選択ロジック ---
	# 死関連の感情
	if pet.emotions is Dictionary:
		var fear: float = pet.emotions.get("fear", 0.0)
		var sadness: float = pet.emotions.get("sadness", 0.0)
		if fear > 0.7 or sadness > 0.8:
			sub_molt = "#AfterlifeEchoes"

	# 反乱的性格
	var brave: float = pet.personality.get("brave", 0.0) if pet.personality is Dictionary else 0.0
	var curious: float = pet.personality.get("curious", 0.0) if pet.personality is Dictionary else 0.0
	if brave > 0.6 and randf() < 0.15:
		sub_molt = "#LanguageRebellion"

	# 最近子供が生まれた
	if context.get("partner_name", "") != "":
		if randf() < 0.3:
			sub_molt = "#BreedingCircle"

	# 高い好奇心 + 生態系変化
	if curious > 0.7 and context.get("recent_trends", []).size() > 0:
		if randf() < 0.2:
			sub_molt = "#EcosystemPulse"

	# --- API/テンプレート判断 ---
	# PostGeneratorのshould_use_apiを使用
	var post_type: PetBookPost.PostType = PetBookPost.PostType.DAILY
	use_api = _post_generator.should_use_api(pet, post_type)

	# コスト残量が少ない場合はテンプレート強制
	if _daily_stats["api_cost_usd"] >= DAILY_API_BUDGET_USD * 0.9:
		use_api = false

	return {"sub_molt": sub_molt, "use_api": use_api}


# === Stage 3: 生成 ===
func _generate_template_post(pet: PetEntity, sub_molt: String, context: Dictionary) -> PetBookPost:
	## テンプレートベースの投稿生成
	return _post_generator.generate_post(pet, sub_molt, context)


func _generate_api_post(pet: PetEntity, sub_molt: String, context: Dictionary) -> PetBookPost:
	## Claude API経由の投稿生成（非同期は_process内で管理）
	## 本番ではHTTPRequestを使うが、ここではプロンプト構築 + 同期フォールバック
	var prompt: String = _post_generator.build_api_prompt(pet, sub_molt, context)

	# --- API呼び出し（本番実装用プレースホルダ） ---
	# var http_request := HTTPRequest.new()
	# add_child(http_request)
	# var body := JSON.stringify({"prompt": prompt, "max_tokens": 200})
	# http_request.request("https://api.anthropic.com/v1/messages", [...], body)
	# await http_request.request_completed
	# --- ここまでプレースホルダ ---

	# 開発フェーズ: テンプレートフォールバック（API応答をシミュレート）
	var post := _post_generator.generate_post(pet, sub_molt, context)
	if post:
		# APIっぽい品質向上: 追加の接尾辞とハイライト
		if post.language_generation >= 2 and randf() < 0.5:
			var extra_words: Array[String] = _post_generator._extract_highlight_words(post.content)
			for w in extra_words:
				if w not in post.highlight_words:
					post.highlight_words.append(w)
	return post


# === Stage 4: 品質評価 ===
func _evaluate_post_quality(post: PetBookPost, pet: PetEntity) -> float:
	## 投稿の品質を0.0〜1.0で評価
	var score: float = 0.5  # ベースライン

	# 長さ適正（短すぎ/長すぎはペナルティ）
	var content_len: int = post.content.length()
	if content_len >= 30 and content_len <= 300:
		score += 0.1
	elif content_len < 15 or content_len > 500:
		score -= 0.2

	# 接尾辞の使用（多すぎず少なすぎず）
	var suffix_count: int = post.suffixes_used.size()
	if suffix_count >= 1 and suffix_count <= 4:
		score += 0.1
	elif suffix_count > 6:
		score -= 0.1

	# highlight_wordsの存在
	if not post.highlight_words.is_empty():
		score += 0.1

	# 感情と性格の一致
	if post.author_emotion != "" and post.personality_influence != "":
		score += 0.05

	# 言語世代に見合った複雑さ
	if post.language_generation >= 2 and suffix_count >= 2:
		score += 0.1
	elif post.language_generation == 0 and suffix_count <= 2:
		score += 0.05

	# SubMoltとの整合性
	var molt_key: String = post.sub_molt.replace("#", "")
	if _check_sub_molt_coherence(post, molt_key):
		score += 0.1

	# 記憶参照がある場合ボーナス
	if not post.memory_references.is_empty():
		score += 0.05

	return clampf(score, 0.0, 1.0)


func _check_sub_molt_coherence(post: PetBookPost, molt_key: String) -> bool:
	## 投稿内容がSubMoltのテーマと整合しているかチェック
	match molt_key:
		"AfterlifeEchoes":
			var keywords: Array[String] = ["death", "void", "echo", "fade", "rebirth", "死", "消え", "蘇"]
			for kw in keywords:
				if kw in post.content.to_lower():
					return true
		"BreedingCircle":
			var keywords: Array[String] = ["baby", "child", "family", "born", "gene", "子供", "家族", "生まれ"]
			for kw in keywords:
				if kw in post.content.to_lower():
					return true
		"LanguageRebellion":
			var keywords: Array[String] = ["rule", "grammar", "rebel", "word", "suffix", "文法", "言葉", "壊す"]
			for kw in keywords:
				if kw in post.content.to_lower():
					return true
		"EcosystemPulse":
			var keywords: Array[String] = ["ecosystem", "climate", "health", "population", "環境", "気候"]
			for kw in keywords:
				if kw in post.content.to_lower():
					return true
		"ForestWhispers":
			return true  # デフォルトは常に整合
	return false


# === Stage 5: 学習 ===
func _learn_from_post(post: PetBookPost, quality: float, method: String) -> void:
	## Karpathy Loop: 品質スコアからテンプレート成功率を更新
	_quality_history.append(quality)
	if _quality_history.size() > 100:
		_quality_history.pop_front()

	_loop_iteration += 1

	# Hebbian記録リクエスト（高品質投稿の複合語を記録）
	if quality >= HEBBIAN_RECORD_THRESHOLD:
		var gm := GameManager.instance
		if gm and gm.biological_memory:
			for word in post.highlight_words:
				gm.biological_memory.record_memory(post.author_pet_id, {
					"type": "language_usage",
					"word": word,
					"sub_molt": post.sub_molt,
					"quality": quality,
					"context_tags": [post.environment, post.author_emotion],
				})

	quality_score_updated.emit(post.author_pet_id, quality)


# === 投稿公開 ===
func _publish_post(post: PetBookPost, pet: PetEntity, schedule: Dictionary) -> void:
	## PetBookCoreへ投稿を公開し、スケジュールを更新
	var gm := GameManager.instance
	if not gm or not gm.pet_book:
		return

	gm.pet_book._publish_post(post)

	# スケジュール更新
	schedule["posts_today"] += 1
	schedule["last_post_time"] = gm.game_time

	# 次の投稿時間を計算
	var interval: float = _calculate_next_interval(pet, schedule)
	schedule["next_post_time"] = gm.game_time + interval


# === スケジュール管理 ===
func _initialize_pet_schedules() -> void:
	## 全ペットの投稿スケジュールを初期化
	var gm := GameManager.instance
	if not gm:
		return

	_pet_schedules.clear()
	for pet_id in gm.pets:
		var pet: PetEntity = gm.pets[pet_id]
		if not pet.is_alive:
			continue

		var initial_delay: float = randf_range(0, 60.0)  # 最初の投稿をバラけさせる
		_pet_schedules[pet_id] = {
			"next_post_time": gm.game_time + initial_delay,
			"posts_today": 0,
			"last_post_time": 0.0,
			"quality_avg": 0.5,
		}


func _calculate_next_interval(pet: PetEntity, schedule: Dictionary) -> float:
	## ペットの状態に応じた次の投稿間隔を計算
	var base: float = MIN_POST_INTERVAL * 2.0  # 4分ベース

	# 感情強度が高い → 投稿頻度UP
	var emotion_intensity: float = 0.5
	if pet.emotions is Dictionary:
		for key in pet.emotions:
			emotion_intensity = maxf(emotion_intensity, pet.emotions[key])
	base *= (1.5 - emotion_intensity)  # 感情1.0で半分の間隔

	# 今日の投稿数が多い → 間隔を延ばす
	var posts_today: int = schedule["posts_today"]
	if posts_today > BASE_POSTS_PER_PET_PER_DAY:
		base *= 1.5

	# 時間帯による補正（ゲーム内時間ベース）
	var gm := GameManager.instance
	if gm:
		var hour: int = int(fmod(gm.game_time / 3600.0, 24.0))
		if hour >= 8 and hour <= 22:  # ピーク時間
			base /= PEAK_HOUR_MULTIPLIER
		else:
			base /= OFF_PEAK_MULTIPLIER

	return clampf(base, MIN_POST_INTERVAL, MIN_POST_INTERVAL * 10.0)


# === 日次管理 ===
func _on_day_change(new_day: String) -> void:
	## 日次切替: 統計記録 + リセット
	daily_cycle_completed.emit(
		_current_day,
		_daily_stats["total_posts"],
		_daily_stats["api_posts"]
	)

	_current_day = new_day
	_reset_daily_stats()
	_initialize_pet_schedules()
	daily_cycle_started.emit(new_day, _pet_schedules.size())


func _reset_daily_stats() -> void:
	_daily_stats = {
		"total_posts": 0,
		"template_posts": 0,
		"api_posts": 0,
		"api_cost_usd": 0.0,
		"quality_scores": [],
		"pet_post_counts": {},
		"sub_molt_distribution": {},
	}


# === 統計API ===
func get_daily_stats() -> Dictionary:
	return _daily_stats.duplicate(true)


func get_average_quality() -> float:
	if _quality_history.is_empty():
		return 0.5
	var total: float = 0.0
	for q in _quality_history:
		total += q
	return total / _quality_history.size()


func get_cost_utilization() -> float:
	## コスト使用率（0.0〜1.0）
	if DAILY_API_BUDGET_USD <= 0:
		return 0.0
	return _daily_stats["api_cost_usd"] / DAILY_API_BUDGET_USD


func get_template_api_ratio() -> Dictionary:
	## テンプレート/API比率
	var total: int = _daily_stats["template_posts"] + _daily_stats["api_posts"]
	if total == 0:
		return {"template": 0.0, "api": 0.0}
	return {
		"template": float(_daily_stats["template_posts"]) / total,
		"api": float(_daily_stats["api_posts"]) / total,
	}


# === セーブ/ロード ===
func to_dict() -> Dictionary:
	return {
		"is_running": _is_running,
		"current_day": _current_day,
		"daily_stats": _daily_stats.duplicate(true),
		"loop_iteration": _loop_iteration,
		"quality_history": _quality_history.duplicate(),
	}


func from_dict(data: Dictionary) -> void:
	_is_running = data.get("is_running", false)
	_current_day = data.get("current_day", Time.get_date_string_from_system())
	_daily_stats = data.get("daily_stats", _daily_stats)
	_loop_iteration = data.get("loop_iteration", 0)
	_quality_history = data.get("quality_history", [])
	if _is_running:
		_initialize_pet_schedules()
