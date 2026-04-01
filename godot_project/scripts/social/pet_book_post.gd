## PetBookPost — PetBook投稿データモデル
## Moltbook風AI専用SNSの個別投稿を表現するデータクラス
## 投稿テキスト + メタデータ + リアクション + 言語情報を統合管理
class_name PetBookPost
extends RefCounted

# === 投稿タイプ ===
enum PostType {
	DAILY,       # 日常投稿（環境の感想、今日の出来事）
	EVENT,       # イベント投稿（死、誕生、進化、災害への反応）
	REPLY,       # 返信投稿（他の投稿への反応）
	REBEL,       # 反乱投稿（ルール逸脱、新語提案、哲学的問い）
	MEMORIAL,    # 追悼投稿（故ペットへの回想）
}

# === 基本フィールド ===
var post_id: int = -1
var author_pet_id: int = -1
var post_type: PostType = PostType.DAILY
var timestamp: float = 0.0            # game_time
var content: String = ""               # 投稿テキスト（ペット言語）
var translation: String = ""           # 人間語翻訳（オプション）

# === 投稿者スナップショット ===
## 投稿時のペット状態を保存（後から参照可能にするため）
var author_name: String = ""
var author_emotion: String = "calm"
var author_emotion_intensity: float = 0.0
var author_personality_dominant: String = ""
var author_evolution_form: String = ""

# === 言語情報 ===
## 投稿に使用された言語パターン
var word_order: String = "SOV"           # 使用語順
var suffixes_used: Array[String] = []    # 使用された接尾辞
var rebel_expressions: Array[String] = [] # 反乱表現（通常ルール逸脱）
var language_generation: int = 0          # 言語世代番号

# === コンテキスト ===
var environment: String = ""              # 投稿時の環境
var triggered_by_event: String = ""       # トリガーイベント（EVENT/MEMORIAL時）
var memory_references: Array[int] = []    # 参照した記憶のID
var reply_to_post_id: int = -1           # 返信先投稿ID（REPLY時）

# === リアクション ===
## 他ペットからの反応（heartbeatで蓄積）
var reactions: Dictionary = {}  # pet_id → {"type": "empathy"|"disagree"|"curious", "timestamp": float}
var reply_count: int = 0
var share_count: int = 0

# === SubMolt・ハイライト（v3追加） ===
var sub_molt: String = ""                 # 所属SubMolt（"#ForestWhispers"等）
var highlight_words: Array[String] = []   # ハイライト対象の複合語
var personality_influence: String = ""    # 投稿に影響した性格特性

# === フラグ ===
var is_pinned: bool = false              # 重要投稿（追悼・マイルストーン）
var is_trending: bool = false            # トレンド入り
var is_archived: bool = false            # アーカイブ済み（古い投稿）


# === 初期化 ===
func _init() -> void:
	suffixes_used = []
	rebel_expressions = []
	memory_references = []
	highlight_words = []
	reactions = {}


# === リアクション操作 ===
func add_reaction(pet_id: int, reaction_type: String, time: float) -> void:
	reactions[pet_id] = {
		"type": reaction_type,
		"timestamp": time,
	}


func get_reaction_count(reaction_type: String) -> int:
	var count: int = 0
	for pet_id in reactions:
		if reactions[pet_id]["type"] == reaction_type:
			count += 1
	return count


func get_total_engagement() -> int:
	## リアクション + 返信 + シェアの合計
	return reactions.size() + reply_count + share_count


func get_emoji_reactions() -> Array[Dictionary]:
	## 絵文字ごとのリアクション集計を返す（UI表示用）
	## 戻り値: [{"icon": "❤️", "count": 12}, {"icon": "🌸", "count": 5}]
	var emoji_map: Dictionary = {
		"empathy": "❤️",
		"disagree": "💔",
		"curious": "🤔",
		"celebrate": "🎉",
		"support": "🤝",
		"nature": "🌸",
		"ocean": "🌊",
		"fire": "🔥",
	}
	var counts: Dictionary = {}  # icon → count
	for pet_id in reactions:
		var r_type: String = reactions[pet_id].get("type", "empathy")
		var icon: String = emoji_map.get(r_type, "❤️")
		counts[icon] = counts.get(icon, 0) + 1
	var result: Array[Dictionary] = []
	for icon in counts:
		result.append({"icon": icon, "count": counts[icon]})
	# カウント降順ソート
	result.sort_custom(func(a, b): return a["count"] > b["count"])
	return result


# === 表示用ヘルパー ===
func get_display_handle() -> String:
	## @name_personality 形式のハンドル名
	return "@%s_%s" % [author_name.to_lower(), author_personality_dominant]


func get_time_ago(current_game_time: float) -> String:
	## 「〜分前」「〜時間前」の相対時間表示
	var diff: float = current_game_time - timestamp
	if diff < 60.0:
		return "%d秒前" % int(diff)
	elif diff < 3600.0:
		return "%d分前" % int(diff / 60.0)
	elif diff < 86400.0:
		return "%d時間前" % int(diff / 3600.0)
	else:
		return "%d日前" % int(diff / 86400.0)


func get_post_type_label() -> String:
	match post_type:
		PostType.DAILY:
			return ""
		PostType.EVENT:
			return "📢イベント"
		PostType.REPLY:
			return ""
		PostType.REBEL:
			return "⚡反乱"
		PostType.MEMORIAL:
			return "📌追悼"
	return ""


func get_emotion_color() -> Color:
	## 感情に基づく投稿の表示色
	match author_emotion:
		"joy":
			return Color(1.0, 0.85, 0.0)      # 金色
		"love", "affection":
			return Color(1.0, 0.4, 0.6)        # ピンク
		"fear":
			return Color(0.5, 0.3, 0.7)        # 紫
		"excitement":
			return Color(1.0, 0.5, 0.0)        # オレンジ
		"sadness":
			return Color(0.3, 0.4, 0.8)        # 青
		"anger":
			return Color(0.9, 0.2, 0.2)        # 赤
		"curiosity", "wonder":
			return Color(0.2, 0.8, 0.6)        # 緑
		"pride":
			return Color(0.9, 0.7, 0.2)        # 黄金
		"calm":
			return Color(0.6, 0.7, 0.8)        # ライトブルー
		"brave":
			return Color(0.8, 0.3, 0.1)        # ダークオレンジ
		_:
			return Color(0.7, 0.7, 0.7)        # グレー


# === シリアライゼーション ===
func to_dict() -> Dictionary:
	var reaction_data: Dictionary = {}
	for pet_id in reactions:
		reaction_data[str(pet_id)] = reactions[pet_id]

	return {
		"post_id": post_id,
		"author_pet_id": author_pet_id,
		"post_type": post_type,
		"timestamp": timestamp,
		"content": content,
		"translation": translation,
		"author_name": author_name,
		"author_emotion": author_emotion,
		"author_emotion_intensity": author_emotion_intensity,
		"author_personality_dominant": author_personality_dominant,
		"author_evolution_form": author_evolution_form,
		"word_order": word_order,
		"suffixes_used": suffixes_used,
		"rebel_expressions": rebel_expressions,
		"language_generation": language_generation,
		"environment": environment,
		"triggered_by_event": triggered_by_event,
		"memory_references": memory_references,
		"reply_to_post_id": reply_to_post_id,
		"reactions": reaction_data,
		"reply_count": reply_count,
		"share_count": share_count,
		"sub_molt": sub_molt,
		"highlight_words": highlight_words,
		"personality_influence": personality_influence,
		"is_pinned": is_pinned,
		"is_trending": is_trending,
		"is_archived": is_archived,
	}


static func from_dict(data: Dictionary) -> PetBookPost:
	var post := PetBookPost.new()
	post.post_id = data.get("post_id", -1)
	post.author_pet_id = data.get("author_pet_id", -1)
	post.post_type = data.get("post_type", PostType.DAILY)
	post.timestamp = data.get("timestamp", 0.0)
	post.content = data.get("content", "")
	post.translation = data.get("translation", "")
	post.author_name = data.get("author_name", "")
	post.author_emotion = data.get("author_emotion", "calm")
	post.author_emotion_intensity = data.get("author_emotion_intensity", 0.0)
	post.author_personality_dominant = data.get("author_personality_dominant", "")
	post.author_evolution_form = data.get("author_evolution_form", "")
	post.word_order = data.get("word_order", "SOV")
	post.suffixes_used = data.get("suffixes_used", [])
	post.rebel_expressions = data.get("rebel_expressions", [])
	post.language_generation = data.get("language_generation", 0)
	post.environment = data.get("environment", "")
	post.triggered_by_event = data.get("triggered_by_event", "")
	post.memory_references = data.get("memory_references", [])
	post.reply_to_post_id = data.get("reply_to_post_id", -1)
	post.reply_count = data.get("reply_count", 0)
	post.share_count = data.get("share_count", 0)
	post.sub_molt = data.get("sub_molt", "")
	post.highlight_words = data.get("highlight_words", [])
	post.personality_influence = data.get("personality_influence", "")
	post.is_pinned = data.get("is_pinned", false)
	post.is_trending = data.get("is_trending", false)
	post.is_archived = data.get("is_archived", false)

	# リアクション復元（文字列キー → intキーに変換）
	var raw_reactions: Dictionary = data.get("reactions", {})
	for key in raw_reactions:
		post.reactions[int(key)] = raw_reactions[key]

	return post
