#!/bin/bash
set -e
LFS_MOUNT=/mnt/lfs
DISK_IMG=lfs_disk.img
DISK_SIZE=10G
if [ "${UID}" = 0 ] ;then
    if [ ! -d "$LFS_MOUNT" ];then
        echo "路径不存在"
        if mkdir "$LFS_MOUNT" ;then
        echo "${LFS_MOUNT}路径创建成功" 
        echo "==============================="
        fi
    else
        echo "${LFS_MOUNT}路径存在"
        echo "==============================="
    fi
    if [ ! -f "$DISK_IMG" ];then
        echo "${DISK_IMG}文件不存在"
        echo "创建${DISK_IMG}文件"
        if dd if=/dev/zero of=lfs_disk.img bs=1G count=10 ;then
            echo "${DISK_IMG}文件创建成功"
            echo "正在格式化${DISK_IMG}为EXT4文件..."
            if mkfs.ext4 -F ${DISK_IMG} ;then
                echo "格式化${DISK_IMG}为EXT4文件成功"
                echo "运行file ${DISK_IMG}查看结果:"
                echo "$(file ${DISK_IMG})"
                echo ""
            fi
        else
            echo "${DISK_IMG}文件创建失败！！"
        fi
    fi
        echo "${DISK_IMG}文件已存在"
        echo "==============================="
        echo "检测是否挂载虚拟硬盘"
        if ! df -h $LFS_MOUNT ;then
            echo "未挂载，正在进行挂载"
            if mount -o loop $DISK_IMG $LFS_MOUNT ;then
                echo "挂载成功，二次验证"
                df -h $LFS_MOUNT
            fi
        fi
            echo "已挂载虚拟硬盘,创建目录与软链接"
            mkdir -p "$LFS_MOUNT/sources" "$LFS_MOUNT/tools"
            chmod a+wt $LFS_MOUNT/sources
            echo "目录创建完成"
        if [ ! -L /tools ]; then
            ln -s "$LFS_MOUNT/tools" /tools
            echo "软链接完成"
        fi
else
    echo "请使用root权限运行此脚本（提示：sudo）"
fi


