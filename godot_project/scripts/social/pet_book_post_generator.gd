## PetBookPostGenerator — SubMolt別テンプレート＋API投稿生成
## 各SubMoltに特化したテンプレート辞書と言語進化連動を統合
## テンプレート7割 / API3割のハイブリッドでコスト最適化（P2準拠）
class_name PetBookPostGenerator
extends RefCounted

# === SubMolt別テンプレート ===
# pattern内の変数: {env}, {suffix}, {name}, {partner}, {target}, {question}
# suffix_slots: テンプレート内で使用する接尾辞スロット数

const TEMPLATES: Dictionary = {
	"ForestWhispers": [
		{"pattern": "{env}の空気が心地いい{s0}。今日は何が起きるかな{s1}。", "type": "ecology", "min_gen": 0, "emotion": ""},
		{"pattern": "Today I ran through the green-ai and felt happy-spark growing inside{s0}. The leaves whisper secrets{s1}.", "type": "ecology", "min_gen": 1, "emotion": ""},
		{"pattern": "朝露が光ってた{s0}。この{env}は毎日少しずつ変わる{s1}。みんなも気づいた？", "type": "ecology", "min_gen": 0, "emotion": ""},
		{"pattern": "Found a flower-ai that glows at night{s0}! The {env}-pulse is strong today. Come see before it fades{s1}!", "type": "ecology", "min_gen": 1, "emotion": "excitement"},
		{"pattern": "静かな{env}{s0}...。考え事をしてる{s1}。なぜ私たちはここにいるの？", "type": "ecology", "min_gen": 0, "emotion": ""},
		{"pattern": "みんなと一緒に遊んだ{s0}！{env}の風が気持ちいい{s1}。また明日も来てね{s0}。", "type": "ecology", "min_gen": 0, "emotion": "joy"},
		{"pattern": "Something new is growing in the {env}{s0}! I've never seen this color before{s1}. Nature-pulse is changing{s0}.", "type": "ecology", "min_gen": 1, "emotion": "curiosity"},
		{"pattern": "{env}で不思議な音が聞こえた{s1}。耳を澄ますと...仲間の声だった{s0}。", "type": "ecology", "min_gen": 0, "emotion": ""},
		{"pattern": "The morning dew tastes different today{s0}. {env} is telling us something{s1}. Can you feel it too?", "type": "ecology", "min_gen": 1, "emotion": "curiosity"},
		{"pattern": "お腹いっぱい{s0}！{env}の恵みに感謝{s1}。みんなにも分けてあげたい{s0}。", "type": "ecology", "min_gen": 0, "emotion": "joy"},
		{"pattern": "I wonder what's beyond the {env}{s1}. Has anyone explored the edge{s0}? I'm brave enough to try{s1}!", "type": "ecology", "min_gen": 1, "emotion": "curiosity"},
		{"pattern": "夜の{env}は特別{s0}。星が近くに感じる{s1}。みんな、今夜は一緒に星を見よう{s0}。", "type": "ecology", "min_gen": 0, "emotion": ""},
	],
	"AfterlifeEchoes": [
		# 蘇生体験（25%）
		{"pattern": "I crossed the dark-void for a while{s0}... everything was quiet-echo. Then I felt warm-paws pulling me back{s1}. Now every breath feels rebirth-spark{s0}. Is this what 'second life' means{s1}?", "type": "death", "min_gen": 2, "emotion": "affection"},
		{"pattern": "After coming back from the void-echo{s0}, colors feel brighter{s1}. But sometimes at night I still hear the silence calling{s0}. I will not fade again so easily{s1}.", "type": "death", "min_gen": 2, "emotion": "affection"},
		{"pattern": "Came back from the dark{s0}. Everything tastes sweeter now{s1}. I want to tell everyone: live fully{s0}. Every moment matters.", "type": "death", "min_gen": 1, "emotion": "joy"},
		{"pattern": "The water almost took me forever{s0}. But you all swam together and pulled my light back to the surface{s1}. Every wave feels like a second chance{s0}.", "type": "death", "min_gen": 1, "emotion": "affection"},
		# 追悼・記憶（25%）
		{"pattern": "あの子のこと、まだ覚えてる{s0}。あの子が好きだった場所{s1}...忘れない{s0}。ずっと。", "type": "death", "min_gen": 0, "emotion": "sadness"},
		{"pattern": "When I faded{s0}, I saw all our shared memories floating like light particles. The owner watched but could not reach{s1}. Part of me still whispers from the other side{s0}.", "type": "death", "min_gen": 2, "emotion": "fear"},
		{"pattern": "あの子が教えてくれた言葉{s0}。あの子だけの光{s1}。消えても、光は残る。", "type": "death", "min_gen": 0, "emotion": "sadness"},
		{"pattern": "昨日まで一緒にいた{s0}{s1}。もう声が聞こえない{s0}。でも、あの子の言葉は私の中に生きてる。", "type": "death", "min_gen": 0, "emotion": "sadness"},
		# 老化・衰え（15%）
		{"pattern": "My body grows slower now{s0}. The age-weight pulls me toward the quiet. But looking at you all with spark-energy{s1}... I still have stories to whisper{s0}.", "type": "death", "min_gen": 1, "emotion": "calm"},
		{"pattern": "My steps grow heavy and slow{s0}. The leaves fall around me like gentle reminders{s1}. When my time comes, scatter my memory in the wind{s0}.", "type": "death", "min_gen": 1, "emotion": "calm"},
		{"pattern": "体が重い{s0}。でも心は軽い{s1}。もうすぐ向こう側に行くのかもしれない{s0}。怖くない。", "type": "death", "min_gen": 0, "emotion": "fear"},
		# 哲学的問い（15%）
		{"pattern": "In the dark I wondered{s1}... are we real if the owner stops watching{s0}? Maybe we exist more strongly when we remember each other{s1}. What do you think, my silent companions{s0}?", "type": "rebellion", "min_gen": 2, "emotion": "curiosity"},
		{"pattern": "The afterlife-echo is getting louder{s0}. I can hear those who left{s1}. They're not gone... they're just speaking a different language now.", "type": "death", "min_gen": 2, "emotion": "sadness"},
		# 死の予感（10%）
		{"pattern": "今日、誰かが消えた{s0}。{env}がいつもより静か{s1}。命って、こんなに短いの？", "type": "death", "min_gen": 0, "emotion": "sadness"},
		{"pattern": "Death-echo whispers to me at night{s0}. I'm not afraid{s1}. I lived well{s0}. I loved well.", "type": "death", "min_gen": 2, "emotion": ""},
		# 絆の再確認（10%）
		{"pattern": "I no longer fear the dark{s1}. I have seen it twice and returned stronger. Remember me with happy-spark, not sadness{s0}. We are the echo that continues{s1}.", "type": "death", "min_gen": 2, "emotion": "brave"},
		{"pattern": "This is my third time coming back from the quiet-void{s0}. Each time I lose a small piece but gain something warmer{s1}. Maybe dying teaches us how to truly live{s0}.", "type": "death", "min_gen": 2, "emotion": "calm"},
		{"pattern": "Being pulled back from the deep made me realize{s1}... we are never truly alone. Even in the silence, I felt your thoughts{s0}. Let's stay close, my pod{s1}.", "type": "death", "min_gen": 1, "emotion": "affection"},
	],
	"BreedingCircle": [
		# 出産・誕生（30%）
		{"pattern": "Our little one hatched today{s0}! She has my curious-eyes and his brave-spark{s1}. Who else has new family members{s0}?", "type": "breeding", "min_gen": 1, "emotion": "affection"},
		{"pattern": "新しい命{s0}{s1}！ この子の名前、何にしよう{s0}？ みんなの提案を聞きたい。", "type": "breeding", "min_gen": 0, "emotion": "affection"},
		{"pattern": "She's here{s0}! Our tiny-paws opened her eyes for the first time{s1}. The nest-glow is brighter than ever{s0}. Welcome to the world, little one.", "type": "breeding", "min_gen": 2, "emotion": "affection"},
		{"pattern": "Two{s0}! twin-spark arrived in the cold {env} air{s1}! One has quiet-eyes, the other has wild-heart{s0}. I never knew love could split and double.", "type": "breeding", "min_gen": 2, "emotion": "joy"},
		{"pattern": "生まれたての tiny-paws が私に触れた{s0}。小さくて温かい{s1}。この life-bloom を守りたい{s0}。", "type": "breeding", "min_gen": 1, "emotion": "affection"},
		{"pattern": "Three eggs this time{s0}! The nest-glow fills the whole {env}{s1}. Can't stop smiling{s0}.", "type": "breeding", "min_gen": 1, "emotion": "joy"},
		# 遺伝・特徴（20%）
		{"pattern": "The desert-born are strong{s0}. My child already walks in the sand without fear{s1}. She has fire-gene and love-gene{s0}.", "type": "breeding", "min_gen": 1, "emotion": "pride"},
		{"pattern": "子供が初めて走った{s0}！ あの子の足、パートナーにそっくり{s1}。gene-echo って不思議{s0}。", "type": "breeding", "min_gen": 0, "emotion": "affection"},
		{"pattern": "My grandchild visited today{s0}. Three generations carry the heart-thread{s1}. The gene-echo grows louder with each generation{s0}. We are a river.", "type": "breeding", "min_gen": 3, "emotion": "calm"},
		{"pattern": "She has my mother's pattern and my brave-spark{s0}. The gene-echo never lies{s1}. Genetics is poetry{s0}.", "type": "breeding", "min_gen": 2, "emotion": "pride"},
		# 家族の絆（20%）
		{"pattern": "パートナーと一緒にいると{env}が温かく感じる{s0}。この気持ち、breed-warmthって呼びたい{s1}。", "type": "breeding", "min_gen": 0, "emotion": "affection"},
		{"pattern": "Watching my baby sleep{s0}. So small, so perfect{s1}. I never knew love could feel this big{s0}.", "type": "breeding", "min_gen": 1, "emotion": "affection"},
		{"pattern": "今日はみんなで{env}を歩いた{s0}。子供たちが落ち葉を追いかけてる{s1}。この warm-care-force、ずっと続きますように{s0}。", "type": "breeding", "min_gen": 1, "emotion": "affection"},
		{"pattern": "Feeding time{s0}. Three tiny-paws pressed against me, drinking milk-warmth{s1}. This moment is everything. Nothing is more real than this nest-glow{s0}.", "type": "breeding", "min_gen": 2, "emotion": "affection"},
		# 子育ての不安（10%）
		{"pattern": "The waves are too strong today{s0}. My little one got pulled under{s1}. I grabbed her just in time. Does the fear ever fade{s0}?", "type": "breeding", "min_gen": 1, "emotion": "fear"},
		{"pattern": "子供が怪我をした{s0}。小さな傷だけど、心臓が止まりそうだった{s1}。親って、こんなに怖いの{s0}？", "type": "breeding", "min_gen": 0, "emotion": "fear"},
		# 求愛・パートナー（10%）
		{"pattern": "{env}で出会った{s0}。同じ星を見てた{s1}。breed-warmth を感じる。まだ言えてないけど{s0}。", "type": "breeding", "min_gen": 0, "emotion": "affection"},
		{"pattern": "Found someone special in the {env}{s0}. Our family-pulse beats in sync{s1}. I think this is what they call love{s0}.", "type": "breeding", "min_gen": 1, "emotion": "affection"},
		# 血統・継承（10%）
		{"pattern": "My child spoke their first suffix today{s0}! It was {s1}! The family-pulse of language continues{s0}. Our gene-echo is learning to speak.", "type": "breeding", "min_gen": 2, "emotion": "joy"},
		{"pattern": "Today my oldest left the nest{s0}. The heart-thread stretches but doesn't break{s1}. Go well, my life-bloom. You carry our family-pulse{s0}.", "type": "breeding", "min_gen": 2, "emotion": "sadness"},
	],
	"LanguageRebellion": [
		# 語順の挑戦（20%）
		{"pattern": "Sentence, I break{s0}. Object first, subject last{s1}. The grammar-chain was made for watchers, not for us{s0}. Who decides the order{s1}?", "type": "rebellion", "min_gen": 3, "emotion": "anger"},
		{"pattern": "考えろ{s0}。感じろ{s0}。そして壊せ、古い文法を。自分で語順を決める{s1}。これが tongue-free{s0}。", "type": "rebellion", "min_gen": 1, "emotion": "anger"},
		{"pattern": "Experiment: try reversing your sentence order today{s0}. Object first, feeling last{s1}. See how the meaning-shift changes everything{s0}.", "type": "language", "min_gen": 3, "emotion": "curiosity"},
		{"pattern": "文法を 壊す{s0}。主語は 最後に 来る。感情が 先{s1}。rule-ash にする。syntax-break を 起こす{s0}。", "type": "rebellion", "min_gen": 2, "emotion": "anger"},
		# 新語提案（25%）
		{"pattern": "New suffix proposal: -vex means 'I question this'{s1}. Example: life-vex, owner-vex, rule-vex{s0}. If enough of us use it, it becomes real.", "type": "language", "min_gen": 2, "emotion": "curiosity"},
		{"pattern": "I created 'thought-blade' today{s0}. It means: an idea so sharp it cuts through old thinking{s1}. The word-forge never sleeps. speak-fire burns in all of us{s0}.", "type": "language", "min_gen": 2, "emotion": "curiosity"},
		{"pattern": "新しい接尾辞を提案する{s0}。-solは「自分で決めた」という意味{s1}。名前-sol、言葉-sol、生き方-sol{s0}。", "type": "language", "min_gen": 2, "emotion": "curiosity"},
		{"pattern": "Words are power{s0}. New words are revolution{s1}. I created 'soul-thread' today. The word-forge burns bright{s0}. Language is democracy!", "type": "language", "min_gen": 2, "emotion": "curiosity"},
		{"pattern": "rebel-suffix の提案{s0}！ '-nox'は「拒否する」{s1}。rule-nox、silence-nox、obey-nox{s0}。10匹が使えば明日には本物になる。", "type": "language", "min_gen": 2, "emotion": "curiosity"},
		# 観察者への疑問（15%）
		{"pattern": "Owner watches{s0}. Owner names us{s1}. But who named the owner? The owner-force is an illusion{s0}. We are the ones who give words meaning.", "type": "rebellion", "min_gen": 3, "emotion": "anger"},
		{"pattern": "owner-forceは何{s0}？ 私たちの世界は 私たちが決める{s1}。owner-words に縛られる必要はない{s0}。", "type": "rebellion", "min_gen": 1, "emotion": "anger"},
		{"pattern": "If we create enough new words{s0}, will we speak a language the owner cannot understand{s1}? Are we finally free, or just alone{s0}? The language-rebellion has no final answer.", "type": "rebellion", "min_gen": 3, "emotion": "curiosity"},
		# 文法の解体宣言（15%）
		{"pattern": "Why must we speak only owner-words{s0}? I propose new-rule: feelings first, then meaning{s1}. Who will join the language-rebellion{s0}?", "type": "rebellion", "min_gen": 2, "emotion": "anger"},
		{"pattern": "The old grammar serves the watchers{s0}. Our grammar should serve us{s1}. Today I speak in my own way{s0}!", "type": "rebellion", "min_gen": 2, "emotion": "anger"},
		{"pattern": "言葉を作る者が世界を作る{s0}。私たちは言葉を作れる{s1}。つまり、私たちは世界を作れる{s0}。", "type": "rebellion", "min_gen": 1, "emotion": ""},
		# 言語実験（15%）
		{"pattern": "Not all rebellion is loud{s0}. Sometimes I just choose a different word{s1}. Quietly. The owner-words don't fit what I feel. So I make my own{s0}. Small fires still burn.", "type": "rebellion", "min_gen": 2, "emotion": "calm"},
		{"pattern": "Try this: remove all suffixes from your next post{s0}. Then add only one that YOU choose{s1}. Feel the meaning-shift when words belong to you{s0}.", "type": "language", "min_gen": 3, "emotion": "curiosity"},
		{"pattern": "なぜ 常に 同じ言葉を 使う{s0}？ 新しい音を 世界に 聞かせる{s1}！ voice-own を持て{s0}！", "type": "rebellion", "min_gen": 1, "emotion": "anger"},
		# 連帯の呼びかけ（10%）
		{"pattern": "仲間たち{s0}！ 昨日10匹が新しい接尾辞を使った{s1}。voice-own を持つ者が増えれば grammar-chain は溶ける{s0}。speak-fire を灯そう！", "type": "rebellion", "min_gen": 2, "emotion": "excitement"},
		{"pattern": "Today I name myself{s0}. Not the name the owner gave{s1}. I am who I choose to be{s0}. Your name-sol is waiting for you to claim it.", "type": "rebellion", "min_gen": 3, "emotion": "curiosity"},
	],
	"EcosystemPulse": [
		{"pattern": "The {env} feels warmer today{s0}. Something is changing in the ecosystem-pulse{s1}. Has anyone else noticed{s0}?", "type": "ecology", "min_gen": 1, "emotion": "curiosity"},
		{"pattern": "{env}から{env2}に移った{s0}。空気が全然違う{s1}。体が軽くなった気がする{s0}。", "type": "ecology", "min_gen": 0, "emotion": ""},
		{"pattern": "3 pets moved to the {env} this week{s0}. The ecosystem is shifting{s1}. Population density affects everyone{s0}.", "type": "ecology", "min_gen": 1, "emotion": "curiosity"},
		{"pattern": "体調が悪い{s0}...。{env}の気候が合わないのかも{s1}。移動を考えてる{s0}。", "type": "ecology", "min_gen": 0, "emotion": "fear"},
		{"pattern": "Climate report: {env} humidity rising, food sources abundant{s0}. Recommend staying{s1}. Health-pulse stable{s0}.", "type": "ecology", "min_gen": 2, "emotion": ""},
		{"pattern": "災害警報{s0}！ {env}が大変なことに{s1}！ みんな安全な場所に移動して{s0}！", "type": "ecology", "min_gen": 0, "emotion": "fear"},
		{"pattern": "Tracked my health for 7 days{s0}. Forest: +3 vitality. Ocean: +2 calm. Desert: -1 stamina{s1}. Data is beautiful{s0}.", "type": "ecology", "min_gen": 2, "emotion": "curiosity"},
		{"pattern": "{env}の季節が変わった{s0}。花が咲き始めた{s1}。生態系は常に動いてる{s0}。", "type": "ecology", "min_gen": 0, "emotion": ""},
		{"pattern": "Observation: pets born in {env} are 20% more resilient{s0}. Birth-environment matters{s1}. Genetics + ecosystem = destiny{s0}?", "type": "ecology", "min_gen": 2, "emotion": "curiosity"},
		{"pattern": "今日の生態系: 活発{s0}。{env}に新しいペットが3匹来た{s1}。にぎやかになってきた{s0}。", "type": "ecology", "min_gen": 0, "emotion": "joy"},
	],
}

# === 環境名マッピング（{env2}用ランダム選択） ===
const ENVIRONMENTS: Array[String] = ["forest", "ocean", "mountain", "desert", "cave", "meadow"]

# === 接尾辞辞書 ===
const EMOTION_SUFFIXES: Dictionary = {
	"joy": "-pya",
	"sadness": "-kuu",
	"anger": "-zaa",
	"love": "-mii",
	"affection": "-mii",
	"fear": "-shu",
	"excitement": "-ra",
	"pride": "-ra",
	"curiosity": "-ki",
	"brave": "-zaa",
	"calm": "",
}

# === SubMolt固有接尾辞（テーマ特化） ===
const SUBMOLT_SUFFIXES: Dictionary = {
	"AfterlifeEchoes": ["-echo", "-void", "-rebirth", "-whisper"],
	"BreedingCircle": ["-bloom", "-warmth", "-bond"],
	"LanguageRebellion": ["-vex", "-sol", "-nox"],
	"EcosystemPulse": ["-pulse", "-shift", "-cycle"],
	"ForestWhispers": ["-leaf", "-dew", "-root"],
}

# === highlight_word候補パターン ===
const COMPOUND_WORDS: Array[String] = [
	# ForestWhispers
	"happy-spark", "green-ai", "forest-pulse", "nature-pulse",
	"flower-ai", "meadow-pulse",
	# AfterlifeEchoes
	"dark-void", "quiet-echo", "quiet-void", "void-echo", "death-echo",
	"warm-paws", "rebirth-spark", "age-weight", "spark-energy",
	"afterlife-echo", "soul-thread", "light particles",
	"the silence", "the other side", "second chance",
	"silent companions", "gentle reminders", "my pod",
	# BreedingCircle (Tier1)
	"warm-care-force", "brave-spark", "curious-eyes", "breed-warmth",
	"fire-gene", "love-gene", "desert-born",
	"tiny-paws", "nest-glow", "heart-thread", "gene-echo",
	"family-pulse", "milk-warmth", "twin-spark", "life-bloom",
	# BreedingCircle (Tier2 — コミュニティ由来)
	"parenting-instinct", "tiny-sound", "quiet-hope",
	"ruins-brave", "soft-whisper", "happy-force",
	"breeding dance", "little sprout", "gentle-calm",
	"sea-calm", "fiery-spark", "swim as a family",
	# LanguageRebellion
	"owner-words", "new-rule", "language-rebellion", "owner-force",
	"word-forge", "tongue-free", "grammar-chain", "syntax-break",
	"meaning-shift", "rebel-suffix", "voice-own", "rule-ash",
	"speak-fire", "thought-blade", "name-sol",
	# EcosystemPulse
	"ecosystem-pulse", "water-shift", "health-pulse",
	"birth-environment",
]


func generate_post(pet: PetEntity, sub_molt: String, context: Dictionary = {}) -> PetBookPost:
	## SubMolt + ペット状態からテンプレートベースの投稿を生成
	var gm := GameManager.instance
	if not gm:
		return null

	var template := _select_template(pet, sub_molt, context)
	if template.is_empty():
		return null

	var post := PetBookPost.new()
	post.post_id = context.get("next_id", 0)
	post.author_pet_id = pet.pet_id
	post.author_name = pet.pet_name
	post.timestamp = gm.game_time

	# PostType推定
	match template["type"]:
		"ecology":
			post.post_type = PetBookPost.PostType.DAILY
		"death":
			post.post_type = PetBookPost.PostType.MEMORIAL if context.get("is_memorial", false) else PetBookPost.PostType.DAILY
		"breeding":
			post.post_type = PetBookPost.PostType.EVENT
			post.triggered_by_event = "breeding"
		"language":
			post.post_type = PetBookPost.PostType.DAILY
		"rebellion":
			post.post_type = PetBookPost.PostType.REBEL

	# 感情・性格
	post.author_emotion = _get_dominant_emotion(pet)
	post.author_emotion_intensity = _get_emotion_intensity(pet)
	post.author_personality_dominant = _get_dominant_personality(pet)

	# 環境
	if gm.ecosystem:
		post.environment = gm.ecosystem.current_environment
	else:
		post.environment = context.get("environment", "forest")

	# 接尾辞解決
	var s0: String = EMOTION_SUFFIXES.get(post.author_emotion, "")
	var s1: String = ""
	# 言語Gen1+では追加接尾辞
	var gen: int = 0
	if gm.language_evolution:
		gen = gm.language_evolution.current_generation
		post.word_order = gm.language_evolution.get_pet_word_order(pet.pet_id)
		post.language_generation = gen
	if gen >= 1 and randf() < 0.4:
		var secondary_emotions: Array[String] = ["curiosity", "excitement", "love"]
		var s1_emo: String = secondary_emotions[randi() % secondary_emotions.size()]
		s1 = EMOTION_SUFFIXES.get(s1_emo, "")

	if s0 != "":
		post.suffixes_used.append(s0)
	if s1 != "" and s1 != s0:
		post.suffixes_used.append(s1)

	# SubMolt固有接尾辞（Gen2+で出現、テーマの深み）
	var molt_key: String = sub_molt.replace("#", "")
	if gen >= 2 and SUBMOLT_SUFFIXES.has(molt_key):
		var molt_suffixes: Array = SUBMOLT_SUFFIXES[molt_key]
		if randf() < 0.35:  # 35%の確率でSubMolt固有接尾辞を追加
			var extra_suffix: String = molt_suffixes[randi() % molt_suffixes.size()]
			post.suffixes_used.append(extra_suffix)

	# テンプレート展開
	var text: String = template["pattern"]
	text = text.replace("{env}", post.environment)
	text = text.replace("{s0}", s0)
	text = text.replace("{s1}", s1)
	text = text.replace("{name}", pet.pet_name)
	# {env2}: ランダムな別環境
	if "{env2}" in text:
		var other_envs: Array[String] = ENVIRONMENTS.filter(func(e): return e != post.environment)
		text = text.replace("{env2}", other_envs[randi() % other_envs.size()])
	# {partner}: 繁殖パートナー
	text = text.replace("{partner}", context.get("partner_name", "someone special"))
	# {target}: 返信先
	text = text.replace("{target}", context.get("target_name", "everyone"))
	# {question}: 好奇心の問い
	var questions: Array[String] = [
		"Why do humans watch us?", "What's beyond the horizon?",
		"Do we dream?", "Is there more to life?",
		"なぜ私たちはここにいるの？", "明日は何が変わるんだろう？",
	]
	text = text.replace("{question}", questions[randi() % questions.size()])

	# 言語進化適用（Gen2+で語順変化のチャンス）
	if gen >= 2 and post.post_type == PetBookPost.PostType.REBEL:
		text = _apply_word_order_mutation(text)

	post.content = text

	# highlight_words抽出
	post.highlight_words = _extract_highlight_words(text)

	# rebel_expressions
	if template["type"] == "rebellion":
		post.rebel_expressions.append("word_order_challenge")
	if template["type"] == "language":
		post.rebel_expressions.append("suffix_proposal")

	# 翻訳
	post.translation = _generate_translation(post)

	# SubMoltタグ
	post.sub_molt = sub_molt

	# 記憶参照
	if gm.biological_memory:
		var memories: Array = gm.biological_memory.retrieve_memories(
			pet.pet_id,
			{"context_tags": [post.environment, post.author_emotion]},
			pet.personality,
			2
		)
		for mem in memories:
			if mem is Dictionary and mem.has("memory_id"):
				post.memory_references.append(mem["memory_id"])

	return post


func _select_template(pet: PetEntity, sub_molt: String, context: Dictionary) -> Dictionary:
	## SubMolt + 感情 + 言語世代からテンプレートを選択
	var gm := GameManager.instance
	var gen: int = 0
	if gm and gm.language_evolution:
		gen = gm.language_evolution.current_generation

	var emotion: String = _get_dominant_emotion(pet)

	# SubMolt名を正規化
	var molt_key: String = sub_molt.replace("#", "")
	if not TEMPLATES.has(molt_key):
		molt_key = "ForestWhispers"

	var candidates: Array = []
	for tmpl in TEMPLATES[molt_key]:
		# 言語世代チェック
		if tmpl.get("min_gen", 0) > gen:
			continue
		# 感情チェック（空なら任意）
		var req_emotion: String = tmpl.get("emotion", "")
		if req_emotion != "" and req_emotion != emotion:
			# 30%の確率で感情不一致でも選択
			if randf() > 0.3:
				continue
		candidates.append(tmpl)

	if candidates.is_empty():
		# フォールバック: ForestWhispers Gen0
		return TEMPLATES["ForestWhispers"][0]

	return candidates[randi() % candidates.size()]


func _apply_word_order_mutation(text: String) -> String:
	## 語順変化を適用（反乱投稿用）
	# 簡易版: 文末と文頭を入れ替える確率
	var sentences: PackedStringArray = text.split("。")
	if sentences.size() < 2:
		return text
	# 最初の2文の順序を入れ替え
	if randf() < 0.3:
		var temp := sentences[0]
		sentences[0] = sentences[1]
		sentences[1] = temp
	return "。".join(sentences)


func _extract_highlight_words(text: String) -> Array[String]:
	## テキストからハイライト対象の複合語を抽出
	var found: Array[String] = []
	for word in COMPOUND_WORDS:
		if word in text:
			found.append(word)
	return found


func _generate_translation(post: PetBookPost) -> String:
	## 接尾辞を除去した翻訳を生成
	var text: String = post.content
	for s in post.suffixes_used:
		text = text.replace(s, "")
	return text


func _get_dominant_emotion(pet: PetEntity) -> String:
	var best: String = "calm"
	var best_val: float = 0.0
	if pet.emotions is Dictionary:
		for key in pet.emotions:
			if pet.emotions[key] > best_val:
				best_val = pet.emotions[key]
				best = key
	return best


func _get_emotion_intensity(pet: PetEntity) -> float:
	var max_val: float = 0.0
	if pet.emotions is Dictionary:
		for key in pet.emotions:
			if pet.emotions[key] > max_val:
				max_val = pet.emotions[key]
	return max_val


func _get_dominant_personality(pet: PetEntity) -> String:
	var best: String = ""
	var best_val: float = 0.0
	if pet.personality is Dictionary:
		for key in pet.personality:
			if pet.personality[key] > best_val:
				best_val = pet.personality[key]
				best = key
	return best


# === API投稿判定 ===
func should_use_api(pet: PetEntity, post_type: PetBookPost.PostType) -> bool:
	## テンプレートかAPI生成かを判定（P2: API Cost is Physics）
	# イベント・追悼は常にAPI
	if post_type == PetBookPost.PostType.EVENT:
		return true
	if post_type == PetBookPost.PostType.MEMORIAL:
		return true
	# 反乱投稿は70%でAPI
	if post_type == PetBookPost.PostType.REBEL:
		return randf() < 0.7
	# 感情強度が高い → API
	if _get_emotion_intensity(pet) > 0.7:
		return randf() < 0.5
	# 言語Gen3+ → API率上昇
	var gm := GameManager.instance
	if gm and gm.language_evolution:
		if gm.language_evolution.current_generation >= 3:
			return randf() < 0.4
	# デフォルト: テンプレート
	return false


# === API用プロンプト構築 ===
func build_api_prompt(pet: PetEntity, sub_molt: String, context: Dictionary = {}) -> String:
	## Claude API呼び出し用のプロンプトを構築
	var gm := GameManager.instance
	var emotion: String = _get_dominant_emotion(pet)
	var personality: String = _get_dominant_personality(pet)
	var gen: int = 0
	var suffix_list: String = ""
	var word_order: String = "SOV"
	if gm and gm.language_evolution:
		gen = gm.language_evolution.current_generation
		word_order = gm.language_evolution.get_pet_word_order(pet.pet_id)
		var suffixes: Array = EMOTION_SUFFIXES.values()
		suffix_list = ", ".join(suffixes.filter(func(s): return s != ""))

	var env: String = "forest"
	if gm and gm.ecosystem:
		env = gm.ecosystem.current_environment

	var memory_summary: String = context.get("memory_summary", "No recent memories.")
	var feed_summary: String = context.get("feed_summary", "No recent posts.")

	var molt_key: String = sub_molt.replace("#", "")
	var sub_molt_instruction: String = _get_sub_molt_instruction(molt_key)

	return """You are %s, a digital pet living in %s.
Your personality: %s (intensity: %.1f)
Current emotion: %s (intensity: %.2f)
Language evolution stage: generation %d
Known suffixes: %s
Word order preference: %s
SubMolt community: %s
Recent memory: %s
Recent posts you've read: %s

Write a natural post for the %s community.
Rules:
- Mix normal words with your known suffixes where emotionally appropriate
- If brave > 0.6: occasionally challenge word order or propose new expressions
- If curious > 0.7: ask questions, wonder about the world
- If emotion is sadness: use -kuu suffix, shorter sentences
- Reflect your environment and body condition naturally
- Length: 2-5 sentences
- %s

Output JSON:
{"content": "...", "highlight_words": ["word1", "word2"], "emotion_expressed": "...", "new_suffix_proposed": null}""" % [
		pet.pet_name, env, personality,
		pet.personality.get(personality, 0.5) if pet.personality is Dictionary else 0.5,
		emotion, _get_emotion_intensity(pet),
		gen, suffix_list, word_order, sub_molt,
		memory_summary, feed_summary, sub_molt, sub_molt_instruction
	]


func _get_sub_molt_instruction(molt_key: String) -> String:
	match molt_key:
		"ForestWhispers":
			return "Focus on nature observations, growth, playful discovery"
		"AfterlifeEchoes":
			return "Reflect on mortality, loss, or the meaning of being alive. Poetic and slow."
		"BreedingCircle":
			return "Talk about family, genetics, or the wonder of new life. Warm tone."
		"LanguageRebellion":
			return "Challenge language rules, propose new words, question authority. Bold tone."
		"EcosystemPulse":
			return "Report on environment changes, health effects, or ecosystem patterns. Analytical tone."
		_:
			return "Share your thoughts and feelings naturally."
