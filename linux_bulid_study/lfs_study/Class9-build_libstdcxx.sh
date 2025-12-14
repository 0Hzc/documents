
#!/bin/bash
set -e

# 因为使用了su - lfs 后会切换为lfs用户，且无法访问root下的文件，所以此脚本需要在lfs的home目录中
# 保证脚本自动化的，采用思路，在此脚本的开头切换为root用户，将逻辑部分使用cat>xxx<<EOF命令将内容写入目标文件中
if [ "${UID}" -ne 0 ];then
    echo "请使用sudo运行此脚本"
    exit 1
fi

cat> /home/lfs/build_libstdcxx.sh <<EOF
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

var=\$(ls gcc-*.tar.xz)
if [ -d "\${var%.tar.xz}" ];then
    echo "\${var%.tar.xz}残留，开始删除\${var%.tar.xz}"
    rm -rf \${var%.tar.xz}
fi

tar -xvf \${var}

cd \${var%.tar.xz}

mkdir -v build

cd build

../libstdc++-v3/configure           \
    --host=\$LFS_TGT                 \
    --build=\$(../config.guess)      \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/\$LFS_TGT/include/c++/14.2.0

make

make DESTDIR=\$LFS install

if [ \$? -eq 0 ];then
    echo "===============编译顺利结束=============="
    echo "开始删除(\${var%.tar.xz})文件夹"
    cd ../..
    rm -rf \${var%.tar.xz}
    echo "删除结束"
fi

echo "删除.la 文件"
rm -v \$LFS/usr/lib/lib{stdc++,stdc++fs,supc++}.la

EOF

chown lfs:lfs /home/lfs/build_libstdcxx.sh
chmod +x /home/lfs/build_libstdcxx.sh
ls  -ll /home/lfs |grep "build_libstdcxx.sh"
cat /home/lfs/build_libstdcxx.sh
echo "请切换为lfs用户，并运行build_libstdcxx.sh"