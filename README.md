# 我的 Web Server

## 部署前

1. 准备域名、海外服务器
2. 获取配置域名解析记录的 API Token
3. 准备 Credentials

```shell
output=$(xray x25519)

export vless_uuid=xray uuid
export xhttp_path=xray uuid
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
sh $PWD/pre_handle.sh
```

## 部署

```shell
sh $PWD/start
```

## 替换你的xray客户端配置文件

```shell
mv /usr/local/etc/xray/config.json /usr/local/etc/xray/config-old.json
cp $PWD/xray/client.json /usr/local/xray/
```

## 通信参考

