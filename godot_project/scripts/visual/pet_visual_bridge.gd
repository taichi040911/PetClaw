## PetVisualBridge — ExpressionSystem の出力をスプライトノードに反映する
## PetEntity の子ノードとして配置し、Body/Eyes/Mouth/Effect スプライトを駆動
class_name PetVisualBridge
extends Node2D

# === Sprite References (シーンツリーから取得) ===
@export var body_sprite: Sprite2D
@export var eyes_sprite: Sprite2D
@export var mouth_sprite: Sprite2D
@export var effect_sprite: Sprite2D
@export var emotion_particles: GPUParticles2D

# === Pet Reference ===
var pet_entity: PetEntity
var pet_id: int = 0

# === Animation State ===
var _idle_time: float = 0.0
var _bounce_offset: float = 0.0
var _original_position: Vector2 = Vector2.ZERO
var _blink_timer: float = 0.0
var _blink_interval: float = 3.0
var _is_blinking: bool = false

# === Sprite Cache ===
var _current_form_id: String = ""
var _expression_textures: Dictionary = {}  # "eyes_happy" → Texture2D etc.
var _current_expression: String = "neutral"  # 現在の表情

# === Evolution Stage Palettes（進化段階→ベースカラーパレット）===
const STAGE_PALETTES: Dictionary = {
	0: {"base": Color(0.95, 0.90, 0.80), "accent": Color(0.90, 0.78, 0.35), "outline": Color(0.70, 0.65, 0.55)},  # Egg — 淡いクリーム
	1: {"base": Color(0.90, 0.65, 0.20), "accent": Color(0.95, 0.78, 0.35), "outline": Color(0.70, 0.45, 0.15)},  # Blob — オレンジ基調
	2: {"base": Color(0.45, 0.78, 0.72), "accent": Color(0.30, 0.65, 0.60), "outline": Color(0.18, 0.45, 0.42)},  # Infant — ティール基調
	3: {"base": Color(0.55, 0.70, 0.85), "accent": Color(0.40, 0.55, 0.80), "outline": Color(0.25, 0.35, 0.55)},  # Youth — 青系
	4: {"base": Color(0.80, 0.50, 0.55), "accent": Color(0.70, 0.35, 0.40), "outline": Color(0.50, 0.20, 0.25)},  # Adult — 深紅系
	5: {"base": Color(0.92, 0.82, 0.35), "accent": Color(0.98, 0.90, 0.50), "outline": Color(0.70, 0.60, 0.20)},  # Elder — ゴールド
}

# === Evolution Stage Body Parameters（進化段階→体形パラメータ）===
const STAGE_BODY_PARAMS: Dictionary = {
	0: {"scale": Vector2(1.2, 1.2), "squash": 0.0, "bounce_mult": 0.3},      # Egg — 丸くて静か
	1: {"scale": Vector2(1.6, 1.6), "squash": 0.15, "bounce_mult": 1.0},     # Blob — 小さく弾む
	2: {"scale": Vector2(1.8, 1.8), "squash": 0.10, "bounce_mult": 0.9},     # Infant — やや大きく
	3: {"scale": Vector2(2.0, 2.0), "squash": 0.05, "bounce_mult": 0.8},     # Youth — 標準サイズ
	4: {"scale": Vector2(2.2, 2.2), "squash": 0.02, "bounce_mult": 0.6},     # Adult — 大きく堂々
	5: {"scale": Vector2(2.5, 2.5), "squash": 0.0, "bounce_mult": 0.4},      # Elder — 最大、落ち着き
}

# === Stage Overlay Texture Cache ===
var _stage_overlay_cache: Dictionary = {}  # stage → ImageTexture
var _current_evolution_stage: int = -1
var _stage_tint: Color = Color.WHITE

# === Color Mapping (感情→ペットの色味変化) ===
const EMOTION_COLORS: Dictionary = {
	"joy": Color(1.0, 0.95, 0.4),       # 明るい黄色
	"love": Color(1.0, 0.6, 0.7),       # ピンク
	"excitement": Color(1.0, 0.8, 0.2),  # オレンジ黄
	"sadness": Color(0.6, 0.7, 0.9),    # 薄い青
	"fear": Color(0.7, 0.6, 0.8),       # 薄い紫
	"neutral": Color(1.0, 1.0, 1.0),    # 白（通常）
}

# === Effect Emoji Textures (procedural) ===
const EFFECT_CHARS: Dictionary = {
	0: "",       # NONE
	1: "♥",     # HEART
	2: "♪",     # MUSIC_NOTE
	3: "!",      # EXCLAMATION
	4: "?",      # QUESTION
	5: "💢",    # ANGER_MARK
	6: "💧",    # SWEAT_DROP
	7: "✨",    # SPARKLES
	8: "Zzz",   # ZZZZZ
	9: "😢",    # TEARS
	10: "//",    # BLUSH
	11: "🌑",   # SHADOW
}


func _ready() -> void:
	_original_position = position

	# 子ノードからスプライト参照を取得
	if not body_sprite:
		body_sprite = get_node_or_null("Body") as Sprite2D
	if not eyes_sprite:
		eyes_sprite = get_node_or_null("Eyes") as Sprite2D
	if not mouth_sprite:
		mouth_sprite = get_node_or_null("Mouth") as Sprite2D
	if not effect_sprite:
		effect_sprite = get_node_or_null("ExpressionEffect") as Sprite2D
	if not emotion_particles:
		emotion_particles = get_node_or_null("EmotionParticles") as GPUParticles2D

	# 親ノードから PetEntity を探す
	await get_tree().process_frame
	var parent: Node = get_parent()
	if parent is PetEntity:
		pet_entity = parent
		pet_id = pet_entity.pet_id
		pet_entity.emotion_changed.connect(_on_emotion_changed)

	# スプライトを読み込み
	_load_pet_sprites()

	# 影スプライトのセットアップ
	var shadow: Sprite2D = get_parent().get_node_or_null("../ShadowSprite") as Sprite2D
	if shadow and not shadow.texture:
		shadow.texture = _create_shadow_texture()


var _status_label: Label  # 状態テキスト（Zzz, !, 💧）
var _zzz_timer: float = 0.0

# === Happiness Indicators ===
var _happiness_timer: float = 0.0
var _happiness_interval: float = 1.5  # パーティクル生成間隔
var _sparkle_pool: Array[Label] = []
const MAX_SPARKLES: int = 6

func _process(delta: float) -> void:
	if not pet_entity:
		return

	# 死亡状態 — グレースケール化して停止
	if not pet_entity.is_alive:
		if body_sprite:
			body_sprite.modulate = body_sprite.modulate.lerp(Color(0.3, 0.3, 0.3, 0.6), 0.02)
		return

	_idle_time += delta
	_update_idle_animation(delta)
	_update_emotion_visuals()
	_update_blink(delta)
	_update_status_visuals(delta)
	_update_happiness_indicators(delta)
	_apply_evolution_stage_visuals(delta)

	# フォーム変更チェック
	var form_id: String = pet_entity.get("current_form") if pet_entity.get("current_form") else "blob"
	if form_id != _current_form_id:
		_current_form_id = form_id
		_load_pet_sprites()


# ========================================================
# スプライト読み込み
# ========================================================

func _load_pet_sprites() -> void:
	if not pet_entity:
		return

	var form_id: String = pet_entity.get("current_form") if pet_entity.get("current_form") else "blob"
	_current_form_id = form_id

	# === Body Sprite ===
	var body_path: String = "res://assets/sprites/forms/%s.png" % form_id
	if ResourceLoader.exists(body_path):
		body_sprite.texture = load(body_path)
	else:
		# プレースホルダーフォールバック
		body_sprite.texture = SpritePlaceholderGenerator.generate_placeholder(form_id)
	# ピクセルアートをくっきり表示
	body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# === Expression Sprites (Eyes/Mouth) ===
	var expr_dir: String = "res://assets/sprites/expressions/%s/" % form_id
	var eyes_path: String = expr_dir + "%s_eyes.png" % form_id
	var mouths_path: String = expr_dir + "%s_mouths.png" % form_id

	if ResourceLoader.exists(eyes_path):
		eyes_sprite.texture = load(eyes_path)
		eyes_sprite.visible = true
	else:
		eyes_sprite.visible = false

	if ResourceLoader.exists(mouths_path):
		mouth_sprite.texture = load(mouths_path)
		mouth_sprite.visible = true
	else:
		mouth_sprite.visible = false

	# パーティクル設定
	_setup_emotion_particles()


func _setup_emotion_particles() -> void:
	if not emotion_particles:
		return
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 20.0
	mat.gravity = Vector3(0, -30, 0)
	mat.initial_velocity_min = 10.0
	mat.initial_velocity_max = 25.0
	mat.spread = 60.0
	mat.scale_min = 0.3
	mat.scale_max = 0.8

	var gradient: Gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.9, 0.3, 1.0))
	gradient.add_point(1.0, Color(1.0, 0.5, 0.2, 0.0))
	var grad_tex: GradientTexture1D = GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_initial_ramp = grad_tex

	emotion_particles.process_material = mat
	emotion_particles.emitting = false


# ========================================================
# アイドルアニメーション
# ========================================================

func _update_idle_animation(_delta: float) -> void:
	# エネルギーに応じたバウンス強度（低エネルギー=ほぼ動かない）
	var energy_mult: float = 1.0
	if pet_entity:
		energy_mult = 0.3 + pet_entity.stats.energy * 0.7  # 0.3〜1.0

	# 進化段階によるバウンス倍率（成長するほど落ち着く）
	var stage_params: Dictionary = STAGE_BODY_PARAMS.get(_current_evolution_stage, STAGE_BODY_PARAMS[3])
	var stage_bounce: float = stage_params["bounce_mult"] as float

	# ゆっくりとした上下バウンス（呼吸のような動き）
	_bounce_offset = sin(_idle_time * 1.5) * 3.0 * energy_mult * stage_bounce
	position = _original_position + Vector2(0, _bounce_offset)

	# 好奇心が高い場合、左右にわずかに揺れる
	if pet_entity and pet_entity.personality.get("curious", 0.5) > 0.7:
		var sway: float = sin(_idle_time * 0.8) * 2.0 * energy_mult
		position.x = _original_position.x + sway


# ========================================================
# まばたき
# ========================================================

func _update_blink(delta: float) -> void:
	_blink_timer += delta
	if _is_blinking:
		if _blink_timer > 0.12:
			_is_blinking = false
			_blink_timer = 0.0
			if eyes_sprite:
				eyes_sprite.modulate.a = 1.0
	else:
		if _blink_timer > _blink_interval:
			_is_blinking = true
			_blink_timer = 0.0
			_blink_interval = randf_range(2.5, 4.5)
			if eyes_sprite:
				eyes_sprite.modulate.a = 0.1  # ほぼ閉じ


# ========================================================
# ステータスビジュアル（空腹・病気・眠い）
# ========================================================

func _update_status_visuals(delta: float) -> void:
	if not pet_entity:
		return

	var hunger: float = pet_entity.stats.hunger
	var health: float = pet_entity.stats.health
	var energy: float = pet_entity.stats.energy

	# 空腹 — 暗くなる + 動きが鈍る
	if hunger < 0.2 and body_sprite:
		var dim: float = 0.5 + hunger * 2.5  # 0.5〜1.0
		body_sprite.modulate.a = lerpf(body_sprite.modulate.a, dim, 0.05)

	# 体調不良 — 緑がかる
	if health < 0.3 and body_sprite:
		var sick_tint: Color = Color(0.7, 0.9, 0.7)
		body_sprite.modulate = body_sprite.modulate.lerp(sick_tint, 0.03)

	# 眠い — DayNightCycleと連動
	if DayNightCycle.instance and DayNightCycle.instance.is_sleepy_time():
		_zzz_timer += delta
		# 3秒ごとにZzzラベルを浮かべる
		if _zzz_timer > 3.0:
			_zzz_timer = 0.0
			_spawn_zzz_label()
		# アイドル動作をゆっくりに
		_idle_time *= 0.98  # 段々遅くなる

	# エネルギー低下 — バウンスが小さくなる（_update_idle_animation内で使用）


func _spawn_zzz_label() -> void:
	var zzz: Label = Label.new()
	zzz.text = ["z", "Z", "z Z"][randi() % 3]
	zzz.add_theme_font_size_override("font_size", 16)
	zzz.add_theme_color_override("font_color", Color(0.6, 0.6, 0.9, 0.5))
	zzz.position = Vector2(randf_range(-15, 25), -60)
	zzz.z_index = 10
	add_child(zzz)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(zzz, "position:y", zzz.position.y - 40, 1.5)
	tween.tween_property(zzz, "modulate:a", 0.0, 1.5)
	tween.chain().tween_callback(zzz.queue_free)


# ========================================================
# 感情ビジュアル
# ========================================================

func _update_emotion_visuals() -> void:
	if not pet_entity:
		return

	# 支配的な感情を取得
	var dominant_emotion: String = "neutral"
	var max_intensity: float = 0.0

	for emotion_name: String in pet_entity.emotions:
		var intensity: float = pet_entity.emotions[emotion_name]
		if intensity > max_intensity:
			max_intensity = intensity
			dominant_emotion = emotion_name

	if max_intensity < 0.1:
		dominant_emotion = "neutral"

	# ボディの色味を感情 + 進化段階で微調整（モジュレーション）
	var emotion_color: Color = EMOTION_COLORS.get(dominant_emotion, Color.WHITE)
	var target_color: Color = _stage_tint.lerp(emotion_color, clampf(max_intensity, 0.0, 0.6))
	if body_sprite:
		body_sprite.modulate = body_sprite.modulate.lerp(target_color, 0.08)

	# 目の色も感情で変える（微妙に）
	if eyes_sprite and eyes_sprite.visible:
		var eye_tint: Color = target_color.lerp(Color.WHITE, 0.7)
		eyes_sprite.modulate = eyes_sprite.modulate.lerp(eye_tint, 0.08)

	# 表情テクスチャの更新（感情に応じた目と口）
	_update_expression(dominant_emotion)

	# パーティクルの制御 — 感情が強い時に放出
	if emotion_particles:
		if max_intensity > 0.6:
			# パーティクルの色を感情色に合わせる
			var mat: ParticleProcessMaterial = emotion_particles.process_material as ParticleProcessMaterial
			if mat and mat.color_initial_ramp:
				var grad_tex: GradientTexture1D = mat.color_initial_ramp as GradientTexture1D
				if grad_tex and grad_tex.gradient:
					grad_tex.gradient.set_color(0, target_color)
					grad_tex.gradient.set_color(1, Color(target_color.r, target_color.g, target_color.b, 0.0))
			emotion_particles.emitting = true
		else:
			emotion_particles.emitting = false


func _update_expression(dominant_emotion: String) -> void:
	# 夜間は眠い表情にオーバーライド
	var target_expression: String = dominant_emotion
	if DayNightCycle.instance and DayNightCycle.instance.is_sleepy_time():
		target_expression = "sleepy"

	if target_expression == _current_expression:
		return
	_current_expression = target_expression

	# 目テクスチャ更新
	if eyes_sprite:
		if target_expression == "sleepy":
			eyes_sprite.texture = ExpressionGenerator.get_sleepy_eye_texture()
		else:
			eyes_sprite.texture = ExpressionGenerator.get_eye_texture(dominant_emotion)
		eyes_sprite.visible = true
		eyes_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# 口テクスチャ更新
	if mouth_sprite:
		if target_expression == "sleepy":
			mouth_sprite.texture = ExpressionGenerator.get_sleepy_mouth_texture()
		else:
			mouth_sprite.texture = ExpressionGenerator.get_mouth_texture(dominant_emotion)
		mouth_sprite.visible = true
		mouth_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _on_emotion_changed(emotion: String, intensity: float) -> void:
	# 強い感情変化時のリアクション
	if intensity > 0.5:
		_play_emotion_reaction(emotion, intensity)


func _play_emotion_reaction(emotion: String, intensity: float) -> void:
	# ジャンプ反応
	var jump_height: float = intensity * 12.0

	var tween: Tween = create_tween()
	tween.tween_property(self, "position:y",
		_original_position.y - jump_height, 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y",
		_original_position.y, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)

	# スケールパルス（ぶわっと膨張）
	if body_sprite:
		var scale_tween: Tween = create_tween()
		scale_tween.tween_property(body_sprite, "scale",
			Vector2(2.3, 2.3), 0.1).set_ease(Tween.EASE_OUT)
		scale_tween.tween_property(body_sprite, "scale",
			Vector2(2.0, 2.0), 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)

	# エフェクト文字の表示
	_show_effect_label(emotion, intensity)


func _show_effect_label(emotion: String, intensity: float) -> void:
	# 感情に応じたエフェクト文字を浮かべる
	var effect_text: String = ""
	match emotion:
		"joy": effect_text = "♪" if intensity < 0.7 else "♥"
		"love": effect_text = "♥"
		"excitement": effect_text = "!"
		"sadness": effect_text = "..."
		"fear": effect_text = "!?"
		_: effect_text = "..."

	var label: Label = Label.new()
	label.text = effect_text
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", EMOTION_COLORS.get(emotion, Color.WHITE))
	label.position = Vector2(20, -50)
	label.z_index = 10
	add_child(label)

	var fade_tween: Tween = create_tween()
	fade_tween.tween_property(label, "position:y", label.position.y - 30, 0.8)
	fade_tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	fade_tween.tween_callback(label.queue_free)


# ========================================================
# Happiness Indicators（幸福度パーティクル）
# ========================================================

func _update_happiness_indicators(delta: float) -> void:
	if not pet_entity:
		return

	# 幸福度の計算（joy + love + excitement の複合）
	var joy: float = pet_entity.emotions.get("joy", 0.0)
	var love: float = pet_entity.emotions.get("love", 0.0)
	var excitement: float = pet_entity.emotions.get("excitement", 0.0)
	var sadness: float = pet_entity.emotions.get("sadness", 0.0)
	var fear: float = pet_entity.emotions.get("fear", 0.0)

	var happiness: float = (joy * 0.4 + love * 0.35 + excitement * 0.25) - (sadness * 0.3 + fear * 0.2)
	happiness = clampf(happiness, 0.0, 1.0)

	# 幸福度が低い場合はスキップ
	if happiness < 0.3:
		_happiness_timer = 0.0
		return

	# 幸福度に応じて生成間隔を調整（高いほど頻繁）
	_happiness_interval = lerpf(2.0, 0.4, (happiness - 0.3) / 0.7)

	_happiness_timer += delta
	if _happiness_timer < _happiness_interval:
		return

	_happiness_timer = 0.0

	# 古いスパークルを掃除
	_sparkle_pool = _sparkle_pool.filter(func(s: Label) -> bool: return is_instance_valid(s))
	if _sparkle_pool.size() >= MAX_SPARKLES:
		return

	# パーティクルの種類を幸福度と感情で決定
	_spawn_happiness_particle(happiness, joy, love, excitement)


func _spawn_happiness_particle(happiness: float, joy: float, love: float, excitement: float) -> void:
	var particle: Label = Label.new()

	# 支配的な正の感情に応じたパーティクル
	var max_positive: String = "joy"
	var max_val: float = joy
	if love > max_val:
		max_positive = "love"
		max_val = love
	if excitement > max_val:
		max_positive = "excitement"

	# パーティクル文字と色
	var chars: Array = []
	var color: Color = Color.WHITE
	match max_positive:
		"joy":
			chars = ["✨", "☆", "★", "✦", "·"]
			color = Color(1.0, 0.95, 0.4, 0.8)
		"love":
			chars = ["♥", "♡", "💕", "·", "♥"]
			color = Color(1.0, 0.55, 0.65, 0.85)
		"excitement":
			chars = ["⚡", "!", "★", "✦", "·"]
			color = Color(1.0, 0.8, 0.2, 0.8)

	particle.text = chars[randi() % chars.size()]

	# サイズは幸福度に応じる
	var size: int = int(10 + happiness * 14)
	particle.add_theme_font_size_override("font_size", size)
	particle.add_theme_color_override("font_color", color)

	# ペットの周囲にランダム配置
	var angle: float = randf() * TAU
	var radius: float = randf_range(25, 60)
	particle.position = Vector2(
		cos(angle) * radius,
		sin(angle) * radius - 30  # ペットの少し上寄り
	)
	particle.z_index = 8
	add_child(particle)
	_sparkle_pool.append(particle)

	# アニメーション: 浮遊 + フェードアウト + 回転
	var duration: float = randf_range(0.8, 1.5)
	var float_y: float = particle.position.y - randf_range(40, 80)
	var sway_x: float = particle.position.x + randf_range(-25, 25)

	particle.scale = Vector2(0.3, 0.3)
	particle.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	# フェードイン
	tween.tween_property(particle, "modulate:a", 1.0, 0.15)
	# スケールアップ
	tween.tween_property(particle, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT)
	# 浮遊
	tween.tween_property(particle, "position:y", float_y, duration).set_ease(Tween.EASE_OUT)
	tween.tween_property(particle, "position:x", sway_x, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# フェードアウト
	tween.tween_property(particle, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)
	# 回転（スパークル感）
	tween.tween_property(particle, "rotation", randf_range(-0.5, 0.5), duration)
	tween.chain().tween_callback(particle.queue_free)


# ========================================================
# 進化段階ビジュアル（体色・体形の変化）
# ========================================================

func _apply_evolution_stage_visuals(_delta: float) -> void:
	if not pet_entity or not body_sprite:
		return

	var stage: int = pet_entity.evolution_stage
	if stage == _current_evolution_stage:
		return

	_current_evolution_stage = stage

	# パレット適用 — ステージごとの基調色をベーストーンとして保持
	var palette: Dictionary = STAGE_PALETTES.get(stage, STAGE_PALETTES[1])
	_stage_tint = palette["base"] as Color

	# 体形パラメータ適用
	var body_params: Dictionary = STAGE_BODY_PARAMS.get(stage, STAGE_BODY_PARAMS[3])
	var target_scale: Vector2 = body_params["scale"] as Vector2
	body_sprite.scale = target_scale

	# ステージ進化時のオーバーレイテクスチャを生成・適用
	if effect_sprite:
		effect_sprite.texture = _get_stage_overlay_texture(stage)
		effect_sprite.modulate = Color(palette["accent"].r, palette["accent"].g, palette["accent"].b, 0.25)
		effect_sprite.visible = stage >= 3  # Youth以降でオーバーレイ表示
		effect_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _get_stage_overlay_texture(stage: int) -> ImageTexture:
	## 進化段階ごとのプロシージャルオーバーレイを生成（Image-based）
	if _stage_overlay_cache.has(stage):
		return _stage_overlay_cache[stage]

	var size: int = 16 + stage * 4  # ステージに応じてサイズ増加
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var palette: Dictionary = STAGE_PALETTES.get(stage, STAGE_PALETTES[1])
	var accent: Color = palette["accent"] as Color
	var outline_color: Color = palette["outline"] as Color
	var center: Vector2 = Vector2(size / 2.0, size / 2.0)

	match stage:
		0, 1:
			# Egg/Blob — シンプルな円形グロー
			_draw_radial_glow(image, center, size / 2.0, accent)
		2:
			# Infant — 小さなドットパターン
			_draw_dot_pattern(image, size, accent, 3)
		3:
			# Youth — 角張ったクレストマーク
			_draw_crest_pattern(image, size, accent, outline_color)
		4:
			# Adult — 力強い放射パターン
			_draw_radial_lines(image, center, size, accent, outline_color, 8)
		5:
			# Elder — 複合オーラパターン
			_draw_radial_glow(image, center, size / 2.0, accent)
			_draw_radial_lines(image, center, size, accent, outline_color, 12)

	var texture: ImageTexture = ImageTexture.create_from_image(image)
	_stage_overlay_cache[stage] = texture
	return texture


func _draw_radial_glow(image: Image, center: Vector2, radius: float, color: Color) -> void:
	## 放射状グラデーションを描画
	var w: int = image.get_width()
	var h: int = image.get_height()
	for x: int in range(w):
		for y: int in range(h):
			var dist: float = Vector2(x, y).distance_to(center) / radius
			if dist <= 1.0:
				var alpha: float = (1.0 - dist * dist) * 0.4
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))


func _draw_dot_pattern(image: Image, size: int, color: Color, spacing: int) -> void:
	## ドットパターンを描画
	for x: int in range(0, size, spacing):
		for y: int in range(0, size, spacing):
			if x < size and y < size:
				image.set_pixel(x, y, Color(color.r, color.g, color.b, 0.3))


func _draw_crest_pattern(image: Image, size: int, accent: Color, outline: Color) -> void:
	## クレスト（紋章）風パターンを描画
	var mid: int = size / 2
	for i: int in range(size):
		# 縦線
		if i < size:
			image.set_pixel(mid, i, Color(outline.r, outline.g, outline.b, 0.5))
		# 横線
		if i < size:
			image.set_pixel(i, mid, Color(outline.r, outline.g, outline.b, 0.5))
		# 斜めアクセント
		if i < size and i < size:
			image.set_pixel(i, i, Color(accent.r, accent.g, accent.b, 0.3))
		var mirror: int = size - 1 - i
		if mirror >= 0 and mirror < size and i < size:
			image.set_pixel(i, mirror, Color(accent.r, accent.g, accent.b, 0.3))


func _draw_radial_lines(image: Image, center: Vector2, size: int, accent: Color, outline: Color, num_lines: int) -> void:
	## 放射線パターンを描画
	var radius: float = size / 2.0
	for line_idx: int in range(num_lines):
		var angle: float = (float(line_idx) / float(num_lines)) * TAU
		for step: int in range(int(radius)):
			var px: int = int(center.x + cos(angle) * step)
			var py: int = int(center.y + sin(angle) * step)
			if px >= 0 and px < size and py >= 0 and py < size:
				var t: float = float(step) / radius
				var c: Color = accent.lerp(outline, t)
				image.set_pixel(px, py, Color(c.r, c.g, c.b, 0.35 * (1.0 - t)))


# ========================================================
# ユーティリティ
# ========================================================

func _create_shadow_texture() -> ImageTexture:
	var size: int = 32
	var image: Image = Image.create(size, int(size * 0.3), false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size / 2.0, size * 0.15)
	for x: int in range(size):
		for y: int in range(int(size * 0.3)):
			var nx: float = (float(x) - center.x) / (size / 2.0)
			var ny: float = (float(y) - center.y) / (size * 0.15)
			var dist_sq: float = nx * nx + ny * ny
			if dist_sq <= 1.0:
				var alpha: float = (1.0 - dist_sq) * 0.3
				image.set_pixel(x, y, Color(0, 0, 0, alpha))
	return ImageTexture.create_from_image(image)
