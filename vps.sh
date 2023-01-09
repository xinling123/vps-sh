#!/bin/bash

arr_info=()
docker_container1=/home/dokcer/

red() {
	echo -e "\033[31m\033[01m$1\033[0m"
}

green() {
	echo -e "\033[32m\033[01m$1\033[0m"
}

yellow() {
	echo -e "\033[33m\033[01m$1\033[0m"
}


# docker 安装
docker_install(){
    docker -v
    if [ $? -eq 0 ]; then
        green "docker已经安装"
    else
        yellow "开始安装docker"
        curl -sSL https://get.daocloud.io/docker | sh
        systemctl enable docker
        apt install docker-compose -y
        curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-`uname -s`-`uname -m` -o /usr/bin/docker-compose
        chmod +x /usr/bin/docker-compose
        docker --version
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
    3) arr_info[3]="emby  $myip:8096\n"; docker_emby ;;
    4) arr_info[4]="Halo  $myip:8090\n"; docker_Halo ;;
    5) arr_info[5]="NAS-TOOL  $myip:3000 User:admin Password:password\n"; docker_NAS_TOOL ;;
    6) arr_info[6]="qbittorrent  $myip:8080\n"; docker_qbittorrent ;;
    7) arr_info[7]="Uptime Kuma  $myip:3001\n"; docker_Uptime_Kuma ;;
    *) red "输入错误";;
    esac
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
    if [ -d "vps-sh/emby/" ]; then
        cp -r vps-sh/emby $docker_container1
        cd $docker_container1/emby
        docker-compose up -d
        if [ $? -eq 0 ]; then
            green "emby 安装成功"
        else
            red "emby 失败"
        fi
    else
        red "emby docker-compose文件不存在"
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
    read -p "请输入docker容器安装路径[默认/home/dokcer/]:" docker_container_path
    [[ -z "${docker_container_path}" ]] && docker_container_path=/home/dokcer/
    if [ -d "$docker_container_path" ]; then
        yellow "$docker_container_path is a directory"
    fi
    docker_container1=$docker_container_path
    mkdir $docker_container_path
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

        read -p "请输入选择的数字：" -a  number

        for i in ${number[@]};
        do
            docker_index $i ;
        done
        echo -e ${arr_info[@]}
    done
}


backup_docker_date(){
    rclone -v
    if [ $? -eq 0 ]; then
        green "rclone已经安装"
    else
        yellow "开始安装rclone"
        curl https://rclone.org/install.sh | sudo bash
        rclone config
        green "rclone安装完成"
    fi
    read -p "是否挂载onedrive[默认y]：" y
    [[ -z "${y}" ]] && y="y"
    if [ $y == "y" ]; then
        apt install fuse zip
        cd /
        mkdir onedrive
        chmod 777 onedrive/
        read -p "请输入onedrive的名字：" name
        rclone mount $name:/ /onedrive --copy-links --allow-other --allow-non-empty --umask 000 --daemon
    fi
    read -p "是否开始自动备份[默认y]：" y
    [[ -z "${y}" ]] && y="y"
    if [ $y == "y" ]; then
        if [ -d "$docker_container1" ]; then
            yellow "将备份 $docker_container1 文件夹下的docker数据"
            cd /home
            mkdir backup
            chmod 777 backup
            git clone https://github.com/xinling123/vps-sh.git
            cp ./vps-sh/backup.sh ./backup/
            # echo '0 4 */3 * * root /home/' >> /etc/crontab
            echo '* * * * * root /home/backup/backup.sh > /home/backup/backup.log' >> /etc/crontab
        else
            red "未检测到 $docker_container1 文件夹"
        fi
    fi
}


# 系统初始化
system_init(){
    apt update -y && apt install wget curl git -y
    read -p "是否挂载硬盘[默认y]：" y
    [[ -z "${y}" ]] && y="y"
    if [ $y == "y" ]; then
        fdisk /dev/sda
        mkfs.ext4 /dev/sda1
        mkdir /data1
        chmod 777 /data1
        mount /dev/sda1 /data1
        echo '/dev/sda1 /data1 ext4 defaults  0  0' >> /etc/fstab
    fi
    read -p "是否增加虚拟内存[默认y]：" y
    [[ -z "${y}" ]] && y="y"
    if [ $y == "y" ]; then
        wget https://www.moerats.com/usr/shell/swap.sh && bash swap.sh
    fi
    read -p "是否启动bbr加速[默认y]：" y
    [[ -z "${y}" ]] && y="y"
    if [ $y == "y" ]; then
        wget -N --no-check-certificate "https://github.000060000.xyz/tcpx.sh" && chmod +x tcpx.sh && ./tcpx.sh
    fi
    read -p "是否重启[默认y]：" y
    [[ -z "${y}" ]] && y="y"
    if [ $y == "y" ]; then
        reboot
    fi
}

# 初始化界面
start(){
    while true
    do 
        yellow "\r\n"
        yellow "0.安装系统更新包"
        yellow "1.安装docker"
        yellow "2.安装docker容器"
        yellow "3.备份docker数据到onedrive"

        read -p "请输入选择的数字：" number
        # [[ -z "${PORT}" ]] && PORT=443
        case $number in 
            0) system_init ;;
            1) docker_install ;;
            2) docker_container ;;
            3) backup_docker_date ;;
            *) red "输入错误";;
            esac
    done
}

[[ $EUID -ne 0 ]] && red "请在root用户下运行脚本" && exit 1
myip=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo $myip
start

