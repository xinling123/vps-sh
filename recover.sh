#!/bin/bash

# 备份文件路径
BACKUP_DIR="/home/docker"
# 恢复备份文件的目标路径
RESTORE_DIR="/home/back"
# 获取备份文件中的容器列表
container_files=$(ls $RESTORE_DIR | grep "_backup.tar")

# 恢复容器数据和配置信息
for file in $container_files; do
    # 提取容器名称
    container_name=$(echo $file | awk -F '_backup.tar' '{print $1}')

    file_path="$RESTORE_DIR/${container_name}_metadata.json"  # 替换成实际的文件路径

    # 使用正则表达式提取Image后面的文本内容
    image_name=$(grep -oP '(?<="Image": ")[^"]*' "$file_path" | awk 'NR==2')

    if [ -n "$image_name" ]; then
        echo "提取的文本内容：$image_name"
    else
        echo "未找到匹配的文本内容。"
    fi

    container_id=$(docker create $image_name)

    echo "恢复容器: $container_name"

    echo "恢复容器: $image_name"
    # 导入容器数据
    docker import $RESTORE_DIR/$file $container_id

    # 导入容器的配置信息和元数据
    docker create --name temp $image_name >/dev/null 2>&1
    docker cp $RESTORE_DIR/${container_name}_metadata.json temp:/metadata.json
    docker rm -fv temp >/dev/null 2>&1

    # 重命名容器
    docker rename $container_id $container_name
done


# 恢复映射的文件
for file in $container_files; do
    # 提取容器名称
    container_name=$(echo $file | awk -F '_backup.tar' '{print $1}')
    echo "恢复映射的文件容器: $container_name"
    # 检查是否存在映射的文件夹
    if [ -d "$RESTORE_DIR/${container_name}_mounted_files" ]; then
        echo "找到映射文件夹"
        # 获取容器ID
        container_id=$(docker ps -aqf "name=$container_name")

        # 恢复映射的文件
        cp -R $RESTORE_DIR/${container_name}_mounted_files $BACKUP_DIR

        # 修改容器的挂载点
        docker inspect $container_id | jq '.[].Mounts[].Source' | while read -r source; do
            if [ ! -z "$source" ] && [ -d "$source" ]; then
                echo "恢复映射的文件: $source"
                cp -R $BACKUP_DIR/${container_name}_mounted_files/$source $source
            fi
        done
    fi
done


# 恢复映射的端口
for file in $container_files; do
    # 提取容器名称
    container_name=$(echo $file | awk -F '_backup.tar' '{print $1}')
    echo "恢复映射的端口容器: $container_name"

    file_path="$RESTORE_DIR/${container_name}_metadata.json"  # 替换成实际的文件路径

    # 使用正则表达式提取Image后面的文本内容
    image_name=$(grep -oP '(?<="Image": ")[^"]*' "$file_path" | awk 'NR==2')

    # 检查是否存在映射的端口文件
    if [ -f "$RESTORE_DIR/${container_name}_port_bindings.txt" ]; then
        echo "找到映射端口文件"
        # 获取容器ID
        container_id=$(docker ps -aqf "name=$container_name")
        # 读取端口映射信息
        port_bindings=$(cat "$RESTORE_DIR/${container_name}_port_bindings.txt")

        docker_command=''
        docker_command1=''

        IFS=' -> ' read -ra items <<< "$port_bindings"

        unique_ports=()

        for item in "${items[@]}"; do
            if [[ ! $item =~ \[::\] ]] && [[ ! -z $item ]] && ! [[ " ${unique_ports[*]} " =~ " $item " ]]; then
                unique_ports+=("$item")
            fi
        done

        for port in "${unique_ports[@]}"; do
            if [[ $port =~ / ]]; then
                IFS="/" read -ra part1 <<< "$port"
                    echo "${part1[0]}"
                    docker_command1="${part1[0]} " 
            elif [[ $port =~ : ]]; then 
                IFS=":" read -ra part2 <<< "$port"
                    echo "${part2[1]}"
                    docker_command+="-p ${part2[1]}:$docker_command1" 
            fi
        done

        echo "$docker_command"

        # 恢复端口映射
        docker container stop "$container_id"
        docker container rm "$container_id"
        docker run -d $docker_command --name "$container_name" "$image_name"

    fi
done

echo "恢复完成！"
