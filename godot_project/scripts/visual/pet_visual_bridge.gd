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

# === Color Mapping (感情→ペットの色味変化) ===
const EMOTION_COLORS: Dictionary = {
	"joy": Color(1.0, 0.95, 0.4),       # 明るい黄色
	"love": Color(1.0, 0.6, 0.7),       # ピンク
	"excitement": Color(1.0, 0.8, 0.2),  # オレンジ黄
	"sadness": Color(0.6, 0.7, 0.9),    # 薄い青
	"fear": Color(0.7, 0.6, 0.8),       # 薄い紫
	"neutral": Color(1.0, 1.0, 1.0),    # 白（通常）
}


func _ready() -> void:
	_original_position = position

	# ExpressionSystem のシグナルに接続
	await get_tree().process_frame
	if GameManager.instance and GameManager.instance.visual_fx:
		# ExpressionSystem は GameManager 経由ではなく独立
		pass

	# 親ノードから PetEntity を探す
	var parent: Node = get_parent()
	if parent is PetEntity:
		pet_entity = parent
		pet_id = pet_entity.pet_id
		pet_entity.emotion_changed.connect(_on_emotion_changed)


func _process(delta: float) -> void:
	if not pet_entity or not pet_entity.is_alive:
		return

	_idle_time += delta
	_update_idle_animation(delta)
	_update_emotion_visuals()


func _update_idle_animation(delta: float) -> void:
	# ゆっくりとした上下バウンス（呼吸のような動き）
	_bounce_offset = sin(_idle_time * 1.5) * 3.0
	position = _original_position + Vector2(0, _bounce_offset)

	# 好奇心が高い場合、左右にわずかに揺れる
	if pet_entity and pet_entity.personality.get("curious", 0.5) > 0.7:
		var sway: float = sin(_idle_time * 0.8) * 2.0
		position.x = _original_position.x + sway


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

	# ボディの色味を感情で微調整（モジュレーション）
	var target_color: Color = EMOTION_COLORS.get(dominant_emotion, Color.WHITE)
	if body_sprite:
		body_sprite.modulate = body_sprite.modulate.lerp(target_color, 0.05)

	# パーティクルの制御
	if emotion_particles:
		if max_intensity > 0.6:
			emotion_particles.emitting = true
		else:
			emotion_particles.emitting = false


func _on_emotion_changed(emotion: String, intensity: float) -> void:
	# 強い感情変化時のリアクション
	if intensity > 0.5:
		_play_emotion_reaction(emotion, intensity)


func _play_emotion_reaction(emotion: String, intensity: float) -> void:
	# 簡易アニメーション: ジャンプ反応
	var jump_height: float = intensity * 10.0

	var tween: Tween = create_tween()
	tween.tween_property(self, "position:y",
		_original_position.y - jump_height, 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y",
		_original_position.y, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)

	# エフェクトスプライトの表示
	if effect_sprite:
		effect_sprite.visible = true
		var effect_tween: Tween = create_tween()
		effect_tween.tween_property(effect_sprite, "modulate:a", 1.0, 0.1)
		effect_tween.tween_interval(0.8)
		effect_tween.tween_property(effect_sprite, "modulate:a", 0.0, 0.3)
		effect_tween.tween_callback(func() -> void: effect_sprite.visible = false)
