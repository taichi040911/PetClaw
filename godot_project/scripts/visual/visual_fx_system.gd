## VisualFXSystem — 粒子エフェクト・HSV色計算・アニメーション統合管理
## 全システムからのビジュアルリクエストを受けて画面に反映する
class_name VisualFXSystem
extends Node

signal fx_started(fx_type: String, pet_id: int)
signal fx_completed(fx_type: String, pet_id: int)

# === 粒子プリセット ===
const PARTICLE_PRESETS: Dictionary = {
	"warning": {
		"lifetime": 1.5,
		"speed_min": 20.0,
		"speed_max": 50.0,
		"gravity": Vector2(0, -10),
		"scale_min": 0.3,
		"scale_max": 0.6,
	},
	"death": {
		"lifetime": 3.0,
		"speed_min": 5.0,
		"speed_max": 15.0,
		"gravity": Vector2(0, -5),
		"scale_min": 0.2,
		"scale_max": 0.8,
	},
	"revival": {
		"lifetime": 2.0,
		"speed_min": 30.0,
		"speed_max": 80.0,
		"gravity": Vector2(0, -30),
		"scale_min": 0.4,
		"scale_max": 1.0,
	},
	"evolution": {
		"lifetime": 4.0,
		"speed_min": 40.0,
		"speed_max": 120.0,
		"gravity": Vector2(0, -50),
		"scale_min": 0.3,
		"scale_max": 1.2,
	},
	"breeding": {
		"lifetime": 3.0,
		"speed_min": 20.0,
		"speed_max": 60.0,
		"gravity": Vector2(0, -20),
		"scale_min": 0.5,
		"scale_max": 1.0,
	},
	"care": {
		"lifetime": 1.0,
		"speed_min": 30.0,
		"speed_max": 70.0,
		"gravity": Vector2(0, -40),
		"scale_min": 0.3,
		"scale_max": 0.7,
	},
	"language_evolution": {
		"lifetime": 2.5,
		"speed_min": 15.0,
		"speed_max": 45.0,
		"gravity": Vector2(0, -15),
		"scale_min": 0.2,
		"scale_max": 0.5,
	},
}

# === 粒子プール ===
var particle_pool: Array[GPUParticles2D] = []
const POOL_SIZE: int = 10
var active_effects: Dictionary = {}  # effect_id → GPUParticles2D


func _ready() -> void:
	_initialize_particle_pool()

	# 言語進化イベントをリッスン
	if GameManager.language_evolution:
		GameManager.language_evolution.word_order_changed.connect(_on_word_order_changed)
		GameManager.language_evolution.suffix_created.connect(_on_suffix_created)
		GameManager.language_evolution.grammar_milestone.connect(_on_grammar_milestone)


func _initialize_particle_pool() -> void:
	for i in POOL_SIZE:
		var particles := GPUParticles2D.new()
		particles.emitting = false
		particles.one_shot = true
		particles.visible = false
		add_child(particles)
		particle_pool.append(particles)


# === メインエフェクト再生 ===
func play_effect(effect_type: String, params: Dictionary) -> void:
	var particles := _get_available_particles()
	if not particles:
		return

	var preset: Dictionary = PARTICLE_PRESETS.get(effect_type, PARTICLE_PRESETS["care"])
	var color: Color = params.get("color", Color.WHITE)
	var amount: int = params.get("particle_amount", 50)
	var duration: float = params.get("duration", preset["lifetime"])
	var pet_id: int = params.get("pet_id", -1)

	# 粒子パラメータ設定
	_configure_particles(particles, preset, color, amount)

	# 位置設定（ペットの位置）
	if pet_id >= 0:
		var pet := GameManager.get_pet_by_id(pet_id)
		if pet:
			particles.global_position = pet.global_position

	# 再生
	particles.visible = true
	particles.emitting = true
	fx_started.emit(effect_type, pet_id)

	# 自動終了
	var effect_id := "%s_%d_%d" % [effect_type, pet_id, Time.get_ticks_msec()]
	active_effects[effect_id] = particles

	await get_tree().create_timer(duration).timeout
	particles.emitting = false
	particles.visible = false
	active_effects.erase(effect_id)
	fx_completed.emit(effect_type, pet_id)


func _get_available_particles() -> GPUParticles2D:
	for particles in particle_pool:
		if not particles.emitting:
			return particles
	# プールが足りなければ新しく作る
	var new_particles := GPUParticles2D.new()
	new_particles.one_shot = true
	add_child(new_particles)
	particle_pool.append(new_particles)
	return new_particles


func _configure_particles(
	particles: GPUParticles2D, preset: Dictionary,
	color: Color, amount: int
) -> void:
	particles.amount = amount
	particles.lifetime = preset["lifetime"]
	particles.modulate = color

	# ProcessMaterialの設定（既存があれば再利用）
	var material: ParticleProcessMaterial
	if particles.process_material is ParticleProcessMaterial:
		material = particles.process_material
	else:
		material = ParticleProcessMaterial.new()
		particles.process_material = material

	material.initial_velocity_min = preset["speed_min"]
	material.initial_velocity_max = preset["speed_max"]
	material.gravity = Vector3(preset["gravity"].x, preset["gravity"].y, 0)
	material.scale_min = preset["scale_min"]
	material.scale_max = preset["scale_max"]
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 10.0
	material.color = color


# === HSV色計算ユーティリティ ===
static func blend_colors(color1: Color, color2: Color, weight: float = 0.5) -> Color:
	return color1.lerp(color2, weight)


static func emotion_to_hsv(emotion: String, intensity: float) -> Color:
	## 感情名と強度からHSVカラーを計算
	var hue := 0.0
	var saturation := 0.5 + intensity * 0.3
	var value := 0.6 + intensity * 0.3

	match emotion:
		"joy": hue = 0.15
		"fear": hue = 0.75
		"excitement": hue = 0.08
		"sadness": hue = 0.6
		"love": hue = 0.95
		_: saturation = 0.0  # neutral = gray

	return Color.from_hsv(hue, saturation, value)


static func environment_tint(base_color: Color, environment: String) -> Color:
	## 環境に基づいて色合いを調整
	var tint: Color
	match environment:
		"forest": tint = Color(0.8, 1.0, 0.8)
		"sea": tint = Color(0.8, 0.9, 1.0)
		"ruins": tint = Color(0.9, 0.8, 1.0)
		"city": tint = Color(1.0, 0.95, 0.8)
		_: tint = Color.WHITE
	return base_color * tint


# === 言語進化ビジュアル ===
func _on_word_order_changed(old_order: String, new_order: String, _reason: String) -> void:
	# 語順変更を画面全体のフラッシュで表現
	play_effect("language_evolution", {
		"color": Color(0.9, 0.8, 1.0),  # 知的な紫系
		"particle_amount": 100,
		"duration": 3.0,
	})


func _on_suffix_created(suffix: String, context: String, _reason: String) -> void:
	# 新しい接尾辞は小さなキラキラで表現
	play_effect("language_evolution", {
		"color": Color(1.0, 0.95, 0.6),  # 金色
		"particle_amount": 40,
		"duration": 1.5,
	})


func _on_grammar_milestone(milestone: String, _details: Dictionary) -> void:
	# マイルストーンは豪華なエフェクト
	play_effect("language_evolution", {
		"color": Color(1.0, 0.85, 0.3),
		"particle_amount": 200,
		"duration": 4.0,
	})
