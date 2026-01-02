# XHTTP / SplitHTTP over QUIC (HTTP/3 / h3) 配置指南（Xray 25.3.6）

你当前的入口里 `443/tcp` 被 Nginx `stream{}` 占用（用于 Reality / Web 转发等 TCP 流量），而 **HTTP/3(h3) 走 UDP/QUIC**。

> ✅ **本仓库已经在服务端 `xray/config.json` 中配置了对外的 `udp/443` XHTTP(h3) 入站**（VLESS + XHTTP + TLS，`ALPN=h3`，tag: `vless-xhttp-h3`）。  
> 你只需要：**放行防火墙/安全组的 `udp/443` 端口**，并确保服务器上存在对应域名的 Let's Encrypt 证书文件。

---

## 1) 服务端：XHTTP(h3) 入站（已配置）

服务端 `xray/config.json` 中已包含以下入站配置（tag: `vless-xhttp-h3`）：

```json
{
  "listen": "0.0.0.0",
  "port": 443,
  "protocol": "vless",
  "settings": {
    "clients": [
      {
        "id": "<this_should_be_replaced_by_vless_uuid>",
        "encryption": "none"
      }
    ],
    "decryption": "none"
  },
  "streamSettings": {
    "network": "xhttp",
    "security": "tls",
    "tlsSettings": {
      "certificates": [
        {
          "certificateFile": "/etc/letsencrypt/live/<this_should_be_replaced_by_root_domain>/fullchain.pem",
          "keyFile": "/etc/letsencrypt/live/<this_should_be_replaced_by_root_domain>/privkey.pem"
        }
      ],
      "alpn": ["h3"]
    },
    "xhttpSettings": {
      "path": "<this_should_be_replaced_by_xhttp_path>",
      "mode": "auto"
    }
  }
}
```

### 防火墙/安全组（必需）

**这是唯一需要你手动操作的步骤：**

```bash
# Ubuntu/Debian (ufw)
sudo ufw allow 443/udp

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-port=443/udp
sudo firewall-cmd --reload

# 或云服务商安全组：放行 UDP 443
```

- **确保 `tcp/443` 仍由 Nginx `stream{}` 占用**；Xray 监听的是 `udp/443`，不会与 `tcp/443` 冲突。
- 如果你所在环境对 `udp/443` 干扰严重，可以改用 `udp/8444`（需要修改服务端和客户端配置）。

---

## 2) 客户端：新增一个 XHTTP(h3) 出站

本仓库已在 `xray/client-config.json` 添加了一个出站 `proxy-xhttp-h3`（默认指向 `443`，ALPN 为 `h3`）。

你也可以手动加（字段要和服务端一致）：

```json
{
  "tag": "proxy-xhttp-h3",
  "protocol": "vless",
  "settings": {
    "vnext": [
      {
        "address": "<this_should_be_replaced_by_root_domain>",
        "port": 443,
        "users": [
          {
            "id": "<this_should_be_replaced_by_vless_uuid>",
            "encryption": "none"
          }
        ]
      }
    ]
  },
  "streamSettings": {
    "network": "xhttp",
    "security": "tls",
    "tlsSettings": {
      "serverName": "<this_should_be_replaced_by_root_domain>",
      "alpn": ["h3"],
      "fingerprint": "chrome"
    },
    "xhttpSettings": {
      "path": "<this_should_be_replaced_by_xhttp_path>",
      "mode": "auto"
    }
  }
}
```

---

## 3) 如何切换让流量走 h3

把客户端路由里用于出海的 `outboundTag` 从 `proxy`（Reality/TCP）改成 `proxy-xhttp-h3`（QUIC/HTTP3）即可。

**注意**：当前配置中，WireGuard 出站（WARP）已使用 `proxy-xhttp-h3` 作为 `dialerProxy`，这意味着 WARP 流量会先通过 XHTTP(h3) 代理。

---

## 4) （可选）如果需要使用 `udp/8444`

如果你所在环境对 `udp/443` 干扰严重：

- 把上面的端口从 `443` 改成 `8444`
- 放行 `udp/8444`
