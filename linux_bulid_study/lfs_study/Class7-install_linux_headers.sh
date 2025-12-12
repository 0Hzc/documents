#!/bin/bash
set -e

# 因为使用了su - lfs 后会切换为lfs用户，且无法访问root下的文件，所以此脚本需要在lfs的home目录中
# 保证脚本自动化的，采用思路，在此脚本的开头切换为root用户，将逻辑部分使用cat>xxx<<EOF命令将内容写入目标文件中
if [ "${UID}" -ne 0 ];then
    echo "请使用sudo运行此脚本"
    exit 1
fi

LFS=/mnt/lfs

mkdir -p ${LFS}/usr/include

chown -R lfs:lfs ${LFS}/usr

echo "开始往lfs目录下写入脚本内容......"
cat > /home/lfs/install_linux_headers.sh <<EOF
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

cd \$LFS/sources

# 1. 解压 Linux 内核源码
var=\$(ls linux-*.tar.xz)
# 清理可能的残留
if [ -d "\${var%.tar.xz}" ];then
    rm -rf \${var%.tar.xz}
fi

tar -xvf \$var
cd \${var%.tar.xz}

# 2. 清理环境
make mrproper

# 3. 生成头文件
make headers

if [ ! -d "\${LFS}/usr/include" ];then
    echo "\${LFS}/usr/include路径不存在"
    exit 1
fi

# 4. 安装头文件 (LFS 标准步骤)
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include/* \$LFS/usr/include

# 5. 清理源码
cd ..
rm -rf \${var%.tar.xz}
echo "Linux API Headers 安装完成"
EOF

chown lfs:lfs /home/lfs/install_linux_headers.sh
chmod +x /home/lfs/install_linux_headers.sh
ls  -ll /home/lfs |grep "install_linux_headers.sh"
cat /home/lfs/install_linux_headers.sh
echo "请切换为lfs用户，并运行install_linux_headers.sh"