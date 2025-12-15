
#!/bin/bash
set -e

# 因为使用了su - lfs 后会切换为lfs用户，且无法访问root下的文件，所以此脚本需要在lfs的home目录中
# 保证脚本自动化的，采用思路，在此脚本的开头切换为root用户，将逻辑部分使用cat>xxx<<EOF命令将内容写入目标文件中
if [ "${UID}" -ne 0 ];then
    echo "请使用sudo运行此脚本"
    exit 1
fi

cat> /home/lfs/build_temp_tools_part1.sh <<EOF
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

# var=\$(ls m4-*.tar.xz)
# if [ -d "\${var%.tar.xz}" ];then
#     echo "\${var%.tar.xz}残留，开始删除\${var%.tar.xz}"
#     rm -rf \${var%.tar.xz}
# fi

# tar -xvf \${var}

# cd \${var%.tar.xz}


# ./configure --prefix=/usr   \
#             --host=\$LFS_TGT \
#             --build=\$(build-aux/config.guess)


# make DESTDIR=\$LFS install

# if [ \$? -eq 0 ];then
#     echo "===============编译顺利结束=============="
#     echo "开始删除(\${var%.tar.xz})文件夹"
#     cd ..
#     rm -rf \${var%.tar.xz}
#     echo "删除结束"
# fi

var1=\$(ls ncurses-*.tar.gz)
if [ -d "\${var1%.tar.gz}" ];then
    echo "\${var1%.tar.gz}残留，开始删除\${var1%.tar.gz}"
    rm -rf \${var1%.tar.gz}
fi

tar -xvf \${var1}

cd \${var1%.tar.gz}

sed -i s/mawk// configure



mkdir build

cd build

../configure --prefix=/usr           \
             --host=\$LFS_TGT         \
             --build=\$(./config.guess) \
             --mandir=/usr/share/man \
             --with-manpage-format=normal \
             --with-shared           \
             --without-normal        \
             --with-cxx-shared       \
             --without-debug         \
             --without-ada           \
             --disable-stripping     \
             --enable-widec          \
             --without-cxx-binding


make
make DESTDIR=\$LFS TIC_PATH=\$(pwd)/progs/tic install


echo "INPUT(-lncursesw)" > \$LFS/usr/lib/libncurses.so

if [ \$? -eq 0 ];then
    echo "===============编译顺利结束=============="
    echo "开始删除(\${var1%.tar.gz})文件夹"
    cd ../..
    rm -rf \${var1%.tar.gz}
    echo "删除结束"
fi

EOF

chown lfs:lfs /home/lfs/build_temp_tools_part1.sh
chmod +x /home/lfs/build_temp_tools_part1.sh
ls  -ll /home/lfs |grep "build_temp_tools_part1.sh"
cat /home/lfs/build_temp_tools_part1.sh
echo "请切换为lfs用户，并运行build_temp_tools_part1.sh"