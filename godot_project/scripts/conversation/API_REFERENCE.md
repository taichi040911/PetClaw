# AtoAConversationSystem — API Reference

## Public Methods

### start_conversation
```gdscript
func start_conversation(pet1: PetEntity, pet2: PetEntity, trigger: String) -> void
```
Initiates a full conversation between two pets with specified trigger context.

**Parameters**:
- `pet1`: First participant (PetEntity)
- `pet2`: Second participant (PetEntity)
- `trigger`: Conversation context ("spontaneous", "greeting", "weather", etc.)

**Emits**:
- `conversation_started([pet1.pet_id, pet2.pet_id])`
- `conversation_message` (for each turn)
- `conversation_ended([pet1.pet_id, pet2.pet_id], summary)`

**Behavior**:
- Checks daily budget before proceeding
- Builds rich conversation context from pet states
- Generates turn prompts via Claude API
- Processes language evolution
- Registers memories
- Generates PetBook posts

---

### trigger_reaction_conversation
```gdscript
func trigger_reaction_conversation(
    pet: PetEntity, target: PetEntity,
    reaction_type: String, detail: String
) -> void
```
Generates an emotional reaction conversation (grief, joy, breeding).

**Parameters**:
- `pet`: Reacting pet
- `target`: Subject of reaction
- `reaction_type`: "grief" | "joy_revival" | "breeding_celebration"
- `detail`: Additional context

---

### to_dict
```gdscript
func to_dict() -> Dictionary
```
Serializes conversation system state for persistence.

**Returns**:
```gdscript
{
    "conversation_log": Array[Dictionary],     # Last 50 conversations
    "daily_cost": float,                       # Current day API cost
    "daily_count": int,                        # Current day conversation count
    "last_daily_reset": int                    # Day number of last reset
}
```

---

### from_dict
```gdscript
func from_dict(data: Dictionary) -> void
```
Restores conversation system state from saved data. Auto-resets if date has changed.

---

## Signals

### conversation_started
```gdscript
signal conversation_started(participants: Array[int])
```
Emitted when a conversation begins.

---

### conversation_ended
```gdscript
signal conversation_ended(participants: Array[int], summary: String)
```
Emitted when a conversation completes.

---

### conversation_message
```gdscript
signal conversation_message(pet_id: int, message: String, metadata: Dictionary)
```
Emitted for each turn. Metadata includes emotion, word_order, importance, etc.

---

## Key Constants

### Budget Management
```gdscript
const DAILY_CONVERSATION_BUDGET: float = 0.50        # $0.50/day
const COST_PER_TURN: float = 0.002                   # ~$0.002 per turn
const MAX_DAILY_CONVERSATIONS: int = 25              # 25 conversations max
```

### Conversation Parameters
```gdscript
const AUTO_CONVERSATION_INTERVAL: float = 180.0      # 3 minutes
const MAX_TURNS_PER_CONVERSATION: int = 6            # Max 6 turns per conversation
const MIN_EMOTION_FOR_SPONTANEOUS: float = 0.4       # 40% emotion threshold
```

### Template Categories
```gdscript
TEMPLATE_CONVERSATIONS: Array[Dictionary]

Available triggers:
- "greeting"     # Hello exchanges
- "weather"      # Environmental discussion
- "food"         # Sharing and eating
- "play"         # Active fun
- "curiosity"    # Exploration
- "comfort"      # Emotional support
```

---

## Internal Methods (Advanced)

### _build_conversation_context
```gdscript
func _build_conversation_context(pet1: PetEntity, pet2: PetEntity, trigger: String) -> Dictionary
```
Builds rich context dict including:
- Pet personalities, emotions, memories
- BiologicalMemory (if available)
- PersistentField community context
- Environment and current grammar

---

### _process_language_evolution
```gdscript
func _process_language_evolution(conversation: Array[Dictionary]) -> void
```
Extracts suffix patterns (-xxx) and registers with LanguageEvolutionSystem.

---

### _register_conversation_memory
```gdscript
func _register_conversation_memory(
    pet: PetEntity,
    conversation: Array[Dictionary],
    partner_name: String
) -> void
```
Registers conversation highlights (high emotion_intensity > 0.4) to BiologicalMemory.

---

### _generate_conversation_posts
```gdscript
func _generate_conversation_posts(
    pet1: PetEntity,
    pet2: PetEntity,
    conversation: Array[Dictionary]
) -> Array[Dictionary]
```
Generates 0-2 PetBook posts based on conversation tone:
- `sadness` → MEMORIAL
- `anger` + high intensity → REBEL
- `curiosity` → EVENT
- Default → DAILY

**Returns**: Array of post dictionaries with fields:
- `author_id`, `author_name`: Who posted
- `content`: Post text
- `post_type`: DAILY | REBEL | MEMORIAL | EVENT
- `emotion`: Detected mood
- `partner_id`: Other participant

---

### _check_budget
```gdscript
func _check_budget() -> bool
```
Returns true if daily conversation budget available.

---

### _record_conversation_cost
```gdscript
func _record_conversation_cost(turn_count: int) -> void
```
Records estimated API cost (turn_count * COST_PER_TURN).
Issues warning at 80% budget utilization.

---

### _on_day_change
```gdscript
func _on_day_change() -> void
```
Resets daily budget and conversation count.
Auto-called when date changes.

---

### _generate_template_conversation
```gdscript
func _generate_template_conversation(
    pet1: PetEntity,
    pet2: PetEntity,
    trigger: String
) -> Array[Dictionary]
```
Generates template-based conversation when API budget exhausted.
Returns up to 3 turns with dynamic pet/suffix substitution.

---

## Integration Example

```gdscript
# In GameManager or main game loop:

func _ready() -> void:
    a2a_system = AtoAConversationSystem.new()
    add_child(a2a_system)

    # Connect signals
    a2a_system.conversation_started.connect(_on_conversation_started)
    a2a_system.conversation_ended.connect(_on_conversation_ended)
    a2a_system.conversation_message.connect(_on_conversation_message)


func _on_conversation_started(participants: Array[int]) -> void:
    print("Conversation started between pets: %s" % participants)


func _on_conversation_ended(participants: Array[int], summary: String) -> void:
    print("Conversation ended: %s" % summary)
    # Auto-save state
    var state = a2a_system.to_dict()
    save_data["conversation_state"] = state


func _on_conversation_message(pet_id: int, message: String, metadata: Dictionary) -> void:
    print("[Pet %d] %s" % [pet_id, message])


# Manually trigger conversation
func start_pet_conversation(pet1: PetEntity, pet2: PetEntity) -> void:
    a2a_system.start_conversation(pet1, pet2, "manual_trigger")


# On load
func load_game_state(save_data: Dictionary) -> void:
    if save_data.has("conversation_state"):
        a2a_system.from_dict(save_data["conversation_state"])
```

---

## Debug Features

### Print Budget Status
```gdscript
print("Daily cost: $%.3f / $%.2f" % [
    a2a_system.daily_conversation_cost,
    a2a_system.DAILY_CONVERSATION_BUDGET
])
print("Conversations: %d / %d" % [
    a2a_system.daily_conversation_count,
    a2a_system.MAX_DAILY_CONVERSATIONS
])
```

### Test Template Generation
```gdscript
var template_conv = a2a_system._generate_template_conversation(pet1, pet2, "greeting")
for turn in template_conv:
    print("[%s] %s" % [turn["pet_name"], turn["message"]])
```

### View Conversation Log
```gdscript
for conv in a2a_system.conversation_log.slice(-5):
    print("Pet %d: %s" % [conv["pet_id"], conv["message"]])
```

---

## Cost Estimates

| Conversation Type | Avg Turns | Cost | Notes |
|---|---|---|---|
| Template (fallback) | 3 | $0.00 | No API calls |
| Short conversation | 2 | $0.004 | Natural quick exchange |
| Normal conversation | 4 | $0.008 | Average interaction |
| Long conversation | 6 | $0.012 | Max turns |
| 25 conversations/day | 100 | $0.20 | Typical daily budget |

---

## Error Handling

System gracefully degrades:
1. **Missing API Key** → Falls back to template conversations
2. **API Request Failure** → Uses local templates
3. **Budget Exhausted** → Switches to templates for rest of day
4. **Missing GameManager System** → Still functions with pet-only context
5. **Failed Memory Save** → Continues conversation, memory skipped

All errors logged via `print()` without halting execution.
