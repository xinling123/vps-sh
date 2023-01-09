#!/bin/bash

cd /home/backup
time=$(date "+%Y-%m-%d")
mkdir $time
cd $time

for dir_name in $(ls $1)
do
    cur_dir="$1/$dir_name"
    if [ -d $cur_dir ];then
    tar -zcvf $dir_name.tar.gz $cur_dir >/dev/null 2>&1
    fi
done

rclone copy /home/backup/$time $2:/Backup/$2-$time   --ignore-existing -u -v -P --transfers=10 --ignore-errors --check-first --checkers=10
rm -rf /home/backup/$time
echo $(date "+%Y-%m-%d %H:%M:%S")'：同步完成！' > /home/backup/backup.log