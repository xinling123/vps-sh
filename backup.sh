#!/bin/bash

cd $1/backup
time=$(date "+%Y-%m-%d")
mkdir $time
cd $time

for dir_name in $(ls $1)
do
    cur_dir="$1/$dir_name"
    if [ -d $cur_dir ];then
    		cd $1
        	tar -zcvf $dir_name.tar.gz $dir_name >/dev/null 2>&1
        	mv $dir_name.tar.gz $1/backup/$time
    fi
done

rclone copy $1/backup/$time $2:/Backup/$2-$time   --ignore-existing -u -v -P --transfers=10 --ignore-errors --check-first --checkers=10
rm -rf $1/backup/$time
rclone --min-age 3d delete $2:/Backup
echo $(date "+%Y-%m-%d %H:%M:%S")'：同步完成！' > $1/backup/backup.log