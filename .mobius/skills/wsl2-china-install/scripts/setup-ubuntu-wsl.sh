#!/bin/bash
# WSL Ubuntu 导入后的配置脚本（在 WSL 内以 root 跑）
# 用法：写到 Windows 盘（如 D:\wsl-dl\setup-wsl.sh）后
#   wsl.exe -d <distro> -u root -- bash -c "sed -i 's/\r$//' /mnt/d/wsl-dl/setup-wsl.sh; bash /mnt/d/wsl-dl/setup-wsl.sh"
# 幂等，可重复跑。日志 /root/setup-wsl.log
# ★ 已修掉"Node 全局 bin 不在 PATH"这个坑（第 5 步），可直接复用。
LOG=/root/setup-wsl.log
exec > >(tee -a "$LOG") 2>&1
echo "=== setup start $(date) ==="
export DEBIAN_FRONTEND=noninteractive
step() { echo; echo "########## $* ##########"; }

# 1. apt 换清华源
step "1/9 apt 换清华源"
cp /etc/apt/sources.list /etc/apt/sources.list.bak 2>/dev/null || true
sed -i 's|http://archive.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g; s|http://security.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list
grep -E '^deb ' /etc/apt/sources.list | head -4
apt-get update -qq || { echo "!! apt update 失败"; exit 1; }

# 2. 基础包（按需增删）
step "2/9 安装基础包"
apt-get install -y --no-install-recommends \
  nano tmux proxychains4 git curl ca-certificates tini \
  python3 python3-pip make g++ procps less locales iproute2 psmisc \
  openssh-server ffmpeg unzip wget xz-utils sudo 2>&1 | tail -4
for c in tmux git curl python3 pip3; do printf "  %-10s " "$c"; command -v $c || echo "(缺)"; done

# 3. locale
step "3/9 locale"
sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen 2>/dev/null || true
locale-gen >/dev/null 2>&1 || true
printf 'LANG=en_US.UTF-8\nLC_ALL=en_US.UTF-8\n' > /etc/default/locale

# 4. pip 源 + uv
step "4/9 pip 换清华源 + uv"
mkdir -p /root/.config/pip
printf '[global]\nindex-url = https://pypi.tuna.tsinghua.edu.cn/simple\n' > /root/.config/pip/pip.conf
pip3 install --no-cache-dir uv 2>&1 | tail -2
command -v uv || echo "!! uv 没装上（不致命）"

# 5. Node（清华 nodejs-release，避开 nodesource 的 GPG 麻烦）
# ★ 关键：解出来的目录名带 -linux-x64 后缀；npm -g 的 prefix 按 symlink 真实路径推算，
#   全局包会落在这个私有 bin 里 → 必须全量软链 + 固定 npm prefix。
step "5/9 装 Node"
if command -v node >/dev/null 2>&1; then echo "已存在 node: $(node -v)"; else
  NODE_VER=v18.20.8
  cd /tmp
  curl -fsSL --retry 3 -m 900 -o node.tar.xz \
    "https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/${NODE_VER}/node-${NODE_VER}-linux-x64.tar.xz" \
    && echo "node 包下载 OK" || echo "!! node 下载失败"
  if [ -s node.tar.xz ]; then
    mkdir -p /usr/local/lib/nodejs
    tar -xJf node.tar.xz -C /usr/local/lib/nodejs && rm -f node.tar.xz
  fi
fi
D=$(ls -d /usr/local/lib/nodejs/node-v*-linux-x64 2>/dev/null | head -1)
echo "node 目录: $D"
ls "$D/bin" 2>/dev/null        # 空 = 路径取错了，下面的 glob 不会展开
if [ -d "$D/bin" ]; then
  for b in "$D"/bin/*; do ln -sf "$b" "/usr/local/bin/$(basename "$b")"; done
  printf 'export PATH=%s/bin:$PATH\n' "$D" > /etc/profile.d/nodejs.sh
  chmod 644 /etc/profile.d/nodejs.sh
fi
echo "prefix=/usr/local" > /etc/npmrc      # 以后 npm i -g 直接落 /usr/local/bin
npm config set registry https://registry.npmmirror.com 2>&1 | tail -1
export PATH="/usr/local/bin:$D/bin:$PATH"
echo "node: $(node -v 2>&1)  npm: $(npm -v 2>&1)"

# 6. 用户 + 免密 sudo（默认用户名按需改；这就是"不用记密码"）
step "6/9 建用户（免密 sudo）"
USER_NAME=mobius
if id $USER_NAME >/dev/null 2>&1; then echo "用户已存在"; else
  useradd -m -s /bin/bash -G sudo $USER_NAME
  echo "$USER_NAME:$USER_NAME" | chpasswd
fi
printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$USER_NAME" > /etc/sudoers.d/$USER_NAME
chmod 0440 /etc/sudoers.d/$USER_NAME
printf '[user]\ndefault=%s\n' "$USER_NAME" > /etc/wsl.conf
mkdir -p /home/$USER_NAME/.config/pip
printf '[global]\nindex-url = https://pypi.tuna.tsinghua.edu.cn/simple\n' > /home/$USER_NAME/.config/pip/pip.conf
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config
cat /etc/wsl.conf

# 7. code-server（国内 deb 源）
step "7/9 code-server"
if [ -x /usr/bin/code-server ]; then echo "已装"; else
  ARCH=$(dpkg --print-architecture)
  U="https://serve.nutshellai.cn/publish/auto/tutorial/code-server_4.19.1_amd64.deb"
  [ "$ARCH" = "arm64" ] && U="https://serve.nutshellai.cn/publish/auto/tutorial/code-server_4.19.1_arm64.deb"
  wget -q -T 600 -O /tmp/code-server.deb "$U" && dpkg -i /tmp/code-server.deb >/dev/null 2>&1 || apt-get -f install -y >/dev/null 2>&1
  rm -f /tmp/code-server.deb
  test -x /usr/bin/code-server && echo "code-server OK" || echo "!! code-server 没装上（不致命）"
fi

# 8. 全局 npm CLI（版本按需固定）
step "8/9 claude-code + codex"
npm install -g --registry=https://registry.npmmirror.com \
  @anthropic-ai/claude-code@2.1.195 @openai/codex@0.144.6 2>&1 | tail -4
command -v claude || echo "!! claude 没装上"
command -v codex  || echo "!! codex 没装上"

# 9. 项目代码：拷进 ext4（别在 /mnt/c 下跑 npm install，跨文件系统极慢）
# ★ npm install 要在有 package.json 的那一层跑；仓库常是 <repo>/<backend>/package.json
step "9/9 拷代码 + 装依赖"
SRC=/mnt/c/Users/Administrator/agent-os/mobius-main
DST=/home/$USER_NAME/mobius-main
if [ -d "$DST" ]; then echo "代码已存在，跳过"; else
  cp -r "$SRC" "$DST" && chown -R $USER_NAME:$USER_NAME "$DST"
  echo "已拷贝: $(du -sh $DST | cut -f1)"
fi
for sub in "." "mobius" "mobius/frontend"; do
  if [ -f "$DST/$sub/package.json" ]; then
    echo "--- npm install @ $sub ---"
    sudo -u $USER_NAME bash -lc "export PATH=/usr/local/bin:\$PATH; cd $DST/$sub && npm install --registry=https://registry.npmmirror.com --fetch-retries=5 2>&1 | tail -5"
  fi
done
chown -R $USER_NAME:$USER_NAME "$DST"

step "环境汇总"
echo "node  : $(node -v 2>&1)   npm: $(npm -v 2>&1)"
echo "python: $(python3 -V 2>&1)"
echo "tmux  : $(tmux -V 2>&1)"
echo "claude: $(command -v claude || echo 缺)   codex: $(command -v codex || echo 缺)"
df -h / | tail -1
echo "=== setup done $(date) ==="
