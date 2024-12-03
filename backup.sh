#!/bin/bash


# Telegram Bot API相关信息
API_TOKEN="5556876362:AAGaZ3imyYi8A01HAwgM5VeyfzJva7cvJ48"
CHAT_ID="1287013549"

# 设置文件路径和目标 rclone 远程路径
FILE_PATH="/home/backup/docker_banckup.tar.gz"        # 要上传的文件路径
LOG_FILE="/home/backup/backups.log"   # 日志文件路径


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

# 判断是否有传入排除参数 ($2)
if [ -n "$2" ]; then
  # 如果有第二个参数，使用 --exclude 排除指定文件或目录
  tar -czf $FILE_PATH /home/docker/ --exclude="$2"
else
  # 没有第二个参数时，正常备份
  tar -czf $FILE_PATH /home/docker/
fi

echo "$(date +'%Y-%m-%d %H:%M:%S') - 备份数据打包完成 '$FILE_PATH' at $HOUR:$MINUTE" >> "$LOG_FILE"

# 删除14天前的文件
find /od -type f -name "*.tar.gz" -mtime +14 -exec rm -f {} \;
echo "$(date +'%Y-%m-%d %H:%M:%S') - 删除14天前的备份文件" >> "$LOG_FILE"

# 按日期命名备份文件，并将其复制到挂载目录
DEST_PATH="/od/$CURRENT_DATE-$(basename "$FILE_PATH")"
cp $FILE_PATH $DEST_PATH
echo "$(date +'%Y-%m-%d %H:%M:%S') - 备份文件复制到 '$DEST_PATH'" >> "$LOG_FILE"

# 删除之前的备份文件（如果存在）
rm -rf $FILE_PATH
MESSAGE="$(date "+%Y-%m-%d %H:%M:%S"): $1 同步完成！"
# 使用curl命令向Telegram Bot API发送请求
curl -s -X POST "https://api.telegram.org/bot$API_TOKEN/sendMessage" \
     -d "chat_id=$CHAT_ID" \
     -d "text=$MESSAGE" >> "$LOG_FILE"
# 日志记录结束时间
echo "$(date +'%Y-%m-%d %H:%M:%S') - 备份完成" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

