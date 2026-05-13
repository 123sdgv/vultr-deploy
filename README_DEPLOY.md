# Vultr 一键部署 WireGuard VPN

这个项目用于在 Vultr 的 Ubuntu 服务器上一键部署 VPN。

部署完成后，服务器上会运行两个服务：

1. Nginx 测试页面
2. wg-easy VPN 管理面板

Nginx 用来测试服务器和 Docker 是否正常。

wg-easy 用来创建 WireGuard VPN 客户端，比如手机、电脑、平板使用的 VPN 配置。

---

## 一、服务器要求

你需要准备一台 Vultr 服务器。

推荐配置：

- 系统：Ubuntu 22.04
- 权限：root 用户
- 网络：有公网 IPv4 地址

比如你的服务器 IP 是：

```text
139.180.133.226
```

后面的命令里，把这个 IP 换成你自己的服务器 IP。

---

## 二、项目部署位置

推荐把项目放在服务器的 `/opt` 目录下面。

进入服务器后执行：

```bash
cd /opt
```

如果服务器上还没有项目，就克隆项目：

```bash
git clone https://github.com/123sdgv/vultr-deploy.git
```

进入项目目录：

```bash
cd vultr-deploy
```

---

## 三、一键部署命令

进入项目目录后，执行：

```bash
bash setup.sh
```

执行这个命令后，脚本会自动做这些事情：

1. 安装 Docker
2. 安装 Docker Compose
3. 配置防火墙
4. 启动 Nginx 测试页面
5. 启动 wg-easy VPN 服务

你不需要一个个手动安装。

---

## 四、部署成功后会出现什么效果？

部署成功后，服务器上会出现两个 Docker 容器：

```text
vultr-test-web
wg-easy
```

你可以用下面命令查看：

```bash
docker ps
```

如果你看到类似下面的内容，就说明服务已经启动：

```text
vultr-test-web
wg-easy
```

---

## 五、Nginx 测试页面怎么访问？

浏览器打开：

```text
http://服务器IP:3000
```

比如：

```text
http://139.180.133.226:3000
```

如果页面能打开，说明：

1. 服务器能访问
2. Docker 正常
3. Nginx 测试服务正常
4. 防火墙的 3000 端口正常

如果打不开，就说明服务器、防火墙、Docker 或容器有问题，需要检查。

---

## 六、VPN 使用哪个端口？

WireGuard VPN 使用这个端口：

```text
51820/udp
```

注意，它是 UDP，不是 TCP。

防火墙必须允许：

```text
51820/udp
```

如果这个端口没打开，VPN 客户端就连不上。

---

## 七、wg-easy 管理后台怎么访问？

wg-easy 的管理后台端口是：

```text
51821
```

但是这个项目不会把 51821 直接暴露到公网。

这样做是为了安全。

所以你不能直接在浏览器打开：

```text
http://服务器IP:51821
```

这个地址正常情况下是打不开的。

正确做法是使用 SSH 隧道。

---

## 八、Windows 电脑怎么打开 wg-easy 管理后台？

在 Windows PowerShell 里面执行：

```powershell
ssh -L 51821:127.0.0.1:51821 root@服务器IP
```

比如：

```powershell
ssh -L 51821:127.0.0.1:51821 root@139.180.133.226
```

执行后，PowerShell 不要关。

然后打开浏览器，访问：

```text
http://127.0.0.1:51821
```

这时候你看到的就是服务器上的 wg-easy 管理后台。

---

## 九、第一次进入 wg-easy 要填什么？

第一次打开 wg-easy 后，会让你初始化。

如果它让你填写 Host，就填服务器公网 IP。

比如：

```text
139.180.133.226
```

不要写成：

```text
host:139.180.133.226
```

也不要写成：

```text
http://139.180.133.226
```

只填纯 IP：

```text
139.180.133.226
```

如果它让你填写端口，就填：

```text
51820
```

最终客户端配置里的 Endpoint 应该长这样：

```text
Endpoint = 139.180.133.226:51820
```

如果 Endpoint 里面出现了这种内容，就是错的：

```text
Endpoint = host:139.180.133.226:51820
```

这种配置会导致 VPN 客户端连接失败。

---

## 十、怎么创建 VPN 客户端？

进入 wg-easy 管理后台后：

1. 点击 New Client
2. 输入设备名字，比如：
   - windows-laptop
   - iphone
   - ipad
3. 创建客户端
4. 下载配置文件，或者扫描二维码

Windows 电脑可以导入配置文件。

手机可以用 WireGuard App 扫二维码。

---

## 十一、连接 VPN 后怎么测试？

连接 WireGuard VPN 后，打开浏览器访问：

```text
https://ifconfig.me
```

如果显示的是 Vultr 服务器的 IP，说明 VPN 生效了。

比如显示：

```text
139.180.133.226
```

那就代表你的电脑或手机流量已经经过这台服务器。

也可以测试：

```text
https://github.com
```

如果 GitHub 能打开，一般说明 VPN 基本正常。

---

## 十二、常用检查命令

查看 Docker 容器：

```bash
docker ps
```

查看当前项目的服务：

```bash
docker compose ps
```

查看 wg-easy 日志：

```bash
docker compose logs -f wg-easy
```

查看 Nginx 日志：

```bash
docker compose logs -f web
```

重启服务：

```bash
docker compose restart
```

停止服务：

```bash
docker compose down
```

重新启动服务：

```bash
docker compose up -d
```

更新镜像：

```bash
docker compose pull
docker compose up -d
```

---

## 十三、防火墙端口说明

这个项目会开放这些端口：

```text
22/tcp      SSH 登录服务器
80/tcp      HTTP，可选
443/tcp     HTTPS，可选
3000/tcp    Nginx 测试页面
51820/udp   WireGuard VPN
```

不会开放这个端口到公网：

```text
51821/tcp   wg-easy 管理后台
```

51821 只能通过 SSH 隧道访问。

这样更安全。

---

## 十四、如果 Nginx 页面打不开怎么办？

先检查容器：

```bash
docker ps
```

如果没有看到：

```text
vultr-test-web
```

说明 Nginx 容器没起来。

可以执行：

```bash
docker compose up -d
```

再检查日志：

```bash
docker compose logs -f web
```

---

## 十五、如果 wg-easy 打不开怎么办？

先确认你有没有开 SSH 隧道。

Windows PowerShell 应该执行：

```powershell
ssh -L 51821:127.0.0.1:51821 root@服务器IP
```

然后浏览器打开：

```text
http://127.0.0.1:51821
```

注意，不是打开：

```text
http://服务器IP:51821
```

如果还是打不开，检查容器：

```bash
docker ps
```

确认里面有：

```text
wg-easy
```

如果没有，查看日志：

```bash
docker compose logs -f wg-easy
```

---

## 十六、如果 VPN 连上了但不能上网怎么办？

先检查客户端配置里的 Endpoint。

正确格式应该是：

```text
Endpoint = 服务器IP:51820
```

比如：

```text
Endpoint = 139.180.133.226:51820
```

错误格式：

```text
Endpoint = host:139.180.133.226:51820
```

如果 Endpoint 错了，就回到 wg-easy 后台重新设置 Host。

Host 只填服务器 IP，不要加 `host:`，不要加 `http://`。

---

## 十七、这个项目最终效果

最终这个项目会做到：

1. 一条命令部署 Docker
2. 一条命令启动 Nginx 测试页
3. 一条命令启动 wg-easy VPN
4. 自动开放 VPN 需要的防火墙端口
5. wg-easy 后台不暴露到公网
6. 可以用 WireGuard 客户端连接 VPN

部署完成后，你主要用这几个地址：

Nginx 测试页：

```text
http://服务器IP:3000
```

wg-easy 管理后台：

```text
http://127.0.0.1:51821
```

VPN 端口：

```text
服务器IP:51820
```
