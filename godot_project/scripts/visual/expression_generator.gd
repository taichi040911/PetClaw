## ExpressionGenerator — 感情に応じたプロシージャル表情テクスチャを生成
## 目と口のピクセルアート表情を動的に生成し、PetVisualBridgeに供給
class_name ExpressionGenerator
extends RefCounted

# === Expression Definitions ===
# 各表情は8x8ピクセルのミニスプライトとして生成

const PIXEL_SIZE: int = 8

# 目の表情パターン（8x8グリッド、1=描画、0=透明）
const EYE_PATTERNS: Dictionary = {
	"neutral": [
		[0,0,0,0,0,0,0,0],
		[0,0,1,1,1,1,0,0],
		[0,1,1,1,1,1,1,0],
		[0,1,1,0,0,1,1,0],
		[0,1,1,0,0,1,1,0],
		[0,1,1,1,1,1,1,0],
		[0,0,1,1,1,1,0,0],
		[0,0,0,0,0,0,0,0],
	],
	"happy": [
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,1,1,1,1,1,1,0],
		[0,0,1,1,1,1,0,0],
		[0,0,0,1,1,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
	],
	"love": [
		[0,0,0,0,0,0,0,0],
		[0,1,0,0,0,1,0,0],
		[1,1,1,0,1,1,1,0],
		[1,1,1,1,1,1,1,0],
		[0,1,1,1,1,1,0,0],
		[0,0,1,1,1,0,0,0],
		[0,0,0,1,0,0,0,0],
		[0,0,0,0,0,0,0,0],
	],
	"sad": [
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,1,1,1,0,0,0],
		[0,1,1,1,1,1,0,0],
		[0,1,1,0,0,1,1,0],
		[0,1,1,0,0,1,1,0],
		[0,0,1,1,1,1,0,0],
		[0,0,0,0,0,0,0,0],
	],
	"excited": [
		[0,0,0,0,0,0,0,0],
		[0,1,1,1,1,1,1,0],
		[1,1,1,1,1,1,1,1],
		[1,1,1,0,0,1,1,1],
		[1,1,1,0,0,1,1,1],
		[1,1,1,1,1,1,1,1],
		[0,1,1,1,1,1,1,0],
		[0,0,0,0,0,0,0,0],
	],
	"scared": [
		[0,0,0,0,0,0,0,0],
		[0,1,1,1,1,1,1,0],
		[1,1,0,0,0,0,1,1],
		[1,0,0,1,1,0,0,1],
		[1,0,0,1,1,0,0,1],
		[1,1,0,0,0,0,1,1],
		[0,1,1,1,1,1,1,0],
		[0,0,0,0,0,0,0,0],
	],
	"sleepy": [
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,1,1,1,1,1,1,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
	],
}

const MOUTH_PATTERNS: Dictionary = {
	"neutral": [
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,1,1,1,1,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
	],
	"happy": [
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,1,0,0,0,0,1,0],
		[0,0,1,1,1,1,0,0],
		[0,0,0,1,1,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
	],
	"love": [
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,1,1,1,1,0,0],
		[0,0,1,1,1,1,0,0],
		[0,0,0,1,1,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
	],
	"sad": [
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,1,1,0,0,0],
		[0,0,1,0,0,1,0,0],
		[0,1,0,0,0,0,1,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
	],
	"excited": [
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,1,0,0,0,0,1,0],
		[0,1,1,1,1,1,1,0],
		[0,0,1,1,1,1,0,0],
		[0,0,0,1,1,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
	],
	"scared": [
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,1,1,1,1,0,0],
		[0,1,0,0,0,0,1,0],
		[0,1,0,0,0,0,1,0],
		[0,0,1,1,1,1,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
	],
	"sleepy": [
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,1,1,1,1,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0],
	],
}

# 感情→表情マッピング
const EMOTION_TO_EXPRESSION: Dictionary = {
	"joy": "happy",
	"love": "love",
	"excitement": "excited",
	"sadness": "sad",
	"fear": "scared",
	"neutral": "neutral",
}

# テクスチャキャッシュ
static var _eye_cache: Dictionary = {}    # expression_name → ImageTexture
static var _mouth_cache: Dictionary = {}  # expression_name → ImageTexture


static func get_eye_texture(emotion: String) -> ImageTexture:
	var expression: String = EMOTION_TO_EXPRESSION.get(emotion, "neutral")

	if _eye_cache.has(expression):
		return _eye_cache[expression]

	var texture: ImageTexture = _generate_texture(EYE_PATTERNS.get(expression, EYE_PATTERNS["neutral"]), Color(0.12, 0.12, 0.15))
	_eye_cache[expression] = texture
	return texture


static func get_mouth_texture(emotion: String) -> ImageTexture:
	var expression: String = EMOTION_TO_EXPRESSION.get(emotion, "neutral")

	if _mouth_cache.has(expression):
		return _mouth_cache[expression]

	var texture: ImageTexture = _generate_texture(MOUTH_PATTERNS.get(expression, MOUTH_PATTERNS["neutral"]), Color(0.12, 0.12, 0.15))
	_mouth_cache[expression] = texture
	return texture


static func get_sleepy_eye_texture() -> ImageTexture:
	if _eye_cache.has("sleepy"):
		return _eye_cache["sleepy"]

	var texture: ImageTexture = _generate_texture(EYE_PATTERNS["sleepy"], Color(0.12, 0.12, 0.15))
	_eye_cache["sleepy"] = texture
	return texture


static func get_sleepy_mouth_texture() -> ImageTexture:
	if _mouth_cache.has("sleepy"):
		return _mouth_cache["sleepy"]

	var texture: ImageTexture = _generate_texture(MOUTH_PATTERNS["sleepy"], Color(0.12, 0.12, 0.15))
	_mouth_cache["sleepy"] = texture
	return texture


static func _generate_texture(pattern: Array, color: Color) -> ImageTexture:
	var image: Image = Image.create(PIXEL_SIZE, PIXEL_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))  # 透明

	for y: int in range(PIXEL_SIZE):
		if y >= pattern.size():
			continue
		var row: Array = pattern[y]
		for x: int in range(PIXEL_SIZE):
			if x >= row.size():
				continue
			if row[x] == 1:
				image.set_pixel(x, y, color)

	return ImageTexture.create_from_image(image)
