#!/bin/bash

# 备份文件路径
BACKUP_DIR="/home/backup"

# EXCLUDE_CONTAINERS=("container1" "container2")
EXCLUDE_CONTAINERS=("qbittorrent" "emby" "dashboard-dashboard-1")

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份所有容器
for container_id in $(docker ps -aq); do
    # 获取容器名称和镜像名称
    container_name=$(docker inspect --format='{{.Name}}' $container_id | sed 's/\///g')
    image_name=$(docker inspect --format='{{.Config.Image}}' $container_id)

    echo "备份容器: $container_name"

    # 备份容器数据
    docker export -o $BACKUP_DIR/${container_name}_backup.tar $container_id

    # 备份容器的配置信息和元数据
    docker inspect $container_id > $BACKUP_DIR/${container_name}_metadata.json

    # 检查是否为需要排除的容器
    if [[ " ${EXCLUDE_CONTAINERS[@]} " =~ " ${container_name} " ]]; then
        echo "跳过容器映射文件备份: $container_name"
        continue
    fi

    # 备份映射的文件
    docker inspect --format='{{ range .Mounts }}{{ .Source }}{{ printf "\n" }}{{ end }}' $container_id | while read -r source; do
        if [ ! -z "$source" ] && [ -d "$source" ]; then
            cp -R $source $BACKUP_DIR/${container_name}_mounted_files
        fi
    done

done
echo "备份完成！"

cd $BACKUP_DIR

echo "正在打包所有文件..."
tar --use-compress-program=pigz -cvpf $1.tar.gz $BACKUP_DIR >/dev/null 2>&1
echo "打包完成！"

