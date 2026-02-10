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

# 替换 xray/server.jsonc
reverse_replace_in_file "$PWD/xray/server.jsonc" \
    "${vless_uuid:-}" \
    "${credential_prefix}vless_uuid"
reverse_replace_in_file "$PWD/xray/server.jsonc" \
    "${reality_pri_key:-}" \
    "${credential_prefix}reality_pri_key"
reverse_replace_in_file "$PWD/xray/server.jsonc" \
    "${xhttp_path:-}" \
    "${credential_prefix}xhttp_path"
reverse_replace_in_file "$PWD/xray/server.jsonc" \
    "${root_domain:-}" \
    "${credential_prefix}root_domain"
reverse_replace_in_file "$PWD/xray/server.jsonc" \
    "${warp_private_key:-}" \
    "${credential_prefix}warp_private_key"
reverse_replace_in_file "$PWD/xray/server.jsonc" \
    "${warp_public_key:-}" \
    "${credential_prefix}warp_public_key"
reverse_replace_in_file "$PWD/xray/server.jsonc" \
    "${warp_private_key:-}" \
    "${credential_prefix}warp_private_key"

# 替换 xray/client.jsonc
reverse_replace_in_file "$PWD/xray/client.jsonc" \
    "${warp_public_key:-}" \
    "${credential_prefix}warp_public_key"
reverse_replace_in_file "$PWD/xray/client.jsonc" \
    "${warp_private_key:-}" \
    "${credential_prefix}warp_private_key"
reverse_replace_in_file "$PWD/xray/client.jsonc" \
    "${root_domain:-}" \
    "${credential_prefix}root_domain"
reverse_replace_in_file "$PWD/xray/client.jsonc" \
    "${vless_uuid:-}" \
    "${credential_prefix}vless_uuid"
reverse_replace_in_file "$PWD/xray/client.jsonc" \
    "${reality_pub_key:-}" \
    "${credential_prefix}reality_pub_key"
reverse_replace_in_file "$PWD/xray/client.jsonc" \
    "${xhttp_path:-}" \
    "${credential_prefix}xhttp_path"

# 替换 nginx 配置
reverse_replace_in_file "$PWD/nginx/nginx.conf" \
    "${xhttp_path:-}" \
    "${credential_prefix}xhttp_path"
reverse_replace_in_file "$PWD/nginx/nginx.conf" \
    "${root_domain:-}" \
    "${credential_prefix}root_domain"
# 替换其他文件
reverse_replace_in_file "$PWD/start.sh" \
    "${root_domain:-}" \
    "${credential_prefix}root_domain"
echo "✓ Configuration files reverted to placeholders successfully"
