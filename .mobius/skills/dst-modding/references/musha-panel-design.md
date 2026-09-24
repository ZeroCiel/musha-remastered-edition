# Musha 职业面板设计约定（2026-09 迭代中）

文件：mods/musha/scripts/widgets/musha_panel_screen.lua（右键技能书打开；**B 键入口 2026-09-24 已移除**）
打开链路（已修通）：右键书(musha_panel tag) → 服务端 musha_action → net_bool set(true) → 客户端 mushapanelchanged → PushEvent("musha_open_skill_panel") → panel ShowPanel。**回调不能过滤 TheWorld.ismastersim**（单机/主机自己就是服务端，过滤后主机打不开）；net_bool 要 0 帧复位才能反复触发。

## 设计方向（用户拍板，勿回书页横排）

- **右侧竖版信息卡**：浅米色纸纹（bookpage_bg 原图铺底，不做半透明）+ 深棕 3px 边框
- 位置：居中锚点 + SetPosition(300, 60)，右缘距屏幕右缘留 ~480 安全距离，不压右侧 HUD 状态区/按钮
- 尺寸：360x440（紧凑），内容 360x440 逻辑区围绕 root (0,0) 排，root SetScale(1.0) 统一控制
- 结构从上到下：装饰星(左上) + 职业名大字 + Lv 小标签（同行）→ 经验条紧贴标题下（灰底轨 340px + 蓝填充，靠左增长）→ EXP 数值小字 → 任务竖列表 3 行 / 空状态"暂无任务"+弱提示"完成转职条件后开启任务"
- 关闭 ✕ 右上（透明 ImageButton 点击区 + 文字，内缩不贴边）
- **无职业弱化/有职业高亮**：无职业时职业名/星/等级/经验条全灰棕降饱和、填充淡灰；有职业时标题亮金、经验条亮蓝。用 has_job = carrer_base 非空判断，在 OnGameDataChanged 和 Refresh 两处同步

## 已踩的 UI 坑（细节见 dst-modding references/dst-api-pitfalls.md）

- ImageButton 继承 Button：无 SetSize/SetTint，用 ForceImageSize + SetImageNormalColour（透明点击区套路）
- Text/Image 无 SetHRegPoint/SetVisible：手动中心定位；Show()/Hide()
- TOP/RIGHT 锚点 + 小偏移 = 面板飞出屏幕被裁 → 居中锚点 + 大偏移

## 相关功能状态（本次会话改完）

- 转职书 musha_jobbook_warrior：用后消费旧书 + SpawnPrefab("musha_skillbook") 发新书（图标统一 musha_skillbook），不再 SetPrefabName 原地改造（改造不持久化，重进丢行为）
- 一转完成 CompleteAdvance：原来 6 个进阶书 prefab 从未注册发不出去 → 统一发 musha_skillbook
- 任务系统审计见 mods/musha/musha-backlog.md（4 个卡死任务 handler 无调用点 + OnAreaTrigger 未定义）
