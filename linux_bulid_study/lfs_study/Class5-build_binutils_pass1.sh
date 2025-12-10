#!/bin/bash
set -e

# 因为使用了su - lfs 后会切换为lfs用户，且无法访问root下的文件，所以此脚本需要在lfs的home目录中
# 保证脚本自动化的，采用思路，在此脚本的开头切换为root用户，将逻辑部分使用cat>xxx<<EOF命令将内容写入目标文件中
if [ "${UID}" -ne 0 ];then
    echo "请使用sudo运行此脚本"
    exit 1
fi

echo "开始往lfs目录下写入脚本内容......"
cat > /home/lfs/build_binutils_pass1.sh <<EOF
# 检查当前用户是否为 lfs
#!/bin/bash
set -e
if [ "\$(whoami)" != "lfs" ]; then
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

var=\$(ls binutils-*.tar.xz)
if [ -d "\${var%.tar.xz}" ];then
    echo "\${var%.tar.xz}残留，开始删除\${var%.tar.xz}"
    rm -rf \${var%.tar.xz}
fi

echo "开始解压\${var}"
tar -xvf \$var

# 进入解压后的目录
# \${var%.tar.xz} 是 Bash 的字符串操作，用于去掉文件名末尾的 .tar.xz
cd \${var%.tar.xz}

mkdir -v build
cd build

# 执行binutils中的configure 脚本
../configure --prefix=/tools \
             --with-sysroot=\$LFS \
             --target=\$LFS_TGT \
             --disable-nls \
             --enable-gprofng=no \
             --disable-werror

make

make install

if [ \$? -eq 0 ];then
    echo "===============编译顺利结束=============="
    echo "开始删除(\${var%.tar.xz})文件夹"
    cd ../..
    rm -rf \${var%.tar.xz}
    echo "删除结束"
fi

EOF

# 将build_binutils_pass1.sh所属权移交给lfs
chown lfs:lfs /home/lfs/build_binutils_pass1.sh
chmod +x /home/lfs/build_binutils_pass1.sh
ls  -ll /home/lfs |grep "build_binutils_pass1.sh"
cat /home/lfs/build_binutils_pass1.sh
echo "请切换为lfs用户，并运行build_binutils_pass1.sh"



