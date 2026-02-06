# 🧗 了个 🧱

基于 Xray (VLESS + Reality + XTLS Vision) 的 VPN 解决方案

## 📋 目录

- [特性](#特性)
- [项目结构](#项目结构)
- [服务端部署](#服务端部署)
  - [事前准备](#事前准备)
  - [配置生成](#配置生成)
  - [部署](#部署)
- [客户端配置](#客户端配置)
  - [更新规则文件](#更新规则文件)
  - [更新配置](#更新配置)
  - [启动服务](#启动服务)
- [配置管理](#配置管理)
- [故障排除](#故障排除)
- [参考资源](#参考资源)
- [XHTTP over HTTP/3（h3/QUIC）](#xhttp-over-http3h3quic)

## ✨ 特性

- **VLESS + Reality + XTLS Vision**: 高性能、低延迟的代理协议
- **路径入口（VLESS over XHTTP）**: 通过 `blog.<root_domain>` + `/<xhttp_path>` 提供可选的“看起来像正常 Web 请求”的入口（由 Nginx 转发到本地 Xray）
- **智能路由**: 自动分流国内外流量
- **广告拦截**: 内置广告域名拦截
- **WireGuard 集成**: 支持 Cloudflare WARP
- **配置管理**: 自动化配置生成和恢复脚本

## 📁 项目结构

```
my-vpn/
├── xray/
│   ├── config.json          # 服务端配置
│   └── client-config.json    # 客户端配置
├── nginx/
│   ├── nginx.conf           # Nginx 主配置
│   └── conf.d/
│       └── blog.conf        # 网站配置
├── letsencrypt/
│   └── dns_tokens.ini       # DNS 验证配置
├── pre_handle.sh            # 配置生成脚本
├── reverse_handle.sh        # 配置恢复脚本
├── start.sh                 # 一键部署脚本
├── install_*.sh             # 安装脚本
├── geoip.dat                # IP 地理位置数据库
└── geosite.dat              # 域名分类数据库
```

## 🖥️ 服务端部署

### 事前准备

1. **准备域名和服务器**
   - 准备一个域名（例如：`your.domain`）
   - 准备一台海外服务器（推荐使用 VPS）

2. **获取 DNS API Token**
   - Cloudflare: 在 [API Tokens](https://dash.cloudflare.com/profile/api-tokens) 创建 Token
   - 或使用其他 DNS 提供商（如 DigitalOcean）

3. **安装 Xray**
   ```bash
   bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
   ```

### 配置生成

#### 步骤 1: 生成密钥和 UUID

```bash
# 生成 Reality 密钥对
output=$(xray x25519)

# 生成 UUID 和路径
export vless_uuid=$(xray uuid)
export xhttp_path=$(xray uuid)

# 设置域名（请替换为你的实际域名）
export root_domain=your.domain
export website_domain=web.your.domain  # 可选：仅用于 blog.conf 的 server_name（不影响入口分流）

# 提取密钥
export reality_pri_key=$(echo "$output" | sed -n 's/Private key: \(.*\)/\1/p')
export reality_pub_key=$(echo "$output" | sed -n 's/Public key: \(.*\)/\1/p')
```

#### 步骤 2: 保存配置到文件（可选但推荐）

```bash
# 创建配置文件
cat > .local.credentials << EOF
vless_uuid=$vless_uuid
xhttp_path=$xhttp_path
root_domain=$root_domain
website_domain=$website_domain
reality_pri_key=$reality_pri_key
reality_pub_key=$reality_pub_key
cloudflare_token=your_cloudflare_token_here
EOF
```

> **注意**: 请将 `your_cloudflare_token_here` 替换为你的实际 Cloudflare API Token

#### 步骤 3: 配置 DNS 验证

编辑 `letsencrypt/dns_tokens.ini`，设置你的 DNS API Token：

```ini
dns_cloudflare_api_token = your_cloudflare_token_here
```

#### 步骤 4: 生成配置文件

```bash
bash ./pre_handle.sh
```

此脚本会将 `.local.credentials` 中的值替换到各个配置文件中。

### 部署

运行一键部署脚本：

```bash
bash ./start.sh
```

该脚本会：

1. 安装 Certbot 和 Nginx
2. 申请 Let's Encrypt 证书（使用 DNS 验证）
3. 配置 Nginx
4. 安装并配置 Xray
5. 重启所有服务

## 💻 客户端配置

### 更新规则文件

定期更新 `geoip.dat` 和 `geosite.dat` 以获得最新的路由规则：

```bash
# 使用 aria2 下载（推荐，支持断点续传）
aria2c -d /tmp \
  https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat \
  https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat

# 备份并替换文件
mv /usr/local/share/xray/geoip.dat /usr/local/share/xray/geoip.dat-bak
mv /usr/local/share/xray/geosite.dat /usr/local/share/xray/geosite.dat-bak
mv /tmp/geoip.dat /usr/local/share/xray/geoip.dat
mv /tmp/geosite.dat /usr/local/share/xray/geosite.dat

# 或使用 curl/wget
curl -L -o /tmp/geoip.dat \
  https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
curl -L -o /tmp/geosite.dat \
  https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
```

### 更新配置

1. **编辑客户端配置**

   编辑 `xray/client-config.json`，替换以下占位符：
   - `<this_should_be_replaced_by_root_domain>` → 你的服务器域名（用于 Reality 出口等）
   - `<this_should_be_replaced_by_vless_uuid>` → 服务端的 UUID
   - `<this_should_be_replaced_by_reality_pub_key>` → 服务端的 Reality 公钥
   - `<this_should_be_replaced_by_xhttp_path>` → 服务端的 xhttp 路径

   **若使用 XHTTP 出口（如 proxy-cursor，供 WARP 拨号等）**：该出口的 `tlsSettings.serverName` 应设为 **`blog.<root_domain>`**，这样流量才会经 Nginx 8443（Let's Encrypt）反代到 Xray 2024；若设为 `<root_domain>` 会进 1443，Reality 与普通 TLS 不兼容会导致连接失败。

2. **复制配置文件**

   ```bash
   # Linux
   cp xray/client-config.json /usr/local/etc/xray/config.json

   # macOS (Homebrew)
   cp xray/client-config.json /opt/homebrew/etc/xray/config.json
   ```

### 启动服务

```bash
# Linux (systemd)
sudo systemctl restart xray
sudo systemctl status xray

# macOS (Homebrew)
brew services restart xray
brew services list
```

## 🔄 流量链路

### 翻墙链路小结

- **一般海外网站**：本机应用 → 系统/应用代理 (10800/10801) → Xray 客户端 → 出站 **proxy-vision** (VLESS + Reality + XTLS Vision) → 公网 443 → Nginx Stream → **1443 (Reality)** → Xray 服务端 → **direct**。**不经过 Let's Encrypt。**
- **Cursor / OpenAI 等（走 WARP）**：本机应用 → 代理 → Xray 客户端 → 出站 **warp**（其 `dialerProxy` 为 **proxy-cursor**）→ 先建立 **proxy-cursor** (VLESS over XHTTP + TLS) → 公网 443，**SNI 需为 blog.\<root_domain\>** → Nginx Stream → **8443** → Nginx 用 **Let's Encrypt** 终结 TLS → 反代到 **2024 (XHTTP)** → Xray 服务端 → **wireguard (WARP)**。**这条链才用到 Let's Encrypt。**

**重要**：走 XHTTP 的出口（如 proxy-cursor）在客户端里必须把 `serverName` 设为 **`blog.<root_domain>`**，这样 443 才会被 Nginx 分到 8443，否则会进 1443（Reality），协议不匹配会失败。

### 架构概览

```
互联网 (443/tcp)
  │
  └─ Nginx Stream (443/tcp) - SNI 分流
      │
      ├─ SNI: blog.<root_domain>
      │   │
      │   └─ → Nginx HTTPS (127.0.0.1:8443)  ← Let's Encrypt 证书
      │       ├─ location /<xhttp_path> → Xray XHTTP (127.0.0.1:2024)
      │       └─ location / → Blog (127.0.0.1:3001)
      │
      └─ 其他 SNI (如 <root_domain>)
          │
          └─ → Xray Reality (127.0.0.1:1443)  ← 无 LE，Reality 自签
              │
              ├─ Reality 协议匹配 → 处理代理流量 → direct / wireguard
              │
              └─ fallback (非 Reality 流量) → Xray XHTTP (127.0.0.1:2024)
```

### 主要流量路径

#### 1. Reality 代理链路（proxy-vision，主力）

```
[客户端应用]
  │
  └─ SOCKS5/HTTP (127.0.0.1:10800/10801) → Xray Client
      │
      ├─ 路由规则匹配
      │   ├─ 中国 IP/域名 → direct（直连）
      │   ├─ 广告域名 → block（拦截）
      │   ├─ Cursor/OpenAI 等 → warp（见下，经 proxy-cursor + WARP）
      │   └─ 海外流量 → proxy-vision（代理）
      │
      └─ proxy-vision outbound (VLESS + Reality + XTLS Vision)
          │
          └─ <root_domain>:443/tcp
              │
              └─ Nginx Stream (SNI 分流)
                  │
                  └─ SNI ≠ blog.<root_domain> → Xray Reality (127.0.0.1:1443)
                      │
                      └─ Reality 解密 → 目标由服务端 direct 出站访问
```

**特点：**

- 使用 Reality 协议伪装，不经过 Let's Encrypt
- XTLS Vision 减少加解密开销
- Nginx Stream 通过 SNI 分流，使用 Proxy Protocol 传递真实 IP
- Reality 入站配置了 fallback 到 XHTTP 入站（端口 2024）

#### 2. XHTTP 路径入口（proxy-cursor，常用于 WARP 拨号）

**方式 A：经 Nginx HTTPS（推荐，走 8443 + Let's Encrypt）**

```
[客户端] → 出站 proxy-cursor (XHTTP + TLS)
  │
  └─ 连接 blog.<root_domain>:443，SNI = blog.<root_domain>
      │
      └─ Nginx Stream → Nginx HTTPS (127.0.0.1:8443)
          │
          └─ location /<xhttp_path> → proxy_pass → Xray XHTTP (127.0.0.1:2024)
              │
              └─ 处理 VLESS 代理流量 → 服务端出站（如 wireguard/WARP）
```

**要点**：客户端里使用 XHTTP 的出口（如 proxy-cursor）必须设置 **`serverName`: `blog.<root_domain>`**，这样才会进 8443，由 Nginx 用 Let's Encrypt 终结 TLS 再反代到 2024。

**方式 B：经 Reality fallback（SNI = \<root_domain\> 时）**

```
[客户端] → <root_domain>:443，SNI = <root_domain>
  │
  └─ Nginx Stream → Xray Reality (127.0.0.1:1443)
      │
      └─ 非 Reality 流量 → fallback → Xray XHTTP (127.0.0.1:2024)
```

若客户端 XHTTP 出口的 serverName 设为 `<root_domain>`，会走此路径；Reality 入站会把“不像 Reality”的流量 fallback 到 2024。若希望 XHTTP 走 8443（证书统一、看起来像正常网站），请用方式 A 并设置 serverName 为 `blog.<root_domain>`。

#### 3. WARP 链路（Cursor/OpenAI 等）

```
[访问 Cursor/OpenAI 等]
  │
  └─ 路由 → outbound warp
      │
      └─ warp 的 dialerProxy = proxy-cursor
          │
          └─ 先建 proxy-cursor 连接（见上：blog.<root_domain> → 8443 → 2024）
              │
              └─ 服务端 Xray 收到后经 wireguard (WARP) 出站访问目标
```

#### 4. Web 访问（Blog）

```
[浏览器] → blog.<root_domain>:443/tcp
  │
  └─ Nginx Stream → Nginx HTTPS (127.0.0.1:8443)
      │
      └─ location / → Blog (127.0.0.1:3001)
```

**特点：** 正常 Web 访问，不经过代理；使用 Let's Encrypt 证书提供 HTTPS。

### Let's Encrypt 在链路中的位置

| 组件 | 作用 |
|------|------|
| **Nginx stream (443)** | 按 SNI 分流：`blog.<root_domain>` → 8443，其它 → 1443。 |
| **Nginx http (8443)** | 仅处理 **blog.<root_domain>**：用 **Let's Encrypt** 终结 TLS；`/` 给博客(3001)，`/<xhttp_path>` 反代到 Xray 2024。 |
| **Let's Encrypt** | 只为 8443 的 HTTPS 提供证书，即只服务「先到 8443」的流量（博客 + XHTTP 入口）。 |
| **Xray 1443** | Reality 入站，不涉及 LE。 |
| **Xray 2024** | XHTTP 入站，仅由 Nginx 从 8443 反代而来时才会被用到。 |

### 端口映射

| 端口      | 服务         | 协议   | 说明                                            |
| --------- | ------------ | ------ | ----------------------------------------------- |
| **443**   | Nginx Stream | TCP    | 入口，SNI 分流                                  |
| **1443**  | Xray Reality | TCP    | Reality 协议处理（仅本地，接受 Proxy Protocol） |
| **2024**  | Xray XHTTP   | TCP    | XHTTP 路径入口（仅本地）                        |
| **8443**  | Nginx HTTPS  | HTTPS  | Web 入口（仅本地回环，支持 HTTP/2 和 QUIC）     |
| **3001**  | Blog 服务    | HTTP   | 博客服务器（仅本地）                            |
| **10800** | Xray SOCKS   | SOCKS5 | 客户端本地代理                                  |
| **10801** | Xray HTTP    | HTTP   | 客户端本地代理                                  |

### 路由规则（客户端）

客户端路由按以下顺序匹配（以当前配置为例）：

1. **特定域名**（如 Cursor、OpenAI、ChatGPT） → `warp`（经 proxy-cursor 上 VPS，再经 WARP 出站）
2. **中国/私有域名** → `direct`（直连）
3. **海外流量** → `proxy-vision`（VLESS + Reality + XTLS Vision，默认代理）
4. **广告域名** → `block`（拦截）

其中 `warp` 的 `dialerProxy` 为 `proxy-cursor`，即先通过 XHTTP + TLS 连接 `blog.<root_domain>`，再经服务端 WARP 访问目标。

### DNS 解析（客户端）

- **中国域名** → 使用国内 DNS（223.5.5.5, 114.114.114.114）
- **海外域名** → 使用海外 DNS（1.1.1.1, 8.8.8.8，含 IPv6 DoH）
- **查询策略**：`UseIP`（优先使用 IP 匹配）

### 服务端出站

服务端 Xray 配置了以下出站：

- **wireguard**: Cloudflare WARP 出站
- **direct**: 直连出站
- **block**: 黑洞出站（拦截）

服务端不配置路由规则，所有流量直接转发到目标服务器。

## 🔧 配置管理

### 恢复配置到模板

如果需要将已配置的文件恢复为模板（例如提交到 Git），运行：

```bash
bash ./reverse_handle.sh
```

此脚本会将所有实际配置值替换回占位符。

### 重新生成配置

如果已经运行过 `reverse_handle.sh`，可以再次运行：

```bash
bash ./pre_handle.sh
```

## 🔍 故障排除

### Xray 启动失败

1. **检查配置文件语法**

   ```bash
   xray -test -config /usr/local/etc/xray/config.json
   ```

2. **查看错误日志**

   ```bash
   tail -f /var/log/xray/error.log
   # 或 macOS
   tail -f /opt/homebrew/var/log/xray/error.log
   ```

3. **常见错误**
   - `empty "shortIds"`: 已修复，如果仍出现，检查 `realitySettings` 中是否包含空的 `shortIds: []`
   - `failed to load config`: 检查 JSON 语法是否正确
   - `permission denied`: 检查文件权限和 Xray 用户权限

### 连接失败

1. **检查服务状态**

   ```bash
   systemctl status xray
   systemctl status nginx
   ```

2. **检查端口监听**

   ```bash
   netstat -tlnp | grep -E '443|1443|2024|8443|3001'
   # 或
   ss -tlnp | grep -E '443|1443|2024|8443|3001'
   ```

3. **检查防火墙**

   ```bash
   # Ubuntu/Debian
   sudo ufw status
   sudo ufw allow 443/tcp

   # CentOS/RHEL
   sudo firewall-cmd --list-all
   sudo firewall-cmd --permanent --add-service=https
   sudo firewall-cmd --reload
   ```

### DNS 解析问题

1. **检查 DNS 配置**
   - 确保客户端配置中的 DNS 设置正确
   - 检查 `geoip.dat` 和 `geosite.dat` 是否最新

2. **测试 DNS 解析**
   ```bash
   dig @1.1.1.1 google.com
   ```

## 📚 参考资源

- [Xray 官方文档](https://xtls.github.io/)
- [Reality 协议说明](https://github.com/XTLS/REALITY)
- [v2ray-rules-dat](https://github.com/Loyalsoldier/v2ray-rules-dat) - 路由规则数据库

## 📝 注意事项

- ⚠️ **安全**: 请妥善保管 `.local.credentials` 文件，不要提交到 Git
- ⚠️ **备份**: 修改配置前建议先备份
- ⚠️ **更新**: 定期更新 Xray 和规则文件以获得最佳性能和安全性
- ⚠️ **日志**: 生产环境建议将日志级别设置为 `error` 或 `warning`

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

**免责声明**: 本项目仅供学习交流使用，请遵守当地法律法规。
