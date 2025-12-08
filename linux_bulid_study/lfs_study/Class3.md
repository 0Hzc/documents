### 📦 第三课：物资采购 (Materials Procurement)

假设你已经修复了上面的挂载脚本，现在我们的 LFS 系统有了一个 10GB 的家（`/mnt/lfs`），而且里面已经有了存放建材的仓库（`/mnt/lfs/sources`）。

但是仓库是空的。LFS 需要大概 80 多个软件包的**源码压缩包**（Tarballs）。我们需要把它们全部下载下来，并且**验证真伪**。

在 LFS 手册中，这一步通常涉及两个文件：

1.  `wget-list`：一个长长的列表，包含了所有软件的下载链接。
2.  `md5sums`：一个包含了所有文件 MD5 哈希值的文件，用来验证下载的文件是否损坏或被篡改。

#### 核心概念：为什么要验证 MD5？

  * **下载损坏**：网络波动可能导致下载的文件只有一半。如果拿这个坏文件去编译，可能跑了 1 小时后报错，非常浪费时间。
  * **安全风险**：验证哈希值能确保你拿到的代码和官方发布的一模一样，没有被黑客植入后门。

-----

### 🛠️ 任务三：编写自动下载与校验脚本

请编写脚本 `download_sources.sh`。

为了模拟真实环境，我们不需要真的去下载 80 个包（那太慢了），我们**模拟**下载 2 个关键的核心包：`binutils` 和 `gcc`。

**我负责提供“采购清单”素材：**

请在脚本最开始，使用我们学过的 `cat > ... <<EOF` 技术，在 `/mnt/lfs/sources` 下生成两个文件。

**文件 1：`wget-list`**

```text
https://ftp.gnu.org/gnu/binutils/binutils-2.43.1.tar.xz
https://ftp.gnu.org/gnu/gcc/gcc-14.2.0/gcc-14.2.0.tar.xz
```

**文件 2：`md5sums`**
*(注：这里为了模拟演示，你可以先假设这两个文件的 MD5 值。在脚本里我们先写个假的或者空的逻辑，或者真的去下载)*
为了让任务简单点，我们先**只做下载逻辑**。

**脚本需求：**

1.  **检查用户**：必须是 root（因为要写 `/mnt/lfs/sources`）。
2.  **检查目录**：确保 `/mnt/lfs/sources` 存在且可写。
3.  **生成清单**：
      * 切换目录到 `$LFS/sources` (使用 `cd $LFS/sources`)。
      * 使用 `Here Document` 生成上面的 `wget-list` 文件。
4.  **批量下载**：
      * 使用 `wget` 命令读取 `wget-list` 并下载。
      * **关键参数**：`wget --input-file=wget-list --continue --directory-prefix=$LFS/sources`
      * *提示：`--continue` (或 `-c`) 表示断点续传，如果下载了一半断了，下次接着下。*
5.  **模拟校验 (选做)**：
      * 虽然我们没有真的 md5sums 文件，但你可以写一行命令：
      * `md5sum * > generated_md5sums`
      * 意思是计算当前下载下来的文件的 MD5，并保存起来。

**特别挑战**：
由于国内网络连接 GNU 官网可能很慢。如果你发现下载不动，你的脚本可以只包含逻辑，不用真的等它下载完（按 Ctrl+C 中断）。或者，你可以把链接换成你可以快速访问的任意小文件的链接（比如百度的 logo），仅为了测试脚本逻辑。

**重点考察**：

  * `cd` 切换目录的使用。
  * `wget` 参数的正确组合。
  * 脚本在执行耗时操作（下载）时的交互提示。

请开始编写 `download_sources.sh`！


### 🛠️ 任务三（进阶版）：正式物资采购脚本

我们不需要手动把 80 个包的 URL 敲进 `cat >> wget-list` 里，LFS 官方提供了现成的列表文件。

我们将编写一个生产环境级别的 `download_full.sh`。

**脚本逻辑升级：**

1.  **获取官方清单**：直接用 `wget` 下载 LFS 官网提供的 `wget-list` 和 `md5sums` 文件。
2.  **更换高速镜像（关键技巧）**：使用 `sed` 命令，把列表里的慢速源（如 `ftp.gnu.org`）批量替换成国内或附近的镜像源（比如清华源、阿里源或 Kernel.org 的 CDN）。
3.  **完整下载**：执行批量下载。
4.  **完整校验**：下载完成后，利用 `md5sum -c` 命令一次性校验所有文件。

**请参考并运行以下代码（请根据你的网络情况决定是否开启镜像替换）：**

```bash
#!/bin/bash
set -e

# 1. 变量定义 (确保和之前保持一致)
export LFS=/mnt/lfs
SOURCES_DIR=$LFS/sources

# 检查是否为 root
if [ "${UID}" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

# 检查目录是否存在
if [ ! -d "$SOURCES_DIR" ]; then
    echo "目录 $SOURCES_DIR 不存在，请先运行 setup_disk.sh"
    exit 1
fi

# 给目录赋予由 sticky bit 权限（LFS 要求），允许所有用户写入
chmod -v a+wt $SOURCES_DIR

# 进入目录
pushd $SOURCES_DIR

echo "=== 1. 获取官方下载清单 ==="
# 注意：这里使用的是 LFS Systemd 12.2 (Stable) 的列表，你可以根据需要改版本
# 如果下载不下来，可以手动复制链接下载
wget https://www.linuxfromscratch.org/lfs/view/stable/wget-list --continue
wget https://www.linuxfromscratch.org/lfs/view/stable/md5sums --continue

echo "=== 2. (可选) 替换为高速镜像 ==="
# 这里的逻辑是：把列表里的 ftp.gnu.org 替换成 mirror.fcix.net (或者其他你喜欢的镜像)
# 很多包都在 gnu，这里替换能显著加速
sed -i 's|https://ftp.gnu.org/gnu/|https://mirrors.ustc.edu.cn/gnu/|g' wget-list
# 部分包在 sourceware
sed -i 's|https://sourceware.org/pub/|https://mirrors.ustc.edu.cn/sourceware/|g' wget-list

echo "=== 3. 开始批量下载 (请耐心等待) ==="
# -i 指定输入文件
# -c 断点续传
# -B 指定基础 URL (这里不需要，因为列表里是全路径)
wget --input-file=wget-list --continue --tries=3

echo "=== 4. 完整性校验 ==="
# grep -v 排除掉 MD5 文件本身的校验行（如果有的话）
# md5sum -c 自动读取文件里的哈希值和文件名进行比对
pushd $SOURCES_DIR
md5sum -c md5sums

# 统计校验结果
if [ $? -eq 0 ]; then
    echo "✅ 所有文件校验通过！物资准备完毕。"
else
    echo "❌ 有文件校验失败，请检查上方报错信息，并重新下载损坏的包。"
fi

popd
```

-----

### 💡 关于这一步的解释

1.  **`pushd` 和 `popd`**：
      * 这比 `cd` 更高级。`pushd` 会记录你原来的位置，等你做完事执行 `popd`，就自动回去了。这在脚本里防止“回不去家”很有用。
2.  **`chmod a+wt`**：
      * `a+wt` 意味着 **A**ll users (所有人) + **W**rite (写权限) + **T** (Sticky Bit 粘滞位)。
      * 这是 LFS 的标准要求。因为稍后我们会创建一个普通用户 `lfs`，我们需要让这个普通用户也能往 `/mnt/lfs/sources` 里写东西，但又不能删除别人的文件。
3.  **镜像替换**：
      * 这是实战经验。GNU 官网在国内（甚至全球部分地区）都非常慢。USTC（中科大）或 TUNA（清华）的镜像通常能跑满带宽。

-----

### ⏳ 现在的任务

**运行这个脚本（或者你自己编写的版本）。**

这可能需要一些时间（取决于你的网速，大概 500MB - 1GB 的数据）。

**当你的屏幕上出现 `✅ 所有文件校验通过！` 时，请告诉我。**

在那之后，我们将进入 **第四章：最后的准备工作**。我们将不再使用 `root` 身份，而是创建一个名为 `lfs` 的专属用户，开始构建我们的临时工具链！