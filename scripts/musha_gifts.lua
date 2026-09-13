-- ============================================
-- musha_gifts.lua（2026-09-12 新建）
-- 礼包数据表 —— 面板「礼包」页读这张表；节日活动期间照常发放
--
-- 每条字段：
--   id       唯一 id（领过会记在玩家数据 pc.userdata.gifts[id]，不能重复领）
--   name     显示名
--   desc     说明（可省）
--   enabled  false → 不显示（做活动上下线用这个开关）
--   period   活动时间（预留）：
--              nil                      = 常驻可领
--              { start_day=1, end_day=10 } = 游戏内第 1~10 天（TheWorld.state.cycles）
--              以后要做真实节日（按现实月份/日期）在这里加字段 + 在 RPC 里判
--   items    发放内容 { { prefab = "xxx", count = N }, ... }
-- ============================================

return {
    -- ⚠️ 2026-09-13 用户要求：测试礼包（dev_test_gift）已删除
    --    表为空 → 面板礼包页会显示「当前没有可领取的礼包」
    --    以后要发活动礼包，照下面注释的格式加进来即可

    -- 节日活动礼包写在这里（例子；活动开始时把 enabled 改 true + 填 period）
    -- {
    --     id = "halloween_2026",
    --     name = "万圣节礼包",
    --     desc = "活动期间限定",
    --     enabled = false,
    --     period = { start_day = 1, end_day = 10 },
    --     items = {
    --         { prefab = "pumpkin", count = 3 },
    --         { prefab = "candy",   count = 5 },
    --     },
    -- },
}
