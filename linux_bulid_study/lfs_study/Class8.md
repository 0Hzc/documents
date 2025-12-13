### 🚀 第八课：系统的心脏 —— Glibc (The GNU C Library)

现在，我们迎来了 **LFS 构建初期最关键、最惊险的一战**。

#### 1\. 为什么 Glibc 是“心脏”？

如果说 Linux 内核是**大脑**（负责指挥硬件），GCC 是**建筑师**（负责造房子），那么 Glibc 就是**地基和砖块**。

  * 你在 C 语言里写的 `printf`、`malloc`、`open`、`exit`，全都是 Glibc 提供的。
  * **没有 Glibc，Linux 上 99% 的程序都跑不起来。**
  * 我们接下来要编译的所有软件（包括 Bash, Make, Tar 等），都要“链接”到这个 Glibc 上。

#### 2\. 这一步的特殊性

  * **打补丁 (Patching)**：Glibc 非常古老且固执，它默认假定自己安装在 `/usr` 下。为了让它乖乖安装在我们的 `$LFS` 目录下并符合 FHS（文件系统层次标准），我们需要给它打一个补丁。
  * **DESTDIR 安装**：我们不能直接 `make install`（那会试图写入宿主机的 `/usr/lib`，然后因为权限不足报错，或者更糟——覆盖宿主机的库）。我们需要使用 `make DESTDIR=$LFS install`，把它“重定向”到 `/mnt/lfs` 里。

-----

### 🛠️ 任务八：编译 Glibc

请编写脚本 `build_glibc.sh`。

**脚本逻辑需求：**

1.  **准备工作**：(Root 生成 -\> LFS 运行)

Glibc 安装需要 etc 和 var 目录，且 lfs 用户需要有写入权限

      ```bash
      mkdir -p ${LFS}/lib64
      mkdir -p ${LFS}/etc
      mkdir -p ${LFS}/var
      mkdir -p ${LFS}/usr/bin
      mkdir -p ${LFS}/usr/lib
      mkdir -p ${LFS}/usr/sbin
      ```
确保 lfs 用户有权写入这些目录

      ```bash
      chown -R lfs:lfs ${LFS}/lib64
      chown -R lfs:lfs ${LFS}/etc
      chown -R lfs:lfs ${LFS}/var
      chown -R lfs:lfs ${LFS}/usr
      ```

对于 Glibc 的编译和安装，除了上述目录外，主要依赖：

$LFS/usr/include：这是 Linux 内核头文件，你应该在之前的步骤（Class7）中已经安装好了。
$LFS/tools 或 $LFS/usr：交叉编译器（Binutils, GCC）应该已经安装在这里，并且 $LFS_TGT 环境变量配置正确

2.  **创建必要的符号链接 (LSB Compliance)**：

      * Glibc 编译时会检查系统是否符合 LSB 标准。在 64 位系统上，它需要一个指向动态链接器的符号链接。
      * **在 Configure 之前**，需要执行以下逻辑（LFS 手册强行要求的）,在步骤5之前执行下面命令：

    <!-- end list -->

    ```bash
    case $(uname -m) in
        i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-linux.so.2 ;;
        x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64 ;;
    esac
    ```

      * *注意：这步操作通常需要先 `mkdir -p $LFS/lib64`（如果不存在）。*

3.  **解压与打补丁**：

      * 解压 `glibc-2.40.tar.xz`。
      * 进入目录。
      * **打补丁**：`patch -Np1 -i ../glibc-2.40-fhs-1.patch`
      * *解释*：`-N` (忽略已打过的补丁), `-p1` (忽略路径中的第一层目录), `-i` (指定补丁文件)。

4.  **创建构建目录**：

      * `mkdir -v build`
      * `cd build`

5.  **配置 (Configure) —— 仔细核对！**

    ```bash
    echo "rootsbindir=/usr/sbin" > configparms

    ../configure                             \
          --prefix=/usr                      \
          --host=$LFS_TGT                    \
          --build=$(../scripts/config.guess) \
          --enable-kernel=4.19               \
          --with-headers=$LFS/usr/include    \
          --disable-nscd                     \
          libc_cv_slibdir=/usr/lib
    ```

      * `configparms`：强制将 sbin 目录设为 `/usr/sbin`。
      * `--prefix=/usr`：告诉 Glibc “将来”你会住在 `/usr` 里。
      * `--host=$LFS_TGT`：使用我们之前做的交叉编译器 GCC。
      * `--with-headers`：**关键！** 指向我们在上一课（第七课）安装的头文件。

6.  **编译与安装**：

      * `make -j$(nproc)`
      * `make DESTDIR=$LFS install`
      * *解释*：`DESTDIR=$LFS` 结合 `--prefix=/usr`，最终文件会落到 `$LFS/usr` 下。

7.  **后续修正 (Fixes)**：

      * **修正 `ldd` 脚本**：Glibc 安装了一个 `ldd` 脚本（用来查看程序依赖库），但脚本里的路径写死了。我们需要把路径修正。

    <!-- end list -->

    ```bash
    sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd
    ```

      * **安装 Locale (语言环境)**：虽然是临时系统，装一部分 locale 可以避免后续很多警告。我们为了省事，这次可以先**跳过** locale 的安装（LFS 交叉工具链阶段通常不装 locale，节省时间）。

8.  **验证**：

      * 检查 `$LFS/usr/lib/libc.so.6` 是否存在。不要尝试运行它，而是检查它的文件属性。
      * 检查文件是否存在及大小：`ls -lh /mnt/lfs/usr/lib/libc.so.6` 
       - 预期结果：应该看到文件存在，大小约为 10MB+，且属于 lfs 用户。
      * 检查文件类型：`file /mnt/lfs/usr/lib/libc.so.6` 
       - 预期结果：应该显示 ELF 64-bit LSB shared object, x86-64...。



**挑战**：Glibc 的编译时间比 GCC 还要长一点，而且对环境非常敏感。请务必确保刚才的 Linux Headers 安装正确。

**请编写并运行 `build_glibc.sh`。祝你好运！**