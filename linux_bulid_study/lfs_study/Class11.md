**务必**执行以下命令验证 Ncurses 的成果，因为它关系到后面 Bash 的编译：

```bash
# 验证 Ncurses 库修正 (还记得那个 INPUT(-lncursesw) 吗？)
cat /mnt/lfs/usr/lib/libncurses.so
# 预期输出：INPUT(-lncursesw)

# 验证 terminfo (Ncurses 的数据库)
ls -d /mnt/lfs/usr/share/terminfo
# 预期输出：目录存在

```

如果这两项没问题，我们就继续！

---

### 🚀 第十一课：系统的灵魂 —— Shell 与 核心工具 (Bash & Coreutils)

现在我们要构建整个系统的**交互界面（Shell）和基本命令（ls, cp, mv 等）**。

这是非常关键的一步，尤其是 **Bash**。

* 目前我们用的 `sh` 还是宿主机的 `/bin/bash`。
* 编译完这一步后，我们将拥有一个**属于 LFS 自己的 Shell**。
* 稍后我们会把 `/mnt/lfs/bin/sh` 指向这个新 Bash，这是我们脱离宿主机的关键一步。

#### 📦 本节目标清单

我们将编写 `build_shell_core.sh`，批量完成以下三个核心软件的编译：

1. **Bash** (The Shell)
* **难点**：配置时要加上 `--without-bash-malloc`。因为 Bash 自带的内存分配器在交叉编译环境下经常崩溃，我们需要强行让它使用 Glibc 的 `malloc`。


2. **Coreutils** (核心工具集)
* 包含 `ls`, `cat`, `cp`, `mv`, `mkdir` 等几十个命令。
* **难点**：它非常庞大。而且我们需要特别启用 `hostname` 工具，同时禁用 `kill` 和 `uptime`（因为这些通常由稍后的 Procps-ng 包提供，避免冲突）。


3. **Make** (构建工具)
* 没有 Make，我们在新系统里就没法编译任何东西。



---

### 🛠️ 任务十一：编写基础系统构建脚本

请编写脚本 `build_shell_core.sh`。

**脚本逻辑需求：**

1. **准备工作**：(Root 生成 -> LFS 运行)。
2. **任务一：编译 Bash**
* **源码**：`bash-5.2.32.tar.gz` (具体版本以 `ls` 为准)。
* **配置**：
```bash
./configure --prefix=/usr                      \
            --build=$(support/config.guess)    \
            --host=$LFS_TGT                    \
            --without-bash-malloc

```


* **编译安装**：`make DESTDIR=$LFS install`
* **关键修正 (链接 sh)**：
* Linux 系统运行脚本时默认找 `/bin/sh`。我们需要创建一个软链接，让 `/bin/sh` 指向刚才装好的 `bash`。
* `ln -sv bash $LFS/bin/sh`




3. **任务二：编译 Coreutils**
* **源码**：`coreutils-9.5.tar.xz`。
* **配置**：
```bash
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime

```


* **编译安装**：`make DESTDIR=$LFS install`
* **路径修正**：
* `chroot` 命令非常重要，但默认安装在 `/usr/bin` 下。为了符合标准，我们要把它移动到 `/usr/sbin`。
* `mv -v $LFS/usr/bin/chroot $LFS/usr/sbin`
* 创建一个 man page 目录（如果不存在），防止后续报错：`mkdir -p $LFS/usr/share/man/man8`
* 重命名 chroot 的文档：`mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8`
* 修改文档里的分类号：`sed -i 's/"1"/"8"/' $LFS/usr/share/man/man8/chroot.8`




4. **任务三：编译 Make**
* **源码**：`make-4.4.1.tar.gz`。
* **配置**：
```bash
./configure --prefix=/usr   \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

```


* **编译安装**：`make DESTDIR=$LFS install`


5. **清理**：
* 每一步做完后删除源码目录。



---

### 🔍 深度验证环节 (请写入脚本)

这次的验证至关重要，因为 Bash 坏了，后面的 Chroot 就会失败。

```bash
echo "---------------------------------------------------"
echo "🔍 正在进行深度验证..."

# 1. 验证 /bin/sh 是否链接正确
# readlink 输出应该是 "bash"
if [ "$(readlink $LFS/bin/sh)" == "bash" ]; then
    echo "✅ [1/3] /bin/sh 正确链接到 bash。"
else
    echo "❌ [1/3] 失败：/bin/sh 链接错误！"
    exit 1
fi

# 2. 验证 Coreutils (以 ls 为例)
# 检查 ls 是否是交叉编译的 x86-64 格式，而不是宿主机的格式
if file $LFS/usr/bin/ls | grep -q "x86-64"; then
    echo "✅ [2/3] Coreutils (ls) 架构正确。"
else
    echo "❌ [2/3] 失败：ls 命令格式不正确 (可能使用了宿主机的 ls)！"
    exit 1
fi

# 3. 验证 Make 是否存在
if [ -x "$LFS/usr/bin/make" ]; then
    echo "✅ [3/3] Make 工具已安装。"
else
    echo "❌ [3/3] 失败：Make 未找到。"
    exit 1
fi

echo "🎉 Shell 与核心工具构建完成！"
echo "---------------------------------------------------"

```

**请尝试在一个脚本中把这三座大山（Bash, Coreutils, Make）翻过去！**


#### 第一步：清理宿主机的错误链接 (Root 身份)
在当前的 Root 终端执行：

```bash
# 删除刚才误创建的垃圾链接
rm -v /bin/bin /lib/lib /sbin/sbin
```

#### 第二步：正确设置 LFS 变量并创建链接 (Root 身份)
确保变量设置正确后再执行操作：

```bash
# 1. 显式设置 LFS 变量
export LFS=/mnt/lfs

# 2. 再次检查 (必须看到 /mnt/lfs 才行)
echo $LFS
# 预期输出: /mnt/lfs

# 3. 执行修复命令 (创建 LFS 系统的目录链接)
for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done

# 4. 修正权限 (因为是 Root 创建的，最好把所有权还给 lfs 用户)
chown -h lfs:lfs $LFS/bin $LFS/lib $LFS/sbin
```

#### 第三步：验证
执行完上述操作后，再次检查：

```bash
ls -l $LFS
```
这次你应该能看到 `bin -> usr/bin` 等链接，且目录内容是 LFS 的结构（包含 `sources`, `tools` 等）。

