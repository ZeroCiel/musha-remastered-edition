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
S.NAMES.MUSHA_ADVANCE_ALTAR = "Tavern"
S.NAMES.MUSHA_ADVANCE_SCROLL = "Advance Scroll"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_ADVANCE_SCROLL = "An ancient scroll taken from the tavern. Unroll it to accept the trial."
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
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_ADVANCE_ALTAR = "A lively tavern where every job-change trial is taken."
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
S.ACTIONS.MUSHA_OPEN_ALTAR = "Enter Tavern"          -- 2026-09-17: was MUSHA_QUEST_INTERACT ("View Quest")
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
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_RABBITBACKPACK = "Fluffy, with a pair of tiny wings. Related to a certain plan."
