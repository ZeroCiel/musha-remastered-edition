-- ============================================================
-- 物品图标清单（唯一真源）—— 2026-09-20
--
--   谁在用：
--     1) modmain.lua 的 Safe("物品图标 assets") —— 把这些图集**全局声明**进 mod 的 Assets
--     2) 以后加新物品图标：把 images/inventoryimages/<图标名>.xml + .tex 放进去，
--        再往下面清单里加一行就完事（缺文件的会被自动跳过，不会崩 mod）
--
--   为什么必须全局声明（而不是只在各自 prefab 的 assets 里）：
--     · Too Many Items(TMI+) 这类辅助 mod 扫的是 **mod 级 Assets** 里所有含 ".xml" 的路径，
--       然后用 TheSim:AtlasContains(xml, "<prefab名>.tex") 找图标 →
--       只在 prefab 的 assets 里声明它扫不到，物品图标就不显示。
--     · 顺带保证纯客户端也一定提前加载到这些图集。
--
--   名字规则（TMI 的约定）：图标里的 image 名必须 == **prefab 名**。
--     images/inventoryimages/musha_mailbox.xml 里的元素名必须是 musha_mailbox.tex
--     prefab 叫 musha_mailbox → 名字对上 → TMI 就能显示。
-- ============================================================

return {
    "book_skill",
    "fangzhi",
    "mage_tome",
    "musha_advance_altar",
    "musha_advance_scroll",
    "musha_jobbook_mage",
    "musha_jobbook_ranger",
    "musha_jobbook_rogue",
    "musha_jobbook_warrior",
    "musha_lifebranch",
    "musha_mailbag",
    "musha_mailbox",
    "musha_note",
    "musha_recall_stone",
    "musha_skill_scroll",
    "musha_skillbook",
    "musha_skillbook_saber",
    "musha_sword",
    "ranger_tome",
    "rogue_tome",
    "warrior_tome",
}
