### 🚀 第十五课：填补空缺 —— 最后的临时工具 (Additional Temporary Tools)

我们现在身处 Chroot 内部，但这只是第一步。
虽然我们有 GCC（在 `/tools` 里）和 Bash（在 `/bin` 里），但为了构建**最终的、完整的** LFS 系统，我们还缺几个用来辅助编译的重磅工具：

1. **Gettext**：用于国际化（很多软件编译时需要它处理 `.po` 文件）。
2. **Bison**：语法分析器（编译某些语言解释器需要）。
3. **Perl**：**极其重要**，Linux 内核和很多核心软件的构建脚本都是用 Perl 写的。
4. **Python**：现代 Linux 软件构建（如 Meson 构建系统）离不开它。
5. **Texinfo**：处理文档系统。
6. **Util-linux**：提供更多底层工具。

这节课，我们将把这些工具一次性补齐。这将是我们作为“临时系统”构建的**最后一战**。

#### ⚠️ 关键的环境变量修正

还记得我在第十三课（进入 Chroot）的脚本里写的 `PATH=/usr/bin:/usr/sbin` 吗？
这里有个**隐患**：我们的 GCC 编译器其实还在 `/tools/bin` 下（这是我们在第六课编译的）。
如果 `PATH` 里没有 `/tools/bin`，接下来的编译都会报错“找不到编译器”。

**所以在运行构建脚本前，我们需要在脚本里强制修正 PATH。**

---

### 🛠️ 任务十五：编写补充工具构建脚本

请**在宿主机**（就像上节课一样）编写脚本 `build_extra_tools.sh`，然后投送到 `$LFS/root`，最后在 **Chroot** 里运行。

**脚本逻辑需求：**

1. **修正 PATH**：把 `/tools/bin` 加回来。
2. **批量构建**：
* **Gettext**：简单配置。
* **Bison**：简单配置。
* **Perl**：配置非常复杂，需要大量参数（因为是临时工具，我们不需要所有特性）。
* **Python**：简单配置，但记得 `--without-ensurepip`（我们不需要 pip）。
* **Texinfo**：简单配置。
* **Util-linux**：需要指定一些目录参数。



**请在宿主机执行以下生成代码：**

```bash
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

```

---

#### 🏃‍♂️ 执行步骤

1. **在宿主机**：运行上面的代码生成脚本。
2. **在 Chroot 窗口**：
* 先确保你的提示符是 `(lfs chroot) root:/#`。
* 运行：`/root/build_extra_tools.sh`。



这个脚本运行时间会稍长一些（尤其是 Perl 和 Python）。当它跑完，我们的**临时系统**就彻底功德圆满，具备了编译最终 LFS 系统所需的一切能力。

**请运行并耐心等待结果！**