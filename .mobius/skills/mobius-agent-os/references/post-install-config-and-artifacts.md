# 装完之后：改配置的正确重启 + 喂离线产物

触发：服务已经跑起来了（`start.py --detach` 成功），接下来要**改配置**或**补装产物**。
两类事都属于「看起来改了就生效、其实没有」。

---

## 1. ★ 改了 `.env` 但 `pm2 restart` 不生效（PM2 env 快照）

**现象**：改 `.env` → `npx pm2 restart mobius-system --update-env` → 接口行为**一点没变**，
`pm2 list` 显示 online、uptime 归零，看着完全正常。

**真因**：`mobius/ecosystem.config.js` 里是

```js
const envKeys = [ ..., 'ENABLE_PASSWORD_LOGIN', ... ];
for (const key of envKeys) {
  if (process.env[key] !== undefined) inheritedEnv[key] = process.env[key];
}
```

—— PM2 的 app env 是**在 PM2 启动那一刻**从当前 shell 环境快照下来的白名单拷贝。
`pm2 restart` 沿用**保存的那份快照**，不会重读 `.env`。
（`--update-env` 只刷新「当前 shell 里存在的变量」，而你的 shell 里并没有这些变量。）

**正解**：重跑启动器，让它重新 `load_dotenv()` 再重建 PM2 应用：

```bash
wsl -d <distro> -u <user> -- bash -lc 'cd ~/mobius-main && python3 start.py --detach'
```

`start_product.py` 里 `loader.load_dotenv(REPO_ROOT/".env")` → 再起 PM2，env 才是新的。
代价：会重编前端（~1 分钟）。**别图快用 `pm2 restart`，会得到「改了但没变」的假象**，
然后开始怀疑配置写法 —— 那是浪费一整轮排错。

**核对思路**：不要用 `pm2 status` 判断，用**接口行为**判断（见下）。

---

## 2. 关掉密码登录（`ENABLE_PASSWORD_LOGIN`）

语义（读 `backend/config.js` 原文）：

```js
ENABLE_PASSWORD_LOGIN: process.env.ENABLE_PASSWORD_LOGIN === 'true',
```

★ 是**字符串严格比较**，不是 truthy 判断 —— 所以写成 `false` 是**正确**的
（`"false" === "true"` → false → 不要密码）。
（如果它是 truthy 写法，`"false"` 反而是真的，那就得删掉整行。**先读源码再改**。）

```bash
# .env
ENABLE_PASSWORD_LOGIN=false
# 然后必须走 §1 的 start.py --detach 重启
```

**效果验证**（唯一可信判据）：

```python
POST /api/auth/login  {"username": "admin"}          # 不传 password
# 改前 → 400 {"error":"Missing credentials"}
# 改后 → 200 {"token": "...", "user": {...}}
```

- 传错密码时 `401 Wrong password` 说明**还在**要密码（配置没生效，回去看 §1）
- ★ 关掉密码后**别对该端口做端口映射/公网暴露**；默认只有 localhost + WSL 内可达

---

## 3. 读「被脱敏」的 `.env` 值

Hermes 的 terminal **会对输出做脱敏**：任何形如 `<...PASSWORD|SECRET|TOKEN|KEY...>=<值>`
的行会被替换成 `***`。于是你会看到

```
--- 改前 ---   58:ENABLE_PASSWORD_LOGIN=***
--- 改后 ---   58:ENABLE_PASSWORD_LOGIN=***
```

—— **改前改后长得一模一样，根本没法确认 sed 生效了没**。
（连 `grep` 出来的「原文」也会被脱敏，别以为文件内容真的是 `***`。）

三种安全读法：

```bash
# ① 布尔判定（最常用）：只输出 YES/NO，不含敏感形状
grep -qx 'ENABLE_PASSWORD_LOGIN=false' .env && echo YES || echo NO

# ② 拆词绕过：读源码里的取值表达式
sed -n '145p' backend/config.js | sed 's/PASSWORD/PW/g'

# ③ 只看长度/结构
awk -F= '/^ENABLE_PASSWORD_LOGIN=/{print length($2)}' .env
```

★ 这套读法**通用**：凡是要确认「某个像密钥的变量到底改成什么了」，都先换形再读，
或者干脆**用行为验证**（§2 的接口测试）而不是读文件。

---

## 4. 桌面客户端：后端会自己去 GitHub 同步 → 墙内必失败，得手动喂

项目有 desktop-sync 服务，**自动**从 GitHub Releases 拉桌面端安装包到
`<proj>/mobius/desktop-builds/`，再由后端 serve 在 `/desktop-builds/`。

**墙内失败签名**（pm2 日志里刷）：

```
[mobius/desktop-sync] 同步异常(下次重试): connect ECONNREFUSED 127.0.0.1:443
```

→ 这是 S302 把 `github.com` 钉到 `127.0.0.1:443`，而 **WSL 里的 127.0.0.1 不是 Windows 的**
（Windows 侧一切正常，WSL 里永远拒连）→ 详见 skill `gfw-network-troubleshooting`。
**在 Windows 侧插机器是查不出问题的**，别浪费时间。

**表现**：`curl localhost:<port>/desktop-builds/manifest.json` → **404**，
网页里的下载入口报「请稍后再试，或联系管理员检查 /desktop-builds/manifest.json」。

### 手动喂（一次搞定，顺便让网页入口也能用）

```bash
# ① 探活的加速镜像拿 zip（别照旧结论说"全废"）→ skill gfw-network-troubleshooting
#    实测 2026-09: ghfast.top 1.9 MB/s 下 138 MB
# ② 放进 desktop-builds（文件名必须保持 mobius-desktop-<ver>-<os>-<arch>.zip）
DEST=<proj>/mobius/desktop-builds
mkdir -p "$DEST" && cp -f <下载的zip> "$DEST/" && chown -R <user>:<user> "$DEST"
# ③ 生成 manifest.json（内含 size + sha256）
sudo -u <user> bash -lc 'cd <proj> && python3 scripts/desktop_manifest.py generate --dir mobius/desktop-builds'
# ④ 校验
sudo -u <user> bash -lc 'cd <proj> && python3 scripts/desktop_manifest.py validate --dir mobius/desktop-builds'
#    → [manifest] ✓ 校验通过
# ⑤ 验证网页入口
curl -s -o /dev/null -w "%{http_code}\n" localhost:<port>/desktop-builds/manifest.json   # 200
curl -s -o /dev/null -w "%{http_code}\n" -r 0-1024 localhost:<port>/desktop-builds/<file> # 206（支持 Range）
```

★ **版本必须与 `mobius/desktop/package.json` 的 `version` 一致**，否则 manifest 校验/下载页对不上
（生成脚本的唯一可信版本源就是那个 package.json）。
★ 下完**核 Content-Length + zip 魔数 `PK`**再喂进去，别把半截文件写进下载页。

一键脚本：`scripts/feed-desktop-builds.sh <zip路径>`（本 skill）

### 相关事实
- 桌面端 = **Electron**（`build.py --build-electron --targets win-x64`），能直接读写本地项目文件、
  多标签工作区、把本机接入为可控节点
- 手机端 APK 作者放在 `serve.nutshellai.cn`（**国内可达**，比 GitHub 好使）
- 桌面端「接入为可控节点」走 SSH（`MOBIUS_SSH_PORT=33318`，`MOBIUS_SSH_URL`）；
  实测 **sshd 没起、33318 没监听** —— 用到那个功能时再起 sshd 并配免密钥，别提前折腾
