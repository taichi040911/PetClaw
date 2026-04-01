## SpriteplaceholderGenerator — 22進化形態のプレースホルダースプライトを動的生成
## テクスチャがないとき、形態ごとのカラー・シルエットを自動生成する
## 実際のスプライトアセットが完成するまでの代替表示
class_name SpritePlaceholderGenerator
extends RefCounted

# 22進化形態の定義
const EVOLUTION_FORMS: Dictionary = {
	# Stage 1: Blob
	"blob": {"color": Color(0.8, 0.8, 0.7), "size": Vector2(32, 32), "shape": "circle"},

	# Stage 2: Infant (4種)
	"forest_infant": {"color": Color(0.3, 0.7, 0.4), "size": Vector2(40, 44), "shape": "round"},
	"sea_infant": {"color": Color(0.3, 0.5, 0.8), "size": Vector2(40, 44), "shape": "round"},
	"city_infant": {"color": Color(0.7, 0.6, 0.4), "size": Vector2(40, 44), "shape": "round"},
	"ruins_infant": {"color": Color(0.5, 0.3, 0.6), "size": Vector2(40, 44), "shape": "round"},

	# Stage 3: Youth (6種)
	"warrior_youth": {"color": Color(0.8, 0.3, 0.2), "size": Vector2(48, 56), "shape": "angular"},
	"scholar_youth": {"color": Color(0.3, 0.4, 0.7), "size": Vector2(48, 56), "shape": "round"},
	"healer_youth": {"color": Color(0.3, 0.7, 0.6), "size": Vector2(48, 56), "shape": "round"},
	"trickster_youth": {"color": Color(0.8, 0.6, 0.2), "size": Vector2(48, 56), "shape": "angular"},
	"sentinel_youth": {"color": Color(0.4, 0.5, 0.6), "size": Vector2(48, 56), "shape": "angular"},
	"shadow_youth": {"color": Color(0.3, 0.2, 0.4), "size": Vector2(48, 56), "shape": "angular"},
	"diplomat_youth": {"color": Color(0.5, 0.6, 0.3), "size": Vector2(48, 56), "shape": "round"},

	# Stage 4: Adult (6種)
	"guardian_adult": {"color": Color(0.2, 0.5, 0.8), "size": Vector2(56, 64), "shape": "angular"},
	"mystic_adult": {"color": Color(0.6, 0.3, 0.8), "size": Vector2(56, 64), "shape": "round"},
	"sage_adult": {"color": Color(0.3, 0.6, 0.5), "size": Vector2(56, 64), "shape": "round"},
	"storm_warrior_adult": {"color": Color(0.7, 0.4, 0.2), "size": Vector2(56, 64), "shape": "angular"},
	"bond_master_adult": {"color": Color(0.8, 0.5, 0.6), "size": Vector2(56, 64), "shape": "round"},
	"dark_sovereign_adult": {"color": Color(0.2, 0.1, 0.3), "size": Vector2(56, 64), "shape": "angular"},

	# Stage 5: Elder/Legend (3種)
	"ancient_elder": {"color": Color(0.6, 0.6, 0.5), "size": Vector2(64, 72), "shape": "round"},
	"language_sage_elder": {"color": Color(0.4, 0.5, 0.7), "size": Vector2(64, 72), "shape": "round"},
	"redeemed_elder": {"color": Color(0.7, 0.6, 0.8), "size": Vector2(64, 72), "shape": "round"},
	"eternal_companion": {"color": Color(0.9, 0.85, 0.6), "size": Vector2(64, 72), "shape": "round"},
}


## 指定した形態のプレースホルダーテクスチャを生成
static func generate_placeholder(form_id: String) -> ImageTexture:
	var form: Dictionary = EVOLUTION_FORMS.get(form_id, {
		"color": Color(0.5, 0.5, 0.5),
		"size": Vector2(48, 48),
		"shape": "circle",
	})

	var size: Vector2 = form["size"]
	var color: Color = form["color"]
	var shape: String = form["shape"]

	var image: Image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	var center: Vector2 = size / 2.0

	for x: int in range(int(size.x)):
		for y: int in range(int(size.y)):
			var pixel: Color = Color.TRANSPARENT
			var pos: Vector2 = Vector2(x, y)
			var dist: float = pos.distance_to(center)

			match shape:
				"circle":
					if dist <= size.x / 2.0:
						var brightness: float = 1.0 - (dist / (size.x / 2.0)) * 0.3
						pixel = color * brightness
						pixel.a = 1.0
				"round":
					var rx: float = size.x / 2.0
					var ry: float = size.y / 2.0
					var nx: float = (float(x) - center.x) / rx
					var ny: float = (float(y) - center.y) / ry
					if nx * nx + ny * ny <= 1.0:
						var brightness: float = 1.0 - (nx * nx + ny * ny) * 0.3
						pixel = color * brightness
						pixel.a = 1.0
				"angular":
					var margin: float = 4.0
					if x >= margin and x < size.x - margin \
						and y >= margin and y < size.y - margin:
						var edge_dist: float = minf(
							minf(float(x) - margin, size.x - margin - float(x)),
							minf(float(y) - margin, size.y - margin - float(y))
						)
						var brightness: float = 0.7 + edge_dist / size.x * 0.6
						pixel = color * brightness
						pixel.a = 1.0

			image.set_pixel(x, y, pixel)

	# 目を描画（簡易）
	var eye_y: int = int(center.y - size.y * 0.1)
	var eye_left_x: int = int(center.x - size.x * 0.15)
	var eye_right_x: int = int(center.x + size.x * 0.15)
	var eye_size: int = maxi(2, int(size.x * 0.06))

	for dx: int in range(-eye_size, eye_size + 1):
		for dy: int in range(-eye_size, eye_size + 1):
			if dx * dx + dy * dy <= eye_size * eye_size:
				var lx: int = clampi(eye_left_x + dx, 0, int(size.x) - 1)
				var ly: int = clampi(eye_y + dy, 0, int(size.y) - 1)
				var rx: int = clampi(eye_right_x + dx, 0, int(size.x) - 1)
				var ry: int = clampi(eye_y + dy, 0, int(size.y) - 1)
				image.set_pixel(lx, ly, Color(0.1, 0.1, 0.15))
				image.set_pixel(rx, ry, Color(0.1, 0.1, 0.15))

	return ImageTexture.create_from_image(image)


## 全22形態のプレースホルダーを一括生成
static func generate_all() -> Dictionary:
	var textures: Dictionary = {}
	for form_id: String in EVOLUTION_FORMS:
		textures[form_id] = generate_placeholder(form_id)
	return textures


## 形態IDが有効かチェック
static func is_valid_form(form_id: String) -> bool:
	return EVOLUTION_FORMS.has(form_id)


## 形態の色を取得
static func get_form_color(form_id: String) -> Color:
	if EVOLUTION_FORMS.has(form_id):
		return EVOLUTION_FORMS[form_id]["color"]
	return Color(0.5, 0.5, 0.5)
