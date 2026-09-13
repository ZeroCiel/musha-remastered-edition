#!/usr/bin/env python3
"""
Hermes Agent 网页聊天界面 - aiohttp 模板
==========================================
将 MODEL 和 WEB_PORT 改为你的配置即可使用。
需要先运行: hermes gateway run
"""

import asyncio
import json
import uuid
import aiohttp
from aiohttp import web
from pathlib import Path

# ===== 配置 =====
API_BASE = "http://127.0.0.1:8642"   # Hermes API 服务器地址
WEB_PORT = 7000                       # 网页端口
MODEL = "deepseek-chat"               # 模型名称（与 config.yaml 一致）

# 加载 HTML（从同目录 index.html）
THIS_DIR = Path(__file__).parent
HTML_CONTENT = (THIS_DIR / "index.html").read_text(encoding="utf-8")


async def handle_index(request):
    """首页"""
    return web.Response(
        text=HTML_CONTENT,
        content_type="text/html",
        charset="utf-8"
    )


async def handle_chat(request):
    """代理聊天请求到 Hermes API 服务器"""
    try:
        # 用 raw bytes 解码，避免 Windows 编码问题
        raw_body = await request.read()
        data = json.loads(raw_body.decode("utf-8", errors="replace"))
        messages = data.get("messages", [])

        system_msg = {
            "role": "system",
            "content": "你是一个智能 AI 助手。请用中文回复用户。"
        }

        payload = {
            "model": MODEL,
            "messages": [system_msg] + messages,
            "stream": False,
        }

        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{API_BASE}/v1/chat/completions",
                json=payload,
                timeout=aiohttp.ClientTimeout(total=300)
            ) as resp:
                raw = await resp.read()
                result = json.loads(raw.decode("utf-8", errors="replace"))

        if "choices" in result and len(result["choices"]) > 0:
            content = result["choices"][0]["message"]["content"]
            return web.json_response({"content": content})
        else:
            return web.json_response(
                {"error": "API 返回异常"}, status=502
            )

    except aiohttp.ClientConnectorError:
        return web.json_response(
            {"error": "无法连接 Hermes API 服务器。请先运行: hermes gateway run"},
            status=503
        )
    except asyncio.TimeoutError:
        return web.json_response({"error": "请求超时"}, status=504)
    except Exception as e:
        return web.json_response({"error": str(e)}, status=500)


async def handle_health(request):
    """健康检查"""
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(
                f"{API_BASE}/v1/models",
                timeout=aiohttp.ClientTimeout(total=5)
            ) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    return web.json_response({"status": "ok", "models": data})
                else:
                    return web.json_response({"status": "error"}, status=502)
    except Exception:
        return web.json_response({"status": "offline"}, status=503)


def main():
    app = web.Application()
    app.router.add_get("/", handle_index)
    app.router.add_post("/api/chat", handle_chat)
    app.router.add_get("/api/health", handle_health)

    print("=" * 60)
    print("  Hermes Agent 网页版")
    print("=" * 60)
    print(f"  API 服务器: {API_BASE}")
    print(f"  模型: {MODEL}")
    print("=" * 60)
    print("  按 Ctrl+C 停止网页服务")
    print()

    async def start():
        runner = web.AppRunner(app)
        await runner.setup()
        site = web.TCPSite(runner, "127.0.0.1", WEB_PORT)
        await site.start()
        for sock in site._server.sockets:
            addr = sock.getsockname()
            print(f"  浏览器打开: http://127.0.0.1:{addr[1]}")
            break
        print()
        await asyncio.Event().wait()

    asyncio.run(start())


if __name__ == "__main__":
    main()
