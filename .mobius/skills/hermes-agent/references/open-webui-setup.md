# Open WebUI Setup with Hermes (Windows)

Full walkthrough for installing Open WebUI as a web frontend for Hermes Agent on Windows, including the Python 3.11 embeddable workaround.

## Architecture

```
Browser → Open WebUI (:8080) → Hermes API (:8642/v1) → LLM
```

## Prerequisites

- Hermes API server running: `hermes gateway run` (port 8642)
- Hermes config has `platforms.api_server.enabled: true`

## Python 3.11 Embeddable Setup

Python 3.14 cannot install Open WebUI (requires `>=3.11,<3.13`). Use the embeddable distribution:

```bash
# Download
curl -L -o python-3.11.9-embed-amd64.zip \
  "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip"

# Extract (to C:\\hermes\\python311\\)
mkdir -p python311 && cd python311
unzip ../python-3.11.9-embed-amd64.zip
```

### Enable pip (embeddable Python lacks it by default)

Edit `python311._pth`:
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
```

## Open WebUI Installation

```bash
python311/Scripts/pip.exe install open-webui
```

Dependencies include: chromadb, langchain, transformers, sentence-transformers, faster-whisper, pandas, scikit-learn, opencv, torch, and 100+ others. ~2GB total.

## Startup

```bash
set OPENAI_API_BASE_URL=http://127.0.0.1:8642/v1
set OPENAI_API_KEY=hermes
python311\\Scripts\\open-webui.exe serve --host 127.0.0.1 --port 8080
```

### First-Run Behavior

1. Generates `.webui_secret_key` in working directory
2. Runs ~30 Alembic DB migrations (creates SQLite DB)
3. Prints ASCII art banner — **HTTP server only available after this**
4. Attempts to download sentence-transformers model from HuggingFace (~60s timeout if unreachable)

Total first-start time: 30–90 seconds. Subsequent starts: ~5 seconds.

### Troubleshooting Startup

**Symptom:** curl gets "connection refused" for 60+ seconds after launch.
**Cause:** HuggingFace model download blocking startup (RAG embedding engine).
**Fix:** Set `RAG_EMBEDDING_ENGINE=` and `HF_HUB_OFFLINE=1` before starting.

**Symptom:** `httpcore.ConnectError: [WinError 10061]` in logs.
**Cause:** Same as above — retrieval model download can't reach huggingface.co.
**Impact:** Non-fatal. Server starts after timeout. The error is cosmetic for local use.

## First Use

1. Open http://127.0.0.1:8080
2. Click "Sign up" — create an admin account (first user is auto-admin)
3. Open WebUI auto-discovers models from the connected API
4. Start chatting

## Batch Launcher

`启动OpenWebUI.bat`:
```batch
@echo off
cd /d C:\\hermes
start "Hermes-API" cmd /c ".venv\\Scripts\\hermes.exe gateway run"
timeout /t 5 /nobreak > nul
set OPENAI_API_BASE_URL=http://127.0.0.1:8642/v1
set OPENAI_API_KEY=hermes
start "OpenWebUI" cmd /c "python311\\Scripts\\open-webui.exe serve --host 127.0.0.1 --port 8080"
```

## File Layout After Setup

```
C:\\hermes\\
  python311\\              # Python 3.11 embeddable
    python.exe
    Scripts\\
      pip.exe
      open-webui.exe
    Lib\\site-packages\\    # ~2GB of packages
  webui\\
    启动OpenWebUI.bat      # One-click launcher
    启动网页版.bat          # Simple chat launcher (port 7860)
    server.py              # Zero-dependency fallback server
    hermes_webui.py        # aiohttp fallback server (port 7000)
    index.html             # Shared chat UI HTML
  .webui_secret_key        # Open WebUI auto-generated
  .venv\\                   # Hermes main venv (Python 3.14)
```
