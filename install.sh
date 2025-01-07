#!/bin/bash

set -e # 脚本遇到错误时立即退出

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 函数：输出带颜色的信息
info() { echo -e "${GREEN}$1${NC}"; }
warn() { echo -e "${YELLOW}$1${NC}"; }
error() { echo -e "${RED}$1${NC}"; }

# 函数：检查命令是否存在
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# 函数：安装依赖
install_dependency() {
    local package="$1"
    if ! command_exists "$package"; then
        info "正在安装 $package..."
        if command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y "$package"
        elif command_exists yum; then
            sudo yum install -y "$package"
        else
            error "无法找到 apt-get 或 yum，请手动安装 $package"
            exit 1
        fi
        if command_exists "$package"; then
            info "$package 安装成功！"
        else
            error "$package 安装失败！"
            exit 1
        fi
    else
        info "$package 已安装。"
    fi
}

# 函数：验证 Telegram Bot Token 和 Chat ID
verify_telegram_credentials() {
  local attempts=0
  while true; do
    read -p "请输入 Telegram Bot Token: " TOKEN
    read -p "请输入 Telegram 机器人聊天 ID: " CHAT_ID

    # 基本验证 Bot Token 和 Chat ID
    if [[ ! -n "$TOKEN" || ! -n "$CHAT_ID" ]]; then
      error "Telegram Bot Token 和 Chat ID 不能为空！"
      attempts=$((attempts+1))
      if [[ $attempts -ge 3 ]]; then
        error "验证失败次数过多，脚本退出。"
        exit 1
      fi
      read -p "是否重新输入 Telegram Bot Token 和 Chat ID？(y/n) " retry
      if [[ "$retry" != "y" && "$retry" != "Y" ]]; then
        error "脚本退出。"
        exit 1
      fi
      continue
    fi

    if [[ ${#TOKEN} -lt 45 ]]; then
      error "Telegram Bot Token 无效！长度必须大于或等于 45 个字符。"
      attempts=$((attempts+1))
      if [[ $attempts -ge 3 ]]; then
        error "验证失败次数过多，脚本退出。"
        exit 1
      fi
      read -p "是否重新输入 Telegram Bot Token 和 Chat ID？(y/n) " retry
      if [[ "$retry" != "y" && "$retry" != "Y" ]]; then
        error "脚本退出。"
        exit 1
      fi
      continue
    fi

    if ! [[ $CHAT_ID =~ ^[0-9]+$ ]]; then
      error "Telegram Chat ID 无效！必须是数字。"
      attempts=$((attempts+1))
      if [[ $attempts -ge 3 ]]; then
        error "验证失败次数过多，脚本退出。"
        exit 1
      fi
      read -p "是否重新输入 Telegram Bot Token 和 Chat ID？(y/n) " retry
      if [[ "$retry" != "y" && "$retry" != "Y" ]]; then
        error "脚本退出。"
        exit 1
      fi
      continue
    fi

    response=$(curl -s -X POST "https://api.telegram.org/bot${TOKEN}/getMe")
    if echo "$response" | grep -q '"ok":true'; then
      info "Telegram Bot Token 和 Chat ID 验证成功!"
      break
    else
      error "Telegram Bot Token 和 Chat ID 验证失败！"
      error "错误信息: $response"
      attempts=$((attempts+1))
      if [[ $attempts -ge 3 ]]; then
        error "验证失败次数过多，脚本退出。"
        exit 1
      fi
      read -p "是否重新输入 Telegram Bot Token 和 Chat ID？(y/n) " retry
      if [[ "$retry" != "y" && "$retry" != "Y" ]]; then
        error "脚本退出。"
        exit 1
      fi
    fi
  done
}

# 函数：获取安装路径
get_install_path() {
    read -p "请输入安装路径（默认为 /usr/local/bin/）: " install_path
    if [[ -z "$install_path" ]]; then
        install_path="/usr/local/bin/"
    fi

    if [[ ! -d "$install_path" ]]; then
        error "安装路径 $install_path 不存在！"
        read -p "是否创建该目录？(y/n) " create_dir
        if [[ "$create_dir" == "y" || "$create_dir" == "Y" ]]; then
            sudo mkdir -p "$install_path"
            if [[ ! -d "$install_path" ]]; then
              error "创建目录 $install_path 失败！"
              exit 1
            fi
            info "目录 $install_path 创建成功！"
        else
          error "安装路径无效，请重新运行脚本并输入有效的安装路径！"
          exit 1
        fi
    fi

    if [[ ! -w "$install_path" ]]; then
      error "安装路径 $install_path 没有写入权限！"
      exit 1
    fi
    echo "$install_path"
}

# 函数：部署脚本
deploy_script() {
    local script_path="$1"
    info "正在部署脚本到 $script_path..."

    # 构建脚本内容
    local script_content
    script_content=$(cat <<'EOF'
#!/bin/bash

set -e

# Telegram Bot API 令牌
TOKEN=""

# Telegram 机器人聊天 ID
CHAT_ID=""

# 获取服务器名称
server_name=$(hostname)

# 获取 IP 地址
ip_address=$(ip addr | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d'/' -f1 | head -n 1)

# 获取 CPU 使用率
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

# 获取内存使用率
mem_usage=$(free -m | awk 'NR==2{printf "%.2f%%\n", $3/$2*100}')

# 获取磁盘使用率
disk_usage=$(df -h | awk '$NF=="/"{printf "%s", $5}' | sed 's/%//g')

# 获取 vnstat 信息函数
get_vnstat_info() {
    local type="$1"
    local value
    case "$type" in
        daily)
            local rx=$(vnstat -d | grep "$(date +%Y-%m-%d)" | awk '{print $2 * 1}' | sed 's/[^0-9.]*//g')
            local tx=$(vnstat -d | grep "$(date +%Y-%m-%d)" | awk '{print $5 * 1}' | sed 's/[^0-9.]*//g')
            value=$(echo "$rx + $tx" | bc)
            ;;
        monthly)
            local rx=$(vnstat -m | awk -v month=$(date +%Y-%m) '$1 == month {print $2 * 1}' | sed 's/[^0-9.]*//g')
            local tx=$(vnstat -m | awk -v month=$(date +%Y-%m) '$1 == month {print $5 * 1}' | sed 's/[^0-9.]*//g')
            value=$(echo "$rx + $tx" | bc)
            ;;
        total)
            local rx=$(vnstat -y | awk 'NR==6 {print $2 * 1}' | sed 's/[^0-9.]*//g')
            local tx=$(vnstat -y | awk 'NR==6 {print $5 * 1}' | sed 's/[^0-9.]*//g')
            value=$(echo "$rx + $tx" | bc)
            ;;
        *)
            echo "Invalid type: $type" >&2
            return 1
            ;;
    esac
    if [[ -n "$value" ]]; then
        value=$(echo "$value * 1024 * 1024 / (1024 * 1024)" | bc)
        printf "%.2fMB" "$value"
    else
      echo "N/A"
    fi
}

# 转义 MarkdownV2 特殊字符函数
escape_markdown() {
  local text="$1"
  text=$(echo "$text" | sed 's/\\/\\\\/g') # 转义反斜杠
  text=$(echo "$text" | sed 's/[]_{}`~>#+=|.!(){}\/]/\\&/g') # 转义其他特殊字符
  echo "$text"
}

# 构建 Telegram 消息 (使用 MarkdownV2)
message="*服务器名称:* $(escape_markdown "$server_name")%0A"
message+="*IP 地址:* $(escape_markdown "$ip_address")%0A"
message+="*CPU 使用率:* $(escape_markdown "${cpu_usage}%")%0A"
message+="*内存使用率:* $(escape_markdown "${mem_usage}")%0A"
message+="*磁盘使用率:* $(escape_markdown "${disk_usage}%")%0A"
message+="*今日总流量:* $(escape_markdown "$(get_vnstat_info daily)")%0A"
message+="*本月总流量:* $(escape_markdown "$(get_vnstat_info monthly)")%0A"
message+="*总流量:* $(escape_markdown "$(get_vnstat_info total)")"

# 转义 `-` 字符
message=$(echo "$message" | sed 's/-/\\-/g')

# 发送 Telegram 消息 (使用 MarkdownV2)
response=$(curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=${message}" \
    -d "parse_mode=MarkdownV2")

# 检查 Telegram API 返回结果
if echo "$response" | grep -q '"ok":true'; then
    echo "Telegram 消息发送成功!"
else
    echo "Telegram 消息发送失败!"
    echo "错误信息: $response"
fi
EOF
)

    # 替换 TOKEN 和 CHAT_ID 变量
    script_content=$(printf "%s" "$script_content" | sed "s/TOKEN=\"\"/TOKEN=\"$TOKEN\"/g")
    script_content=$(printf "%s" "$script_content" | sed "s/CHAT_ID=\"\"/CHAT_ID=\"$CHAT_ID\"/g")

    # 写入脚本文件
    printf "%s" "$script_content" > "$script_path"
    chmod +x "$script_path"
    if [[ $? -eq 0 ]]; then
        info "脚本部署成功！"
    else
        error "脚本部署失败！"
        exit 1
    fi
}

# 函数：配置 crontab
configure_crontab() {
    local script_path="$1"
    info "正在配置 crontab..."

    # 检查 crontab 是否已经存在
    if crontab -l 2>/dev/null | grep -q "$script_path"; then
        warn "crontab 中已存在该任务，跳过配置。"
        return
    fi

    # 添加新的 crontab 任务
    (crontab -l 2>/dev/null; echo "0 8 * * * $script_path >> /var/log/vnstat_telegram.log 2>&1") | crontab -
    if [[ $? -eq 0 ]]; then
        info "crontab 配置成功！"
    else
        error "crontab 配置失败！"
        exit 1
    fi
}

# 函数：创建日志文件
create_log_file() {
    info "正在创建日志文件..."
    touch /var/log/vnstat_telegram.log
    if [[ $? -eq 0 ]]; then
        info "日志文件创建成功！"
    else
        error "日志文件创建失败！"
        exit 1
    fi
}

# 函数：检查网络连接
check_network_connection() {
    info "正在检查网络连接..."
    if ping -c 1 google.com &> /dev/null; then
        info "网络连接正常。"
    else
        error "网络连接失败！请检查网络设置。"
        exit 1
    fi
}

# 主程序
info "欢迎使用 vnstat_telegram 安装脚本！"

# 检测是否为交互式终端
if [[ -t 0 ]]; then
  # 是交互式终端，直接执行
  info "脚本正在执行..."

  # 1. 检查用户权限
  if [ "$(id -u)" -ne 0 ]; then
    error "请以 root 用户或使用 sudo 运行此脚本。"
    exit 1
  fi

  # 2. 检查网络连接
  check_network_connection

  # 3. 验证 Telegram Bot Token 和 Chat ID
  verify_telegram_credentials

  # 4. 获取安装路径
  install_path=$(get_install_path)

  # 5. 安装依赖
  install_dependency vnstat
  install_dependency bc
  install_dependency curl

  # 6. 部署脚本
  script_path="$install_path/vnstat_telegram.sh"
  deploy_script "$script_path"

  # 7. 配置 crontab
  configure_crontab "$script_path"

  # 8. 创建日志文件
  create_log_file

  info "安装完成！"
  info "脚本已安装到 $script_path"
  info "日志文件已创建在 /var/log/vnstat_telegram.log"
  info "脚本将在每天早上 8 点运行。"
else
  # 不是交互式终端，提示用户下载并执行
  error "检测到非交互式执行 (例如管道执行)。"
  error "请使用以下命令下载脚本并手动执行："
  echo
  echo "  curl -sSL https://raw.githubusercontent.com/mcj13/vnstat-telegram-installer/main/install.sh -o install.sh"
  echo "  bash install.sh"
  echo
  exit 1
fi
