# PE 区段分析与 exe 启动行为诊断方法

## 原理

通过分析 exe 的 PE 区段（section）数量和特征区段名，可以快速判断 exe 是否被加壳以及壳的类型。结合启动行为（进程存活、端口绑定、console输出），三步即可确定 exe 状态，无需逆向分析。

## PE 区段分析 Python 脚本

```python
import struct

with open('target.exe', 'rb') as f:
    data = f.read()
pe_off = struct.unpack('<I', data[0x3c:0x40])[0]
num = struct.unpack('<H', data[pe_off+6:pe_off+8])[0]
sect_off = pe_off + 0xF8
print(f'Sections: {num}')
for i in range(num):
    name = data[sect_off:sect_off+8].rstrip(b'\x00').decode('ascii', errors='replace')
    vsize = struct.unpack('<I', data[sect_off+8:sect_off+12])[0]
    raw_sz = struct.unpack('<I', data[sect_off+16:sect_off+20])[0]
    print(f'  {name:8s} VSize={vsize:>8x} RawSz={raw_sz:>8x}')
    sect_off += 40
```

## 区段模式速查

| sections | 特征区段 | 判断 | 典型版本 |
|----------|---------|------|---------|
| 6 | `.text`, `.rdata`, `.data`, `.reloc`, `.rsrc` | **普通PE，未加壳** | S4chd服务端、彩虹岛单机服务端 |
| 8 | `.vmp0`, `.vmp1` | **VMProtect加壳**（前4区段 RawSize=0） | **所有端客户端(LaTaleClient.exe)** — S2/彩虹岛单机/S3 三端同一个加壳文件，都不能在Win11上跑 |
| 多段+压缩 | 区段名混乱或空名 | UPX/ASPack等通用壳 | 少数旧版程序 |

### 客户端加壳关键确认（2026-05-28）

**S2/彩虹岛单机/S3 三个版本的 `LaTaleClient.exe` 是同一个被 VMProtect 加壳的文件**：
- 文件大小完全相同：3.85MB (3,852,800 bytes)
- 区段完全一致：8 sections，`.vmp0`/`.vmp1` 特征
- PE header 完全相同：Windows 5.01 (GUI), Intel i386
- 行为完全一致：在 Win11 上弹出辅助窗口（GameGuard）后闪退

**结论**：客户端加壳问题不是版本特有的，这是所有老端客户端的通病。有可打开客户端（国服或其他不受限版本）就尽量用。

### VMProtect 加壳的典型特征

1. 区段数 8+（额外 `.vmp0`、`.vmp1` 命名区段）
2. 前 4 个区段（`.text`, `.rdata`, `.data`, `.vmp0`）的 `RawSize=0` — 数据加密存储
3. 实际代码在 `.vmp1` 区段（RawSize 非零）
4. 文件尾有乱码/空名区段

## 启动行为诊断流程（三步法）

1. **看 console 输出** — 从 git-bash 用 `background=true` 启动 exe
2. **看进程存活** — 等 3-5 秒后 `tasklist | grep Latale`
3. **看端口绑定** — `netstat -ano | findstr 端口号`

### 行为模式速查

| 行为模式 | Console输出 | 进程存活 | 绑端口 | 出dmp | 判断 | 典型场景 |
|----------|------------|---------|--------|-------|------|---------|
| 保护壳失败 | 无（静默 exit 0） | ❌ | ❌ | ❌ | 需要 CHDS.dll 或签名才能运行业务逻辑 | S3锁端exe、S2他乡exe |
| 源码 fatal bug | 有打印（如 Division Failed!!!） | ❌（getchar后return false） | ❌ | ❌ | exe 内源码逻辑缺陷，非保护机制 | S2他乡 MgmtServer 某些版本 |
| 配置错误 | 有打印（GLOBAL_SYS.LDT 等） | ✅（卡住/循环） | ❌ | ✅ | 路径/ODBC/SPF 配置问题 | S4chd 配错路径时 |
| 正常启动 | 有打印（MGMTServer was Started!!!） | ✅ | ✅ | — | ✅ 正常可用 | S4chd、彩虹岛单机 MgmtServer |
| 正常死锁 | 无新打印 | ✅（卡死） | ❌ | ❌ | 等资源/网关/其他组件就绪 | 缺 GLOBAL_SYS.LDT、缺网关 |

## 实测案例

### 案例1：彩虹岛单机端 MgmtServer（6 sections，正常）

```
file: PE32 executable for MS Windows 5.01 (console), Intel i386, 6 sections
Sections: 6
  .text    RawSz=0x3a5e00    （正常，非加密）
  .rdata   RawSz=0x6c0e
  .data    RawSz=0x5c00
  .reloc   RawSz=0x1000
  .rsrc    RawSz=0x1c00
启动行为：进程存活（29MB），绑端口，无dmp
判断：普通PE，可正常启动 ✅
```

### 案例2：LaTaleClient.exe（8 sections，VMProtect 加壳）

```
file: PE32 executable for MS Windows 5.01 (GUI), Intel i386, 8 sections
Sections: 8
  .text    RawSz=0             ← 加密
  .rdata   RawSz=0             ← 加密
  .data    RawSz=0             ← 加密
  .vmp0    RawSz=0             ← VMProtect 虚拟区
  .vmp1    RawSz=0x3a6600      ← 实际加密代码
  .reloc   RawSz=0x200
  .rsrc    RawSz=0x1c00
  乱码名   RawSz=0x4200
启动行为：弹辅助窗口后闪退，Win11 不支持 VMProtect 壳
判断：VMProtect 加壳，无法在 Win11 上运行 ❌
```

**注意**：S2/彩虹岛单机/S3 三端的 LaTaleClient.exe **完全相同**（3.85MB, 8 sections, 同一发布者打包），都不能在 Win11 上跑。这不是哪个特定版本的问题。

### 案例3：S3锁端 MgmtServer（静默 exit 0）

```
行为：./LataleMgmtServer.exe 启动后无 console 输出，进程不存活，无 dmp
判断：保护壳校验失败（需要配套 CHDS.dll 或网关签名才能运行）
```

## 常见陷阱

1. **区段数不等于加壳**：VS 编译器生成的普通 PE 也是 6 sections。关键看是否有 `.vmp0`/`.vmp1` 等壳特征区段。
2. **RawSize=0 不全是加密**：`.bss` 区段（未初始化数据）RawSize 也为 0，但它在 PE 中通常叫 `.bss` 而不是 `.text`/`.rdata`。
3. **进程存活 ≠ 正常工作**：彩虹岛服务端进程可能活着但不绑端口（卡在初始化），需要用 netstat 确认端口状态。
4. **dmp 文件存在 ≠ exe 坏了**：配置错误也会出 dmp，这是 exe 的正常错误报告机制，不是 exe 本身有问题。
5. **静默 exit 0 是保护壳的特征**：正常 exe 初始化失败会打印错误信息并等待按键（getchar）。exit 0 且无任何输出是有意为之的保护机制。
