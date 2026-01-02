# 流量链路分析

## 📊 架构概览

```
互联网
  │
  ├─ 客户端 (Xray Client)
  │   ├─ SOCKS5 (127.0.0.1:10800)
  │   └─ HTTP (127.0.0.1:10801)
  │
  └─ 服务端入口 (443)
      │
      ├─ Nginx Stream (443/tcp) - SNI 分流（开启 Proxy Protocol）
      │   │
      │   ├─ blog.<root_domain> → web_backend (127.0.0.1:8443)
      │   └─ 其他 → reality_backend (127.0.0.1:1443)
      │
      ├─ Xray XHTTP(h3) (udp/443) - QUIC/HTTP3 代理入口（直连 Xray）
      │   └─ VLESS + XHTTP + TLS(ALPN=h3) - 已启用，需放行防火墙/安全组
      │
      ├─ Nginx HTTPS (127.0.0.1:8443) - Web 入口（仅本机回环）
      │   ├─ /<xhttp_path> → Xray XHTTP (127.0.0.1:2024)
      │   └─ / → Blog (127.0.0.1:3001)
      │
      └─ Xray (1443, 2024, 443/udp)
          ├─ Reality (1443) - 主要代理入口（TCP，经 Nginx Stream 转发）
          ├─ XHTTP Path (2024) - 路径入口（VLESS over XHTTP，经 Nginx(8443) 转发）
          └─ XHTTP(h3) (443/udp) - QUIC/HTTP3 代理入口（直连，不经过 Nginx）
```

---

## 🔄 详细流量链路

### 场景 1: 客户端代理流量（主要路径 - Reality）

```
[客户端应用]
    │
    ├─ SOCKS5/HTTP → Xray Client (127.0.0.1:10800/10801)
    │   │
    │   ├─ 路由规则匹配
    │   │   ├─ BitTorrent → direct
    │   │   ├─ 私有/中国 IP → direct
    │   │   ├─ 广告 → block
    │   │   ├─ Instagram 等 → wireguard (WARP)
    │   │   └─ geosite:geolocation-!cn → proxy (代理)
    │   │
    │   └─ proxy outbound
    │       │
    │       └─ VLESS + Reality + XTLS Vision
    │           │
    │           └─ Reality 握手（底层为 TCP；可携带 TLS/ALPN 指纹以伪装）
    │               │
    │               └─ Reality 协议
    │                   │
    │                   └─ 目标: <root_domain>:443
    │
[互联网]
    │
    └─ HTTPS (443) → 服务端
        │
        └─ Nginx Stream (443/tcp)
            │
            ├─ SNI 读取: <root_domain>
            │   │
            │   └─ 匹配规则: default → reality_backend
            │       │
            │       └─ 转发到: 127.0.0.1:1443 (Proxy Protocol)
            │
            └─ Xray Reality Inbound (1443)
                │
                ├─ 验证 Reality 参数
                │   ├─ serverName: <root_domain>
                │   ├─ shortId: e4c59e0a8bc6f50e
                │   └─ publicKey 验证
                │
                ├─ 成功 → 处理代理流量
                │   │
                │   └─ 根据路由规则转发
                │       ├─ BitTorrent → block
                │       ├─ 私有 IP → block
                │       ├─ 中国 IP → block
                │       ├─ 广告域名 → block
                │       ├─ Instagram / api2.cursor.com 等 → wireguard
                │       └─ 其他 → direct (直连到目标)
                │
                └─ 失败 → Fallback 到 2024（Xray 内部 fallback，不经过 Nginx）
```

**关键点：**

- Reality 协议伪装成访问 `<root_domain>` 的 HTTPS 流量
- 使用 XTLS Vision 减少加解密开销
- Nginx Stream 通过 **SNI 分流**把默认流量转给 `127.0.0.1:1443`，并通过 **Proxy Protocol**把真实来源信息传给 Xray（`acceptProxyProtocol: true`）

---

### 场景 2: 路径入口（VLESS over XHTTP，经 Nginx 转发）

```
[客户端] → [服务端 443]
    │
    └─ Nginx Stream (443/tcp)
        │
        └─ SNI: blog.<root_domain> → web_backend
            │
            └─ Nginx HTTPS (127.0.0.1:8443)
                │
                ├─ 路径匹配: /<xhttp_path>
                │   │
                │   └─ proxy_pass → Xray XHTTP (127.0.0.1:2024)
                │       │
                │       └─ Xray XHTTP Inbound (2024)
                │           │
                │           └─ 处理 VLESS 流量
                │
                └─ 其他路径 → Blog (127.0.0.1:3001)
```

**关键点：**

- 这是独立的“路径入口”，通过 Nginx 的 `location /<xhttp_path>` 转发到 Xray 2024
- 当前配置为 `proxy_pass http://127.0.0.1:2024;`，因此 Xray 2024 入站为 `network: "xhttp"`
- 要命中这条路径入口，外部请求必须让 SNI 命中 `blog.<root_domain>`（否则会被 Stream 分流到 Reality 后端）

---

### 场景 3: Web 访问（Blog）

```
[浏览器] → [服务端 443]
    │
    └─ Nginx Stream (443/tcp)
        │
        └─ SNI: blog.<root_domain> → web_backend
            │
            └─ Nginx HTTPS (127.0.0.1:8443)
                │
                ├─ HTTP/2
                │
                └─ location / → Blog (127.0.0.1:3001)
                    │
                    └─ Nginx Blog Server (3001)
                        │
                        └─ 返回静态文件
```

**关键点：**

- 通过子域名 `blog.<root_domain>` 访问
- Web 入口在 `127.0.0.1:8443` 启用了 TLS，并开启了 `http2`
- Nginx 的 `Alt-Svc: h3=":443"` 已被注释，因为 `udp/443` 被 Xray 的 XHTTP(h3) 代理入口占用（不是 Web 的 HTTP/3）
- 独立的 Web 服务器配置

---

### 场景 4: XHTTP(h3) 代理入口（QUIC/HTTP3）

```
[客户端应用]
    │
    ├─ SOCKS5/HTTP → Xray Client (127.0.0.1:10800/10801)
    │   │
    │   └─ proxy-xhttp-h3 outbound
    │       │
    │       └─ VLESS + XHTTP + TLS(ALPN=h3)
    │           │
    │           └─ QUIC/HTTP3 握手
    │               │
    │               └─ 目标: <root_domain>:443/udp
    │
[互联网]
    │
    └─ QUIC (udp/443) → 服务端
        │
        └─ Xray XHTTP(h3) Inbound (443/udp)
            │
            ├─ 验证 TLS 证书和 ALPN=h3
            │
            └─ 处理 VLESS 代理流量
                │
                └─ 根据路由规则转发（同场景 1）
```

**关键点：**

- 这是独立的 QUIC/HTTP3 入口，**不经过 Nginx**，直连 Xray
- 使用 TLS 证书（Let's Encrypt），强制 `ALPN: ["h3"]`
- 与 Reality 入口（TCP）并行，客户端可选择使用 `proxy-xhttp-h3` 出站
- 需要放行防火墙/安全组的 `udp/443` 端口

---

### 场景 5: 客户端路由决策

```
[应用请求] → Xray Client
    │
    ├─ DNS 查询
    │   ├─ 中国域名 → DoH: 223.5.5.5 / 114.114.114.114
    │   └─ 其他 → DoH: 1.1.1.1 / 8.8.8.8（含 IPv6 DoH）
    │
    ├─ 路由规则匹配（按顺序）
    │   │
    │   ├─ 1. BitTorrent → direct
    │   │
    │   ├─ 2. 私有/中国 IP → direct
    │   │
    │   ├─ 3. 广告域名 → block
    │   │   └─ geosite:cn, geosite:apple-cn 等
    │   │
    │   ├─ 4. Instagram 等 → wireguard
    │   │   └─ 通过 WARP 访问（使用 proxy-xhttp-h3 作为 dialerProxy）
    │   │
    │   └─ 5. geosite:geolocation-!cn → proxy
    │       └─ 通过 Reality 代理（TCP，默认）或 proxy-xhttp-h3（QUIC，可选）
    │
    └─ 执行路由决策
```

**关键点：**

- 中国流量在客户端直连，不经过服务器
- 智能分流确保性能和隐私
- WARP 用于特定域名（如 Instagram），且 **WireGuard 出站使用 `proxy-xhttp-h3` 作为 `dialerProxy`**（即 WARP 流量先通过 XHTTP(h3) 代理）

---

## 🔍 端口和协议映射

### 服务端端口

| 端口 | 服务           | 协议  | 说明                                                            |
| ---- | -------------- | ----- | --------------------------------------------------------------- |
| 443  | Nginx Stream   | TCP   | 入口，SNI 分流                                                  |
| 443  | Xray XHTTP(h3) | UDP   | HTTP/3(QUIC) 代理入口（直连 Xray，已启用，需放行防火墙/安全组） |
| 1443 | Xray Reality   | TCP   | Reality 协议处理                                                |
| 2024 | Xray XHTTP     | TCP   | XHTTP 路径入口（仅本地，给 Nginx 转发）                         |
| 8443 | Nginx HTTPS    | HTTPS | Web 入口（仅本地回环，由 Stream 转发进入）                      |
| 3001 | Nginx Blog     | HTTP  | 博客服务器                                                      |

### 客户端端口

| 端口  | 服务       | 协议   | 说明             |
| ----- | ---------- | ------ | ---------------- |
| 10800 | Xray SOCKS | SOCKS5 | 本地 SOCKS5 代理 |
| 10801 | Xray HTTP  | HTTP   | 本地 HTTP 代理   |

---

## 🛡️ 安全特性

### 1. Reality 协议

- **TLS 指纹伪装**: 伪装成 Chrome 浏览器
- **SNI 伪装**: 使用真实域名作为 SNI
- **ShortId 验证**: 额外的身份验证层
- **XTLS Vision**: 减少加解密开销

### 2. 流量特征

- **ALPN 协商**: h2, http/1.1（现代浏览器行为；Reality 本身仍是 TCP 入口）
- **Proxy Protocol**: 传递真实客户端 IP
- **SNI 分流**: 基于域名的智能分流

### 3. 路由安全

- **中国 IP 阻止**: 服务端阻止中国 IP 访问（异常检测）
- **私有 IP 阻止**: 防止内网扫描
- **BitTorrent 阻止**: 防止 P2P 流量

---

## 📈 性能优化

### 1. DNS 优化

- **分域 DNS**: 中国域名使用国内 DNS，其他使用海外 DNS
- **IPv4 优先**: `queryStrategy: UseIPv4`
- **DNS over HTTPS**: 加密 DNS 查询

### 2. 传输优化

- **XTLS Vision**: 减少加解密开销
- **HTTP/2**: Web 侧支持多路复用
- **连接复用**: 减少握手开销

### 3. 路由优化

- **智能分流**: 中国流量直连，减少延迟
- **WARP 集成**: 特定域名使用 Cloudflare WARP

---

## ⚠️ 潜在问题

### 1. Nginx gRPC Path 配置（用于路径入口）

```nginx
location /<xhttp_path> {
    proxy_pass http://127.0.0.1:2024;
}
```

**说明**: 当前 Xray 2024 入站使用 `network: "xhttp"`，因此这里应使用 `proxy_pass`（HTTP 反代），而不是 `grpc_pass`。

### 2. Path 入口可用性

- 确保外部访问的 SNI 能命中 `blog.<root_domain>`，否则不会进入 `8443` 的 `location /<xhttp_path>`
- 确保客户端使用的 XHTTP `path` 与 `<xhttp_path>` 一致

### 3. SNI 分流逻辑

- `blog.<root_domain>` → web_backend
- 其他 → reality_backend
- 确保客户端使用正确的 SNI

---

## 🔧 建议优化

1. **确认路径入口协议**: nginx 使用 `grpc_pass` 时，Xray 2024 入站应为 `grpc`
2. **添加监控**: 监控各端口的连接数和流量
3. **日志分析**: 定期分析访问日志，优化路由规则
4. **性能测试**: 测试不同场景下的延迟和吞吐量

---

## 📝 总结

当前架构实现了：

- ✅ 高性能代理（Reality + XTLS Vision）
- ✅ QUIC/HTTP3 支持（XHTTP(h3) 入口，udp/443）
- ✅ 智能分流（中国流量直连）
- ✅ 多入口支持（TCP: Reality / QUIC: XHTTP(h3) / HTTPS Path: XHTTP）
- ✅ 安全防护（TLS 指纹伪装）
- ✅ WARP 集成（WireGuard 使用 XHTTP(h3) 作为 dialerProxy）
- ✅ 灵活扩展（支持 Web 服务）

需要注意：

- ⚠️ 路径入口使用 XHTTP：nginx 需 `proxy_pass`，Xray 2024 入站需 `network: "xhttp"`
- ⚠️ 确保 SNI 分流逻辑正确
- ⚠️ **XHTTP(h3) 入口需放行防火墙/安全组的 `udp/443` 端口**
- ⚠️ 监控服务端资源使用
