
#!/bin/bash
set -e

# 因为使用了su - lfs 后会切换为lfs用户，且无法访问root下的文件，所以此脚本需要在lfs的home目录中
# 保证脚本自动化的，采用思路，在此脚本的开头切换为root用户，将逻辑部分使用cat>xxx<<EOF命令将内容写入目标文件中
if [ "${UID}" -ne 0 ];then
    echo "请使用sudo运行此脚本"
    exit 1
fi

echo "开始往lfs目录下写入脚本内容......"
cat > /home/lfs/build_gcc_pass1.sh <<EOF
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
 
tar -xvf ../mpfr-*.tar.xz
mv -v mpfr-* mpfr

tar -xvf ../gmp-*.tar.xz
mv -v gmp-* gmp

tar -xvf ../mpc-*.tar.gz
mv -v mpc-* mpc

case \$(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac

mkdir -v build

cd build

../configure                                       \
    --target=\$LFS_TGT                              \
    --prefix=/tools                                \
    --with-glibc-version=2.40                      \
    --with-sysroot=\$LFS                            \
    --with-newlib                                  \
    --without-headers                              \
    --enable-default-pie                           \
    --enable-default-ssp                           \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++

make

make install

cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  \`dirname \$(\$LFS_TGT-gcc -print-libgcc-file-name)\`/include/limits.h

if [ \$? -eq 0 ];then
    echo "===============编译顺利结束=============="
    echo "开始删除(\${var%.tar.xz})文件夹"
    cd ../..
    rm -rf \${var%.tar.xz}
    echo "删除结束"
fi

EOF

chown lfs:lfs /home/lfs/build_gcc_pass1.sh
chmod +x /home/lfs/build_gcc_pass1.sh
ls  -ll /home/lfs |grep "build_gcc_pass1.sh"
cat /home/lfs/build_gcc_pass1.sh
echo "请切换为lfs用户，并运行build_gcc_pass1.sh"