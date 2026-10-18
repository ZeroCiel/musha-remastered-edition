-- Musha 0.7.6 — English Language File

local S = GLOBAL.STRINGS

-- Item names
S.NAMES.MUSHA_SWORD = "Sword"
S.NAMES.MUSHA_LIFEBRANCH = "Life Branch"
S.NAMES.MUSHA_SKILLBOOK = "Skill Book"
S.NAMES.MUSHA_SKILL_SCROLL = "Skill Scroll"
S.NAMES.MUSHA_NOTE = "Note"
S.NAMES.MUSHA_JOBBOOK = "Job Tome"
S.NAMES.MUSHA_JOBBOOK_WARRIOR = "Job Tome (Warrior)"
-- ✅ 2026-09-17 发布前：测试专用转职书已下架 → S.NAMES.MUSHA_JOBBOOK_SABER = "Swordsman Advance Tome (TEST)"
S.NAMES.MUSHA_BOOK_UNKNOWN = "An Unknown Book"
S.NAMES.MUSHA_JOBBOOK_MAGE = "Mage Job Tome"
S.NAMES.MUSHA_JOBBOOK_RANGER = "Ranger Job Tome"
S.NAMES.MUSHA_JOBBOOK_GUARDIAN = "Guardian Jobbook"
S.NAMES.MUSHA_JOBBOOK_ASSASSIN = "Assassin Job Tome"
S.NAMES.MUSHA_ADVANCE_ALTAR = "Hotel"   -- ★ 2026-09-28 用户："英文直译 hotel"（原 Tavern 非直译，写错）
S.NAMES.MUSHA_ADVANCE_SCROLL = "Advance Scroll"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_ADVANCE_SCROLL = "An ancient scroll taken from the hotel. Unroll it to accept the trial."
S.NAMES.MUSHA_SKILLBOOK_SWORDSMAN = "Swordsman Basic Skill Book"
S.NAMES.MUSHA_SKILLBOOK_GUARDIAN = "Guardian Basic Skill Book"
S.NAMES.MUSHA_SKILLBOOK_ALCHEMIST = "Alchemist Basic Skill Book"
S.NAMES.MUSHA_SKILLBOOK_ELEMENTALIST = "Elementalist Basic Skill Book"
S.NAMES.MUSHA_SKILLBOOK_BARD = "Bard Basic Skill Book"
S.NAMES.MUSHA_SKILLBOOK_MOONSHADOW = "Moonshadow Basic Skill Book"
S.NAMES.MUSHA_REST_ITEM = "Rest"

-- Item descriptions
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_JOBBOOK_WARRIOR = "A tome recording the path of the warrior. Use to change job to Warrior."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_JOBBOOK_MAGE = "A tome recording the path of the mage. Use to change job to Mage."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_JOBBOOK_RANGER = "A tome recording the path of the ranger. Use to change job to Ranger."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_JOBBOOK_ASSASSIN = "A tome recording the path of the assassin. Use to change job to Assassin."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_ADVANCE_ALTAR = "A lively hotel where every job-change trial is taken."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK_SWORDSMAN = "Contains basic skills for Swordsmen."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK_GUARDIAN = "Contains basic skills for Guardians."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK_ALCHEMIST = "Contains basic skills for Alchemists."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK_ELEMENTALIST = "Contains basic skills for Elementalists."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK_BARD = "Contains basic skills for Bards."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK_MOONSHADOW = "Contains basic skills for Moonshadows."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SWORD = "A heavy job sword emitting a faint cold gleam."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_LIFEBRANCH = "A branch that is still alive. Warm in the hand, as if it were budding."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK = "A yellowed book recording your job skills."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILL_SCROLL = "A scroll of common combat techniques. Unroll it to learn the skill within."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_REST_ITEM = "Right-click to toggle resting state."

-- Character selection screen
S.CHARACTER_TITLES.musha = "Wandering Snow Maiden"
S.CHARACTER_NAMES.musha = "Ciel"
S.CHARACTER_DESCRIPTIONS.musha = "*Starts with a guiding note\n*Exclusive job system\n*Can change to Warrior/Mage/Rogue/Ranger\n*Higher levels grant more power"
S.CHARACTER_QUOTES.musha = "\"The cold wind will guide your path.\""

-- Action names
S.ACTIONS.MUSHA_USE_JOBBOOK = "Change Job"
S.ACTIONS.MUSHA_USE_JOBBOOK_STR = {
    ["转职"] = "Change Job",
    ["使用"] = "Use",
    ["未知"] = "Unknown",
}
S.ACTIONS.MUSHA_OPEN_ALTAR = "Enter Hotel"            -- 2026-09-17: was MUSHA_QUEST_INTERACT ("View Quest"); 2026-09-28 Tavern→Hotel 直译
S.ACTIONS.MUSHA_UNROLL_SCROLL = "Unroll Scroll"    -- 2026-09-17: advance scroll from the altar
-- 2026-09-18 advance-direction crests (two handed out at the ceremony: Swordsman / Guardian)
S.ACTIONS.MUSHA_USE_CREST = "Use Crest"
-- ★ 2026-09-19 邮包系统（信箱 + 信差包）
--   Action label: default "Touch"; becomes "Upgrade" when a mail kit is carried (see strfn).
--   BIND / OPEN are spares until the "already bound" state is synced to the client.
S.ACTIONS.MUSHA_OPEN_MAILBOX = "Touch"
S.ACTIONS.MUSHA_PUT_MAILBOX = "Store in Mailbox"
S.ACTIONS.MUSHA_OPEN_MAILBOX_STR = {
    UPGRADE = "Upgrade",
    BIND    = "Touch (Bind)",
    OPEN    = "Touch (Open)",
}
S.ACTIONS.MUSHA_OPEN_MAILBAG = "Open Mail Bag"
S.NAMES.MUSHA_MAILBOX = "Mailbox"
S.NAMES.MUSHA_MAILBAG = "Mail Bag"
S.NAMES.MUSHA_MAILKIT_1 = "Mail Upgrade Kit I (3 to 5 slots)"
S.NAMES.MUSHA_MAILKIT_2 = "Mail Upgrade Kit II (5 to 7 slots)"
S.NAMES.MUSHA_MAILKIT_3 = "Mail Upgrade Kit III (7 to 9 slots)"
S.NAMES.MUSHA_MAILKIT_4 = "Mail Upgrade Kit IV (9 to 12 slots)"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_MAILBOX = "Touch it once and your inbox lives here. It stays here."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_MAILBAG = "Fill it, close it -- and it all goes home."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_MAILKIT_1 = "Hold it at the mailbox and say 'upgrade'."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_MAILKIT_2 = "Hold it at the mailbox and say 'upgrade'."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_MAILKIT_3 = "Hold it at the mailbox and say 'upgrade'."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_MAILKIT_4 = "Hold it at the mailbox and say 'upgrade'."
S.NAMES.MUSHA_CREST_SABER = "Swordsman Crest"
S.NAMES.MUSHA_CREST_GUARDIAN = "Guardian Crest"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_CREST_SABER = "A crest marked with a blade. Use it and you walk the swordsman's path -- the choice is final."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_CREST_GUARDIAN = "A crest marked with a shield. Use it and you walk the guardian's path -- the choice is final."
S.ACTIONS.MUSHA_LEARN_SKILL = "Learn Skill"
S.ACTIONS.MUSHA_REST = "Rest"
S.ACTIONS.MUSHA_OPEN_PANEL = "Open Panel"
S.ACTIONS.MUSHA_READ_NOTE = "Read"

-- System messages
S.MUSHA_JOB_USE_NO_SYSTEM = "Job system not available…"
S.MUSHA_JOB_USE_ALREADY_HAS = "You already have a job!"
S.MUSHA_JOB_USE_WARRIOR = "You changed job to: Warrior"
S.MUSHA_JOB_USE_NO_JOB = "You haven't chosen a job yet!"

-- Job names
S.MUSHA_JOB_WARRIOR = "Warrior"
S.MUSHA_JOB_MAGE = "Mage"
S.MUSHA_JOB_RANGER = "Ranger"
S.MUSHA_JOB_ASSASSIN = "Assassin"
S.MUSHA_JOB_SWORDSMAN = "Swordsman"
S.MUSHA_JOB_SABER = "Swordsman"   -- alias: the code-side tree key is "saber"
S.MUSHA_JOB_GUARDIAN = "Guardian"
S.MUSHA_JOB_ALCHEMIST = "Alchemist"
S.MUSHA_JOB_ELEMENTALIST = "Elementalist"
S.MUSHA_JOB_BARD = "Bard"
S.MUSHA_JOB_MOONSHADOW = "Moonshadow"
S.MUSHA_JOB_NONE = "None"

-- Quest messages
S.MUSHA_QUEST_ACCEPTED = "You have accepted a quest. Go complete it!"
S.MUSHA_QUEST_ABORTED = "You gave up the current quest, losing 80 experience."
S.MUSHA_QUEST_COMPLETE = "Quest complete!"
S.MUSHA_QUEST_ALL_DONE = "You have completed all advancement quests!"


-- ============================================================
-- Recall Stone (2026-09-20)
--   Hold it and use on anything to bind; right-click in inventory to return home
--   360s cooldown / 3 uses / destroyed when used up
-- ============================================================
S.NAMES.MUSHA_RECALL_STONE = "Recall Stone"
S.ACTIONS.MUSHA_RECALL_HOME = "Go Home"
S.ACTIONS.MUSHA_BIND_STONE = "Bind"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_RECALL_STONE = "A warm little stone. Show it a place and say 'here', then right-click to come back."
S.NAMES.MUSHA_RECALL_STONE_GREEN = "Recall Stone (Green Gem)"

S.NAMES.MUSHA_RABBITBACKPACK = "Rabbit Backpack"

-- ============================================================
-- ★ 2026-09-29 Job Reset Stone (test item, no recipe at all)
--   · Nothing in the crafting tab -> c_give("musha_job_reset") only
--   · Who may use it: author's SteamID / testers / local host (scripts/musha_dev_mode.lua)
-- ============================================================
S.NAMES.MUSHA_JOB_RESET = "Job Reset Stone"
S.ACTIONS.MUSHA_RESET_JOB = "Reset Job"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_JOB_RESET = "Cold as a blank save. One touch wipes job, level and skills -- only testers can hold it."
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_RABBITBACKPACK = "Fluffy, with a pair of tiny wings. Related to a certain plan."

-- ============================================================
-- ★ 2026-09-29 English batch 2: panel UI strings (STRINGS.MUSHA_PANEL)
--   Readers: screens/musha_panel_screen.lua, screens/musha_tavern_screen.lua
--   Loaded per-client by modmain based on that player's Profile language.
--   ⚠️ Keys must match chinese.lua exactly (a check script diffs the two).
--   ⚠️ Mailbox fallback logs (musha_panel_screen.lua:169-183) stay Chinese on purpose.
-- ============================================================
S.MUSHA_PANEL = {
    -- ---- Tabs / page titles ----
    TITLE_HOME = "Home",
    TITLE_SKILL = "Skills",
    TITLE_EQUIP = "Gear",
    TITLE_MAIL = "Mailbox",
    TITLE_SET = "Settings",
    TITLE_GIFT = "Gifts",
    TITLE_DEX = "Collection",
    DEX_TITLE = "Collection",
    EQUIP_HEAD = "Gear · Stats",

    -- ---- Job / common ----
    NO_JOB = "No job",
    UNKNOWN_QUEST = "Unknown quest",
    BOOL_ON = "On",
    BOOL_OFF = "Off",

    -- ---- Home: class EXP bar ----
    EXP_FMT = "Class EXP %s/%s",

    -- ---- Home: empty quest list ----
    EMPTY_TITLE = "No quests yet",
    EMPTY_HINT = "Quests unlock once you meet the job-change requirements",
    EMPTY_TAVERN_TITLE = "Pick up quests at the Hotel 》",
    EMPTY_TAVERN_HINT = "Daily commissions are taken at the hotel · Class-change scrolls come from the hotel",
    EMPTY_NOJOB_TITLE = "No job yet",
    EMPTY_NOJOB_HINT = "Use a Job Tome to start your path",

    -- ---- Quest rows ----
    QUEST_DONE = "✓ Done",
    NEED_FMT = "Requires: %s (%s/%s)",
    REWARD_EXP_FMT = "Reward: Class EXP +%s",
    REWARD_HINT = "Reward: see the quest-complete message",
    ADVANCE_FMT = "[Job Change %s/3]",
    QUEST_REQ_DEFAULT = "Complete the quest objective",
    ABANDON = "Abandon",   -- ★ 09-29 button on the expanded quest row (drops it back to the board)

    -- "What you need" labels (ty = same key as the server's QDEFS.type)
    QUEST_REQ = {
        discover       = "Travel and discover the target",
        kill_spider    = "Kill spiders",
        survive        = "Survive days",
        collect        = "Collect Nightmare Fuel",
        collect_gems   = "Collect the three gems (red/green/blue)",
        craft          = "Craft anything",
        cookpot        = "Harvest a Crock Pot",
        kill_pig       = "Kill pigs",
        kill_firehound = "Kill fire hounds",
        heal_skill     = "Use the heal skill",
        craft_science  = "Craft a Science Machine",
    },

    -- Quest names (client-side table; the server also sends q.n, but the
    -- client prefers this table so the language follows the player)
    QUEST_NAMES = {
        [1]  = "See the Dragonfly",
        [2]  = "Kill 20 spiders",
        [3]  = "Survive 5 days",
        [4]  = "Find Glommer",
        [5]  = "Get 7 Nightmare Fuel",
        [6]  = "Collect the three gems",
        [7]  = "Craft 20 items",
        [8]  = "Harvest a Crock Pot 5 times",
        [9]  = "Defeat 8 Werepigs",
        [10] = "Defeat 5 Fire Hounds",
        [11] = "Find a Walrus Camp",
        [12] = "Use the heal skill 5 times",
        [13] = "Build a Science Machine",
    },

    -- ---- Inheritance ceremony hints (server sends only a key + job keys;
    --      the client composes the sentence in its own language) ----
    CEREMONY_HINT = "Inheritance ceremony: right-click the hotel to finish",
    CEREMONY_CHOICE_FMT = "Choose a path: use the crest you are holding (%s)",

    -- ---- Skills ----
    SKILL_HEAD = "Skills",
    SKILL_HEAD_FMT = "%s · Lv %d · SP %d",
    TAB_UNLEARNED = "Not Learned",
    TAB_LEARNED = "Learned",
    SKILL_LVL_FMT = "%s Lv %d / %d",
    LBL_CURRENT = "Current: ",
    LBL_MAXED = "Maxed",
    LBL_NEXT = "Next: ",
    LBL_AFTER = "After: ",
    NEED_LEVEL_FMT = "Requires Lv.%d",
    NEED_BOOK_FMT = "Needs %d skillbook(s) to unlock",
    NEED_SP_FMT = "Costs %d skill point(s)",
    UNLOCK_HINT_FMT = "Click here (or +) to unlock with skillbooks in your bag · needs %d",
    SKILL_FOOT = "Skills learned from skillbooks · coming later",
    BTN_UPGRADE = "Upgrade",
    SKILL_EMPTY_NOJOB = "No job yet",
    SKILL_EMPTY_NONE = "No skills learned yet",
    SKILL_EMPTY_ALL = "All skills of this job are learned",

    -- ---- Horizontal skill tree (widgets/musha_skill_tree.lua) ----
    TREE_HINT = "Hold and drag to pan · the small arrows by the scroll bar work too",
    BADGE_BOOK = "Bk",
    BADGE_LOCK = "Lk",
    BADGE_MAX = "Max",
    HL_NAME_FMT = "%s (%d/%d)",
    LBL_CURRENT_UNLEARNED = "Current: not learned",
    REQ_LEVEL_FMT = "level %d",
    REQ_BOOK_FMT = "%d skillbook(s)",
    REQ_SP_FMT = "%d skill point(s)",
    LBL_PREREQ = "prereq: ",
    LBL_PREREQ_SEP = ", ",
    LBL_COND = "Requires: ",

    -- ---- Settings ----
    SET_MONSTER_SPAWN = "Monster Spawn",
    SET_SPAWN_MULT = "Spawn Multiplier",
    SET_DAILY_COUNT = "Daily Quest Count",
    SET_EXP_MULT = "EXP Multiplier",
    SET_DEBUG = "Debug Info",
    SAVE_LOG = "Save Log",
    EDIT = "Edit",
    EDITING = "Editing",

    -- ---- Gifts ----
    GIFT_HEAD = "Gifts",
    GIFT_HINT_EVENT = "Given out during holiday events · they show up here when an event is live",
    GIFT_HINT_EMPTY = "No gifts to claim right now · they show up during holiday events",
    GIFT_HINT_DAY = "Unlocks by in-game day · each one claimable once",
    GIFT_HINT_EVENT2 = "Event gift · each one claimable once",
    GIFT_DAY_FMT = "Available on day %d (%d days to go)",
    GIFT_DEFAULT = "Gift",
    CLAIMED = "Claimed",
    CLAIM = "Claim",

    -- ---- Collection ----
    DEX_TIP = "(Listed in release order · new content keeps arriving.)",
    DEX_SCOPE_WORLD = "World",
    DEX_SCOPE_PERSONAL = "Personal",

    -- ---- Hotel commission board ----
    TAVERN_TITLE = "Hotel Commissions",
    TAVERN_SUB = "Progress starts once you accept",
    TAVERN_HEAD_AVAIL = "Available",
    TAVERN_HEAD_ACT = "In Progress",
    TAVERN_FOOT = "Right-click the hotel again or click × to close",
    TAVERN_EMPTY_AVAIL = "All of today's commissions are taken",
    TAVERN_EMPTY_ACT = "No commissions accepted yet",
    TAVERN_MORE_FMT = "…%d more",
    QUEST_DEFAULT_FMT = "Quest %s",
    ACCEPT = "Accept",
    REWARD_ROW_FMT = "%s · EXP +%s · %s/3",
    Q_COMMON = "Common",
    Q_WHITE = "White",
    Q_SILVER = "Silver",
    Q_GOLD = "Gold",
}
