#!/bin/bash
# 获取链接的真实路径
SH_TARGET=$(readlink -f /bin/sh)
# 检查路径中是否包含 "bash"
if echo "$SH_TARGET" | grep -q "bash"; then
    echo "环境检查：/bin/sh 正确指向 ($SH_TARGET)。"
    echo "进行下一步，工具包最小版本检查："
    echo "============================================"
else
    echo "默认shell不为bash，终止脚本"
    echo "运行检查命令：ls -l /bin/sh"
    echo $(ls -l /bin/sh)
    exit 1
fi

check_version(){
    case $1 in
    "Bash")
        echo "当前检测包为Bash"
        echo -n "当前版本为："
        echo "$(bash --version)" | awk 'NR == 1 {print $4}'
        echo "最小版本要求：3.2"
        echo "============================================"
        ;;
    Binutils)
        echo "当前检测包为Binutils"
        echo -n "当前版本为："
        echo "$(ld --version)" | awk 'NR == 1 {print $7}' 
        echo "最小版本要求：2.25" 
        echo "============================================"
        ;;
    Bison)
        echo "当前检测包为Bison"
        echo -n "当前版本为："
        echo "$(bison --version)" |awk 'NR == 1 {print $4}'
        echo "最小版本要求：2.7"
        echo "============================================"
        ;;
    Coreutils)
        echo "当前检测包为Coreutils"
        echo -n "当前版本为："
        echo "$(chown --version)" |awk 'NR == 1 {print $4}'
        echo "最小版本要求：6.9"
        echo "============================================"
        ;;
    GCC)
        echo "当前检测包为GCC"
        echo -n "当前版本为："
        echo "$(gcc --version)" |awk 'NR == 1 {print $4}'
        echo "最小版本要求：6.2"
        echo "============================================"
        ;;
    Grep)
        echo "当前检测包为Grep"
        echo -n "当前版本为："
        echo "$(grep --version)" |awk 'NR == 1 {print $4}'
        echo "最小版本要求：2.5.1a"
        echo "============================================"
        ;;
    Gzip)
        echo "当前检测包为Gzip"
        echo -n "当前版本为："
        echo "$(gzip --version)" |awk 'NR == 1 {print $2}'
        echo "最小版本要求：1.3.12"
        echo "============================================"
        ;;
    Make)
        echo "当前检测包为Make"
        echo -n "当前版本为："
        echo "$(make --version)" |awk 'NR == 1 {print $3}'
        echo "最小版本要求：4.0"
        echo "============================================"
        ;;
    Sed)
        echo "当前检测包为Sed"
        echo -n "当前版本为："
        echo "$(sed --version)" |awk 'NR == 1 {print $4}'
        echo "最小版本要求：4.1.5"
        echo "============================================"
        ;;
    Tar)
        echo "当前检测包为Tar"
        echo -n "当前版本为："
        echo "$(tar --version)" |awk 'NR == 1 {print $4}'
        echo "最小版本要求：1.22"
        echo "============================================"
        ;;
    esac
}


for package in "Bash" "Binutils" "Bison" "Coreutils" "GCC" "Grep" "Gzip" "Make" "Sed" "Tar"; do
    check_version "$package"
done