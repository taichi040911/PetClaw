## SpritePlaceholderGenerator — Lo-Fiピクセルアートスプライトを動的生成
## たまごっち/デジモン/Lo-Fi Monsters風のレトロピクセルアート
## 22進化形態 + 卵のスプライトを限定パレットで生成
class_name SpritePlaceholderGenerator
extends RefCounted

# === Lo-Fi Color Palette (Orange/Teal Gameboy inspired) ===
const PAL_BG: Color = Color(0.96, 0.95, 0.90)        # クリーム背景
const PAL_ORANGE_LIGHT: Color = Color(0.95, 0.78, 0.35)  # 明るいオレンジ
const PAL_ORANGE: Color = Color(0.90, 0.65, 0.20)     # メインオレンジ
const PAL_ORANGE_DARK: Color = Color(0.70, 0.45, 0.15)  # 暗いオレンジ
const PAL_TEAL_LIGHT: Color = Color(0.45, 0.78, 0.72)  # 明るいティール
const PAL_TEAL: Color = Color(0.30, 0.65, 0.60)       # メインティール
const PAL_TEAL_DARK: Color = Color(0.18, 0.45, 0.42)  # 暗いティール
const PAL_BLACK: Color = Color(0.12, 0.12, 0.15)      # 目/輪郭
const PAL_WHITE: Color = Color(0.98, 0.98, 0.95)      # ハイライト
const PAL_PURPLE: Color = Color(0.50, 0.30, 0.55)     # ダーク進化
const PAL_GOLD: Color = Color(0.92, 0.82, 0.35)       # エターナル

# === Sprite Size per Stage ===
const STAGE_SIZES: Dictionary = {
	0: 24,   # Blob
	1: 28,   # Infant
	2: 32,   # Youth
	3: 36,   # Adult
	4: 40,   # Elder
	5: 44,   # Eternal
}

# 22進化形態の定義 — パレット色・ステージ・シルエット
const EVOLUTION_FORMS: Dictionary = {
	# Stage 0: Blob
	"blob": {"stage": 0, "body": "blob", "color1": "orange", "color2": "orange_light", "features": ["dot_eyes", "tiny_mouth"]},

	# Stage 1: Infant (4種)
	"forest_infant": {"stage": 1, "body": "round_ears", "color1": "teal", "color2": "teal_light", "features": ["round_eyes", "smile", "leaf"]},
	"sea_infant": {"stage": 1, "body": "droplet", "color1": "teal", "color2": "teal_light", "features": ["round_eyes", "wavy_mouth", "bubble"]},
	"city_infant": {"stage": 1, "body": "square_body", "color1": "orange", "color2": "orange_light", "features": ["square_eyes", "grin", "antenna"]},
	"ruins_infant": {"stage": 1, "body": "ghost", "color1": "purple", "color2": "teal_dark", "features": ["wide_eyes", "zigzag_mouth"]},

	# Stage 2: Youth (7種)
	"warrior_youth": {"stage": 2, "body": "angular", "color1": "orange", "color2": "orange_dark", "features": ["angry_eyes", "grin", "horn"]},
	"scholar_youth": {"stage": 2, "body": "round_body", "color1": "teal", "color2": "teal_light", "features": ["glasses_eyes", "smile"]},
	"healer_youth": {"stage": 2, "body": "round_body", "color1": "teal_light", "color2": "teal", "features": ["gentle_eyes", "smile", "halo"]},
	"trickster_youth": {"stage": 2, "body": "angular", "color1": "orange_light", "color2": "orange", "features": ["wink_eyes", "grin", "tail"]},
	"sentinel_youth": {"stage": 2, "body": "square_body", "color1": "teal_dark", "color2": "teal", "features": ["visor_eyes", "neutral"]},
	"shadow_youth": {"stage": 2, "body": "angular", "color1": "purple", "color2": "teal_dark", "features": ["slit_eyes", "frown"]},
	"diplomat_youth": {"stage": 2, "body": "round_body", "color1": "orange", "color2": "teal", "features": ["round_eyes", "smile", "bow"]},

	# Stage 3: Adult (6種)
	"guardian_adult": {"stage": 3, "body": "big_square", "color1": "teal", "color2": "teal_dark", "features": ["determined_eyes", "neutral", "shield"]},
	"mystic_adult": {"stage": 3, "body": "tall_round", "color1": "purple", "color2": "teal", "features": ["sparkle_eyes", "smile", "gem"]},
	"sage_adult": {"stage": 3, "body": "round_body", "color1": "teal", "color2": "teal_light", "features": ["wise_eyes", "tiny_smile", "book"]},
	"storm_warrior_adult": {"stage": 3, "body": "angular", "color1": "orange_dark", "color2": "orange", "features": ["fierce_eyes", "grin", "lightning"]},
	"bond_master_adult": {"stage": 3, "body": "round_body", "color1": "orange_light", "color2": "teal_light", "features": ["heart_eyes", "wide_smile", "heart"]},
	"dark_sovereign_adult": {"stage": 3, "body": "angular", "color1": "purple", "color2": "black", "features": ["red_eyes", "frown", "crown"]},

	# Stage 4: Elder (3種)
	"ancient_elder": {"stage": 4, "body": "wise_round", "color1": "teal_dark", "color2": "teal", "features": ["half_eyes", "tiny_smile", "beard"]},
	"language_sage_elder": {"stage": 4, "body": "tall_round", "color1": "teal", "color2": "teal_light", "features": ["glasses_eyes", "smile", "scroll"]},
	"redeemed_elder": {"stage": 4, "body": "wise_round", "color1": "purple", "color2": "teal_light", "features": ["gentle_eyes", "smile", "wings"]},

	# Stage 5: Eternal
	"eternal_companion": {"stage": 5, "body": "cosmic", "color1": "gold", "color2": "orange_light", "features": ["sparkle_eyes", "wide_smile", "crown", "wings"]},
}


## メインカラーを名前から取得
static func _get_color(name: String) -> Color:
	match name:
		"orange_light": return PAL_ORANGE_LIGHT
		"orange": return PAL_ORANGE
		"orange_dark": return PAL_ORANGE_DARK
		"teal_light": return PAL_TEAL_LIGHT
		"teal": return PAL_TEAL
		"teal_dark": return PAL_TEAL_DARK
		"purple": return PAL_PURPLE
		"gold": return PAL_GOLD
		"black": return PAL_BLACK
		"white": return PAL_WHITE
	return PAL_ORANGE


## プレースホルダースプライトを生成（Lo-Fiピクセルアート）
static func generate_placeholder(form_id: String) -> ImageTexture:
	var form: Dictionary = EVOLUTION_FORMS.get(form_id, EVOLUTION_FORMS["blob"])
	var stage: int = form.get("stage", 0)
	var px_size: int = STAGE_SIZES.get(stage, 32)
	var img_size: int = px_size

	var image: Image = Image.create(img_size, img_size, false, Image.FORMAT_RGBA8)

	var col1: Color = _get_color(form.get("color1", "orange"))
	var col2: Color = _get_color(form.get("color2", "orange_light"))
	var body_type: String = form.get("body", "blob")
	var features: Array = form.get("features", [])

	# ボディ描画
	_draw_body(image, img_size, body_type, col1, col2)

	# 輪郭線
	_draw_outline(image, img_size)

	# 顔パーツ
	for feature: String in features:
		_draw_feature(image, img_size, feature, body_type)

	return ImageTexture.create_from_image(image)


## ボディシルエット描画
static func _draw_body(image: Image, size: int, body_type: String, col1: Color, col2: Color) -> void:
	var cx: float = size / 2.0
	var cy: float = size / 2.0

	match body_type:
		"blob":
			# 丸いブロブ（たまごっち初期型）
			var r: float = size * 0.38
			for x: int in range(size):
				for y: int in range(size):
					var dx: float = x - cx
					var dy: float = (y - cy - 1) * 1.15  # 少し縦長
					if dx * dx + dy * dy <= r * r:
						var t: float = float(y) / float(size)
						image.set_pixel(x, y, col1.lerp(col2, t))
			# 小さな足
			_draw_feet(image, size, col1)

		"round_ears":
			# 丸ボディ + 耳
			var r: float = size * 0.32
			for x: int in range(size):
				for y: int in range(size):
					var dx: float = x - cx
					var dy: float = (y - cy + 1)
					if dx * dx + dy * dy <= r * r:
						var t: float = float(y) / float(size)
						image.set_pixel(x, y, col1.lerp(col2, t))
			# 耳
			_draw_circle(image, int(cx - size * 0.25), int(cy - size * 0.32), int(size * 0.12), col2)
			_draw_circle(image, int(cx + size * 0.25), int(cy - size * 0.32), int(size * 0.12), col2)
			_draw_feet(image, size, col1)

		"droplet":
			# 水滴型
			var r: float = size * 0.30
			for x: int in range(size):
				for y: int in range(size):
					var dx: float = x - cx
					var lower_y: float = cy + 2
					var dy: float = y - lower_y
					if dx * dx + dy * dy <= r * r:
						image.set_pixel(x, y, col1.lerp(col2, float(y) / float(size)))
					# 上部の尖り
					elif y < int(cy) and y > int(cy - size * 0.35):
						var width_at_y: float = r * (float(y) - (cy - size * 0.35)) / (size * 0.35)
						if absf(dx) <= width_at_y:
							image.set_pixel(x, y, col2)

		"square_body":
			# 四角いボディ
			var margin: int = int(size * 0.18)
			var top: int = int(size * 0.22)
			var bottom: int = int(size * 0.78)
			for x: int in range(margin, size - margin):
				for y: int in range(top, bottom):
					var t: float = float(y - top) / float(bottom - top)
					image.set_pixel(x, y, col1.lerp(col2, t))
			_draw_feet(image, size, col1)

		"ghost":
			# ゴースト型（下部が波打つ）
			var r: float = size * 0.32
			for x: int in range(size):
				for y: int in range(size):
					var dx: float = x - cx
					var dy: float = (y - cy + 2)
					if y < int(cy + r) and (dx * dx + dy * dy <= r * r or (y > int(cy) and absf(dx) < r)):
						image.set_pixel(x, y, col1.lerp(col2, float(y) / float(size)))
			# 波打つ下部
			for x: int in range(int(cx - r), int(cx + r)):
				if x >= 0 and x < size:
					var wave_y: int = int(cy + r - 1 + sin(float(x) * 1.5) * 2)
					if wave_y >= 0 and wave_y < size:
						image.set_pixel(x, wave_y, col1)

		"angular":
			# 角ばったボディ（戦士系）
			var w: float = size * 0.35
			var h: float = size * 0.38
			var top_y: int = int(cy - h)
			for x: int in range(size):
				for y: int in range(size):
					var dx: float = absf(x - cx)
					if y >= top_y and y < int(cy + h):
						var width_at_y: float = w
						if y < int(cy - h * 0.3):
							# 上部は少し狭い
							width_at_y = w * 0.7 + w * 0.3 * (float(y - top_y) / (h * 0.7))
						if dx <= width_at_y:
							image.set_pixel(x, y, col1.lerp(col2, float(y) / float(size)))
			_draw_feet(image, size, col1)

		"round_body":
			# 大きな丸ボディ
			var r: float = size * 0.35
			for x: int in range(size):
				for y: int in range(size):
					var dx: float = x - cx
					var dy: float = y - cy
					if dx * dx + dy * dy <= r * r:
						image.set_pixel(x, y, col1.lerp(col2, float(y) / float(size)))
			_draw_feet(image, size, col1)

		"big_square":
			# 大きな四角（ガーディアン）
			var margin: int = int(size * 0.12)
			var top: int = int(size * 0.15)
			var bottom: int = int(size * 0.80)
			for x: int in range(margin, size - margin):
				for y: int in range(top, bottom):
					image.set_pixel(x, y, col1.lerp(col2, float(y - top) / float(bottom - top)))
			_draw_feet(image, size, col1)

		"tall_round":
			# 縦長丸（ミスティック/セージ）
			var rx: float = size * 0.28
			var ry: float = size * 0.40
			for x: int in range(size):
				for y: int in range(size):
					var nx: float = (x - cx) / rx
					var ny: float = (y - cy) / ry
					if nx * nx + ny * ny <= 1.0:
						image.set_pixel(x, y, col1.lerp(col2, float(y) / float(size)))
			_draw_feet(image, size, col1)

		"wise_round":
			# 長老型（丸い + 下部広がり）
			var r: float = size * 0.33
			for x: int in range(size):
				for y: int in range(size):
					var dx: float = x - cx
					var dy: float = y - cy + 2
					var effective_r: float = r
					if y > int(cy):
						effective_r = r + (float(y) - cy) * 0.15  # 下部が広がる
					if dx * dx + dy * dy <= effective_r * effective_r:
						image.set_pixel(x, y, col1.lerp(col2, float(y) / float(size)))

		"cosmic":
			# コズミック型（エターナル — 光る丸）
			var r: float = size * 0.36
			for x: int in range(size):
				for y: int in range(size):
					var dx: float = x - cx
					var dy: float = y - cy
					var dist_sq: float = dx * dx + dy * dy
					if dist_sq <= r * r:
						var t: float = sqrt(dist_sq) / r
						var glow: Color = col2.lerp(col1, t)
						glow = glow.lerp(PAL_WHITE, (1.0 - t) * 0.3)
						image.set_pixel(x, y, glow)
			_draw_feet(image, size, col1)

		_:
			# デフォルト: 丸
			var r: float = size * 0.35
			for x: int in range(size):
				for y: int in range(size):
					if Vector2(x, y).distance_to(Vector2(cx, cy)) <= r:
						image.set_pixel(x, y, col1)


## 足の描画
static func _draw_feet(image: Image, size: int, color: Color) -> void:
	var cx: int = size / 2
	var foot_y: int = int(size * 0.78)
	var foot_w: int = maxi(2, int(size * 0.10))
	var foot_h: int = maxi(2, int(size * 0.08))
	# 左足
	_draw_rect(image, cx - int(size * 0.18), foot_y, foot_w, foot_h, color.darkened(0.15))
	# 右足
	_draw_rect(image, cx + int(size * 0.08), foot_y, foot_w, foot_h, color.darkened(0.15))


## 円の描画
static func _draw_circle(image: Image, cx: int, cy: int, r: int, color: Color) -> void:
	for x: int in range(maxi(0, cx - r), mini(image.get_width(), cx + r + 1)):
		for y: int in range(maxi(0, cy - r), mini(image.get_height(), cy + r + 1)):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
				image.set_pixel(x, y, color)


## 矩形の描画
static func _draw_rect(image: Image, x0: int, y0: int, w: int, h: int, color: Color) -> void:
	for x: int in range(maxi(0, x0), mini(image.get_width(), x0 + w)):
		for y: int in range(maxi(0, y0), mini(image.get_height(), y0 + h)):
			image.set_pixel(x, y, color)


## 輪郭線を追加（ピクセルアート風）
static func _draw_outline(image: Image, size: int) -> void:
	var outline_img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	for x: int in range(size):
		for y: int in range(size):
			if image.get_pixel(x, y).a > 0.5:
				# 隣接ピクセルが透明なら輪郭
				var is_edge: bool = false
				for offset: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					var nx: int = x + offset.x
					var ny: int = y + offset.y
					if nx < 0 or nx >= size or ny < 0 or ny >= size:
						is_edge = true
						break
					if image.get_pixel(nx, ny).a < 0.5:
						is_edge = true
						break
				if is_edge:
					outline_img.set_pixel(x, y, PAL_BLACK)

	# 輪郭を元の画像に合成
	for x: int in range(size):
		for y: int in range(size):
			if outline_img.get_pixel(x, y).a > 0.5:
				image.set_pixel(x, y, PAL_BLACK)


## 顔パーツの描画
static func _draw_feature(image: Image, size: int, feature: String, _body_type: String) -> void:
	var cx: int = size / 2
	var eye_y: int = int(size * 0.38)
	var mouth_y: int = int(size * 0.52)
	var eye_gap: int = maxi(2, int(size * 0.14))
	var px: int = maxi(1, int(size * 0.04))  # ピクセルサイズ

	match feature:
		# === 目 ===
		"dot_eyes":
			_draw_rect(image, cx - eye_gap, eye_y, px, px, PAL_BLACK)
			_draw_rect(image, cx + eye_gap - px, eye_y, px, px, PAL_BLACK)

		"round_eyes":
			var er: int = maxi(1, int(size * 0.05))
			_draw_circle(image, cx - eye_gap, eye_y, er, PAL_BLACK)
			_draw_circle(image, cx + eye_gap, eye_y, er, PAL_BLACK)
			# ハイライト
			if er >= 2:
				image.set_pixel(cx - eye_gap - 1, eye_y - 1, PAL_WHITE)
				image.set_pixel(cx + eye_gap - 1, eye_y - 1, PAL_WHITE)

		"square_eyes":
			var es: int = maxi(2, int(size * 0.08))
			_draw_rect(image, cx - eye_gap - es / 2, eye_y - es / 2, es, es, PAL_BLACK)
			_draw_rect(image, cx + eye_gap - es / 2, eye_y - es / 2, es, es, PAL_BLACK)

		"wide_eyes":
			var er: int = maxi(2, int(size * 0.07))
			_draw_circle(image, cx - eye_gap, eye_y, er, PAL_BLACK)
			_draw_circle(image, cx + eye_gap, eye_y, er, PAL_BLACK)
			_draw_circle(image, cx - eye_gap, eye_y, maxi(1, er - 1), PAL_WHITE)
			_draw_circle(image, cx + eye_gap, eye_y, maxi(1, er - 1), PAL_WHITE)
			# 瞳
			image.set_pixel(cx - eye_gap, eye_y, PAL_BLACK)
			image.set_pixel(cx + eye_gap, eye_y, PAL_BLACK)

		"angry_eyes":
			# 怒り目（V字）
			for i: int in range(maxi(2, int(size * 0.06))):
				var lx: int = cx - eye_gap - i
				var rx: int = cx + eye_gap + i
				var ey: int = eye_y + i / 2
				if lx >= 0 and lx < size and ey < size:
					image.set_pixel(lx, ey, PAL_BLACK)
					if ey > 0:
						image.set_pixel(lx, ey - 1, PAL_BLACK)
				if rx >= 0 and rx < size and ey < size:
					image.set_pixel(rx, ey, PAL_BLACK)
					if ey > 0:
						image.set_pixel(rx, ey - 1, PAL_BLACK)

		"glasses_eyes":
			var er: int = maxi(2, int(size * 0.06))
			# 丸メガネ
			_draw_circle(image, cx - eye_gap, eye_y, er, PAL_BLACK)
			_draw_circle(image, cx - eye_gap, eye_y, maxi(1, er - 1), PAL_WHITE)
			_draw_circle(image, cx + eye_gap, eye_y, er, PAL_BLACK)
			_draw_circle(image, cx + eye_gap, eye_y, maxi(1, er - 1), PAL_WHITE)
			# ブリッジ
			_draw_rect(image, cx - eye_gap + er, eye_y, eye_gap * 2 - er * 2, px, PAL_BLACK)
			# 瞳
			image.set_pixel(cx - eye_gap, eye_y, PAL_BLACK)
			image.set_pixel(cx + eye_gap, eye_y, PAL_BLACK)

		"gentle_eyes":
			# 優しい半月目
			for i: int in range(maxi(2, int(size * 0.06))):
				var lx: int = cx - eye_gap - i + int(size * 0.03)
				var rx: int = cx + eye_gap - i + int(size * 0.03)
				if lx >= 0 and lx < size:
					image.set_pixel(lx, eye_y, PAL_BLACK)
				if rx >= 0 and rx < size:
					image.set_pixel(rx, eye_y, PAL_BLACK)

		"wink_eyes":
			# 片目ウインク
			var er: int = maxi(1, int(size * 0.05))
			_draw_circle(image, cx - eye_gap, eye_y, er, PAL_BLACK)
			if er >= 2:
				image.set_pixel(cx - eye_gap - 1, eye_y - 1, PAL_WHITE)
			# ウインク（横線）
			_draw_rect(image, cx + eye_gap - er, eye_y, er * 2, px, PAL_BLACK)

		"visor_eyes":
			# バイザー（横一線）
			var vw: int = int(size * 0.35)
			_draw_rect(image, cx - vw / 2, eye_y - px, vw, px * 2, PAL_BLACK)
			# 光る部分
			_draw_rect(image, cx - vw / 2 + 2, eye_y - px, 2, px, PAL_TEAL_LIGHT)
			_draw_rect(image, cx + vw / 2 - 4, eye_y - px, 2, px, PAL_TEAL_LIGHT)

		"slit_eyes":
			# 細い目
			_draw_rect(image, cx - eye_gap - px, eye_y, px * 2, px, PAL_BLACK)
			_draw_rect(image, cx + eye_gap - px, eye_y, px * 2, px, PAL_BLACK)

		"determined_eyes":
			var er: int = maxi(2, int(size * 0.05))
			_draw_circle(image, cx - eye_gap, eye_y, er, PAL_BLACK)
			_draw_circle(image, cx + eye_gap, eye_y, er, PAL_BLACK)
			# 眉毛
			_draw_rect(image, cx - eye_gap - er, eye_y - er - px, er * 2, px, PAL_BLACK)
			_draw_rect(image, cx + eye_gap - er, eye_y - er - px, er * 2, px, PAL_BLACK)

		"sparkle_eyes":
			# キラキラ目（星型）
			var er: int = maxi(2, int(size * 0.06))
			_draw_circle(image, cx - eye_gap, eye_y, er, PAL_GOLD)
			_draw_circle(image, cx + eye_gap, eye_y, er, PAL_GOLD)
			image.set_pixel(cx - eye_gap, eye_y, PAL_WHITE)
			image.set_pixel(cx + eye_gap, eye_y, PAL_WHITE)

		"fierce_eyes":
			var er: int = maxi(2, int(size * 0.05))
			_draw_circle(image, cx - eye_gap, eye_y, er, PAL_ORANGE_DARK)
			_draw_circle(image, cx + eye_gap, eye_y, er, PAL_ORANGE_DARK)
			image.set_pixel(cx - eye_gap, eye_y, PAL_BLACK)
			image.set_pixel(cx + eye_gap, eye_y, PAL_BLACK)

		"heart_eyes":
			# ハート目
			var er: int = maxi(1, int(size * 0.04))
			_draw_circle(image, cx - eye_gap - er / 2, eye_y - er / 2, er, Color(0.9, 0.3, 0.4))
			_draw_circle(image, cx - eye_gap + er / 2, eye_y - er / 2, er, Color(0.9, 0.3, 0.4))
			_draw_circle(image, cx + eye_gap - er / 2, eye_y - er / 2, er, Color(0.9, 0.3, 0.4))
			_draw_circle(image, cx + eye_gap + er / 2, eye_y - er / 2, er, Color(0.9, 0.3, 0.4))

		"red_eyes":
			var er: int = maxi(2, int(size * 0.05))
			_draw_circle(image, cx - eye_gap, eye_y, er, Color(0.8, 0.15, 0.15))
			_draw_circle(image, cx + eye_gap, eye_y, er, Color(0.8, 0.15, 0.15))

		"half_eyes":
			# 半目（長老）
			_draw_rect(image, cx - eye_gap - px, eye_y, px * 3, px, PAL_BLACK)
			_draw_rect(image, cx + eye_gap - px, eye_y, px * 3, px, PAL_BLACK)

		"wise_eyes":
			var er: int = maxi(1, int(size * 0.04))
			_draw_circle(image, cx - eye_gap, eye_y, er, PAL_BLACK)
			_draw_circle(image, cx + eye_gap, eye_y, er, PAL_BLACK)

		# === 口 ===
		"tiny_mouth":
			image.set_pixel(cx, mouth_y, PAL_BLACK)

		"smile":
			# 微笑み（弧）
			var mw: int = maxi(2, int(size * 0.10))
			for i: int in range(mw):
				var mx: int = cx - mw / 2 + i
				var my: int = mouth_y + (1 if (i > 0 and i < mw - 1) else 0)
				if mx >= 0 and mx < size and my < size:
					image.set_pixel(mx, my, PAL_BLACK)

		"wide_smile":
			var mw: int = maxi(3, int(size * 0.15))
			for i: int in range(mw):
				var mx: int = cx - mw / 2 + i
				var my: int = mouth_y + (1 if (i > 1 and i < mw - 2) else 0)
				if mx >= 0 and mx < size and my < size:
					image.set_pixel(mx, my, PAL_BLACK)

		"grin":
			# ニヤリ
			var mw: int = maxi(3, int(size * 0.12))
			_draw_rect(image, cx - mw / 2, mouth_y, mw, px, PAL_BLACK)
			# 上向きの端
			if cx - mw / 2 >= 0 and mouth_y - 1 >= 0:
				image.set_pixel(cx - mw / 2, mouth_y - 1, PAL_BLACK)
			if cx + mw / 2 - 1 < size and mouth_y - 1 >= 0:
				image.set_pixel(cx + mw / 2 - 1, mouth_y - 1, PAL_BLACK)

		"wavy_mouth":
			var mw: int = maxi(3, int(size * 0.12))
			for i: int in range(mw):
				var mx: int = cx - mw / 2 + i
				var my: int = mouth_y + (1 if i % 2 == 0 else 0)
				if mx >= 0 and mx < size and my < size:
					image.set_pixel(mx, my, PAL_BLACK)

		"frown":
			var mw: int = maxi(2, int(size * 0.10))
			for i: int in range(mw):
				var mx: int = cx - mw / 2 + i
				var my: int = mouth_y - (1 if (i > 0 and i < mw - 1) else 0)
				if mx >= 0 and mx < size and my >= 0 and my < size:
					image.set_pixel(mx, my, PAL_BLACK)

		"neutral":
			var mw: int = maxi(2, int(size * 0.08))
			_draw_rect(image, cx - mw / 2, mouth_y, mw, px, PAL_BLACK)

		"zigzag_mouth":
			var mw: int = maxi(3, int(size * 0.12))
			for i: int in range(mw):
				var mx: int = cx - mw / 2 + i
				var my: int = mouth_y + (1 if i % 2 == 0 else -1)
				if mx >= 0 and mx < size and my >= 0 and my < size:
					image.set_pixel(mx, my, PAL_BLACK)

		"tiny_smile":
			var mw: int = maxi(2, int(size * 0.06))
			for i: int in range(mw):
				var mx: int = cx - mw / 2 + i
				if mx >= 0 and mx < size and mouth_y < size:
					image.set_pixel(mx, mouth_y, PAL_BLACK)

		# === アクセサリー ===
		"leaf":
			var lx: int = cx + int(size * 0.15)
			var ly: int = int(size * 0.15)
			_draw_rect(image, lx, ly, 3, 2, PAL_TEAL)
			if lx + 1 < size and ly - 1 >= 0:
				image.set_pixel(lx + 1, ly - 1, PAL_TEAL)

		"bubble":
			var bx: int = cx + int(size * 0.22)
			var by: int = int(size * 0.25)
			if bx < size and by < size:
				_draw_circle(image, bx, by, maxi(1, int(size * 0.04)), PAL_TEAL_LIGHT)

		"antenna":
			var ax: int = cx
			var ay: int = int(size * 0.15)
			_draw_rect(image, ax, ay, px, int(size * 0.08), PAL_ORANGE_DARK)
			_draw_circle(image, ax, ay, maxi(1, px), PAL_ORANGE_LIGHT)

		"horn":
			var hx: int = cx
			var hy: int = int(size * 0.12)
			_draw_rect(image, hx - px, hy, px * 2, int(size * 0.08), PAL_ORANGE_DARK)

		"tail":
			var tx: int = int(size * 0.80)
			var ty: int = int(size * 0.55)
			if tx + 3 < size:
				_draw_rect(image, tx, ty, 3, 2, PAL_ORANGE_DARK)
				image.set_pixel(tx + 2, ty - 1, PAL_ORANGE_DARK)

		"halo":
			# 天使の輪
			var hx: int = cx
			var hy: int = int(size * 0.12)
			var hw: int = int(size * 0.18)
			_draw_rect(image, hx - hw / 2, hy, hw, px, PAL_GOLD)

		"bow":
			# リボン
			var bx: int = cx + int(size * 0.18)
			var by: int = int(size * 0.20)
			if bx + 2 < size and by + 2 < size:
				image.set_pixel(bx, by, PAL_ORANGE)
				image.set_pixel(bx + 1, by + 1, PAL_ORANGE)
				image.set_pixel(bx - 1, by + 1, PAL_ORANGE)

		"shield":
			var sx: int = int(size * 0.78)
			var sy: int = int(size * 0.40)
			_draw_rect(image, sx, sy, 3, 4, PAL_TEAL_DARK)
			if sx + 1 < size and sy + 4 < size:
				image.set_pixel(sx + 1, sy + 4, PAL_TEAL_DARK)

		"gem":
			var gx: int = cx
			var gy: int = int(size * 0.28)
			if gy >= 0 and gx >= 0 and gx < size:
				image.set_pixel(gx, gy, PAL_PURPLE)
				if gx - 1 >= 0:
					image.set_pixel(gx - 1, gy + 1, PAL_PURPLE)
				if gx + 1 < size:
					image.set_pixel(gx + 1, gy + 1, PAL_PURPLE)

		"lightning":
			var lx: int = int(size * 0.78)
			var ly: int = int(size * 0.25)
			if lx < size and ly + 4 < size:
				image.set_pixel(lx, ly, PAL_GOLD)
				image.set_pixel(lx - 1, ly + 1, PAL_GOLD)
				image.set_pixel(lx, ly + 2, PAL_GOLD)
				image.set_pixel(lx + 1, ly + 3, PAL_GOLD)

		"heart":
			var hx: int = int(size * 0.78)
			var hy: int = int(size * 0.25)
			if hx + 1 < size and hy + 1 < size:
				image.set_pixel(hx, hy, Color(0.9, 0.3, 0.4))
				image.set_pixel(hx + 1, hy, Color(0.9, 0.3, 0.4))
				image.set_pixel(hx, hy + 1, Color(0.9, 0.3, 0.4))

		"crown":
			var cw: int = int(size * 0.22)
			var cy: int = int(size * 0.10)
			_draw_rect(image, cx - cw / 2, cy, cw, 2, PAL_GOLD)
			# 3つのとんがり
			if cx - cw / 2 >= 0 and cy - 1 >= 0:
				image.set_pixel(cx - cw / 2, cy - 1, PAL_GOLD)
			image.set_pixel(cx, cy - 2, PAL_GOLD)
			if cx + cw / 2 - 1 < size and cy - 1 >= 0:
				image.set_pixel(cx + cw / 2 - 1, cy - 1, PAL_GOLD)

		"beard":
			var bw: int = int(size * 0.16)
			var by: int = int(size * 0.58)
			for i: int in range(bw):
				var bx: int = cx - bw / 2 + i
				var b_y: int = by + (1 if i % 2 == 0 else 0)
				if bx >= 0 and bx < size and b_y < size:
					image.set_pixel(bx, b_y, PAL_TEAL_LIGHT)

		"scroll":
			var sx: int = int(size * 0.78)
			var sy: int = int(size * 0.45)
			_draw_rect(image, sx, sy, 2, 4, PAL_ORANGE_LIGHT)

		"wings":
			var wy: int = int(size * 0.35)
			# 左翼
			var lwx: int = int(size * 0.10)
			_draw_rect(image, lwx, wy, 2, 3, PAL_TEAL_LIGHT)
			if lwx - 1 >= 0:
				image.set_pixel(lwx - 1, wy + 1, PAL_TEAL_LIGHT)
			# 右翼
			var rwx: int = int(size * 0.85)
			if rwx + 2 <= size:
				_draw_rect(image, rwx, wy, 2, 3, PAL_TEAL_LIGHT)
				if rwx + 2 < size:
					image.set_pixel(rwx + 2, wy + 1, PAL_TEAL_LIGHT)

		"book":
			var bkx: int = int(size * 0.75)
			var bky: int = int(size * 0.50)
			_draw_rect(image, bkx, bky, 3, 3, PAL_ORANGE_DARK)


## 卵スプライト生成
static func generate_egg() -> ImageTexture:
	var size: int = 32
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0

	# 卵型（楕円）
	var rx: float = size * 0.32
	var ry: float = size * 0.42
	for x: int in range(size):
		for y: int in range(size):
			var nx: float = (x - cx) / rx
			var ny: float = (y - cy + 2) / ry
			if nx * nx + ny * ny <= 1.0:
				var t: float = float(y) / float(size)
				var col: Color = PAL_ORANGE_LIGHT.lerp(PAL_ORANGE, t)
				# 上部ハイライト
				if ny < -0.3:
					col = col.lerp(PAL_WHITE, 0.2)
				image.set_pixel(x, y, col)

	# ティールの模様
	for x: int in range(size):
		for y: int in range(size):
			if image.get_pixel(x, y).a > 0.5:
				var nx: float = (x - cx) / rx
				var ny: float = (y - cy + 2) / ry
				# ジグザグ模様
				if absf(ny - 0.1 + sin(float(x) * 0.8) * 0.15) < 0.06:
					image.set_pixel(x, y, PAL_TEAL)

	_draw_outline(image, size)
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
		return _get_color(EVOLUTION_FORMS[form_id].get("color1", "orange"))
	return PAL_ORANGE
