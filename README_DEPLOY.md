新建 Vultr Ubuntu 服务器
↓
SSH 登录
↓
复制一条命令
↓
自动安装 Docker、Git、基础工具
↓
自动拉取 GitHub 项目
↓
自动配置 .env
↓
自动启动 docker compose

## 二、服务器要求

推荐系统：

Ubuntu 22.04 LTS
Ubuntu 24.04 LTS

推荐配置：

1 核 1G：仅适合轻量测试
1 核 2G：适合小型项目
2 核 4G：适合正式一点的服务

## 三、一键部署命令

首次部署时，SSH 登录服务器：

bash
ssh root@你的服务器IP

然后执行：

bash
curl -fsSL https://raw.githubusercontent.com/你的用户名/你的仓库/main/setup.sh | bash

如果需要临时指定仓库、分支、项目名，可以使用：

bash
curl -fsSL https://raw.githubusercontent.com/你的用户名/你的仓库/main/setup.sh |
APP_NAME=my-app
PROJECT_REPO=https://github.com/你的用户名/你的仓库.git
PROJECT_BRANCH=main
bash

## 四、部署后的常用命令

进入项目目录：

bash
cd /opt/my-app

查看容器状态：

bash
docker compose ps

查看日志：

bash
docker compose logs -f

重启服务：

bash
docker compose restart

停止服务：

bash
docker compose down

重新构建并启动：

bash
docker compose up -d --build

## 五、环境变量说明

`.env.example` 可以提交到 GitHub。

`.env` 不要提交到 GitHub。

首次部署时，如果服务器上没有 `.env`，脚本会自动执行：

bash
cp .env.example .env

部署完成后，如果需要修改配置：

bash
nano /opt/my-app/.env

修改后重启：

bash
cd /opt/my-app
docker compose restart

## 六、销毁与复活

不用服务器时，可以直接在 Vultr 后台 Destroy。

下次重新创建服务器后，再次执行一键部署命令即可恢复环境。

## 七、注意事项

1. 不要把真实密码、Token、密钥提交到 GitHub。
2. `.env` 应加入 `.gitignore`。
3. `docker-compose.yml` 中建议给服务添加：

yaml
restart: unless-stopped

4. 如果使用域名，需要把域名 A 记录解析到 Vultr 服务器 IP。
