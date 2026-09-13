# Hermes Web Chat UI (aiohttp Proxy)

A lightweight browser-based chat interface that proxies requests to Hermes's
built-in API server (`platforms.api_server` on port 8642). Avoids the heavy
Open WebUI stack when Python 3.11 / Docker are unavailable.

## Architecture

```
Browser (http://127.0.0.1:7000)
    │  POST /api/chat  { messages: [...] }
    ▼
aiohttp proxy (webui/hermes_webui.py)
    │  POST /v1/chat/completions  (OpenAI-compatible)
    ▼
Hermes API server (127.0.0.1:8642, started by `hermes gateway run`)
```

The proxy adds a Chinese system prompt, injects the model name, and forwards
user messages. It avoids CORS by serving both the HTML page and the API proxy
on the same origin.

## Key Files

- `webui/hermes_webui.py` — the aiohttp server + proxy
- `webui/index.html` — standalone HTML/JS chat UI (dark theme)
- `webui/启动网页版.bat` — Windows launcher that starts both gateway + webui

## Startup Sequence

1. Ensure API server is configured:
   ```yaml
   platforms:
     api_server:
       enabled: true
       extra:
         port: 8642
         host: "127.0.0.1"
   ```
2. Start the gateway: `hermes gateway run`
3. Start the web UI: `.venv/Scripts/python.exe webui/hermes_webui.py`
4. Open: `http://127.0.0.1:7000`

## Pitfalls

### aiohttp: "charset must not be in content_type argument"

When using `body=bytes` in `web.Response`, the `content_type` parameter cannot
include `charset=utf-8`. Workaround: use `text=str` + separate `charset` kwarg.

```python
# BROKEN:
return web.Response(body=html.encode(), content_type="text/html; charset=utf-8")
# ValueError: charset must not be in content_type argument

# FIXED:
return web.Response(text=html, content_type="text/html", charset="utf-8")
```

### Windows port TIME_WAIT

On Windows, killed processes leave ports in TIME_WAIT for ~120 seconds.
During development, use `port=0` in `web.TCPSite` to auto-allocate a free port,
then read the actual port from `site._server.sockets[0].getsockname()`.

```python
site = web.TCPSite(runner, "127.0.0.1", 0)  # auto-pick
await site.start()
port = site._server.sockets[0].getsockname()[1]
print(f"Listening on http://127.0.0.1:{port}")
```

### git-bash curl sends non-UTF-8 bytes

On Windows git-bash, `curl -d '{...中文...}'` may send GBK-encoded bytes.
The aiohttp handler should decode with `errors="replace"`:

```python
raw_body = await request.read()
data = json.loads(raw_body.decode("utf-8", errors="replace"))
```

Browsers always send UTF-8, so this only affects terminal testing.

### API response encoding

Hermes API server may return JSON with non-UTF-8 bytes in certain edge cases.
Always decode with `errors="replace"`:

```python
raw = await resp.read()
result = json.loads(raw.decode("utf-8", errors="replace"))
```
