#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/fs.h>

#define MY_DEVICE_NAME "my_test_device"

static int major_num;

static int my_open(struct inode *inode, struct file *file){
    printk(KERN_INFO "My Device:被用户打开了(Open)!\n");
    return 0;
}

static int my_release(struct inode *inode, struct file *file){
    printk(KERN_INFO "My Device:被用户关闭了(Release)\n");
    return 0;
}

static struct file_operations my_flop = {
    .owner = THIS_MODULE,
    .open = my_open,
    .release = my_release, 
};

static int __init my_device_init(void){
    printk(KERN_ERR "My Device正在加载.....\n");
    // 核心函数：register_chrdev
    // 参数1: 0 表示让内核自动分配一个主设备号
    // 参数2: 设备名字
    // 参数3: 我们的菜单
    major_num = register_chrdev(0,MY_DEVICE_NAME,&my_flop);
    if(major_num<0){
        printk(KERN_ALERT "My Device: 注册失败了，错误码 %d\n", major_num);
        return major_num;
    }
    printk(KERN_INFO "My Device: 注册成功！主设备号是: %d\n", major_num);
    return 0;
}

static void __exit my_device_exit(void){
    // 核心函数：unregister_chrdev (必须和注册时对应)
    unregister_chrdev(major_num,MY_DEVICE_NAME);
    printk(KERN_INFO "My Device: 已卸载，再见！\n");
}

module_init(my_device_init);
module_exit(my_device_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("0hzc");
MODULE_DESCRIPTION("A simple Hello World Module");


/*
使用该模块
make成功后

加载模块
sudo insmod chrdev_base.ko

增加文件绑定链接
  需要先查看驱动分配的主设备号
  dmesg|tail -5
创建绑定文件链接
sudo mknod /dev/my_test_device c 240 0
——c 代表字符设备 (Character)。
——240 是刚才日志里看到的数字。
——0 是次设备号，填 0 就行。

使用，并去dmesg中查看
cat /dev/my_test_device  因为没写 read 函数，所以cat 命令可能会报错或者什么都不显示，这很正常，按 Ctrl+C 退出即可。目的是触发 open 动作
dmesg |tail -5 
*/