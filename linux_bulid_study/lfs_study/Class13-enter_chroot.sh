#!/bin/bash
set -e

# 因为使用了su - lfs 后会切换为lfs用户，且无法访问root下的文件，所以此脚本需要在lfs的home目录中
# 保证脚本自动化的，采用思路，在此脚本的开头切换为root用户，将逻辑部分使用cat>xxx<<EOF命令将内容写入目标文件中
if [ "${UID}" -ne 0 ];then
    echo "请使用sudo运行此脚本"
    exit 1
fi

export LFS=/mnt/lfs

# 2. 所有权修正
echo "正在修正文件所有权..."
chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
if [ -d "$LFS/lib64" ]; then
    chown -R root:root $LFS/lib64
fi

# 3. 挂载虚拟文件系统
echo "正在挂载虚拟文件系统..."

# 辅助函数：检查挂载点
function check_and_mount() {
    local device=$1
    local mountpoint=$2
    local type=$3
    
    # 确保挂载点存在
    if [ ! -d "$mountpoint" ]; then
        mkdir -pv "$mountpoint"
    fi

    if ! mountpoint -q "$mountpoint"; then
        if [ -n "$type" ]; then
            mount -vt "$type" "$device" "$mountpoint"
        else
            mount -v --bind "$device" "$mountpoint"
        fi
    else
        echo "$mountpoint 已经挂载，跳过。"
    fi
}

check_and_mount /dev "$LFS/dev" ""
check_and_mount /dev/pts "$LFS/dev/pts" ""
check_and_mount proc "$LFS/proc" "proc"
check_and_mount sysfs "$LFS/sys" "sysfs"
check_and_mount tmpfs "$LFS/run" "tmpfs"

# 4. 修复 /dev/shm
if [ -h $LFS/dev/shm ]; then
    echo "正在修复 /dev/shm..."
    mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi

# 5. 进入 Chroot
echo "正在进入 Chroot 环境..."
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    /bin/bash --login