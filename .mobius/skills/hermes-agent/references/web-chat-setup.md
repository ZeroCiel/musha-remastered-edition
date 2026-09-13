# Hermes Web Chat UI Setup

Web-based chat interfaces for Hermes Agent. Two options depending on your environment.

## Option A: aiohttp Proxy (Lightweight, No Extra Dependencies)

When Open WebUI can't be installed (e.g. Python 3.11 required but only 3.14 available, no Docker).

### Architecture

```
Browser (http://127.0.0.1:PORT)
    ↕
Web UI (aiohttp proxy)
    ↕
Hermes API Server (http://127.0.0.1:8642)
    ↕
LLM
```

### Prerequisites

1. Ensure `config.yaml` has API server enabled:
   ```yaml
   platforms:
     api_server:
       enabled: true
       extra:
         port: 8642
         host: 127.0.0.1
   ```

2. Start the gateway: `hermes gateway run`

3. Verify:
   ```bash
   curl http://127.0.0.1:8642/v1/models
   # Should return: {"object":"list","data":[{"id":"hermes-agent",...}]}
   ```

### Files (from templates/)

- `templates/hermes_webui.py` — aiohttp server + proxy (port 7000)
- `templates/server.py` — zero-dependency http.server fallback (port 7860)
- Both need an `index.html` alongside them.

### Key Pitfalls

- **charset in content_type crashes**: Use `text=` + separate `charset=` parameter, never inline.
- **UTF-8 decode errors**: Always decode raw bytes with `errors="replace"` on Windows.
- **Port TIME_WAIT**: Windows holds ports for 30-120s after kill. Use `port=0` for auto-allocation during dev.
- **ThreadingMixIn required** for the zero-dep server — `http.server.HTTPServer` is single-threaded.

## Option B: Open WebUI (Full-Featured)

Full walkthrough for installing Open WebUI as a web frontend for Hermes Agent on Windows.

### Architecture

```
Browser → Open WebUI (:8080) → Hermes API (:8642/v1) → LLM
```

### Python 3.11 Embeddable Setup

When system Python is 3.14+ (Open WebUI requires `>=3.11,<3.13`):

```bash
curl -L -o python-3.11.9-embed-amd64.zip \
  "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip"
mkdir -p python311 && cd python311
unzip ../python-3.11.9-embed-amd64.zip
```

Edit `python311._pth` — uncomment `import site` and add `Lib/site-packages`:

```
python311.zip
.

import site
Lib/site-packages
```

Then:

```bash
mkdir -p Lib/site-packages
curl -sL https://bootstrap.pypa.io/get-pip.py -o get-pip.py
./python.exe get-pip.py
python311/Scripts/pip.exe install open-webui
```

### Startup

```bash
set OPENAI_API_BASE_URL=http://127.0.0.1:8642/v1
set OPENAI_API_KEY=hermes
python311\Scripts\open-webui.exe serve --host 127.0.0.1 --port 8080
```

### First-Run Behavior

1. Generates `.webui_secret_key`
2. Runs ~30 Alembic DB migrations (~30s)
3. Attempts to download sentence-transformers from HuggingFace (~60s timeout if unreachable)
4. Skip RAG with: `set RAG_EMBEDDING_ENGINE=` and `set HF_HUB_OFFLINE=1`

## Browser Crash Troubleshooting (Windows)

### Edge crash dump location
```
C:\Users\<user>\AppData\Local\Microsoft\Edge\User Data\Crashpad\reports\
```

### Common causes on localhost
1. **WebView2 memory pressure** — `msedgewebview2.exe` processes consuming 500MB+
2. **Corrupted profile** — Rename `User Data` directory to reset (clears bookmarks/extensions)
3. **Extension conflicts** — Launch with `msedge --disable-extensions`
4. **Graphics driver** — Try `msedge --disable-gpu`
5. **Antivirus injection** — Temporarily disable security software

### Diagnostic order
1. Check crash dumps exist → confirms Edge problem, not server
2. Try `msedge --disable-extensions` → eliminates extension cause
3. Try `msedge --disable-gpu` → eliminates GPU/driver
4. Try Chrome/Firefox → eliminates Edge-specific issue
5. Reset profile → nuclear option
6. Reinstall Edge from microsoft.com/edge

### Server-side verification first
```bash
# Homepage loads
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:PORT/
# Chat works
curl -s -X POST http://127.0.0.1:PORT/api/chat \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"test"}]}'
```
If curl succeeds but browser crashes → browser problem. If curl hangs → fix server first.
