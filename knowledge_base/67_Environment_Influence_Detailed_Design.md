# 環境影響 詳細設計ガイド
**PetClaw Knowledge Base — 2026年3月最新版**

## 1. 全体コンセプト

目標: 「環境を選ぶ・変える」行動がペットの命・成長・関係性に明確に影響し、プレイヤーの選択が世界を変える実感を与える。

- **たまごっち風**: 環境による「世話の効果変化」
- **ポケモン風**: 環境ごとの進化分岐と多様性
- **デジモン風**: 環境がパートナーシップと進化のドラマを生む

### PetClaw版の特徴
- 環境は動的に変更可能（プレイヤーが移動アクションで選択）
- 環境が体調・生き死に・進化・AtoA会話に即時・長期的に影響
- 粒子エフェクト + HSV色計算で視覚的に「環境の影響」を感じさせる
- Karpathy Loopで「環境選択の面白さ・バランス」を自動数百改善

### 環境の種類
- **森**: 成長速め、Curiosity ↑、Health安定
- **海**: 特殊進化ルート開放、Calm ↑、Energy消費緩やか
- **廃墟（ホラー寄り）**: Brave ↑、Fear微増、特殊イベント多め
- **街**: Affection ↑、社会的AtoA会話増加

## 2. 詳細メカニクス設計

### 環境影響の基本ルール
- **即時影響**: 環境変更後すぐに体調・Moodにボーナス/ペナルティ
- **長期影響**: 環境滞在時間で性格Traitsや進化ルートが変化
- **AtoA連動**: 環境でペット同士の会話内容が変わる（森では「自然の話」、廃墟では「怖い話」）
- **生き死に連動**: 悪い環境でHealth減衰が加速 → 死リスク↑
- **交配連動**: 特定の環境で交配成功率や遺伝特性が変わる

## 3. Godot 4.x 詳細実装例

### EnvironmentSystem.gd

```gdscript
class_name EnvironmentSystem

@export var current_environment: String = "forest"
@onready var background_particles: GPUParticles2D = $EnvParticles

func change_environment(new_env: String):
    current_environment = new_env
    update_environment_effects()
    await MCP.play_environment_transition(new_env)

func update_environment_effects():
    match current_environment:
        "forest":
            pet.stats.curiosity += 0.15
            pet.stats.health *= 1.05
            background_particles.color = Color(0.3, 0.8, 0.4)
        "sea":
            pet.stats.calm += 0.2
            pet.stats.energy_decay_rate *= 0.8
            background_particles.color = Color(0.2, 0.6, 1.0)
        "ruins":
            pet.stats.brave += 0.25
            pet.stats.fear += 0.1
            background_particles.color = Color(0.4, 0.3, 0.5)

    background_particles.amount = 120 + (pet.personality.brave * 80)
    background_particles.emitting = true
```

### 環境影響のAtoA会話トリガー

```gdscript
func trigger_environment_a2a():
    var prompt = """
    You are in {current_environment} environment.
    Talk naturally with your friend about how this environment makes you feel,
    and suggest an activity that fits this place.
    Reflect your personality and current emotions.
    """
    var response = await ClaudeAPI.call_agent(prompt, pet_agents)
    AtoAConversationSystem.display_log(response)
```
