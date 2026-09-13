# chdemu — 彩虹岛开源模拟器

**位置**: `D:\chdemu\` (clone from https://github.com/gmsj0001/chdemu)

**性质**: 这是一个**独立的第三方彩虹岛模拟器**，不是官方服务端源码，也不是"他乡彩虹岛"服务端的源码。它用 C++ 重写了网络层和游戏逻辑，不依赖任何官方的服务端代码。

## 关键差异

| 方面 | chdemu | 他乡彩虹岛服务端 |
|------|--------|----------------|
| 基础 | 从零编写的模拟器 | 基于泄漏的官方 LataleServer 源码 |
| 加密 | 无加密模块 | 有 Cipher 加密层 (Cipher_Mode 0-3) |
| 协议 | 自定义简化协议 | 官方原始协议 |
| 数据库 | SQLite | SQL Server (JSQL2008) |
| 文件数 | 17 个 .cpp | 数百个 .cpp + 依赖库 |
| CHDS | 无 | 有 CHDS.dll 硬编码 IP 校验 |

## 对我们的帮助

chdemu 的 **Network.cpp** 和 **Handler.cpp** 可以作为了解彩虹岛网络包格式的参考，但不能直接替换或补丁到我们的服务端中。它的协议实现是独立编写的，可能不兼容我们的客户端。

## 项目结构

```
chdemu/
  chdemu.sln       — VS 解决方案
  chdemu.vcxproj   — 项目文件（单项目）
  PacketSniffer/   — 网络抓包工具
  src/
    Main.cpp       — 入口
    Network.cpp    — 网络层
    Handler.cpp    — 协议处理
    GameWorld.cpp  — 游戏世界
    Player.cpp     — 玩家
    Item.cpp       — 物品
    Skill.cpp      — 技能
    Quest.cpp      — 任务
    Stage.cpp      — 地图/关卡
    DataBase.cpp   — 数据库
    Common.cpp     — 公共工具
```

## 结论

chdemu 不是我们需要的"美服源码"。如果真的需要官方源码参考，应该找泄露的 LataleServer 完整源码（通常包含 LataleGameServer、LataleLoginServer、LataleMgmtServer 等项目）。
