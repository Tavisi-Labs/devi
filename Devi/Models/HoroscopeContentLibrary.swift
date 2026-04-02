// MARK: - Models/HoroscopeContentLibrary.swift
// Pre-written Vedic content library for the horoscope engine.
// 36 daily themes, 48 category readings, 27 mantra entries,
// 12 Jupiter modifiers, 12 Saturn modifiers, 9 planet-color mappings.

import Foundation

enum HoroscopeContentLibrary {

    // MARK: - House Theme

    struct HouseTheme {
        let themeStatement: String
        let supportingText: String
        let doList: [String]
        let dontList: [String]
    }

    // MARK: - Daily Themes (12 houses x 3 variants)
    // Index 0 = House 1, Index 11 = House 12. Each inner array has 3 variants.

    static let themes: [[HouseTheme]] = [

        // ─── House 1 (Janma) — Self-focus, new beginnings ───
        [
            HouseTheme(
                themeStatement: "Today begins with you.",
                supportingText: "The Moon lights up your first house, turning the spotlight inward. This is a day for fresh starts and personal clarity. Your instincts are sharper than usual — trust what your body is telling you.",
                doList: ["Start something you have been putting off", "Wear something that makes you feel confident", "Set one clear intention for the week ahead"],
                dontList: ["Ignore your physical energy levels", "Let someone else set your agenda", "Compare yourself to others"]
            ),
            HouseTheme(
                themeStatement: "A reset is already underway.",
                supportingText: "When the Moon returns to your rising sign, it is like a personal new moon. You may feel a quiet surge of motivation that was not there yesterday. Use this energy wisely — it will not last forever.",
                doList: ["Journal about what you actually want", "Take a solo walk to clear your mind", "Make one decision you have been avoiding"],
                dontList: ["Overcommit to social plans", "Dismiss restless feelings as anxiety", "Stay up late — sleep restores you tonight"]
            ),
            HouseTheme(
                themeStatement: "Your presence carries weight today.",
                supportingText: "People notice you more than usual when the Moon crosses your ascendant. Your words land differently, your mood is contagious. This is not the day to hide in the background.",
                doList: ["Speak up in a meeting or conversation", "Update your appearance in some small way", "Lead by example in one area of your life"],
                dontList: ["Shrink yourself to make others comfortable", "Pick fights just because you feel bold", "Neglect self-care in favor of productivity"]
            ),
        ],

        // ─── House 2 (Dhana) — Wealth, family matters ───
        [
            HouseTheme(
                themeStatement: "What you value is asking for attention.",
                supportingText: "The second house brings focus to your resources — money, possessions, and the things that give you a sense of stability. A family conversation may surface, or you might feel drawn to reassess how you spend.",
                doList: ["Review a subscription or expense you forgot about", "Call a family member you have been meaning to reach", "Cook a meal from a recipe that means something to you"],
                dontList: ["Make impulsive purchases", "Avoid a financial conversation that needs to happen", "Take family dynamics personally today"]
            ),
            HouseTheme(
                themeStatement: "Comfort is not the same as complacency.",
                supportingText: "Today highlights the difference between genuine security and just staying comfortable. The Moon in your wealth house can bring a moment of clarity about what truly sustains you versus what you cling to out of habit.",
                doList: ["Move money into savings, even a small amount", "Express gratitude to someone who supports you", "Eat something nourishing and unhurried"],
                dontList: ["Lend money you cannot afford to lose", "Ignore a bill or financial notification", "Confuse self-worth with net worth"]
            ),
            HouseTheme(
                themeStatement: "Small investments compound over time.",
                supportingText: "This is a day for quiet accumulation rather than dramatic moves. The second house rewards patience and steady effort. Something you put energy into weeks ago may start showing returns.",
                doList: ["Follow up on a pending payment or invoice", "Spend quality time with someone in your inner circle", "Organize one area of your physical space"],
                dontList: ["Gamble on a hunch without research", "Neglect your own needs to fund someone else's", "Undervalue a skill you take for granted"]
            ),
        ],

        // ─── House 3 (Sahaja) — Courage, communication ───
        [
            HouseTheme(
                themeStatement: "Say what you have been thinking.",
                supportingText: "The third house amplifies your voice and sharpens your mental edge. Messages, conversations, and short journeys are all highlighted. If you have been holding back a thought, today gives you the nerve to share it.",
                doList: ["Send that message or email you drafted in your head", "Read or listen to something that challenges your perspective", "Take a different route to a familiar place"],
                dontList: ["Gossip — your words carry further today", "Overthink a text before hitting send", "Avoid a sibling or neighbor who needs your attention"]
            ),
            HouseTheme(
                themeStatement: "Curiosity leads somewhere useful today.",
                supportingText: "Your mind is restless in the best way. The Moon in your communication house makes you a sponge for new information. A random conversation or article might hold exactly the insight you need.",
                doList: ["Ask a question you have been too proud to ask", "Write down a recurring idea before you lose it", "Learn one new thing, however small"],
                dontList: ["Scatter your energy across too many interests", "Sign contracts without reading the details", "Dismiss your own ideas as unoriginal"]
            ),
            HouseTheme(
                themeStatement: "Bravery looks like honesty right now.",
                supportingText: "The third house is called Sahaja — the house of courage. Today that courage shows up as willingness to be direct. Not harsh, not blunt, just clear. People will respect you more for it.",
                doList: ["Have a conversation you have been postponing", "Try something that requires a small amount of nerve", "Support a friend's creative effort with genuine feedback"],
                dontList: ["Confuse aggression with assertiveness", "Multitask during important conversations", "Let fear of judgment stop you from speaking"]
            ),
        ],

        // ─── House 4 (Sukha) — Comfort, home, mother ───
        [
            HouseTheme(
                themeStatement: "Home is where you need to be.",
                supportingText: "The Moon feels most at ease in the fourth house — this is its natural domain. You may feel a pull toward your living space, your roots, or the people who raised you. Nesting is not laziness; it is restoration.",
                doList: ["Improve one thing about your living space", "Reach out to your mother or a maternal figure", "Cook or order your comfort food without guilt"],
                dontList: ["Force yourself to be social if you need rest", "Ignore a maintenance issue at home", "Reopen old family wounds without intention"]
            ),
            HouseTheme(
                themeStatement: "Your inner world needs tending.",
                supportingText: "Today favors turning inward. The fourth house governs your emotional foundation, and the Moon's visit here can bring up feelings that were sitting just beneath the surface. Let them come through — they are trying to help.",
                doList: ["Sit quietly for ten minutes without a screen", "Rearrange or clean a space that feels stagnant", "Write about a memory that keeps returning"],
                dontList: ["Numb out with distractions", "Start a renovation project on impulse", "Dismiss emotions as irrational"]
            ),
            HouseTheme(
                themeStatement: "Roots before branches.",
                supportingText: "Before you can grow outward, you need to feel grounded. The fourth house asks whether your foundation is solid — your home, your sense of belonging, your relationship with where you come from. Strengthen what is underneath.",
                doList: ["Fix something around the house that has been bothering you", "Spend time with family, even virtually", "Go to bed early and protect your sleep"],
                dontList: ["Overextend yourself at work today", "Suppress homesickness or nostalgia", "Make a major life decision from a restless place"]
            ),
        ],

        // ─── House 5 (Putra) — Creativity, romance, children ───
        [
            HouseTheme(
                themeStatement: "Play is not optional today.",
                supportingText: "The fifth house is where joy lives. The Moon here wants you to create, flirt, laugh, and remember what it felt like to do things just because they were fun. Productivity can wait — delight cannot.",
                doList: ["Make something with your hands", "Spend time with a child or your inner child", "Say yes to a spontaneous invitation"],
                dontList: ["Turn a hobby into a hustle", "Ignore a romantic spark or gesture", "Overanalyze your creative output"]
            ),
            HouseTheme(
                themeStatement: "What you start now carries momentum.",
                supportingText: "The fifth house is the house of beginnings — not just biological children, but any creation that comes from you. Ideas conceived today have an unusual vitality. Write them down, sketch them out, give them a first breath.",
                doList: ["Begin a creative project, even imperfectly", "Flirt or express affection openly", "Take a risk that excites more than it scares you"],
                dontList: ["Wait for perfect conditions to start", "Suppress joy to seem serious", "Bet more than you can afford to lose"]
            ),
            HouseTheme(
                themeStatement: "Romance lives in the small moments.",
                supportingText: "You do not need a grand gesture to feel alive today. The fifth house Moon finds magic in the ordinary — a shared laugh, a clever line, a sunset noticed. Let yourself be enchanted by the day.",
                doList: ["Plan something fun for the evening", "Revisit a book, film, or album you loved as a teenager", "Compliment someone sincerely"],
                dontList: ["Compare your love life to anyone else's", "Skip leisure because you feel guilty", "Dismiss a creative impulse as silly"]
            ),
        ],

        // ─── House 6 (Ripu) — Challenges, service, health ───
        [
            HouseTheme(
                themeStatement: "Handle what is in front of you.",
                supportingText: "The sixth house is not glamorous, but it is honest. Today rewards you for showing up and doing the work — fixing the thing, serving the person, tending to your body. Small acts of discipline build the life you want.",
                doList: ["Tackle a task you have been procrastinating on", "Move your body for at least twenty minutes", "Help someone without being asked"],
                dontList: ["Ignore a health symptom that keeps returning", "Pick a fight with a coworker", "Skip meals or hydration because you are busy"]
            ),
            HouseTheme(
                themeStatement: "Obstacles are today's curriculum.",
                supportingText: "The sixth house puts friction in your path not to break you but to build you. A difficult email, a schedule conflict, or a minor health annoyance — each one is a chance to respond with skill instead of reaction.",
                doList: ["Resolve a workplace conflict calmly", "Schedule that doctor or dentist appointment", "Organize your to-do list by priority, not urgency"],
                dontList: ["Ignore your body's signals", "Complain without offering a solution", "Take on someone else's problems as your own"]
            ),
            HouseTheme(
                themeStatement: "Service is strength, not sacrifice.",
                supportingText: "Helping others does not diminish you — it reveals your capability. The Moon in the sixth house draws out your willingness to be useful. The key is to serve from fullness, not from obligation.",
                doList: ["Volunteer your expertise to someone who needs it", "Adjust your diet or routine in one small way", "Clean or declutter your workspace"],
                dontList: ["Martyr yourself for approval", "Engage in office politics", "Neglect your own health while caring for others"]
            ),
        ],

        // ─── House 7 (Kalatra) — Partnerships, relationships ───
        [
            HouseTheme(
                themeStatement: "Today pulls your attention toward the people closest to you.",
                supportingText: "The seventh house is the mirror — it shows you who you are through the eyes of your partner, your close friend, your collaborator. Pay attention to what draws you toward someone today, and what pushes you away.",
                doList: ["Have an honest conversation with your partner or closest friend", "Seek a second opinion on something important", "Compromise on one thing without keeping score"],
                dontList: ["Project your frustrations onto your partner", "Avoid conflict by going silent", "Make a major relationship decision from emotion alone"]
            ),
            HouseTheme(
                themeStatement: "Partnerships reveal your growing edges.",
                supportingText: "The Moon in the house of others highlights what you give and what you receive. If there is an imbalance in a key relationship, you will feel it today. This is not about blame — it is about recalibration.",
                doList: ["Express appreciation to someone who shows up for you", "Negotiate a better arrangement in a professional relationship", "Listen more than you speak in your next conversation"],
                dontList: ["People-please at the cost of your boundaries", "Start a new partnership without due diligence", "Compare your relationship to someone else's highlight reel"]
            ),
            HouseTheme(
                themeStatement: "The right people sharpen you.",
                supportingText: "Not every relationship is comfortable, and not every comfortable relationship is good. The seventh house Moon asks you to notice who makes you better — and who just makes you smaller. Choose wisely today.",
                doList: ["Reach out to a mentor or advisor", "Set one clear boundary in a relationship", "Collaborate on something rather than going solo"],
                dontList: ["Tolerate disrespect to keep the peace", "Rush into a business agreement", "Ghost someone who deserves a real response"]
            ),
        ],

        // ─── House 8 (Randhra) — Transformation, hidden matters ───
        [
            HouseTheme(
                themeStatement: "Something beneath the surface is shifting.",
                supportingText: "The eighth house is deep water. The Moon here can stir up emotions you did not know you were carrying — old grief, buried desire, or a quiet knowing that something in your life has run its course. Trust the process.",
                doList: ["Sit with an uncomfortable feeling instead of running from it", "Research an insurance, tax, or investment matter", "Have a vulnerable conversation with someone you trust"],
                dontList: ["Suppress intense emotions with substances or scrolling", "Ignore your intuition about a financial matter", "Force transformation — let it happen at its pace"]
            ),
            HouseTheme(
                themeStatement: "Endings make room.",
                supportingText: "The eighth house governs what must be released so new life can enter. This does not mean something dramatic will happen today — but you may feel a readiness to let go of something that once defined you.",
                doList: ["Delete, donate, or discard something you have outgrown", "Update your will, beneficiaries, or emergency contacts", "Meditate or practice breathwork to process what is surfacing"],
                dontList: ["Cling to a situation that has clearly ended", "Dig into someone's private business", "Make fear-based financial decisions"]
            ),
            HouseTheme(
                themeStatement: "Power lives where you are willing to look.",
                supportingText: "The eighth house rewards emotional honesty. What you are avoiding holds exactly the energy you need. Today is not about comfort — it is about depth. Go where the discomfort is, and you will find something valuable.",
                doList: ["Journal about a pattern you keep repeating", "Explore a topic that both fascinates and unnerves you", "Share a secret with someone who has earned your trust"],
                dontList: ["Manipulate a situation to feel in control", "Overshare with people who have not proven safe", "Ignore dreams or strong gut feelings"]
            ),
        ],

        // ─── House 9 (Dharma) — Fortune, higher learning ───
        [
            HouseTheme(
                themeStatement: "Your perspective is expanding.",
                supportingText: "The ninth house opens doors to bigger thinking. Whether through a book, a teacher, a podcast, or a conversation with someone from a different background, today brings an upgrade to how you see the world.",
                doList: ["Read or study something outside your usual interests", "Plan a future trip, even if it is just research", "Ask an elder or teacher for advice"],
                dontList: ["Dismiss beliefs that differ from yours", "Stay in your echo chamber", "Preach without practicing"]
            ),
            HouseTheme(
                themeStatement: "Luck favors those who show up prepared.",
                supportingText: "The ninth house is traditionally the house of fortune — but not the lottery kind. Today's good fortune comes through effort meeting opportunity. Put yourself in the path of serendipity by doing your work with faith.",
                doList: ["Apply for something you want, even if you are unsure", "Visit a temple, library, or place that inspires you", "Reconnect with a mentor or spiritual guide"],
                dontList: ["Wait for luck to find you on the couch", "Cut corners on something that matters", "Ignore a meaningful coincidence"]
            ),
            HouseTheme(
                themeStatement: "What you believe shapes what you build.",
                supportingText: "The ninth house is about dharma — your calling, your code, the principles you live by. The Moon here invites you to check whether your daily actions still match your deeper beliefs. Small realignments now prevent large detours later.",
                doList: ["Revisit your personal mission or guiding values", "Learn something that has no immediate practical use", "Be generous with your knowledge — teach someone"],
                dontList: ["Compromise your ethics for convenience", "Argue about philosophy when action is needed", "Confuse education with wisdom"]
            ),
        ],

        // ─── House 10 (Karma) — Career, public life, duty ───
        [
            HouseTheme(
                themeStatement: "The world is watching. Make it count.",
                supportingText: "The tenth house puts you on stage — your reputation, your contribution, your legacy are all in focus. This is not about performing; it is about doing your best work where people can see it. Let your actions speak today.",
                doList: ["Deliver excellent work on a visible project", "Update your professional profile or portfolio", "Take responsibility for something publicly"],
                dontList: ["Cut corners on quality", "Seek validation instead of impact", "Badmouth a colleague or competitor"]
            ),
            HouseTheme(
                themeStatement: "Your duty and your desire can align.",
                supportingText: "The Karma bhava reminds you that career is not separate from purpose. If your work feels hollow, today may clarify why. If it feels meaningful, today amplifies that satisfaction. Either way, show up fully.",
                doList: ["Have a strategic conversation about your career trajectory", "Complete a task that directly advances your goals", "Mentor someone who is earlier on the path"],
                dontList: ["Confuse being busy with being productive", "Ignore your health for the sake of a deadline", "Compromise your integrity for a promotion"]
            ),
            HouseTheme(
                themeStatement: "Build something that outlasts the day.",
                supportingText: "The tenth house governs your mark on the world. Today is excellent for work that has lasting impact — writing, building, organizing, leading. Focus less on what is urgent and more on what actually matters.",
                doList: ["Start a long-term project or take its next step", "Seek feedback from someone whose opinion you trust", "Dress and carry yourself as the person you are becoming"],
                dontList: ["Chase short-term wins at the cost of long-term reputation", "Overwork yourself to the point of diminishing returns", "Let impostor syndrome stop you from stepping up"]
            ),
        ],

        // ─── House 11 (Labha) — Gains, friendships, wishes ───
        [
            HouseTheme(
                themeStatement: "Community is your superpower today.",
                supportingText: "The eleventh house is where your network becomes your net worth — not in a transactional way, but through genuine connection. A friend, a group, or an online community may bring exactly the opportunity or encouragement you need.",
                doList: ["Attend a social or professional gathering", "Reconnect with an old friend", "Share a goal with someone who can help"],
                dontList: ["Isolate yourself when people are reaching out", "Use friendships purely for personal gain", "Ignore a group invitation"]
            ),
            HouseTheme(
                themeStatement: "What you wished for is closer than you think.",
                supportingText: "The eleventh house is called Labha — the house of gains. When the Moon visits here, desires have a way of materializing. Not through magic, but because your energy aligns with what you have been working toward. Stay open.",
                doList: ["Write down your top three wishes and one action for each", "Accept help or generosity without deflecting", "Contribute to a cause that matters to you"],
                dontList: ["Dismiss good news as too good to be true", "Hoard resources when sharing would help everyone", "Abandon a friendship over a minor disagreement"]
            ),
            HouseTheme(
                themeStatement: "Your circle shapes your trajectory.",
                supportingText: "Today makes visible the connection between who you spend time with and where your life is heading. The eleventh house governs your tribe. If you feel uplifted by your people, you are in the right place. If not, notice that too.",
                doList: ["Support a friend's project or idea publicly", "Join a group aligned with your interests", "Celebrate someone else's win genuinely"],
                dontList: ["Stay in groups that drain your energy", "Compare your progress to peers", "Network inauthentically"]
            ),
        ],

        // ─── House 12 (Vyaya) — Release, expenses, solitude ───
        [
            HouseTheme(
                themeStatement: "Rest is not retreat. It is preparation.",
                supportingText: "The twelfth house asks you to step back from the noise. This is not a day for launching or pushing forward — it is a day for processing, dreaming, and letting go. What you release now creates space for what comes next.",
                doList: ["Sleep in or take a nap without guilt", "Spend time near water — a bath, a lake, the ocean", "Donate or give away something you no longer need"],
                dontList: ["Force productivity on a rest day", "Ignore recurring dreams or strong impressions", "Overspend to fill an emotional void"]
            ),
            HouseTheme(
                themeStatement: "Solitude has something to teach you.",
                supportingText: "The twelfth house dissolves boundaries — between waking and dreaming, between self and other, between holding on and letting go. You may feel more porous than usual. Protect your energy and seek quiet.",
                doList: ["Meditate, pray, or sit in silence", "Visit a hospital, shelter, or ashram to serve", "Forgive someone — even if only in your heart"],
                dontList: ["Numb your feelings with excess screen time", "Make binding commitments today", "Ignore signs of burnout or exhaustion"]
            ),
            HouseTheme(
                themeStatement: "What ends quietly makes room for what begins loudly.",
                supportingText: "The twelfth house is the final chapter before the cycle restarts. Something in your life is completing — a phase, a habit, a relationship dynamic. Do not cling. The Moon here promises that endings are not losses but transitions.",
                doList: ["Complete or close out a lingering project", "Practice letting go through journaling or ceremony", "Be generous — this house rewards giving"],
                dontList: ["Start new ventures today — the timing is wrong", "Resist closure on something that has clearly ended", "Isolate from depression — solitude is healthy, withdrawal is not"]
            ),
        ],
    ]

    // MARK: - Category Readings (12 houses x 4 categories)
    // Key = house number (1-12), Value = dictionary of category -> (summary, intensity)

    static let categoryReadings: [Int: [HoroscopeCategory: (summary: String, intensity: Int)]] = [

        // House 1 (Janma) — Primary: Health, Spirituality
        1: [
            .love: (
                summary: "Relationships take a back seat to self-discovery today. You are more magnetic when you focus on yourself, which paradoxically draws others closer. Let connections happen naturally.",
                intensity: 2
            ),
            .work: (
                summary: "Your professional presence is heightened. First impressions and personal branding are especially strong. Lead with confidence but avoid steamrolling colleagues.",
                intensity: 3
            ),
            .spirituality: (
                summary: "The Moon in your first house is a spiritual reset button. Your awareness is crisp and your connection to your body is strong. Use this clarity for meditation or introspection.",
                intensity: 4
            ),
            .health: (
                summary: "Your body is speaking louder than usual. Energy levels may spike or dip noticeably. This is an excellent day to start a new health routine or recommit to an existing one.",
                intensity: 5
            ),
        ],

        // House 2 (Dhana) — Primary: Work, Love
        2: [
            .love: (
                summary: "Family bonds and intimate conversations are highlighted. You may feel a desire for emotional security from your partner. Express your needs directly rather than hinting.",
                intensity: 4
            ),
            .work: (
                summary: "Financial matters command your attention. A salary discussion, budget review, or business opportunity could surface. Trust your sense of value — you know what your work is worth.",
                intensity: 4
            ),
            .spirituality: (
                summary: "Gratitude is your spiritual practice today. The second house connects material blessings with divine grace. Notice abundance where you usually see scarcity.",
                intensity: 2
            ),
            .health: (
                summary: "Pay attention to what you put into your body. The second house governs the mouth and throat — nutrition, hydration, and vocal rest all matter more today.",
                intensity: 3
            ),
        ],

        // House 3 (Sahaja) — Primary: Work, Love
        3: [
            .love: (
                summary: "Communication is the currency of love today. A heartfelt text, a long phone call, or a witty exchange could deepen a bond. Flirting comes easily and feels natural.",
                intensity: 4
            ),
            .work: (
                summary: "Emails, meetings, and brainstorms are your arena. Your ideas are sharp and your delivery is compelling. Pitch, present, or negotiate — your words carry extra persuasion.",
                intensity: 4
            ),
            .spirituality: (
                summary: "Your spiritual growth today comes through learning and asking questions. Read a sacred text, listen to a dharma talk, or have a conversation that shifts your worldview.",
                intensity: 2
            ),
            .health: (
                summary: "Mental restlessness could translate to physical tension, especially in the shoulders and hands. Short walks, stretching, or journaling help discharge nervous energy.",
                intensity: 2
            ),
        ],

        // House 4 (Sukha) — Primary: Love, Health
        4: [
            .love: (
                summary: "Emotional depth is available in your closest relationships. This is a day for vulnerability and tenderness, not performance. The love you seek is found at home, not in the crowd.",
                intensity: 5
            ),
            .work: (
                summary: "Work-from-home energy is strong. If you must go to the office, bring the comfort of home with you — a favorite mug, a familiar playlist. Productivity follows emotional safety.",
                intensity: 2
            ),
            .spirituality: (
                summary: "The fourth house is the seat of the heart. Prayer, devotion, and inner stillness come naturally. If you have a home altar or meditation corner, spend extra time there today.",
                intensity: 4
            ),
            .health: (
                summary: "Emotional health is physical health today. Chest tightness, stomach knots, or fatigue may signal unexpressed feelings. Nurture yourself the way you would nurture someone you love.",
                intensity: 4
            ),
        ],

        // House 5 (Putra) — Primary: Love, Spirituality
        5: [
            .love: (
                summary: "Romance is alive and playful. Whether you are single or partnered, the fifth house brings flirtation, attraction, and creative chemistry. Let love be joyful rather than serious.",
                intensity: 5
            ),
            .work: (
                summary: "Creative projects and brainstorming sessions shine. Routine tasks may bore you, but anything involving innovation, design, or self-expression flows beautifully.",
                intensity: 3
            ),
            .spirituality: (
                summary: "Devotion through joy is today's path. Sing a kirtan, dance in your living room, or create something beautiful as an offering. The divine delights in your delight.",
                intensity: 4
            ),
            .health: (
                summary: "Playful movement beats grueling exercise today. Dance, swim, play a sport, or take a child to the park. Your body wants to move with pleasure, not punishment.",
                intensity: 3
            ),
        ],

        // House 6 (Ripu) — Primary: Health, Work
        6: [
            .love: (
                summary: "Relationships may feel like work today — and that is not necessarily bad. Small acts of service, like making tea or running an errand, speak louder than grand declarations.",
                intensity: 2
            ),
            .work: (
                summary: "This is your most productive day in the cycle. The sixth house rewards discipline, problem-solving, and meticulous attention. Tackle the hardest task first and watch it yield.",
                intensity: 5
            ),
            .spirituality: (
                summary: "Karma yoga — the path of selfless action — is your practice today. Serve without expecting recognition. The spiritual reward is in the doing, not the outcome.",
                intensity: 3
            ),
            .health: (
                summary: "Health is the headline today. Schedule that check-up, refill that prescription, or adjust your diet. The sixth house does not create illness — it creates the awareness to prevent it.",
                intensity: 5
            ),
        ],

        // House 7 (Kalatra) — Primary: Love, Work
        7: [
            .love: (
                summary: "Relationships are the main event. Whether it is a romantic partner, a best friend, or a business ally, the seventh house demands honest engagement. Show up fully and expect the same.",
                intensity: 5
            ),
            .work: (
                summary: "Partnerships and negotiations dominate the professional landscape. Sign contracts, finalize deals, or formalize a collaboration. Your ability to find common ground is at its peak.",
                intensity: 4
            ),
            .spirituality: (
                summary: "The divine appears to you through other people today. A stranger's kindness, a partner's patience, or an opponent's challenge — each is a mirror reflecting something sacred.",
                intensity: 3
            ),
            .health: (
                summary: "Balance is the keyword. The seventh house governs equilibrium — if you have been overworking, rest. If you have been idle, move. Your body craves symmetry and moderation.",
                intensity: 3
            ),
        ],

        // House 8 (Randhra) — Primary: Spirituality, Health
        8: [
            .love: (
                summary: "Intimacy deepens or complications surface — sometimes both. The eighth house does not do shallow. If a relationship can handle truth, it grows stronger today. If it cannot, cracks show.",
                intensity: 3
            ),
            .work: (
                summary: "Shared finances, investments, and other people's money are in focus. Research, due diligence, and strategic thinking are favored. Avoid impulsive financial moves.",
                intensity: 3
            ),
            .spirituality: (
                summary: "This is the most spiritually potent house. Meditation goes deeper, dreams are more vivid, and the veil between worlds feels thinner. Lean into mystery rather than demanding answers.",
                intensity: 5
            ),
            .health: (
                summary: "Detoxification — physical, emotional, or digital — is strongly supported. The eighth house eliminates what no longer serves. Fasting, sweating, or deep breathing all align with this energy.",
                intensity: 4
            ),
        ],

        // House 9 (Dharma) — Primary: Spirituality, Work
        9: [
            .love: (
                summary: "Long-distance connections and cross-cultural relationships are highlighted. If single, you may be attracted to someone whose worldview differs from yours. Shared values matter more than shared backgrounds.",
                intensity: 3
            ),
            .work: (
                summary: "Teaching, publishing, legal matters, and international business are all favored. Your vision extends beyond the immediate — think strategically about where you want to be in a year.",
                intensity: 4
            ),
            .spirituality: (
                summary: "The ninth house is dharma itself. Today you may feel a calling, encounter a teacher, or stumble upon a text that changes your trajectory. Trust synchronicities — they are not random.",
                intensity: 5
            ),
            .health: (
                summary: "Physical well-being benefits from a change of scenery. Walk in nature, visit a new neighborhood, or exercise outdoors. The body thrives when the mind is inspired.",
                intensity: 2
            ),
        ],

        // House 10 (Karma) — Primary: Work, Health
        10: [
            .love: (
                summary: "Romantic energy takes a practical form today. Showing up reliably, keeping promises, and being a stable presence matters more than flowers or poetry. Love is a verb.",
                intensity: 2
            ),
            .work: (
                summary: "This is your most publicly visible day. Professional achievements, promotions, and recognition are all possible. Put your best work forward — leadership is watching, even if you do not see them.",
                intensity: 5
            ),
            .spirituality: (
                summary: "Your spiritual practice today is doing your duty with full presence. The tenth house finds the sacred in professional excellence. Work as worship is not a metaphor — it is a method.",
                intensity: 3
            ),
            .health: (
                summary: "Posture, stamina, and structural health are in focus. The tenth house governs the skeletal system — your knees, spine, and joints. Stand tall, stretch often, and do not sit for too long.",
                intensity: 4
            ),
        ],

        // House 11 (Labha) — Primary: Love, Work
        11: [
            .love: (
                summary: "Friendship-based love thrives. The eleventh house values companionship, shared dreams, and mutual support over passion alone. Tell your friends you love them — they need to hear it.",
                intensity: 4
            ),
            .work: (
                summary: "Networking, teamwork, and group projects are your fast lane. A contact or referral could open a door that was previously closed. Collaborate generously and success multiplies.",
                intensity: 4
            ),
            .spirituality: (
                summary: "Sangha — spiritual community — is your practice today. Join a group meditation, attend a satsang, or simply be in the presence of like-minded seekers. Growth accelerates in good company.",
                intensity: 3
            ),
            .health: (
                summary: "Social wellness is health. The eleventh house governs the circulatory system and your social circulation. Laugh with friends, attend a group fitness class, or simply be around people who energize you.",
                intensity: 3
            ),
        ],

        // House 12 (Vyaya) — Primary: Spirituality, Health
        12: [
            .love: (
                summary: "Love today is quiet and sacrificial. The twelfth house softens boundaries — you may feel another's pain as your own. Compassion is your gift, but protect yourself from absorbing too much.",
                intensity: 2
            ),
            .work: (
                summary: "Professional drive dims in favor of reflection. Behind-the-scenes work, research, and planning are favored over public-facing tasks. Do not force visibility today.",
                intensity: 2
            ),
            .spirituality: (
                summary: "The twelfth house is moksha — liberation itself. Meditation, prayer, and surrender reach their deepest point here. You may feel a profound connection to something larger than yourself.",
                intensity: 5
            ),
            .health: (
                summary: "Rest is medicine. The twelfth house governs sleep, the feet, and the immune system. Prioritize sleep quality, take a warm bath, and avoid overstimulation. Your body is recharging.",
                intensity: 4
            ),
        ],
    ]

    // MARK: - Nakshatra Mantras (27 entries)

    static let nakshatraMantra: [String: MantraReading] = [
        "Ashwini": MantraReading(
            sanskrit: "Om Ashwini Kumarabhyam Namaha",
            translation: "Salutations to the Ashwini Kumaras, the celestial healers",
            deity: "Ashwini Kumaras"
        ),
        "Bharani": MantraReading(
            sanskrit: "Om Yamaya Namaha",
            translation: "Salutations to Yama, lord of dharma and cosmic order",
            deity: "Yama"
        ),
        "Krittika": MantraReading(
            sanskrit: "Om Agnaye Namaha",
            translation: "Salutations to Agni, the sacred fire",
            deity: "Agni"
        ),
        "Rohini": MantraReading(
            sanskrit: "Om Brahmane Namaha",
            translation: "Salutations to Brahma, the creator",
            deity: "Brahma"
        ),
        "Mrigashira": MantraReading(
            sanskrit: "Om Somaya Namaha",
            translation: "Salutations to Soma, the lunar deity of nectar",
            deity: "Soma"
        ),
        "Ardra": MantraReading(
            sanskrit: "Om Rudraya Namaha",
            translation: "Salutations to Rudra, the cosmic transformer",
            deity: "Rudra"
        ),
        "Punarvasu": MantraReading(
            sanskrit: "Om Aditaye Namaha",
            translation: "Salutations to Aditi, the infinite mother",
            deity: "Aditi"
        ),
        "Pushya": MantraReading(
            sanskrit: "Om Brihaspataye Namaha",
            translation: "Salutations to Brihaspati, the divine teacher",
            deity: "Brihaspati"
        ),
        "Ashlesha": MantraReading(
            sanskrit: "Om Sarpebhyo Namaha",
            translation: "Salutations to the Nagas, the serpent deities",
            deity: "Nagas"
        ),
        "Magha": MantraReading(
            sanskrit: "Om Pitribhyo Namaha",
            translation: "Salutations to the Pitris, the ancestral spirits",
            deity: "Pitris"
        ),
        "Purva Phalguni": MantraReading(
            sanskrit: "Om Bhagaya Namaha",
            translation: "Salutations to Bhaga, the deity of fortune and delight",
            deity: "Bhaga"
        ),
        "Uttara Phalguni": MantraReading(
            sanskrit: "Om Aryamne Namaha",
            translation: "Salutations to Aryaman, the deity of patronage and honor",
            deity: "Aryaman"
        ),
        "Hasta": MantraReading(
            sanskrit: "Om Savitre Namaha",
            translation: "Salutations to Savitar, the vivifying solar deity",
            deity: "Savitar"
        ),
        "Chitra": MantraReading(
            sanskrit: "Om Tvashtre Namaha",
            translation: "Salutations to Tvashtar, the celestial architect",
            deity: "Tvashtar"
        ),
        "Swati": MantraReading(
            sanskrit: "Om Vayave Namaha",
            translation: "Salutations to Vayu, the lord of wind and breath",
            deity: "Vayu"
        ),
        "Vishakha": MantraReading(
            sanskrit: "Om Indragnibhyam Namaha",
            translation: "Salutations to Indra and Agni, lords of power and fire",
            deity: "Indragni"
        ),
        "Anuradha": MantraReading(
            sanskrit: "Om Mitraya Namaha",
            translation: "Salutations to Mitra, the deity of friendship and alliance",
            deity: "Mitra"
        ),
        "Jyeshtha": MantraReading(
            sanskrit: "Om Indraya Namaha",
            translation: "Salutations to Indra, king of the devas",
            deity: "Indra"
        ),
        "Mula": MantraReading(
            sanskrit: "Om Nirritaye Namaha",
            translation: "Salutations to Nirriti, the goddess of dissolution",
            deity: "Nirriti"
        ),
        "Purva Ashadha": MantraReading(
            sanskrit: "Om Apahe Namaha",
            translation: "Salutations to Apas, the cosmic waters",
            deity: "Apas"
        ),
        "Uttara Ashadha": MantraReading(
            sanskrit: "Om Vishvedebhyo Namaha",
            translation: "Salutations to the Vishvedevas, the universal gods",
            deity: "Vishvedevas"
        ),
        "Shravana": MantraReading(
            sanskrit: "Om Vishnave Namaha",
            translation: "Salutations to Vishnu, the all-pervading preserver",
            deity: "Vishnu"
        ),
        "Dhanishtha": MantraReading(
            sanskrit: "Om Vasubhyo Namaha",
            translation: "Salutations to the Vasus, the elemental deities of abundance",
            deity: "Vasus"
        ),
        "Shatabhisha": MantraReading(
            sanskrit: "Om Varunaya Namaha",
            translation: "Salutations to Varuna, lord of the cosmic waters",
            deity: "Varuna"
        ),
        "Purva Bhadrapada": MantraReading(
            sanskrit: "Om Ajaaikapadaya Namaha",
            translation: "Salutations to Aja Ekapada, the one-footed cosmic serpent",
            deity: "Aja Ekapada"
        ),
        "Uttara Bhadrapada": MantraReading(
            sanskrit: "Om Ahirbudhnyaya Namaha",
            translation: "Salutations to Ahir Budhnya, the serpent of the deep",
            deity: "Ahir Budhnya"
        ),
        "Revati": MantraReading(
            sanskrit: "Om Pushne Namaha",
            translation: "Salutations to Pushan, the nourishing guide of journeys",
            deity: "Pushan"
        ),
    ]

    // MARK: - Planet-to-Color Mapping (9 navagraha)

    static let planetColor: [String: AuspiciousColor] = [
        "Sun":     AuspiciousColor(name: "Copper",      hex: "#B87333"),
        "Moon":    AuspiciousColor(name: "Silver",       hex: "#C0C0C0"),
        "Mars":    AuspiciousColor(name: "Red",          hex: "#C45050"),
        "Mercury": AuspiciousColor(name: "Green",        hex: "#4AAD6E"),
        "Jupiter": AuspiciousColor(name: "Gold",         hex: "#D4A040"),
        "Venus":   AuspiciousColor(name: "Pink",         hex: "#D47AAD"),
        "Saturn":  AuspiciousColor(name: "Blue",         hex: "#4A6FA5"),
        "Rahu":    AuspiciousColor(name: "Smoky Grey",   hex: "#808080"),
        "Ketu":    AuspiciousColor(name: "Saffron",      hex: "#FF9933"),
    ]

    // MARK: - Jupiter Modifiers (12 houses)
    // Describes how Jupiter's transit through each house modifies the daily reading.

    static let jupiterModifiers: [Int: String] = [
        1:  "Jupiter's grace illuminates your sense of self, bringing optimism and expansion to personal endeavors. Growth feels effortless — just make sure confidence does not tip into overreach.",
        2:  "Jupiter in your house of wealth amplifies financial opportunities and family blessings. Resources may flow more generously than expected. Use abundance wisely rather than spending it all at once.",
        3:  "Jupiter expands your communicative reach and intellectual curiosity. Teaching, writing, and media projects are blessed. Your words carry more authority and your ideas find a wider audience.",
        4:  "Jupiter brings growth and comfort to your home life and emotional foundations. A move, renovation, or deepening of family bonds is possible. Inner peace becomes your greatest asset.",
        5:  "Jupiter in the house of creativity supercharges romance, artistic output, and joy. Children or creative projects may bring unexpected blessings. Take the risk — fortune favors your self-expression.",
        6:  "Jupiter's presence in the sixth house helps you overcome obstacles and improve health habits. Enemies lose their power, debts become manageable, and service to others brings unexpected rewards.",
        7:  "Jupiter blesses partnerships of all kinds. Marriage prospects improve, business alliances strengthen, and negotiations go smoothly. The right person may walk into your life at the right time.",
        8:  "Jupiter in the eighth house deepens your spiritual transformation and may bring gains through inheritance, insurance, or shared resources. The mysteries of life feel less frightening and more fascinating.",
        9:  "Jupiter is at home in the ninth house, multiplying your good fortune. Travel, higher education, and spiritual growth are all powerfully supported. Teachers and mentors appear when you need them.",
        10: "Jupiter elevates your career and public standing. Promotions, recognition, and professional milestones are within reach. Your reputation grows and leadership opportunities present themselves.",
        11: "Jupiter in the house of gains fulfills long-held wishes. Social circles expand, income from side ventures increases, and the support of friends and community lifts you higher than solo effort could.",
        12: "Jupiter in the twelfth house brings spiritual expansion and blessings through surrender. Foreign travel, meditation retreats, and charitable giving are all deeply rewarding. Letting go becomes a form of receiving.",
    ]

    // MARK: - Saturn Modifiers (12 houses)
    // Describes how Saturn's transit through each house modifies the daily reading.

    static let saturnModifiers: [Int: String] = [
        1:  "Saturn's weight on your first house demands discipline and self-honesty. Progress feels slower, but what you build now is built to last. Patience with yourself is not optional — it is essential.",
        2:  "Saturn in the house of wealth requires financial prudence and careful planning. Income may feel constrained, but this is the universe teaching you the difference between what you need and what you want.",
        3:  "Saturn tests your courage and communication. Words may feel heavier, and bold action requires more effort than usual. Persist — the skills you sharpen under pressure become your greatest strengths.",
        4:  "Saturn's transit through your fourth house may bring responsibilities at home or emotional heaviness. A parent may need your support, or your living situation demands restructuring. Build the foundation patiently.",
        5:  "Saturn in the house of joy asks you to take creativity seriously. Romance may feel weighty, and fun requires effort. The reward is depth — anything you create now has lasting substance and meaning.",
        6:  "Saturn in the sixth house strengthens your ability to handle adversity. Health routines become non-negotiable, and daily discipline yields real results. Your enemies and obstacles gradually lose their grip.",
        7:  "Saturn in the seventh house tests your most important relationships. Commitments deepen or dissolve depending on their integrity. This is not punishment — it is a filter that keeps only what is real.",
        8:  "Saturn's presence in the eighth house can feel heavy, bringing confrontation with mortality, debt, or deep psychological patterns. Transformation is not comfortable, but what emerges is unshakeable.",
        9:  "Saturn challenges your beliefs and tests your faith. Dogma crumbles, but genuine wisdom survives. Teachers may disappoint, pushing you to find your own authority. The path narrows but becomes yours.",
        10: "Saturn in your tenth house demands professional excellence without shortcuts. Career progress slows but becomes more meaningful. Authority figures scrutinize your work — give them nothing to criticize.",
        11: "Saturn in the house of gains filters your social circle. Fair-weather friends disappear, but the ones who remain are allies for life. Financial gains come slowly but reliably through sustained effort.",
        12: "Saturn in the twelfth house intensifies solitude and spiritual reckoning. Hidden fears surface, and sleep may be disrupted. This is the final exam before a new cycle — face what remains unfaced.",
    ]
}
