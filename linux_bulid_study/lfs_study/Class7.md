### 🏛️ 第七课：打通任督二脉 —— Linux API Headers

这一步相对简单，不需要编译整个 Linux 内核（那要等到最后），我们只需要从内核源码里“抠”出头文件，放到 `/tools/include` 下，供后续的 Glibc 使用。

#### 核心概念：Sanitized Headers (净化的头文件)
Linux 内核源码里有很多头文件是给内核开发者用的，普通应用程序（用户态）看不懂，甚至引用了会报错。
我们需要运行一个特殊的命令 `make headers`，让内核帮我们清洗出一份**“给应用程序看”**的标准接口头文件。

---

### 🛠️ 任务七：安装 Linux API Headers

请编写脚本 `install_linux_headers.sh`。

**素材准备**：
你需要找到 `linux-6.x.x.tar.xz` (具体版本看你的 `sources` 目录，通常是 LFS 列表里的版本)。

**脚本逻辑需求**：

1.  **准备工作**：(老规矩：Root 生成 -> LFS 运行)。
2.  **解压**：
    * 进入 `$LFS/sources`。
    * 解压 Linux 内核源码包。
    * 进入目录。
3.  **清理环境 (Clean)**：
    * 即使是刚解压的，官方建议先运行 `make mrproper`。
    * *作用：清除所有之前的编译配置，确保环境绝对干净。*
4.  **提取头文件 (Make Headers)**：
    * 执行命令：`make headers`。
    * 这一步不会编译内核，只会生成头文件。
5.  **安装头文件 (Install)**：
    * LFS 这里的操作有点特殊，我们不能直接 `make install`（那样会装到宿主机去）。
    * 我们需要手动把生成的头文件复制到 `/mnt/lfs/usr/include`（注意：是目标系统的 `/usr/include`，虽然我们现在还在 `/tools` 阶段，但 LFS 12.x 建议直接放到 `$LFS/usr` 下供 Glibc 使用）。
    * **更正**：根据最新的 LFS 12.2 手册，Linux Headers 应该安装到 `$LFS/usr/include`。
    * **操作步骤**：
        1.  找到生成的头文件（通常在 `usr/include` 目录下）。
        2.  使用 `find` 命令清理掉不需要的隐藏文件（`.` 开头的文件）。
            * `find usr/include -type f ! -name '*.h' -delete`
        3.  把 `usr/include` 里的所有内容复制到 `$LFS/usr/include`。
            * `cp -rv usr/include $LFS/usr`
            * *(注意：如果 `$LFS/usr` 不存在，你需要先 `mkdir -p $LFS/usr`)*。
6.  **清理**：
    * 删除源码目录。

**⚠️ 特别注意**：
这一步非常快，可能只需要几秒钟到一分钟。它主要是在做文件复制。

**请编写脚本 `install_linux_headers.sh`。**
(提示：在使用 `find` 和 `cp` 时，路径要写对，特别是源目录 `usr/include` 是在源码包里的相对路径)。