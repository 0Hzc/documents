#!/bin/bash
set -e
# 检查是否为 root
if [ "${UID}" -ne 0 ];then
    echo "请使用sudo运行此脚本"
    exit 1
fi
#========================WSL2环境下临时LFS用户和组准备============================================
#           说明
# 因为ubuntu系统的lfs组与lfs用户共用gid，若删除lfs用户，则创建的lfs组也会删除
# 因此进行自动化创建新lfs用户时，需先判断lfs用户是否存在，并删除
# 再判断lfs组是否存在，并删除
# 最后再重新创建lfs组和lfs用户

if id lfs > /dev/null 2>&1; then
    echo "lfs用户已存在，开始删除..."
    # -r 参数：删除用户的同时清理家目录（避免重建冲突）
    if userdel -r lfs; then
        echo "lfs用户删除成功"
    else
        echo "错误：lfs用户删除失败"
        exit 1  # 删除失败时退出，避免后续错误
    fi
fi

# 检查家目录是否残留（兜底）
if [ -d "/home/lfs" ]; then
    echo "警告：/home/lfs 目录残留，强制清理..."
    rm -rf "/home/lfs" || { echo "错误：清理残留家目录失败"; exit 1; }
fi


if getent group lfs > /dev/null 2>&1; then
    echo "lfs 组已存在，无需重复创建"
else
    if groupadd lfs; then
        echo "lfs 组创建成功"
    else
        echo "错误：lfs 组创建失败！"
        exit 1
    fi
fi

echo "开始创建lfs用户..."


# 创建用户（-m 自动建家目录，-k /dev/null 不复制骨架文件）
if useradd -s /bin/bash -g lfs -m -k /dev/null lfs; then
    echo "lfs用户创建成功"
    echo "设置lfs默认密码：123456"

    # 核心：非交互式设置密码（echo 密码 | passwd --stdin 仅适用于CentOS/RHEL；Ubuntu用chpasswd）
    echo "lfs:123456" | chpasswd
    # 检查密码设置是否成功
    if [ $? -eq 0 ]; then
        echo "lfs用户密码设置成功"
    else
        echo "错误：lfs用户密码设置失败"
        exit 1
    fi    
else
    echo "错误：lfs用户创建失败"
    exit 1
fi


#========================移交工具所属权============================================

if chown -v lfs:lfs ${LFS}/tools >/dev/null 2>&1;then
    echo "移交tools权限成功"
else
    echo "错误：移交tools权限错误"
    exit 1
fi

if chown -v lfs:lfs ${LFS}/sources >/dev/null 2>&1;then
    echo "移交sources权限成功"
else
    echo "错误：移交sources权限错误"
    exit 1
fi

#=======================在WLS2的临时LFS用户下指定干净的bash空间========================
if cd /home/lfs >/dev/null 2>&1;then
cat >.bash_profile<<EOF
exec env -i HOME=/home/lfs TERM=\$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat >.bashrc<<EOF
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/bin:/usr/bin
export LFS LC_ALL LFS_TGT PATH
EOF
#同时需要将root权限下创建的文件，移交权限给lfs用户
chown lfs:lfs /home/lfs/.bash_profile /home/lfs/.bashrc
fi

echo "用户创建成功。请运行 su - lfs 切换身份进行验证。"