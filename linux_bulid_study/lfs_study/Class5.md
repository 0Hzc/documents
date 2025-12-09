

-----

### 🚀 第五章：构建临时系统 (Constructing a Temporary System)

现在，我们以 `lfs` 用户的身份，站在了起跑线上。
我们要开始**第五章**的学习。这是 LFS 旅程中第一次真正的“编译”。

#### 宏观概念：鸡生蛋，蛋生鸡

我们要构建一个编译器（GCC），但构建编译器本身又需要一个编译器。
我们现在的策略是：**用宿主机的旧 GCC，编译出一个“跨平台”的新 GCC。**

这个过程分为两轮（Pass 1 和 Pass 2）：

1.  **Pass 1**：编译出一套与宿主系统隔离的工具链（Binutils, GCC, Linux Headers）。
2.  **Pass 2**：用刚才编译出来的工具链，再编译一遍自己和基础库（Glibc）。这是为了彻底切断与宿主机的联系。

今天，我们只做 **第一轮的第一步：编译 Binutils (Pass 1)**。

#### 为什么要先编译 Binutils？

Binutils 包含链接器 (`ld`) 和汇编器 (`as`)。GCC 编译出代码后，必须靠它们才能变成可执行文件。所以，**它是编译器的基石，必须第一个装。**

-----

### 🛠️ 任务五：编译 Binutils (Pass 1)

这是一个极其标准的源码编译流程，所有的 LFS 软件包安装都遵循这个**黄金三部曲**：

1.  **解压** (`tar`)。
2.  **配置** (`configure`)。
3.  **编译与安装** (`make` & `make install`)。

**请编写脚本 `build_binutils_pass1.sh`。**

**⚠️ 关键规则（一定要遵守）：**

1.  **身份**：脚本不需要 `sudo`！必须以 `lfs` 用户身份运行（因为我们要往 `/mnt/lfs/tools` 写东西，而这个目录已经是 lfs 的了）。
2.  **独立目录**：LFS 这里的编译有一个特殊要求 —— **不要在源码目录里直接编译**。要创建一个 `build` 文件夹，进去编译。

**脚本需求：**

1.  **变量准备**：
      * 确保 `LFS` 变量存在（`source ~/.bashrc` 或依赖环境）。
      * 定义 `LFS_TGT` 变量（虽然环境里有，显式定义更安全）。
2.  **解压**：
      * 进入 `$LFS/sources`。
      * 解压 `binutils-2.43.1.tar.xz` (或你下载的版本)。
      * 进入解压后的目录。
3.  **创建构建目录**：
      * `mkdir -v build`
      * `cd build`
4.  **配置 (Configure) —— 最硬核的部分**：
    我们需要执行 `../configure` 脚本，并带上一堆参数。
    请原样使用以下参数，并**尝试思考** `Running Configure` 这一步是在干什么：
    ```bash
    ../configure --prefix=/tools \
                 --with-sysroot=$LFS \
                 --target=$LFS_TGT \
                 --disable-nls \
                 --enable-gprofng=no \
                 --disable-werror
    ```
      * `--prefix=/tools`：告诉它安装到 `/tools` 去（而不是默认的 /usr/local）。
      * `--target=$LFS_TGT`：**核心参数**。告诉它：“你要把自己变成一个能处理 `x86_64-lfs-linux-gnu` 格式代码的工具”，这就是交叉编译。
5.  **编译 (Make)**：
      * 执行 `make`。
      * *(可选技巧：`make -j4` 利用你的 4 核 CPU 加速)*。
6.  **安装 (Install)**：
      * 执行 `make install`。
7.  **清理现场 (Cleanup)**：
      * 回到 `$LFS/sources`。
      * 删除解压出来的源码目录 `rm -rf binutils-2.43.1`。
      * *LFS 习惯：保持 source 目录干净，每次装完就删掉源码文件夹，只留压缩包。*

**这个脚本将是你编译的第一个软件。请编写并尝试运行它！**
*(如果编译过程满屏乱跳代码，不用慌，只要最后没有 `Error` 且脚本正常结束就是成功)*