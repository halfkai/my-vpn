#!/bin/bash

source ./.local.credentials
credential_prefix=this_should_be_replaced_by_

sed -i '' "s/$cloudflare_token/<${credential_prefix}cloudflare_token>/g" "$PWD/letsencrypt/dns_tokens.ini"
sed -i '' "s/$digitalocean_token/<${credential_prefix}digitalocean_token>/g" "$PWD/letsencrypt/dns_tokens.ini"

sed -i '' "s/$vless_uuid/<${credential_prefix}vless_uuid>/g" "$PWD/xray/config.json"
sed -i '' "s/$reality_pri_key/<${credential_prefix}reality_pri_key>/g" "$PWD/xray/config.json"
sed -i '' "s/$xhttp_path/<${credential_prefix}xhttp_path>/g" "$PWD/xray/config.json"
sed -i '' "s/$xhttp_path/<${credential_prefix}xhttp_path>/g" "$PWD/nginx/nginx.conf"
sed -i '' "s/$reality_domain/<${credential_prefix}reality_domain>/g" "$PWD/nginx/nginx.conf"
sed -i '' "s/$root_domain/<${credential_prefix}root_domain>/g" "$PWD/nginx/nginx.conf"
sed -i '' "s/$website_domain/<${credential_prefix}website_domain>/g" "$PWD/nginx/conf.d/blog.conf"
sed -i '' "s/$root_domain/<${credential_prefix}root_domain>/g" "$PWD/start.sh"
sed -i '' "s/$root_domain/<${credential_prefix}root_domain>/g" "$PWD/hysteria/config.yaml"
sed -i '' "s/$root_domain/<${credential_prefix}root_domain>/g" "$PWD/xray/config.json"

sed -i '' "s/$root_domain/<${credential_prefix}root_domain>/g" "$PWD/xray/client-config.json"
sed -i '' "s/$vless_uuid/<${credential_prefix}vless_uuid>/g" "$PWD/xray/client-config.json"
sed -i '' "s/$root_domain/<${credential_prefix}root_domain>/g" "$PWD/xray/client-config.json"
sed -i '' "s/$reality_pub_key/<${credential_prefix}reality_pub_key>/g" "$PWD/xray/client-config.json"
sed -i '' "s/$xhttp_path/<${credential_prefix}xhttp_path>/g" "$PWD/xray/client-config.json"

sed -i '' "s/$hysteria_password/<${credential_prefix}hysteria_password>/g" "$PWD/hysteria/config.yaml"
