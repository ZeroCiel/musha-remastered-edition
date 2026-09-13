#!/usr/bin/env python3
"""
Hermes 网页聊天 - 零依赖模板
==============================
使用 Python 内置 http.server，无需安装任何第三方库。
将此文件放在 webui/ 目录，同目录下有 index.html。

启动前确保: hermes gateway run (API 在 8642 端口)
启动: python server.py
访问: http://127.0.0.1:7860
"""
import http.server
import json
import urllib.request
import socketserver
from pathlib import Path

# ===== 配置 =====
PORT = 7860
API_BASE = "http://127.0.0.1:8642"
MODEL = "deepseek-chat"

THIS_DIR = Path(__file__).parent
HTML = (THIS_DIR / "index.html").read_text(encoding="utf-8")


class Handler(http.server.BaseHTTPRequestHandler):
    timeout = 300

    def log_message(self, format, *args):
        """只在错误时打印"""
        if any(str(c) in str(args) for c in ("4", "5")):
            print(f"  [{self.command}] {self.path} -> {args}")

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        if self.path in ("/", "/index.html"):
            data = HTML.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self._cors()
            self.end_headers()
            self.wfile.write(data)
        elif self.path == "/api/health":
            try:
                req = urllib.request.Request(f"{API_BASE}/v1/models")
                with urllib.request.urlopen(req, timeout=5) as resp:
                    result = resp.read().decode("utf-8")
                self._json(200, {"status": "ok", "models": json.loads(result)})
            except Exception as e:
                self._json(503, {"status": "offline", "error": str(e)})
        else:
            self.send_error(404)

    def do_POST(self):
        if self.path == "/api/chat":
            try:
                length = int(self.headers.get("Content-Length", 0))
                if length == 0:
                    self._json(400, {"error": "请求体为空"})
                    return
                body = self.rfile.read(length).decode("utf-8")
                data = json.loads(body)
                messages = data.get("messages", [])

                payload = json.dumps({
                    "model": MODEL,
                    "messages": [
                        {"role": "system", "content": "你是 Hermes Agent，请用中文回复。"}
                    ] + messages,
                    "stream": False,
                }).encode("utf-8")

                req = urllib.request.Request(
                    f"{API_BASE}/v1/chat/completions",
                    data=payload,
                    headers={"Content-Type": "application/json; charset=utf-8"}
                )
                with urllib.request.urlopen(req, timeout=300) as resp:
                    result = json.loads(resp.read().decode("utf-8"))

                if "choices" in result and result["choices"]:
                    content = result["choices"][0]["message"]["content"]
                    self._json(200, {"content": content})
                else:
                    self._json(502, {"error": "API 返回异常"})
            except urllib.error.URLError as e:
                self._json(503, {"error": f"无法连接 API: {e.reason}"})
            except json.JSONDecodeError:
                self._json(400, {"error": "JSON 解析失败"})
            except Exception as e:
                print(f"  [错误] {e}")
                self._json(500, {"error": str(e)})
        else:
            self.send_error(404)

    def _json(self, status, data):
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self._cors()
        self.end_headers()
        self.wfile.write(body)


# CRITICAL: ThreadingMixIn 防止单请求阻塞所有连接
class ThreadedServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    allow_reuse_address = True
    daemon_threads = True


def main():
    server = ThreadedServer(("127.0.0.1", PORT), Handler)
    print(f"\n{'='*60}")
    print(f"  Hermes Agent 网页版 (零依赖)")
    print(f"{'='*60}")
    print(f"  地址: http://127.0.0.1:{PORT}")
    print(f"  API:  {API_BASE}")
    print(f"  模型: {MODEL}")
    print(f"{'='*60}")
    print(f"  按 Ctrl+C 停止")
    print()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n  已停止")
        server.shutdown()


if __name__ == "__main__":
    main()
