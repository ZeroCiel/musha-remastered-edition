-- Musha 0.7.13 — 日本語 (Japanese) Language File
-- ★ 2026-10-02 日语界面批：新建本文件（台词另有 speech_musha_jp.lua，早就位）
--   · key 与 chinese.lua / english.lua 一一对应（102 个 S.* key + STRINGS.NAMES.musha）
--   · 注释保持中文（与 english.lua 同惯例），只译值
--   · 酒馆按用户「名实分离」口径 = 英文直译 Hotel → 日语同用「ホテル」

local S = GLOBAL.STRINGS

-- 物品名称
S.NAMES.MUSHA_SWORD = "剣"
S.NAMES.MUSHA_LIFEBRANCH = "生命の枝"
S.NAMES.MUSHA_SKILLBOOK = "スキルブック"
S.NAMES.MUSHA_SKILL_SCROLL = "スキルの巻物"
S.NAMES.MUSHA_NOTE = "メモ"
S.NAMES.MUSHA_JOBBOOK = "転職書"
S.NAMES.MUSHA_JOBBOOK_WARRIOR = "転職書（戦士）"
-- ✅ 2026-09-17 发布前：测试专用转职书已下架 → S.NAMES.MUSHA_JOBBOOK_SABER = "剣士転職書（テスト）"
S.NAMES.MUSHA_BOOK_UNKNOWN = "よく分からない本"
S.NAMES.MUSHA_JOBBOOK_MAGE = "メイジ転職書"
S.NAMES.MUSHA_JOBBOOK_RANGER = "レンジャー転職書"
S.NAMES.MUSHA_JOBBOOK_GUARDIAN = "ガーディアン転職書"
S.NAMES.MUSHA_JOBBOOK_ASSASSIN = "アサシン転職書"
S.NAMES.MUSHA_ADVANCE_ALTAR = "ホテル"   -- ★ 用户：英文直译 hotel（名实分离）→ 日语同口径
S.NAMES.MUSHA_ADVANCE_SCROLL = "転職の巻物"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_ADVANCE_SCROLL = "ホテルの奥から取り出した古い巻物。広げて試練を受けよう。"
S.NAMES.MUSHA_SKILLBOOK_SWORDSMAN = "ソードマンの基礎スキルブック"
S.NAMES.MUSHA_SKILLBOOK_GUARDIAN = "ガーディアンの基礎スキルブック"
S.NAMES.MUSHA_SKILLBOOK_ALCHEMIST = "アルケミストの基礎スキルブック"
S.NAMES.MUSHA_SKILLBOOK_ELEMENTALIST = "エレメンタリストの基礎スキルブック"
S.NAMES.MUSHA_SKILLBOOK_BARD = "バードの基礎スキルブック"
S.NAMES.MUSHA_SKILLBOOK_MOONSHADOW = "ムーンシャドウの基礎スキルブック"
S.NAMES.MUSHA_REST_ITEM = "休憩"

-- 物品描述
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_JOBBOOK_WARRIOR = "戦士の道を記した本。読むと職業が戦士になる。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_JOBBOOK_MAGE = "メイジの道を記した本。読むと職業がメイジになる。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_JOBBOOK_RANGER = "レンジャーの道を記した本。読むと職業がレンジャーになる。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_JOBBOOK_ASSASSIN = "アサシンの道を記した本。読むと職業がアサシンになる。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_ADVANCE_ALTAR = "古いホテル。そこには先へ進む力を秘めた場所がある。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK_SWORDSMAN = "ソードマンの基礎スキルを記した本。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK_GUARDIAN = "ガーディアンの基礎スキルを記した本。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK_ALCHEMIST = "アルケミストの基礎スキルを記した本。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK_ELEMENTALIST = "エレメンタリストの基礎スキルを記した本。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK_BARD = "バードの基礎スキルを記した本。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK_MOONSHADOW = "ムーンシャドウの基礎スキルを記した本。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SWORD = "重い職業用の剣。薄く寒い光を放っている。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_LIFEBRANCH = "まだ生きている枝。握るとあたたかく、何かが芽吹いている感触がする。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK = "色褪せた本。あなたの職業スキルが記されている。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILL_SCROLL = "基本スキルの心得を記した巻物。広げるとその中のスキルを習得できる。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_REST_ITEM = "右クリックで休憩状態を切り替える。"

-- 角色选人界面
S.CHARACTER_TITLES.musha = "冒険者"
S.CHARACTER_NAMES.musha = "ミューシャ"
S.CHARACTER_DESCRIPTIONS.musha = "*最初に案内のメモを持参\n*複数の方向に成長できる\n*レベルが高いほど強くなる"
S.CHARACTER_QUOTES.musha = "\"私の実力、見せてあげる。\""
STRINGS.NAMES.musha = "ミューシャ"

-- 动作名称
S.ACTIONS.MUSHA_USE_JOBBOOK = "転職"
S.ACTIONS.MUSHA_USE_JOBBOOK_STR = {
    -- ⚠️ 这三个 key 是**查找键**（musha_actions.lua:26 用中文 key 取值），不能改，只译值
    ["转职"] = "転職",
    ["使用"] = "使用",
    ["未知"] = "不明",
}
S.ACTIONS.MUSHA_OPEN_ALTAR = "ホテルを開く"          -- 2026-09-17：原 MUSHA_QUEST_INTERACT("查看任务")，祭坛改成容器后重命名
S.ACTIONS.MUSHA_UNROLL_SCROLL = "巻物を広げる"      -- 2026-09-17：转职卷轴（祭坛里取出来的）
-- ★ 2026-09-18 进阶方向徽记（就职仪式发两枚：剑士 / 近卫；用掉一枚 = 选定方向，不可更改）
S.ACTIONS.MUSHA_USE_CREST = "紋章を使う"
-- ★ 2026-09-19 邮包系统（信箱 + 信差包）
S.ACTIONS.MUSHA_OPEN_MAILBOX = "触れる"
S.ACTIONS.MUSHA_PUT_MAILBOX = "郵便箱に入れる"
S.ACTIONS.MUSHA_OPEN_MAILBOX_STR = {
    UPGRADE = "アップグレード",
    BIND    = "触れる（紐付け）",
    OPEN    = "触れる（開く）",
}
S.ACTIONS.MUSHA_OPEN_MAILBAG = "配達バッグを開く"
S.NAMES.MUSHA_MAILBOX = "郵便箱"
S.NAMES.MUSHA_MAILBAG = "配達バッグ"
S.NAMES.MUSHA_MAILKIT_1 = "郵便アップグレードキット I（受信箱 3→5 マス）"
S.NAMES.MUSHA_MAILKIT_2 = "郵便アップグレードキット II（受信箱 5→7 マス）"
S.NAMES.MUSHA_MAILKIT_3 = "郵便アップグレードキット III（受信箱 7→9 マス）"
S.NAMES.MUSHA_MAILKIT_4 = "郵便アップグレードキット IV（受信箱 9→12 マス）"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_MAILBOX = "初めて触ると、受信箱がここに置かれる。それ以降はずっとここにいる。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_MAILBAG = "中に物を入れて閉じれば、勝手に家まで帰っていく。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_MAILKIT_1 = "持ちながら郵便箱に「アップグレード」と言えばいい。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_MAILKIT_2 = "持ちながら郵便箱に「アップグレード」と言えばいい。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_MAILKIT_3 = "持ちながら郵便箱に「アップグレード」と言えばいい。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_MAILKIT_4 = "持ちながら郵便箱に「アップグレード」と言えばいい。"
S.NAMES.MUSHA_CREST_SABER = "ソードマンの紋章"
S.NAMES.MUSHA_CREST_GUARDIAN = "ガーディアンの紋章"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_CREST_SABER = "剣の紋様が刻まれた紋章。使うとソードマンになる——方向は変更できない。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_CREST_GUARDIAN = "盾の紋様が刻まれた紋章。使うとガーディアンになる——方向は変更できない。"
S.ACTIONS.MUSHA_LEARN_SKILL = "スキルを学ぶ"
S.ACTIONS.MUSHA_REST = "休憩"
S.ACTIONS.MUSHA_OPEN_PANEL = "パネルを開く"
S.ACTIONS.MUSHA_READ_NOTE = "読む"

-- 系统消息
S.MUSHA_JOB_USE_NO_SYSTEM = "職業システムのサポートがない…"
S.MUSHA_JOB_USE_ALREADY_HAS = "もう職業を選んでいる！"
S.MUSHA_JOB_USE_WARRIOR = "職業を戦士に転職した"
S.MUSHA_JOB_USE_NO_JOB = "まだ職業を選んでいない！"

-- 职业名称
S.MUSHA_JOB_WARRIOR = "戦士"
S.MUSHA_JOB_MAGE = "メイジ"
S.MUSHA_JOB_RANGER = "レンジャー"
S.MUSHA_JOB_ASSASSIN = "アサシン"
S.MUSHA_JOB_SWORDSMAN = "ソードマン"
S.MUSHA_JOB_SABER = "ソードマン"        -- 代码里的树名是 saber（组件 self.saber），补个别名给技能页显示用
S.MUSHA_JOB_GUARDIAN = "ガーディアン"
S.MUSHA_JOB_ALCHEMIST = "アルケミスト"
S.MUSHA_JOB_ELEMENTALIST = "エレメンタリスト"
S.MUSHA_JOB_BARD = "バード"
S.MUSHA_JOB_MOONSHADOW = "ムーンシャドウ"
S.MUSHA_JOB_NONE = "職業なし"

-- 任务消息
S.MUSHA_QUEST_ACCEPTED = "任務を受け取った。こなそう！"
S.MUSHA_QUEST_ABORTED = "今の任務を放棄した。経験値を 80 失った。"
S.MUSHA_QUEST_COMPLETE = "任務完了！"
S.MUSHA_QUEST_ALL_DONE = "転職任務はすべて完了した！"


-- ============================================================
-- 回城石（2026-09-20 用户需求）
--   拿在手上对任何东西用 = 绑定它；背包里右键石头 = 回家
--   冷却 360 秒 / 可用 3 次 / 用完自毁
-- ============================================================
S.NAMES.MUSHA_RECALL_STONE = "帰還石"
S.ACTIONS.MUSHA_RECALL_HOME = "帰る"
S.ACTIONS.MUSHA_BIND_STONE = "紐付ける"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_RECALL_STONE = "あたたかい石。持ちながら場所に「ここだ」と言えば、あとで右クリックで帰れる——道も人も覚えていてくれる。"
-- 第二条配方（绿宝石版）在合成栏里单独列一条，名字区分开
S.NAMES.MUSHA_RECALL_STONE_GREEN = "帰還石（エメラルド）"

S.NAMES.MUSHA_RABBITBACKPACK = "うさぎバックパック"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_RABBITBACKPACK = "ふわふわで、小さな翼がついている。どこかの計画と関係があるらしい。"

-- ============================================================
-- ★ 2026-09-29 职业重置石（测试道具，用户："不开放任何制作条件"）
--   · 合成栏里**没有配方** → 只能 c_give("musha_job_reset")
--   · 使用权限：作者 SteamID / 测试安全员 / 本地房主模式（scripts/musha_dev_mode.lua）
-- ============================================================
S.NAMES.MUSHA_JOB_RESET = "職業リセット石"
S.ACTIONS.MUSHA_RESET_JOB = "職業をリセット"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_JOB_RESET = "空白のセーブデータのように冷たい。触ると職業・レベル・スキルがすべてゼロになる——テスト担当しか使えない。"

-- ============================================================
-- ★ 2026-10-02 日语批：面板 UI 文案表（STRINGS.MUSHA_PANEL）
--   读取方：screens/musha_panel_screen.lua、screens/musha_tavern_screen.lua
--   ⚠️ 三份语言文件的 key 必须一一对应（chinese / english / japanese）
--   ⚠️ 信箱兜底日志（musha_panel_screen.lua:169-183）按用户口径保持中文，不进本表
--   ⚠️ 技能正文 / 导航横幅 / 礼包内容 / 更新日志走 *_en 回退（UIIsEN：非中文 = 英文）
--     → 日语界面 = 本表日语 + 技能/横幅/内容英语（要日语技能正文需另开一批）
-- ============================================================
S.MUSHA_PANEL = {
    -- ---- 页签 / 页内标题 ----
    TITLE_HOME = "ホーム",
    TITLE_SKILL = "スキル",
    TITLE_EQUIP = "装備",
    TITLE_MAIL = "ポスト",
    TITLE_SET = "設定",
    TITLE_GIFT = "ギフト",
    TITLE_DEX = "図鑑",
    DEX_TITLE = "図鑑",
    EQUIP_HEAD = "装備 · 能力",

    -- ---- 职业 / 通用 ----
    NO_JOB = "職業なし",
    UNKNOWN_QUEST = "不明な任務",
    BOOL_ON = "オン",
    BOOL_OFF = "オフ",

    -- ---- 主页：经验条 ----
    EXP_FMT = "職業経験 %s/%s",

    -- ---- 主页：任务区空状态 ----
    EMPTY_TITLE = "任務なし",
    EMPTY_HINT = "転職の条件を満たすと任務が解放される",
    EMPTY_TAVERN_TITLE = "ホテルで関連任務を受け取って 》",
    EMPTY_TAVERN_HINT = "毎日の依頼はホテルで受注 · 転職任務はホテルで巻物を受け取る",
    EMPTY_NOJOB_TITLE = "職業なし",
    EMPTY_NOJOB_HINT = "職業書で職業の道を始めよう",

    -- ---- 任务行 ----
    QUEST_DONE = "✓ 完了",
    NEED_FMT = "必要：%s（%s/%s）",
    REWARD_EXP_FMT = "報酬：職業経験 +%s",
    REWARD_HINT = "報酬：任務完了のメッセージを参照",
    ADVANCE_FMT = "【転職%s/3】",
    QUEST_REQ_DEFAULT = "任務目標を達成する",
    ABANDON = "放棄",   -- ★ 09-29 任务详情子行右端按钮（点了把任务丢回酒馆）

    -- "需要什么"文案（ty = 服务端 QDEFS.type 同源 key）
    QUEST_REQ = {
        discover       = "目標地点へ向かう",
        kill_spider    = "クモを倒す",
        survive        = "生存日数",
        collect        = "ナイトメア燃料を集める",
        collect_gems   = "3色のジェムを集める（赤/緑/青）",
        craft          = "何かを1つ作る",
        cookpot        = "料理鍋を回収",
        kill_pig       = "ブタ人を倒す",
        kill_firehound = "ファイアハウンドを倒す",
        heal_skill     = "回復スキルを使う",
        craft_science  = "科学機械を作る",
    },

    -- 任务名（面板本地表；服务端也发 q.n，客户端优先用本表 → 语言跟人走）
    QUEST_NAMES = {
        [1]  = "ドラゴンフライに会う",
        [2]  = "クモを20匹倒す",
        [3]  = "5日間生き残る",
        [4]  = "グロムを見つける",
        [5]  = "ナイトメア燃料を7個入手する",
        [6]  = "3色のジェムを集める",
        [7]  = "アイテムを20個作る",
        [8]  = "料理鍋を5回回収する",
        [9]  = "ワーギを8匹倒す",
        [10] = "ファイアハウンドを5匹倒す",
        [11] = "アザラシの野営地を見つける",
        [12] = "回復スキルを5回使う",
        [13] = "科学機械を1台建てる",
    },

    -- ---- 就职仪式提示（服务端只发 key + 职业 key 列表，客户端本地拼）----
    CEREMONY_HINT = "就職式：ホテルに戻って右クリックで完了",
    CEREMONY_CHOICE_FMT = "方向を決める：手持ちの紋章を使う（%s）",

    -- ---- 技能页 ----
    SKILL_HEAD = "スキル",
    SKILL_HEAD_FMT = "%s · レベル %d · 使用可能スキルポイント %d",
    TAB_UNLEARNED = "未習得",
    TAB_LEARNED = "習得済み",
    SKILL_LVL_FMT = "%sレベル %d / %d",
    LBL_CURRENT = "現在：",
    LBL_MAXED = "最大レベル",
    LBL_NEXT = "次のレベル：",
    LBL_AFTER = "習得後：",
    NEED_LEVEL_FMT = "必要 Lv.%d",
    NEED_BOOK_FMT = "解放にスキルブック %d 冊が必要",
    NEED_SP_FMT = "スキルポイント %d を消費",
    UNLOCK_HINT_FMT = "ここ（または +）をクリックして、バッグのスキルブックで解放 · 必要 %d 冊",
    SKILL_FOOT = "スキルブックで覚えるスキル · 今後追加",
    BTN_UPGRADE = "強化",
    SKILL_EMPTY_NOJOB = "まだ職業がない",
    SKILL_EMPTY_NONE = "まだスキルを習得していない",
    SKILL_EMPTY_ALL = "この職業のスキルはすべて習得済み",

    -- ---- 横排技能树（widgets/musha_skill_tree.lua）----
    TREE_HINT = "空白部分を押したまま左右にドラッグ · スクロールバー両端の矢印でも可",
    BADGE_BOOK = "本",
    BADGE_LOCK = "鍵",
    BADGE_MAX = "満",
    HL_NAME_FMT = "%s（%d/%d）",
    LBL_CURRENT_UNLEARNED = "現在：未習得",
    REQ_LEVEL_FMT = "キャラクターレベル %d",
    REQ_BOOK_FMT = "スキルブック %d 冊",
    REQ_SP_FMT = "スキルポイント %d",
    LBL_PREREQ = "前提：",
    LBL_PREREQ_SEP = "、",
    LBL_COND = "条件：",

    -- ---- 设置页 ----
    SET_MONSTER_SPAWN = "モンスター出現",
    SET_SPAWN_MULT = "出現倍率",
    SET_DAILY_COUNT = "毎日の任務数",
    SET_EXP_MULT = "経験値倍率",
    SET_DEBUG = "デバッグ情報",
    SAVE_LOG = "ログ保存",
    EDIT = "編集",
    EDITING = "編集中",

    -- ---- 礼包页 ----
    GIFT_HEAD = "ギフト",
    GIFT_HINT_EVENT = "イベント期間中に配布 · イベントがあるとここに表示される",
    GIFT_HINT_EMPTY = "現在受け取れるギフトはない · イベント期間にここへ表示される",
    GIFT_HINT_DAY = "ゲーム内の日数で解放 · 各個つき1回だけ",
    GIFT_HINT_EVENT2 = "イベントギフト · 各個つき1回だけ",
    GIFT_DAY_FMT = "第 %d 日に受取可（あと %d 日）",
    GIFT_DEFAULT = "ギフト",
    CLAIMED = "受取済み",
    CLAIM = "受け取る",

    -- ---- 图鉴页 ----
    DEX_TIP = "（図鑑は公開順に並ぶ · 新しい内容は順次追加される）",
    DEX_SCOPE_WORLD = "世界",
    DEX_SCOPE_PERSONAL = "個人",

    -- ---- 酒馆委托板 ----
    TAVERN_TITLE = "ホテルの依頼",
    TAVERN_SUB = "「受注」を押してから進捗が計測される",
    TAVERN_HEAD_AVAIL = "受注可能な依頼",
    TAVERN_HEAD_ACT = "進行中",
    TAVERN_FOOT = "もう一度ホテルを右クリックするか × で閉じる",
    TAVERN_EMPTY_AVAIL = "今日の依頼はすべて受注済み",
    TAVERN_EMPTY_ACT = "受注中の依頼はない",
    TAVERN_MORE_FMT = "…あと %d 件",
    QUEST_DEFAULT_FMT = "任務%s",
    ACCEPT = "受注",
    REWARD_ROW_FMT = "%s · 経験 +%s · %s/3",
    Q_COMMON = "普通",
    Q_WHITE = "白",
    Q_SILVER = "銀",
    Q_GOLD = "金",
}
