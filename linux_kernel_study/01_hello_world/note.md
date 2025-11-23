# 

# wsl2内核模块编译环境搭建
在 WSL2 环境下编译内核模块时遇到错误：
```
make: *** /lib/modules/6.6.87.2-microsoft-standard-WSL2/build: No such file or directory. Stop.
```
**原因**：WSL2 使用微软定制的内核，默认不包含编译外部内核模块所需的头文件和构建系统。

### 1. 安装必要的编译工具

```bash
sudo apt update
sudo apt install -y build-essential flex bison libssl-dev libelf-dev bc dwarves
```

### 2. 下载 WSL2 内核源码

**方法**：从 GitHub 下载对应分支的 zip 文件

- 访问：https://github.com/microsoft/WSL2-Linux-Kernel
- 切换到分支：`linux-msft-wsl-6.6.y`（根据你的内核版本选择）
- 下载 zip 文件并上传到 WSL2

**查看当前内核版本**：
```bash
uname -r
# 输出示例：6.6.87.2-microsoft-standard-WSL2
```

### 3. 解压并进入内核源码目录

```bash
cd ~
unzip -q WSL2-Linux-Kernel-linux-msft-wsl-6.6.y.zip
cd WSL2-Linux-Kernel-linux-msft-wsl-6.6.y
```

### 4. 配置内核

```bash
# 使用当前运行内核的配置
zcat /proc/config.gz > .config

# 更新配置（会提示一些新选项）
make oldconfig
```

**配置选项建议**：
- `Mitigate Straight-Line-Speculation (SLS)` → 输入 `n`
- `Memory initialization` → 输入 `1`（选择 no automatic initialization）
- 其他新选项直接按回车接受默认值

### 5. 准备内核构建环境

```bash
# 准备构建环境
make prepare

# 构建编译脚本
make scripts
```

### 6. 构建模块支持

```bash
# 准备模块编译环境
make modules_prepare

# 编译内核模块以生成 Module.symvers（耗时较长，10-20分钟）
make ARCH=x86_64 modules -j$(nproc)
```

**注意**：`make modules` 会编译所有内核模块，生成 `Module.symvers` 文件，这是后续编译外部模块所必需的。

### 7. 创建符号链接

```bash
# 创建模块目录
sudo mkdir -p /lib/modules/$(uname -r)

# 创建指向内核源码的符号链接
sudo ln -sf ~/WSL2-Linux-Kernel-linux-msft-wsl-6.6.y /lib/modules/$(uname -r)/build
```

**验证链接**：
```bash
ls -la /lib/modules/$(uname -r)/build
# 应显示指向内核源码目录的符号链接
```

---

## 编译内核模块

###  创建 Makefile

```makefile
obj-m += my_kernel.o

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
```

**重要提醒**：
- `all:` 和 `clean:` 后面的缩进**必须使用 Tab 键**，不能使用空格
- `obj-m` 中的 `.o` 文件名要与 `.c` 源文件名对应

###  编译模块

```bash
# 清理旧的编译文件
make clean

# 编译
make
```

**成功输出示例**：
```
make[1]: Entering directory '/home/ubuntu/WSL2-Linux-Kernel-linux-msft-wsl-6.6.y'
  CC [M]  /home/ubuntu/linux_kernel_study/my_kernel.o
  MODPOST /home/ubuntu/linux_kernel_study/Module.symvers
  CC [M]  /home/ubuntu/linux_kernel_study/my_kernel.mod.o
  LD [M]  /home/ubuntu/linux_kernel_study/my_kernel.ko
make[1]: Leaving directory '/home/ubuntu/WSL2-Linux-Kernel-linux-msft-wsl-6.6.y'
```

编译成功后会生成 `my_kernel.ko` 文件。

---

## 加载和测试模块

### 1. 加载模块

```bash
sudo insmod my_kernel.ko
```

### 2. 查看内核日志

```bash
dmesg | tail -5
```

**预期输出**：
```
[ 1234.567890] Hello,Linux Kernel ! I am coming!
```

### 3. 查看已加载的模块

```bash
lsmod | grep my_kernel
```

### 4. 查看模块详细信息

```bash
modinfo my_kernel.ko
```

### 5. 卸载模块

```bash
sudo rmmod my_kernel
```

### 6. 再次查看日志

```bash
dmesg | tail -5
```

**预期输出**：
```
[ 1234.567890] Hello,Linux Kernel ! I am coming!
[ 1250.123456] Goodbye,Linux Kernel ! I will be back!
```

---
