extends Node
class_name PetAutonomySystem

# ═══════════════════════════════════════════════════════════════════════════════
# PetAutonomySystem: Avatar-UI風 Pulse + Resonance 自律行動エンジン
# 
# ペットの周期的な自律行動（Pulse）とイベント駆動の反応（Resonance）を管理
# API使用最適化（PULSE_OK プロトコル）と感情進化を統合
# ═══════════════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────────────
# 定数 / Constants
# ───────────────────────────────────────────────────────────────────────────────

const PULSE_INTERVAL: float = 120.0  # 秒 - ペットの自律行動を評価する周期
const RESONANCE_COOLDOWN: float = 30.0  # 秒 - 同じペットの連続反応を防止
const ACTION_DECISION_THRESHOLD: float = 0.4  # スコア閾値 - これ以上でアクション実行
const PULSE_OK_THRESHOLD: float = 0.25  # このスコア以下ならPULSE_OK（スキップ）

const AUTONOMY_ACTIONS: Array[String] = [
	"wander",           # さまよう - 環境を探索、関心・好奇心
	"nap",              # 昼寝 - 疲労回復、リラックス
	"groom",            # グルーミング - 衛生・自己ケア
	"seek_companion",   # 仲間を探す - 社会性、寂しさ
	"explore_area",     # 広範囲探索 - 冒険欲、環境学習
	"practice_language", # 言語練習 - AtoA会話、進化学習
	"play_alone",       # 一人遊び - 遊び心、気晴らし
	"meditate"          # 瞑想 - 精神統一、平穏さ
]

# ───────────────────────────────────────────────────────────────────────────────
# シグナル / Signals
# ───────────────────────────────────────────────────────────────────────────────

## ペットが自律的なアクションを開始する際に発火
signal autonomous_action_started(pet_id: int, action: String, reason: String)

## ペットが自律的なアクションを完了する際に発火
signal autonomous_action_completed(pet_id: int, action: String, result: Dictionary)

## アクション評価後にPULSE_OK（スキップ）判定された場合に発火
signal pulse_skipped(pet_id: int, reason: String)

## イベント駆動の反応が発火する際に発火
signal resonance_triggered(pet_id: int, event_type: String, reaction: String)

# ───────────────────────────────────────────────────────────────────────────────
# 内部状態 / Internal State
# ───────────────────────────────────────────────────────────────────────────────

# ペットID → 最後のパルス評価タイムスタンプ
var pet_last_pulse: Dictionary = {}

# ペットID → 最近のアクション履歴（Array）
# 各要素: {"action": String, "timestamp": float, "reason": String}
var pet_pulse_history: Dictionary = {}

# ペットID → レゾナンス冷却タイマー（イベント連続発火防止）
var resonance_cooldown: Dictionary = {}

# グローバルタイマー
var pulse_timer: float = 0.0

# ゲームマネージャー参照キャッシュ
var _game_manager: Node  # GameManager (autoload)

# ───────────────────────────────────────────────────────────────────────────────
# ライフサイクル / Lifecycle
# ───────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_game_manager = GameManager.instance
	if _game_manager == null:
		push_error("PetAutonomySystem: GameManager not available")
		set_process(false)
		return
	
	# ゲームマネージャーのペット管理イベントをリッスン
	if _game_manager.has_signal("pet_spawned"):
		_game_manager.pet_spawned.connect(_on_pet_spawned)
	if _game_manager.has_signal("pet_died"):
		_game_manager.pet_died.connect(_on_pet_died)
	if _game_manager.has_signal("pet_evolved"):
		_game_manager.pet_evolved.connect(_on_pet_evolved)


func _process(delta: float) -> void:
	pulse_timer += delta
	
	if pulse_timer >= PULSE_INTERVAL:
		pulse_timer = 0.0
		_evaluate_all_pets()
	
	_update_cooldowns(delta)


# ───────────────────────────────────────────────────────────────────────────────
# Pulse System: 周期的な自律行動評価
# ───────────────────────────────────────────────────────────────────────────────

## すべての生きているペットについてパルス評価を実行
func _evaluate_all_pets() -> void:
	if _game_manager == null or _game_manager.pet_roster == null:
		return
	
	for pet_id in _game_manager.pet_roster.keys():
		var pet: PetEntity = _game_manager.pet_roster[pet_id]
		if pet == null or pet.is_dead:
			continue
		
		var decision: Dictionary = _decide_pulse_action(pet)
		
		if decision.is_empty():
			# PULSE_OK: アクション不要 - API呼び出しをスキップしコスト削減
			pulse_skipped.emit(pet_id, "Content state - no urgent needs")
		else:
			_execute_autonomous_action(pet, decision)


## ペットのアクション決定ロジック（優先度付き）
## 
## 優先度:
## 1. 緊急ニーズ（飢え < 0.2、体力 < 0.3）
## 2. 社会的ニーズ（孤独感、友好ペット近くに存在）
## 3. パーソナリティ駆動（好奇心→探索、遊び心→遊ぶ、落ち着き→瞑想）
## 4. 環境特異的（森→採食、遺跡→調査、海→泳ぐ）
## スコアが閾値以下 → PULSE_OK（空辞書を返す）
func _decide_pulse_action(pet: PetEntity) -> Dictionary:
	var scores: Dictionary = {}
	var reason_map: Dictionary = {}
	
	# Priority 1: 緊急ニーズ
	if pet.stats.hunger < 0.2:
		scores["wander"] = 0.95
		reason_map["wander"] = "Critical hunger - searching for food"
	elif pet.stats.health < 0.3:
		scores["nap"] = 0.90
		reason_map["nap"] = "Low health - needs rest"
	
	# Priority 2: 社会的ニーズ
	var loneliness: float = pet.emotions.loneliness if pet.emotions else 0.0
	if loneliness > 0.7:
		scores["seek_companion"] = 0.8
		reason_map["seek_companion"] = "High loneliness - seeking social contact"
	
	# Priority 3: パーソナリティ駆動
	var curiosity: float = pet.personality.curiosity if pet.personality else 0.5
	var playfulness: float = pet.personality.playfulness if pet.personality else 0.5
	var calmness: float = pet.personality.calmness if pet.personality else 0.5
	
	if curiosity > 0.65:
		scores["explore_area"] = 0.7 + (curiosity * 0.2)
		reason_map["explore_area"] = "High curiosity - exploring environment"
	
	if playfulness > 0.65 and pet.stats.energy > 0.5:
		scores["play_alone"] = 0.65 + (playfulness * 0.2)
		reason_map["play_alone"] = "Playful mood and energetic"
	
	if calmness > 0.65 and pet.emotions.stress < 0.3:
		scores["meditate"] = 0.6 + (calmness * 0.15)
		reason_map["meditate"] = "Calm personality - peaceful state"
	
	# Priority 4: 環境特異的（簡略版）
	if pet.current_environment and "forest" in pet.current_environment.to_lower():
		scores["wander"] = max(scores.get("wander", 0.0), 0.55)
		if not reason_map.has("wander"):
			reason_map["wander"] = "Forest environment - natural foraging"
	
	# グルーミング・言語練習は低優先度背景行動
	if pet.stats.cleanliness < 0.4:
		scores["groom"] = 0.45
		reason_map["groom"] = "Low cleanliness - grooming needed"
	
	if pet.knowledge.vocabulary_size > 5:  # ある程度語語力がある
		scores["practice_language"] = 0.40 + (pet.emotions.contentment * 0.1)
		reason_map["practice_language"] = "Language development opportunity"
	
	# 最高スコアアクションを選択
	var best_action: String = ""
	var best_score: float = 0.0
	for action in scores.keys():
		if scores[action] > best_score:
			best_score = scores[action]
			best_action = action
	
	# スコアが閾値以下ならPULSE_OK
	if best_score < PULSE_OK_THRESHOLD:
		return {}
	
	# 最終チェック: スコアがアクション実行閾値以上か確認
	if best_score >= ACTION_DECISION_THRESHOLD:
		return {
			"action": best_action,
			"reason": reason_map.get(best_action, "Autonomy driven"),
			"intensity": best_score
		}
	
	return {}


## 自律アクションを実行し、統計効果を適用
func _execute_autonomous_action(pet: PetEntity, decision: Dictionary) -> void:
	var action: String = decision.get("action", "")
	var reason: String = decision.get("reason", "")
	var intensity: float = decision.get("intensity", 0.5)
	
	if action.is_empty():
		return
	
	var pet_id: int = pet.pet_id
	
	# アクション開始シグナル
	autonomous_action_started.emit(pet_id, action, reason)
	
	# 最近のアクション履歴に記録
	_record_action_history(pet_id, action, reason)
	
	# アクション統計効果を適用
	var result: Dictionary = _apply_action_effects(pet, action, intensity)
	
	# アクション完了シグナル
	autonomous_action_completed.emit(pet_id, action, result)


## アクションの統計効果を計算・適用
func _apply_action_effects(pet: PetEntity, action: String, intensity: float) -> Dictionary:
	var result: Dictionary = {
		"action": action,
		"stats_changed": {},
		"emotion_changes": {},
		"api_triggered": false
	}
	
	# 各アクションの効果定義
	match action:
		"wander":
			pet.stats.hunger -= 0.15 * intensity
			pet.stats.energy -= 0.1 * intensity
			result.stats_changed["hunger"] = -0.15 * intensity
			result.stats_changed["energy"] = -0.1 * intensity
		
		"nap":
			pet.stats.energy = min(1.0, pet.stats.energy + 0.4 * intensity)
			pet.stats.health = min(1.0, pet.stats.health + 0.15 * intensity)
			result.stats_changed["energy"] = 0.4 * intensity
			result.stats_changed["health"] = 0.15 * intensity
		
		"groom":
			pet.stats.cleanliness = min(1.0, pet.stats.cleanliness + 0.3 * intensity)
			pet.stats.health = min(1.0, pet.stats.health + 0.05 * intensity)
			result.stats_changed["cleanliness"] = 0.3 * intensity
			result.stats_changed["health"] = 0.05 * intensity
		
		"seek_companion":
			# 社会性は別システム（PetSocialSystem）で管理される想定
			pet.stats.energy -= 0.05 * intensity
			result.stats_changed["energy"] = -0.05 * intensity
			# APIトリガー可能性あり（他ペットとの相互作用）
			result.api_triggered = true
		
		"explore_area":
			pet.stats.energy -= 0.2 * intensity
			pet.stats.hunger -= 0.1 * intensity
			result.stats_changed["energy"] = -0.2 * intensity
			result.stats_changed["hunger"] = -0.1 * intensity
		
		"practice_language":
			# 言語システムが語彙進化をハンドル
			pet.stats.energy -= 0.08 * intensity
			result.stats_changed["energy"] = -0.08 * intensity
			result.api_triggered = true  # AtoA会話トリガー
		
		"play_alone":
			pet.stats.energy -= 0.15 * intensity
			pet.stats.hunger -= 0.08 * intensity
			if pet.emotions:
				pet.emotions.contentment = min(1.0, pet.emotions.contentment + 0.2 * intensity)
				result.emotion_changes["contentment"] = 0.2 * intensity
		
		"meditate":
			if pet.emotions:
				pet.emotions.stress = max(0.0, pet.emotions.stress - 0.25 * intensity)
				pet.emotions.contentment = min(1.0, pet.emotions.contentment + 0.15 * intensity)
				result.emotion_changes["stress"] = -0.25 * intensity
				result.emotion_changes["contentment"] = 0.15 * intensity
	
	return result


## ペットのアクション履歴に記録（最新20件を保持）
func _record_action_history(pet_id: int, action: String, reason: String) -> void:
	if not pet_pulse_history.has(pet_id):
		pet_pulse_history[pet_id] = []
	
	var history: Array = pet_pulse_history[pet_id]
	history.append({
		"action": action,
		"reason": reason,
		"timestamp": Time.get_ticks_msec() / 1000.0
	})
	
	# 履歴を最新20件に制限
	if history.size() > 20:
		history.remove_at(0)


# ───────────────────────────────────────────────────────────────────────────────
# Resonance System: イベント駆動の反応
# ───────────────────────────────────────────────────────────────────────────────

## 環境変化イベントに対するレゾナンス反応
func trigger_resonance_environmental(pet_id: int, event_type: String) -> void:
	if not _is_resonance_available(pet_id):
		return
	
	var pet: PetEntity = _get_pet_by_id(pet_id)
	if pet == null:
		return
	
	var reaction: String = _evaluate_resonance_reaction(pet, event_type)
	if not reaction.is_empty():
		resonance_triggered.emit(pet_id, event_type, reaction)
		_apply_resonance_effects(pet, reaction)
		_set_resonance_cooldown(pet_id)


## 他ペットの死亡に対する同情反応
func trigger_resonance_death(pet_id: int, deceased_pet_id: int) -> void:
	if not _is_resonance_available(pet_id):
		return
	
	var pet: PetEntity = _get_pet_by_id(pet_id)
	if pet == null:
		return
	
	# 故ペットとの関係強度に基づいて反応
	var relationship_score: float = _get_relationship_score(pet_id, deceased_pet_id)
	var reaction: String = ""
	
	if relationship_score > 0.7:
		reaction = "grief"  # 深い悲しみ
	elif relationship_score > 0.4:
		reaction = "sadness"  # 悲しみ
	else:
		reaction = "curiosity"  # 軽い関心・戸惑い
	
	if not reaction.is_empty():
		resonance_triggered.emit(pet_id, "pet_death", reaction)
		_apply_resonance_effects(pet, reaction)
		_set_resonance_cooldown(pet_id)


## 進化イベント時の興奮・祝い反応
func trigger_resonance_evolution(pet_id: int, evolved_pet_id: int) -> void:
	if not _is_resonance_available(pet_id):
		return
	
	var pet: PetEntity = _get_pet_by_id(pet_id)
	if pet == null:
		return
	
	var reaction: String = "celebration"
	
	if pet_id == evolved_pet_id:
		reaction = "joy"  # 自身の進化への歓喜
	else:
		var relationship_score: float = _get_relationship_score(pet_id, evolved_pet_id)
		if relationship_score > 0.6:
			reaction = "celebration"  # 友人の進化を祝う
	
	resonance_triggered.emit(pet_id, "pet_evolution", reaction)
	_apply_resonance_effects(pet, reaction)
	_set_resonance_cooldown(pet_id)


## レゾナンス反応を評価（環境イベント用）
func _evaluate_resonance_reaction(pet: PetEntity, event_type: String) -> String:
	var curiosity: float = pet.personality.curiosity if pet.personality else 0.5
	var fear_threshold: float = 0.4
	var fear_value: float = pet.emotions.fear if pet.emotions else 0.0
	
	match event_type:
		"weather_storm":
			return "fear" if fear_value > fear_threshold else "alert"
		
		"temperature_drop":
			return "discomfort" if pet.stats.health < 0.5 else "alert"
		
		"new_item_appeared":
			return "curiosity" if curiosity > 0.6 else "caution"
		
		"unknown_sound":
			return "fear" if fear_value > fear_threshold else "curiosity"
		
		"safe_zone_change":
			return "relief"
	
	return ""


## レゾナンス反応の統計効果を適用
func _apply_resonance_effects(pet: PetEntity, reaction: String) -> void:
	if pet.emotions == null:
		return
	
	match reaction:
		"grief":
			pet.emotions.sadness = min(1.0, pet.emotions.sadness + 0.6)
			pet.emotions.contentment = max(0.0, pet.emotions.contentment - 0.4)
		
		"sadness":
			pet.emotions.sadness = min(1.0, pet.emotions.sadness + 0.3)
		
		"curiosity":
			pet.emotions.curiosity = min(1.0, pet.emotions.curiosity + 0.4)
		
		"joy":
			pet.emotions.contentment = min(1.0, pet.emotions.contentment + 0.5)
			pet.stats.energy = min(1.0, pet.stats.energy + 0.2)
		
		"celebration":
			pet.emotions.contentment = min(1.0, pet.emotions.contentment + 0.3)
			pet.stats.energy = min(1.0, pet.stats.energy + 0.15)
		
		"fear":
			pet.emotions.fear = min(1.0, pet.emotions.fear + 0.5)
			pet.emotions.stress = min(1.0, pet.emotions.stress + 0.3)
		
		"alert":
			pet.emotions.stress = min(1.0, pet.emotions.stress + 0.2)
		
		"discomfort":
			pet.stats.health = max(0.0, pet.stats.health - 0.1)
		
		"relief":
			pet.emotions.stress = max(0.0, pet.emotions.stress - 0.3)


# ───────────────────────────────────────────────────────────────────────────────
# ユーティリティ / Utilities
# ───────────────────────────────────────────────────────────────────────────────

## レゾナンス冷却をチェック（同じペットの連続反応を防止）
func _is_resonance_available(pet_id: int) -> bool:
	var cooldown_remaining: float = resonance_cooldown.get(pet_id, 0.0)
	return cooldown_remaining <= 0.0


## レゾナンス冷却を開始
func _set_resonance_cooldown(pet_id: int) -> void:
	resonance_cooldown[pet_id] = RESONANCE_COOLDOWN


## フレーム更新で冷却をカウントダウン
func _update_cooldowns(delta: float) -> void:
	for pet_id in resonance_cooldown.keys():
		resonance_cooldown[pet_id] -= delta


## ペットIDからPetEntityを取得
func _get_pet_by_id(pet_id: int) -> PetEntity:
	if _game_manager == null or _game_manager.pet_roster == null:
		return null
	return _game_manager.pet_roster.get(pet_id, null)


## 2つのペット間の関係強度を取得（仮実装）
## 実装側では PetSocialSystem などと連携
func _get_relationship_score(pet_a_id: int, pet_b_id: int) -> float:
	# プレースホルダー実装
	# 実運用では PetSocialSystem または GameManager から値を取得
	return 0.5


# ───────────────────────────────────────────────────────────────────────────────
# イベントハンドラ / Event Handlers
# ───────────────────────────────────────────────────────────────────────────────

func _on_pet_spawned(pet: PetEntity) -> void:
	var pet_id: int = pet.pet_id
	pet_last_pulse[pet_id] = Time.get_ticks_msec() / 1000.0
	pet_pulse_history[pet_id] = []
	resonance_cooldown[pet_id] = 0.0


func _on_pet_died(pet_id: int) -> void:
	# ペット死亡時に履歴をクリア
	if pet_pulse_history.has(pet_id):
		pet_pulse_history.erase(pet_id)
	if pet_last_pulse.has(pet_id):
		pet_last_pulse.erase(pet_id)
	if resonance_cooldown.has(pet_id):
		resonance_cooldown.erase(pet_id)


func _on_pet_evolved(pet_id: int) -> void:
	# 進化時にパーソナリティベースのアクション傾向が変わる可能性
	# 履歴はリセットせず継続保持
	pass


# ───────────────────────────────────────────────────────────────────────────────
# セーブ/ロード / Save & Load
# ───────────────────────────────────────────────────────────────────────────────

func to_dict() -> Dictionary:
	return {
		"pet_last_pulse": pet_last_pulse,
		"pet_pulse_history": pet_pulse_history,
		"resonance_cooldown": resonance_cooldown,
		"pulse_timer": pulse_timer
	}


func from_dict(data: Dictionary) -> void:
	pet_last_pulse = data.get("pet_last_pulse", {})
	pet_pulse_history = data.get("pet_pulse_history", {})
	resonance_cooldown = data.get("resonance_cooldown", {})
	pulse_timer = data.get("pulse_timer", 0.0)
