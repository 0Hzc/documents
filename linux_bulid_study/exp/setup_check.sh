#!/bin/bash

export LFS=/mnt/lfs
export LFS_TGT=x86_64-lfs-linux-gnu
export JOB_COUNT=4

echo "我们将构建目标：${LFS_TGT}，挂载点为：${LFS}"

echo '请确保系统变量${LFS}已正确设置'

echo "编译并将使用${JOB_COUNT}个核心。"