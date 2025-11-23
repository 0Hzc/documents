# 实践从0实现linux
根据指导，在ubuntu20.04环境下，进行开发
## 配置环境
### 安装必要的软件包
```bash
# 更新软件包列表
sudo apt update
# 安装基本开发工具
sudo apt install build-essential
# 安装编译器、汇编器和调试工具
sudo apt install gcc nasm make gdb
# 安装QEMU模拟器
sudo apt install qemu-system-x86
# 安装32位编译选项
sudo apt install gcc-multilib
# 安装其他有用的工具
sudo apt install git vim
```
安装所需的软件包后<br>

安装完所需软件包，构建整个项目的架构：<br>

```plaintest
/home/ubuntu/myos/         # 项目根目录
├── Makefile              # 在这里创建Makefile
├── link.ld               # 链接脚本也放在这里
├── src/                  # 源代码目录
│   ├── boot/             # 引导加载程序
│   ├── kernel/           # 内核代码
│   ├── drivers/          # 设备驱动
│   ├── fs/               # 文件系统
│   └── include/          # 头文件
└── build/                # 编译输出目录
```


针对此目录结构进行必要的说明：<br>
下列是计算机启动时的执行流程的粗略概括<br>
```plaintest
+-------------------+
|  计算机启动       |
|  BIOS初始化硬件   |
+-------------------+
            |
            v
+-------------------+
|  加载引导加载程序  |
|  (boot.asm)       |
+-------------------+
            |
            v
+-------------------+
|  初始化硬件环境   |
|  (设置段寄存器、  |
|   清屏等)         |
+-------------------+
            |
            v
+-------------------+
|  从硬盘读取内核   |
|  (kernel.bin)     |
+-------------------+
            |
            v
+-------------------+
|  跳转到内核入口点  |
|  (kernel_main)    |
+-------------------+
            |
            v
+-------------------+
|  内核代码初始化   |
|  系统 (main.c)    |
+-------------------+
```
对于流程图中提到的kerner.bin文件以及各个文件的处理过程，可简单概括为下面的内容：<br>
1.引导加载程序".asm"文件，以及内核代码，在这里简单将其称为"main.c",<br>
2.然后整体客观来看，
- ".asm"主要是与在软件层面实现与实际硬件打交道的(例如负责初始化硬件环境，如设置段寄存器、清屏、读取硬盘等)<br>
- "main.c"是由高级语言编写实现一些功能，（例如内存管理和多任务等），<br>

然后因为要将高级语言的东西实现到实际硬件上，就需要链接器将编译后的.bin文件链接起来，在这里可以看作是boot.bin,以及经过gcc编译后的.o文件编译的kernel.bin，具体链接方式的则是通过".ld"文件来实现的<br>
而makefile文件，则可视为，具体实现各个步骤的脚本，例如使用什么工具编译，编译的命令，等等
## 创建项目目录结构
```bash
# 创建项目主目录
mkdir -p ~/myos
cd ~/myos

# 创建子目录
mkdir -p src/boot    # 引导加载程序代码
mkdir -p src/kernel  # 内核代码
mkdir -p src/drivers # 设备驱动
mkdir -p src/fs      # 文件系统
mkdir -p src/include # 头文件
mkdir -p build    
```

### 编写.asm文件
在src/boot/目录下创建boot.asm:
```nasm
; 引导加载程序 - MBR (主引导记录)
org 0x7C00                ; BIOS加载MBR到0x7C00处
bits 16                   ; 16位实模式

start:
    ; 设置段寄存器
    cli                    ; 关闭中断
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00         ; 设置栈指针
    sti                    ; 开启中断
    
    ; 清屏
    mov ax, 0x03
    int 0x10
    
    ; 打印启动消息
    mov si, boot_msg
    call print_string
    
    ; 加载内核到内存
    mov ah, 0x02           ; BIOS读磁盘功能
    mov al, 10             ; 读取的扇区数
    mov ch, 0              ; 柱面0
    mov cl, 2              ; 从第2扇区开始(第1扇区是MBR)
    mov dh, 0              ; 磁头0
    mov dl, 0x80           ; 驱动器0 (第一块硬盘)
    mov bx, 0x1000         ; ES:BX - 加载到0x1000:0处
    mov es, bx
    xor bx, bx
    int 0x13               ; 调用BIOS磁盘服务
    
    jc disk_error          ; 如果出错则跳转
    
    ; 跳转到内核
    jmp 0x1000:0x0000
    
disk_error:
    mov si, error_msg
    call print_string
    jmp $

print_string:
    lodsb                  ; 从SI加载字符到AL
    or al, al              ; 检查是否字符串结束
    jz .done
    mov ah, 0x0E           ; BIOS显示字符功能
    int 0x10
    jmp print_string
.done:
    ret

; 数据
boot_msg db "MyOS Bootloader v0.1", 0x0D, 0x0A, 0
error_msg db "Disk Error!", 0x0D, 0x0A, 0

; 填充剩余空间并添加MBR签名
times 510 - ($ - $$) db 0
dw 0xAA55                 ; MBR签名
```
### 编写main.c文件
在src/kernel/main.c中创建基础内核：
```c
// 内核入口点
void kernel_main() {
    // 设置VGA文本模式缓冲区
    char* video_memory = (char*)0xB8000;
    
    // 清屏
    for (int i = 0; i < 80 * 25 * 2; i += 2) {
        video_memory[i] = ' ';
        video_memory[i + 1] = 0x07; // 灰底黑字
    }
    
    // 显示欢迎消息
    const char* welcome = "MyOS Kernel v0.1";
    for (int i = 0; *welcome; i += 2, welcome++) {
        video_memory[i] = *welcome;
    }
    
    // 挂起内核
    while(1);
}
```

### 编写link.ld文件
```ld
ENTRY(_start)

SECTIONS {
    . = 0x10000; /* 内核加载到1MB处 */
    
    .text : {
        *(.text)
    }
    
    .data : {
        *(.data)
    }
    
    .bss : {
        *(.bss)
    }
    
    /DISCARD/ : {
        *(.comment)
        *(.eh_frame)
    }
}
```
### 编写Makefile文件
```makeile
# 目标架构
ARCH := i386

# 工具链
CC := gcc
ASM := nasm
LD := ld

# 编译选项
CFLAGS := -m32 -nostdlib -nostdinc -fno-builtin -fno-stack-protector -nostartfiles -nodefaultlibs -Wall -Wextra -c
ASMFLAGS := -f bin
LDFLAGS := -m elf_i386 -T link.ld

# 源文件和目标文件
SRC_DIR := src
BUILD_DIR := build
KERNEL := myos.bin
BOOTLOADER := boot.bin
DISK := disk.img

.PHONY: all clean run

all: $(BUILD_DIR)/$(DISK)

# 编译引导加载程序
$(BUILD_DIR)/$(BOOTLOADER): $(SRC_DIR)/boot/boot.asm
	@mkdir -p $(@D)
	$(ASM) $(ASMFLAGS) $< -o $@

# 编译内核
$(BUILD_DIR)/$(KERNEL): $(SRC_DIR)/kernel/main.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $< -o $(BUILD_DIR)/main.o
	$(LD) $(LDFLAGS) $(BUILD_DIR)/main.o -o $@

# 创建磁盘镜像
$(BUILD_DIR)/$(DISK): $(BUILD_DIR)/$(BOOTLOADER) $(BUILD_DIR)/$(KERNEL)
	dd if=/dev/zero of=$@ bs=512 count=2880
	dd if=$(BUILD_DIR)/$(BOOTLOADER) of=$@ conv=notrunc
	dd if=$(BUILD_DIR)/$(KERNEL) of=$@ seek=1 conv=notrunc

# 运行QEMU
run: $(BUILD_DIR)/$(DISK)
	qemu-system-i386 -drive format=raw,file=$(BUILD_DIR)/$(DISK)

clean:
	rm -rf $(BUILD_DIR)
```

## 运行检测
```bash
#在项目根目录运行
make run
```
