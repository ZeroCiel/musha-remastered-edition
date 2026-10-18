-- ============================================
-- musha_gifts.lua（2026-09-12 新建；2026-09-14 改双轨）
-- 礼包数据表 —— 面板「礼包」页读这张表；服务端 RPC 按同一张表校验
--
-- ★★ 两类礼包（用户 2026-09-14 定）★★
--   ① 游戏时间礼包  kind = "cycle"
--        · 按【游戏内天数】解锁（TheWorld.state.cycles）
--        · 礼包页【常显】：没到天数也看得见，只是按钮位显示"第 X 天可领（还差 N 天）"，点不了
--        · 字段 day = 第几天开放
--   ② 节日礼包      kind = "festival"
--        · 按【现实日期】窗口，例：国庆 10-01 ~ 10-07
--        · 只在窗口内【出现】在礼包页；窗口外连行都不显示
--        · 字段 from / to = "YYYY-MM-DD"（**本机时间**，含首尾两天）
--   ③ 不写 kind = 常驻礼包（一直在、随时能领）—— 老行为，留着备用
--
-- 其余字段：
--   id       唯一 id（领过会记在玩家数据 pc.userdata.gifts[id]，不能重复领）
--   name     显示名
--   desc     说明（可省）
--   enabled  false → 不显示（活动上下线用这个开关）
--   items    发放内容 { { prefab = "xxx", count = N }, ... }
-- ============================================

return {
    ---------------------------------------------------------------
    -- ① 游戏时间礼包（按游戏内天数；常显 + 没到天数锁住）
    --    数值表见 musha-dayrewards-plan.md
    ---------------------------------------------------------------
    {
        id = "day_01", kind = "cycle", day = 1,
        name = "开荒礼",       name_en = "Starter Gift",
        desc = "游戏内第 1 天", desc_en = "In-game day 1",
        items = { { prefab = "redgem", count = 2 } },
    },
    {
        id = "day_03", kind = "cycle", day = 3,
        name = "生命护符",     name_en = "Life Amulet",
        desc = "游戏内第 3 天", desc_en = "In-game day 3",
        items = { { prefab = "amulet", count = 1 } },
    },
    {
        id = "day_10", kind = "cycle", day = 10,
        name = "生命树枝",      name_en = "Life Branch",
        desc = "游戏内第 10 天", desc_en = "In-game day 10",
        items = { { prefab = "musha_lifebranch", count = 1 } },
    },
    -- 还没做（物品的贴图/机制缺，先挂着；做好把注释去掉即可）
    -- { id = "day_16", kind = "cycle", day = 16, name = "能量水晶", desc = "游戏内第 16 天",
    --   items = { { prefab = "??", count = 1 } } },
    -- { id = "day_30", kind = "cycle", day = 30, name = "完最后一程 · 水晶剑", desc = "游戏内第 30 天",
    --   items = { { prefab = "??", count = 1 } } },

    ---------------------------------------------------------------
    -- ② 节日礼包（按现实日期；只在窗口内出现）
    --    国庆 = 10/01 ~ 10/07（跨到别的节日：复制一条改 id/from/to/名字）
    ---------------------------------------------------------------
    {
        id = "national_day_2026", kind = "festival",
        from = "2026-10-01", to = "2026-10-07",
        name = "国庆礼包",                name_en = "National Day Gift",
        desc = "10 月 1 日 — 10 月 7 日限定", desc_en = "Oct 1 — Oct 7 only",
        items = {
            { prefab = "redgem", count = 3 },   -- ⚠️ 内容待你定，先占位
        },
    },
}
