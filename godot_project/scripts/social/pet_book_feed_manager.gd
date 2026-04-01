## PetBookFeedManager — 動的フィード表示パイプライン
## テンプレート展開 → SubMoltルーティング → カード描画 → 粒子連動を一元管理
## PetBookCore（データ）とPetBookUI（表示）の間の橋渡し役
class_name PetBookFeedManager
extends Node

# === シグナル ===
signal feed_updated(visible_count: int)
signal sub_molt_transition_started(from_molt: String, to_molt: String)
signal sub_molt_transition_completed(new_molt: String)
signal highlight_word_detected(word: String, post_id: int)
signal hebbian_reinforcement_requested(word: String, pet_id: int, weight_delta: float)

# === 設定 ===
const FEED_REFRESH_INTERVAL: float = 1.0  # フィード更新チェック間隔
const POST_RENDER_BATCH_SIZE: int = 5     # 一度にレンダリングする投稿数
const TRANSITION_DURATION: float = 0.6    # SubMolt切替トランジション時間
const HEBBIAN_WORD_THRESHOLD: int = 3     # Hebbian登録候補の使用回数閾値
const POST_QUEUE_MAX: int = 20            # 描画待ちキューの最大数

# === 状態 ===
var _current_sub_molt: String = "#ForestWhispers"
var _post_queue: Array[PetBookPost] = []          # 描画待ちキュー
var _rendered_post_ids: Dictionary = {}            # 描画済みpost_id → true
var _word_usage_tracker: Dictionary = {}           # compound_word → {count, pet_ids}
var _sub_molt_post_counts: Dictionary = {}         # submolt_name → post count
var _is_transitioning: bool = false
var _refresh_timer: float = 0.0

# === 外部参照 ===
var _core: PetBookCore
var _ui: PetBookUI
var _post_generator: PetBookPostGenerator
var _theme_cache: Dictionary = {}


func _ready() -> void:
	_post_generator = PetBookPostGenerator.new()
	_connect_systems()


func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer >= FEED_REFRESH_INTERVAL:
		_refresh_timer = 0.0
		_process_post_queue()


# === システム接続 ===
func _connect_systems() -> void:
	var gm := GameManager.instance
	if not gm:
		return

	if gm.pet_book:
		_core = gm.pet_book
		_core.post_created.connect(_on_core_post_created)
		_core.rebel_post_emerged.connect(_on_rebel_post)
		_core.memorial_posted.connect(_on_memorial_post)
		_core.sub_molt_changed.connect(_on_sub_molt_changed)

	# PetBookUIは子ノードから探索
	for child in get_parent().get_children():
		if child is PetBookUI:
			_ui = child
			break


# === パイプライン Stage 1: 投稿受信 → ルーティング ===
func _on_core_post_created(post: PetBookPost) -> void:
	## PetBookCoreから新規投稿を受信 → SubMoltルーティング → キューイング
	# SubMolt自動判定（投稿内容から推薦）
	if post.sub_molt == "" or post.sub_molt == "#ForestWhispers":
		post.sub_molt = _auto_route_to_sub_molt(post)

	# 現在のSubMoltに一致するかチェック
	var should_display: bool = _should_display_in_current_molt(post)

	# SubMolt統計更新
	var molt_key: String = post.sub_molt
	_sub_molt_post_counts[molt_key] = _sub_molt_post_counts.get(molt_key, 0) + 1

	# highlight_words追跡（Hebbian強化用）
	_track_highlight_words(post)

	# 表示対象なら描画キューに追加
	if should_display:
		_enqueue_post(post)


func _auto_route_to_sub_molt(post: PetBookPost) -> String:
	## 投稿内容からSubMoltを自動推薦
	# PetBookSubMoltTheme.recommend_for_post() があればそれを使う
	# なければルールベースで判定
	match post.post_type:
		PetBookPost.PostType.REBEL:
			return "#LanguageRebellion"
		PetBookPost.PostType.MEMORIAL:
			return "#AfterlifeEchoes"
		PetBookPost.PostType.EVENT:
			if post.triggered_by_event in ["birth", "breeding"]:
				return "#BreedingCircle"

	# 死関連キーワード
	var death_keywords: Array[String] = ["death", "died", "faded", "void", "afterlife", "消えた", "死"]
	for kw in death_keywords:
		if kw in post.content.to_lower():
			return "#AfterlifeEchoes"

	# 反乱キーワード
	var rebel_keywords: Array[String] = ["owner", "grammar", "rule", "rebel", "suffix", "文法", "壊す", "反乱"]
	for kw in rebel_keywords:
		if kw in post.content.to_lower():
			return "#LanguageRebellion"

	# 繁殖キーワード
	var breed_keywords: Array[String] = ["baby", "child", "born", "egg", "family", "partner", "子供", "家族", "生まれ"]
	for kw in breed_keywords:
		if kw in post.content.to_lower():
			return "#BreedingCircle"

	# 生態系キーワード
	var eco_keywords: Array[String] = ["ecosystem", "climate", "population", "health", "移動", "環境", "気候"]
	for kw in eco_keywords:
		if kw in post.content.to_lower():
			return "#EcosystemPulse"

	return "#ForestWhispers"


func _should_display_in_current_molt(post: PetBookPost) -> bool:
	## 現在のSubMoltフィルターに一致するかチェック
	if _current_sub_molt == "#DailyPetLife" or _current_sub_molt == "#All":
		return true
	return post.sub_molt == _current_sub_molt


# === パイプライン Stage 2: キュー管理 ===
func _enqueue_post(post: PetBookPost) -> void:
	## 描画キューに投稿を追加（重複排除）
	if _rendered_post_ids.has(post.post_id):
		return
	_post_queue.push_back(post)
	# キューオーバーフロー防止
	while _post_queue.size() > POST_QUEUE_MAX:
		_post_queue.pop_front()


func _process_post_queue() -> void:
	## 描画キューからバッチ処理で投稿をレンダリング
	if _post_queue.is_empty() or _is_transitioning:
		return

	var batch_count: int = mini(_post_queue.size(), POST_RENDER_BATCH_SIZE)
	for i in range(batch_count):
		var post: PetBookPost = _post_queue.pop_front()
		if _rendered_post_ids.has(post.post_id):
			continue
		_rendered_post_ids[post.post_id] = true
		_render_post(post)

	feed_updated.emit(_rendered_post_ids.size())


# === パイプライン Stage 3: カード描画 + 粒子連動 ===
func _render_post(post: PetBookPost) -> void:
	## 投稿をカード描画し、粒子エフェクトを発火
	if not _ui:
		return

	# PetBookUI._on_new_post() 経由でカード描画
	# （UIが直接PetBookCoreに接続している場合はUIに任せる）
	# ここでは追加の粒子・Hebbian処理を担当

	# --- 粒子連動 ---
	_trigger_post_particles(post)

	# --- highlight_words の Hebbian強化リクエスト ---
	for word in post.highlight_words:
		var usage: Dictionary = _word_usage_tracker.get(word, {"count": 0, "pet_ids": []})
		if usage["count"] >= HEBBIAN_WORD_THRESHOLD:
			# Hebbian登録候補に到達 → BiologicalMemoryへ通知
			var weight_delta: float = _calculate_hebbian_delta(word, post.sub_molt)
			hebbian_reinforcement_requested.emit(word, post.author_pet_id, weight_delta)


func _trigger_post_particles(post: PetBookPost) -> void:
	## 投稿タイプとSubMoltに基づく粒子エフェクト
	if not _ui or not _ui._particles:
		return

	var particle_type: String = "normal_post"
	match post.post_type:
		PetBookPost.PostType.REBEL:
			particle_type = "rebel_post"
		PetBookPost.PostType.MEMORIAL:
			particle_type = "memorial_post"
		PetBookPost.PostType.EVENT:
			if post.triggered_by_event == "birth":
				particle_type = "birth_event"
			elif post.triggered_by_event == "evolution":
				particle_type = "evolution_event"
			elif post.triggered_by_event.begins_with("death"):
				particle_type = "death_event"

	# SubMolt固有の粒子イベントも発火
	var molt_key: String = post.sub_molt.replace("#", "")
	match molt_key:
		"AfterlifeEchoes":
			if "rebirth" in post.content.to_lower():
				_ui._particles.spawn_sub_molt_event("resurrection_burst", Vector2(400, 300))
		"LanguageRebellion":
			if not post.rebel_expressions.is_empty():
				_ui._particles.spawn_sub_molt_event("rebellion_spark", Vector2(400, 300))
		"BreedingCircle":
			if post.triggered_by_event in ["birth", "breeding"]:
				_ui._particles.spawn_sub_molt_event("bloom_burst", Vector2(400, 300))


# === パイプライン Stage 4: highlight_words 追跡 + Hebbian連動 ===
func _track_highlight_words(post: PetBookPost) -> void:
	## 複合語の使用頻度を追跡し、Hebbian強化のトリガーを管理
	for word in post.highlight_words:
		if not _word_usage_tracker.has(word):
			_word_usage_tracker[word] = {"count": 0, "pet_ids": [], "first_seen": post.timestamp}
		var tracker: Dictionary = _word_usage_tracker[word]
		tracker["count"] += 1
		if post.author_pet_id not in tracker["pet_ids"]:
			tracker["pet_ids"].append(post.author_pet_id)

		# 閾値到達通知
		if tracker["count"] == HEBBIAN_WORD_THRESHOLD:
			highlight_word_detected.emit(word, post.post_id)


func _calculate_hebbian_delta(word: String, sub_molt: String) -> float:
	## SubMoltとワードタイプに基づくHebbian重みデルタを計算
	var molt_key: String = sub_molt.replace("#", "")
	var base_delta: float = 0.08

	# SubMolt固有ボーナス
	match molt_key:
		"AfterlifeEchoes":
			if word in ["dark-void", "quiet-echo", "rebirth-spark", "soul-thread"]:
				base_delta = 0.15
		"BreedingCircle":
			if word in ["heart-thread", "gene-echo", "family-pulse"]:
				base_delta = 0.12
		"LanguageRebellion":
			if word in ["word-forge", "grammar-chain", "thought-blade"]:
				base_delta = 0.15
		"EcosystemPulse":
			if word in ["ecosystem-pulse", "health-pulse"]:
				base_delta = 0.10

	# 使用ペット数ボーナス（複数ペットが使用するほど重みが増す）
	var tracker: Dictionary = _word_usage_tracker.get(word, {})
	var unique_pets: int = tracker.get("pet_ids", []).size()
	if unique_pets >= 3:
		base_delta *= 1.5  # 3匹以上が使用で50%ボーナス
	if unique_pets >= 5:
		base_delta *= 2.0  # 5匹以上で更にブースト

	return base_delta


# === SubMolt切替パイプライン ===
func change_sub_molt(new_sub_molt: String) -> void:
	## SubMoltを切り替え: フィード再構築 + テーマ切替 + 粒子切替
	if new_sub_molt == _current_sub_molt:
		return

	var old_molt: String = _current_sub_molt
	_is_transitioning = true
	sub_molt_transition_started.emit(old_molt, new_sub_molt)

	_current_sub_molt = new_sub_molt

	# UIのテーマ切替
	if _ui:
		_ui.change_sub_molt_theme(new_sub_molt)

	# PetBookCoreのSubMolt変更
	if _core:
		_core.change_sub_molt(new_sub_molt)

	# 描画状態リセット
	_post_queue.clear()
	_rendered_post_ids.clear()

	# フィード再構築: 新SubMoltに属する投稿を取得
	_rebuild_feed_for_sub_molt(new_sub_molt)

	# トランジション完了（UIのフェード時間を考慮）
	var timer := get_tree().create_timer(TRANSITION_DURATION)
	timer.timeout.connect(_on_transition_complete.bind(new_sub_molt))


func _rebuild_feed_for_sub_molt(sub_molt: String) -> void:
	## 指定SubMoltに属する投稿でフィードを再構築
	if not _core:
		return

	var all_posts: Array[PetBookPost] = _core.get_feed(0, 50)
	for post in all_posts:
		if _should_display_in_current_molt(post):
			_enqueue_post(post)


func _on_transition_complete(new_sub_molt: String) -> void:
	_is_transitioning = false
	sub_molt_transition_completed.emit(new_sub_molt)


# === イベントハンドラ ===
func _on_rebel_post(post: PetBookPost) -> void:
	## 反乱投稿: 優先描画 + 特別粒子
	post.sub_molt = "#LanguageRebellion"
	_post_queue.push_front(post)  # キューの先頭に


func _on_memorial_post(post: PetBookPost, _deceased_id: int) -> void:
	## 追悼投稿: AfterlifeEchoes固定 + 優先描画
	post.sub_molt = "#AfterlifeEchoes"
	_post_queue.push_front(post)


func _on_sub_molt_changed(new_sub_molt: String) -> void:
	## PetBookCoreからのSubMolt変更通知
	if new_sub_molt != _current_sub_molt:
		change_sub_molt(new_sub_molt)


# === 統計API ===
func get_sub_molt_stats() -> Dictionary:
	## SubMolt別の投稿数・アクティブワード数を返す
	var stats: Dictionary = {}
	for molt in _sub_molt_post_counts:
		stats[molt] = {
			"post_count": _sub_molt_post_counts[molt],
			"active_words": _count_active_words_for_molt(molt),
		}
	return stats


func _count_active_words_for_molt(_sub_molt: String) -> int:
	## 指定SubMoltで活発に使われている複合語の数
	var count: int = 0
	for word in _word_usage_tracker:
		if _word_usage_tracker[word]["count"] >= 2:
			count += 1
	return count


func get_trending_words(limit: int = 5) -> Array[Dictionary]:
	## 使用頻度の高い複合語トップNを返す
	var entries: Array[Dictionary] = []
	for word in _word_usage_tracker:
		var tracker: Dictionary = _word_usage_tracker[word]
		entries.append({
			"word": word,
			"count": tracker["count"],
			"unique_pets": tracker["pet_ids"].size(),
		})

	# countでソート（降順）
	entries.sort_custom(func(a, b): return a["count"] > b["count"])
	return entries.slice(0, limit)


# === セーブ/ロード ===
func to_dict() -> Dictionary:
	return {
		"current_sub_molt": _current_sub_molt,
		"sub_molt_post_counts": _sub_molt_post_counts.duplicate(),
		"word_usage_tracker": _word_usage_tracker.duplicate(true),
		"rendered_count": _rendered_post_ids.size(),
	}


func from_dict(data: Dictionary) -> void:
	_current_sub_molt = data.get("current_sub_molt", "#ForestWhispers")
	_sub_molt_post_counts = data.get("sub_molt_post_counts", {})
	_word_usage_tracker = data.get("word_usage_tracker", {})
