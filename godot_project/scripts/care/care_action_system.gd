## CareActionSystem — プレイヤーの世話アクションを処理
## Feed/Clean/Play/Train/Medicine/Pet/Exploreの効果を計算し、全システムに伝播する
## AtoA会話トリガー + 生態系統合版
class_name CareActionSystem
extends Node

signal care_performed(pet_id: int, action: String, effectiveness: float)

# === アクション効果定義 ===
const ACTION_EFFECTS: Dictionary = {
	"feed": {
		"stats": {"hunger": 0.3, "energy": 0.1, "health": 0.05},
		"emotions": {"joy": 0.2, "love": 0.1},
		"personality": {},
		"affection_gain": 0.05,
	},
	"play": {
		"stats": {"hunger": -0.05, "energy": -0.15, "health": 0.02},
		"emotions": {"joy": 0.3, "excitement": 0.25},
		"personality": {"playful": 0.005, "curious": 0.003},
		"affection_gain": 0.08,
	},
	"train": {
		"stats": {"hunger": -0.1, "energy": -0.2, "health": 0.03},
		"emotions": {"excitement": 0.15},
		"personality": {"brave": 0.008, "calm": 0.003},
		"affection_gain": 0.06,
		"evolution_readiness_boost": 0.02,
	},
	"medicine": {
		"stats": {"health": 0.35, "hunger": -0.05},
		"emotions": {"fear": 0.1, "love": 0.15},  # 薬は少し怖いけど愛を感じる
		"personality": {},
		"affection_gain": 0.04,
	},
	"clean": {  # 掃除・お風呂
		"stats": {"health": 0.15, "energy": 0.05},
		"emotions": {"joy": 0.15, "love": 0.1},
		"personality": {"calm": 0.004},
		"affection_gain": 0.06,
		"illness_resistance_boost": 0.03,
	},
	"pet": {  # なでる
		"stats": {"energy": 0.05},
		"emotions": {"love": 0.25, "joy": 0.15},
		"personality": {"affectionate": 0.005},
		"affection_gain": 0.1,
	},
	"explore": {  # 探索させる
		"stats": {"hunger": -0.08, "energy": -0.12},
		"emotions": {"excitement": 0.3, "fear": 0.05},
		"personality": {"curious": 0.01, "brave": 0.005},
		"affection_gain": 0.03,
		"evolution_readiness_boost": 0.01,
	},
}


func perform_action(pet: PetEntity, action: String) -> float:
	if action not in ACTION_EFFECTS:
		push_warning("CareActionSystem: Unknown action '%s'" % action)
		return 0.0

	if not pet.is_alive:
		push_warning("CareActionSystem: Cannot perform action on dead pet")
		return 0.0

	var effects: Dictionary = ACTION_EFFECTS[action]
	var effectiveness := 1.0

	# 環境による効果修正
	effectiveness *= _get_environment_modifier(pet, action)

	# 性格による効果修正
	effectiveness *= _get_personality_modifier(pet, action)

	# ステータス適用
	for stat_name in effects.get("stats", {}):
		var delta: float = effects["stats"][stat_name] * effectiveness
		pet.stats.modify(stat_name, delta)

	# 感情適用
	for emotion in effects.get("emotions", {}):
		var intensity: float = effects["emotions"][emotion] * effectiveness
		GameManager.emotion_system.stimulate(pet, emotion, intensity, "care_%s" % action)

	# 性格進化
	for t_name in effects.get("personality", {}):
		pet.evolve_personality(t_name, effects["personality"][t_name] * effectiveness)

	# 愛着度
	var affection_gain: float = effects.get("affection_gain", 0.0) * effectiveness
	pet.stats.modify("affection", affection_gain)

	# 進化準備度
	var evo_boost: float = effects.get("evolution_readiness_boost", 0.0) * effectiveness
	if evo_boost > 0.0:
		pet.stats.modify("evolution_readiness", evo_boost)

	# 病気耐性ブースト（Clean等）
	var illness_boost: float = effects.get("illness_resistance_boost", 0.0) * effectiveness
	if illness_boost > 0.0:
		pet.stats.modify("disease_resistance", illness_boost)

	# 記憶に追加
	pet.add_memory({
		"type": "care_received",
		"action": action,
		"effectiveness": effectiveness,
	})

	care_performed.emit(pet.pet_id, action, effectiveness)

	# ビジュアルエフェクト
	_play_care_visuals(pet, action, effectiveness)

	# AtoA会話トリガー（60%の確率で世話後に会話発生）
	if randf() < 0.6:
		_trigger_care_a2a_conversation(pet, action)

	return effectiveness


func _get_environment_modifier(pet: PetEntity, action: String) -> float:
	var env := pet.current_environment
	match action:
		"feed":
			if env == "city": return 1.2    # 街は食べ物豊富
			if env == "ruins": return 0.8   # 廃墟は食料少なめ
			if env == "sea": return 1.1     # 海の幸
		"clean":
			if env == "sea": return 1.2     # 海水浴効果
			if env == "ruins": return 0.85  # 汚れやすい
		"play":
			if env == "forest": return 1.15  # 森は遊び場豊富
			if env == "sea": return 1.1
			if env == "city": return 1.1    # 社交遊び
		"train":
			if env == "ruins": return 1.2   # 廃墟はサバイバル訓練に最適
			if env == "sea": return 1.1     # 泳ぎ訓練
		"explore":
			if env == "ruins": return 1.3   # 探索の面白さ
			if env == "sea": return 1.2
		"medicine":
			if env == "forest": return 1.1  # 薬草が豊富
			if env == "ruins": return 0.9   # 衛生環境が悪い
	return 1.0


func _get_personality_modifier(pet: PetEntity, action: String) -> float:
	match action:
		"play":
			return 0.8 + pet.personality["playful"] * 0.4
		"train":
			return 0.8 + pet.personality["brave"] * 0.3
		"explore":
			return 0.7 + pet.personality["curious"] * 0.6
		"pet":
			return 0.8 + pet.personality["affectionate"] * 0.4
	return 1.0


func _play_care_visuals(pet: PetEntity, action: String, effectiveness: float) -> void:
	var emotion_color: Color = GameManager.emotion_system.get_emotion_color(pet)
	var fx_params := {
		"pet_id": pet.pet_id,
		"action": action,
		"color": emotion_color,
		"intensity": effectiveness,
		"particle_amount": int(50 * effectiveness),
	}

	match action:
		"feed":
			fx_params["fx_type"] = "sparkle_up"
		"clean":
			fx_params["fx_type"] = "shimmer_bubbles"
			fx_params["color"] = Color(0.7, 0.85, 1.0)  # 清潔感のある青白
		"play":
			fx_params["fx_type"] = "bounce_circles"
		"train":
			fx_params["fx_type"] = "power_burst"
		"medicine":
			fx_params["fx_type"] = "healing_wave"
		"pet":
			fx_params["fx_type"] = "heart_float"
		"explore":
			fx_params["fx_type"] = "trail_sparkle"

	GameManager.visual_fx.play_effect("care", fx_params)


# === AtoA会話トリガー（世話後の自然な会話） ===
func _trigger_care_a2a_conversation(pet: PetEntity, action: String) -> void:
	var all_pets := GameManager.get_all_pets()
	var other_pets: Array[PetEntity] = []
	for p in all_pets:
		if p.pet_id != pet.pet_id and p.is_alive:
			other_pets.append(p)

	if other_pets.is_empty():
		return

	# 最も愛着の高い相手を選択
	var partner: PetEntity = other_pets[0]
	var max_love := 0.0
	for p in other_pets:
		if p.emotions["love"] > max_love:
			max_love = p.emotions["love"]
			partner = p

	# アクション別の会話テーマ
	var reaction_type := ""
	match action:
		"feed": reaction_type = "care_feed_joy"
		"clean": reaction_type = "care_clean_refresh"
		"play": reaction_type = "care_play_fun"
		"train": reaction_type = "care_train_encourage"
		"medicine": reaction_type = "care_medicine_concern"
		"pet": reaction_type = "care_pet_warmth"
		"explore": reaction_type = "care_explore_discovery"

	GameManager.a2a_system.trigger_reaction_conversation(
		pet, partner, reaction_type, action
	)
