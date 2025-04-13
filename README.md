# 🧗了个🧱

## 服务端

### 事前准备

1. 准备域名、海外服务器
2. 获取配置域名解析记录的 API Token
3. 准备 Credentials

```shell
output=$(xray x25519)

export vless_uuid=`xray uuid`
export xhttp_path=`xray uuid`
export reality_domain=reality.your.domain
export root_domain=your.domain
export website_domain=web.your.domain
export reality_pri_key=$(echo "$output" | sed -n 's/Private key: \(.*\)/\1/p')
export reality_pub_key=$(echo "$output" | sed -n 's/Public key: \(.*\)/\1/p')
```

[Optional]可选
```shell
touch .local.credentials &&
echo "vless_uuid=$vless_uuid" > .local.credentials &&
echo "xhttp_path=$xhttp_path" >> .local.credentials &&
echo "reality_domain=$reality_domain" >> .local.credentials &&
echo "root_domain=$root_domain" >> .local.credentials &&
echo "website_domain=$website_domain" >> .local.credentials &&
echo "reality_pri_key=$reality_pri_key" >> .local.credentials &&
echo "reality_pub_key=$reality_pub_key" >> .local.credentials
```

```shell
bash $PWD/pre_handle.sh
```

### 部署

```shell
bash $PWD/start.sh
```

## 客户端

### 更新本地 geoip.dat / geosite.dat

1. 参考 [v2ray-rules-dat](https://github.com/Loyalsoldier/v2ray-rules-dat)

```shell
# 下载命令，我本地使用 aria2，可替换成 curl / wget
aria2c -d /tmp https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat && mv /usr/local/share/xray/geoip.dat /usr/local/share/xray/geoip.dat-bak && mv /tmp/geoip.dat /usr/local/share/xray/geoip.dat

aria2c -d /tmp https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat && mv /usr/local/share/xray/geosite.dat /usr/local/share/xray/geosite.dat-bak && mv /tmp/geosite.dat /usr/local/share/xray/geosite.dat
```

### 更新配置

```shell
mv /usr/local/etc/xray/config.json /usr/local/etc/xray/config.json-bak
cp $PWD/xray/client-config.json /usr/local/etc/xray/config.json
```

###　リンク スタート！

```shell
systemctl restart xray # or brew services restart xray
```

## 服务端配置参考

1. 仅使用 443 端口完美配置 Nginx SNI 分流 REALITY&XHTTP、Hysteria 2 及 WEB 网站 [by Tabsp](https://tabsp.com/posts/nginx-sni-vless-reality-vision-xhttp-hysteria2-web/)


