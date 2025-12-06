mock_build(){
    echo  "=== 开始构建 $1 ==="
    sleep 1
    echo "$1 安装完成！"
}

mock_build "Binutils"
mock_build "GCC"
mock_build "Glibc"

