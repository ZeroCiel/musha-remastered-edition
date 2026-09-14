-- ================================================================
-- 导航图标清单（唯一真源）—— 2026-09-13
--   modmain.lua（注册 assets）和 scripts/screens/musha_panel_screen.lua（画图标）都读这里
--
-- 用法：打包好哪一张 tex，哪一行就留着；没打包的先用 -- 注释掉，
--       那一行导航就只显示文字（不会报错、不会空一块）。
--
-- 打包做法：用你的贴图工具把 images/nav_xxx.png 转成
--           images/nav_xxx.tex + images/nav_xxx.xml（做法同 bookpage_bg）
--   ⚠️ png 文件名必须是 ASCII：中文名转出来的 xml 是空的（工具不认中文名）
--   ⚠️ 转完 tex/xml 之后必须重启游戏（assets 只在开游戏时加载一次）
-- ================================================================
return {
    { key = "home",  file = "nav_home"  },   -- 主页：房子
    { key = "skill", file = "nav_skill" },   -- 技能：枝干
    { key = "equip", file = "nav_equip" },   -- 装备：胸甲
    { key = "mail",  file = "nav_mail"  },   -- 信箱：信封
    { key = "set",   file = "nav_set"   },   -- 设置：齿轮
    { key = "gift",  file = "nav_gift"  },   -- 礼包：礼物盒
    { key = "dex",   file = "nav_dex"   },   -- 图鉴：放大镜
}
