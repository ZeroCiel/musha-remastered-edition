# S4端拷贝迁移记录 (2026-06-05)

## 背景

用户想测试 S4chd（99元端）如果拷贝到新目录 `D:\LaTale\S4\` 并换上 S2 素材，能不能启动进游戏。

## 操作步骤

1. 拷贝 S4chd 的 `configure.ini`、加密 `.inis`、所有 `.SPF` + `_LOCALIZE.LDT` 到 S4 对应目录
2. grep 所有 `S4chd` 引用 → 批量替换为 `S4`

## 遇到的关键问题

### 1. configure.ini 原有脏数据

原 S4 目录的 `configure.ini` 已被人为修改过，尾部有大量乱码路径和孤儿段：
- 221行后出现 `D:\�ʺ絺\bin2\SPF������_\`（原始韩文/繁中路径，在简体系统上乱码）
- 两个 `[MS]` 段（port=10021 和 port=10024），配置拼接痕迹
- 孤儿段 `Latalegameserver_103~110`，port=30003~30010，resourceDir 指向乱码路径
- 注释有韩文乱码

**教训**：不要手动逐行修复脏配置（改不完、改不干净）。直接拿完好版本的完整 `configure.ini` 覆盖。

### 2. `[ConfigurePath]` 引用加密 .inis 的路径

`configure.ini` 的 `[ConfigurePath]` 段指向 `.inis`（加密格式），不是 `.ini`。
```ini
[ConfigurePath]
Share=D:\LaTale\S4chd\bin2\configure_share.inis
ODBC=D:\LaTale\S4chd\bin2\Global_ODBC.inis
IPFILTER=D:\LaTale\S4chd\bin2\IPFiltering.inis
```

即使改成指向 `.ini` 明文文件，exe 第一行代码仍然是 `Load configure from Security INI`——它硬编码走加密读取路径。

### 3. 大小写不一致的 ResourceDir

`configure.ini` 同时使用 `ResourceDir`（首字母大写）和 `resourceDir`（首字母小写）两种写法。两个都要改。

## 经验总结

### S4chd 拷贝迁移清单

1. 拷贝 `configure.ini` → 覆盖目标目录
2. 拷贝所有 `.inis` → `bin2/`
3. 拷贝所有 `.SPF` + `_LOCALIZE.LDT` → `resource/`
4. 修改 `configure.ini` 中的路径：
   - `[ConfigurePath]` → 三个路径
   - 所有 `ResourceDir=` + `resourceDir=` → 全局替换
5. 验证干净：`grep -n "旧目录名" configure.ini` → 无输出

### 手动启动 vs 网关启动

- 网关.exe 自动拉起 GS 但 GameServer 不存活（日志显示加载配置崩了）
- 手动逐个启动反而全活
- 结论：S4chd 的 exe 依赖加密 `.inis` 配置。网关启动时网关自己读配置解密，但手动启动时 exe 还是需要加密 `.inis`——只要 `.inis` 在正确路径就能正常启动。
