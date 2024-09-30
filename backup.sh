#!/bin/bash

# Telegram Bot API相关信息
API_TOKEN="5556876362:AAGaZ3imyYi8A01HAwgM5VeyfzJva7cvJ48"
CHAT_ID="1287013549"

# 备份文件路径
BACKUP_DIR="/home/docker/backup/"

# 跳过备份的容器映射文件
EXCLUDE_CONTAINERS=("qbittorrent" "emby" "dashboard-dashboard-1")
# 跳过备份的容器
EXCLUDE_CONTAINERS1=("ifile" "mysql_ifile" "crawlab_master" "crawlab_mongo_1" "nastools" "h5ai" "ifile" "mysql_ifile")

time=$(date "+%Y-%m-%d")

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份所有容器
for container_id in $(docker ps -aq); do
    # 获取容器名称和镜像名称
    container_name=$(docker inspect --format='{{.Name}}' $container_id | sed 's/\///g')
    image_name=$(docker inspect --format='{{.Config.Image}}' $container_id)

    echo $(date "+%Y-%m-%d %H:%M:%S"): "备份容器: $container_name" >> /home/docker/backup.log

    # 检查是否为需要排除的容器
    if [[ " ${EXCLUDE_CONTAINERS1[@]} " =~ " ${container_name} " ]]; then
        echo $(date "+%Y-%m-%d %H:%M:%S"): "跳过容器备份: $container_name" >> /home/docker/backup.log
        continue
    fi

    # 备份容器数据
    docker export -o $BACKUP_DIR/${container_name}_backup.tar $container_id

    # 备份容器的配置信息和元数据
    docker inspect $container_id > $BACKUP_DIR/${container_name}_metadata.json

    # 备份映射的端口
    port_bindings=$(docker port $container_id)
    echo $port_bindings > $BACKUP_DIR/${container_name}_port_bindings.txt
    
    # 检查是否为需要排除的容器
    if [[ " ${EXCLUDE_CONTAINERS[@]} " =~ " ${container_name} " ]]; then
        echo $(date "+%Y-%m-%d %H:%M:%S"): "跳过容器映射文件备份: $container_name" >> /home/docker/backup.log
        continue
    fi

    # 备份映射的文件
    docker inspect --format='{{ range .Mounts }}{{ .Source }}{{ printf "\n" }}{{ end }}' $container_id | while read -r source; do
        if [ ! -z "$source" ] && [ -d "$source" ]; then
            # 获取目录名
            dir_name=$(basename "$source")
            mkdir -p $BACKUP_DIR/${container_name}_mounted_files/$dir_name
            cp -R $source $BACKUP_DIR/${container_name}_mounted_files/$dir_name
        fi
    done

done
echo $(date "+%Y-%m-%d %H:%M:%S"): "备份完成！" >> /home/docker/backup.log
cd $BACKUP_DIR

echo $(date "+%Y-%m-%d %H:%M:%S"): echo "正在打包所有文件..." >> /home/docker/backup.log
tar --use-compress-program=pigz -cvpf $1.tar.gz $BACKUP_DIR >/dev/null 2>&1
echo $(date "+%Y-%m-%d %H:%M:%S"): echo "打包完成！" >> /home/docker/backup.log
echo $(date "+%Y-%m-%d %H:%M:%S"): echo "开始同步文件到OneDrive！" >> /home/docker/backup.log
OneDriveUploader -c /home/auth.json -t 50 -s $BACKUP_DIR -r "backup/$1/$time" >/dev/null 2>&1
# 要发送的消息
MESSAGE="$(date "+%Y-%m-%d %H:%M:%S"): $1 同步完成！"
echo $MESSAGE >> /home/docker/backup.log
rm -rf $BACKUP_DIR
echo $(date "+%Y-%m-%d %H:%M:%S"): echo "删除本地备份文件！" >> /home/docker/backup.log

# 使用curl命令向Telegram Bot API发送请求
curl -s -X POST "https://api.telegram.org/bot$API_TOKEN/sendMessage" \
     -d "chat_id=$CHAT_ID" \
     -d "text=$MESSAGE" >> /home/docker/backup.log
echo "" >> /home/docker/backup.log
