# 客户端登录抓包代理（中间人模式）

## 用途
当 LaTaleClient.exe 能启动但连不上 LoginServer（卡"连接中"），需要抓包看实际发了什么协议。

## 代理原理
```
LaTaleClient.exe → 代理(监听 19999) → 真正的 LoginServer(端口)
                  打印所有数据包
```

## Python 代理代码

```python
import socket, threading
from datetime import datetime

LISTEN_PORT = 19999          # 客户端bat里的端口
TARGET_HOST = "127.0.0.1"
TARGET_PORT = 19100          # 实际LoginServer端口（从configure.ini确认）

def hexdump(data, label=""):
    ts = datetime.now().strftime("%H:%M:%S.%f")[:-3]
    print(f"\n[{ts}] {label} ({len(data)} bytes)", flush=True)
    show = data[:256]
    for i in range(0, len(show), 16):
        chunk = show[i:i+16]
        hex_part = ' '.join(f'{b:02x}' for b in chunk)
        ascii_part = ''.join(chr(b) if 32 <= b <= 126 else '.' for b in chunk)
        print(f"  {i:04x}  {hex_part:48s}  {ascii_part}", flush=True)
    if len(data) > 256:
        print(f"  ... ({len(data)} bytes total)", flush=True)

def forward(src, dst, direction):
    try:
        while True:
            data = src.recv(65536)
            if not data: break
            hexdump(data, direction)
            dst.sendall(data)
    except: pass
    finally:
        try: dst.close()
        except: pass

def handle_client(client, addr):
    print(f"\n[+] New client: {addr}", flush=True)
    try:
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.settimeout(10)
        server.connect((TARGET_HOST, TARGET_PORT))
        print(f"[+] Connected to {TARGET_HOST}:{TARGET_PORT}", flush=True)
        t1 = threading.Thread(target=forward, args=(client, server, ">> CLIENT→SERVER"), daemon=True)
        t2 = threading.Thread(target=forward, args=(server, client, "<< SERVER→CLIENT"), daemon=True)
        t1.start(); t2.start()
        t1.join(); t2.join()
    except Exception as e:
        print(f"[!] Failed: {e}", flush=True)
    finally:
        try: client.close()
        except: pass

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind(("0.0.0.0", LISTEN_PORT))
sock.listen(5)
print(f"Proxy on {LISTEN_PORT} → {TARGET_HOST}:{TARGET_PORT}", flush=True)
while True:
    client, addr = sock.accept()
    threading.Thread(target=handle_client, args=(client, addr), daemon=True).start()
```

## 启动方式

### 问题：直接跑脚本可能被火绒拦截
- 需要把 `python.exe` 加到火绒信任区
- 或者写日志文件方式：`python -u proxy.py > proxy.log 2>&1`

### 判断代理是否工作
- 客户端启动后查看代理日志是否有新条目
- 如果没有 → 客户端连的IP:PORT不是代理监听的

## 常见诊断结论

| 现象 | 结论 |
|------|------|
| 代理无连接，客户端显示"连接中" | 客户端连的不是127.0.0.1:19999（可能是写死的IP，或通过网关中转） |
| 代理收到TCP连接但无数据包交换 | Cipher加密握手失败（Cipher_Mode/UseEncryption不匹配） |
| 代理收到数据包 | 可以分析协议格式（包类型、字段结构） |

## 端口不匹配（2026-05-27 发现）

**configure.ini 中 LoginServer端口 ≠ 客户端bat中 /LoginServer 端口** 是常见问题：

| 端版本 | LoginServer端口 | 客户端bat连接端口 |
|--------|----------------|------------------|
| S2怀旧端(单机) | 19100 | 19999 |
| S2他乡端 | 19999 | 19999 |
| S4CHD | 9001 | — |

**排查方法**：在 configure.ini 中搜索 `[LataleLoginServer]` 段下的 `port =`。

## 火绒误杀后的判断

如果之前能连但现在连不上，且没有其他配置变化：
1. 检查导入表是否缺 DLL：`python -c "import pefile; pe=pefile.PE('LaTaleClient.exe'); print([e.dll for e in pe.DIRECTORY_ENTRY_IMPORT])"`
2. 检查火绒隔离区：`C:\ProgramData\Huorong\Sysdiag\Quarantine\`
3. 用 `netstat -ano | findstr "PID"` 看客户端进程实际连了哪些远程地址
