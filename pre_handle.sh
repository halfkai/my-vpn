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

# 替换函数：检查文件存在后再替换
replace_in_file() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    
    if [[ -f "$file" ]]; then
        sed "${SED_INPLACE[@]}" "s|${pattern}|${replacement}|g" "$file"
    else
        echo "Warning: File not found: $file" >&2
    fi
}

# 验证必需变量
required_vars=(
    "vless_uuid"
    "reality_pri_key"
    "reality_pub_key"
    "xhttp_path"
    "root_domain"
)

for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        echo "Error: Required variable '$var' is not set in .local.credentials" >&2
        exit 1
    fi
done

# 替换 letsencrypt 配置
replace_in_file "$PWD/letsencrypt/dns_tokens.ini" \
    "<${credential_prefix}cloudflare_token>" \
    "${cloudflare_token:-}"

# 替换 xray/config.json
replace_in_file "$PWD/xray/config.json" \
    "<${credential_prefix}vless_uuid>" \
    "$vless_uuid"
replace_in_file "$PWD/xray/config.json" \
    "<${credential_prefix}reality_pri_key>" \
    "$reality_pri_key"
replace_in_file "$PWD/xray/config.json" \
    "<${credential_prefix}xhttp_path>" \
    "$xhttp_path"
replace_in_file "$PWD/xray/config.json" \
    "<${credential_prefix}root_domain>" \
    "$root_domain"
replace_in_file "$PWD/xray/config.json" \
    "<${credential_prefix}warp_secret_key>" \
    "${warp_secret_key:-}"
replace_in_file "$PWD/xray/config.json" \
    "<${credential_prefix}warp_public_key>" \
    "${warp_public_key:-}"
replace_in_file "$PWD/xray/config.json" \
    "<${credential_prefix}warp_private_key>" \
    "${warp_private_key:-}"

# 替换 xray/client-config.json
replace_in_file "$PWD/xray/client-config.json" \
    "<${credential_prefix}warp_public_key>" \
    "${warp_public_key:-}"
replace_in_file "$PWD/xray/client-config.json" \
    "<${credential_prefix}warp_private_key>" \
    "${warp_private_key:-}"
replace_in_file "$PWD/xray/client-config.json" \
    "<${credential_prefix}root_domain>" \
    "$root_domain"
replace_in_file "$PWD/xray/client-config.json" \
    "<${credential_prefix}vless_uuid>" \
    "$vless_uuid"
replace_in_file "$PWD/xray/client-config.json" \
    "<${credential_prefix}reality_pub_key>" \
    "$reality_pub_key"
replace_in_file "$PWD/xray/client-config.json" \
    "<${credential_prefix}xhttp_path>" \
    "$xhttp_path"

# 替换 nginx 配置
replace_in_file "$PWD/nginx/nginx.conf" \
    "<${credential_prefix}xhttp_path>" \
    "$xhttp_path"
replace_in_file "$PWD/nginx/nginx.conf" \
    "<${credential_prefix}root_domain>" \
    "$root_domain"
replace_in_file "$PWD/nginx/conf.d/blog.conf" \
    "<${credential_prefix}website_domain>" \
    "${website_domain:-}"

# 替换其他文件
replace_in_file "$PWD/start.sh" \
    "<${credential_prefix}root_domain>" \
    "$root_domain"
echo "✓ Configuration files updated successfully"
echo ""
echo "Note: To revert changes, run: ./reverse_handle.sh"

