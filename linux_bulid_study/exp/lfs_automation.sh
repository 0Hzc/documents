#!/bin/bash
set -e
LFS_MNT="/mnt/lfs_sim"
mock_build(){
    echo  "=== 开始构建 $1 ==="
    sleep 1
    if [ "$1" = "Glibc" ];then
    non_existent_command
    fi
    echo "$1 安装完成！"
}
for package in "Binutils" "GCC" "Glibc" "Bison";do
    mock_build "$package"
done