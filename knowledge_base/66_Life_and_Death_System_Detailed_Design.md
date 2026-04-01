# 生き死にシステム 詳細設計ガイド
**PetClaw Knowledge Base — 2026年3月最新版**

## 1. 全体コンセプト

目標: 「世話をしたくなる愛着」と「命の大切さ」を強く感じさせる。

- **たまごっち**: 「死のリスクによる緊張感」
- **ポケモン**: 「努力で救える成長」
- **デジモン**: 「パートナーとの絆が命を左右するドラマ」

を現代AIで融合:
- 放置やミスで死のリスクが発生
- AtoA協力や特別世話で蘇生可能
- 死の悲しみを他のペットとの会話で表現（関係性の深み）
- Karpathy Loopで「緊張感と愛着のバランス」を自動数百改善

## 2. 詳細メカニクス設計

### 死の条件と進行
- **警告段階**: HungerまたはHealthが0に近づくと「弱り」アニメ + 粒子エフェクト（暗い色調）
- **死の判定**: Hunger/Healthが一定時間0以下 / Ageが極端に高い場合の老衰
- **死の演出**: ペットが静かに倒れるアニメ → 画面全体の粒子が暗く減衰 → AtoA会話で他ペットが悲しむ
- **蘇生条件**: 特別ケア（Medicine + AtoA協力）、他ペットのAffectionが高い場合に蘇生確率アップ、蘇生後は性格や感情が少し変化

### 老化システム
- Ageが上昇するごとに体調変化が速くなる
- 特殊進化ルート開放（老化耐性や賢さルート）
- 老化演出: 動きがゆっくりになり、粒子が柔らかい光に変化

### AtoA・感情との連動
- 死発生時: 他のペットが自律的に悲しみ会話 → 感情値（fear, affection）が上昇
- 蘇生時: ペット同士で「生き返ってよかった！」の喜び会話
- 性格影響: 勇敢なペットは死のリスクを減らす行動を優先、好奇心高いペットは新しい環境で寿命を延ばす

## 3. Godot 4.x 詳細実装例

### LifeDeathSystem.gd

```gdscript
class_name LifeDeathSystem

@onready var pet_display: AnimatedSprite2D = $PetDisplay
@onready var death_particles: GPUParticles2D = $DeathParticles

var is_alive: bool = true
var age: float = 0.0
var warning_threshold: float = 0.2

func process_life_cycle(delta: float):
    age += delta / 3600.0

    var hunger = pet.stats.hunger
    var health = pet.stats.health

    if hunger <= 0 or health <= 0:
        enter_warning_state()
        if check_death_condition():
            trigger_death()

    if age > 50:
        pet.stats.health *= 0.995

func enter_warning_state():
    pet_display.play("weak")
    death_particles.color = Color(0.3, 0.1, 0.4)
    death_particles.emitting = true

func trigger_death():
    is_alive = false
    pet_display.play("death")
    death_particles.amount = 300
    death_particles.emitting = true
    AtoAConversationSystem.trigger_death_reaction(pet)
    await MCP.play_death_sequence()

func revive():
    is_alive = true
    pet.stats.health = 0.5
    pet.stats.hunger = 0.5
    age = 0.0
    pet_display.play("revive")
    AtoAConversationSystem.trigger_revive_reaction(pet)
```
