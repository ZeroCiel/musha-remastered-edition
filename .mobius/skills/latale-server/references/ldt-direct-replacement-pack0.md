# LDT 直接替换与 Pack=0 模式

## 背景

服务端有两种模式读取 LDT 资源：

- **Pack=1**（默认）：从 SPF 包文件读取（`ResourceDir` 下的 `*.SPF`）
- **Pack=0**：直接从目录读取（`ResourceDir\DATA\LDT\*.LDT`）

Pack=0 模式下，服务端忽略所有 SPF，直接读文件夹下的 .LDT 文件。这跟 Pack=1 读 SPF 里解出来的 LDT 是**同一个格式**。

## 配置方法

configure.ini 中每个服务段 (`[LataleAS]`, `[LataleLobbyServer]`, `[LataleGameServer_101]` 等) 都有各自的 `ResourceDir` 和 `Pack` 配置。

要切换为目录模式：

```ini
ResourceDir = D:\Server\SPF\ROWID\
Pack = 0
```

注意：
- ResourceDir 指向 SPF 解包目录的根
- 服务端会去 `{ResourceDir}\DATA\LDT\` 找 .LDT 文件
- 每个服务段都要改（全局段也会影响部分服务）
- 切忌只看一段就以为全改了——configure.ini 里有 10+ 段各自独立

## LDT 文件格式（源码逆向验证通过）

从 `SPLDTFile.h` 确认的结构：

```c
struct LDT_Header {
    long    nDB_ID;           // 4字节 (通常=0)
    long    nFields;          // 4字节 (字段数)
    long    nData;            // 4字节 (数据行数)
    LDT_STR64 FieldNAM[128];  // 128 * 64 = 8192字节 (字段名)
    long    FieldTYP[128];    // 128 * 4 = 512字节 (字段类型)
};
// 总头部大小 = 12 + 8192 + 512 = 8716字节（固定）
```

- 字段类型：0=NA, 1=String, 2=TF, 3=Num, 4=Per, 5=FID, 6=Alias, 7=Num64
- 字段名：64字节定长，null终止符+空格填充
- 字段类型：32位int数组，只有前 nFields 个有效
- 数据区：从偏移 8716 开始
  - 每行第一个字段是 PrimaryKey (int32，从1开始)
  - 后续字段按 FieldTYP 顺序解析：
    - NA/TF/Num/FID: 固定 4 字节
    - Float: 固定 4 字节
    - String/Alias: 2 字节长度前缀 + 变长数据（EUC-KR 编码）
    - Num64: 固定 8 字节
- **无加密**：源码中 LoadLDTFile 直接读二进制，0行解密/校验代码
- **无版本校验**：服务端不检查 LDT 的版本号或指纹
- 编码：字符串字段为 EUC-KR (CP949)

## Pack=0 替换策略

### 验证流程

1. **先解包一个完整的 SPF 到目录**（用 SFP v1.6 或 LaTaleTools）
2. **改 ResourceDir 指向解包目录 + Pack=0**
3. **先启动最轻量的服务测试**（AS 最好，依赖最少）
4. 如果 AS 能启动，逐步启动其他服务
5. 如果不认，看 console 输出在哪里崩——LDT 加载失败会有 `xxx.LDT : FAILED!` 日志

### 常见崩溃原因

| 现象 | 原因 |
|------|------|
| 服务闪退、无输出 | ResourceDir 路径不存在 |
| `GLOBAL_SYS.LDT : FAILED!` | GLOBAL_SYS.LDT 不在 `{ResourceDir}\DATA\LDT\` 下 |
| `CDivisionInfoList::Init()` 后 getchar 阻塞 | Division/PVP 相关 LDT 加载失败（旧版 exe 有这问题） |
| 服务启动但端口不绑定 | SPF 加密校验——旧版他乡 exe 可能在校验 SPF 的哈希/签名 |
| 客户端连上但功能异常 | LDT 内 ID 索引不匹配 |

### 关键限制

这个替换策略的前提是：**旧版他乡 exe 的 Pack=0 实现没有额外校验**。有些魔改版 exe 可能在 Pack=0 路径中也嵌入了他自己的解密/校验逻辑。验证的唯一方法是：实际操作 → 看启动时崩不崩。

## 与 SFP 工具重打包的关系

如果 Pack=0 可以直接跑解包目录，那就不需要 SFP 重打包了——直接改目录下的 LDT 文件，重启服务即生效。

如果旧版 exe 的 Pack=0 路径有坑（如他只支持 Pack=1），那就必须用 SFP v1.6 重打包 SPF。

## 已验证的 LDT 文件（从 ROWID.SPF 解包）

位置：SFP v1.6 解包 `D:\Backup\Documents\ROWID\DATA\LDT\` 包含 200+ 个 LDT。
已验证格式正确（业务数据完整，非空壳）：ACHIEVE.LDT (32 fields, 200 rows)。

典型文本字段（可汉化）：
- GLOBAL_STRING.LDT — 全局 UI 文本
- CASH_SHOP.LDT — 商城商品名
- MAP_INFO.LDT — 地图名
- WORLD_MAP_STAGE.LDT — 世界地图名称/描述
- QUEST*.LDT — 任务文本
- NPCTALK.LDT — NPC 对话
- SKILL_TXT.LDT — 技能描述
