#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

if [ "${EUID}" -ne 0 ]; then
  SUDO="sudo"
else
  SUDO=""
fi

log() {
  echo
  echo "==> $1"
}

detect_public_ip() {
  curl -4 -fsS https://api.ipify.org || \
  curl -4 -fsS https://ifconfig.me || \
  echo ""
}

install_base_packages() {
  log "安装基础工具"
  $SUDO apt-get update
  $SUDO apt-get install -y ca-certificates curl gnupg ufw lsb-release
}

install_docker() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    log "Docker 和 Docker Compose 已安装"
    return
  fi

  log "安装 Docker Engine 和 Docker Compose Plugin"

  $SUDO install -m 0755 -d /etc/apt/keyrings

  if [ ! -f /etc/apt/keyrings/docker.asc ]; then
    $SUDO curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    $SUDO chmod a+r /etc/apt/keyrings/docker.asc
  fi

  CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"
  ARCH="$(dpkg --print-architecture)"

  cat <<EOF | $SUDO tee /etc/apt/sources.list.d/docker.sources >/dev/null
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${CODENAME}
Components: stable
Architectures: ${ARCH}
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  $SUDO apt-get update
  $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  $SUDO systemctl enable --now docker
}

prepare_env() {
  log "准备 .env 配置"

  PUBLIC_IP="$(detect_public_ip)"

  if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP="<你的服务器公网IP>"
  fi

  if [ ! -f .env ]; then
    cp .env.example .env
  fi

  if grep -q "^SERVER_IP=" .env; then
    sed -i "s/^SERVER_IP=.*/SERVER_IP=${PUBLIC_IP}/" .env
  else
    echo "SERVER_IP=${PUBLIC_IP}" >> .env
  fi

  set -a
  # shellcheck disable=SC1091
  source .env
  set +a

  APP_PORT="${APP_PORT:-3000}"
  WG_PORT="${WG_PORT:-51820}"
  WG_UI_PORT="${WG_UI_PORT:-51821}"
}

configure_firewall() {
  log "配置 UFW 防火墙"

  $SUDO ufw allow OpenSSH || true
  $SUDO ufw allow 22/tcp || true
  $SUDO ufw allow 80/tcp || true
  $SUDO ufw allow 443/tcp || true
  $SUDO ufw allow "${APP_PORT}/tcp" || true
  $SUDO ufw allow "${WG_PORT}/udp" || true

  yes | $SUDO ufw enable >/dev/null 2>&1 || true

  echo
  $SUDO ufw status verbose || true
}

start_services() {
  log "启动 Docker 服务"

  $SUDO docker compose pull
  $SUDO docker compose up -d

  echo
  $SUDO docker compose ps
}

check_services() {
  log "检查容器状态"

  if ! $SUDO docker ps --format '{{.Names}}' | grep -qx "vultr-test-web"; then
    echo "错误：vultr-test-web 没有运行"
    exit 1
  fi

  if ! $SUDO docker ps --format '{{.Names}}' | grep -qx "wg-easy"; then
    echo "错误：wg-easy 没有运行"
    exit 1
  fi

  echo "vultr-test-web 正常运行"
  echo "wg-easy 正常运行"
}

print_result() {
  echo
  echo "============================================================"
  echo "部署完成"
  echo "============================================================"
  echo
  echo "服务器公网 IP:"
  echo "${SERVER_IP:-$PUBLIC_IP}"
  echo
  echo "Nginx 测试页面:"
  echo "http://${SERVER_IP:-$PUBLIC_IP}:${APP_PORT}"
  echo
  echo "WireGuard VPN 端口:"
  echo "${WG_PORT}/udp"
  echo
  echo "wg-easy 管理后台没有暴露到公网。"
  echo "请在 Windows PowerShell 执行："
  echo
  echo "ssh -L ${WG_UI_PORT}:127.0.0.1:${WG_UI_PORT} root@${SERVER_IP:-$PUBLIC_IP}"
  echo
  echo "然后在浏览器打开："
  echo
  echo "http://127.0.0.1:${WG_UI_PORT}"
  echo
  echo "wg-easy 初始化时请填写："
  echo
  echo "Host: ${SERVER_IP:-$PUBLIC_IP}"
  echo "Port: ${WG_PORT}"
  echo
  echo "注意：Host 只填 IP，不要写 host:${SERVER_IP:-$PUBLIC_IP}"
  echo "正确 Endpoint 应该类似：${SERVER_IP:-$PUBLIC_IP}:${WG_PORT}"
  echo "============================================================"
}

main() {
  install_base_packages
  install_docker
  prepare_env
  configure_firewall
  start_services
  check_services
  print_result
}

main "$@"
