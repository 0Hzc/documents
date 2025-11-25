#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/fs.h>
#include <linux/uaccess.h> // ⚠️必须加这个！包含 copy_to_user/copy_from_user

#define MY_DEVICE_NAME "my_rw_device"

static int major_num;
static char kernel_buffer[1024]; // 我们的仓库，用来存用户发来的数据

// 1. 实现 write 函数 (用户 -> 内核)
// 参数 buff: 用户给的数据地址
// 参数 len: 用户打算写多少字节
// 参数 ppos: 文件偏移量 (这次先不管它)
static ssize_t my_write(struct file *file, const char __user *buff, size_t len, loff_t *ppos) {
    unsigned long copy_ret;
    
    // 安全检查：如果用户写的数据太多，就把我们的仓库撑爆了
    if (len > 1024) {
        printk(KERN_ALERT "My Device: 数据太长了，装不下！\n");
        return -EINVAL; // 返回“无效参数”错误
    }

    // 核心动作：从用户空间搬运数据
    // copy_from_user(目的地-内核, 来源-用户, 长度)
    // 返回值：如果成功返回0，失败返回没拷贝完的字节数
    copy_ret = copy_from_user(kernel_buffer, buff, len);
    
    if (copy_ret) {
        printk(KERN_ERR "My Device: 搬运失败，丢了数据！\n");
        return -EFAULT;
    }

    // 这一步很重要：手动给字符串末尾加结束符，防止打印乱码
    kernel_buffer[len] = '\0'; 

    printk(KERN_INFO "My Device: 收到用户写入: %s\n", kernel_buffer);
    
    return len; // 返回实际写入的字节数，告诉用户“我收到了这么多”
}

// 2. 实现 read 函数 (内核 -> 用户)
// 参数 buff: 用户接收数据的地址
// 参数 len: 用户想读多少字节
// 参数 ppos: ⚠️书签！记录读到哪里了
static ssize_t my_read(struct file *file, char __user *buff, size_t len, loff_t *ppos) {
    int data_len = strlen(kernel_buffer);
    int ret;

    // 逻辑：如果“书签”的位置已经超过了数据长度，说明读完了
    if (*ppos >= data_len) {
        return 0; // 返回0表示 EOF (End Of File)，cat 命令就会停止
    }

    // 调整读取长度：如果用户想读100个，但我只有5个，那就只给他5个
    if (len > data_len - *ppos) {
        len = data_len - *ppos;
    }

    // 核心动作：把数据搬给用户
    // copy_to_user(目的地-用户, 来源-内核, 长度)
    ret = copy_to_user(buff, kernel_buffer + *ppos, len);
    
    if (ret) {
        return -EFAULT;
    }

    // ⚠️关键一步：移动书签！
    // 就像你看书，看完这一页要翻页，否则下次还是从第0页开始读，cat就会死循环
    *ppos += len; 

    printk(KERN_INFO "My Device: 发送给用户 %zu 字节\n", len);
    return len; // 返回实际读取的字节数
}

static int my_open(struct inode *inode, struct file *file) {
    printk(KERN_INFO "My Device: Open\n");
    return 0;
}

static int my_release(struct inode *inode, struct file *file) {
    printk(KERN_INFO "My Device: Release\n");
    return 0;
}

// 3. 更新菜单，把 read 和 write 加上
static struct file_operations my_fops = {
    .owner = THIS_MODULE,
    .open = my_open,
    .release = my_release,
    .write = my_write,  // 新增
    .read = my_read,    // 新增
};

static int __init my_driver_init(void) {
    major_num = register_chrdev(0, MY_DEVICE_NAME, &my_fops);
    if (major_num < 0) return major_num;
    printk(KERN_INFO "My Device: 注册成功，主设备号: %d\n", major_num);
    return 0;
}

static void __exit my_driver_exit(void) {
    unregister_chrdev(major_num, MY_DEVICE_NAME);
}

module_init(my_driver_init);
module_exit(my_driver_exit);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("You");

/*
使用该模块
make成功后

加载模块
sudo insmod chrdev_rw.ko

增加文件绑定链接
  需要先查看驱动分配的主设备号
  dmesg|tail -5
创建绑定文件链接
sudo mknod /dev/chrdev_rw c 240 0
——c 代表字符设备 (Character)。
——240 是刚才日志里看到的数字。
——0 是次设备号，填 0 就行。

使用，并去dmesg中查看
echo "Hello Kernel, I am User!" > /dev/chrdev_rw  //触发 my_write 函数
dmesg |tail -5  


cat /dev/my_rw_device  //触发 my_read 函数
会直接在终端进行打印结果
*/