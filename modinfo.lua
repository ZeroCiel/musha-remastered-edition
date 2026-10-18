name = "Musha 0.7.13 职业系统重制版"
-- ★ 2026-10-04 扩写（用户「7 件点头事项…起」）：只写核实过的事实，不写职业数/技能树数（没查到表）
--   红线已避开：不提战力数值、不提 VIP/强化、不点元素精灵名、不摆对抗、无比喻实词
description = "Musha 职业系统重制版 — 雪儿 (Ciel)。转职任务与每日委托、技能树加点与图鉴面板；界面支持中文 / English / 日本語。全部玩法内容永久免费。"
author = "Ciel (雪儿)"
version = "0.7.13"

forumthread = ""

api_version = 10

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
hamlet_compatible = false

all_clients_require_mod = false

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = {
    "musha",
    "class",
    "rpg",
}

-- 配置选项
configuration_options = {
    {
        name = "musha_rest_enabled",
        label = "启用休息技能",
        hover = "开启后所有职业可以使用「休息」技能（怀旧功能）",
        options = {
            { description = "关闭", data = false },
            { description = "开启", data = true },
        },
        default = false,
    },
    {
        name = "musha_show_class_skin",
        label = "显示职业皮肤",
        hover = "开启后角色会根据部分职业显示专属皮肤（需房主设置）",
        options = {
            { description = "关闭", data = false },
            { description = "开启", data = true },
        },
        default = false,
    },
    {
        name = "musha_daily_quest_count",
        label = "每日任务数量",
        hover = "每天发放的日常任务数（3=悠闲，4=标准，5=充实）",
        options = {
            { description = "悠闲 (3)", data = 3 },
            { description = "标准 (4)", data = 4 },
            { description = "充实 (5)", data = 5 },
        },
        default = 4,
    },
}
