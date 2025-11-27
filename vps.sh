#!/bin/bash

# 保存输出所有的安装的应用
arr_info=()
# docker的安装目录
docker_container1=/home/docker/
# OneDrive的备份名字
onedrive_name=9929
# 显示红色的输出
red() {
	echo -e "\033[31m\033[01m$1\033[0m"
}

# 显示绿色的输出
green() {
	echo -e "\033[32m\033[01m$1\033[0m"
}


# 显示黄色的输出
yellow() {
	echo -e "\033[33m\033[01m$1\033[0m"
}


# docker 安装
docker_install(){
    # 判断docker是否已经安装
    if type docker >/dev/null 2>&1; then
        green "docker已经安装"
    else  # 开始安装docker
        yellow "开始安装docker"
        apt update
        apt install -y docker-compose
        curl -fsSL https://get.docker.com | bash
        systemctl enable docker


        read -p "是否修改docker api最小要求版本[默认y]：" y
        [[ -z "${y}" ]] && y="y"
        if [ $y == "y" ]; then
            mkdir -p /etc/docker
            echo '{"min-api-version": "1.24"}' > /etc/docker/daemon.json
            systemctl daemon-reload && systemctl restart docker
            green "修改docker api版本成功"
        fi
        docker version
        docker-compose --version
        green "docker安装完成"
    fi
}


# docker容器选择
docker_index(){
    case $1 in 
    0) count=1 ;;
    1) arr_info[1]="Nginx Proxy Manager  $myip:81 Email:admin@example.com Password: changeme\n"; docker_Nginx_Proxy_Manager ;;
    2) arr_info[2]="Easyimage  $myip:8180\n"; docker_Easyimage ;;
    3) arr_info[3]="Emby  $myip:8096\n"; docker_emby ;;
    4) arr_info[4]="Halo  $myip:8090\n"; docker_Halo ;;
    5) arr_info[5]="NAS-TOOL  $myip:3000 User:admin Password:password\n"; docker_NAS_TOOL ;;
    6) arr_info[6]="qbittorrent  $myip:8080\n"; docker_qbittorrent ;;
    7) arr_info[7]="Uptime Kuma  $myip:3001\n"; docker_Uptime_Kuma ;;
    8) arr_info[8]="3x-ui  $myip:2053\n"; docker_3x-ui ;;
    *) red "输入错误";;
    esac
}


# 安装3x-ui面板
docker_3x-ui(){
    if [ -d "vps-sh/3x-ui/" ]; then
        cp -r vps-sh/3x-ui $docker_container1
        cd $docker_container1/3x-ui
        docker-compose up -d
        if [ $? -eq 0 ]; then
            green "3x-ui 安装成功"
        else
            red "3x-ui 失败"
        fi
    else
        red "3x-ui docker-compose文件不存在"
    fi
    cd ../..
}


# 安装Uptime Kuma
docker_Uptime_Kuma(){
    if [ -d "vps-sh/Uptime_Kuma/" ]; then
        cp -r vps-sh/Uptime_Kuma $docker_container1
        cd $docker_container1/Uptime_Kuma
        docker-compose up -d
        if [ $? -eq 0 ]; then
            green "Uptime_Kuma 安装成功"
        else
            red "Uptime_Kuma 失败"
        fi
    else
        red "Uptime_Kuma docker-compose文件不存在"
    fi
    cd ../..
}


# 安装qbittorrent
docker_qbittorrent(){
    if [ -d "vps-sh/qbittorrent/" ]; then
        cp -r vps-sh/qbittorrent $docker_container1
        cd $docker_container1/qbittorrent
        docker-compose up -d
        if [ $? -eq 0 ]; then
            green "qbittorrent 安装成功"
        else
            red "qbittorrent 失败"
        fi
    else
        red "qbittorrent docker-compose文件不存在"
    fi
    cd ../..
}


# 安装NAS-TOOL
docker_NAS_TOOL(){
    if [ -d "vps-sh/NAS_Tool/" ]; then
        cp -r vps-sh/NAS_Tool $docker_container1
        cd $docker_container1/NAS_Tool
        docker-compose up -d
        if [ $? -eq 0 ]; then
            green "NAS-TOOL 安装成功"
        else
            red "NAS-TOOL 失败"
        fi
    else
        red "NAS-TOOL docker-compose文件不存在"
    fi
    cd ../..
}


# 安装Halo
docker_Halo(){
    if [ -d "vps-sh/Halo/" ]; then
        cp -r vps-sh/Halo $docker_container1
        cd $docker_container1/Halo
        docker-compose up -d
        if [ $? -eq 0 ]; then
            green "Halo 安装成功"
        else
            red "Halo 失败"
        fi
    else
        red "Halo docker-compose文件不存在"
    fi
    cd ../..
}


# 安装emby
docker_emby(){
    if [ -d "vps-sh/Emby/" ]; then
        cp -r vps-sh/Emby $docker_container1
        cd $docker_container1/Emby
        docker-compose up -d
        if [ $? -eq 0 ]; then
            green "Emby 安装成功"
        else
            red "Emby 失败"
        fi
    else
        red "Emby docker-compose文件不存在"
    fi
    cd ../..
}


# 安装Easyimage
docker_Easyimage(){
    if [ -d "vps-sh/Easyimage/" ]; then
        cp -r vps-sh/Easyimage $docker_container1
        cd $docker_container1/Easyimage
        docker-compose up -d
        if [ $? -eq 0 ]; then
            green "Easyimage 安装成功"
        else
            red "Easyimage 失败"
        fi
    else
        red "Easyimage docker-compose文件不存在"
    fi
    cd ../..
}


# 安装Nginx_Proxy_Manager
docker_Nginx_Proxy_Manager(){
    if [ -d "vps-sh/Nginx_Proxy_Manager/" ]; then
        cp -r vps-sh/Nginx_Proxy_Manager $docker_container1
        cd $docker_container1/Nginx_Proxy_Manager
        docker-compose up -d
        if [ $? -eq 0 ]; then
            green "Nginx Proxy Manager 安装成功"
        else
            red "Nginx Proxy Manager 失败"
        fi
    else
        red "Nginx Proxy Manager docker-compose文件不存在"
    fi
    cd ../..
}

# 选择安装docker容器
docker_container(){
    read -p "请输入docker容器安装路径[默认/home/docker/]:" docker_container_path
    [[ -z "${docker_container_path}" ]] && docker_container_path=$docker_container1
    if [ -d "$docker_container_path" ]; then
        yellow "$docker_container_path is a directory"
    fi
    docker_container1=$docker_container_path
    mkdir -p $docker_container_path
    cd $docker_container_path
    cd ..
    git clone https://github.com/xinling123/vps-sh.git
    # cp -r vps-sh/. $docker_container_path
    # rm -rf vps-sh/

    count=0
    while [ $count -eq 0 ]
    do
        yellow "\r\n"
        yellow "0.退出"
        yellow "1.安装Nginx Proxy Manager"
        yellow "2.安装Easyimage"
        yellow "3.安装emby"
        yellow "4.安装Halo"
        yellow "5.安装NAS-TOOL"
        yellow "6.安装qbittorrent4.3.8"
        yellow "7.安装Uptime Kuma"
        yellow "8.安装3x-ui面板"

        read -p "请输入选择的数字：" -a  number

        for i in ${number[@]};
        do
            docker_index $i ;
        done
        echo -e ${arr_info[@]}
        cd ${docker_container_path}
        cd ..
        # rm -rf vps-sh/
    done
}


backup_docker_date(){
    if type rclone >/dev/null 2>&1; then
        green "rclone已经安装"
    else
        yellow "开始安装rclone"
        apt install zip -y
        curl https://rclone.org/install.sh | bash
        rclone config
        green "rclone安装完成"
    fi
    # wget https://raw.githubusercontent.com/MoeClub/OneList/master/OneDriveUploader/amd64/linux/OneDriveUploader -P /usr/local/bin/
    # chmod +x /usr/local/bin/OneDriveUploader
    # if command -v pigz &> /dev/null; then
    # echo "pigz 已安装"
    # else
    #     echo "pigz 未安装"
    # fi

    read -p "是否挂载onedrive[默认y]：" y
    [[ -z "${y}" ]] && y="y"
    if [ $y == "y" ]; then
        apt install fuse3 -y
        cd /
        mkdir onedrive
        chmod 777 onedrive/
        read -p "请输入onedrive挂载的名字：" name
        $onedrive_name = $name
        rclone mount od:/${name} /onedrive --copy-links --allow-other --allow-non-empty --umask 000 --daemon
        green "onedrive挂载成功"
    fi

    read -p "是否安装自动备份工具[默认y]：" y
    [[ -z "${y}" ]] && y="y"
    if [ $y == "y" ]; then
        yellow "开始安装自动备份工具"
        curl -fsSL https://raw.githubusercontent.com/shuguangnet/docker_backup_script/main/install.sh | bash
        green "自动备份工具安装完成"
    fi

    read -p "是否开始自动备份[默认y]：" y
    [[ -z "${y}" ]] && y="y"
    if [ $y == "y" ]; then
        systemctl start docker-backup.timer

        echo "0 3 * * 5 docker-backup -a -c /opt/docker-backup/backup.conf.local -o /onedrive >/dev/null 2>&1
# 每周四凌晨3点清理旧备份
0 3 * * 5 docker-backup find /onedrive -type d -mtime +60 -exec rm -rf {} \; >/dev/null 2>&1
" >> /etc/crontab
    fi
}



# 系统初始化
system_init(){
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    apt update -y && apt install wget curl git vnstat -y

    # read -p "是否挂载硬盘[默认n]：" y
    # [[ -z "${y}" ]] && y="n"
    # if [ $y == "y" ]; then
    #     fdisk /dev/sda
    #     mkfs.ext4 /dev/sda1
    #     mkdir /data1
    #     chmod 777 /data1
    #     mount /dev/sda1 /data1
    #     echo '/dev/sda1 /data1 ext4 defaults  0  0' >> /etc/fstab
    # fi
}


swap_init(){
    wget https://www.moerats.com/usr/shell/swap.sh && bash swap.sh
}

dd_init(){
    
    read -p "debian系统版本（11/12）：" debian_version
    read -p "ssh端口号：" ssh_port
    read -p "root密码：" root_pwd

    wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh && bash InstallNET.sh -debian $debian_version --bbr -port  $ssh_port -pwd $root_pwd
    yellow "dd系统预计需要5-10分钟，请耐心等待"
    sleep 10
    reboot
}

tcp_init(){
    wget -O tcpx.sh "https://github.com/ylx2016/Linux-NetSpeed/raw/master/tcpx.sh" && chmod +x tcpx.sh && ./tcpx.sh
}


# 初始化界面
start(){
    while true
    do 
        yellow "\r\n"
        yellow "0.一键dd脚本"
        yellow "1.安装系统更新包"
        yellow "2.增加虚拟内存"
        yellow "3.tcp网络调优（建议11和22）"
        yellow "4.安装docker"
        yellow "5.安装docker容器"
        yellow "6.安装备份工具"


        read -p "请输入选择的数字：" number
        for i in ${number[@]};
        do
            case $i in 
            0) dd_init ;;
            1) system_init ;;
            2) swap_init ;;
            3) tcp_init ;;
            4) docker_install ;;
            5) docker_container ;;
            6) backup_docker_date ;;
            *) red "输入错误";;
            esac
        done
    done
}


[[ $EUID -ne 0 ]] && red "请在root用户下运行脚本" && exit 1 
myip=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo $myip
start



