---
name: mobius-agent-os
description: 在 WSL2 Linux 上部署/运维 Mobius（自进化 Agent OS，服务端只支持 Linux，启动器写死 tmux）。含首启流程、aimux 桥的 GitHub 下载绕过、模型接入（Codex/Claude Code/DeepSeek harness）的 API 配置法、一键启动器。当用户要装/修/配 Mobius、配模型接入、或 Mobius 启动失败时使用。
---

# Mobius Agent OS 部署与运维（WSL2）

前置：Linux 环境。Windows 上先按 `wsl2-ubuntu-china` 装好 WSL2 + Ubuntu，发行版必须能跑 tmux（Mobius 服务端启动器写死 tmux，Windows 原生跑不了；Docker 就够，但 Docker Desktop 对 8G 机器太重）。

## 代码与依赖
- 仓库结构：根目录 `conf_prepare.py` / `conf_check.py` / `start.py`（Python 入口），`mobius/`（Node 后端 + `frontend/`），`scripts/`，`deploy/`
- 官方 base 镜像依赖（`deploy/onekey/Dockerfile4zh-base`）：node:18-bookworm + apt `nano tmux proxychains-ng git curl ca-certificates tini python3 make g++ procps less locales iproute2 psmisc openssh-server ffmpeg unzip` + `uv` + code-server 4.19.1 + 全局 npm `@anthropic-ai/claude-code@2.1.195` `@openai/codex@0.144.6`
- 代码**必须拷进 WSL 原生文件系统**（`~`），**不要在 `/mnt/c` 下跑 npm install**，跨文件系统极慢

## 首启三步
```bash
cd ~/mobius-main
python3 conf_prepare.py    # 非 TTY 时自动用默认路径，生成 .env + 随机 JWT_SECRET + admin 密码
python3 conf_check.py      # 应输出 "Configuration OK"
python3 start.py --detach  # 前端编译(+后端/pm2/code-server)，不占终端
```
`conf_prepare.py` 会把 admin 密码打进 stdout（`MOBIUS_BOOTSTRAP_USERS=admin:<随机>:admin:管理员`），**记下来**。
启动后监听端口来自 `.env`：`MOBIUS_PORT=33314`（内部）、**实际网页/后端是 `VITE_PORT=33316`**、code-server `33317`、SSH `33318`、aimux 桥 `33315`。
健康检查：`curl http://localhost:33316/api/v2/health`。

## 坑 1：aimux 桥要 GitHub 下 Python 3.12 → 墙内必失败
`mobius/scripts/setup-aimux-bridge.sh` 里 `uv venv "$VENV" --python 3.12`，系统没 3.12 时 uv 去 GitHub Releases 下 python-build-standalone → `Downloading cpython-3.12.14 ... error: Request failed after 3 retries / Invalid tar file` → **start_product.py 退出码 2，后面服务全不启动**。

它的幂等检查只看「`$VENV/bin/aimux` 可执行 + `site-packages/aimux-*.dist-info` 版本匹配」，**不看 Python 版本**。绕过：
```bash
VENV=~/mobius-main/mobius/.venv-aimux
rm -rf "$VENV"
uv venv "$VENV" --python /usr/bin/python3.10        # 用系统 python，不下载
uv pip install --python "$VENV" --no-cache \
  --index-url https://pypi.tuna.tsinghua.edu.cn/simple/ 'aimux==0.1.29'
ls -la "$VENV/bin/aimux" "$VENV"/lib/python*/site-packages/aimux-*.dist-info
```
（备选：设 `UV_PYTHON_INSTALL_MIRROR` 指向南大/中科大的 github-release 镜像取真 3.12。）

## 坑 2：模型接入（关键）
模型配置存在 `MODEL_ACCESS_PATH`(= `<data>/model-access.json`)，**可以完全用 admin API 配置，不用点网页表单**。

```python
import json, urllib.request
BASE, PW = "http://localhost:33316", "<admin密码>"
def http(url, body=None, token=None, method=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method or ("POST" if body is not None else "GET"))
    req.add_header("Content-Type", "application/json")
    if token: req.add_header("Authorization", "Bearer " + token)
    with urllib.request.urlopen(req, timeout=40) as r:
        return json.loads(r.read().decode("utf-8", "replace"))
token = http(BASE + "/api/auth/login", {"username": "admin", "password": PW})["token"]
```
接口（都在 `/api/admin/model-access/` 下，需 Bearer JWT）：
| 路径 | 用途 |
| --- | --- |
| `codex` (GET/POST) · `codex/:key` (GET/PUT/DELETE) | Codex CLI 渠道 |
| `claude-code` … | Claude Code CLI 模型 |
| `deepseek-harness` … | DeepSeek harness（要求 Node 22.19+/24+，Node 18 跑不了） |

### Codex 渠道的 TOML 规则
- **`wire_api = "chat"` 在 Codex 0.144.6 已被移除**，只认 `responses`。否则报 `Error loading config.toml: wire_api = "chat" is no longer supported`
- TOML **必须含 `api_key` 字段**，否则 400 `config_toml 必须包含 api_key`；真实密钥放请求体 `secret_value`，TOML 里填占位符 `<API_KEY>`（或 `REPLACE_WITH_ENV_OR_SECRET_MANAGER`）
- TOML 的 `env_key` 必须 == 请求体的 `secret_env_key`
- **渠道名（channel）只能纯英文字母**，带 `-` 会 400 `Codex 渠道只能包含英文字母, 例如 mobiusdefault`

可用的创建请求体：
```python
toml = f'''model_provider = "deepseek"
model = "{MODEL}"
disable_response_storage = true
windows_wsl_setup_acknowledged = true

[model_providers.deepseek]
name = "DeepSeek"
base_url = "https://api.deepseek.com/v1"
wire_api = "responses"
env_key = "DEEPSEEK_API_KEY"
api_key = "<API_KEY>"
'''
body = {"channel": "deepseek", "label": "DeepSeek", "codex_model": MODEL,
        "secret_env_key": "DEEPSEEK_API_KEY", "secret_value": "<sk-...>",
        "config_toml": toml, "enabled": True}
http(BASE + "/api/admin/model-access/codex", body, token=token)
```
写入位置：`~/.codex/<channel>.config.toml`；会话用 `codex --profile <channel>` 加载。

### DeepSeek 实测（2026）
- 模型列表：`GET https://api.deepseek.com/v1/models`
- **支持 Responses API**（`POST /v1/responses` → 200），所以能直接走 Codex 渠道
- **也支持 Anthropic 接口**（`POST /anthropic/v1/messages`，header `x-api-key` + `anthropic-version: 2023-06-01` → 200），所以 Claude Code 渠道也能接

### 冒烟测试（必做）
```bash
wsl -d <distro> -u <user> -- bash -lc '
  export DEEPSEEK_API_KEY=sk-...   # 手工测时手动导出；正常由 Mobius 从 secret_value 注入
  cd ~ && codex --profile deepseek exec -s read-only --skip-git-repo-check "只回复两个字：成功"'
```
正常输出会含 `model: <模型名>` `provider: deepseek` 和模型的回复。
`codex doctor` 报 `auth: no Codex credentials` / `reachability` 不可达是**正常的**（它探的是 OpenAI 官方接口，墙外），不影响自建 provider。

### 成本警告
Codex 系统提示词极肥：一句"只回复两个字"实测 **10,563 token**。即**每个新会话起步就烧约一万 token**。建议按任务分渠道（强模型给难活、便宜模型给日常）：`bubblewrap` 也建议装上（`apt install bubblewrap`），否则沙箱有 warning。

## 坑 3：改 `.env` 后必须走 start.py，`pm2 restart` 不生效
`mobius/ecosystem.config.js` 用 **envKeys 白名单 + `inheritedEnv`** 在 **PM2 启动那一刻**固化环境变量：
```js
const envKeys = [ ..., 'ENABLE_PASSWORD_LOGIN', ... ];
for (const key of envKeys) if (process.env[key] !== undefined) inheritedEnv[key] = process.env[key];
```
所以 `pm2 restart --update-env` 也是沿用旧值。**改完 `.env` 必须重跑 `python3 start.py --detach`**（它会重新 load_dotenv 并用新 env 重建 PM2 app）。

### 免密码登录
`config.js` 里是 `ENABLE_PASSWORD_LOGIN: process.env.ENABLE_PASSWORD_LOGIN === 'true'` —— **必须精确是字符串 `'true'` 才要求密码**。设 `.env` 里 `ENABLE_PASSWORD_LOGIN=false` + `start.py --detach` 后，`POST /api/auth/login {"username":"admin"}`（不传 password）即返回 200 + token。
验证方式（**别用 grep 看值**，密钥类变量会被日志脱敏成 `***`）：直接打 API，或 `grep -qx "ENABLE_PASSWORD_LOGIN=false" .env && echo YES`。

## 桌面客户端（Electron）
官方包在 GitHub Releases（`github.com/mobius-system/mobius/releases/download/desktop-v<V>/mobius-desktop-<V>-win-x64.zip`，约 138MB）。墙内 `github.com` 会 302 到被劫持的地址 → 用加速镜像（实测 200）：`https://ghfast.top/<原url>`、`https://gh-proxy.com/<原url>`、`https://ghproxy.net/<原url>`（ghfast 实测 1.9 MB/s）。

拿到 zip 后喂给服务器，网页里的下载入口即生效：
```bash
mkdir -p ~/mobius-main/mobius/desktop-builds
cp <zip> ~/mobius-main/mobius/desktop-builds/     # 文件名必须 mobius-desktop-<版本>-win-x64.zip
cd ~/mobius-main && python3 scripts/desktop_manifest.py generate --dir mobius/desktop-builds
                  python3 scripts/desktop_manifest.py validate --dir mobius/desktop-builds
# 验证：curl -I http://localhost:33316/desktop-builds/manifest.json  → 200
```
`desktop_manifest.py generate` 的版本取自 `mobius/desktop/package.json`，show 服务 `--version` 可覆盖。

后端自带 `sync-desktop-builds` 服务会自己去 GitHub 拉这些包，但在装有 **Steamcommunity 302** 的机器上必然失败：日志 `[mobius/desktop-sync] 同步异常: connect ECONNREFUSED 127.0.0.1:443` —— 因为 hosts 把 github.com 指到 127.0.0.1，Windows 上 S302 接得住，**WSL 里的 127.0.0.1 是另一个回环**、无人监听。只能手动喂（上面那套）。

### ★ 客户端登录报 400 `{"error":"Missing credentials"}` = **用户名框是空的**
`electron/main.ts` 的 `doLogin` 固定发 `POST /api/auth/login` body `{"username": <框值>, "password": <框值>}`。
服务端只有 `!username` 会回这句，**逐个案测过**：
`{"username":"admin"}` → 200；`{"username":"admin","password":""}` → 200；
`{"username":""}` → **400 Missing credentials**；`{"username":"Admin"}` → 200（大小写不敏感）。
登录页那句「密码 不填也可尝试」**只针对密码**，用户名必填。
客户端还会把账号密码存下来做 JWT 续期（提前 10 min 重登），所以关掉密码登录后它照样能跑。

## 项目导入 & 工作区路径
官方流程（`docs/tutorial/02a_…`）：**新建项目 → 「在 vscode 中打开」→ 把 zip 拖进 code-server 窗口 →
建任务「用刚上传的文件创建项目并初始化 Git 版本控制」**。不需要人工把文件摆到某个目录。

要直接给路径时：
| 方向 | 路径 |
|---|---|
| WSL 看 Windows 盘 | `D:\xxx` → `/mnt/d/xxx`（agent 直接可读，不用先搬） |
| Mobius 项目落地目录 | `<data>/workspace/<用户名>/`（本机 `/home/mobius/mobius-main/host_data/data/workspace/admin/`） |
| Windows 打开 WSL 目录 | 资源管理器粘 `\\wsl.localhost\Ubuntu2204\home\mobius\mobius-main\host_data\data\workspace\admin` |

★ **别在 `/mnt/d` 下跑 git/npm**（9p 跨文件系统极慢），先 `cp -r` 进 workspace。
★ 从 Windows 侧自动化查 WSL 路径别内联 UNC（git-bash 会吃掉一层 `\`，报 `C:\wsl.localhost\...`），
写成 `.ps1` 用 `powershell -File` 跑。

## 坑 4：Windows 一键启动器（.bat）
服务跑在 WSL 的 PM2 里，**Windows 重启后不会自动起**。桌面放 `启动Mobius.bat`：
```bat
@echo off
wsl.exe -d Ubuntu2204 -- echo ok >nul 2>&1
curl.exe -s -o nul -m 5 http://localhost:33316/api/v2/health
if not errorlevel 1 goto openbrowser
wsl.exe -d Ubuntu2204 -u mobius -- bash -lc "cd ~/mobius-main && python3 start.py --detach"
for /l %%i in (1,1,60) do (
    curl.exe -s -o nul -m 3 http://localhost:33316/api/v2/health
    if not errorlevel 1 goto ready
    ping -n 2 127.0.0.1 >nul
)
:ready
:openbrowser
start "" http://localhost:33316
```
**必须**：bat 存成 **GBK**（`iconv -f UTF-8 -t GBK`）—— cmd 对 UTF-8 批处理有解析 bug，会把中文行拆成多条命令报"不是内部或外部命令"。**别用 `chcp 65001`**。
**别用 `timeout /t N`**（会命中 Git for Windows 的 GNU timeout.exe 报错），用 `ping -n N 127.0.0.1 >nul`。

## 桌面客户端（「桌面端小莫」，Electron）

官方原生客户端，能力比网页多：**直接读写本地项目文件、把本机接入为可控节点、多标签工作区**。
用户在微信/作者宣传里看到的就是它，**别回\"只有网页版\"**。

- 发布在 GitHub Releases：tag `desktop-v<版本>`，产物 `mobius-desktop-<版本>-win-x64.zip`（mac 另有 dmg/zip、arm64/x64）
- **产物版本必须与 `mobius/desktop/package.json` 的 `version` 一致** —— 生成 manifest 的脚本以此为准，不一致会让下载页指向不存在的文件

### 墙内必踩：后端的自动同步器永远失败
`backend/services/sync-desktop-builds.ts` 会定时从 GitHub Releases 拉产物到 `mobius/desktop-builds/`。
墙内 + S302 劫持下它一直刷 `connect ECONNREFUSED 127.0.0.1:443`
（机理：hosts 劫持按网络命名空间生效，WSL 里的 127.0.0.1 不是 Windows 的回环 →
详见 skill `gfw-network-troubleshooting` 的「hosts 劫持按命名空间生效」条）。
**症状**：网页里「下载客户端」入口报错 / 404（`/desktop-builds/manifest.json` 不存在）。

### 手动喂（已实测通过）
```bash
# 1) 先用加速镜像下 release 附件（镜像死活是时效性事实，先探：
#    bash <gfw skill>/scripts/github_mirror_probe.sh mobius-system mobius desktop-v0.0.29 mobius-desktop-0.0.29-win-x64.zip ）
curl -L --retry 3 --retry-delay 5 -o mobius-desktop-0.0.29-win-x64.zip \
  'https://ghfast.top/https://github.com/mobius-system/mobius/releases/download/desktop-v0.0.29/mobius-desktop-0.0.29-win-x64.zip'
# 2) 放进 desktop-builds（文件名必须保持 mobius-desktop-<版本>-<os>-<arch>.<ext> 结构，脚本靠它解析）
D=~/mobius-main/mobius/desktop-builds; mkdir -p $D && cp mobius-desktop-0.0.29-win-x64.zip $D/ && chown -R mobius:mobius $D
# 3) 生成 + 校验 manifest（脚本自己算 size/sha256，version 读 desktop/package.json）
cd ~/mobius-main
python3 scripts/desktop_manifest.py generate --dir mobius/desktop-builds
python3 scripts/desktop_manifest.py validate --dir mobius/desktop-builds
```
**验证**：`/desktop-builds/manifest.json` → 200；zip 支持断点（range 请求 → 206）。
之后网页里的下载入口也能用，客户端填 `http://localhost:33316` + admin 账号即可。

**另一个前提**：客户端的「把本机接入为可控节点」走 SSH（配置 `MOBIUS_SSH_PORT=33318`），
而 `start.py` **不会起 sshd** —— 实测启动后 33318 与 22 都没监听。要用这个功能得自己
`service ssh start`（WSL 无 systemd）并配免密钥。客户端的账号密码是本地存的，会提前 10 min 用账号密码重登续 JWT。

## 坑 4：改 `.env` 后 `pm2 restart` 不生效（PM2 env 快照）★

`mobius/ecosystem.config.js` 用 `envKeys` 白名单把 env 在 **PM2 启动那一刻**快照下来
（`inheritedEnv`），`pm2 restart --update-env` 沿用旧快照 → **改了 `.env` 行为不变**，
而 `pm2 list` / uptime 一切正常，极易误判成「配置写法错了」。

**正解：重跑启动器**（它重新 `load_dotenv` 再重建 PM2 应用，代价是重编前端 ~1 分钟）：

```bash
wsl -d Ubuntu2204 -u mobius -- bash -lc 'cd ~/mobius-main && python3 start.py --detach'
```

判据用**接口行为**，不要用 pm2 status。实例：关掉密码登录后
`POST /api/auth/login {"username":"admin"}` 应从 `400 Missing credentials` 变成 `200 + token`。

★ 连带一个坑：Hermes 终端**会脱敏输出**里 `<...PASSWORD|SECRET|TOKEN|KEY>=值` 的行
（你只会看到 `***`），所以 `--- 改前 ---` / `--- 改后 ---` 长得一模一样、无法确认 sed 生效没。
用布尔判定（`grep -qx 'X=false' .env && echo YES`）或换形再读，**别以为文件内容真是 `***`**。

## 坑 5：网页「下载客户端」入口 404 —— 后端同步 GitHub 必失败，得手动喂

后端有 desktop-sync 服务自动从 GitHub Releases 拉桌面端安装包，墙内日志一直刷
`[mobius/desktop-sync] 同步异常(下次重试): connect ECONNREFUSED 127.0.0.1:443`
（S302 把 github.com 钉到 127.0.0.1:443，而 **WSL 里的 127.0.0.1 不是 Windows 的**）
→ `/desktop-builds/manifest.json` 永远 404，下载页报「请稍后再试」。

手动喂只需一条：

```bash
bash scripts/feed-desktop-builds.sh <下载好的zip路径>
```

（拷进 `<proj>/mobius/desktop-builds/` → `scripts/desktop_manifest.py generate` → `validate`；
文件名/版本必须与 `mobius/desktop/package.json` 一致。）

全部细节 —— 配置重启语义、免密码登录开关、脱敏读法、桌面端喂法与验证
→ `references/post-install-config-and-artifacts.md`

## 常用运维命令
```bash
# 服务状态
wsl -d Ubuntu2204 -u mobius -- bash -lc 'cd ~/mobius-main/mobius && npx --no-install pm2 list'
# 日志
wsl -d Ubuntu2204 -u mobius -- bash -lc 'cd ~/mobius-main/mobius && npx --no-install pm2 logs mobius-system'
# 停止
wsl -d Ubuntu2204 -u mobius -- bash -lc 'cd ~/mobius-main/mobius && npx --no-install pm2 stop mobius-system'
wsl --shutdown      # 整个 WSL 停掉
```
注意：`wsl -- <bash -c "...">` 里的 `$PATH`/`$?` 会被**外层 Windows bash 提前展开**（导致语法错误）。用单引号包、或干脆用全路径 `/usr/local/bin/node`。

## 资源占用（实测，8G 机器）
待机时 WSL 内存约 480MB、CPU 负载 0.01（pm2 后端 114M + token 代理 75M + esbuild）；**没有 agent 会话在跑时几乎不占机器**。agent 进程只在新建会话/发任务时以 tmux 会话形式起。
WSL 一关服务全没（`wsl --shutdown` / 重启电脑后**不会自启**），靠桌面启动器拉起来。

## 支持文件
- `references/post-install-config-and-artifacts.md` — **装完之后**：改 `.env` 的正确重启方式
  （PM2 env 快照坑）、`ENABLE_PASSWORD_LOGIN` 免密码登录语义与验证、读被脱敏的 `.env` 值、
  桌面端 `/desktop-builds/` 手动喂法全命令
- `scripts/feed-desktop-builds.sh` — 一键把离线下好的桌面端 zip 喂进 `/desktop-builds/`
  （校验 zip 魔数 + 版本一致性 → 生成 manifest.json → 校验）
- 装/跑/排查的上游背景（WSL2 安装、Node PATH、接模型、启动排障）→ skill `windows-install-preflight`
  及其 `references/wsl2-install-cn.md`、`references/agent-os-model-wiring.md`
