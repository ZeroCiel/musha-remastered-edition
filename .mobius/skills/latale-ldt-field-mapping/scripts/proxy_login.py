"""
WARNING: 此脚本已废弃！
dbgls.dll 的认证不走 LoginServer 的 19999 TCP 端口，
所以用代理拦截19999端口抓不到dbgls.dll的认证包。

保留此脚本仅作为彩虹岛标准登录协议的抓包参考。
"""

# 中间人代理 - 监听19998端口，转发到LoginServer 19999
# 抓取LaTaleClient.exe和LoginServer之间的标准登录协议
import socket, threading, sys, time

LOGIN_HOST = '127.0.0.1'
LOGIN_PORT = 19999
PROXY_PORT = 19998

def forward(src, dst, name, log_prefix):
    """转发数据并记录"""
    try:
        while True:
            data = src.recv(4096)
            if not data:
                break
            print(f"\n{log_prefix} [{name}] {len(data)} 字节:")
            print(f"  HEX: {data.hex()}")
            try:
                text = data.decode('utf-16-le', errors='replace')
                if any(ord(c) > 0x4E00 for c in text):
                    print(f"  UTF-16LE: {text[:100]}")
            except:
                pass
            dst.send(data)
    except:
        pass
    finally:
        try:
            src.close()
        except:
            pass
        try:
            dst.close()
        except:
            pass

def start_proxy():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('127.0.0.1', PROXY_PORT))
    server.listen(1)
    print(f"代理已启动: 127.0.0.1:{PROXY_PORT} -> {LOGIN_HOST}:{LOGIN_PORT}")
    print("请修改客户端配置文件, 将LoginServer端口指向19998")
    print("然后启动客户端...\n")
    
    conn, addr = server.accept()
    print(f"客户端连接: {addr}")
    
    backend = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    backend.connect((LOGIN_HOST, LOGIN_PORT))
    print(f"已连接后端LoginServer\n")
    
    t1 = threading.Thread(target=forward, args=(conn, backend, "客户端->服务端", ">>>"), daemon=True)
    t2 = threading.Thread(target=forward, args=(backend, conn, "服务端->客户端", "<<<"), daemon=True)
    t1.start()
    t2.start()
    t1.join()
    t2.join()
    print("\n连接关闭")

if __name__ == '__main__':
    start_proxy()
