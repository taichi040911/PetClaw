## BreedingSystem — 交配・遺伝・子孫誕生を管理
## ポケモンの収集要素 + デジモンの進化分岐を統合
class_name BreedingSystem
extends Node

signal breeding_available(pet1_id: int, pet2_id: int)
signal offspring_born(parent1_id: int, parent2_id: int, child: PetEntity)
signal trait_inherited(child_id: int, trait: String, from_parent_id: int)

# === 交配条件閾値 ===
const MIN_AFFECTION: float = 0.6      # 最低愛着度
const MIN_HEALTH: float = 0.5         # 最低体力
const MIN_AGE: float = 10.0           # 最低年齢（Child以上）
const MAX_AGE: float = 70.0           # 最高年齢（Elder後半は不可）
const COMPATIBILITY_THRESHOLD: float = 0.4  # 最低相性スコア

# === 遺伝パラメータ ===
const TRAIT_INHERIT_CHANCE: float = 0.7     # 各Traitが親から継承される確率
const MUTATION_CHANCE: float = 0.1          # 突然変異確率
const MUTATION_RANGE: float = 0.15          # 突然変異の変動幅
const MEMORY_INHERIT_CHANCE: float = 0.2    # 記憶が継承される確率
const MEMORY_INHERIT_MAX: int = 5           # 最大継承記憶数


# === 相性チェック ===
func check_compatibility(pet1: PetEntity, pet2: PetEntity) -> Dictionary:
	var result := {
		"compatible": false,
		"score": 0.0,
		"reasons": [],
		"blockers": [],
	}

	# 年齢チェック
	if pet1.age < MIN_AGE or pet2.age < MIN_AGE:
		result["blockers"].append("too_young")
	if pet1.age > MAX_AGE or pet2.age > MAX_AGE:
		result["blockers"].append("too_old")

	# 体力チェック
	if pet1.stats.health < MIN_HEALTH or pet2.stats.health < MIN_HEALTH:
		result["blockers"].append("low_health")

	# 生存チェック
	if not pet1.is_alive or not pet2.is_alive:
		result["blockers"].append("not_alive")

	if result["blockers"].size() > 0:
		return result

	# 性格相性スコア計算
	var personality_score := _calculate_personality_compatibility(pet1, pet2)

	# 感情相性
	var emotion_score := _calculate_emotion_compatibility(pet1, pet2)

	# 環境ボーナス
	var env_bonus: float = GameManager.ecosystem.get_breeding_bonus()

	# 愛着度
	var affection_score := (pet1.emotions["love"] + pet2.emotions["love"]) / 2.0

	# 総合スコア
	var total_score := (
		personality_score * 0.3 +
		emotion_score * 0.2 +
		affection_score * 0.4 +
		maxf(0.0, env_bonus) * 0.1
	)

	result["score"] = total_score
	result["compatible"] = total_score >= COMPATIBILITY_THRESHOLD

	if personality_score > 0.6:
		result["reasons"].append("personality_match")
	if affection_score > 0.7:
		result["reasons"].append("strong_bond")
	if env_bonus > 0.0:
		result["reasons"].append("favorable_environment")

	return result


func _calculate_personality_compatibility(pet1: PetEntity, pet2: PetEntity) -> float:
	# 補完的な性格の方が相性が良い（正反対ではなく、バランスの取れた組み合わせ）
	var score := 0.0
	var trait_count := 0
	for trait in pet1.personality:
		var diff := absf(pet1.personality[trait] - pet2.personality[trait])
		# 適度な差（0.2〜0.5）が最高スコア
		if diff >= 0.2 and diff <= 0.5:
			score += 1.0
		elif diff < 0.2:
			score += 0.7  # 似すぎも悪くない
		else:
			score += 0.3  # 差が大きすぎると低め
		trait_count += 1
	return score / maxf(1, trait_count)


func _calculate_emotion_compatibility(pet1: PetEntity, pet2: PetEntity) -> float:
	# 同じポジティブ感情を共有しているほど相性が良い
	var shared_positivity := 0.0
	shared_positivity += minf(pet1.emotions["joy"], pet2.emotions["joy"])
	shared_positivity += minf(pet1.emotions["love"], pet2.emotions["love"])
	shared_positivity += minf(pet1.emotions["excitement"], pet2.emotions["excitement"])
	return clampf(shared_positivity / 1.5, 0.0, 1.0)


# === 交配実行 ===
func breed(pet1: PetEntity, pet2: PetEntity) -> PetEntity:
	var compat := check_compatibility(pet1, pet2)
	if not compat["compatible"]:
		push_warning("Breeding failed: incompatible (%s)" % str(compat["blockers"]))
		return null

	# 子孫生成
	var child := _create_offspring(pet1, pet2, compat["score"])

	# 親の感情反応
	GameManager.emotion_system.stimulate(pet1, "love", 0.5, "breeding")
	GameManager.emotion_system.stimulate(pet1, "joy", 0.4, "breeding")
	GameManager.emotion_system.stimulate(pet2, "love", 0.5, "breeding")
	GameManager.emotion_system.stimulate(pet2, "joy", 0.4, "breeding")

	# 親に記憶追加
	pet1.add_memory({"type": "bred", "partner_id": pet2.pet_id, "child_id": child.pet_id})
	pet2.add_memory({"type": "bred", "partner_id": pet1.pet_id, "child_id": child.pet_id})

	offspring_born.emit(pet1.pet_id, pet2.pet_id, child)

	# AtoA交配会話
	GameManager.a2a_system.trigger_reaction_conversation(
		pet1, pet2, "breeding_celebration", ""
	)

	# ビジュアル
	_play_breeding_visuals(pet1, pet2, child)

	return child


func _create_offspring(parent1: PetEntity, parent2: PetEntity, compat_score: float) -> PetEntity:
	var child := PetEntity.new()
	child.pet_id = GameManager.generate_pet_id()
	child.pet_name = _generate_offspring_name(parent1, parent2)
	child.age = 0.0
	child.evolution_stage = 0  # Egg
	child.is_alive = true
	child.current_environment = parent1.current_environment

	# === 性格の遺伝 ===
	for trait in parent1.personality:
		if randf() < TRAIT_INHERIT_CHANCE:
			# どちらの親から継承するか
			var from_parent: PetEntity
			if randf() < 0.5:
				from_parent = parent1
			else:
				from_parent = parent2
			child.personality[trait] = from_parent.personality[trait]
			trait_inherited.emit(child.pet_id, trait, from_parent.pet_id)
		else:
			# ランダム値
			child.personality[trait] = randf_range(0.3, 0.7)

		# 突然変異
		if randf() < MUTATION_CHANCE:
			var mutation := randf_range(-MUTATION_RANGE, MUTATION_RANGE)
			child.personality[trait] = clampf(child.personality[trait] + mutation, 0.0, 1.0)

	# === 記憶の部分継承 ===
	var inherited_memories: Array[Dictionary] = []
	var all_parent_memories := parent1.memories + parent2.memories
	all_parent_memories.shuffle()
	for memory in all_parent_memories:
		if inherited_memories.size() >= MEMORY_INHERIT_MAX:
			break
		if randf() < MEMORY_INHERIT_CHANCE:
			var inherited := memory.duplicate()
			inherited["inherited"] = true
			inherited["from_parent"] = true
			inherited_memories.append(inherited)
	child.memories = inherited_memories

	# === 初期ステータス ===
	child.stats.hunger = 0.8
	child.stats.health = 0.9
	child.stats.energy = 0.7
	child.stats.mood = 0.8
	# 親の平均値をベースに病気耐性を設定
	child.stats.disease_resistance = (
		parent1.stats.disease_resistance + parent2.stats.disease_resistance
	) / 2.0 + randf_range(-0.1, 0.1)

	return child


func _generate_offspring_name(parent1: PetEntity, parent2: PetEntity) -> String:
	# 親の名前から文字を組み合わせて生成（仮実装）
	var name1 := parent1.pet_name
	var name2 := parent2.pet_name
	if name1.length() >= 2 and name2.length() >= 2:
		return name1.substr(0, ceili(name1.length() / 2.0)) + name2.substr(floori(name2.length() / 2.0))
	return "Baby"


func _play_breeding_visuals(parent1: PetEntity, parent2: PetEntity, child: PetEntity) -> void:
	# 親の感情色をブレンド
	var color1 := GameManager.emotion_system.get_emotion_color(parent1)
	var color2 := GameManager.emotion_system.get_emotion_color(parent2)
	var blend_color := color1.lerp(color2, 0.5)

	GameManager.visual_fx.play_effect("breeding", {
		"parent1_id": parent1.pet_id,
		"parent2_id": parent2.pet_id,
		"child_id": child.pet_id,
		"color": blend_color,
		"particle_amount": 250,
		"duration": 4.0,
	})


# === 遺伝システム（v2追加） ===

## 遺伝形質定義
const GENETIC_TRAITS: Dictionary = {
	"appearance": {"heritability": 0.8, "mutation_rate": 0.05},
	"personality": {"heritability": 0.6, "mutation_rate": 0.10},
	"language_tendency": {"heritability": 0.7, "mutation_rate": 0.08},
	"emotion_range": {"heritability": 0.5, "mutation_rate": 0.12},
	"lifespan_modifier": {"heritability": 0.4, "mutation_rate": 0.15},
	"suffix_affinity": {"heritability": 0.75, "mutation_rate": 0.06},
}

signal genetic_trait_inherited(child_id: int, trait: String, heritability_value: float)
signal twin_born(parent1_id: int, parent2_id: int, child1_id: int, child2_id: int)
signal mutation_occurred(child_id: int, trait: String, mutation_type: String, new_value: float)


func calculate_offspring_traits(parent1: PetEntity, parent2: PetEntity) -> Dictionary:
	## 両親の遺伝形質から子の形質を計算
	var offspring_traits := {}

	for trait_name: String in GENETIC_TRAITS.keys():
		var trait_info: Dictionary = GENETIC_TRAITS[trait_name]
		var heritability: float = trait_info.get("heritability", 0.5)

		# 1. どちらの親を支配親とするか（遺伝率ベース）
		var dominant_parent: PetEntity
		if randf() < heritability:
			# 高遺伝率形質は親のいずれかを継承
			dominant_parent = parent1 if randf() < 0.5 else parent2
		else:
			# 低遺伝率形質はランダム
			dominant_parent = null

		# 2. 形質値を取得（ブレンド）
		var parent1_value: float = _get_trait_value(parent1, trait_name)
		var parent2_value: float = _get_trait_value(parent2, trait_name)
		var base_value: float

		if dominant_parent:
			base_value = _get_trait_value(dominant_parent, trait_name)
		else:
			# ブレンド（親の平均 + 乱数ボーナス）
			var blend_factor: float = randf()
			base_value = lerp(parent1_value, parent2_value, blend_factor)

		# 3. 突然変異チェック
		var mutation_info := check_mutation(trait_name, base_value)
		if mutation_info.get("mutated", false):
			base_value = mutation_info.get("new_value", base_value)
			mutation_occurred.emit(
				-1,  # child_id は後で設定
				trait_name,
				mutation_info.get("mutation_type", "unknown"),
				base_value
			)

		# 4. 有効範囲にクランプ
		base_value = clampf(base_value, 0.0, 1.0)
		offspring_traits[trait_name] = base_value
		genetic_trait_inherited.emit(-1, trait_name, heritability)

	return offspring_traits


func _get_trait_value(pet: PetEntity, trait_name: String) -> float:
	## ペットから形質値を取得
	match trait_name:
		"appearance":
			# 外見特性 (0.0-1.0スケール)
			return pet.evolution_stage / 5.0  # 進化段階をスケーリング
		"personality":
			# 性格（複数の性格タイプの平均）
			var sum: float = 0.0
			var count: int = 0
			for key in pet.personality.keys():
				sum += pet.personality[key]
				count += 1
			return sum / maxf(1, count)
		"language_tendency":
			# 言語傾向（BiologicalMemoryの学習スタイル）
			return 0.5  # プレースホルダー（実装時にBiologicalMemoryから取得）
		"emotion_range":
			# 感情振幅（全感情の分散）
			var avg: float = 0.0
			for emotion_val in pet.emotions.values():
				avg += emotion_val
			return avg / maxf(1, pet.emotions.size())
		"lifespan_modifier":
			# 寿命修正（年齢ベース）
			return clampf(pet.age / 100.0, 0.0, 1.0)
		"suffix_affinity":
			# サフィックス親和性（言語進化の接尾辞選好）
			return 0.5  # プレースホルダー（実装時に言語システムから取得）
		_:
			return 0.5


func check_mutation(trait_name: String, base_value: float) -> Dictionary:
	## 突然変異チェック
	## Returns: {"mutated": bool, "new_value": float, "mutation_type": String}
	var trait_info: Dictionary = GENETIC_TRAITS.get(trait_name, {})
	var mutation_rate: float = trait_info.get("mutation_rate", 0.05)

	if randf() >= mutation_rate:
		return {"mutated": false, "new_value": base_value, "mutation_type": "none"}

	# 突然変異が発生
	var mutation_type: String
	var new_value: float

	var mutation_roll: float = randf()
	if mutation_roll < 0.4:
		# 値を上昇させる突然変異（boost）
		mutation_type = "boost"
		new_value = clampf(base_value + randf_range(0.1, 0.3), 0.0, 1.0)
	elif mutation_roll < 0.8:
		# 値を低下させる突然変異（reduce）
		mutation_type = "reduce"
		new_value = clampf(base_value - randf_range(0.1, 0.3), 0.0, 1.0)
	else:
		# ユニークな突然変異（unique）
		mutation_type = "unique"
		new_value = randf()

	return {"mutated": true, "new_value": new_value, "mutation_type": mutation_type}


func check_twin_probability(parent1: PetEntity, parent2: PetEntity) -> float:
	## 双子確率を計算（基本5%、環境・健康で変動）
	var base_prob: float = 0.05

	# 健康度ボーナス
	var health_bonus: float = 0.0
	if parent1.stats.health > 0.7 and parent2.stats.health > 0.7:
		health_bonus = 0.02

	# 環境ボーナス（草原+2%）
	var env_bonus: float = 0.0
	if parent1.current_environment == "meadow" or parent2.current_environment == "meadow":
		env_bonus = 0.02

	# 愛着度ボーナス（両親の愛着が高い場合）
	var affection_bonus: float = 0.0
	var avg_affection: float = (parent1.affection + parent2.affection) / 2.0
	if avg_affection > 0.8:
		affection_bonus = 0.03

	var total_prob: float = base_prob + health_bonus + env_bonus + affection_bonus
	return clampf(total_prob, 0.01, 0.15)


# === 家系図データ（v2追加） ===

var family_tree: Dictionary = {}  # pet_id → FamilyNode

class FamilyNode:
	var pet_id: int
	var pet_name: String
	var parent1_id: int = -1
	var parent2_id: int = -1
	var children_ids: Array[int] = []
	var partner_ids: Array[int] = []
	var generation: int = 0
	var birth_time: float = 0.0
	var death_time: float = -1.0  # -1 = alive
	var genetic_traits: Dictionary = {}

	func _init(p_pet_id: int, p_pet_name: String) -> void:
		pet_id = p_pet_id
		pet_name = p_pet_name
		birth_time = Time.get_unix_time_from_system()

	func to_dict() -> Dictionary:
		return {
			"pet_id": pet_id,
			"pet_name": pet_name,
			"parent1_id": parent1_id,
			"parent2_id": parent2_id,
			"children_ids": children_ids.duplicate(),
			"partner_ids": partner_ids.duplicate(),
			"generation": generation,
			"birth_time": birth_time,
			"death_time": death_time,
			"genetic_traits": genetic_traits.duplicate(),
		}

	static func from_dict(data: Dictionary) -> FamilyNode:
		var node := FamilyNode.new(data.get("pet_id", 0), data.get("pet_name", "Unknown"))
		node.parent1_id = data.get("parent1_id", -1)
		node.parent2_id = data.get("parent2_id", -1)
		node.children_ids = Array(data.get("children_ids", []))
		node.partner_ids = Array(data.get("partner_ids", []))
		node.generation = data.get("generation", 0)
		node.birth_time = data.get("birth_time", 0.0)
		node.death_time = data.get("death_time", -1.0)
		node.genetic_traits = data.get("genetic_traits", {})
		return node


func register_birth(child: PetEntity, parent1: PetEntity, parent2: PetEntity) -> void:
	## 出生を家系図に登録
	var parent1_node: FamilyNode = family_tree.get(parent1.pet_id)
	var parent2_node: FamilyNode = family_tree.get(parent2.pet_id)
	var child_node := FamilyNode.new(child.pet_id, child.pet_name)

	# 親情報を設定
	child_node.parent1_id = parent1.pet_id
	child_node.parent2_id = parent2.pet_id

	# 親の世代から子の世代を計算
	var parent_generation: int = 0
	if parent1_node:
		parent_generation = maxf(parent_generation, parent1_node.generation)
	if parent2_node:
		parent_generation = maxf(parent_generation, parent2_node.generation)
	child_node.generation = parent_generation + 1

	# 遺伝形質を記録
	child_node.genetic_traits = calculate_offspring_traits(parent1, parent2)

	# 親に子を追加
	if parent1_node:
		parent1_node.children_ids.append(child.pet_id)
	if parent2_node:
		parent2_node.children_ids.append(child.pet_id)

	# パートナー情報を更新
	if not parent1_node:
		parent1_node = FamilyNode.new(parent1.pet_id, parent1.pet_name)
		family_tree[parent1.pet_id] = parent1_node
	if not parent2_node:
		parent2_node = FamilyNode.new(parent2.pet_id, parent2.pet_name)
		family_tree[parent2.pet_id] = parent2_node

	if parent2.pet_id not in parent1_node.partner_ids:
		parent1_node.partner_ids.append(parent2.pet_id)
	if parent1.pet_id not in parent2_node.partner_ids:
		parent2_node.partner_ids.append(parent1.pet_id)

	# 子を家系図に追加
	family_tree[child.pet_id] = child_node


func get_family_tree_for_pet(pet_id: int) -> Dictionary:
	## 特定ペットの家系図データを取得（UI表示用）
	## Returns ancestors (up 3 generations) and descendants (down 3 generations)
	var pet_node: FamilyNode = family_tree.get(pet_id)
	if not pet_node:
		return {}

	var result := {
		"self": pet_node.to_dict(),
		"ancestors": _get_ancestors(pet_node, 3),
		"descendants": _get_descendants(pet_node, 3),
		"partners": [],
	}

	# パートナー情報を追加
	for partner_id in pet_node.partner_ids:
		var partner_node: FamilyNode = family_tree.get(partner_id)
		if partner_node:
			result["partners"].append(partner_node.to_dict())

	return result


func _get_ancestors(node: FamilyNode, max_depth: int) -> Array[Dictionary]:
	## 祖先を取得（最大3世代まで）
	var ancestors: Array[Dictionary] = []

	if max_depth <= 0:
		return ancestors

	# 親を取得
	if node.parent1_id >= 0:
		var parent1: FamilyNode = family_tree.get(node.parent1_id)
		if parent1:
			ancestors.append(parent1.to_dict())
			# 祖父母を再帰的に取得
			ancestors.append_array(_get_ancestors(parent1, max_depth - 1))

	if node.parent2_id >= 0:
		var parent2: FamilyNode = family_tree.get(node.parent2_id)
		if parent2:
			ancestors.append(parent2.to_dict())
			# 祖父母を再帰的に取得
			ancestors.append_array(_get_ancestors(parent2, max_depth - 1))

	return ancestors


func _get_descendants(node: FamilyNode, max_depth: int) -> Array[Dictionary]:
	## 子孫を取得（最大3世代まで）
	var descendants: Array[Dictionary] = []

	if max_depth <= 0:
		return descendants

	# 子を取得
	for child_id in node.children_ids:
		var child: FamilyNode = family_tree.get(child_id)
		if child:
			descendants.append(child.to_dict())
			# 孫を再帰的に取得
			descendants.append_array(_get_descendants(child, max_depth - 1))

	return descendants


func get_lineage_stats(pet_id: int) -> Dictionary:
	## 血統統計（最長血統、遺伝的多様性、突然変異数）
	var pet_node: FamilyNode = family_tree.get(pet_id)
	if not pet_node:
		return {}

	var max_lineage_depth: int = _calculate_max_depth(pet_node)
	var total_descendants: int = _count_descendants(pet_node)
	var genetic_diversity: float = _calculate_genetic_diversity(pet_node)
	var mutation_count: int = _count_mutations(pet_node)

	return {
		"pet_id": pet_id,
		"generation": pet_node.generation,
		"max_lineage_depth": max_lineage_depth,
		"total_descendants": total_descendants,
		"genetic_diversity": genetic_diversity,
		"mutation_count": mutation_count,
		"ancestors_count": _count_ancestors(pet_node),
		"partners": pet_node.partner_ids.size(),
	}


func _calculate_max_depth(node: FamilyNode) -> int:
	## ペットのツリー内での最大深度を計算
	if node.children_ids.is_empty():
		return 1

	var max_child_depth: int = 0
	for child_id in node.children_ids:
		var child: FamilyNode = family_tree.get(child_id)
		if child:
			max_child_depth = maxf(max_child_depth, _calculate_max_depth(child))

	return max_child_depth + 1


func _count_descendants(node: FamilyNode) -> int:
	## 総子孫数を計算
	var count: int = 0
	for child_id in node.children_ids:
		count += 1
		var child: FamilyNode = family_tree.get(child_id)
		if child:
			count += _count_descendants(child)
	return count


func _count_ancestors(node: FamilyNode) -> int:
	## 総祖先数を計算
	var count: int = 0
	if node.parent1_id >= 0:
		count += 1
		var parent1: FamilyNode = family_tree.get(node.parent1_id)
		if parent1:
			count += _count_ancestors(parent1)
	if node.parent2_id >= 0:
		count += 1
		var parent2: FamilyNode = family_tree.get(node.parent2_id)
		if parent2:
			count += _count_ancestors(parent2)
	return count


func _calculate_genetic_diversity(node: FamilyNode) -> float:
	## 遺伝的多様性を計算（0.0-1.0、高いほど多様）
	if node.genetic_traits.is_empty():
		return 0.5

	var diversity: float = 0.0
	for trait_value in node.genetic_traits.values():
		# 0.5から離れるほど多様性が高い
		diversity += absf(trait_value - 0.5)

	return clampf(diversity / node.genetic_traits.size(), 0.0, 1.0)


func _count_mutations(node: FamilyNode) -> int:
	## ツリー全体での突然変異数を計算
	var count: int = 0

	# 現在のノードで突然変異が記録されているか（プレースホルダー）
	if node.genetic_traits.has("_mutation_occurred"):
		count += 1

	# 子孫の突然変異を再帰的にカウント
	for child_id in node.children_ids:
		var child: FamilyNode = family_tree.get(child_id)
		if child:
			count += _count_mutations(child)

	return count
