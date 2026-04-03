# KB115: Character Design Specifications - All 22 Evolution Forms
**Version**: 2026-04-03
**Scope**: Pixel art sprite design specs for every PetClaw evolution form
**Sprite Size**: 64x64 base (upscaled from 32x32 for detail), 2D pixel art style
**Style**: Cute creature evolution (Tamagotchi meets Pokemon aesthetic)

---

## Design Philosophy

### Core Visual Identity
- **Round, organic shapes** — even tough forms keep soft curves
- **Expressive eyes** — largest feature, convey personality immediately
- **Color-coded evolution** — each form has a distinct palette that reads at 32px
- **Silhouette test** — each form must be identifiable by outline alone
- **Progressive complexity** — Stage 2 simple, Stage 5 ornate

### Visual Progression Rules
| Stage | Complexity | Size Ratio | Feature Count |
|-------|-----------|------------|---------------|
| 1 (Blob) | Minimal | 0.6x | Eyes only |
| 2 (Infant) | Simple | 0.7x | Eyes + 1 accessory |
| 3 (Youth) | Medium | 0.85x | Eyes + mouth + 2 accessories |
| 4 (Adult) | Detailed | 1.0x | Full face + 3 accessories + aura |
| 5 (Elder) | Ornate | 1.1x | Full face + 4+ accessories + complex aura |

### Dark Route Visual Rules
- Desaturated palette, shifted toward purple/black
- Red or amber eyes (never warm colors)
- Angular features breaking the round silhouette
- Shadow/flame particle effects

---

## Stage 0-1: Universal Forms

### Egg (卵)
- **Shape**: Perfect oval, slight wobble animation
- **Color**: Warm cream (#FFF8E1) with faint spots
- **Detail**: Tiny crack pattern appears before hatching
- **Size**: 24x32 within 64x64 canvas

### Blob (幼体)
- **Shape**: Round blob, slightly bottom-heavy (pear shape)
- **Color**: Cream/orange (#FFE0B2) body, lighter belly (#FFF3E0)
- **Eyes**: Large, round, black — 40% of face area
- **Detail**: Tiny blush marks, subtle bounce idle animation
- **Size**: 28x28 within 64x64 canvas
- **Personality**: Curious and innocent

---

## Stage 2: Infant Forms (5 Forms)

### 1. forest_infant (森の幼子)
- **Silhouette**: Round body + two small leaf-shaped ears on top
- **Body**: Soft green (#4CAF50) with lighter belly (#C8E6C9)
- **Accent**: Leaf green ears (#8BC34A), tiny vine curl on tail
- **Eyes**: Large, round, black with green reflection dot
- **Unique**: Small leaf growing from head, dappled light pattern on body
- **Particle**: Floating leaf motes

### 2. sea_infant (海の幼子)
- **Silhouette**: Round body + two small fin-like protrusions on sides
- **Body**: Ocean blue (#42A5F5) with lighter belly (#BBDEFB)
- **Accent**: Cyan fin tips (#81D4FA), bubble pattern on cheeks
- **Eyes**: Large, round, blue-black with water reflection
- **Unique**: Tiny dorsal fin on head, wave pattern on belly
- **Particle**: Rising bubbles

### 3. ruins_infant (遺跡の幼子)
- **Silhouette**: Round body + small crystal horn on forehead
- **Body**: Mystic purple (#AB47BC) with lighter belly (#E1BEE7)
- **Accent**: Crystal lavender horn (#CE93D8), rune mark on forehead
- **Eyes**: Large, round, with faint glow (purple iris)
- **Unique**: Glowing rune symbol (triangle) on forehead, stone fragment floating nearby
- **Particle**: Faint rune sparkles

### 4. city_infant (街の幼子)
- **Silhouette**: Round body + tiny scarf flowing to one side
- **Body**: Warm orange (#FFA726) with lighter belly (#FFE082)
- **Accent**: Red scarf (#EF5350), small gear-shaped ear accessory
- **Eyes**: Large, round, bright and alert
- **Unique**: Tiny red scarf, antenna-like cowlick hair
- **Particle**: Small gear/star sparkles

### 5. neglected_infant (さすらいの幼子) [DARK]
- **Silhouette**: Slightly angular body (less round), pointed ear tips
- **Body**: Gray (#616161) with darker belly (#424242)
- **Accent**: Dark gray (#333333), scratch marks on body
- **Eyes**: Large but narrow, RED pupils (#B71C1C), wary expression
- **Unique**: Torn ear edge, scar mark on cheek, matted texture
- **Particle**: Dark motes, shadow wisps

---

## Stage 3: Youth Forms (7 Forms)

### 6. warrior_youth (勇者の若者)
- **Silhouette**: Upright stance, small crest/mohawk on head, athletic build
- **Body**: Bold red (#D32F2F) with lighter chest plate area (#FF8A65)
- **Accent**: Gold crest (#FFD54F), red cape-like back marking
- **Eyes**: Determined, slightly angular, with fire reflection
- **Unique**: Flame-shaped crest on head, small shield mark on chest, brave stance
- **Particle**: Ember sparks rising

### 7. scholar_youth (知恵の若者)
- **Silhouette**: Slim build, large round head, small glasses/goggles on forehead
- **Body**: Deep blue (#303F9F) with lighter belly (#7986CB)
- **Accent**: Silver-blue glasses frame, book mark on back
- **Eyes**: Extra large, sparkling with curiosity (star-shaped catchlight)
- **Unique**: Round glasses pushed up on forehead, floating book page nearby, ink stain on paw
- **Particle**: Floating text/symbol fragments

### 8. healer_youth (癒しの若者)
- **Silhouette**: Soft rounded build, small halo-like ring above head
- **Body**: Warm pink (#EC407A) with cream belly (#F8BBD0)
- **Accent**: Soft gold halo ring, paw glow effect
- **Eyes**: Large, gentle, with warm light reflection (heart-shaped catchlight)
- **Unique**: Small healing aura from hands, flower crown, gentle posture
- **Particle**: Heart motes, soft pink glow

### 9. trickster_youth (いたずらの若者)
- **Silhouette**: Bouncy pose, curly tail, mischievous lean forward
- **Body**: Bright yellow (#FFB300) with lighter belly (#FFE082)
- **Accent**: Orange star marks (#FF9800), swirl on tail tip
- **Eyes**: Asymmetric — one slightly larger, playful squint
- **Unique**: Curly spring-like tail, star-shaped cheek marks, jester-like ear tips
- **Particle**: Confetti sparkles, musical notes

### 10. sentinel_youth (静寂の若者)
- **Silhouette**: Balanced, grounded pose, geometric ear shapes
- **Body**: Steel teal (#455A64) with lighter belly (#90A4AE)
- **Accent**: Teal crystal mark (#26A69A) on forehead, geometric patterns
- **Eyes**: Deep, calm, with geometric iris pattern
- **Unique**: Geometric crystal on forehead, balanced symmetrical posture, meditation-like calm
- **Particle**: Slow-orbiting geometric shapes

### 11. diplomat_youth (語り部の若者)
- **Silhouette**: Expressive pose, speech-bubble-like ear shape, open stance
- **Body**: Teal (#009688) with lighter belly (#80CBC4)
- **Accent**: Gold speech marks (#FFD700), ribbon-like tail
- **Eyes**: Warm, communicative, with golden catchlight
- **Unique**: Golden speech bubble mark on chest, flowing ribbon from neck, open welcoming pose
- **Particle**: Floating word fragments (PetClaw original language glyphs)

### 12. shadow_youth (影の若者) [DARK]
- **Silhouette**: Angular, sharp features, flame-like hair/crest
- **Body**: Dark purple (#311B92) with void-black belly (#1A0A4A)
- **Accent**: Deep violet flame (#5E35B1), shadow tendrils
- **Eyes**: Narrow, RED with inner glow (#F44336), burning intensity
- **Unique**: Dark flame crest, shadow tendrils from body, cracked ground effect
- **Particle**: Purple shadow flames, dark motes

---

## Stage 4: Adult Forms (6 Forms)

### 13. guardian_adult (守護者)
- **Silhouette**: Large, protective stance, crystal shield on one arm, wing-like shoulder plates
- **Body**: Royal gold (#FFC107) with cream chest (#FFF176)
- **Accent**: Crystal blue shield (#64B5F6), golden aura outline
- **Eyes**: Warm, protective, large with golden iris
- **Unique**: Crystal shield arm, shoulder plate wings, heart-shaped chest emblem, golden aura
- **Particle**: Golden light motes, shield shimmer

### 14. sage_adult (賢者)
- **Silhouette**: Tall, serene, floating book orbiting, hood/cowl shape
- **Body**: Wisdom blue (#1E88E5) with lighter robe area (#64B5F6)
- **Accent**: Silver-white book (#E0E0E0), knowledge crystal on staff
- **Eyes**: All-seeing, calm, with galaxy-like depth (blue iris with star)
- **Unique**: Floating open book, crystal-topped staff, starfield pattern on robe
- **Particle**: Star dust, floating formula glyphs

### 15. bond_master_adult (絆の達人)
- **Silhouette**: Open-armed pose, ribbon-like connections extending outward
- **Body**: Deep rose (#E91E63) with lighter heart area (#F8BBD0)
- **Accent**: Rainbow ribbon connections (#FF9800, #4CAF50, #2196F3), bond crystal
- **Eyes**: Deeply emotional, large with rainbow catchlight
- **Unique**: Rainbow bond ribbons extending from body, heart crystal on chest, warm embrace pose
- **Particle**: Rainbow motes, heart sparkles, connection lines

### 16. storm_warrior_adult (嵐の戦士)
- **Silhouette**: Dynamic action pose, storm cape flowing, lightning-bolt crest
- **Body**: Crimson red (#B71C1C) with electric streaks (#EF5350)
- **Accent**: Electric yellow lightning marks (#FFEB3B), storm cape
- **Eyes**: Fierce joy, electric spark in iris
- **Unique**: Lightning-bolt crest, flowing storm cape, electric crackling on fists
- **Particle**: Lightning bolts, storm clouds, electric arcs

### 17. mystic_adult (神秘者)
- **Silhouette**: Floating slightly, ancient rune circle around, ethereal robes
- **Body**: Ancient purple (#6A1B9A) with cosmic pattern (#BA68C8)
- **Accent**: Gold rune ring (#FFD700), time crystal
- **Eyes**: Ancient, seeing-beyond, with rune-patterned iris
- **Unique**: Floating rune circle orbiting body, third-eye mark on forehead, cosmic robe pattern
- **Particle**: Orbiting runes, time distortion shimmer

### 18. dark_sovereign_adult (闇の覇者) [DARK]
- **Silhouette**: Imposing, crown-like head protrusions, shadow wings
- **Body**: Void black (#212121) with deep purple veins (#4527A0)
- **Accent**: Dark crown (#311B92), shadow flame wings
- **Eyes**: Burning red with dark power (#F44336), dominating gaze
- **Unique**: Shadow crown, dark flame wings, cracked body revealing purple energy, commanding stance
- **Particle**: Shadow flames, void motes, dark lightning

---

## Stage 5: Elder/Legend Forms (4 Forms)

### 19. ancient_elder (太古の長老)
- **Silhouette**: Large, serene, floating rune stones orbiting, ancient tree-like appearance
- **Body**: Ancient gold (#FFD600) with warm amber belly (#FFF176)
- **Accent**: Floating rune stones (#A1887F), wisdom markings
- **Eyes**: Infinitely wise, gentle, amber with constellation pattern
- **Unique**: Floating ancient stones orbiting, tree-ring pattern on body, flower crown of all seasons
- **Particle**: Ancient golden dust, floating rune stones, seasonal flower petals

### 20. eternal_companion (永遠の伴侶)
- **Silhouette**: Graceful, heart-shaped body accent, light wings, eternal flame
- **Body**: Eternal rose (#E91E63) with light pink (#FCE4EC)
- **Accent**: Eternal light wings (#FFFFFF with rose tint), heart orbit
- **Eyes**: Overflowing with love, large with eternal light reflection
- **Unique**: Light wings, heart-shaped orbit trail, eternal flame on chest, most beautiful form
- **Particle**: Eternal light sparkles, orbiting hearts, rose petals

### 21. language_sage_elder (言語の大賢者)
- **Silhouette**: Tall, floating word streams around body, translator crystal crown
- **Body**: Deep teal (#00838F) with flowing text pattern (#80DEEA)
- **Accent**: Crystal crown (#E0F7FA), word stream ribbons
- **Eyes**: Understanding all, with text/glyph reflection in iris
- **Unique**: Floating word streams of original language, crystal crown, universal translator aura
- **Particle**: Floating language glyphs (PetClaw original words), translation sparkles

### 22. redeemed_elder (闇からの帰還者) [SPECIAL]
- **Silhouette**: Dual nature — half-light half-shadow, redemption wings, scars that glow
- **Body**: Sunrise orange (#E65100) with gradient to light (#FFAB40)
- **Accent**: Dual wings (one light #FFFFFF, one fading shadow #9E9E9E), redemption scars
- **Eyes**: Dual-colored (one warm amber, one fading red), showing journey from darkness
- **Unique**: Asymmetric wings (light + fading shadow), scars that glow with golden light, rarest form
- **Particle**: Dual light/shadow motes transitioning, golden scar glow, redemption sparkles

---

## Expression System (Shared Across All Forms)

### Eye Shapes (12)
| Shape | Description |
|-------|-------------|
| NORMAL | Round, default |
| HAPPY | Upward arc (^  ^) |
| EXCITED | Star-shaped sparkle |
| SAD | Downward droop with tear |
| ANGRY | V-shaped, furrowed |
| SCARED | Wide open, shrunk pupil |
| SLEEPY | Half-closed horizontal |
| LOVE | Heart-shaped |
| CURIOUS | One larger, one smaller |
| CLOSED | X-shaped or line |
| DOT | Tiny dot (distant/thinking) |
| SPARKLE | Cross-shaped sparkle |

### Mouth Shapes (10)
| Shape | Description |
|-------|-------------|
| NEUTRAL | Straight line |
| SMILE | Upward curve |
| WIDE_SMILE | Big open smile |
| FROWN | Downward curve |
| OPEN | Circle (surprise/singing) |
| WAVY | Wavy line (nervous) |
| CHOMP | Triangle (eating) |
| POUT | Small circle pushed out |
| WHISTLE | Tiny circle |
| TINY_SMILE | Small gentle smile |

---

## Color Palette Summary

| Form | Body | Accent | Eye | Aura |
|------|------|--------|-----|------|
| blob | #FFE0B2 | #FFF3E0 | #212121 | none |
| forest_infant | #4CAF50 | #8BC34A | #212121 | leaf green |
| sea_infant | #42A5F5 | #81D4FA | #212121 | ocean cyan |
| ruins_infant | #AB47BC | #CE93D8 | #4A148C | mystic purple |
| city_infant | #FFA726 | #FF5252 | #212121 | warm orange |
| neglected_infant | #616161 | #424242 | #B71C1C | shadow |
| warrior_youth | #D32F2F | #FFD54F | #212121 | ember red |
| scholar_youth | #303F9F | #7986CB | #212121 | ink blue |
| healer_youth | #EC407A | #F8BBD0 | #212121 | heal pink |
| trickster_youth | #FFB300 | #FF9800 | #212121 | spark yellow |
| sentinel_youth | #455A64 | #26A69A | #212121 | crystal teal |
| diplomat_youth | #009688 | #FFD700 | #212121 | speech gold |
| shadow_youth | #311B92 | #5E35B1 | #F44336 | shadow purple |
| guardian_adult | #FFC107 | #64B5F6 | #212121 | golden |
| sage_adult | #1E88E5 | #E0E0E0 | #212121 | star blue |
| bond_master_adult | #E91E63 | rainbow | #212121 | rainbow |
| storm_warrior_adult | #B71C1C | #FFEB3B | #212121 | electric |
| mystic_adult | #6A1B9A | #FFD700 | #212121 | cosmic purple |
| dark_sovereign_adult | #212121 | #4527A0 | #F44336 | void |
| ancient_elder | #FFD600 | #A1887F | #212121 | ancient gold |
| eternal_companion | #E91E63 | #FFFFFF | #212121 | eternal light |
| language_sage_elder | #00838F | #E0F7FA | #212121 | text teal |
| redeemed_elder | #E65100 | dual | dual | dawn |
