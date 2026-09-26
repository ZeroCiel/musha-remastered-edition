name = "Musha 0.7.9 职业系统重制版"
description = "Musha 职业系统重制版 — 雪儿 (Ciel)"
author = "Ciel (雪儿)"
version = "0.7.11"

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
