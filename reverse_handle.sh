#!/bin/bash

set -euo pipefail

# 检查 credentials 文件是否存在
if [[ ! -f "./.local.credentials" ]]; then
    echo "Error: .local.credentials file not found!" >&2
    exit 1
fi

source ./.local.credentials

credential_prefix=this_should_be_replaced_by_

# 检测操作系统并设置 sed 参数
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_INPLACE=(-i '')
else
    SED_INPLACE=(-i)
fi

# 反向替换函数：将实际值替换回占位符
reverse_replace_in_file() {
    local file="$1"
    local value="$2"
    local placeholder="$3"
    
    if [[ -f "$file" ]]; then
        if [[ -n "${value:-}" ]]; then
            sed "${SED_INPLACE[@]}" "s|${value}|<${placeholder}>|g" "$file"
        fi
    else
        echo "Warning: File not found: $file" >&2
    fi
}

# 替换 letsencrypt 配置
reverse_replace_in_file "$PWD/letsencrypt/dns_tokens.ini" \
    "${cloudflare_token:-}" \
    "${credential_prefix}cloudflare_token"

# 替换 xray/config.json
reverse_replace_in_file "$PWD/xray/config.json" \
    "${vless_uuid:-}" \
    "${credential_prefix}vless_uuid"
reverse_replace_in_file "$PWD/xray/config.json" \
    "${reality_pri_key:-}" \
    "${credential_prefix}reality_pri_key"
reverse_replace_in_file "$PWD/xray/config.json" \
    "${xhttp_path:-}" \
    "${credential_prefix}xhttp_path"
reverse_replace_in_file "$PWD/xray/config.json" \
    "${root_domain:-}" \
    "${credential_prefix}root_domain"
reverse_replace_in_file "$PWD/xray/config.json" \
    "${warp_secret_key:-}" \
    "${credential_prefix}warp_secret_key"
reverse_replace_in_file "$PWD/xray/config.json" \
    "${warp_public_key:-}" \
    "${credential_prefix}warp_public_key"
reverse_replace_in_file "$PWD/xray/config.json" \
    "${warp_private_key:-}" \
    "${credential_prefix}warp_private_key"
reverse_replace_in_file "$PWD/xray/config.json" \
    "${my_server_ipv4:-}" \
    "${credential_prefix}my_server_ipv4"
reverse_replace_in_file "$PWD/xray/config.json" \
    "${my_server_ipv6:-}" \
    "${credential_prefix}my_server_ipv6"

# 替换 xray/client-config.json
reverse_replace_in_file "$PWD/xray/client-config.json" \
    "${warp_public_key:-}" \
    "${credential_prefix}warp_public_key"
reverse_replace_in_file "$PWD/xray/client-config.json" \
    "${warp_private_key:-}" \
    "${credential_prefix}warp_private_key"
reverse_replace_in_file "$PWD/xray/client-config.json" \
    "${root_domain:-}" \
    "${credential_prefix}root_domain"
reverse_replace_in_file "$PWD/xray/client-config.json" \
    "${vless_uuid:-}" \
    "${credential_prefix}vless_uuid"
reverse_replace_in_file "$PWD/xray/client-config.json" \
    "${reality_pub_key:-}" \
    "${credential_prefix}reality_pub_key"
reverse_replace_in_file "$PWD/xray/client-config.json" \
    "${xhttp_path:-}" \
    "${credential_prefix}xhttp_path"
reverse_replace_in_file "$PWD/xray/client-config.json" \
    "${my_server_ipv4:-}" \
    "${credential_prefix}my_server_ipv4"
reverse_replace_in_file "$PWD/xray/client-config.json" \
    "${my_server_ipv6:-}" \
    "${credential_prefix}my_server_ipv6"

# 替换 nginx 配置
reverse_replace_in_file "$PWD/nginx/nginx.conf" \
    "${xhttp_path:-}" \
    "${credential_prefix}xhttp_path"
reverse_replace_in_file "$PWD/nginx/nginx.conf" \
    "${root_domain:-}" \
    "${credential_prefix}root_domain"
reverse_replace_in_file "$PWD/nginx/conf.d/blog.conf" \
    "${website_domain:-}" \
    "${credential_prefix}website_domain"

# 替换其他文件
reverse_replace_in_file "$PWD/start.sh" \
    "${root_domain:-}" \
    "${credential_prefix}root_domain"
reverse_replace_in_file "$PWD/hysteria/config.yaml" \
    "${root_domain:-}" \
    "${credential_prefix}root_domain"
reverse_replace_in_file "$PWD/hysteria/config.yaml" \
    "${hysteria_password:-}" \
    "${credential_prefix}hysteria_password"

echo "✓ Configuration files reverted to placeholders successfully"
