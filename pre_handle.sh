#!/bin/bash

source ./.local.credentials
credential_prefix=this_should_be_replaced_by_

sed -i '' "s/<${credential_prefix}cloudflare_token>/$cloudflare_token/g" "$PWD/letsencrypt/dns_tokens.ini"
sed -i '' "s/<${credential_prefix}digitalocean_token>/$digitalocean_token/g" "$PWD/letsencrypt/dns_tokens.ini"

sed -i '' "s/<${credential_prefix}vless_uuid>/$vless_uuid/g" "$PWD/xray/config.json"
sed -i '' "s/<${credential_prefix}reality_pri_key>/$reality_pri_key/g" "$PWD/xray/config.json"
sed -i '' "s/<${credential_prefix}xhttp_path>/$xhttp_path/g" "$PWD/xray/config.json"
sed -i '' "s/<${credential_prefix}xhttp_path>/$xhttp_path/g" "$PWD/nginx/nginx.conf"
sed -i '' "s/<${credential_prefix}reality_domain>/$reality_domain/g" "$PWD/nginx/nginx.conf"
sed -i '' "s/<${credential_prefix}root_domain>/$root_domain/g" "$PWD/nginx/nginx.conf"
sed -i '' "s/<${credential_prefix}website_domain>/$website_domain/g" "$PWD/nginx/conf.d/blog.conf"
sed -i '' "s/<${credential_prefix}root_domain>/$root_domain/g" "$PWD/start.sh"
sed -i '' "s/<${credential_prefix}root_domain>/$root_domain/g" "$PWD/hysteria/config.yaml"
sed -i '' "s/<${credential_prefix}root_domain>/$root_domain/g" "$PWD/xray/config.json"

sed -i '' "s/<${credential_prefix}root_domain>/$root_domain/g" "$PWD/xray/client-config.json"
sed -i '' "s/<${credential_prefix}vless_uuid>/$vless_uuid/g" "$PWD/xray/client-config.json"
sed -i '' "s/<${credential_prefix}root_domain>/$root_domain/g" "$PWD/xray/client-config.json"
sed -i '' "s/<${credential_prefix}reality_pub_key>/$reality_pub_key/g" "$PWD/xray/client-config.json"
sed -i '' "s/<${credential_prefix}xhttp_path>/$xhttp_path/g" "$PWD/xray/client-config.json"

sed -i '' "s/<${credential_prefix}hysteria_password>/$hysteria_password/g" "$PWD/hysteria/config.yaml"
