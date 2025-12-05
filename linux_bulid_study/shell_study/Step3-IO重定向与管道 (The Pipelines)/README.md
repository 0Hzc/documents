### 第三阶段：I/O 重定向与管道 (The Pipelines)

恭喜你进入第三阶段！在 LFS 编译过程中，屏幕上会疯狂滚动成千上万行代码编译信息。

  * 如果我们想回头看哪里报错了，屏幕早就滚过去了。
  * 有些工具输出的“错误信息”其实不需要理会。
  * 我们需要把这些信息**抓取**下来保存到文件里。

这就是 **I/O 重定向** 的作用。

#### 1\. 三大“流” (Streams)

Linux 系统中，每个进程启动时都会打开三个文件描述符：

| 描述符 | 名称 | 缩写 | 用途 | 默认去向 |
| :--- | :--- | :--- | :--- | :--- |
| **0** | 标准输入 | `stdin` | 程序读取数据的地方 | 键盘 |
| **1** | 标准输出 | `stdout` | 程序打印正常结果的地方 | 屏幕终端 |
| **2** | 标准错误 | `stderr` | 程序打印报错信息的地方 | 屏幕终端 |

#### 2\. 重定向符号 (核心语法)

| 符号 | 作用 | LFS 场景 |
| :--- | :--- | :--- |
| `>` | **覆盖**输出到文件 | 生成新的配置文件：`echo "nameserver 8.8.8.8" > /etc/resolv.conf` |
| `>>` | **追加**输出到文件 | 添加日志：`echo "编译完成" >> build.log` |
| `2>` | 只重定向**错误**信息 | 忽略错误：`rm file_not_exist 2> /dev/null` |
| `2>&1` | **错误和正常输出合并** | 编译软件：`make > make.log 2>&1` (最常用！) |

> **关键解释 `2>&1`**：
> 它的意思是：“把**通道 2**（错误）接到**通道 1**（正常输出）上去”。这样所有的信息都会顺着通道 1 流入文件中。

使用2>&1要注意必须遵循`command >> file 2>&1` 同时注意file前后的空格

#### 3\. 管道 `|`

管道的作用是：**把上一个命令的输出 (`stdout`)，直接插到下一个命令的输入 (`stdin`) 嘴里。**

  * **例子**：`cat /etc/passwd | grep "root"`
      * `cat` 吐出文件内容 -\> `grep` 接收并过滤包含 "root" 的行。

-----



#### Here Document (`<<EOF`)

这是 LFS 手册中出现频率极高的一个语法。

**场景**：
在 LFS 构建中，你需要创建很多配置文件（比如 `/etc/fstab`，或者编写一个简单的 C 语言测试代码）。
如果每一行都用 `echo "..." >> file`，代码会变得非常难看且难以维护。

**解决方案：Here Document (免交互文档)**
它可以让你像在记事本里一样，一次性把多行内容写入文件。

##### 1\. 核心语法

```bash
cat > 文件名 << EOF
第一行内容
第二行内容
变量也是可以被解析的：${LFS}
EOF
```

  * `cat > 文件名`：表示我们要写入（覆盖）一个文件。
  * `<< EOF`：告诉 Shell，“从现在开始，我输入的每一行都是文件内容，直到你遇到 `EOF` 这个词为止”。
  * `EOF`：这是一个界定符（End Of File），其实你可以用任何词（比如 `END`、`STOP`），但 `EOF` 是约定俗成的标准。



代码编写得非常流畅！语法上完全没有错误，可以直接运行。

但是，作为一个未来的 LFS 开发者，我必须指出一个**极其隐蔽的“逻辑陷阱”**，这个问题在编写生成脚本（Generate Scripts）时经常发生。

###### 变量“提前”解析
```sh
LFS_TGT="x86_64-lfs-linux-gnu"
cat > lfs_profile <<EOF
export LFS=/mnt/lfs
export LC_ALL=POSIX
export LFS_TGT=${LFS_TGT}
export PATH=/tools/bin:$PATH
# End of profile
EOF
```
在 `<<EOF` 模式下，Shell 会尝试解析**所有**的变量。

  * `${LFS_TGT}` 被解析成 `x86_64...` -\> **这是我们要的**。
  * `$PATH` 也会被解析成**你当前系统（WSL）的 Path** -\> **这可能不是我们要的**。

**后果：**
生成的 `lfs_profile` 文件里，内容会变成死板的：
`export PATH=/tools/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin...`

如果不希望 `$PATH` 在生成时被解析，而是保持字面上的 `$PATH` 符号，让脚本在**未来运行时**再去读取当时的 PATH，你需要给 `$` 加转义符 `\`。

**修正版（LFS 最佳实践）：**

```bash
export PATH=/tools/bin:\$PATH  # 注意这里的反斜杠
```

这样生成的文件内容就会保留为：`export PATH=/tools/bin:$PATH`。

-----
##### 2\. LFS 实战演示

假设我们要自动生成一个 DNS 配置文件。

**普通写法 (累死人版)：**

```bash
echo "# DNS Config" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
```

**Here Doc 写法 (优雅版)：**

```bash
cat > resolv.conf << EOF
# DNS Config
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF
```

-----

### 🛠️ 任务三：模拟 LFS 编译日志系统

请编写脚本 `log_test.sh`，完成以下需求。这一次我们要重点练习如何把“报错信息”也抓进文件里。

**需求清单：**

1.  **定义变量**：
    * 定义日志文件路径变量 `LOG_FILE="build.log"`。
2.  **环境清理**：
    * 如果 `build.log` 已经存在，先删除它（使用 `rm -f`），确保我们每次运行都是从零开始记录。
3.  **第一步：覆盖写入 (Start)**
    * 输出字符串 `"=== 开始构建 LFS 环境 ==="`。
    * **要求**：这句话不能显示在屏幕上，必须**覆盖写入** (`>`) 到 `${LOG_FILE}` 中。
4.  **第二步：追加写入 (Progress)**
    * 输出字符串 `"正在下载源码包..."`。
    * **要求**：这句话不能显示在屏幕上，必须**追加写入** (`>>`) 到 `${LOG_FILE}` 中。
5.  **第三步：捕获错误 (The Tricky Part)**
    * 执行命令 `ls /bu_cun_zai_de_wen_jian` (这肯定会报错)。
    * **关键要求**：
        * 屏幕上**不能**出现任何报错信息。
        * 报错信息（比如 "No such file or directory"）必须被**追加**保存到 `${LOG_FILE}` 中。
        * *(提示：你需要结合 `>>` 和 `2>&1`，或者使用 `2>>`。建议尝试 `command >> file 2>&1` 这种标准写法)*。
6.  **验证结果**：
    * 最后，在屏幕上输出 `"脚本运行结束，以下是日志内容："`。
    * 使用 `cat` 命令显示 `${LOG_FILE}` 的内容。

**请编写并运行脚本，看看你能否成功“抓住”那个报错信息！**

### 🛠️ 任务四：自动化生成配置文件

我们在 LFS 中经常需要创建一个名为 `.bash_profile` 的环境配置文件。请编写脚本 `create_config.sh`，模拟这个过程。

**需求如下：**

1.  **定义变量**：`LFS_TGT="x86_64-lfs-linux-gnu"`。
2.  **使用 Here Document**：
      * 创建一个名为 `lfs_profile` 的文件。
      * 文件内容必须包含以下多行信息：
        ```text
        export LFS=/mnt/lfs
        export LC_ALL=POSIX
        export LFS_TGT=（这里请引用脚本开头定义的变量）
        export PATH=/tools/bin:$PATH
        # End of profile
        ```
3.  **验证**：
      * 脚本运行后，使用 `cat lfs_profile` 查看生成的文件内容。
      * **检查重点**：确认文件里的 `LFS_TGT` 是变成了具体的值（`x86_64...`），还是保留了变量名。

**开始吧！这是我们在进入“文本处理三剑客（Sed/Awk/Grep）”之前的最后一个基础技能。**