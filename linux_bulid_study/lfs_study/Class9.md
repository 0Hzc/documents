### 🚀 第九课：C++ 的基石 —— Libstdc++ (Pass 1)

**Glibc** 搞定后，C 语言的世界已经打通了。但 GCC 不仅是 C 编译器，它也是 C++ 编译器（G++）。
C++ 程序运行需要标准库支持，这就是 **Libstdc++**。

#### 1\. 特殊的身世

你可能会去下载列表中找 `libstdc++-xxx.tar.gz`，但你会发现**找不到**。

  * **真相**：Libstdc++ 是 GCC 的一部分，它的源码就藏在 **GCC 的源码包**里。
  * **操作逻辑**：我们需要**再次解压 GCC 源码包**，但这次我们**只编译里面的 Libstdc++ 模块**，不编译编译器本身。

#### 2\. 为什么要现在装？

我们在第六课（GCC Pass 1）中，虽然启用了 C++ 语言支持，但当时因为没有 Glibc，我们禁用了 `libstdc++`。现在有了 Glibc，我们必须把它补上，这样我们的临时工具链才完整。

-----

### 🛠️ 任务九：编译 Libstdc++

请编写脚本 `build_libstdcxx.sh`。

**脚本逻辑需求：**

1.  **准备工作**：(Root 生成 -\> LFS 运行)。

2.  **解压源码**：

      * **注意**：使用的是 `gcc-14.2.0.tar.xz`（和第六课用的是同一个包）。
      * 解压并进入目录。

3.  **创建构建目录**：

      * `mkdir -v build`
      * `cd build`

4.  **配置 (Configure) —— 重点参数解析**：

    ```bash
    ../libstdc++-v3/configure           \
        --host=$LFS_TGT                 \
        --build=$(../config.guess)      \
        --prefix=/usr                   \
        --disable-multilib              \
        --disable-nls                   \
        --disable-libstdcxx-pch         \
        --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/14.2.0
    ```

      * `../libstdc++-v3/configure`：注意路径！我们不是运行顶层的 configure，而是直接运行 `libstdc++-v3` 子目录下的配置脚本。
      * `--host=$LFS_TGT`：我们要编译的是给 LFS 系统用的库（交叉编译）。
      * `--prefix=/usr`：安装到 `$LFS/usr` 下。
      * `--disable-libstdcxx-pch`：禁用预编译头文件（Precompiled Headers），虽然能加快编译速度，但作为临时工具没必要，且容易出问题。
      * `--with-gxx-include-dir`：**关键！** 这告诉安装程序：“把 C++ 的头文件放到 `/tools/...` 下面去”。这样后续我们用交叉编译器 `$LFS_TGT-g++` 编译代码时，它能自动找到这些头文件。

5.  **编译与安装**：

      * `make`
      * `make DESTDIR=$LFS install`

6.  **清理**：

      * 删除解压的 `gcc` 目录。
      * 删除**所有** `.la` 文件（LFS 的一个洁癖习惯）：
        `rm -v $LFS/usr/lib/lib{stdc++,stdc++fs,supc++}.la`
          * *解释*：`.la` 是 libtool 的描述文件，在现代 Linux 系统中经常会导致库链接路径混乱，通常删了更安全。

-----

### 🔍 深度验证环节 (请写入脚本或手动执行)

脚本执行完毕后，请务必进行以下验证：

1.  **验证库文件是否存在**：

    ```bash
    ls -l $LFS/usr/lib/libstdc++.so.6
    ```

      * **预期**：应该显示文件信息（通常是一个软链接指向具体的版本号）。

2.  **验证头文件位置 (至关重要)**：
在 lfs 用户 下手动运行以下这段代码，确认你的交叉编译器是健康的：

    ```bash
      echo "---------------------------------------------------"
      echo "🔍 正在进行深度验证..."

      # 验证 1: C++ 头文件是否安装到了 /tools
      # 这一点至关重要，交叉编译器去这里找头文件
      if [ -d "$LFS/tools/$LFS_TGT/include/c++/14.2.0" ]; then
      echo "✅ [1/2] C++ 头文件路径正确 (/tools/...)"
      else
      echo "❌ [1/2] 失败：头文件未安装到 /tools 下！"
      exit 1
      fi

      # 验证 2: 终极测试 - 尝试编译一个 C++ 小程序
      echo 'int main(){}' > dummy.cxx
      if $LFS_TGT-g++ dummy.cxx -o dummy; then
      echo "✅ [2/2] 终极测试：交叉编译器成功编译 C++ 代码！"
      rm dummy dummy.cxx
      else
      echo "❌ [2/2] 失败：交叉编译器无法编译 C++ 代码。"
      exit 1
      fi
      echo "---------------------------------------------------"

    ```
      * **原因**：如果这里的路径错了，后面编译 C++ 程序时会报 `iostream: No such file or directory`。

**请编写 `build_libstdcxx.sh`。** 这步通常比较快（比起编译整个 GCC）。