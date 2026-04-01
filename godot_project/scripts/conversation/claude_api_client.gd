## ClaudeAPIClient — Claude APIとの通信を管理
## AtoA会話生成・言語進化判定のLLMバックエンド
class_name ClaudeAPIClient
extends Node

signal request_completed(response: String)
signal request_failed(error: String)

# === Configuration ===
const API_URL: String = "https://api.anthropic.com/v1/messages"
const MODEL: String = "claude-sonnet-4-20250514"
const MAX_TOKENS: int = 256
const TEMPERATURE: float = 0.8  # 創造性を重視

var api_key: String = ""
var http_request: HTTPRequest


func _ready() -> void:
	http_request = HTTPRequest.new()
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
	var key_path := "user://api_key.txt"
	if FileAccess.file_exists(key_path):
		var file := FileAccess.open(key_path, FileAccess.READ)
		if file:
			api_key = file.get_as_text().strip_edges()
			file.close()


# === メイン生成関数 ===
func generate(system_prompt: String, user_prompt: String) -> String:
	if api_key.is_empty():
		push_warning("ClaudeAPIClient: No API key configured")
		request_failed.emit("No API key configured")
		return _generate_fallback(user_prompt)

	var headers := [
		"Content-Type: application/json",
		"x-api-key: %s" % api_key,
		"anthropic-version: 2023-06-01",
	]

	var body := {
		"model": MODEL,
		"max_tokens": MAX_TOKENS,
		"temperature": TEMPERATURE,
		"system": system_prompt,
		"messages": [
			{"role": "user", "content": user_prompt}
		],
	}

	var json_body := JSON.stringify(body)
	var error := http_request.request(API_URL, headers, HTTPClient.METHOD_POST, json_body)

	if error != OK:
		push_warning("ClaudeAPIClient: Request failed with error %d" % error)
		request_failed.emit("HTTP request error: %d" % error)
		return _generate_fallback(user_prompt)

	# レスポンスを待つ
	var result: Array = await http_request.request_completed
	var response_code: int = result[1]
	var response_body: PackedByteArray = result[3]

	if response_code != 200:
		push_warning("ClaudeAPIClient: HTTP %d" % response_code)
		request_failed.emit("HTTP %d" % response_code)
		return _generate_fallback(user_prompt)

	var json := JSON.new()
	var parse_result := json.parse(response_body.get_string_from_utf8())
	if parse_result != OK:
		request_failed.emit("JSON parse error")
		return _generate_fallback(user_prompt)

	var data: Dictionary = json.data
	if data.has("content") and data["content"].size() > 0:
		var response_text: String = data["content"][0].get("text", "...")
		request_completed.emit(response_text)
		return response_text

	request_failed.emit("Empty content in response")
	return _generate_fallback(user_prompt)


# === フォールバック（オフライン時やAPIエラー時） ===
func _generate_fallback(context: String) -> String:
	## APIが使えない時のローカル生成（ランダムテンプレート）
	var templates := [
		"*looks around curiously*-spark",
		"*wags tail happily*-glow",
		"*nudges friend gently*-bloom",
		"*bounces with excitement*-flash",
		"*sits quietly*-mist",
		"*plays with a leaf*-spark-glow",
		"*sniffs the air*-flash",
	]
	return templates[randi() % templates.size()]


func _on_request_completed(
	_result: int, _response_code: int,
	_headers: PackedStringArray, _body: PackedByteArray
) -> void:
	# HTTPRequestのシグナルハンドラ（awaitで処理するため通常は不使用）
	pass
