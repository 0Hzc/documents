
#!/bin/bash
set -e

# 因为使用了su - lfs 后会切换为lfs用户，且无法访问root下的文件，所以此脚本需要在lfs的home目录中
# 保证脚本自动化的，采用思路，在此脚本的开头切换为root用户，将逻辑部分使用cat>xxx<<EOF命令将内容写入目标文件中
if [ "${UID}" -ne 0 ];then
    echo "请使用sudo运行此脚本"
    exit 1
fi

cat> /home/lfs/build_remaining_tools.sh <<EOF
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


my_array=("diffutils" "file" "findutils" "gawk" "grep" "gzip" "patch" "sed" "tar" "xz")

cd \$LFS/sources


for item in "\${my_array[@]}"; do
    # 获取文件名 (假设只有一个匹配的文件)
    # 使用 ls 可能在文件名包含空格时出问题，但在 LFS 源码包场景通常没问题
    var=\$(ls \$item-*.tar.* 2>/dev/null | head -n 1)

    # 检查是否找到了文件
    if [ -z "\$var" ]; then
        echo "未找到 \$item 的源码包"
        continue
    fi

    echo "正在处理: \$var"

    # 根据后缀判断
    case "\$var" in
        *.tar.gz)
            echo "检测到 gz 格式"
            if [ -d "\${var%.tar.gz}" ];then
                echo "\${var%.tar.gz}残留，开始删除..."
                rm -rf \${var%.tar.gz}
            fi
            echo "正在解压 \${var}..."
            tar -xf \${var}
            cd \${var%.tar.gz}
            ;;
        *.tar.xz)
            echo "检测到 xz 格式"
            if [ -d "\${var%.tar.xz}" ];then
                echo "\${var%.tar.xz}残留，开始删除..."
                rm -rf \${var%.tar.xz}
            fi
            echo "正在解压 \${var}..."
            tar -xf \${var}
            cd \${var%.tar.xz}
            ;;
        *)
            echo "未知格式: \$var"
            ;;
    esac
    
    echo "--------------------------------"

    case "\$item" in
        "findutils")
        ./configure --prefix=/usr                      \
                    --host=\$LFS_TGT                    \
                    --localstatedir=/var/lib/locate
        ;;
        "gzip")
        ./configure --prefix=/usr                      \
                    --host=\$LFS_TGT
        ;;
        *)
        ./configure --prefix=/usr                      \
                    --host=\$LFS_TGT
        ;;
    esac

    make -j\$(nproc)
    make DESTDIR=\$LFS install

    cd \$LFS/sources
    # 可选：为了节省空间，可以在这里删除解压后的目录
    # rm -rf \${var%.tar.*}

done


# --- 深度验证 ---
echo "---------------------------------------------------"
echo "🔍 正在进行最终验证..."

failed=0
for tool in diff file find gawk grep gzip patch sed tar xz; do
    if [ -x "\$LFS/usr/bin/\$tool" ]; then
        echo "✅ \$tool 已安装"
    else
        echo "❌ \$tool 缺失！"
        failed=1
    fi
done

if [ \$failed -eq 0 ]; then
    echo "🎉 所有剩余工具构建完成！临时系统准备就绪！"
else
    echo "❌ 存在构建失败的工具，请检查日志。"
    exit 1
fi
echo "---------------------------------------------------"
EOF

chown lfs:lfs /home/lfs/build_remaining_tools.sh
chmod +x /home/lfs/build_remaining_tools.sh
ls  -ll /home/lfs |grep "build_remaining_tools.sh"
cat /home/lfs/build_remaining_tools.sh
echo "请切换为lfs用户，并运行build_remaining_tools.sh"