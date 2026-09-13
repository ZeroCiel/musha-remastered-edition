# 给自托管 Agent OS / 编码 CLI 接模型（走后台 API，不手点表单）

**触发**：项目装起来了（见 `wsl2-install-cn.md` §8），要把它接到模型 API 上。
项目自带 Web 后台「模型接入」，用户又讨厌对着表单猜字段 —— 这时**别让他点表单**，
直接读源码找出后台 REST API 写进去，最后用一条命令做端到端冒烟。

实测对象：Mobius 1.9.0 + DeepSeek key。结论对同类项目（自带 admin 后台的 agent OS）通用。

---

## 0. 先定一个原则：模型 ID 问 API，别问 memory

★ **不要凭印象填模型名。** 实测 `deepseek-chat` 这种"经典名"在这家已经不存在了：

```bash
curl -s https://api.deepseek.com/v1/models -H "Authorization: Bearer $KEY" \
  | python -c "import sys,json;print([m['id'] for m in json.load(sys.stdin)['data']])"
# 实测返回：['deepseek-flash', 'deepseek-v4-pro']
```

先花 3 秒列一次，比建好渠道再排错便宜得多。**这条对任何国产/中转站都适用。**

## 0b. 同一个 key 可能同时支持两种协议（决定能喂哪些 CLI）

同一把 DeepSeek key 实测两条路都 200：

| 协议 | 端点 | 能给谁用 |
|---|---|---|
| OpenAI Responses | `POST https://api.deepseek.com/v1/responses` | **Codex CLI**（`wire_api="responses"`） |
| Anthropic Messages | `POST https://api.deepseek.com/anthropic/v1/messages` | **Claude Code**（`ANTHROPIC_BASE_URL`） |

→ 国产模型**不一定需要中转站**，先各发一条最小请求探一下，再决定是走 Codex 还是 Claude Code 标签。

---

## 1. 摸后台 API（读源码，别猜路径）

```bash
# 1) 路由挂载点：在 server 入口里找
grep -nE "app\.use\('/api" <proj>/server.js
# 2) 具体端点：在路由文件里找
grep -nE "router\.(get|post|put|delete)\('[^']*(model|codex|claude|harness)[^']*'" <proj>/backend/routes/admin.ts
# 3) 请求体字段：读 service 层的 upsert 函数（字段名 + 抛错条件都在那）
#    <proj>/backend/services/model-access.ts
```

Mobius 实测结果：

```
POST /api/auth/login                 {username, password}      → {token, user}   (JWT 7 天)
GET  /api/admin/model-access/codex                              → 渠道列表
POST /api/admin/model-access/codex   <body>                     → 新建
PUT  /api/admin/model-access/codex/:key  <body>                 → 修改
DEL  /api/admin/model-access/codex/:key
# 同族还有 /model-access/claude-code 和 /model-access/deepseek-harness 三个 tab
```

- 认证头：`Authorization: Bearer <token>`
- 后台密码在 `.env` 的 `MOBIUS_BOOTSTRAP_USERS`（格式 `id:password:role:显示名`），
  或首次配置脚打印的凭据（见 §8.4 of `wsl2-install-cn.md`）

★ 拼 JSON 别用 `curl -d`：`config_toml` 是多行 TOML，转义会很痛。
用 `execute_code` 里的 `urllib` + `json.dumps`，一次跑完 login→建→复查。

## 2. 建渠道时 TOML 的两个硬约束（报错原文 + 修法）

后台对 `config_toml` 做校验，**两条都实测踩过**：

| 报错 | 真因 | 修法 |
|---|---|---|
| `config_toml 必须包含 api_key (<key>)` | 密钥放在单独的 `secret_value` 字段时，TOML 里**仍必须有一行 `api_key`** | TOML 里写占位符 `api_key = "<API_KEY>"`，真 key 留在 `secret_value` |
| `config_toml 的 env_key (X) 必须和秘钥名 (Y) 一致` | TOML 的 `env_key` 与请求里的 `secret_env_key` 不同名 | 两处写同一个变量名（如都用 `DEEPSEEK_API_KEY`） |

- 项目认的占位符**只有两个**：`<API_KEY>` 和 `REPLACE_WITH_ENV_OR_SECRET_MANAGER`
  （比对时 `toUpperCase()`；命中即视为占位符，于是真正生效的 key 来自 `secret_value`）。
  随手编的 `"replace-me-auth-token"` **不在**白名单里 —— 它会被当成真 key 用。
- 请求体字段（codex 渠道）：
  `{channel, label, codex_model, secret_env_key, secret_value, config_toml, enabled}`
  —— `channel` 是英文短名，同时决定 `~/.codex/<channel>.config.toml` 的文件名。

## 3. Codex CLI 的配置：`wire_api = "chat"` 已经不能用了

★ **这是本轮最硬的一个坑：直接启动失败，配置都加载不了。**

```
Error loading config.toml: `wire_api = "chat"` is no longer supported.
How to fix: set `wire_api = "responses"` in your provider config.
```

Codex CLI 0.144.6 只认 `responses`。而绝大多数国产/中转端点对外是
**OpenAI chat-completions** 风格 —— 所以顺序是：
**先测端点支不支持 `/v1/responses`（§0b），再决定能不能给 Codex 用**；
不支持就改走 Claude Code 标签，别硬填 `chat`。

可用配方（实测通过）：

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

落盘位置 `~/.codex/<channel>.config.toml`；会话侧用 `codex --profile <channel>` 指定。

### 端到端冒烟（必做，一条命令）

```bash
export DEEPSEEK_API_KEY=sk-...
codex --profile deepseek exec -s read-only --skip-git-repo-check "只回复两个字：成功"
```

成功的样子（含要核对的几行）：
```
model: deepseek-v4-pro
provider: deepseek
codex
成功
tokens used
10,563
```
- `-s read-only` 免审批；`--skip-git-repo-check` 允许在非 git 目录跑（冒烟用）
- 沙箱需要 `bubblewrap`：缺了只是 warning（用内置的）；`sudo apt install bubblewrap` 可消除
- `apt` 装 bubblewrap 后 `command -v bwrap` 应为 `/usr/bin/bwrap`

## 4. ★ 费用：Codex 每个新会话先烧 ~1 万 token

实测「只回复两个字：成功」→ **tokens used 10,563**。这是 Codex 系统提示词的固定开销，
**与任务大小无关，每开一个新会话都要先交**。对在意 token 钱的用户要**主动说**，
并给出分渠道方案：

- 简单/批量活儿 → 便宜快的渠道（如 `deepseek-flash`）
- 难活儿 → 强模型渠道（如 `deepseek-v4-pro`）
- 做法：同一套 API 再建一个渠道（不同 `channel` 名 + 不同 `model`），
  在会话的模型下拉里按任务选，**别所有会话都挂最贵的**

## 5. `codex doctor` 的假警报（墙内 + 国产端点必现，别追）

```
✗ auth          no Codex credentials were found        ← doctor 不读 profile 的 env_key，实测不影响运行
✗ reachability  one or more required provider endpoints are unreachable  ← 探的是 OpenAI 官方域名（墙外）
⚠ websocket     Responses WebSocket timed out          ← 国产端点无 WS，自动回落 HTTPS
⚠ Model metadata for `deepseek-v4-pro` not found. Defaulting to fallback metadata
```

**判据只有一个：`codex exec` 实际能不能出话。** doctor 报红不等于配置错。
（`Model metadata ... fallback` 是 Codex 不认识非 OpenAI 模型名的固有提示，未能消除，属可接受。）

## 6. 备选路线（本例没用上，留档）

- `/model-access/deepseek-harness`：项目有专门的 DeepSeek harness 后端，
  字段更简单（`{key,label,provider,model,base_url,secret_value,max_tokens,enabled}`，
  provider 默认 `deepseek-official`）。**但它的运行时要求 Node 22.19+ / 24+**，
  本机从 tarball 装的是 Node 18 → 走 Codex 路线更省事。
- Claude Code 标签：`{"env":{"ANTHROPIC_BASE_URL":".../anthropic","ANTHROPIC_AUTH_TOKEN":"sk-...","ANTHROPIC_MODEL":"..."}}`

## 7. 环境备注（本轮落地值）

- 渠道 `deepseek`（label `DeepSeek`），模型 `deepseek-v4-pro`，`session_model` = `codex:deepseek`
- 配置 `~/.codex/deepseek.config.toml`；密钥变量 `DEEPSEEK_API_KEY`
- 版本：codex-cli 0.144.6 / claude-code 2.1.195 / Node v18.20.8 / npm 10.8.2
- ★ 这些版本号是**作者钉死的**（见 `wsl2-install-cn.md` §5），升级前先想清楚
  `wire_api` 这类"破坏性变更"会不会再来一次
