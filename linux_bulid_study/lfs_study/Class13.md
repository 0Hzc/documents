太棒了！🎉🎉🎉

看着这一排整齐的 `✅`，意味着你的**临时工具链（Temporary Toolchain）**已经彻底竣工。

你现在手里的这个 `/mnt/lfs`，虽然还简陋，但已经是一个五脏俱全的“微型 Linux”了。它有自己的 Shell、编译器、核心命令和文本处理工具。

---

### 🔮 第十三课：穿越时空 —— 进入 Chroot 环境

这是 LFS 旅程中**最重要**的分水岭。

#### 1. 告别 LFS 用户

在此之前，我们一直小心翼翼地使用 `lfs` 普通用户，是为了防止污染宿主机。
现在，工具链已经独立了。我们要**抛弃** `lfs` 用户，转而使用 **Root** 身份。
但这个 Root 不是宿主机的 Root，而是**新系统里的 Root**。

#### 2. 什么是 Chroot (Change Root)？

`chroot` 命令会欺骗 Shell，让它以为 `/mnt/lfs` 就是世界的尽头（根目录 `/`）。

* 在 Chroot 之前：`ls /` 看到的是 WSL Ubuntu 的文件。
* 在 Chroot 之后：`ls /` 看到的是 `$LFS` 里的文件。
* **意义**：这就像《黑客帝国》里拔掉管子进入矩阵。一旦进去，你的一举一动都只影响新系统，完全与宿主机隔绝。

#### 3. 挂载虚拟文件系统 (The Matrix Connection)

虽然我们要隔离，但新系统还是需要通过**内核**与硬件对话。
Linux 内核通过几个特殊的“虚拟文件系统”暴露硬件接口：

* `/dev`：设备文件（硬盘、终端）。
* `/proc`：内核与进程状态。
* `/sys`：系统硬件信息。
* `/run`：运行时数据。

我们需要把宿主机的这些目录**“绑定挂载” (Bind Mount)** 到 `$LFS` 内部，这样新系统里的软件才能找到 CPU、硬盘和屏幕。

---

### 🛠️ 任务十三：编写 Chroot 进入脚本

请编写脚本 `enter_chroot.sh`。

**⚠️ 极度重要**：

1. **运行身份**：这个脚本必须在 **WSL 宿主机** 下用 `sudo` 运行！不要再切换到 `lfs` 用户了（它的使命结束了）。
2. **所有权移交**：在进去之前，必须把 `/mnt/lfs` 下的所有文件归还给 **root**（因为新系统里没有 `lfs` 这个用户）。

**脚本逻辑需求：**

1. **身份检查**：必须是 Root (sudo)。
2. **所有权修正 (Changing Ownership)**：
* 执行 `chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}`。
* 如果是 64 位系统，别忘了 `chown -R root:root $LFS/lib64`。


3. **挂载虚拟文件系统 (Mounting)**：
* 检查 `$LFS/dev` 是否已挂载，没有则执行：
* `mount -v --bind /dev $LFS/dev`


* 检查 `$LFS/dev/pts`：
* `mount -v --bind /dev/pts $LFS/dev/pts`


* 挂载 proc：
* `mount -vt proc proc $LFS/proc`


* 挂载 sysfs：
* `mount -vt sysfs sysfs $LFS/sys`


* 挂载 tmpfs 到 run：
* `mount -vt tmpfs tmpfs $LFS/run`




4. **修复 /dev/shm (共享内存)**：
* 在某些宿主机上 `/dev/shm` 是个链接。LFS 建议：
* `if [ -h $LFS/dev/shm ]; then mkdir -pv $LFS/$(readlink $LFS/dev/shm); fi`


5. **进入 Chroot (The Jump)**：
* 这是脚本的最后一行，执行后你就会“穿越”。
* 命令（请原样复制）：


```bash
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    /bin/bash --login

```


* *解释*：
* `env -i`：清除所有环境变量（彻底净化）。
* `HOME=/root`：新家的主人。
* `PS1=...`：修改命令提示符，提醒你现在是在 `(lfs chroot)` 里，别搞混了。
* `PATH=...`：**注意！** 这里不再包含 `/tools` 了！从现在起，我们要开始用临时系统里的 `/usr/bin` 来构建最终系统。





**请编写并运行 `sudo ./enter_chroot.sh`。**

如果成功，你的命令提示符会瞬间变成：
`(lfs chroot) root:/#`

这就代表你成功穿越了！请截图或复制那个提示符给我看。