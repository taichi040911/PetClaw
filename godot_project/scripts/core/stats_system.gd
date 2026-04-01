## StatsData — ペットのステータス値を管理するデータクラス
## 各値は0.0〜1.0に正規化される
class_name StatsData
extends RefCounted

signal stat_changed(stat_name: String, old_value: float, new_value: float)

# === Core Stats ===
var hunger: float = 1.0      # 満腹度（0=飢餓, 1=満腹）
var health: float = 1.0      # 体力/免疫（0=瀕死, 1=健康）
var energy: float = 1.0      # 活動力（0=疲労, 1=元気）
var mood: float = 0.5        # 気分（0=最悪, 1=最高）
var affection: float = 0.3   # 愛着度（プレイヤーとの絆）

# === Derived Stats（環境・進化で変動） ===
var disease_resistance: float = 0.5   # 病気耐性
var evolution_readiness: float = 0.0  # 進化準備度


func modify(stat_name: String, delta: float) -> void:
	var old_value: float = get(stat_name)
	if old_value == null:
		push_warning("StatsData: Unknown stat '%s'" % stat_name)
		return
	var new_value: float = clampf(old_value + delta, 0.0, 1.0)
	set(stat_name, new_value)
	if absf(new_value - old_value) > 0.001:
		stat_changed.emit(stat_name, old_value, new_value)


func set_mood(value: float) -> void:
	var old_value := mood
	mood = clampf(value, 0.0, 1.0)
	if absf(mood - old_value) > 0.01:
		stat_changed.emit("mood", old_value, mood)


func get_danger_level() -> float:
	## 危険度: 0.0=安全, 1.0=即死レベル
	var danger := 0.0
	danger += maxf(0.0, 0.3 - hunger) * 2.0      # 空腹が0.3以下で危険増加
	danger += maxf(0.0, 0.2 - health) * 3.0      # 体力が0.2以下で急速に危険
	danger += maxf(0.0, 0.1 - energy) * 1.0      # エネルギー枯渇
	return clampf(danger, 0.0, 1.0)


func get_overall_condition() -> String:
	## ペットの全体状態をラベルで返す
	var avg := (hunger + health + energy + mood) / 4.0
	if avg > 0.8: return "excellent"
	elif avg > 0.6: return "good"
	elif avg > 0.4: return "fair"
	elif avg > 0.2: return "poor"
	else: return "critical"


func to_dict() -> Dictionary:
	return {
		"hunger": hunger,
		"health": health,
		"energy": energy,
		"mood": mood,
		"affection": affection,
		"disease_resistance": disease_resistance,
		"evolution_readiness": evolution_readiness,
	}


func from_dict(data: Dictionary) -> void:
	hunger = data.get("hunger", 1.0)
	health = data.get("health", 1.0)
	energy = data.get("energy", 1.0)
	mood = data.get("mood", 0.5)
	affection = data.get("affection", 0.3)
	disease_resistance = data.get("disease_resistance", 0.5)
	evolution_readiness = data.get("evolution_readiness", 0.0)
