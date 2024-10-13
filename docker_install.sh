#!/bin/bash

echo "检测安装环境"
apt-get install expect wget -y > /dev/null
wget -O vps.sh --no-check-certificate "https://raw.githubusercontent.com/xinling123/vps-sh/master/vps.sh" && chmod +x vps.sh

# 使用 expect 运行交互式脚本
expect <<EOF
    # 启动交互式脚本
    spawn ./vps.sh

    # 自动输入1
    expect "请输入选择的数字："   # 匹配提示信息
    send "1\r"                   # 发送1并回车

    # 检查docker是否已安装
    expect {
        "docker已经安装" {
            send_user "\nDocker 已经安装，结束脚本。\n"  # 输出提示
            exit 0                                       # 退出 expect
        }
        "请输入选择的数字：" {
            send_user "\n再次提示输入选择，继续运行或执行其他操作。\n"
            # 根据需要可以继续输入或处理其他逻辑
            # 例如可以输入其他选项或退出
            send "0\r"   # 假设发送0作为下一个操作
        }
        timeout {
            send_user "\n操作超时，脚本结束。\n"
            exit 1  # 超时后退出
        }
    }

    # 等待脚本运行结束
    expect eof
EOF
