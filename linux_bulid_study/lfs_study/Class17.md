太棒了！🎉🎉🎉

既然你已经完成了**存档（备份）**，现在你的 LFS 之旅拥有了最宝贵的“后悔药”。无论接下来的操作有多么惊险，你都可以随时回滚到这个状态。

现在，我们正式进入 **LFS 第八章：安装基本系统软件 (Installing Basic System Software)**。

### 🏛️ 第十七课：重返矩阵与最终基石 (Re-entry & The Final Glibc)

这是真正“盖楼”的开始。
在之前的章节里，我们编译的 Glibc 和 GCC 都是放在 `/tools` 里的“临时工”。
从这一课开始，我们要把这些核心软件**重新编译一遍**，并且这次是安装到标准的 `/usr` 和 `/lib` 目录下，成为你系统里永久的一部分。

本课我们将完成三件事：

1. **恢复现场**：重新挂载并进入 Chroot（因为备份时我们退出来了）。
2. **热身运动**：安装 `Man-pages` (文档) 和 `Iana-Etc` (网络协议表)。
3. **最终 BOSS**：编译并安装**最终版 Glibc**，并配置系统的时区和动态链接库加载器。

---

### 🛠️ 步骤一：恢复挂载并进入 Chroot

因为备份前我们卸载了虚拟文件系统，现在必须把它们挂载回来才能工作。

**请在宿主机 (WSL Root) 运行以下命令：**
*(你可以把这几行保存为 `mount_and_enter.sh`，以后每次重启 WSL 都要用)*

```bash
export LFS=/mnt/lfs

# 1. 挂载虚拟文件系统 (如果还没挂载)
# 使用 mountpoint -q 判断，防止重复挂载
mountpoint -q $LFS/dev     || mount -v --bind /dev $LFS/dev
mountpoint -q $LFS/dev/pts || mount -v --bind /dev/pts $LFS/dev/pts
mountpoint -q $LFS/proc    || mount -vt proc proc $LFS/proc
mountpoint -q $LFS/sys     || mount -vt sysfs sysfs $LFS/sys
mountpoint -q $LFS/run     || mount -vt tmpfs tmpfs $LFS/run

# 2. 修复 /dev/shm (防止重启后丢失)
if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi

# 3. 进入 Chroot
# 注意：这里我们再次进入，准备开始大干一场
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    /bin/bash --login

```

**运行后，确保你的提示符回到了 `(lfs chroot) root:/#`。**

---

### 🛠️ 步骤二：构建最终基石脚本

请在 **Chroot 环境内** 创建并运行脚本 `build_final_system_part1.sh`。
*(你可以像之前一样在宿主机写好投送进去，也可以直接在 Chroot 里用 `cat` 写)*

**脚本要点：**

* **Glibc 的测试**：通常我们会运行 Glibc 的测试套件（Test Suite），但这需要很长时间。为了课程进度，我们这里**跳过测试**（Standard LFS 允许这样，虽然不推荐用于生产环境）。如果你非常想要跑测试，可以把脚本里的 `make check` 注释打开。
* **配置文件**：Glibc 安装完后，必须手动创建 `/etc/nsswitch.conf` 和 `/etc/ld.so.conf`，否则系统无法解析域名或加载库文件。
* **Locales**：安装语言包，防止以后出现乱码。

**脚本内容 (在宿主机生成，投送给 Chroot)：**

```bash
cat > $LFS/root/build_final_system_part1.sh << "EOF"
#!/bin/bash
set -e

cd /sources

echo "=== 1. 安装 Man-pages (系统文档) ==="
tarball=$(ls man-pages-*.tar.* | head -n1)
dir=${tarball%.tar.xz}
[ -d "$dir" ] && rm -rf "$dir"
tar -xf $tarball && cd $dir

make prefix=/usr install

cd /sources && rm -rf $dir
echo "✅ Man-pages 安装完成"


echo "=== 2. 安装 Iana-Etc (网络协议表) ==="
tarball=$(ls iana-etc-*.tar.* | head -n1)
dir=${tarball%.tar.gz}
[ -d "$dir" ] && rm -rf "$dir"
tar -xf $tarball && cd $dir

cp -v services protocols /etc

cd /sources && rm -rf $dir
echo "✅ Iana-Etc 安装完成"


echo "=== 3. 安装 Glibc (最终版) ==="
# 注意：这是系统里最重要的库，步骤较多，请耐心
tarball=$(ls glibc-*.tar.xz | head -n1)
dir=${tarball%.tar.xz}
[ -d "$dir" ] && rm -rf "$dir"
tar -xf $tarball && cd $dir

# 打补丁
patch -Np1 -i ../glibc-2.40-fhs-1.patch

mkdir -v build && cd build

# 配置 (注意：这里没有 --host=$LFS_TGT 了，因为我们在本机编译本机！)
echo "rootsbindir=/usr/sbin" > configparms
../configure --prefix=/usr                            \
             --disable-werror                         \
             --enable-kernel=4.19                     \
             --enable-stack-protector=strong          \
             --disable-nscd                           \
             libc_cv_slibdir=/usr/lib

echo "🔨 正在编译 Glibc (这需要几分钟)..."
make -j$(nproc)

# 跳过 make check (为了速度)
# make check

echo "💾 正在安装 Glibc..."
# 创建必要的配置文件，防止安装过程报错
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile

make install

# 安装被配置脚本忽略的工具
sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd
cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd

echo "🌍 安装 Locales (语言支持)..."
# 只安装最重要的几个，节省时间
mkdir -pv /usr/lib/locale
localedef -i C -f UTF-8 C.UTF-8
localedef -i zh_CN -f UTF-8 zh_CN.UTF-8
localedef -i en_US -f UTF-8 en_US.UTF-8

echo "⚙️ 配置 Glibc..."

# 1. 配置 /etc/nsswitch.conf (名称服务切换)
cat > /etc/nsswitch.conf << "NSSWITCH"
passwd: files
group: files
shadow: files
hosts: files dns
networks: files
protocols: files
services: files
ethers: files
rpc: files
NSSWITCH

# 2. 配置 /etc/ld.so.conf (动态链接库搜索路径)
cat > /etc/ld.so.conf << "LDCONF"
/usr/local/lib
/opt/lib
include /etc/ld.so.conf.d/*.conf
LDCONF
mkdir -pv /etc/ld.so.conf.d

cd /sources && rm -rf $dir
echo "✅ Glibc (Final) 构建完成！"

# --- 深度验证 ---
echo "---------------------------------------------------"
echo "🔍 验证 Glibc..."
# 验证 ldd 是否正常
if ldd /bin/bash | grep -q "libc.so.6"; then
    echo "✅ ldd 工作正常，/bin/bash 链接到了 libc"
else
    echo "❌ ldd 检查失败！"
    exit 1
fi

# 验证 locale
if localedef --list-archive | grep -q "zh_CN.utf8"; then
    echo "✅ 中文环境 (zh_CN.utf8) 已就绪"
else
    echo "❌ Locale 安装失败"
fi
echo "---------------------------------------------------"
EOF

chmod +x $LFS/root/build_final_system_part1.sh

```

---

#### 🏃‍♂️ 执行任务

1. **挂载并进入**：先运行第一段代码 `mount_and_enter`。
2. **生成脚本**：运行第二段代码生成脚本。
3. **执行构建**：在 `(lfs chroot)` 下运行 `/root/build_final_system_part1.sh`。

**这个脚本跑完，你的 LFS 系统就拥有了真正的“灵魂”。请把最后的验证输出发给我！**