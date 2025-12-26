#!/bin/bash
set -e
# 注意：这个命令是在 WSL 宿主机终端执行的！
# 确保 LFS 变量存在
export LFS=/mnt/lfs
mkdir -pv $LFS/root

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
chmod +x $LFS/root/init_chroot_system.sh
echo "执行完毕"