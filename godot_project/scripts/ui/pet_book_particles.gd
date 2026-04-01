## PetBookParticles — PetBook粒子エフェクトシステム
## 環境・感情・イベントに連動する背景＋投稿粒子を管理
## GPUParticles2Dをプールして動的に生成・再利用
class_name PetBookParticles
extends Node2D

# === 環境別粒子設定 ===
const PARTICLE_CONFIGS: Dictionary = {
	"forest": {
		"color": Color(0.2, 0.8, 0.3, 0.15),
		"amount": 30,
		"lifetime": 4.0,
		"velocity_min": Vector2(-10, -20),
		"velocity_max": Vector2(10, -5),
		"scale_min": 0.3,
		"scale_max": 0.7,
	},
	"ocean": {
		"color": Color(0.2, 0.4, 0.9, 0.15),
		"amount": 25,
		"lifetime": 5.0,
		"velocity_min": Vector2(-15, -10),
		"velocity_max": Vector2(15, 10),
		"scale_min": 0.2,
		"scale_max": 0.5,
	},
	"mountain": {
		"color": Color(0.6, 0.6, 0.7, 0.12),
		"amount": 15,
		"lifetime": 6.0,
		"velocity_min": Vector2(-5, -15),
		"velocity_max": Vector2(5, -3),
		"scale_min": 0.4,
		"scale_max": 0.8,
	},
	"desert": {
		"color": Color(0.9, 0.7, 0.3, 0.10),
		"amount": 20,
		"lifetime": 3.5,
		"velocity_min": Vector2(5, -5),
		"velocity_max": Vector2(25, 5),
		"scale_min": 0.2,
		"scale_max": 0.4,
	},
	"cave": {
		"color": Color(0.3, 0.2, 0.5, 0.10),
		"amount": 10,
		"lifetime": 7.0,
		"velocity_min": Vector2(-3, -8),
		"velocity_max": Vector2(3, -2),
		"scale_min": 0.3,
		"scale_max": 0.5,
	},
	"meadow": {
		"color": Color(0.4, 0.9, 0.4, 0.12),
		"amount": 35,
		"lifetime": 3.0,
		"velocity_min": Vector2(-8, -12),
		"velocity_max": Vector2(8, -3),
		"scale_min": 0.2,
		"scale_max": 0.5,
	},
}

# === イベント粒子設定 ===
const EVENT_CONFIGS: Dictionary = {
	"normal_post": {
		"amount": 8,
		"lifetime": 1.5,
		"spread": 60.0,
		"velocity": 30.0,
		"alpha": 0.3,
	},
	"rebel_post": {
		"amount": 15,
		"lifetime": 2.0,
		"spread": 120.0,
		"velocity": 50.0,
		"alpha": 0.5,
	},
	"memorial_post": {
		"amount": 12,
		"lifetime": 3.0,
		"spread": 40.0,
		"velocity": 15.0,
		"alpha": 0.4,
	},
	"birth_event": {
		"amount": 20,
		"lifetime": 2.5,
		"spread": 180.0,
		"velocity": 60.0,
		"alpha": 0.6,
	},
	"evolution_event": {
		"amount": 25,
		"lifetime": 2.0,
		"spread": 360.0,
		"velocity": 80.0,
		"alpha": 0.7,
	},
	"new_word": {
		"amount": 10,
		"lifetime": 1.0,
		"spread": 90.0,
		"velocity": 40.0,
		"alpha": 0.5,
	},
	"death_event": {
		"amount": 8,
		"lifetime": 4.0,
		"spread": 30.0,
		"velocity": 10.0,
		"alpha": 0.3,
	},
}

# === 状態 ===
var _current_environment: String = "forest"
var _current_theme: PetBookSubMoltTheme = null
var _ambient_particles: GPUParticles2D
var _active_event_particles: Array[GPUParticles2D] = []
var _particle_pool: Array[GPUParticles2D] = []
const MAX_EVENT_PARTICLES: int = 10
const POOL_SIZE: int = 15


func _ready() -> void:
	_create_ambient_particles()
	_create_particle_pool()


# === 背景環境粒子 ===
func _create_ambient_particles() -> void:
	_ambient_particles = GPUParticles2D.new()
	_ambient_particles.emitting = true
	_ambient_particles.one_shot = false
	_ambient_particles.z_index = -1
	add_child(_ambient_particles)
	_apply_ambient_config("forest")


func set_environment(env: String) -> void:
	## 環境変更 → 背景粒子をクロスフェード
	if env == _current_environment:
		return

	_current_environment = env
	var tween := create_tween()
	tween.tween_property(_ambient_particles, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_apply_ambient_config.bind(env))
	tween.tween_property(_ambient_particles, "modulate:a", 1.0, 0.5)


func _apply_ambient_config(env: String) -> void:
	var config: Dictionary = PARTICLE_CONFIGS.get(env, PARTICLE_CONFIGS["forest"])

	# ParticleProcessMaterial を使用
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = config["velocity_min"].length()
	mat.initial_velocity_max = config["velocity_max"].length()
	mat.gravity = Vector3(0, -2, 0)
	mat.scale_min = config["scale_min"]
	mat.scale_max = config["scale_max"]
	mat.color = config["color"]

	_ambient_particles.process_material = mat
	_ambient_particles.amount = config["amount"]
	_ambient_particles.lifetime = config["lifetime"]

	# 放出範囲をビューポート幅に合わせる
	var viewport_size := get_viewport_rect().size
	_ambient_particles.position = Vector2(viewport_size.x / 2.0, viewport_size.y)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(viewport_size.x / 2.0, 10, 0)


# === イベント粒子 ===
func spawn_post_particles(post_type: String, emotion_color: Color, spawn_position: Vector2) -> void:
	## 投稿イベントに応じた粒子をスポーン
	var config: Dictionary = EVENT_CONFIGS.get(post_type, EVENT_CONFIGS["normal_post"])
	var particles := _get_from_pool()
	if not particles:
		return

	particles.position = spawn_position
	particles.one_shot = true
	particles.emitting = false

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = config["spread"]
	mat.initial_velocity_min = config["velocity"] * 0.5
	mat.initial_velocity_max = config["velocity"]
	mat.gravity = Vector3(0, 5, 0)
	mat.scale_min = 0.3
	mat.scale_max = 0.8

	# 色設定（感情色 × alpha）
	var particle_color := emotion_color
	particle_color.a = config["alpha"]
	mat.color = particle_color

	# 死亡イベントは下方向に沈降
	if post_type == "death_event":
		mat.direction = Vector3(0, 1, 0)
		mat.gravity = Vector3(0, 20, 0)

	# 進化イベントは全方向に爆発
	if post_type == "evolution_event":
		mat.direction = Vector3(0, 0, 0)
		mat.spread = 180.0
		mat.gravity = Vector3.ZERO

	particles.process_material = mat
	particles.amount = config["amount"]
	particles.lifetime = config["lifetime"]
	particles.emitting = true

	_active_event_particles.append(particles)

	# 寿命後にプールに返却
	var timer := get_tree().create_timer(config["lifetime"] + 0.5)
	timer.timeout.connect(_return_to_pool.bind(particles))


func spawn_new_word_particles(word_position: Vector2) -> void:
	## 新語誕生の特別エフェクト
	spawn_post_particles("new_word", Color(NEW_WORD_COLOR), word_position)


# === 粒子プール管理 ===
func _create_particle_pool() -> void:
	for i in range(POOL_SIZE):
		var p := GPUParticles2D.new()
		p.emitting = false
		p.visible = false
		add_child(p)
		_particle_pool.append(p)


func _get_from_pool() -> GPUParticles2D:
	if _particle_pool.is_empty():
		# プール枯渇時は最も古いアクティブ粒子を再利用
		if _active_event_particles.is_empty():
			return null
		var oldest := _active_event_particles[0]
		_active_event_particles.remove_at(0)
		oldest.emitting = false
		return oldest

	var p := _particle_pool.pop_back()
	p.visible = true
	return p


func _return_to_pool(particles: GPUParticles2D) -> void:
	particles.emitting = false
	particles.visible = false
	_active_event_particles.erase(particles)
	if _particle_pool.size() < POOL_SIZE:
		_particle_pool.append(particles)


# === 新語誕生用の色定数 ===
const NEW_WORD_COLOR: String = "#33FF99"


# === SubMoltテーマ連動（v2追加） ===
func apply_sub_molt_theme(theme: PetBookSubMoltTheme) -> void:
	## SubMoltテーマに基づいて環境粒子を切り替え
	_current_theme = theme

	var tween := create_tween()
	tween.tween_property(_ambient_particles, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_apply_theme_ambient.bind(theme))
	tween.tween_property(_ambient_particles, "modulate:a", 1.0, 0.3)


func _apply_theme_ambient(theme: PetBookSubMoltTheme) -> void:
	## テーマから環境粒子の設定を適用
	var mat := ParticleProcessMaterial.new()
	mat.color = theme.env_particle_color
	mat.scale_min = theme.env_particle_scale_min
	mat.scale_max = theme.env_particle_scale_max

	# 重力方向（上昇する魂 vs 落ちる葉 etc）
	mat.gravity = Vector3(theme.env_particle_gravity.x, -theme.env_particle_gravity.y, 0)
	mat.direction = Vector3(0, -1, 0) if theme.env_particle_gravity.y > 0 else Vector3(0, 1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 5.0
	mat.initial_velocity_max = 15.0

	# 放出範囲
	var viewport_size := get_viewport_rect().size
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(viewport_size.x / 2.0, 10, 0)

	_ambient_particles.process_material = mat
	_ambient_particles.amount = theme.env_particle_amount
	_ambient_particles.lifetime = theme.env_particle_lifetime
	_ambient_particles.position = Vector2(viewport_size.x / 2.0, viewport_size.y)


func spawn_sub_molt_event(event_type: String, spawn_position: Vector2) -> void:
	## SubMoltテーマ固有のイベント粒子をスポーン
	if not _current_theme:
		return
	var configs: Dictionary = _current_theme.event_particle_configs
	if not configs.has(event_type):
		return

	var config: Dictionary = configs[event_type]
	var particles := _get_from_pool()
	if not particles:
		return

	particles.position = spawn_position
	particles.one_shot = config.get("one_shot", false)
	particles.emitting = false

	var mat := ParticleProcessMaterial.new()
	mat.color = config.get("color", Color.WHITE)
	mat.spread = 90.0
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 50.0
	mat.scale_min = 0.3
	mat.scale_max = 0.7

	var grav: Vector2 = config.get("gravity", Vector2(0, 5))
	mat.gravity = Vector3(grav.x, -grav.y, 0)

	if config.has("explosiveness"):
		particles.explosiveness = config["explosiveness"]
	else:
		particles.explosiveness = 0.0

	var viewport_size := get_viewport_rect().size
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT

	particles.process_material = mat
	particles.amount = config.get("amount", 10)
	particles.lifetime = config.get("lifetime", 1.5)
	particles.emitting = true

	_active_event_particles.append(particles)

	var timer := get_tree().create_timer(config.get("lifetime", 1.5) + 0.5)
	timer.timeout.connect(_return_to_pool.bind(particles))


# === SubMolt詳細粒子設定（v3追加） ===
## 各SubMoltテーマごとの細かなParticleProcessMaterialパラメータ
const SUB_MOLT_PARTICLE_DETAILS: Dictionary = {
	"forest_whispers": {
		"ambient": {
			"direction": Vector3(0.3, -1, 0),
			"spread": 30.0,
			"initial_velocity_min": 5.0,
			"initial_velocity_max": 12.0,
			"gravity": Vector3(2, -8, 0),
			"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
			"emission_box_extents": Vector3(200, 10, 0),
			"color_ramp": [Color(0.2, 0.8, 0.3, 1.0), Color(0.8, 0.9, 0.2, 0.0)],
			"color_ramp_offsets": [0.0, 1.0],
			"turbulence_enabled": true,
			"turbulence_noise_strength": 2.0,
			"turbulence_noise_speed": 0.5,
		},
		"event_new_post": {
			"spread": 60.0,
			"explosiveness": 0.3,
			"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
			"emission_sphere_radius": 15.0,
			"color": Color(0.2, 0.8, 0.3, 0.6),
		},
		"event_curiosity": {
			"spread": 90.0,
			"explosiveness": 0.5,
			"color": Color(0.4, 0.9, 0.4, 0.5),
			"scale_curve_enabled": true,
			"damping": 2.0,
		},
	},
	"afterlife_echoes": {
		"ambient": {
			"direction": Vector3(0, 1, 0),
			"spread": 20.0,
			"initial_velocity_min": 3.0,
			"initial_velocity_max": 8.0,
			"gravity": Vector3(0, 3, 0),
			"color_ramp": [Color(0.7, 0.3, 0.9, 1.0), Color(0.7, 0.3, 0.9, 0.0)],
			"color_ramp_offsets": [0.0, 1.0],
			"turbulence_enabled": true,
			"turbulence_noise_strength": 4.0,
			"turbulence_noise_speed": 0.2,
			"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
			"emission_box_extents": Vector3(200, 10, 0),
		},
		"event_death": {
			"spread": 30.0,
			"gravity": Vector3(0, -20, 0),
			"explosiveness": 0.0,
			"color": Color(0.4, 0.4, 0.4, 0.5),
			"initial_velocity_min": 10.0,
			"initial_velocity_max": 25.0,
		},
		"event_resurrection_burst": {
			"spread": 180.0,
			"explosiveness": 1.0,
			"gravity": Vector3(0, 40, 0),
			"color_ramp": [Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 0.8, 0.2, 0.0)],
			"color_ramp_offsets": [0.0, 1.0],
			"scale_min": 0.5,
			"scale_max": 1.5,
			"initial_velocity_min": 60.0,
			"initial_velocity_max": 100.0,
		},
	},
	"breeding_circle": {
		"ambient": {
			"direction": Vector3(0.2, -1, 0),
			"spread": 45.0,
			"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
			"emission_box_extents": Vector3(200, 10, 0),
			"color_ramp": [Color(1.0, 0.7, 0.85, 1.0), Color(1.0, 0.95, 0.9, 0.0)],
			"color_ramp_offsets": [0.0, 1.0],
			"gravity": Vector3(1.5, -6, 0),
			"turbulence_enabled": true,
			"turbulence_noise_strength": 3.0,
			"initial_velocity_min": 2.0,
			"initial_velocity_max": 8.0,
		},
		"event_birth": {
			"spread": 360.0,
			"explosiveness": 1.0,
			"initial_velocity_min": 40.0,
			"initial_velocity_max": 80.0,
			"gravity": Vector3.ZERO,
			"color_ramp": [Color(1.0, 0.85, 0.2, 1.0), Color(1.0, 0.9, 0.4, 0.0)],
			"color_ramp_offsets": [0.0, 1.0],
			"scale_curve_enabled": true,
		},
		"event_bloom_burst": {
			"spread": 180.0,
			"explosiveness": 0.85,
			"color": Color(1.0, 0.7, 0.85, 0.7),
			"damping": 5.0,
			"initial_velocity_min": 30.0,
			"initial_velocity_max": 60.0,
		},
	},
	"language_rebellion": {
		"ambient": {
			"direction": Vector3(0, 0, 0),
			"spread": 180.0,
			"initial_velocity_min": 1.0,
			"initial_velocity_max": 5.0,
			"gravity": Vector3.ZERO,
			"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
			"emission_sphere_radius": 300.0,
			"color_ramp": [Color(0.7, 0.3, 0.9, 1.0), Color(0.2, 0.8, 0.9, 1.0)],
			"color_ramp_offsets": [0.0, 0.5],
			"turbulence_enabled": true,
			"turbulence_noise_strength": 6.0,
			"turbulence_noise_speed": 1.5,
		},
		"event_rebellion_spark": {
			"spread": 120.0,
			"explosiveness": 0.9,
			"initial_velocity_min": 50.0,
			"initial_velocity_max": 80.0,
			"gravity": Vector3(0, 10, 0),
			"color": Color(1.0, 0.2, 0.2, 0.8),
		},
		"event_word_forge_flash": {
			"spread": 360.0,
			"explosiveness": 1.0,
			"initial_velocity_min": 60.0,
			"initial_velocity_max": 100.0,
			"color_ramp": [Color(1.0, 0.7, 0.2, 1.0), Color(1.0, 0.85, 0.2, 0.0)],
			"color_ramp_offsets": [0.0, 1.0],
			"lifetime": 0.8,
		},
	},
	"ecosystem_pulse": {
		"event_migration": {
			"direction": Vector3(1, 0, 0),
			"spread": 15.0,
			"initial_velocity_min": 20.0,
			"initial_velocity_max": 40.0,
			"gravity": Vector3(0, -2, 0),
			"color": Color(0.2, 0.8, 0.3, 0.6),
		},
		"event_disaster_warning": {
			"spread": 360.0,
			"explosiveness": 1.0,
			"initial_velocity_min": 80.0,
			"initial_velocity_max": 120.0,
			"color_ramp": [Color(1.0, 0.2, 0.2, 1.0), Color(1.0, 0.6, 0.2, 0.0)],
			"color_ramp_offsets": [0.0, 1.0],
			"scale_max": 1.2,
		},
	},
}


func _apply_sub_molt_ambient_detailed(theme_id: String) -> void:
	## SUB_MOLT_PARTICLE_DETAILSから詳細パラメータを適用
	if not SUB_MOLT_PARTICLE_DETAILS.has(theme_id):
		return

	var theme_config: Dictionary = SUB_MOLT_PARTICLE_DETAILS[theme_id]
	if not theme_config.has("ambient"):
		return

	var ambient_config: Dictionary = theme_config["ambient"]
	var mat := ParticleProcessMaterial.new()

	# 詳細パラメータを適用
	_apply_detailed_material(mat, ambient_config)

	# グラデーション設定
	if ambient_config.has("color_ramp"):
		var gradient := _create_color_ramp(
			ambient_config["color_ramp"],
			ambient_config.get("color_ramp_offsets", [])
		)
		mat.color_ramp = gradient

	_ambient_particles.process_material = mat
	_ambient_particles.amount = ambient_config.get("amount", 30)
	_ambient_particles.lifetime = ambient_config.get("lifetime", 4.0)

	var viewport_size := get_viewport_rect().size
	_ambient_particles.position = Vector2(viewport_size.x / 2.0, viewport_size.y)


func spawn_sub_molt_event_detailed(theme_id: String, event_type: String, spawn_position: Vector2) -> void:
	## 詳細パラメータを使ったSubMoltイベント粒子をスポーン
	if not SUB_MOLT_PARTICLE_DETAILS.has(theme_id):
		return

	var theme_config: Dictionary = SUB_MOLT_PARTICLE_DETAILS[theme_id]
	if not theme_config.has(event_type):
		return

	var event_config: Dictionary = theme_config[event_type]
	var particles := _get_from_pool()
	if not particles:
		return

	particles.position = spawn_position
	particles.one_shot = event_config.get("one_shot", true)
	particles.emitting = false

	var mat := ParticleProcessMaterial.new()

	# 詳細パラメータを適用
	_apply_detailed_material(mat, event_config)

	# グラデーション設定
	if event_config.has("color_ramp"):
		var gradient := _create_color_ramp(
			event_config["color_ramp"],
			event_config.get("color_ramp_offsets", [])
		)
		mat.color_ramp = gradient

	# 単一色が指定されていれば使用
	if event_config.has("color"):
		mat.color = event_config["color"]

	particles.process_material = mat
	particles.amount = event_config.get("amount", 15)
	particles.lifetime = event_config.get("lifetime", 1.5)

	# 爆発度設定
	if event_config.has("explosiveness"):
		particles.explosiveness = event_config["explosiveness"]

	# ダンピング設定
	if event_config.has("damping"):
		mat.damping = event_config["damping"]

	particles.emitting = true
	_active_event_particles.append(particles)

	var timer := get_tree().create_timer(particles.lifetime + 0.5)
	timer.timeout.connect(_return_to_pool.bind(particles))


func _create_color_ramp(colors: Array[Color], offsets: Array[float]) -> Gradient:
	## グラデーション生成ヘルパー
	var gradient := Gradient.new()

	# offsets が空の場合は均等に配置
	var actual_offsets: Array[float] = offsets
	if actual_offsets.is_empty() and not colors.is_empty():
		for i in range(colors.size()):
			actual_offsets.append(float(i) / float(colors.size() - 1) if colors.size() > 1 else 0.0)

	# グラデーント点を追加
	for i in range(colors.size()):
		var offset: float = actual_offsets[i] if i < actual_offsets.size() else float(i) / float(colors.size())
		gradient.add_point(offset, colors[i])

	return gradient


func _apply_detailed_material(mat: ParticleProcessMaterial, config: Dictionary) -> void:
	## 設定辞書からParticleProcessMaterialに詳細パラメータを適用するヘルパー

	# 方向・スプレッド
	if config.has("direction"):
		mat.direction = config["direction"]
	if config.has("spread"):
		mat.spread = config["spread"]

	# 初期速度
	if config.has("initial_velocity_min"):
		mat.initial_velocity_min = config["initial_velocity_min"]
	if config.has("initial_velocity_max"):
		mat.initial_velocity_max = config["initial_velocity_max"]

	# 重力
	if config.has("gravity"):
		mat.gravity = config["gravity"]

	# スケール
	if config.has("scale_min"):
		mat.scale_min = config["scale_min"]
	if config.has("scale_max"):
		mat.scale_max = config["scale_max"]

	# 放出形状
	if config.has("emission_shape"):
		mat.emission_shape = config["emission_shape"]

	if config.has("emission_box_extents"):
		mat.emission_box_extents = config["emission_box_extents"]

	if config.has("emission_sphere_radius"):
		mat.emission_sphere_radius = config["emission_sphere_radius"]

	# タービュレンス設定
	if config.has("turbulence_enabled"):
		mat.turbulence_enabled = config["turbulence_enabled"]
	if config.has("turbulence_noise_strength"):
		mat.turbulence_noise_strength = config["turbulence_noise_strength"]
	if config.has("turbulence_noise_speed"):
		mat.turbulence_noise_speed = config["turbulence_noise_speed"]

	# その他のパラメータ
	if config.has("color"):
		mat.color = config["color"]
	if config.has("damping"):
		mat.damping = config["damping"]
	if config.has("scale_curve_enabled"):
		# Note: scale_curve の完全な実装にはAnimationCurveが必要
		# ここではフラグのみ設定
		if config["scale_curve_enabled"]:
			var curve := AnimationCurve.new()
			curve.add_point(0.0, 0.3)
			curve.add_point(0.5, 1.0)
			curve.add_point(1.0, 0.5)
			mat.scale = 1.0
