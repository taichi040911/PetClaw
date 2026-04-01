## EmotionSystem — 感情の計算・減衰・性格との相互作用を管理
class_name EmotionSystem
extends Node

signal emotion_spike(pet_id: int, emotion: String, intensity: float)
signal emotional_state_changed(pet_id: int, dominant_emotion: String)

# 感情の自然減衰率（毎秒）
const DECAY_RATES: Dictionary = {
	"joy": 0.005,
	"fear": 0.008,
	"excitement": 0.01,
	"sadness": 0.003,      # 悲しみは長く残る
	"love": 0.002,         # 愛は最も持続する
}

# 感情強度がこの値を超えると「スパイク」イベント発火
const SPIKE_THRESHOLD: float = 0.7

var tracked_pets: Array[PetEntity] = []


func register_pet(pet: PetEntity) -> void:
	if pet not in tracked_pets:
		tracked_pets.append(pet)


func unregister_pet(pet: PetEntity) -> void:
	tracked_pets.erase(pet)


func _process(delta: float) -> void:
	for pet in tracked_pets:
		if not pet.is_alive:
			continue
		_decay_emotions(pet, delta)
		_apply_personality_bias(pet, delta)
		_check_dominant_emotion(pet)


# === 感情の自然減衰 ===
func _decay_emotions(pet: PetEntity, delta: float) -> void:
	for emotion_name in pet.emotions:
		var rate: float = DECAY_RATES.get(emotion_name, 0.005)
		var current: float = pet.emotions[emotion_name]
		if current > 0.0:
			pet.emotions[emotion_name] = maxf(0.0, current - rate * delta)


# === 性格バイアス（性格が感情の基底値に影響） ===
func _apply_personality_bias(pet: PetEntity, delta: float) -> void:
	# 勇敢 → fearを減少させやすい
	if pet.personality["brave"] > 0.6:
		var fear_reduction := (pet.personality["brave"] - 0.6) * 0.002 * delta
		pet.emotions["fear"] = maxf(0.0, pet.emotions["fear"] - fear_reduction)

	# 好奇心 → excitementを維持しやすい
	if pet.personality["curious"] > 0.6:
		var excitement_floor := (pet.personality["curious"] - 0.6) * 0.1
		pet.emotions["excitement"] = maxf(excitement_floor, pet.emotions["excitement"])

	# 愛情深い → loveの減衰が遅い
	if pet.personality["affectionate"] > 0.6:
		var love_preservation := (pet.personality["affectionate"] - 0.6) * 0.5
		# love減衰率を実質的に下げる（すでに減衰済みなので微加算で補正）
		pet.emotions["love"] = minf(1.0, pet.emotions["love"] + love_preservation * 0.001 * delta)


# === 支配的感情の判定 ===
func _check_dominant_emotion(pet: PetEntity) -> void:
	var max_emotion: String = "neutral"
	var max_intensity: float = 0.15  # この閾値以下はneutral
	for emotion_name in pet.emotions:
		if pet.emotions[emotion_name] > max_intensity:
			max_intensity = pet.emotions[emotion_name]
			max_emotion = emotion_name
	# 変化があればシグナル
	emotional_state_changed.emit(pet.pet_id, max_emotion)


# === 外部からの感情刺激 ===
func stimulate(pet: PetEntity, emotion: String, intensity: float, source: String = "") -> void:
	## ペットに感情刺激を与える
	## source: "care_feed", "a2a_conversation", "environment", "death_event" etc.
	var personality_modifier := _get_personality_modifier(pet, emotion)
	var final_intensity := intensity * personality_modifier

	pet.blend_emotion(emotion, final_intensity)

	# スパイクチェック
	if pet.emotions[emotion] >= SPIKE_THRESHOLD:
		emotion_spike.emit(pet.pet_id, emotion, pet.emotions[emotion])

	# 記憶に記録（強い感情のみ）
	if final_intensity > 0.3:
		pet.add_memory({
			"type": "emotion_event",
			"emotion": emotion,
			"intensity": final_intensity,
			"source": source,
		})

	# 想起による感情再活性化（BiologicalMemorySystem連携）
	if final_intensity > 0.5 and GameManager.instance and GameManager.instance.biological_memory:
		var query := {"emotion_tag": emotion, "context_tags": [source]}
		var recalled := GameManager.instance.biological_memory.retrieve_memories(
			pet.pet_id, query, pet.personality, 1
		)
		for mem in recalled:
			# 過去の関連記憶が感情を微増幅（アミグダラ-海馬フィードバック）
			var echo_boost: float = mem["emotion_intensity"] * 0.1
			pet.blend_emotion(mem["emotion_tag"], echo_boost)


func _get_personality_modifier(pet: PetEntity, emotion: String) -> float:
	## 性格による感情感受性の調整
	match emotion:
		"fear":
			return 1.0 - pet.personality["brave"] * 0.4  # 勇敢→恐怖を感じにくい
		"excitement":
			return 0.7 + pet.personality["curious"] * 0.6  # 好奇心→興奮しやすい
		"joy":
			return 0.8 + pet.personality["playful"] * 0.4  # 遊び好き→喜びやすい
		"love":
			return 0.7 + pet.personality["affectionate"] * 0.6  # 愛情深い→愛を感じやすい
		"sadness":
			return 0.8 + pet.personality["affectionate"] * 0.3  # 愛情深い→悲しみも深い
		_:
			return 1.0


# === 感情のHSV色取得（VisualFX連携用） ===
func get_emotion_color(pet: PetEntity) -> Color:
	## 支配的感情に基づくHSVカラーを返す
	var dominant: String = "neutral"
	var max_val: float = 0.0
	for emotion in pet.emotions:
		if pet.emotions[emotion] > max_val:
			max_val = pet.emotions[emotion]
			dominant = emotion

	match dominant:
		"joy": return Color.from_hsv(0.15, 0.7, 0.9)         # 暖かい黄色
		"fear": return Color.from_hsv(0.75, 0.6, 0.4)        # 暗い紫
		"excitement": return Color.from_hsv(0.08, 0.8, 1.0)  # 鮮やかなオレンジ
		"sadness": return Color.from_hsv(0.6, 0.5, 0.5)      # 落ち着いた青
		"love": return Color.from_hsv(0.95, 0.6, 0.9)        # ピンク
		_: return Color.from_hsv(0.0, 0.0, 0.7)              # ニュートラルグレー
