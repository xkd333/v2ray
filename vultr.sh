#!/bin/bash

# 确保脚本遇到错误时继续执行，避免因为部分组件已存在而中断
set +e

echo "=========================================="
echo "1. 开始执行 V2Ray 安装脚本"
echo "=========================================="
# 提示：如果该安装脚本有交互菜单，请在此处按提示完成安装
bash <(wget -qO- -o- https://ebj.cc/vultr/v2ray.sh)

echo "=========================================="
echo "2. 开始创建 VMess-TCP-test.json 配置文件"
echo "=========================================="
# 确保配置文件夹存在
mkdir -p /etc/v2ray/conf

# 使用 EOF 写入多行 JSON 内容
cat > /etc/v2ray/conf/VMess-TCP-test.json << 'EOF'
{
  "inbounds": [
    {
      "tag": "VMess-TCP-test.json",
      "port": 43331,
      "listen": "0.0.0.0",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "45da5dde-3752-4577-967f-637aff73ef8c"
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "tcpSettings": {
          "header": {
            "type": "none"
          }
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ]
}
EOF
echo "配置文件已成功写入到 /etc/v2ray/conf/VMess-TCP-test.json"

echo "=========================================="
echo "3. 开始执行 BBR 脚本"
echo "=========================================="
if [ -f "/etc/v2ray/sh/src/bbr.sh" ]; then
    bash /etc/v2ray/sh/src/bbr.sh
else
    echo "警告：未找到 /etc/v2ray/sh/src/bbr.sh 文件。如果 BBR 已开启或脚本路径不同，请忽略此警告。"
fi

echo "=========================================="
echo "4. 开始关闭系统防火墙"
echo "=========================================="
# 尝试关闭 ufw (Debian/Ubuntu 常用)
if command -v ufw >/dev/null 2>&1; then
    echo "检测到 ufw，正在关闭..."
    ufw disable
fi

# 尝试关闭 firewalld (CentOS/RedHat 常用)
if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet firewalld; then
        echo "检测到 firewalld，正在关闭并禁用..."
        systemctl stop firewalld
        systemctl disable firewalld
    fi
fi

# 清理 iptables 规则 (可选保险措施，全部放行)
if command -v iptables >/dev/null 2>&1; then
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -F
    echo "iptables 规则已清空并设置为全局放行。"
fi
echo "系统内部防火墙已关闭。"

echo "=========================================="
echo "5. 重启 V2Ray 服务"
echo "=========================================="
v2ray restart

echo "=========================================="
echo "所有任务已执行完成！"
echo "=========================================="