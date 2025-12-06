# 此文档记录从零构建linux实操部分

## Step1
### 下载工具包
```bash
sudo apt install bash binutils bison bzip2 coreutils diffutils findutils gawk gcc glibc grep gzip m4 make patch perl python sed tar texinfo xz
```

### 创建文件夹、脚本
```bash
# 创建一个名为lfs(Linux From Scratch)的新用户 
mkdir lfs
cd lfs
mkdir Programming
cd Programming
mkdir LFS

# 在/lfs/Programming/LFS下创建脚本
# 
touch lfs.sh

# 创建格式化硬盘并创建分区的脚本
touch setupdisk.sh
touch versioncheck.sh
touch download.sh
```

### 编辑脚本内容
#### 编辑lfs.sh脚本内容
```sh
#!/bin/bash
export LFS=/mnt/lfs
export LFS_TGT=x86_64-lfs-linux-gnu
export LFS_DISK=/dev/sdb

if ! grep -q "$LFS" /proc/mounts;
    source setupdisk.sh "$LFS_DISK"
    sudo mount "${LFS_DISK}2" "$LFS"
    sudo chown -v $USER "$LFS"
fi


mkdir -pv $LFS/sources
mkdir -pv $LFS/tools

mkdir -pv $LFS/boot
mkdir -pv $LFS/etc
mkdir -pv $LFS/bin
mkdir -pv $LFS/lib
mkdir -pv $LFS/sbin
mkdir -pv $LFS/usr
mkdir -pv $LFS/var

case $(uname -m) in
    x86_64) mkdir -pv $LFS/lib64 ;;
esac
fi
```
分析：
---
- #!/bin/bash  指定该脚本用 bash 解释器执行。是 Linux shell 脚本的标准开头。
---
- 定义一个变量'LFS'，并将其设置为挂载点路径
"LFS=/mnt/lfs"
考虑到后续会在子shell中运行某些命令，将'lfs'变量导出
"export LFS=/mnt/lfs"
---

- 定义一个变量'LFS_TGT'，表示目标系统的三元组，含义是构建一个64位的基于GNU的Linux系统
---

- 定义并导出环境变量 LFS_DISK，指定要操作的磁盘设备，sdb为插入的U盘的名字

---

- 在linux终端中使用cat /proc/mounts 可以查看已经挂载的文件系统
- grep -q "$LFS" /proc/mounts 表示在 /proc/mounts 文件中静默（-q）查找 $LFS 这个挂载点
- 如果 grep 没有找到 $LFS，返回非零（假），加上 ! 取反后，if 判断为真，说明 $LFS 没有被挂载。
- source setupdisk.sh "$LFS_DISK" ：如果上面条件成立（即 $LFS 没有挂载），则用 source 命令加载并执行 setupdisk.sh 脚本，并传递 $LFS_DISK 作为参数。source 的作用是“在当前 shell 环境中执行脚本”，这样脚本中设置的变量等会影响当前 shell，而不是新开一个子 shell
- fi：if 的结尾，表示 if 语句块结束。fi 是 if 的反写，是 shell 脚本的语法。

---

#### 编写setupdisk.sh脚本内容
```sh
LFS_DISK="$1"

sudo fdisk "$LFS_DISK" << EOF
o
n
p
1

+100M
a
n
p
2


p
w
q
EOF

sudo mkfs -t ext2 -F "${LFS_DISK}1"
sudo mkfs -t ext2 -F "${LFS_DISK}2"
```
此部分内容不做过多解释，将fdisk使用自动化，且该脚本需实操验证

### 疑问点1
上述step1的所有内容均为阅读Linux from scratch system相关视频的操作步骤，主题内容是准备U盘并完成分区，
我的疑问是：从内容上给来看，大致内容和行为就是创建了文件系统以及格式化硬盘作为挂载目录、我想知道这些操作是在设备A上进行的吗？
场景是：以使用U盘为例，将U盘插入设备A，然后在A设备上下载工具包、创建文件夹、脚本，其中创建的文件夹是在我A设备的任何文件夹下创建即可吗？还是在U盘所在文件夹？如果是在U盘所在文件夹，编写的脚本中存在格式化U盘的操作，那理论上就是在A设备的某个路径下进行step1的操作对吗？

你的疑问总结如下：  
1. 这些操作（如分区、格式化、挂载等）是在设备A上进行的吗？  
2. 创建的文件夹是在A设备的任何文件夹下创建即可，还是必须在U盘上？  
3. 如果是在U盘上，脚本中有格式化U盘的操作，那理论上是在A设备的某个路径下进行step1的操作对吗？

详细解答如下：
---
#### 1. 操作是在设备A上进行的吗？
是的，所有操作（包括分区、格式化U盘、挂载、创建文件夹、编写脚本等）都是在设备A（你的主机）上进行的。U盘只是作为目标存储介质插入到设备A。
#### 2. 文件夹创建位置
- **脚本、工具包、初始文件夹**（如 lfs.sh、setupdisk.sh、sources、tools 等）可以在A设备的任意目录下创建，比如你的主目录、桌面、或你喜欢的工作目录。
- 只有在脚本执行到“挂载U盘分区到 $LFS（如 /mnt/lfs）”之后，后续的 LFS 系统相关目录（如 $LFS/sources、$LFS/tools、$LFS/boot 等）才会被创建到 U盘的分区上（即 /mnt/lfs 目录实际上对应U盘的分区）。
#### 3. 格式化U盘与操作路径
- 格式化U盘的操作（setupdisk.sh）确实会清空U盘上的所有数据，这一步是在A设备上执行的，目标是U盘（如 /dev/sdb）。
- 你在A设备的任意目录下准备和运行这些脚本都可以，只要脚本中指定的设备名（如 /dev/sdb）是你插入的U盘。
- 当你执行 `sudo mount "${LFS_DISK}2" "$LFS"` 后，$LFS（如 /mnt/lfs）就指向了U盘的第二分区。此后在 $LFS 下创建的文件夹和文件，实际都写入U盘分区。
#### 场景总结
- 你在A设备上插入U盘，U盘被识别为 /dev/sdb。
- 你在A设备的任意目录下准备脚本和工具。
- 运行脚本时，脚本会自动分区、格式化U盘，并挂载到 /mnt/lfs。
- 之后所有在 $LFS 下的操作，实际都在U盘分区上进行。
#### 重点提醒
- **一定要确认 /dev/sdb 是你的U盘，否则会误格式化其他硬盘！**
- 脚本和初始准备工作可以在A设备任意目录下进行，不影响最终LFS系统的构建。

### 疑问点2
对于linux操作系统，结合lfs.sh脚本内容，我想知道/mnt/lfs这个路径很重要吗？
在我的印象里，安装好的linux操作系统的根目录是/ ，它与/mnt/lfs有什么关系呢？我发现后续脚本中很多地方都是直接使用的LFS这个变量的值，也就是/mnt/lfs这个路径，之后再这个路径下进行创建linux文件夹系统，难道说/mnt/lfs就是安装好的linux的/目录吗？

详细解答如下：
---
#### /mnt/lfs 路径的作用
- /mnt/lfs 只是你当前主机（设备A）上的一个普通挂载点目录，通常用来挂载U盘或硬盘的某个分区。
- 在 LFS（Linux From Scratch）构建过程中，/mnt/lfs 作为“新系统的根目录”来使用。你所有的 LFS 构建操作（如创建 /boot、/etc、/bin 等目录）其实都是在 /mnt/lfs 这个路径下进行的。
#### /mnt/lfs 和 / 的关系
- / 是你当前主机（设备A）正在运行的 Linux 系统的根目录。
- /mnt/lfs 是你为“新构建的LFS系统”准备的一个临时根目录。你在 /mnt/lfs 下搭建的其实是另一个全新的 Linux 系统的根目录结构。
- 当你后续 chroot 或真正用U盘启动时，/mnt/lfs 里的内容就会变成新系统的 /（根目录）。
#### 为什么脚本里大量用 $LFS（/mnt/lfs）
- 这样可以确保所有新系统的文件都被正确地放到U盘分区（/mnt/lfs）下，而不会污染当前主机的系统。
- 只有等你完成所有构建、并 chroot 进 $LFS 或用U盘启动时，/mnt/lfs 里的内容才会成为新系统的 /。
#### 总结
- /mnt/lfs 只是主机上的一个挂载点，是“新系统的临时根目录”。
- 你在 /mnt/lfs 下搭建的目录结构，最终会成为新LFS系统的根目录（/）。
- 当前主机的 / 和 /mnt/lfs 是两个完全独立的目录树。

所以，/mnt/lfs 在LFS构建过程中非常重要，但它只是“新系统的根目录的临时代表”。等你真正用U盘启动LFS时，/mnt/lfs 里的内容就会变成新系统的 / 了。