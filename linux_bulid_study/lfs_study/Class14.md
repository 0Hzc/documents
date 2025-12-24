### 🏛️ 第十四课：构建骨架 —— 目录树与核心配置 (Creating Directories & Essential Files)

现在的 `/mnt/lfs` (也就是现在的 `/`) 里虽然有了 `bin`, `lib`, `usr`，但作为一个标准的 Linux 系统，它还缺胳膊少腿。

* **缺目录**：没有 `/home`，没有 `/root`，没有 `/tmp`，没有 `/proc`（虽然挂载了但目录结构可能不完整）。
* **缺身份**：系统不知道谁是 `root`，谁是 `users`。如果你现在运行 `ls -l`，看到的可能只是数字 ID 而不是用户名。

#### 🛠️ 任务十四：系统初始化脚本

为了保持自动化的优良传统，我们将编写一个脚本 `init_chroot_system.sh`。

**⚠️ 执行方式发生了改变**：

1. **编写位置**：你依然在 **宿主机** 的终端里（你可以开一个新的 WSL 窗口，或者暂时 `exit` 退出 chroot 来写脚本，但我建议开新窗口）。
2. **投送**：把脚本写到 `$LFS/root/` 目录下。
3. **运行**：回到你的 **Chroot 窗口**，运行这个脚本。

**请在宿主机（WSL）编写以下脚本：**

```bash
# 注意：这个命令是在 WSL 宿主机终端执行的！
# 确保 LFS 变量存在
export LFS=/mnt/lfs

cat > $LFS/root/init_chroot_system.sh << "EOF"
#!/bin/bash
set -e

echo "=== 1. 创建标准目录结构 (FHS 标准) ==="
mkdir -pv /{boot,home,mnt,opt,srv}
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

# 创建 /run 的链接 (为了兼容性)
ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

# 只有 root 才能写的目录，权限设为 0750 或 1777
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

echo "=== 2. 创建核心用户与组文件 ==="
# 创建 /etc/passwd
cat > /etc/passwd << "ETCPASSWD"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/bin/false
systemd-network:x:76:76:systemd Network Management:/:/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/bin/false
systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
ETCPASSWD

# 创建 /etc/group
cat > /etc/group << "ETCGROUP"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
audio:x:9:
dialout:x:10:
video:x:11:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
uuidd:x:80:
systemd-oom:x:81:
wheel:x:97:
nogroup:x:99:
users:x:999:
ETCGROUP

echo "=== 3. 初始化日志文件 ==="
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

echo "🎉 系统骨架初始化完成！"
EOF

# 给脚本可执行权限
chmod +x $LFS/root/init_chroot_system.sh

```

---

#### 🏃‍♂️ 执行步骤

1. **在宿主机**：运行上面的代码块，生成脚本。
2. **切换到 Chroot 窗口**（你应该还停留在 `(lfs chroot) root:/#`）。
3. **运行脚本**：
```bash
/root/init_chroot_system.sh

```


4. **验证效果**：
* 运行 `ls -l /root`。
* **关键变化**：刚才你看到的可能是 `0` (数字 ID)，现在应该能看到用户名 `root` 了！因为系统有了 `/etc/passwd`，终于认识你是谁了。



**请执行并告诉我结果！这个脚本跑完，你的 LFS 就正式有了“户口本”和“房子结构”。**