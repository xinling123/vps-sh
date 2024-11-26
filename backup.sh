#!/bin/bash

# 获取外部传入的参数（REMOTE_PATH 的目标路径部分）
if [ -z "$1" ]; then
  echo "请提供 rclone 目标路径的文件夹名！"
  exit 1
fi

# 设置文件路径和目标 rclone 远程路径
FILE_PATH="/home/docker_banckup.tar.gz"        # 要上传的文件路径
REMOTE_PATH="remote:$1"           # rclone 远程目标路径，通过外部参数传入
LOG_FILE="/home/backups.log"   # 日志文件路径

# 获取当前日期
CURRENT_DATE=$(date +%Y-%m-%d)

# 生成一个随机的小时和分钟（0 到 23 小时，0 到 59 分钟）
HOUR=$(shuf -i 0-23 -n 1)
MINUTE=$(shuf -i 0-59 -n 1)

# 计算当前时间和目标时间的秒数
CURRENT_HOUR=$(date +%H)
CURRENT_MINUTE=$(date +%M)
TARGET_TIME=$(($HOUR * 3600 + $MINUTE * 60))  # 随机时间的秒数
CURRENT_TIME=$(($CURRENT_HOUR * 3600 + $CURRENT_MINUTE * 60))  # 当前时间的秒数

# 计算需要等待的时间（秒）
if [ $TARGET_TIME -gt $CURRENT_TIME ]; then
    SLEEP_TIME=$(($TARGET_TIME - $CURRENT_TIME))
else
    SLEEP_TIME=$(($TARGET_TIME - $CURRENT_TIME + 86400))  # 如果目标时间已过去，加上 24 小时（86400 秒）
fi

# 日志记录开始时间
echo "$(date +'%Y-%m-%d %H:%M:%S') - 开始等待随机时间，备份将在 $SLEEP_TIME 秒后开始" >> "$LOG_FILE"

# 等待随机时间
sleep $SLEEP_TIME

# 日志记录备份开始
echo "$(date +'%Y-%m-%d %H:%M:%S') - 开始备份数据 '$FILE_PATH' at $HOUR:$MINUTE" >> "$LOG_FILE"

# 删除之前的备份文件（如果存在）
rm -rf $FILE_PATH

# 创建备份文件
tar -czf $FILE_PATH /home/docker/
echo "$(date +'%Y-%m-%d %H:%M:%S') - 备份数据打包完成 '$FILE_PATH' at $HOUR:$MINUTE" >> "$LOG_FILE"

# 删除 14 天之前的文件
echo "$(date +'%Y-%m-%d %H:%M:%S') - 删除 14 天前的备份文件 " >> "$LOG_FILE"
rclone delete "$REMOTE_PATH" --min-age 14d >> "$LOG_FILE" 2>&1

# 执行 rclone 上传操作并捕获其退出状态
echo "$(date +'%Y-%m-%d %H:%M:%S') - 上传备份文件 '$FILE_PATH' to '$REMOTE_PATH/$CURRENT_DATE-$(basename "$FILE_PATH")'." >> "$LOG_FILE"
rclone copy "$FILE_PATH" "$REMOTE_PATH/$CURRENT_DATE-$(basename "$FILE_PATH")"
RCLONE_EXIT_STATUS=$?

# 检查 rclone 命令的退出状态，记录成功或失败
if [ $RCLONE_EXIT_STATUS -eq 0 ]; then
  echo "$(date +'%Y-%m-%d %H:%M:%S') - '$FILE_PATH' 备份成功 " >> "$LOG_FILE"
else
  echo "$(date +'%Y-%m-%d %H:%M:%S') - '$FILE_PATH' 备份失败 $RCLONE_EXIT_STATUS." >> "$LOG_FILE"
fi

# 日志记录结束时间
echo "$(date +'%Y-%m-%d %H:%M:%S') - 备份完成 " >> "$LOG_FILE"
