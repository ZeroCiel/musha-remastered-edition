# PE区段加壳类型检测 & tshark网络分析

## PE 加壳类型快速识别

用Python分析PE区段名来判断加壳类型：

```python
import struct

with open('目标.dll', 'rb') as f:
    data = f.read()

pe_offset = struct.unpack('<I', data[0x3c:0x40])[0]
sections_offset = pe_offset + 0xF8

for i in range(10):
    pos = sections_offset + i * 40
    name = data[pos:pos+8].rstrip(b'\x00').decode('ascii', errors='replace')
    if not name:
        break
    print(f"  区段: {name}")
```

**常见加壳区段名对照：**
| 区段名 | 加壳类型 | 反编译难度 |
|--------|---------|-----------|
| `.vmp0` / `.vmp1` | **VMProtect** | ★★★★★（极高） |
| `UPX0` / `UPX1` | **UPX** | ★（可脱壳） |
| `.packed` / `.lz01` | ASPack/UPack | ★~★★ |
| `.themida` / `.safeline` | Themida/WinLicense | ★★★★ |
| `.enigma` / `e_shell` | Enigma Protector | ★★★★ |
| `.nsp0` / `.nsp1` / `.nsp2` | Neolite/Shrinker | ★★★ |
| `.tElock` / `.tqund` | tElock | ★★★ |

注意：UPX可以用 `upx -d 目标.dll` 直接脱壳；VMP没有公开脱壳工具。

## tshark（Wireshark命令行）常用命令

```bash
# 查看所有端口通信
tshark -r 文件.pcapng -T fields -e tcp.srcport -e tcp.dstport

# 过滤特定端口的流量
tshark -r 文件.pcapng -Y "tcp.port==19999" -T fields -e frame.number -e tcp.srcport -e tcp.dstport -e data.data

# 查看TCP流内容
tshark -r 文件.pcapng -z follow,tcp,ascii,流编号

# 查看所有TCP流编号
tshark -r 文件.pcapng -Y "tcp.port==19999" -T fields -e tcp.stream | sort -u

# 统计各端口流量
tshark -r 文件.pcapng -T fields -e tcp.srcport -e tcp.dstport | sort | uniq -c | sort -rn

# 导出指定流的数据
tshark -r 文件.pcapng -z follow,tcp,hex,流编号
```

## 常用Wireshark捕获接口（Windows）

| 接口名 | 用途 |
|--------|------|
| Adapter for loopback traffic capture | 捕获127.0.0.1本地回环流量 |
| WLAN / 以太网 | 捕获外部网络流量 |
| Npcap Loopback Adapter | 部分系统用这个代替loopback |

## Python读取pcapng（备用，tshark不可用时）

见 `C:\Users\Administrator\Temp\read_pcap.py`，利用pcapng的Enhanced Packet Block（0x06）解析。

注意：简单pcapng解析可能报错，优先用tshark。
