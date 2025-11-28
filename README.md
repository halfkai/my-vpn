# 🧗 了个 🧱

基于 Xray (VLESS + Reality + XTLS Vision) 和 Hysteria 2 的 VPN 解决方案

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

## ✨ 特性

- **VLESS + Reality + XTLS Vision**: 高性能、低延迟的代理协议
- **Hysteria 2**: 基于 QUIC 的加速协议
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
├── hysteria/
│   └── config.yaml          # Hysteria 2 配置
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
export reality_domain=reality.your.domain
export root_domain=your.domain
export website_domain=web.your.domain

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
reality_domain=$reality_domain
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
5. 安装并启动 Hysteria 2
6. 重启所有服务

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

   - `<this_should_be_replaced_by_root_domain>` → 你的服务器域名
   - `<this_should_be_replaced_by_vless_uuid>` → 服务端的 UUID
   - `<this_should_be_replaced_by_reality_pub_key>` → 服务端的 Reality 公钥
   - `<this_should_be_replaced_by_xhttp_path>` → 服务端的 xhttp 路径

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
   netstat -tlnp | grep -E '443|1443|2024'
   # 或
   ss -tlnp | grep -E '443|1443|2024'
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
- [Nginx SNI 分流配置](https://tabsp.com/posts/nginx-sni-vless-reality-vision-xhttp-hysteria2-web/) - 仅使用 443 端口的完美配置方案

## 📝 注意事项

- ⚠️ **安全**: 请妥善保管 `.local.credentials` 文件，不要提交到 Git
- ⚠️ **备份**: 修改配置前建议先备份
- ⚠️ **更新**: 定期更新 Xray 和规则文件以获得最佳性能和安全性
- ⚠️ **日志**: 生产环境建议将日志级别设置为 `error` 或 `warning`

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

**免责声明**: 本项目仅供学习交流使用，请遵守当地法律法规。
