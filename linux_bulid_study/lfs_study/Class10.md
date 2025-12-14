### 🚀 第十课：流水线作业 —— 临时工具的批量生产 (M4 & Ncurses)

恭喜你！随着 Libstdc++ 的完成，我们已经跨越了 LFS 最艰难的“死循环”阶段（编译器编译编译器）。现在的你，拥有了一套完整的、独立的交叉编译工具链：

  * **Binutils** (处理二进制)
  * **GCC + Glibc + Libstdc++** (编译 C/C++ 代码)

接下来，我们要进入 **LFS 第六章：交叉编译临时工具 (Cross Compiling Temporary Tools)**。

#### 1\. 这一章在做什么？

我们要利用刚才做好的工具链，编译出一系列基础软件（如 Bash, Coreutils, Make, Grep 等）。
这些软件将被安装在 `/tools` 目录下。
**目的**：构建一个**功能完备的微型 Linux 系统**（临时系统）。等这个系统完善了，我们就可以 `chroot` 进去，把它当作真正的系统来用。

#### 2\. 为什么叫“流水线”？

从现在开始，你会发现脚本逻辑变得**高度重复**：
`解压` -\> `mkdir build` -\> `configure` -\> `make` -\> `make install` -\> `清理`。

为了避免每一课都重复写几十行代码，我们要学习\*\*“通用构建模板”\*\*的思维。今天我们先拿两个简单的工具练手：**M4** 和 **Ncurses**。

  * **M4**：一个宏处理器，编译 Bison（语法分析器）时必须用它。
  * **Ncurses**：处理终端屏幕显示的库（比如 `menuconfig` 界面或 `nano` 编辑器都要用到它）。

-----

### 🛠️ 任务十：编译 M4 和 Ncurses

请编写脚本 `build_temp_tools_part1.sh`。

**脚本逻辑需求：**

1.  **准备工作**：(Root 生成 -\> LFS 运行)。

2.  **任务一：编译 M4**

      * **源码包**：`m4-1.4.19.tar.xz` (版本可能不同，以 ls 为准)。
      * **配置**：
        ```bash
        ./configure --prefix=/usr   \
                    --host=$LFS_TGT \
                    --build=$(build-aux/config.guess)
        ```
      * **安装**：`make DESTDIR=$LFS install`
      * *注意：M4 不支持在 build 目录外编译，直接在源码根目录编译即可。*

3.  **任务二：编译 Ncurses**

      * **源码包**：`ncurses-6.5.tar.gz`。
      * **预处理**：确保 `gawk` 能够被找到（LFS 环境中通常没问题，但为了保险）：
        `sed -i s/mawk// configure`
      * **创建构建目录**：`mkdir build` -\> `cd build`。
      * **配置** (参数较多，直接复制)：
        ```bash
        ../configure --prefix=/usr           \
                     --host=$LFS_TGT         \
                     --build=$(./config.guess) \
                     --mandir=/usr/share/man \
                     --with-manpage-format=normal \
                     --with-shared           \
                     --without-normal        \
                     --with-cxx-shared       \
                     --without-debug         \
                     --without-ada           \
                     --disable-stripping     \
                     --enable-widec
        ```
      * **安装**：
        `make`
        `make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install`
          * *解释*：`TIC_PATH` 是 Ncurses 特有的参数，用于指定编译好的 terminfo 编译器路径。
      * **修复库链接**：(Ncurses 的一个历史遗留问题，很多程序找 `libncurses.so` 但它生成的是 `libncursesw.so`)
        ```bash
        echo "INPUT(-lncursesw)" > $LFS/usr/lib/libncurses.so
        ```

4.  **清理**：

      * 每编译完一个，都要删除源码目录。

**💡 挑战**：
请尝试在一个脚本里连续完成这两个软件的编译。这能锻炼你处理“批量任务”的能力。

**请编写 `build_temp_tools_part1.sh`！**