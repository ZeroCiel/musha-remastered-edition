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
--
-- ★ 2026-09-24 双语：加 file_en = 英文版横幅（从 图片/UI_en.png 按 2列3行切出）
--   - 有 file_en 的行：英文玩家看到 nav_xxx_en.tex，中文玩家看到 file
--   - 没有 file_en 的行（equip）：两种语言都用 file
--   - modmain 注册时**两种语言都注册**（assets 在语言判定之前跑），面板构造时才按
--     TUNING.MUSHA_UI_LANG 挑。所以只要 tex/xml 在，切语言就有图。
--   - 英文版只有横幅（整颗按钮），中文版同理 → 两侧走同一套渲染，不会中英不一致。
-- ================================================================
return {
    { key = "home",  file = "nav_home",  file_en = "nav_home_en"  },   -- 主页：房子 / Home
    { key = "skill", file = "nav_skill", file_en = "nav_skill_en" },   -- 技能：魔法书 / Skills
    { key = "equip", file = "nav_equip"  },                            -- 装备：胸甲（无英文版，双语共用）
    { key = "mail",  file = "nav_mail",  file_en = "nav_mail_en"  },   -- 信箱：信封 / Mailbox
    { key = "set",   file = "nav_set",   file_en = "nav_set_en"   },   -- 设置：齿轮 / Settings
    { key = "gift",  file = "nav_gift",  file_en = "nav_gift_en"  },   -- 礼包：礼物盒 / Gift Pack
    { key = "dex",   file = "nav_dex",   file_en = "nav_dex_en"   },   -- 图鉴：书 / Gallery
}
