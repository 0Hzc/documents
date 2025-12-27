#!/bin/bash
set -e

export LFS=/mnt/lfs

cat > $LFS/root/build_extra_tools.sh << "EOF"
#!/bin/bash
set -e

echo "=== 0. 环境准备 ==="
# 关键：把 /tools/bin 加入 PATH，否则找不到 gcc
export PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin

# 检查编译器是否工作
if ! gcc --version >/dev/null 2>&1; then
    echo "❌ 错误：在 PATH 中找不到 gcc！"
    echo "当前 PATH: $PATH"
    exit 1
fi

cd /sources

# 定义列表
TOOLS="gettext bison perl python texinfo util-linux"

for pkg in $TOOLS; do
    echo "---------------------------------------------------"
    echo "🔨 正在构建: $pkg"
    
    # 自动解压逻辑
    tarball=$(ls ${pkg}-*.tar.* 2>/dev/null | head -n 1)
    if [ -z "$tarball" ]; then echo "❌ 未找到 $pkg 源码"; exit 1; fi
    
    # 获取目录名
    if [[ "$tarball" == *.tar.xz ]]; then dirname=${tarball%.tar.xz}; 
    elif [[ "$tarball" == *.tar.gz ]]; then dirname=${tarball%.tar.gz}; fi
    
    # 清理残留
    if [ -d "$dirname" ]; then rm -rf "$dirname"; fi
    
    tar -xf "$tarball"
    cd "$dirname"

    # --- 配置与编译 ---
    case $pkg in
        gettext)
            ./configure --disable-shared
            make
            cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
            ;;
            
        bison)
            ./configure --prefix=/usr \
                        --docdir=/usr/share/doc/bison-3.8.2
            make
            make install
            ;;
            
        perl)
            # Perl 需要非常详细的配置
            sh Configure -des                                        \
                         -Dprefix=/usr                               \
                         -Dvendorprefix=/usr                         \
                         -Duseshrplib                                \
                         -Dprivlib=/usr/lib/perl5/5.40/core_perl     \
                         -Darchlib=/usr/lib/perl5/5.40/core_perl     \
                         -Dsitelib=/usr/lib/perl5/5.40/site_perl     \
                         -Dsitearch=/usr/lib/perl5/5.40/site_perl    \
                         -Dvendorlib=/usr/lib/perl5/5.40/vendor_perl \
                         -Dvendorarch=/usr/lib/perl5/5.40/vendor_perl
            make
            make install
            ;;
            
        python)
            # 临时 Python 不需要 pip，且需要开启共享库
            ./configure --prefix=/usr   \
                        --enable-shared \
                        --without-ensurepip
            make
            make install
            ;;
            
        texinfo)
            ./configure --prefix=/usr
            make
            make install
            ;;
            
        util-linux)
            # 创建必要的目录
            mkdir -pv /var/lib/hwclock
            ./configure --libdir=/usr/lib    \
                        --runstatedir=/run   \
                        --disable-chfn-chsh  \
                        --disable-login      \
                        --disable-nologin    \
                        --disable-su         \
                        --disable-setpriv    \
                        --disable-runuser    \
                        --disable-pylibmount \
                        --disable-static     \
                        --without-python     \
                        --without-systemd    \
                        --without-systemdsystemunitdir
            make
            make install
            ;;
    esac

    # 清理
    cd /sources
    rm -rf "$dirname"
    echo "✅ $pkg 构建完成"
done

echo "---------------------------------------------------"
echo "🎉 所有补充临时工具构建完成！"
echo "🔍 验证核心解释器..."

if perl -v | grep -q "v5."; then echo "✅ Perl 工作正常"; else echo "❌ Perl 异常"; fi
if python3 -V | grep -q "3."; then echo "✅ Python 工作正常"; else echo "❌ Python 异常"; fi

EOF

chmod +x $LFS/root/build_extra_tools.sh