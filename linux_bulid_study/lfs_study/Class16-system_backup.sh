#!/bin/bash
set -e

# 确保在宿主机 root 下
if [ "${UID}" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

export LFS=/mnt/lfs

echo "=== 1. 系统瘦身 (Strip Debug Symbols) ==="
# 注意：我们通过 chroot 进去执行 strip 命令
# 这会删除 /tools 和 /usr/bin 下二进制文件里的调试信息，能省几百兆空间
if [ -d $LFS/tools ]; then
    echo "正在清理临时工具链..."
    chroot "$LFS" /usr/bin/env -i \
        HOME=/root TERM="$TERM" PATH=/usr/bin:/usr/sbin:/tools/bin \
        /bin/bash -c "strip --strip-debug /usr/lib/* /usr/bin/* /tools/lib/* /tools/bin/* 2>/dev/null || true"
fi

# 删除一些不必要的文档
rm -rf $LFS/usr/share/{info,man,doc}/*
rm -rf $LFS/tools/{info,man,doc}/*

echo "=== 2. 创建备份 (Create Tarball) ==="
# 获取当前日期
DATE=$(date +%Y%m%d)
BACKUP_FILE="/root/lfs_temp_system_backup_${DATE}.tar.xz"

echo "正在打包整个 $LFS 目录..."
echo "目标文件: $BACKUP_FILE"
echo "这可能需要几分钟，请耐心等待..."

# 使用 tar 打包
# --exclude=sources: 源码包太大且已经下载好了，没必要备份进系统镜像里（你可以单独备份 sources）
# --exclude=lost+found: 也没用
cd $LFS
tar -cJpf $BACKUP_FILE . \
    --exclude=./sources \
    --exclude=./lost+found \
    --exclude=./dev \
    --exclude=./proc \
    --exclude=./sys \
    --exclude=./run \
    --exclude=./tmp/*

echo "---------------------------------------------------"
echo "🎉 备份完成！"
echo "档案位置: $BACKUP_FILE"
echo "档案大小: $(du -h $BACKUP_FILE | awk '{print $1}')"
echo "---------------------------------------------------"
echo "⚠️ 恢复指南："
echo "如果后续玩坏了，只需运行："
echo "1. rm -rf $LFS/*"
echo "2. tar -xpf $BACKUP_FILE -C $LFS"
echo "---------------------------------------------------"