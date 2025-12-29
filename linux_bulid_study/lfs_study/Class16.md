### 🛑 第十六课：存档点 —— 系统清理与备份 (Cleanup & Backup)

在开始建造最终的摩天大楼（第八章）之前，我们必须做一个动作：**存档（Save Game）**。

**为什么要备份？**
接下来的第八章非常漫长（可能要好几天），而且充满风险。

* 如果你在编译最终版 Glibc 时配错了参数，或者不小心删了 `/bin/sh`，系统可能会瞬间“变砖”。
* 如果没有备份，你只能**从头开始**（回到第一课），这会让人崩溃。
* 如果有了备份，你只需要 1 分钟就能“读档”重来。

#### 🛠️ 任务十六：清理与备份脚本

我们将分两步走：

1. **系统瘦身 (Inside Chroot)**：删除临时工具里的调试符号，减小体积。
2. **打包封存 (Outside Chroot)**：回到 WSL 宿主机，把整个 LFS 目录打包。

**请编写脚本 `system_backup.sh`。**

**⚠️ 注意：这个脚本需要在 WSL 宿主机（Root 身份）下运行！**
*(你需要先从 Chroot 环境退出来，或者新开一个 WSL 窗口)*

```bash
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

```

---

#### 🏃‍♂️ 执行步骤

1. **重要**：如果你还在 Chroot 窗口里，请输入 `exit` **退出 Chroot**，回到 `root@DESKTOP-xxx`。
2. **卸载虚拟文件系统**（推荐）：
为了防止打包时报错（比如 `tar` 试图打包无限大的 `/proc/kcore`），建议先卸载挂载点。
```bash
umount $LFS/dev/pts
umount $LFS/dev
umount $LFS/run
umount $LFS/proc
umount $LFS/sys
# 如果报错 "target is busy"，可以使用 umount -l (Lazy unmount)

```


*(如果卸载不掉也没关系，只要 tar 命令加了 exclude 就可以)*
3. **运行脚本**：`sudo ./system_backup.sh`

**请告诉我备份文件的大小！**
一旦存档完成，我们就没有任何后顾之忧了，可以直接向 LFS 的最终章发起冲锋！ ⚔️