#!/bin/bash
set -e
export LFS=/mnt/lfs
SOURCES_DIR="${LFS}/sources"


# 检查是否为 root
if [ ${UID} -ne 0 ];then
    echo "请使用sudo运行此脚本"
    exit 1
fi

# 检查目录是否存在
if [ ! -d "$SOURCES_DIR" ];then
    echo "目录 $SOURCES_DIR 不存在，请先运行 Class2-setup_disk.sh"
    exit 1
fi

# 给目录赋予由 sticky bit 权限（LFS 要求），允许所有用户写入
chmod -v a+wt "$SOURCES_DIR"

# 进入目录
pushd "$SOURCES_DIR"


echo "===  获取官方下载清单 ==="
if [ ! -f wget-list ] ;then
    echo "下载清单不存在，开始下载...."
    wget https://www.linuxfromscratch.org/lfs/view/stable/wget-list --continue
    echo "=== 2. (可选) 替换为高速镜像 ==="
    sed -i 's|https://ftp.gnu.org/gnu/|https://mirrors.ustc.edu.cn/gnu/|g' wget-list
    sed -i 's|https://sourceware.org/pub/|https://mirrors.ustc.edu.cn/sourceware/|g' wget-list
else
    echo "下载清单已存在"
fi

if [ ! -f md5sums ] ;then
    echo "md5验证清单不存在，开始下载...."
    wget https://www.linuxfromscratch.org/lfs/view/stable/md5sums --continue
else
    echo "md5验证清单已存在"
fi

echo "===  开始批量下载 (请耐心等待) ==="
# -i 指定输入文件
# -c 断点续传
# -B 指定基础 URL (这里不需要，因为列表里是全路径)

missing=0
missing_files=()
while read -r url; do
    file=${url##*/}
    if [ ! -f "$file" ]; then
        missing=1
        missing_files+=("$file")
    fi
done < wget-list

if [ "$missing" -eq 0 ]; then
    echo "所有包已存在，跳过 wget"
else
    echo "======= 缺失的包列表 ======="
    for f in "${missing_files[@]}"; do
        echo "$f"
    done
    echo "======= 共缺失 ${#missing_files[@]} 个包，开始下载 ======="
    wget --input-file=wget-list --continue --tries=3
fi

echo "===  完整性校验 ==="
# grep -v 排除掉 MD5 文件本身的校验行（如果有的话）
# md5sum -c 自动读取文件里的哈希值和文件名进行比对
if md5sum -c md5sums; then
    echo "✅ 所有文件校验通过！物资准备完毕。"
else
    echo "❌ 有文件校验失败，请检查上方报错信息，并重新下载损坏的包。"
fi

popd