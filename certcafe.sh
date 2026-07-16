#!/usr/bin/env bash

# ======================================
#           🏷️ CertCafe v1.0
#     Your SSL Certificate Café
# ======================================
#
# Welcome to CertCafe! ☕
# 
# 今天想来点什么证书？
# What certificate would you like today?
#
# 🍵 招牌特饮 | House Specials:
#   - 一键安装部署 | One-click Setup
#   - 多平台支持 | Multi-platform DNS
#   - 自动续期 | Auto-renewal
#
# 🌍 国际风味 | Global Flavors:
#   Cloudflare, Alibaba, Tencent
#   DNSPod, Huawei, JD Cloud
#
# 用法: ./certcafe.sh
# Usage: ./certcafe.sh
# ======================================

SCRIPT_NAME="CertCafe"
ACME_INSTALL_DIR="$HOME/.acme.sh"
ACME_URL="https://get.acme.sh"

# 咖啡馆主题颜色
BROWN='\033[0;33m'
CREAM='\033[1;37m'  
ESPRESSO='\033[0;31m'
MATCHA='\033[0;32m'
LATTE='\033[1;33m'
MOCHA='\033[0;34m'
NC='\033[0m'

# 输出彩色文本
print_color() {
    echo -e "${1}${2}${NC}"
}

# 输出“进行中”类提示（与 print_color 风格一致）
print_brewing() {
    print_color $BROWN "$1"
}

# 咖啡馆艺术
print_cafe_logo() {
    echo -e "${BROWN}"
    echo "    )))"
    echo "   (((("
    echo "  +-----+"
    echo "  | ☕  |   CertCafe"
    echo "  +-----+"
    echo "    |||"
    echo -e "${NC}"
}

print_coffee_cup() {
    echo -e "${BROWN}"
    echo "   ( ( )"
    echo "    ) ) "
    echo "  ........."
    echo "  |       |]"
    echo "  \       /"
    echo "   \-----/"
    echo -e "${NC}"
}

# 检查acme.sh是否已安装
check_acme_installed() {
    if [ -f "$ACME_INSTALL_DIR/acme.sh" ]; then
        return 0
    else
        return 1
    fi
}

is_valid_email() {
    [[ "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
}

prompt_acme_account_email() {
    local required="${1:-0}"
    local email_input

    if [ -n "$ACME_ACCOUNT_EMAIL" ] && is_valid_email "$ACME_ACCOUNT_EMAIL"; then
        return 0
    fi

    while true; do
        if [ "$required" = "1" ]; then
            read -p "请输入用于注册 ACME/ZeroSSL 账户的邮箱: " email_input
        else
            read -p "请输入用于注册 ACME 账户的邮箱（可留空跳过）: " email_input
        fi

        if [ -z "$email_input" ]; then
            if [ "$required" = "1" ]; then
                print_color $ESPRESSO "ZeroSSL 需要有效邮箱才能注册账户"
                continue
            fi
            return 0
        fi

        if is_valid_email "$email_input"; then
            ACME_ACCOUNT_EMAIL="$email_input"
            export ACME_ACCOUNT_EMAIL
            return 0
        fi

        print_color $ESPRESSO "邮箱格式不正确，请重新输入"
    done
}

# 安装acme.sh
install_acme() {
    print_color $BROWN "开始安装acme.sh..."
    
    if check_acme_installed; then
        print_color $LATTE "acme.sh已经安装，跳过安装步骤"
        return 0
    fi

    prompt_acme_account_email 0
    
    # 下载并安装acme.sh
    if [ -n "$ACME_ACCOUNT_EMAIL" ]; then
        curl -s $ACME_URL | sh -s email="$ACME_ACCOUNT_EMAIL"
    else
        curl -s $ACME_URL | sh
    fi
    
    if [ $? -eq 0 ]; then
        print_color $MATCHA "acme.sh安装成功！"
        # 添加到环境变量
        if [[ ":$PATH:" != *":$ACME_INSTALL_DIR:"* ]]; then
            echo "export PATH=\"\$PATH:$ACME_INSTALL_DIR\"" >> ~/.bashrc
            source ~/.bashrc
        fi
        return 0
    else
        print_color $ESPRESSO "acme.sh安装失败！"
        return 1
    fi
}

register_zerossl_account() {
    prompt_acme_account_email 1 || return 1

    print_color $BROWN "正在注册/更新 ZeroSSL 账户邮箱: $ACME_ACCOUNT_EMAIL"
    cd "$ACME_INSTALL_DIR" || return 1
    ./acme.sh --register-account -m "$ACME_ACCOUNT_EMAIL" --server zerossl

    if [ $? -eq 0 ]; then
        print_color $MATCHA "ZeroSSL 账户邮箱已配置完成"
        return 0
    fi

    print_color $ESPRESSO "ZeroSSL 账户注册失败，请检查邮箱或 acme.sh 输出信息"
    return 1
}

# 选择DNS提供商
select_dns_provider() {
    local configured_provider
    configured_provider=$(detect_configured_dns_provider)
    if [ -n "$configured_provider" ]; then
        while true; do
            print_color $BROWN "检测到可用的 DNS 环境配置：$(dns_provider_display_name "$configured_provider")（$configured_provider）"
            echo "1) 使用当前环境配置（默认）"
            echo "2) 手动选择/重新输入 DNS 提供商"
            echo "0) ↩️ 返回上一级"
            read -p "请输入选择 [0-2，默认 1]: " env_dns_choice

            case ${env_dns_choice:-1} in
                0)
                    print_color $LATTE "返回主菜单..."
                    return 2
                    ;;
                1)
                    DNS_PROVIDER="$configured_provider"
                    export DNS_PROVIDER
                    print_color $MATCHA "已使用当前环境配置：$(dns_provider_display_name "$DNS_PROVIDER")"
                    validate_dns_credentials
                    return $?
                    ;;
                2)
                    break
                    ;;
                *)
                    print_color $ESPRESSO "无效选择！请输入 0-2 之间的数字"
                    echo ""
                    ;;
            esac
        done
    fi

    while true; do
		print_color $BROWN "请选择DNS提供商："
		echo "1) Cloudflare"
		echo "2) Alibaba Cloud (阿里云)"
		echo "3) Tencent Cloud (腾讯云)"
		echo "4) DNSPod"
		echo "5) Huawei Cloud (华为云)"
		echo "6) JD Cloud (京东云)"
		echo "7) 其他（手动配置）"
		echo "0) ↩️ 返回上一级"
		read -p "请输入选择 [0-7]: " dns_choice
		
		case $dns_choice in
			0)
				print_color $LATTE "返回主菜单..."
				return 2  # 特殊返回码表示用户选择返回
				;;
			1)
				DNS_PROVIDER="dns_cf"
				configure_cloudflare_credentials
				break
				;;
			2)
				DNS_PROVIDER="dns_ali"
				read -p "请输入阿里云 AccessKey ID: " ali_key
				read -p "请输入阿里云 AccessKey Secret: " ali_secret
				export Ali_Key="$ali_key"
				export Ali_Secret="$ali_secret"
				print_color $MATCHA "已设置阿里云DNS提供商"
				break
				;;
			3)
				DNS_PROVIDER="dns_tencent"
				read -p "请输入腾讯云 SecretId: " tc_secret_id
				read -p "请输入腾讯云 SecretKey: " tc_secret_key
				export Tencent_SecretId="$tc_secret_id"
				export Tencent_SecretKey="$tc_secret_key"
				print_color $MATCHA "已设置腾讯云 DNS 提供商"
				break
				;;
			4)
				DNS_PROVIDER="dns_dp"
				read -p "请输入DNSPod ID: " dp_id
				read -p "请输入DNSPod Key: " dp_key
				export DP_Id="$dp_id"
				export DP_Key="$dp_key"
				print_color $MATCHA "已设置DNSPod DNS提供商"
				break
				;;
			5)
				DNS_PROVIDER="dns_huaweicloud"
				read -p "请输入华为云 AccessKey ID: " hw_key
				read -p "请输入华为云 Secret Access Key: " hw_secret
				export HUAWEICLOUD_Username="$hw_key"
				export HUAWEICLOUD_Password="$hw_secret"
				print_color $MATCHA "已设置华为云DNS提供商"
				break
				;;
			6)
				DNS_PROVIDER="dns_jd"
				read -p "请输入京东云 AccessKey ID: " jd_access_key
				read -p "请输入京东云 Secret Access Key: " jd_secret_key
				export JD_ACCESS_KEY_ID="$jd_access_key"
				export JD_ACCESS_KEY_SECRET="$jd_secret_key"
				print_color $MATCHA "已设置京东云DNS提供商"
				break
				;;
			7)
				print_color $LATTE "请手动配置DNS API环境变量"
				read -p "请输入DNS提供商（如dns_xxx）: " DNS_PROVIDER
				print_color $LATTE "请确保已设置相应的环境变量"
				break
				;;
			*)
				print_color $ESPRESSO "无效选择！请输入 0-7 之间的数字"
				echo ""
				read -p "按回车键重新选择..."
				continue
				;;
		esac
	done
    
    # 验证必要的环境变量是否设置
    export DNS_PROVIDER
    validate_dns_credentials
}

# 验证DNS凭据
validate_dns_credentials() {
    case $DNS_PROVIDER in
        dns_cf)
            if [ -z "$CF_Token" ] && { [ -z "$CF_Key" ] || [ -z "$CF_Email" ]; }; then
                print_color $ESPRESSO "错误：Cloudflare API Token 未设置，或 Global API Key/Email 未设置"
                return 1
            fi
            ;;
        dns_ali)
            if [ -z "$Ali_Key" ] || [ -z "$Ali_Secret" ]; then
                print_color $ESPRESSO "错误：阿里云 AccessKey 或 Secret 未设置"
                return 1
            fi
            ;;
        dns_tencent)
            if [ -z "$Tencent_SecretId" ] || [ -z "$Tencent_SecretKey" ]; then
                print_color $ESPRESSO "错误：腾讯云 SecretId 或 SecretKey 未设置"
                return 1
            fi
            ;;
        dns_dp)
            if [ -z "$DP_Id" ] || [ -z "$DP_Key" ]; then
                print_color $ESPRESSO "错误：DNSPod ID 或 Key 未设置"
                return 1
            fi
            ;;
        dns_huaweicloud)
            if [ -z "$HUAWEICLOUD_Username" ] || [ -z "$HUAWEICLOUD_Password" ]; then
                print_color $ESPRESSO "错误：华为云 AccessKey 或 Secret 未设置"
                return 1
            fi
            ;;
        dns_jd)
            if [ -z "$JD_ACCESS_KEY_ID" ] || [ -z "$JD_ACCESS_KEY_SECRET" ]; then
                print_color $ESPRESSO "错误：京东云 AccessKey ID 或 Secret 未设置"
                return 1
            fi
            ;;
    esac
    return 0
}

# 获取 DNS 提供商的显示名称
dns_provider_display_name() {
    case "$1" in
        dns_cf) echo "Cloudflare" ;;
        dns_ali) echo "Alibaba Cloud (阿里云)" ;;
        dns_tencent) echo "Tencent Cloud (腾讯云)" ;;
        dns_dp) echo "DNSPod" ;;
        dns_huaweicloud) echo "Huawei Cloud (华为云)" ;;
        dns_jd) echo "JD Cloud (京东云)" ;;
        *) echo "$1" ;;
    esac
}

configure_cloudflare_credentials() {
    local cf_auth_choice
    local cf_key
    local cf_email
    local cf_token
    local cf_zone_id
    local cf_account_id

    print_color $BROWN "请选择 Cloudflare API 凭据类型："
    echo "1) API Token（推荐）：只授权指定域名的 DNS 管理权限，更安全"
    echo "2) Global API Key + Email（不推荐）：账号级全局密钥，权限较大，仅用于旧版配置"
    read -p "请输入选择 [1-2，默认 1]: " cf_auth_choice

    case ${cf_auth_choice:-1} in
        2)
            print_color $LATTE "Global API Key 方式需要填写 Cloudflare 账号邮箱和全局 API Key。"
            while [ -z "$cf_key" ]; do
                read -p "请输入 Cloudflare Global API Key（必填）: " cf_key
                [ -z "$cf_key" ] && print_color $ESPRESSO "Cloudflare Global API Key 不能为空"
            done
            while [ -z "$cf_email" ]; do
                read -p "请输入 Cloudflare 账号邮箱（必填）: " cf_email
                [ -z "$cf_email" ] && print_color $ESPRESSO "Cloudflare 账号邮箱不能为空"
            done
            export CF_Key="$cf_key"
            export CF_Email="$cf_email"
            unset CF_Token CF_Account_ID CF_Zone_ID
            print_color $MATCHA "已设置 Cloudflare Global API Key 凭据"
            ;;
        *)
            print_color $LATTE "API Token 至少需要 Zone:Read 和 DNS:Edit 权限，建议只授权当前要签发证书的域名。"
            while [ -z "$cf_token" ]; do
                read -p "请输入 Cloudflare API Token（必填）: " cf_token
                [ -z "$cf_token" ] && print_color $ESPRESSO "Cloudflare API Token 不能为空"
            done
            read -p "请输入 Cloudflare Zone ID（可留空；推荐填写，填写后会直接操作该域名 Zone，避免自动识别失败）: " cf_zone_id
            read -p "请输入 Cloudflare Account ID（可留空；仅当同一 Token 可访问多个账号时，用于限定账号范围）: " cf_account_id
            export CF_Token="$cf_token"
            export CF_Zone_ID="$cf_zone_id"
            export CF_Account_ID="$cf_account_id"
            unset CF_Key CF_Email
            print_color $MATCHA "已设置 Cloudflare API Token 凭据"
            ;;
    esac
}

# 检查指定 DNS 提供商所需的环境变量是否已配置
has_dns_env_credentials() {
    case "$1" in
        dns_cf)
            [ -n "$CF_Token" ] || { [ -n "$CF_Key" ] && [ -n "$CF_Email" ]; }
            ;;
        dns_ali)
            [ -n "$Ali_Key" ] && [ -n "$Ali_Secret" ]
            ;;
        dns_tencent)
            [ -n "$Tencent_SecretId" ] && [ -n "$Tencent_SecretKey" ]
            ;;
        dns_dp)
            [ -n "$DP_Id" ] && [ -n "$DP_Key" ]
            ;;
        dns_huaweicloud)
            [ -n "$HUAWEICLOUD_Username" ] && [ -n "$HUAWEICLOUD_Password" ]
            ;;
        dns_jd)
            [ -n "$JD_ACCESS_KEY_ID" ] && [ -n "$JD_ACCESS_KEY_SECRET" ]
            ;;
        *)
            [ -n "$1" ]
            ;;
    esac
}

# 优先使用当前 shell 中已经配置好的 DNS 环境变量
detect_configured_dns_provider() {
    local provider
    local detected_provider=""
    local detected_count=0

    if [ -n "$DNS_PROVIDER" ] && has_dns_env_credentials "$DNS_PROVIDER"; then
        echo "$DNS_PROVIDER"
        return 0
    fi

    for provider in dns_cf dns_ali dns_tencent dns_dp dns_huaweicloud dns_jd; do
        if has_dns_env_credentials "$provider"; then
            detected_provider="$provider"
            detected_count=$((detected_count + 1))
        fi
    done

    if [ "$detected_count" -eq 1 ]; then
        echo "$detected_provider"
        return 0
    fi

    return 1
}

# acme.sh 的续期依赖 cron 任务；默认开启，用户可在签发流程中选择关闭。
configure_auto_renew() {
    if [ "${ENABLE_AUTO_RENEW:-1}" != "1" ]; then
        print_color $LATTE "已按选择跳过自动续期配置"
        return 0
    fi

    if [ ! -x "./acme.sh" ]; then
        print_color $ESPRESSO "未找到可执行的 acme.sh，无法配置自动续期"
        return 1
    fi

    ./acme.sh --install-cronjob >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_color $MATCHA "已开启自动续期（acme.sh cron 任务）"
        return 0
    fi

    print_color $LATTE "自动续期任务配置失败，请稍后手动执行：$ACME_INSTALL_DIR/acme.sh --install-cronjob"
    return 1
}

# 显示DNS提供商帮助信息
show_dns_help() {
    print_color $LATTE "DNS API 配置说明："
    echo "======================================"
    echo "京东云配置方法："
    echo "1. 登录京东云控制台"
    echo "2. 进入『访问控制』->『用户管理』"
    echo "3. 创建子用户或使用现有用户"
    echo "4. 为用户添加『JDCloudDNSFullAccess』权限"
    echo "5. 在『AccessKey管理』中创建AccessKey"
    echo "6. 将AccessKey ID和Secret Key输入到脚本中"
    echo ""
    echo "其他云服务商类似，需要相应的API权限"
    echo "======================================"
    read -p "按回车键继续..."
}

# 选择域名验证方式（DNS 或 HTTP）
select_verify_method() {
    while true; do
        print_color $BROWN "请选择域名验证方式："
        echo "1) DNS 验证（需配置 DNS 提供商 API，支持泛域名）"
        echo "2) HTTP 验证（需域名已解析到本机，占用 80 端口或提供网站根目录）"
        echo "0) 返回上一级"
        read -p "请输入选择 [0-2]: " verify_choice
        case $verify_choice in
            0)
                return 2
                ;;
            1)
                VERIFY_METHOD="dns"
                print_color $MATCHA "已选择 DNS 验证"
                return 0
                ;;
            2)
                VERIFY_METHOD="http"
                print_color $BROWN "请选择 HTTP 验证方式："
                echo "1) Standalone（临时占用 80 端口，签发时请确保无其他程序占用 80 端口）"
                echo "2) Webroot（将验证文件写入网站根目录，需已运行 Web 服务）"
                echo "0) 返回"
                read -p "请输入选择 [0-2]: " http_mode_choice
                case $http_mode_choice in
                    0) continue ;;
                    1)
                        HTTP_MODE="standalone"
                        print_color $MATCHA "已选择 Standalone 模式"
                        return 0
                        ;;
                    2)
                        HTTP_MODE="webroot"
                        read -p "请输入网站根目录（如 /var/www/html）: " WEBROOT_PATH
                        if [ -z "$WEBROOT_PATH" ]; then
                            print_color $ESPRESSO "网站根目录不能为空"
                            continue
                        fi
                        if [ ! -d "$WEBROOT_PATH" ]; then
                            print_color $ESPRESSO "目录不存在: $WEBROOT_PATH"
                            read -p "是否继续？[y/N]: " cont
                            [[ ! $cont =~ ^[Yy]$ ]] && continue
                        fi
                        print_color $MATCHA "已选择 Webroot 模式，根目录: $WEBROOT_PATH"
                        return 0
                        ;;
                    *)
                        print_color $ESPRESSO "无效选择"
                        continue
                        ;;
                esac
                ;;
            *)
                print_color $ESPRESSO "无效选择，请输入 0、1 或 2"
                continue
                ;;
        esac
    done
}

# 一键安装部署
auto_deploy() {
    print_color $MATCHA "开始一键安装部署..."
    
    # 1. 安装 acme.sh
    if ! install_acme; then
        return 1
    fi
    
    # 2. 选择验证方式（DNS / HTTP）
    select_verify_method
    local verify_result=$?
    if [ $verify_result -eq 2 ]; then
        print_color $LATTE "已取消，返回主菜单"
        return 0
    fi
    
    # 3. 若为 DNS 验证，显示帮助并选择 DNS 提供商
    if [ "$VERIFY_METHOD" = "dns" ]; then
        show_dns_help
        select_dns_provider
        local dns_result=$?
        if [ $dns_result -eq 2 ]; then
            print_color $LATTE "已取消 DNS 提供商选择，返回主菜单"
            return 0
        elif [ $dns_result -ne 0 ]; then
            print_color $ESPRESSO "DNS 凭据验证失败，请重新配置"
            return 1
        fi
    fi
    
    # 4. 输入域名信息
    read -p "请输入主域名（例如：example.com）: " main_domain
    
    # 验证域名格式
    if ! [[ $main_domain =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        print_color $ESPRESSO "域名格式不正确，请重新输入"
        return 1
    fi
    
    read -p "请输入要签发的域名（多个用空格分隔，留空则使用主域名）: " domains
    
    if [ -z "$domains" ]; then
        domains="$main_domain"
        print_color $BROWN "将为主域名 $main_domain 签发证书"
    else
        domains="$main_domain $domains"
        print_color $BROWN "将为以下域名签发证书: $domains"
    fi
    
    # 5. 选择证书类型
    print_color $BROWN "请选择证书类型："
    echo "1) RSA (默认，兼容性好)"
    echo "2) ECC (更安全，体积小)"
    read -p "请输入选择 [1-2]: " cert_choice
    
    case $cert_choice in
        2)
            KEY_LENGTH="ec-256"
            CERT_TYPE="ECC"
            print_color $MATCHA "已选择ECC证书"
            ;;
        *)
            KEY_LENGTH="2048"
            CERT_TYPE="RSA"
            print_color $MATCHA "已选择RSA证书"
            ;;
    esac
    
    # 6. 选择证书颁发机构
    print_color $BROWN "请选择证书颁发机构："
    echo "1) Let's Encrypt (默认)"
    echo "2) ZeroSSL"
    echo "3) Buypass"
    read -p "请输入选择 [1-3]: " ca_choice
    
    case $ca_choice in
        2)
            CA_SERVER="--server zerossl"
            CA_NAME="ZeroSSL"
            if ! register_zerossl_account; then
                return 1
            fi
            ;;
        3)
            CA_SERVER="--server buypass"
            CA_NAME="Buypass"
            ;;
        *)
            CA_SERVER="--server letsencrypt"
            CA_NAME="Let's Encrypt"
            ;;
    esac
    
    print_color $MATCHA "使用证书颁发机构: $CA_NAME"

    # 7. 自动续期配置（默认开启）
    ENABLE_AUTO_RENEW=1
    read -p "是否开启自动续期？[Y/n]: " auto_renew_choice
    if [[ $auto_renew_choice =~ ^[Nn]$ ]]; then
        ENABLE_AUTO_RENEW=0
        print_color $LATTE "本次将不会配置自动续期"
    else
        print_color $MATCHA "将默认开启自动续期"
    fi
    
    # 8. 签发证书
    print_color $BROWN "开始签发${CERT_TYPE}证书..."
    
    cd $ACME_INSTALL_DIR
    local auto_renew_configured=0
    local domain_args=()
    local cert_domain

    for cert_domain in $domains; do
        if [[ "$cert_domain" == \*.* ]] && [ "$VERIFY_METHOD" != "dns" ]; then
            print_color $ESPRESSO "泛域名 $cert_domain 必须使用 DNS 验证，HTTP 验证不支持泛域名"
            return 1
        fi
        domain_args+=("-d" "$cert_domain")
    done
    
    for domain in "$main_domain"; do
        print_color $LATTE "正在为以下域名签发同一张证书: $domains"
        if [ "$VERIFY_METHOD" = "dns" ]; then
            print_color $BROWN "验证方式: DNS（$DNS_PROVIDER）"
        else
            print_color $BROWN "验证方式: HTTP（$HTTP_MODE）"
        fi
        
        # 根据验证方式执行签发命令
        if [ "$VERIFY_METHOD" = "dns" ]; then
            if [ "$CERT_TYPE" = "ECC" ]; then
                ./acme.sh --issue --dns $DNS_PROVIDER "${domain_args[@]}" --keylength ec-256 $CA_SERVER
            else
                ./acme.sh --issue --dns $DNS_PROVIDER "${domain_args[@]}" --keylength 2048 $CA_SERVER
            fi
        else
            # HTTP 验证：Standalone 或 Webroot
            if [ "$CERT_TYPE" = "ECC" ]; then
                if [ "$HTTP_MODE" = "standalone" ]; then
                    ./acme.sh --issue --standalone "${domain_args[@]}" --keylength ec-256 $CA_SERVER
                else
                    ./acme.sh --issue "${domain_args[@]}" -w "$WEBROOT_PATH" --keylength ec-256 $CA_SERVER
                fi
            else
                if [ "$HTTP_MODE" = "standalone" ]; then
                    ./acme.sh --issue --standalone "${domain_args[@]}" --keylength 2048 $CA_SERVER
                else
                    ./acme.sh --issue "${domain_args[@]}" -w "$WEBROOT_PATH" --keylength 2048 $CA_SERVER
                fi
            fi
        fi
        
        if [ $? -eq 0 ]; then
            print_color $MATCHA "域名 $domain 证书签发成功！"
            
            # 询问是否安装证书
            read -p "是否安装证书到指定目录？[y/N]: " install_choice
            if [[ $install_choice =~ ^[Yy]$ ]]; then
                read -p "请输入证书安装目录（默认：/etc/ssl/$domain）: " install_dir
                install_dir=${install_dir:-"/etc/ssl/$domain"}
                
                # 创建目录
                sudo mkdir -p "$install_dir"
                
                # 安装证书
                ./acme.sh --install-cert -d "$domain" \
                    --cert-file "$install_dir/cert.pem" \
                    --key-file "$install_dir/key.pem" \
                    --fullchain-file "$install_dir/fullchain.pem" \
                    --reloadcmd "echo '证书已安装到 $install_dir'"
                
                if [ $? -eq 0 ]; then
                    print_color $MATCHA "证书已成功安装到 $install_dir"
                    
                    # 显示证书文件权限
                    echo "证书文件权限："
                    ls -la "$install_dir/" | grep -E "(cert.pem|key.pem|fullchain.pem)"
                else
                    print_color $ESPRESSO "证书安装失败"
                fi
            fi
            
            # 显示证书信息
            echo ""
            print_color $BROWN "证书信息："
            ./acme.sh --info -d "$domain"

            if [ "$auto_renew_configured" -eq 0 ]; then
                configure_auto_renew
                auto_renew_configured=1
            fi
            
        else
            print_color $ESPRESSO "域名 $domain 证书签发失败！"
            print_color $LATTE "请检查："
            if [ "$VERIFY_METHOD" = "dns" ]; then
                echo "1. DNS API 凭据是否正确"
                echo "2. 域名解析是否生效"
            else
                echo "1. 域名是否已解析到本机（HTTP 验证需从外网可访问 http://域名/.well-known/acme-challenge/）"
                if [ "$HTTP_MODE" = "standalone" ]; then
                    echo "2. 80 端口是否已被占用（签发时请暂时关闭 Nginx/Apache 等）"
                else
                    echo "2. 网站根目录 $WEBROOT_PATH 是否可写、Web 服务是否已运行"
                fi
            fi
            echo "3. 网络连接是否正常"
        fi
        echo "--------------------------------------"
    done
}

# 手动更新证书
manual_renew() {
    if ! check_acme_installed; then
        print_color $ESPRESSO "acme.sh未安装，请先执行一键安装部署！"
        return 1
    fi
    
    cd $ACME_INSTALL_DIR
    
    print_color $BROWN "请选择更新方式："
    echo "1) 更新所有证书"
    echo "2) 更新指定域名证书"
    echo "3) 强制更新所有证书（忽略有效期）"
	echo "0) 返回上一级菜单"
    read -p "请输入选择 [0-3]: " renew_choice
    
    case $renew_choice in
        1)
            print_color $LATTE "开始更新所有证书..."
            ./acme.sh --renew-all
            ;;
        2)
            read -p "请输入要更新的域名: " renew_domain
            if [ -z "$renew_domain" ]; then
                print_color $ESPRESSO "域名不能为空"
                return 1
            fi
            print_color $LATTE "开始更新域名 $renew_domain 的证书..."
            ./acme.sh --renew -d "$renew_domain"
            ;;
        3)
            print_color $LATTE "开始强制更新所有证书..."
            ./acme.sh --renew-all --force
            ;;
		0)
			print_color $MATCHA "返回上一级菜单..."
			return 0
			;;
        *)
            print_color $ESPRESSO "无效选择"
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        print_color $MATCHA "证书更新成功！"
    else
        print_color $ESPRESSO "证书更新失败！"
    fi
}

# 查看已安装证书列表
list_certificates() {
    if ! check_acme_installed; then
        print_color $ESPRESSO "acme.sh未安装，请先执行一键安装部署！"
        return 1
    fi
    
    cd $ACME_INSTALL_DIR
    
    print_color $BROWN "已安装的证书列表："
    echo "======================================"
    
    # 使用acme.sh内置命令列出证书
    ./acme.sh --list
    
    echo ""
    print_color $LATTE "证书存储目录: $ACME_INSTALL_DIR"
}

# 查看指定证书信息
view_certificate() {
    if ! check_acme_installed; then
        print_color $ESPRESSO "acme.sh未安装，请先执行一键安装部署！"
        return 1
    fi
    
    cd $ACME_INSTALL_DIR
    
    read -p "请输入要查看的域名: " view_domain
    
    if [ -z "$view_domain" ]; then
        print_color $ESPRESSO "域名不能为空"
        return 1
    fi
    
    print_color $MATCHA "证书信息 - $view_domain"
    echo "======================================"
    
    # 使用acme.sh查看证书信息
    ./acme.sh --info -d "$view_domain"
    
    if [ $? -ne 0 ]; then
        print_color $ESPRESSO "未找到域名 $view_domain 的证书信息"
        return 1
    fi
    
    # 显示证书文件详情
    cert_dir="$ACME_INSTALL_DIR/$view_domain"
    if [ -d "$cert_dir" ]; then
        echo ""
        print_color $BROWN "证书文件："
        ls -la "$cert_dir/" | grep -E "\.(cer|key|pem|crt)$"
    fi
}

# 卸载/删除证书
uninstall_certificate() {
    if ! check_acme_installed; then
        print_color $ESPRESSO "acme.sh未安装，无需卸载"
        return 1
    fi
    
    cd $ACME_INSTALL_DIR
    
    print_color $BROWN "请选择卸载选项："
    echo "1) 删除单个域名证书"
    echo "2) 删除所有证书"
    echo "3) 仅移除自动续期（保留证书文件）"
    read -p "请输入选择 [1-3]: " uninstall_choice
    
    case $uninstall_choice in
        1)
            uninstall_single_cert
            ;;
        2)
            uninstall_all_certs
            ;;
        3)
            disable_auto_renew
            ;;
        *)
            print_color $ESPRESSO "无效选择"
            return 1
            ;;
    esac
}

# 卸载单个证书
uninstall_single_cert() {
    echo -e "${BROWN}请告诉我您想卸载哪个域名的证书${NC}"
    
    # 显示当前证书列表
    echo -e "${CREAM}当前安装的证书：${NC}"
    echo "======================================"
    ./acme.sh --list | grep -v "Main_Domain" | while read line; do
        if [ -n "$line" ]; then
            domain=$(echo "$line" | awk '{print $1}')
            echo "  📄 $domain"
        fi
    done
    echo "======================================"
    
    read -p "请输入要卸载的域名: " uninstall_domain
    
    if [ -z "$uninstall_domain" ]; then
        print_color $ESPRESSO "域名不能为空"
        return 1
    fi
    
    # 检查证书是否存在
    if [ ! -d "$ACME_INSTALL_DIR/$uninstall_domain" ]; then
        print_color $ESPRESSO "未找到域名 $uninstall_domain 的证书"
        return 1
    fi
    
    # 确认卸载
    print_color $ESPRESSO "⚠️  即将卸载证书：$uninstall_domain"
    echo -e "${CREAM}这将执行以下操作：${NC}"
    echo "  • 删除证书文件"
    echo "  • 移除自动续期任务"
    echo "  • 清理配置信息"
    echo
    read -p "确定要卸载吗？[y/N]: " confirm_uninstall
    
    if [[ ! $confirm_uninstall =~ ^[Yy]$ ]]; then
        print_color $LATTE "卸载已取消"
        return 0
    fi
    
    # 执行卸载
    print_brewing "正在卸载证书 $uninstall_domain ..."
    
    # 使用acme.sh的卸载功能
    ./acme.sh --remove -d "$uninstall_domain"
    
    if [ $? -eq 0 ]; then
        print_color $MATCHA "✅ 证书 $uninstall_domain 卸载成功！"
        
        # 额外清理
        if [ -d "$ACME_INSTALL_DIR/$uninstall_domain" ]; then
            rm -rf "$ACME_INSTALL_DIR/$uninstall_domain"
            print_color $MATCHA "已清理残留文件"
        fi
    else
        print_color $ESPRESSO "❌ 证书卸载失败，尝试手动清理..."
        manual_cleanup "$uninstall_domain"
    fi
}

# 卸载所有证书
uninstall_all_certs() {
    print_color $ESPRESSO "🚨 警告：这将删除所有证书！"
    echo -e "${CREAM}受影响的操作：${NC}"
    echo "  • 删除所有证书文件"
    echo "  • 移除所有自动续期任务"
    echo "  • 清理所有证书配置"
    echo
    echo -e "${LATTE}这通常用于：${NC}"
    echo "  • 服务器迁移前"
    echo "  • 彻底重置证书系统"
    echo "  • 测试环境清理"
    echo
    
    read -p "您确定要删除所有证书吗？[yes/NO]: " confirm_all
    
    if [ "$confirm_all" != "yes" ]; then
        print_color $LATTE "操作已取消"
        return 0
    fi
    
    print_brewing "开始卸载所有证书..."
    
    # 获取所有证书域名
    local cert_domains=$(./acme.sh --list | grep -v "Main_Domain" | awk '{print $1}')
    local count=0
    
    if [ -z "$cert_domains" ]; then
        print_color $LATTE "没有找到可卸载的证书"
        return 0
    fi
    
    for domain in $cert_domains; do
        print_brewing "卸载证书: $domain"
        ./acme.sh --remove -d "$domain"
        if [ $? -eq 0 ]; then
            print_color $MATCHA "✅ 已卸载: $domain"
            count=$((count + 1))
        else
            print_color $ESPRESSO "❌ 卸载失败: $domain"
        fi
    done
    
    # 清理残留目录
    print_brewing "清理残留文件..."
    find "$ACME_INSTALL_DIR" -maxdepth 1 -type d -name "*.com" -o -name "*.org" -o -name "*.net" | while read dir; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            print_color $MATCHA "已清理: $(basename "$dir")"
        fi
    done
    
    print_color $MATCHA "🎉 证书卸载完成！共卸载 $count 个证书"
    print_color $LATTE "☕ 所有SSL证书已被清理"
}

# 禁用自动续期
disable_auto_renew() {
     echo -e "${BROWN}您想禁用哪个域名的自动续期？${NC}"
    
    # 显示当前证书列表
    echo -e "${CREAM}当前证书列表：${NC}"
    echo "======================================"
    ./acme.sh --list | grep -v "Main_Domain" | while read line; do
        if [ -n "$line" ]; then
            domain=$(echo "$line" | awk '{print $1}')
            echo "  🔄 $domain"
        fi
    done
    echo "======================================"
    
    read -p "请输入域名（留空则禁用所有）: " disable_domain
    
    if [ -z "$disable_domain" ]; then
        print_color $ESPRESSO "⚠️  将禁用所有证书的自动续期"
        read -p "确定要继续吗？[yes/NO]: " confirm_disable_all
        
        if [ "$confirm_disable_all" != "yes" ]; then
            print_color $LATTE "操作已取消"
            return 0
        fi
        
        # 禁用所有自动续期
        local cert_domains=$(./acme.sh --list | grep -v "Main_Domain" | awk '{print $1}')
        local count=0
        
        for domain in $cert_domains; do
            ./acme.sh --remove -d "$domain" --auto-upgrade 0
            if [ $? -eq 0 ]; then
                print_color $MATCHA "✅ 已禁用自动续期: $domain"
                count=$((count + 1))
            fi
        done
        
        print_color $MATCHA "已禁用 $count 个证书的自动续期"
        
    else
        # 禁用单个域名的自动续期
        ./acme.sh --remove -d "$disable_domain" --auto-upgrade 0
        
        if [ $? -eq 0 ]; then
            print_color $MATCHA "✅ 已禁用 $disable_domain 的自动续期"
            print_color $LATTE "证书文件仍然保留，但不会自动更新"
        else
            print_color $ESPRESSO "❌ 操作失败"
        fi
    fi
}

# 手动清理（备用方案）
manual_cleanup() {
    local domain="$1"
    
     echo -e "${BROWN}尝试手动清理 $domain${NC}"
    
    # 清理证书目录
    if [ -d "$ACME_INSTALL_DIR/$domain" ]; then
        rm -rf "$ACME_INSTALL_DIR/$domain"
        print_color $MATCHA "已删除证书目录: $ACME_INSTALL_DIR/$domain"
    fi
    
    # 清理cron任务（如果存在）
    local cron_count=$(crontab -l 2>/dev/null | grep -c "$domain")
    if [ $cron_count -gt 0 ]; then
        crontab -l | grep -v "$domain" | crontab -
        print_color $MATCHA "已移除相关的自动续期任务"
    fi
    
    # 清理配置引用
    local config_file="$ACME_INSTALL_DIR/account.conf"
    if [ -f "$config_file" ] && grep -q "$domain" "$config_file"; then
        sed -i "/$domain/d" "$config_file"
        print_color $MATCHA "已清理配置引用"
    fi
    
    print_color $MATCHA "手动清理完成"
}

# 证书状态检查
check_cert_status() {
    # 动态查找acme.sh路径
    find_acme_path() {
        local paths=(
            "$HOME/.acme.sh"
            "/root/.acme.sh" 
            "/usr/local/share/acme.sh"
            "$(dirname "$(which acme.sh 2>/dev/null)" 2>/dev/null)"
        )
        
        for path in "${paths[@]}"; do
            if [ -f "$path/acme.sh" ]; then
                echo "$path"
                return 0
            fi
        done
        return 1
    }
    
    # 查找acme.sh安装目录
    local found_dir=$(find_acme_path)
    if [ -z "$found_dir" ]; then
        print_color $ESPRESSO "❌ 未找到 acme.sh，请先运行一键安装部署"
        return 1
    fi
    
    ACME_INSTALL_DIR="$found_dir"
    cd "$ACME_INSTALL_DIR"
    
    print_color $BROWN "📊 证书状态报告"
    echo "======================================"
    echo -e "${CREAM}检测路径: $ACME_INSTALL_DIR${NC}"
    echo ""
    
    local cert_count=0
    local renew_count=0
    local expiring_count=0
    
    # 主要检测方法：直接扫描证书目录
    echo -e "${CREAM}扫描证书目录...${NC}"
    for item in "$ACME_INSTALL_DIR"/*; do
        if [ -d "$item" ]; then
            local domain=$(basename "$item")
            # 检查是否是有效的证书目录（包含证书文件）
            if [ -f "$item/fullchain.cer" ] || [ -f "$item/$domain.key" ]; then
                cert_count=$((cert_count + 1))
                
                echo -e "${CREAM}📄 证书: $domain${NC}"
                
                # 检查证书过期时间
                if [ -f "$item/fullchain.cer" ]; then
                    local expiry=$(openssl x509 -in "$item/fullchain.cer" -noout -enddate 2>/dev/null 2>/dev/null | cut -d= -f2)
                    if [ -n "$expiry" ]; then
                        echo -e "  📅 过期时间: $expiry"
                        
                        # 计算剩余天数
                        local expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null)
                        local current_epoch=$(date +%s)
                        if [ -n "$expiry_epoch" ] && [ "$expiry_epoch" -gt "$current_epoch" ]; then
                            local days_left=$(( (expiry_epoch - current_epoch) / 86400 ))
                            if [ $days_left -lt 10 ]; then
                                echo -e "  ⚠️  剩余天数: ${ESPRESSO}$days_left 天${NC}"
                                expiring_count=$((expiring_count + 1))
                            else
                                echo -e "  ✅ 剩余天数: ${MATCHA}$days_left 天${NC}"
                            fi
                        else
                            echo -e "  ❌ 证书已过期"
                            expiring_count=$((expiring_count + 1))
                        fi
                    fi
                fi
                
                # 检查自动续期
                local renew_status=$(crontab -l 2>/dev/null | grep -c "$domain")
                if [ $renew_status -gt 0 ]; then
                    echo -e "  🔄 自动续期: ${MATCHA}启用${NC}"
                    renew_count=$((renew_count + 1))
                else
                    echo -e "  ⏸️  自动续期: ${LATTE}禁用${NC}"
                fi
                
                echo ""
            fi
        fi
    done
    
    # 显示结果
    echo "======================================"
    echo -e "${CREAM}📈 统计信息：${NC}"
    if [ $cert_count -eq 0 ]; then
        echo -e "  ${LATTE}暂无已安装的证书${NC}"
        echo -e "  ${LATTE}请使用『☕ 一键冲泡证书』功能申请SSL证书${NC}"
    else
        echo -e "  总证书数: ${MATCHA}$cert_count${NC}"
        echo -e "  自动续期: ${MATCHA}$renew_count${NC}"
        echo -e "  禁用续期: ${LATTE}$((cert_count - renew_count))${NC}"
        if [ $expiring_count -gt 0 ]; then
            echo -e "  即将过期: ${ESPRESSO}$expiring_count${NC}"
        fi
    fi
    echo ""
}

# 查看当前配置的环境变量
show_env_config() {
    clear
    print_color $BROWN "当前配置的环境变量（敏感信息已脱敏）"
    echo -e "${CREAM}----------------------------------------${NC}"
    echo ""

    # 当前 shell 的 DNS 相关变量（可能未设置）
    if [ -n "$DNS_PROVIDER" ]; then
        print_color $MATCHA "DNS_PROVIDER = $DNS_PROVIDER"
    else
        echo "DNS_PROVIDER = （未设置）"
    fi

    echo "各 DNS 提供商凭据状态："
    echo "  Cloudflare:    CF_Token=$([ -n "$CF_Token" ] && echo '***已设置***' || echo '（未设置）')  CF_Zone_ID=$([ -n "$CF_Zone_ID" ] && echo '***已设置***' || echo '（未设置）')  CF_Account_ID=$([ -n "$CF_Account_ID" ] && echo '***已设置***' || echo '（未设置）')  CF_Key=$([ -n "$CF_Key" ] && echo '***已设置***' || echo '（未设置）')  CF_Email=$([ -n "$CF_Email" ] && echo '***已设置***' || echo '（未设置）')"
    echo "  阿里云:        Ali_Key=$([ -n "$Ali_Key" ] && echo '***已设置***' || echo '（未设置）')  Ali_Secret=$([ -n "$Ali_Secret" ] && echo '***已设置***' || echo '（未设置）')"
    echo "  腾讯云:        Tencent_SecretId=$([ -n "$Tencent_SecretId" ] && echo '***已设置***' || echo '（未设置）')  Tencent_SecretKey=$([ -n "$Tencent_SecretKey" ] && echo '***已设置***' || echo '（未设置）')"
    echo "  DNSPod:        DP_Id=$([ -n "$DP_Id" ] && echo '***已设置***' || echo '（未设置）')  DP_Key=$([ -n "$DP_Key" ] && echo '***已设置***' || echo '（未设置）')"
    echo "  华为云:        HUAWEICLOUD_Username=$([ -n "$HUAWEICLOUD_Username" ] && echo '***已设置***' || echo '（未设置）')  HUAWEICLOUD_Password=$([ -n "$HUAWEICLOUD_Password" ] && echo '***已设置***' || echo '（未设置）')"
    echo "  京东云:        JD_ACCESS_KEY_ID=$([ -n "$JD_ACCESS_KEY_ID" ] && echo '***已设置***' || echo '（未设置）')  JD_ACCESS_KEY_SECRET=$([ -n "$JD_ACCESS_KEY_SECRET" ] && echo '***已设置***' || echo '（未设置）')"

    echo ""
    if [ -n "$ACME_INSTALL_DIR" ]; then
        echo "ACME_INSTALL_DIR = $ACME_INSTALL_DIR"
    else
        echo "ACME_INSTALL_DIR = （未设置，将使用默认）"
    fi
    echo ""
}

# 显示主菜单
show_menu() {
    clear
    print_cafe_logo
	echo -e "${CREAM}======================================${NC}"
    echo -e "${BROWN}        🏷️ CertCafe 主菜单${NC}"
    echo -e "${CREAM}======================================${NC}"
    echo "1) 一键安装部署"
    echo "2) 手动更新证书"
    echo "3) 查看已安装证书列表"
    echo "4) 查看指定证书信息"
    echo "5) 显示DNS配置帮助"
    echo "6) 卸载/停止证书"
	echo "7) 证书状态报告"
	echo "8) 查看当前配置的环境变量"
	echo "0) 退出"
    echo ""
}

# 离开信息
goodbye_from_cafe() {
    echo -e "${BROWN}感谢光临 CertCafe！${NC}"
    print_coffee_cup
    echo -e "${CREAM}期待您的再次光临！👋${NC}"
    echo -e "${LATTE}记住：好网站，从一杯安全的证书开始！${NC}"
    echo ""
}

# 主函数
main() {
    while true; do
        show_menu
        read -p "请选择操作 [0-8]: " choice
        
        case $choice in
			0)
                goodbye_from_cafe
                exit 0
                ;;
            1)
				clear
                auto_deploy
                ;;
            2)
                manual_renew
                ;;
            3)
                list_certificates
                ;;
            4)
                view_certificate
                ;;
            5)
                show_dns_help
                ;;
            6)
                uninstall_certificate
                ;;
			7)
                check_cert_status
                ;;
            8)
                show_env_config
                ;;
            *)
                print_color $ESPRESSO "无效选择，请重新输入！"
                ;;
        esac
        
        echo ""
        read -p "按回车键继续..."
    done
}

# 脚本启动
if [ "$(id -u)" -eq 0 ]; then
    print_color $LATTE "警告：不建议使用root用户执行此脚本"
    read -p "是否继续？[y/N]: " continue_choice
    if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

main
