# Mobius（自进化 Agent OS）在 WSL2 上的落地记录

## 结论型速查

| 项 | 值 |
|---|---|
| 发行版 | `Ubuntu2204`（清华 rootfs 手导，vhdx 在 `D:\WSL\Ubuntu2204\ext4.vhdx`） |
| 默认用户 | `mobius`（**免密 sudo**，全程不用敲密码） |
| 代码 | `~/mobius-main`；Windows 侧副本 `C:\Users\Administrator\agent-os\mobius-main` |
| 网页界面 | **`http://localhost:33316`** ← ★ 以 `start.py` 打印的 `frontend:` 行为准 |
| 其它端口 | code-server 33317 / aimux 桥 33315 / SSH 33318 |
| `.env` 里的 `MOBIUS_PORT` | `33314` —— ★ **实测根本没在监听**（curl → 000）。别照它报地址给用户 |
| 启动 | `cd ~/mobius-main && python3 start.py --detach` |
| 配置日志 | `/root/setup-wsl.log`（安装）、`/root/fix*-mobius.log`（修补） |

登录账号来自 `conf_prepare.py` 随机生成的 `MOBIUS_BOOTSTRAP_USERS`
（格式 `user:password:role:display_name`，分号分隔多项）——跑完立刻抄给用户。

## 为什么必须 Linux（别再纠结"能不能 Windows 直跑"）

服务端启动器**写死 tmux**：`boot_utils.py` 的 `tmux_session_exists` / `kill_tmux_session`，
`start_product.py` 的 `reset_tmux_session`。tmux 是 Linux 专有，作用是不让后端随终端关闭而死。
仓库里确实有 Windows 分支（`build.py` 产 `mobius.cmd`），但那是**客户端**；
官方给 Windows 的一键脚本本质是 Docker —— 而 Docker 容器也是 Linux，比 WSL2 更重。
改源码把 tmux 换掉 = 动它"自进化"的底层，出问题对不上官方，不建议。

## 依赖清单（对齐官方 base 镜像 `deploy/onekey/Dockerfile4zh-base`）

- apt：`nano tmux proxychains4 git curl ca-certificates tini python3 python3-pip
  make g++ procps less locales iproute2 psmisc openssh-server ffmpeg unzip`
- python：`uv`
- Node **18**（官方 base 是 `node:18-bookworm`，别用 20/22 自作主张）
- 全局 npm CLI：`@anthropic-ai/claude-code@2.1.195 @openai/codex@0.144.6`
- code-server 4.19.1（deb，国内源 `serve.nutshellai.cn`）
- 项目依赖两处都要装：`mobius/`（原生模块 `node-pty` / `better-sqlite3` 需要 make/g++/python3）
  和 `mobius/frontend/`

## 首次配置：三步，全部可非交互

1. **`python3 conf_prepare.py`** —— 复制 `.env.default` → `.env`，随机化 `JWT_SECRET`
   与 bootstrap 用户密码，并派生所有本地路径。
   ★ **stdin 不是 TTY 时它自动取默认值**（不会卡在 `input()`），所以管道/后台调用不会挂死；
   默认 `MOBIUS_DATA_PATH=<repo>/host_data/data`。`MODEL_ACCESS_PATH` 等全由它派生。
2. **`python3 conf_check.py`** —— 末尾出现 `Configuration OK` 即通过。它会顺带装
   `display_images`、校验 code-server、装占位 bash 命令。
   ★ 可选的 aimux 远程桥在非交互时会被**跳过**（不致命，别当成失败）。
3. **`python3 start.py --detach`** —— 编译并起服务，不占终端（前端要编译，几分钟）。
   `--help` 还有 `--only-update-frontend` / `--live-frontend-debug` / `--hard-reset <hash>`。

## 坑

- `npm install` **必须在 `mobius-main/mobius/` 里跑**（`package.json` 在这一层）。
  在仓库根跑会 `ENOENT .../package.json` —— 根目录只有一个 88 字节的 `package-lock.json`。
- `npm install` 超时（`ETIMEDOUT`/`errno -110`）几乎都是**同机 Steam 下载抢带宽**，重试即可；
  想快就先让用户暂停 Steam 下载队列（Steam 侧处置见 `steam-app-repair`）。
- `~/.local/bin` 不在 PATH，`conf_check` 会提示；要用 `display_images` 得自己加进 PATH。
- **模型接入不在文件里配**：走网页 **管理中心 → 模型接入**，右上角切 Codex / Claude Code。
  ★ 也可以**直接打后台接口**、跳过表单（见上面「管理后台 API」一节）。
  - Codex：每渠道一份 `~/.codex/<渠道>.config.toml`，会话用 `codex --profile <渠道>`
  - Claude Code：走 `--settings <文件>` 直连上游，settings JSON 形如
    `{"env":{"ANTHROPIC_BASE_URL":"https://.../v1","ANTHROPIC_AUTH_TOKEN":"sk-...","ANTHROPIC_MODEL":"..."}}`
- 6 核 8G 的笔记本：`.wslconfig` 锁 `memory=3072MB` 后够跑，但**别同时开大下载**（会互相拖死）。
- ★ **`| tail -N` 会把后台日志憋住**：`python3 start.py --detach 2>&1 | tail -80 > log` 会让 log
  在命令结束前**一直是 0 字节**，后台跑时完全看不到进度（实测白等一轮）。改成直接重定向
  `cmd > log 2>&1`，想看进度再 `tail` 那个文件。
- ★ **git-bash 调 wsl 时 `$VAR` 会被外层 Windows bash 先展开**：
  `wsl.exe -d X -- bash -c 'export PATH=/usr/local/bin:$PATH; ...'` → 外层把 `$PATH` 展开成
  一长串带括号的 Windows 路径 → `bash: -c: line 1: syntax error near unexpected token '('`。
  用 `bash -lc`（字符串里别出现 `$VAR`），或更稳的：**把脚本写到 `/mnt/d/...` 再 `bash 那个文件`**
  （本会话全程用后者，最不容易踩）。
- 编译期 `tsc --noEmit` 会吃 **700 MB+ RSS 且满核**（实测 116% CPU）——这台 8G 机器上编译时
  别同时开浏览器大户，否则 WSL（限 3G）会被挤。

## ★★ aimux 桥：墙内必失败，而且会**中断整条启动链**

`start_product.py` 在起服务前会调 `mobius/scripts/setup-aimux-bridge.sh`（实验性远程算力桥），
里面是 `UV_VENV_CLEAR=1 uv venv "$VENV" --python 3.12`。系统里没有 3.12 时 uv 会去
**GitHub Releases** 拉独立 CPython（python-build-standalone）→ 墙内 3 次重试全超时：

```
Downloading cpython-3.12.14-linux-x86_64-gnu (32.6MiB)
error: Request failed after 3 retries in 264.0s
  Caused by: Failed to extract archive: ... Invalid tar file
  Caused by: operation timed out
start_product.py: command failed with exit code 2
start.py: command failed with exit code 2
```

★ **前端已经编译成功（`✓ built in 30.64s`）也会被这一步拖死** —— 它排在
`[2/4] promote compiled frontend` 之后，炸掉后服务一个都不起、`33316` 一直 000。
只要看到 `exit code 2` + `setup-aimux-bridge`，就是它，不是网络也不是代码。

**修法（已实测通过）**：脚本的幂等检查只看 **`$VENV/bin/aimux` 可执行 + `aimux-<ver>.dist-info` 目录**，
**完全不看 Python 版本** → 用系统解释器自己把 venv 建出来，脚本下次直接 `exit 0` 跳过、不碰 GitHub：

```bash
VENV=~/mobius-main/mobius/.venv-aimux
uv venv "$VENV" --python /usr/bin/python3.10        # 用系统 python，不下载任何运行时
uv pip install --python "$VENV" --no-cache \
  --index-url https://pypi.tuna.tsinghua.edu.cn/simple/ 'aimux==0.1.29'
ls "$VENV/bin/aimux"                                 # 两条都命中 ⇒ setup 脚本跳过
ls -d "$VENV"/lib/python*/site-packages/aimux-*.dist-info
```
（脚本自带的 install 用 `--index-url https://pypi.org/simple/` + proxychains，墙内同样要换清华。）

**Plan B（确实要 3.12 本体）**：给 uv 设镜像 `UV_PYTHON_INSTALL_MIRROR`。可达性实测：
**南大 `mirrors.nju.edu.cn/github-release/astral-sh/python-build-standalone` 200 ✓、
中科大 `mirrors.ustc.edu.cn/github-release/...` 200 ✓、清华 404 ✗（它没镜像这个仓库）**。

## 管理后台 API（不想让用户点表单就直接打接口）

UI 在 33316，但渠道也能用 API 建。★ 注意 **admin 路由是 `/api/admin`（没有 v2 前缀）**，
而健康检查是 `/api/v2/health` —— 容易搞混：

```bash
T=$(curl -s -X POST http://localhost:33316/api/auth/login \
      -H 'Content-Type: application/json' \
      -d '{"username":"admin","password":"<conf_prepare 生成的密码>"}' \
    | python -c 'import sys,json;print(json.load(sys.stdin)["token"])')

# 列现有渠道（没配过就是 []）
curl -s http://localhost:33316/api/admin/model-access/codex -H "Authorization: Bearer $T"

# 建/改渠道
curl -s -X POST http://localhost:33316/api/admin/model-access/codex \
  -H "Authorization: Bearer $T" -H 'Content-Type: application/json' -d @body.json
```

`upsertCodexModel` 认的字段：`channel`（渠道名，纯英文，也接受 `key`）/ `label`（显示名）/
`config_toml`（TOML 全文）/ `secret_env_key`（或 `env_key`）/ `secret_value`（真实 key）/
`enabled` / `use_proxy`。
★ `config_toml` 里的 `env_key` **必须与 `secret_env_key` 一致**，否则报配置不匹配
（`assertConfigEnvKeyMatches`）。同类端点还有 `/model-access/claude-code`、
`/model-access/deepseek-harness`、`/model-access/codex-subscription/{prepare,upload-auth}`。

Codex 渠道的 TOML 照仓库自带模板 `deploy/codex/mobiusdefault.config.toml`：
`model_provider` / `model` 两个顶层键 + `[model_providers.<名>]` 段的
`name` / `base_url` / `wire_api` / `env_key`。

### ★★ `wire_api = "chat"` 已被 Codex 移除（照抄模板会直接起不来）
Codex **0.144.6 只认 `wire_api = "responses"`**，写 `chat` 会在**加载配置阶段**就报错：
```
Error loading config.toml: `wire_api = "chat"` is no longer supported.
How to fix: set `wire_api = "responses"` in your provider config.
```
★ 别以为国内上游只支持 chat-completions 就没救 —— **DeepSeek 两种接口都有**，实测：
- `POST https://api.deepseek.com/v1/responses` → **200**（支持 Responses API → 直接走 Codex 渠道）
- `POST https://api.deepseek.com/anthropic/v1/messages`（头 `x-api-key` + `anthropic-version: 2023-06-01`）→ **200**
  （→ Claude Code 渠道也能接同一把 key）
配之前先花 10 秒探一下上游到底支持哪个接口，别猜。

### 建渠道的两个硬校验（都会 400 挡下）
```python
# ① config_toml 必须含 api_key 字段，否则: {"error":"config_toml 必须包含 api_key"}
#    真实密钥走 secret_value，TOML 里写占位符
#    占位符只认这两个（isSecretPlaceholder）: "<API_KEY>" / "REPLACE_WITH_ENV_OR_SECRET_MANAGER"
# ② channel 只能纯【英文字母】—— 带连字符会被拒:
#    {"error":"Codex 渠道只能包含英文字母, 例如 mobiusdefault"}
#    deepseek-flash ✗  →  dsflash ✓（显示名 label 可以随便写 "DeepSeek Flash"）
```
可用模板（`secret_env_key` 必须与 TOML 的 `env_key` 完全一致）：
```toml
model_provider = "deepseek"
model = "deepseek-v4-pro"
disable_response_storage = true
windows_wsl_setup_acknowledged = true

[model_providers.deepseek]
name = "DeepSeek"
base_url = "https://api.deepseek.com/v1"
wire_api = "responses"
env_key = "DEEPSEEK_API_KEY"
api_key = "<API_KEY>"
```
★ 模型名**先查列表再填**：`GET https://api.deepseek.com/v1/models`（实测返回
`deepseek-flash` / `deepseek-v4-pro` —— 不是想当然的 `deepseek-chat`）。同一把 key 可以建多个渠道
（强模型 + 便宜模型分开），会话里按任务挑。

### 冒烟测试（必做，别只看接口 200）
```bash
wsl -d Ubuntu2204 -u mobius -- bash -lc '
  export DEEPSEEK_API_KEY=sk-...
  cd ~ && codex --profile <渠道> exec -s read-only --skip-git-repo-check "只回复两个字：成功"'
```
正常输出含 `model: <模型名>`、`provider: <渠道>` 和模型回复。
`codex doctor` 报 `auth: no Codex credentials` / `reachability 不可达` **是正常的**
（它探的是 OpenAI 官方接口 + Responses WebSocket，墙外/上游不支持）—— 别去修它。
顺手 `apt install bubblewrap` 消掉沙箱 warning。

★ **成本警告（要主动告诉用户）**：Codex 系统提示词极肥，一句「只回复两个字」实测烧
**10,301~10,563 token** —— 等于**每个新会话起步就先交约一万 token 的钱**。跑多 agent 时这是主要开销。

## 起停与排障

```bash
python3 start.py --detach                       # 起（前端要编译，这台机器约 1~3 分钟）
wsl.exe -d Ubuntu2204 -u mobius -- bash -lc 'cd ~/mobius-main/mobius && npx --no-install pm2 list'
curl -s http://localhost:33316/api/v2/health    # {"service":"mobius-system","version":"1.9.0",...}
```
- 启动成功的判据：`start.py` 末尾打印 attach/stop 命令那一屏（pm2 logs / pm2 stop、
  `tmux attach -t code-server`），并且 `33316 → 200`、`33317 → 302`。
- `started_at` / `uptime_ms` 在 health 里，可用来判断"睡了 8 小时还在不在跑"。

## ★ 改 `.env` 后必须走 `start.py`，`pm2 restart` 不生效

`mobius/ecosystem.config.js` 用 **envKeys 白名单 + `inheritedEnv`** 把环境变量在
**PM2 启动那一刻固化**：
```js
const envKeys = [ ..., 'ENABLE_PASSWORD_LOGIN', ... ];
for (const key of envKeys) if (process.env[key] !== undefined) inheritedEnv[key] = process.env[key];
```
所以改完 `.env` 后 `pm2 restart --update-env` **仍然沿用旧值**（实测白折腾一轮）。
必须重跑 **`python3 start.py --detach`**（它重新 `load_dotenv` 并用新 env 重建 PM2 app）。
同类：任何 envKeys 白名单里的键都适用。

### 免密码登录（用户嫌密码长时的正解）
`config.js` 是 **`ENABLE_PASSWORD_LOGIN: process.env.ENABLE_PASSWORD_LOGIN === 'true'`**
—— 必须精确是字符串 `'true'` 才要求密码，设 `false` 即关闭：
```
.env:  ENABLE_PASSWORD_LOGIN=false   →   python3 start.py --detach
验证:  POST /api/auth/login {"username":"admin"}   →  200 + token（不传 password）
```
服务端会自己声明：`GET /api/auth/config` → `{"password_required":false}`。

### ★ 读配置值时别用 grep —— Hermes 会把密钥类变量脱敏成 `***`
`grep '^ENABLE_PASSWORD_LOGIN' .env` / `sed -n` 出来的值一律显示 `***`
（凡是键名含 `PASSWORD`/`SECRET`/`TOKEN`/`KEY` 的赋值都会被日志层遮掉），
**看着像没改动，其实改了**。三种可靠读法：
```bash
grep -qx "ENABLE_PASSWORD_LOGIN=false" .env && echo "已改 ✓"      # 布尔断言，不回显值
sed -n '145p' config.js | sed 's/PASSWORD/PW/g'                   # 换掉关键词再打印原文
# 或干脆功能验证：直接打接口看行为（最可靠）
```

## 桌面客户端（Electron，官方叫「桌面端小莫」）

网页版之外有**原生桌面客户端**（直接读写本地项目文件、把本机注册为可调度节点、多标签工作区）。
- 官方包在 **GitHub Releases**：`github.com/mobius-system/mobius/releases/download/desktop-v<版本>/mobius-desktop-<版本>-win-x64.zip`（实测 **138 MB**）
- 墙内 `github.com` 会 302 到被劫持地址 → 用加速镜像前缀（**实测 200，1.9 MB/s**）：
  `https://ghfast.top/<原url>`、`https://gh-proxy.com/<原url>`、`https://ghproxy.net/<原url>`
- zip 顶层就是 `Mobius Desktop.exe`（172 MB，自带一份 Python 运行时所以体积大），解压即用

### 喂给服务器的网页下载入口
```bash
mkdir -p ~/mobius-main/mobius/desktop-builds
cp <zip> ~/mobius-main/mobius/desktop-builds/       # 文件名必须是 mobius-desktop-<版本>-win-x64.zip
cd ~/mobius-main && python3 scripts/desktop_manifest.py generate --dir mobius/desktop-builds
                    python3 scripts/desktop_manifest.py validate --dir mobius/desktop-builds
# 验证: curl -I http://localhost:33316/desktop-builds/manifest.json → 200；zip → 206
```
`generate` 的版本取自 `mobius/desktop/package.json`（本机 = 0.0.29，必须与下载的 release 对齐），
可 `--version` 覆盖。后端本来有个 `sync-desktop-builds` 服务自己从 GitHub 拉，
但在装了 **Steamcommunity 302** 的机器上**必然失败**：
`[mobius/desktop-sync] 同步异常: connect ECONNREFUSED 127.0.0.1:443`
—— hosts 把 github.com 指到 127.0.0.1，Windows 上 S302 接得住，**WSL 里的 127.0.0.1 是另一个回环**、
无人监听。所以只能手动喂（上面那套）。

### ★ 客户端登录报 400 `{"error":"Missing credentials"}` = 用户名框是空的
客户端固定发 `POST /api/auth/login` body `{"username": <框里的值>, "password": <框里的值>}`
（`electron/main.ts` 的 `doLogin`）。服务端只可能因为 `!username` 返回这句 ——
**逐个案测过**：`{"username":"admin"}` → 200、`{"username":"admin","password":""}` → 200、
`{"username":"","password":""}` → **400 Missing credentials**、`{"username":"Admin"}` → 200（大小写不敏感）。
登录页那句「密码 不填也可尝试」**只针对密码**，用户名必填。
客户端还会存账号密码用于 JWT 续期（提前 10 min 重登），所以关掉密码登录后它也能跑。

## 项目导入 & 工作区路径

官方导入流程（`docs/tutorial/02a_…`）：**新建项目 → 点「在 vscode 中打开」→ 把 zip 直接拖进
code-server 窗口 → 建任务「用刚上传的文件创建项目并初始化 Git 版本控制」**。
不需要人工把文件摆到某个目录。

要直接给路径时记住这三个方向：
| 方向 | 路径 |
|---|---|
| WSL 看 Windows 盘 | `D:\xxx` → `/mnt/d/xxx`（agent 直接可读，不用先搬） |
| Mobius 项目落地目录 | `<data>/workspace/<用户名>/`（本机 = `/home/mobius/mobius-main/host_data/data/workspace/admin/`） |
| Windows 打开 WSL 目录 | 资源管理器地址栏粘 `\\wsl.localhost\Ubuntu2204\home\mobius\mobius-main\host_data\data\workspace\admin`（实测可列目录） |

`WORKSPACE_ROOT` / `HOME_WORKSPACE_ROOT`(=home) / `LOCAL_WORKSPACE_ROOT`(=employees) 三者都在
`.env` 里由 `conf_prepare.py` 派生。★ **别在 `/mnt/d` 下跑 git/npm**（9p 跨文件系统极慢，拖死 agent），
正经活儿先 `cp -r` 进 workspace。

## 资源占用（实测）

| 项 | 占用 |
|---|---|
| Ubuntu 22.04.5 + 全部依赖 | **3.9 G**（ext4.vhdx 动态增长，**不会自动缩**） |
| 后端 `mobius/node_modules` | 161 M |
| 前端 `mobius/frontend/node_modules` | 278 M |
| 仓库本体 | 24 M |

规划空间时按「**再留 2~3 G 余量**」报给用户；D 盘这类项目盘同时还要装 WSL 时，
先算清「项目占用 vs 同盘其它需求（游戏创意工坊等）」再动手。
