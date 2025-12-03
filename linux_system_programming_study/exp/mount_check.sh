#!/bin/bash
export LFS=/mnt/LFS

if [ "${UID}" != 0 ]; then
echo "请使用root权限运行此脚本（提示：sudo）"
exit 1
else
    if [ -d "${LFS}" ]; then
    echo "目录${LFS}已存在，准备就绪"
    exit 0
    else
    echo "目录不存在，正在创建${LFS}..."
    mkdir -p ${LFS}
        if [ $? = 0 ]; then
        echo "创建成功"
        exit 0
        else
        echo "创建失败"
        fi
    fi    
fi