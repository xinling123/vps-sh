#!/usr/bin/env bash
set -euo pipefail

# ====== 可配置项 ======
readonly TARGET_DNS="8.8.8.8#dns.google 1.1.1.1#cloudflare-dns.com"
readonly SECURE_RESOLVED_CONFIG="[Resolve]
DNS=${TARGET_DNS}
LLMNR=no
MulticastDNS=no
DNSSEC=allow-downgrade
DNSOverTLS=yes
"
# 调试开关：true 输出更多调试信息
DEBUG=true
# =======================

readonly GREEN="\033[0;32m"
readonly YELLOW="\033[1;33m"
readonly RED="\033[0;31m"
readonly NC="\033[0m"
log() { echo -e "${GREEN}--> $1${NC}"; }
log_warn() { echo -e "${YELLOW}--> $1${NC}"; }
log_error() { echo -e "${RED}--> $1${NC}" >&2; }

purify_and_harden_dns() {
    echo -e "\n--- 开始执行DNS净化与安全加固流程 ---"
    local debian_version
    debian_version=$(grep "VERSION_ID" /etc/os-release | cut -d'=' -f2 | tr -d '"' || echo "unknown")

    log "阶段一：正在清除所有潜在的DNS冲突源..."
    local dhclient_conf="/etc/dhcp/dhclient.conf"
    if [[ -f "$dhclient_conf" ]]; then
        if ! grep -q "ignore domain-name-servers;" "$dhclient_conf" || ! grep -q "ignore domain-search;" "$dhclient_conf"; then
            log "正在驯服 DHCP 客户端 (dhclient)..."
            {
                echo ""
                echo "ignore domain-name-servers;"
                echo "ignore domain-search;"
            } >> "$dhclient_conf"
            log "${GREEN}✅ 已确保 'ignore' 指令存在于 ${dhclient_conf}${NC}"
        fi
    fi

    local ifup_script="/etc/network/if-up.d/resolved"
    if [[ -f "$ifup_script" ]] && [[ -x "$ifup_script" ]]; then
        log "正在禁用有冲突的 if-up.d 兼容性脚本..."
        chmod -x "$ifup_script"
        log "${GREEN}✅ 已移除 ${ifup_script} 的可执行权限。${NC}"
    fi

    local interfaces_file="/etc/network/interfaces"
    if [[ -f "$interfaces_file" ]] && grep -qE '^[[:space:]]*dns-(nameservers|search|domain)' "$interfaces_file"; then
        log "正在净化 /etc/network/interfaces 中的厂商残留DNS配置..."
        sed -i -E 's/^[[:space:]]*(dns-(nameservers|search|domain).*)/# \1/' "$interfaces_file"
        log "${GREEN}✅ 旧有DNS配置已成功注释禁用。${NC}"
    fi

    log "阶段二：正在配置 systemd-resolved..."
    if ! command -v resolvectl &> /dev/null; then
        log "正在安装 systemd-resolved..."
        apt-get update -y > /dev/null
        apt-get install -y systemd-resolved > /dev/null
    fi

    if [[ "$debian_version" == "11" ]] && dpkg -s resolvconf &> /dev/null; then
        log "检测到 Debian 11 上的 'resolvconf'，正在卸载..."
        apt-get remove -y resolvconf > /dev/null
        rm -f /etc/resolv.conf
        log "${GREEN}✅ 'resolvconf' 已成功卸载。${NC}"
    fi

    log "正在启用并启动 systemd-resolved 服务..."
    systemctl enable systemd-resolved
    systemctl start systemd-resolved

    log "正在应用最终的DNS安全配置 (DoT, DNSSEC...)"
    echo -e "${SECURE_RESOLVED_CONFIG}" > /etc/systemd/resolved.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    systemctl restart systemd-resolved
    sleep 1

    log "阶段三：正在安全地重启网络服务以应用所有更改..."
    if systemctl is-enabled --quiet networking.service; then
        systemctl restart networking.service
        log "${GREEN}✅ networking.service 已安全重启。${NC}"
    fi

    echo -e "\n${GREEN}✅ 全部操作完成！以下是最终的 DNS 配置状态：${NC}"
    echo "===================================================="
    resolvectl status
    echo "===================================================="
    echo -e "\n${GREEN}DNS净化脚本执行完成${NC}"
    echo -e "贡献者：NSdesk"
    echo -e "更多信息：https://www.nodeseek.com/space/23129/"
    echo "===================================================="
}

# 辅助：归一化 token（按空格拆分、去空、排序、去重、合并成单行）
normalize_tokens() {
    if [[ -z "${1:-}" ]]; then
        echo ""
        return
    fi
    echo "$1" | tr ' ' '\n' | sed '/^$/d' | sort -u | tr '\n' ' ' | xargs
}

main() {
    if [[ $EUID -ne 0 ]]; then
       log_error "错误: 此脚本必须以 root 用户身份运行。请使用 'sudo'。"
       exit 1
    fi

    echo "--- 开始执行全面系统DNS健康检查 ---"
    local is_perfect=true

    echo -n "1. 检查 systemd-resolved 实时状态... "
    if ! command -v resolvectl &> /dev/null || ! resolvectl status &> /dev/null; then
        echo -e "${YELLOW}服务未运行或无响应。${NC}"
        is_perfect=false
    else
        local status_output
        status_output=$(resolvectl status)

        # 更精确地在 Global 区块内匹配 "DNS Server(s)" 行：遇到空行或下一个区块停止搜索
        local dns_line
        dns_line=$(echo "$status_output" | awk '
            BEGIN { in_global=0 }
            /^Global/ { in_global=1; next }
            in_global && /^$/ { exit }
            in_global && /^[[:space:]]*DNS Servers?/ { print; exit }
        ')

        # 去掉标签并压缩空白，删除 \r
        local dns_clean
        dns_clean=$(echo "$dns_line" | sed -E 's/^[[:space:]]*DNS Servers?[[:space:]]*//' | tr -d '\r' | tr -s ' ')

        # 归一化当前与目标
        local norm_current_dns norm_target_dns
        norm_current_dns=$(normalize_tokens "$dns_clean")
        norm_target_dns=$(normalize_tokens "${TARGET_DNS}")

        if [[ "${DEBUG}" == true ]]; then
            echo "调试信息："
            echo "  原始 Global DNS 行：${dns_line}"
            echo "  清理后 DNS 字符串：${dns_clean}"
            echo "  归一化后（当前）：'${norm_current_dns}'"
            echo "  归一化后（目标）：'${norm_target_dns}'"
            echo "  LLMNR 检查: $(echo "${status_output}" | grep -q -- "-LLMNR" && echo "禁用（通过）" || echo "未禁用（失败）")"
            echo "  mDNS 检查: $(echo "${status_output}" | grep -q -- "-mDNS" && echo "禁用（通过）" || echo "未禁用（失败）")"
            echo "  DoT 检查: $(echo "${status_output}" | grep -q -- "+DNSOverTLS" && echo "启用（通过）" || echo "未启用（失败）")"
            echo "  DNSSEC 检查: $(echo "${status_output}" | grep -q "DNSSEC=allow-downgrade" && echo "allow-downgrade（通过）" || echo "未设置/失败")"
        fi

        # 检查标志
        local flags_ok=true
        if ! echo "${status_output}" | grep -q -- "-LLMNR"; then flags_ok=false; fi
        if ! echo "${status_output}" | grep -q -- "-mDNS"; then flags_ok=false; fi
        if ! echo "${status_output}" | grep -q -- "+DNSOverTLS"; then flags_ok=false; fi
        if ! echo "${status_output}" | grep -q "DNSSEC=allow-downgrade"; then flags_ok=false; fi

        # 默认：严格集合比较（归一化后相等且 flags_ok 为 true）
        local dns_ok=false
        if [[ "${norm_current_dns}" == "${norm_target_dns}" ]] && [[ "${flags_ok}" == true ]]; then
            dns_ok=true
        fi

        # 宽松替代（如果你想允许额外条目，只需启用下一行并注释掉上面的严格比较）
        # if echo "${status_output}" | grep -q "8.8.8.8" && echo "${status_output}" | grep -q "1.1.1.1" && [[ "${flags_ok}" == true ]]; then dns_ok=true; fi

        if [[ "${dns_ok}" != true ]]; then
            echo -e "${YELLOW}实时配置与安全目标不符。${NC}"
            is_perfect=false
        else
            echo -e "${GREEN}配置正确。${NC}"
        fi
    fi

    echo -n "2. 检查 dhclient.conf 配置... "
    local dhclient_conf="/etc/dhcp/dhclient.conf"
    if [[ -f "$dhclient_conf" ]]; then
        if grep -q "ignore domain-name-servers;" "$dhclient_conf" && grep -q "ignore domain-search;" "$dhclient_conf"; then
            echo -e "${GREEN}已净化。${NC}"
        else
            echo -e "${YELLOW}未发现 'ignore' 净化参数。${NC}"
            is_perfect=false
        fi
    else
        echo -e "${GREEN}文件不存在，无需净化。${NC}"
    fi

    echo -n "3. 检查 if-up.d 冲突脚本... "
    local ifup_script="/etc/network/if-up.d/resolved"
    if [[ ! -f "$ifup_script" ]] || [[ ! -x "$ifup_script" ]]; then
        echo -e "${GREEN}已禁用或不存在。${NC}"
    else
        echo -e "${YELLOW}脚本存在且可执行。${NC}"
        is_perfect=false
    fi

    if [[ "$is_perfect" == true ]]; then
        echo -e "\n${GREEN}✅ 全面检查通过！系统DNS配置稳定且安全。无需任何操作。${NC}"
        echo -e "贡献者：NSdesk"
        echo -e "更多信息：https://www.nodeseek.com/space/23129/"
        exit 0
    else
        echo -e "\n${YELLOW}--> 一项或多项检查未通过。为了确保系统的长期稳定，将执行完整的净化与加固流程...${NC}"
        purify_and_harden_dns
    fi
}

main "$@"
