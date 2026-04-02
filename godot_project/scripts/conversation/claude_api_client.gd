## ClaudeAPIClient — Claude APIとの通信を管理
## AtoA会話生成・言語進化判定のLLMバックエンド
## リトライ + 性格/感情反映フォールバックテンプレート
class_name ClaudeAPIClient
extends Node

signal request_completed(response: String)
signal request_failed(error: String)

# === Configuration ===
const API_URL: String = "https://api.anthropic.com/v1/messages"
const MODEL: String = "claude-sonnet-4-20250514"
const MAX_TOKENS: int = 256
const TEMPERATURE: float = 0.8  # 創造性を重視
const MAX_RETRIES: int = 2
const RETRY_DELAY: float = 1.5  # 秒

var api_key: String = ""
var http_request: HTTPRequest
var _total_api_calls: int = 0
var _total_fallbacks: int = 0


func _ready() -> void:
	http_request = HTTPRequest.new()
	http_request.timeout = 10.0  # 10秒タイムアウト
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

	# APIキーの読み込み（環境変数またはファイルから）
	_load_api_key()


func _load_api_key() -> void:
	# まず環境変数を試す
	if OS.has_environment("ANTHROPIC_API_KEY"):
		api_key = OS.get_environment("ANTHROPIC_API_KEY")
		return

	# ファイルから読み込み
	var key_path: String = "user://api_key.txt"
	if FileAccess.file_exists(key_path):
		var file: FileAccess = FileAccess.open(key_path, FileAccess.READ)
		if file:
			api_key = file.get_as_text().strip_edges()
			file.close()


# === メイン生成関数（リトライ付き） ===
func generate(system_prompt: String, user_prompt: String) -> String:
	if api_key.is_empty():
		push_warning("ClaudeAPIClient: No API key configured — using template mode")
		request_failed.emit("No API key configured")
		return _generate_personality_fallback(user_prompt)

	# リトライループ
	for attempt: int in range(MAX_RETRIES + 1):
		var result: String = await _try_api_call(system_prompt, user_prompt)
		if not result.is_empty():
			_total_api_calls += 1
			request_completed.emit(result)
			return result

		# リトライ前に待機（最後の試行後は待たない）
		if attempt < MAX_RETRIES:
			print("[ClaudeAPI] Retry %d/%d after %.1fs..." % [attempt + 1, MAX_RETRIES, RETRY_DELAY])
			await get_tree().create_timer(RETRY_DELAY).timeout

	# 全リトライ失敗 → フォールバック
	_total_fallbacks += 1
	request_failed.emit("All %d attempts failed" % (MAX_RETRIES + 1))
	return _generate_personality_fallback(user_prompt)


func _try_api_call(system_prompt: String, user_prompt: String) -> String:
	var headers: PackedStringArray = PackedStringArray([
		"Content-Type: application/json",
		"x-api-key: %s" % api_key,
		"anthropic-version: 2023-06-01",
	])

	var body: Dictionary = {
		"model": MODEL,
		"max_tokens": MAX_TOKENS,
		"temperature": TEMPERATURE,
		"system": system_prompt,
		"messages": [
			{"role": "user", "content": user_prompt}
		],
	}

	var json_body: String = JSON.stringify(body)
	var error: int = http_request.request(API_URL, headers, HTTPClient.METHOD_POST, json_body)

	if error != OK:
		push_warning("ClaudeAPIClient: Request failed with error %d" % error)
		return ""

	# レスポンスを待つ
	var result: Array = await http_request.request_completed
	var response_code: int = result[1]
	var response_body: PackedByteArray = result[3]

	if response_code != 200:
		push_warning("ClaudeAPIClient: HTTP %d" % response_code)
		return ""

	var json: JSON = JSON.new()
	var parse_result: int = json.parse(response_body.get_string_from_utf8())
	if parse_result != OK:
		return ""

	if not json.data is Dictionary:
		push_warning("ClaudeAPIClient: unexpected JSON type: %s" % typeof(json.data))
		return ""
	var data: Dictionary = json.data
	if data.has("content") and data["content"] is Array and data["content"].size() > 0:
		return data["content"][0].get("text", "")

	return ""


# === 性格/感情反映フォールバック ===
func _generate_personality_fallback(context: String) -> String:
	## APIが使えない時のローカル生成
	## コンテキストから性格/感情情報を抽出し、それに合ったテンプレートを選択

	# コンテキストからヒントを抽出
	var is_brave: bool = context.contains("brave") or context.contains("adventurous")
	var is_calm: bool = context.contains("calm") or context.contains("gentle")
	var is_playful: bool = context.contains("playful") or context.contains("energetic")
	var is_curious: bool = context.contains("curious") or context.contains("wonder")
	var is_sad: bool = context.contains("sadness") or context.contains("lonely")
	var is_happy: bool = context.contains("joy") or context.contains("happy")
	var is_loving: bool = context.contains("love") or context.contains("affection")
	var is_scared: bool = context.contains("fear") or context.contains("anxious")

	# 現在の文法からサフィックスを取得
	var suffix: String = "-spark"
	if GameManager.language_evolution:
		var grammar: Dictionary = GameManager.language_evolution.get_current_grammar()
		var suffixes: Array = grammar.get("suffixes", [])
		if not suffixes.is_empty():
			suffix = suffixes[randi() % suffixes.size()]

	# 独自語彙があれば使用
	var vocab_word: String = ""
	if GameManager.instance and GameManager.instance.original_language:
		var vocab: Dictionary = GameManager.instance.original_language.get_full_vocabulary()
		if not vocab.is_empty():
			var keys: Array = vocab.keys()
			var entry: Dictionary = vocab[keys[randi() % keys.size()]]
			if entry.get("strength", 0.0) > 0.3:
				vocab_word = entry.get("ai_term", "")

	# 性格+感情に基づくテンプレート選択
	var templates: Array[String] = []

	if is_sad:
		templates = [
			"*looks down quietly%s* ...%s" % [suffix, suffix],
			"*sighs softly%s* The world feels heavy%s..." % [suffix, suffix],
			"*huddles close%s* I miss the warmth%s..." % [suffix, suffix],
		]
	elif is_scared:
		templates = [
			"*trembles slightly%s* W-what was that%s?" % [suffix, suffix],
			"*hides behind friend%s* Is it safe%s...?" % [suffix, suffix],
			"*peeks out nervously%s* ...%s?" % [suffix, suffix],
		]
	elif is_loving:
		templates = [
			"*nuzzles warmly%s* You're my favorite%s!" % [suffix, suffix],
			"*purrs contentedly%s* Together is best%s." % [suffix, suffix],
			"*leans close%s* I feel safe with you%s." % [suffix, suffix],
		]
	elif is_happy:
		templates = [
			"*bounces excitedly%s* What a wonderful day%s!" % [suffix, suffix],
			"*spins around joyfully%s* Everything sparkles%s!" % [suffix, suffix],
			"*giggles%s* Life is beautiful%s!" % [suffix, suffix],
		]
	elif is_brave:
		templates = [
			"*stands tall%s* Let's explore further%s!" % [suffix, suffix],
			"*charges forward%s* Nothing can stop us%s!" % [suffix, suffix],
			"*roars proudly%s* We are strong%s!" % [suffix, suffix],
		]
	elif is_curious:
		templates = [
			"*tilts head%s* What's over there%s?" % [suffix, suffix],
			"*sniffs curiously%s* This is new%s! Interesting%s!" % [suffix, suffix, suffix],
			"*examines closely%s* I wonder how it works%s..." % [suffix, suffix],
		]
	elif is_playful:
		templates = [
			"*pounces playfully%s* Tag! You're it%s!" % [suffix, suffix],
			"*rolls around%s* Haha%s! Catch me%s!" % [suffix, suffix, suffix],
			"*does a silly dance%s* Wheee%s!" % [suffix, suffix],
		]
	elif is_calm:
		templates = [
			"*breathes slowly%s* The air is peaceful%s." % [suffix, suffix],
			"*watches the sky%s* Time flows gently%s..." % [suffix, suffix],
			"*sits serenely%s* All is well%s." % [suffix, suffix],
		]
	else:
		templates = [
			"*looks around%s* Hmm%s..." % [suffix, suffix],
			"*yawns softly%s* What shall we do%s?" % [suffix, suffix],
			"*stretches%s* Another moment together%s." % [suffix, suffix],
		]

	var response: String = templates[randi() % templates.size()]

	# 独自語彙を挿入（あれば）
	if not vocab_word.is_empty() and randf() < 0.4:
		response = response + " " + vocab_word + suffix

	return response


func get_stats() -> Dictionary:
	return {
		"total_api_calls": _total_api_calls,
		"total_fallbacks": _total_fallbacks,
		"api_key_configured": not api_key.is_empty(),
	}


func _on_request_completed(
	_result: int, _response_code: int,
	_headers: PackedStringArray, _body: PackedByteArray
) -> void:
	# HTTPRequestのシグナルハンドラ（awaitで処理するため通常は不使用）
	pass
