#!/bin/bash
set -e

# 因为使用了su - lfs 后会切换为lfs用户，且无法访问root下的文件，所以此脚本需要在lfs的home目录中
# 保证脚本自动化的，采用思路，在此脚本的开头切换为root用户，将逻辑部分使用cat>xxx<<EOF命令将内容写入目标文件中
if [ "${UID}" -ne 0 ];then
    echo "请使用sudo运行此脚本"
    exit 1
fi

LFS=/mnt/lfs

# 创建必要的目录结构 (参考 LFS 12.2 Chapter 4.2)
# Glibc 安装需要 etc 和 var 目录，且 lfs 用户需要有写入权限
mkdir -p ${LFS}/lib64
mkdir -p ${LFS}/etc
mkdir -p ${LFS}/var
mkdir -p ${LFS}/usr/bin
mkdir -p ${LFS}/usr/lib
mkdir -p ${LFS}/usr/sbin

# 确保 lfs 用户有权写入这些目录
chown -R lfs:lfs ${LFS}/lib64
chown -R lfs:lfs ${LFS}/etc
chown -R lfs:lfs ${LFS}/var
chown -R lfs:lfs ${LFS}/usr



#======================临时分界线
cat > /home/lfs/build_glibc.sh << EOF
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

if [ -z "\$LFS_TGT" ]; then
    echo "错误: LFS_TGT 环境变量未设置。请检查 lfs 用户的 .bashrc 文件。"
    exit 1
fi



cd \$LFS/sources

# 1. 解压 Linux 内核源码
var=\$(ls glibc-*.tar.xz)
# 清理可能的残留
if [ -d "\${var%.tar.xz}" ];then
    rm -rf \${var%.tar.xz}
fi

# 动态查找补丁文件
patch_file=\$(ls \$LFS/sources/glibc-*-fhs-1.patch 2>/dev/null | head -n 1)
if [ -z "\$patch_file" ]; then
    echo "错误: 未找到 glibc-*-fhs-1.patch 补丁文件。"
    exit 1
fi

tar -xvf \$var
cd \${var%.tar.xz}

patch -Np1 -i \$patch_file

mkdir -v build

cd build

case \$(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 \$LFS/lib/ld-linux.so.2 ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 \$LFS/lib64 ;;
esac

echo "rootsbindir=/usr/sbin" > configparms

../configure                             \
      --prefix=/usr                      \
      --host=\$LFS_TGT                    \
      --build=\$(../scripts/config.guess) \
      --enable-kernel=4.19               \
      --with-headers=\$LFS/usr/include    \
      --disable-nscd                     \
      libc_cv_slibdir=/usr/lib

make -j\$(nproc)

make DESTDIR=\$LFS install

sed '/RTLDLIST=/s@/usr@@g' -i \$LFS/usr/bin/ldd

# 清理源码
cd ..
rm -rf \${var%.tar.xz}
echo "Glibc 交叉编译安装完成"

EOF

chmod +x /home/lfs/build_glibc.sh
chown lfs:lfs /home/lfs/build_glibc.sh
ls  -ll /home/lfs |grep "build_glibc.sh"
cat /home/lfs/build_glibc.sh
echo "请切换为lfs用户，并运行build_glibc.sh"