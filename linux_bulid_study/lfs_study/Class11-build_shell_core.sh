
#!/bin/bash
set -e

# 因为使用了su - lfs 后会切换为lfs用户，且无法访问root下的文件，所以此脚本需要在lfs的home目录中
# 保证脚本自动化的，采用思路，在此脚本的开头切换为root用户，将逻辑部分使用cat>xxx<<EOF命令将内容写入目标文件中
if [ "${UID}" -ne 0 ];then
    echo "请使用sudo运行此脚本"
    exit 1
fi

cat> /home/lfs/build_shell_core.sh <<EOF
#!/bin/bash
set -e

if [ "\$(whoami)" != "lfs" ];then
    echo "错误：当前用户是 \$(whoami)，请切换到 lfs 用户后再运行此脚本！"
    echo "提示：请先运行 'su - lfs'"
    exit 1
fi

if ! env|grep "LFS=/mnt/lfs";then
    echo "LFS 变量不存在"
    exit 1
fi

LFS_TGT=\$(uname -m)-lfs-linux-gnu

cd \$LFS/sources

# ==========================================
# 1. 编译 Bash
# ==========================================
var=\$(ls bash-*.tar.gz)
if [ -d "\${var%.tar.gz}" ];then
    echo "\${var%.tar.gz}残留，开始删除..."
    rm -rf \${var%.tar.gz}
fi

echo "正在解压 \${var}..."
tar -xf \${var}
cd \${var%.tar.gz}

./configure --prefix=/usr                      \
            --build=\$(support/config.guess)    \
            --host=\$LFS_TGT                    \
            --without-bash-malloc

make DESTDIR=\$LFS install

# 关键修正：链接 sh 到 bash
ln -sv bash \$LFS/bin/sh

echo "Bash 编译完成，清理源码..."
cd ..
rm -rf \${var%.tar.gz}


# ==========================================
# 2. 编译 Coreutils
# ==========================================
var1=\$(ls coreutils-*.tar.xz)
if [ -d "\${var1%.tar.xz}" ];then
    echo "\${var1%.tar.xz}残留，开始删除..."
    rm -rf \${var1%.tar.xz}
fi

echo "正在解压 \${var1}..."
tar -xf \${var1}
cd \${var1%.tar.xz}

./configure --prefix=/usr                     \
            --host=\$LFS_TGT                   \
            --build=\$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime

make DESTDIR=\$LFS install

# 路径修正
mv -v \$LFS/usr/bin/chroot \$LFS/usr/sbin
mkdir -p \$LFS/usr/share/man/man8
mv -v \$LFS/usr/share/man/man1/chroot.1 \$LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' \$LFS/usr/share/man/man8/chroot.8

echo "Coreutils 编译完成，清理源码..."
cd ..
rm -rf \${var1%.tar.xz}


# ==========================================
# 3. 编译 Make
# ==========================================
var2=\$(ls make-*.tar.gz)
if [ -d "\${var2%.tar.gz}" ];then
    echo "\${var2%.tar.gz}残留，开始删除..."
    rm -rf \${var2%.tar.gz}
fi

echo "正在解压 \${var2}..."
tar -xf \${var2}
cd \${var2%.tar.gz}

./configure --prefix=/usr   \
            --without-guile \
            --host=\$LFS_TGT \
            --build=\$(build-aux/config.guess)

make DESTDIR=\$LFS install

echo "Make 编译完成，清理源码..."
cd ..
rm -rf \${var2%.tar.gz}


# ==========================================
# 4. 深度验证环节 (Class11 要求)
# ==========================================
echo "---------------------------------------------------"
echo "🔍 正在进行深度验证..."

# 1. 验证 /bin/sh 是否链接正确
if [ "\$(readlink \$LFS/bin/sh)" == "bash" ]; then
    echo "✅ [1/3] /bin/sh 正确链接到 bash。"
else
    echo "❌ [1/3] 失败：/bin/sh 链接错误！"
    exit 1
fi

# 2. 验证 Coreutils (以 ls 为例)
if file \$LFS/usr/bin/ls | grep -q "x86-64"; then
    echo "✅ [2/3] Coreutils (ls) 架构正确。"
else
    echo "❌ [2/3] 失败：ls 命令格式不正确 (可能使用了宿主机的 ls)！"
    exit 1
fi

# 3. 验证 Make 是否存在
if [ -x "\$LFS/usr/bin/make" ]; then
    echo "✅ [3/3] Make 工具已安装。"
else
    echo "❌ [3/3] 失败：Make 未找到。"
    exit 1
fi

echo "🎉 Shell 与核心工具构建完成！"
echo "---------------------------------------------------"

EOF

chown lfs:lfs /home/lfs/build_shell_core.sh
chmod +x /home/lfs/build_shell_core.sh
ls  -ll /home/lfs |grep "build_shell_core.sh"
cat /home/lfs/build_shell_core.sh
echo "请切换为lfs用户，并运行build_shell_core.sh"