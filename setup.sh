#!/usr/bin/env bash
set -Eeuo pipefail

# =========================================================
# Vultr Ubuntu 一键复原脚本
# 适用场景：
# 1. 新建 Vultr Ubuntu 服务器
# 2. SSH 登录
# 3. 执行本脚本
# 4. 自动安装环境、拉取项目、启动服务
# =========================================================

# -----------------------------
# 你需要修改的默认配置
# -----------------------------

APP_NAME="${APP_NAME:-vultr-deploy}"
APP_DIR="${APP_DIR:-/opt/${APP_NAME}}"

PROJECT_REPO="${PROJECT_REPO:-https://github.com/你的用户名/你的仓库.git}"
PROJECT_BRANCH="${PROJECT_BRANCH:-main}"

# 如果你有私密 .env 文件地址，可以以后再配置
ENV_FILE_URL="${ENV_FILE_URL:-}"

# -----------------------------
# 基础函数
# -----------------------------

log() {
  echo
  echo "========== $1 =========="
}

fail() {
  echo
  echo "❌ 出错：$1"
  exit 1
}

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    fail "请使用 root 用户运行，或者使用 sudo bash setup.sh"
  fi
}

# -----------------------------
# 1. 检查系统
# -----------------------------

need_root

log "检查系统信息"

if [ ! -f /etc/os-release ]; then
  fail "无法识别系统版本"
fi

. /etc/os-release

echo "系统：${PRETTY_NAME}"
echo "项目名称：${APP_NAME}"
echo "项目目录：${APP_DIR}"
echo "Git 仓库：${PROJECT_REPO}"
echo "Git 分支：${PROJECT_BRANCH}"

# -----------------------------
# 2. 更新系统并安装基础工具
# -----------------------------

log "更新系统并安装基础工具"

apt-get update -y
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  git \
  ufw \
  unzip \
  htop

# -----------------------------
# 3. 安装 Docker
# -----------------------------

log "安装 Docker 与 Docker Compose"

if command -v docker >/dev/null 2>&1; then
  echo "Docker 已安装，跳过安装"
else
  install -m 0755 -d /etc/apt/keyrings

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc

  chmod a+r /etc/apt/keyrings/docker.asc

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list

  apt-get update -y

  apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
fi

systemctl enable docker
systemctl start docker

docker --version
docker compose version

# -----------------------------
# 4. 配置防火墙
# -----------------------------

log "配置防火墙"

ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp

# 如果你的项目临时使用 3000 端口，可以保留这一行
ufw allow 3000/tcp

ufw --force enable
ufw status

# -----------------------------
# 5. 拉取或更新项目
# -----------------------------

log "拉取 GitHub 项目"

if [ -d "${APP_DIR}/.git" ]; then
  echo "项目已存在，执行更新"
  cd "${APP_DIR}"
  git fetch origin
  git checkout "${PROJECT_BRANCH}"
  git pull origin "${PROJECT_BRANCH}"
else
  echo "首次部署，克隆项目"
  rm -rf "${APP_DIR}"
  git clone -b "${PROJECT_BRANCH}" "${PROJECT_REPO}" "${APP_DIR}"
  cd "${APP_DIR}"
fi

# -----------------------------
# 6. 配置 .env
# -----------------------------

log "配置环境变量"

cd "${APP_DIR}"

if [ -n "${ENV_FILE_URL}" ]; then
  echo "检测到 ENV_FILE_URL，正在下载 .env"
  curl -fsSL "${ENV_FILE_URL}" -o .env
elif [ ! -f ".env" ] && [ -f ".env.example" ]; then
  echo "未检测到 .env，已从 .env.example 复制"
  cp .env.example .env
elif [ ! -f ".env" ]; then
  echo "未检测到 .env 或 .env.example，创建空 .env"
  touch .env
else
  echo ".env 已存在，跳过"
fi

# -----------------------------
# 7. 启动项目
# -----------------------------

log "启动项目"

if [ -f "docker-compose.yml" ] || [ -f "compose.yml" ]; then
  docker compose pull || true
  docker compose up -d --build
else
  echo "⚠️ 未发现 docker-compose.yml 或 compose.yml"
  echo "当前脚本已完成系统环境与代码恢复，但还没有启动项目。"
  echo "后续需要根据你的项目类型补充启动命令。"
fi

# -----------------------------
# 8. 输出状态
# -----------------------------

log "部署状态"

cd "${APP_DIR}"

if [ -f "docker-compose.yml" ] || [ -f "compose.yml" ]; then
  docker compose ps
fi

echo
echo "✅ Vultr 一键复原完成"
echo
echo "项目目录：${APP_DIR}"
echo "查看日志：cd ${APP_DIR} && docker compose logs -f"
echo "重启项目：cd ${APP_DIR} && docker compose restart"
echo "停止项目：cd ${APP_DIR} && docker compose down"
echo
