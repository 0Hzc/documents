#include <linux/module.h>   // 所有模块都必须包含的头文件
#include <linux/kernel.h>   // 包含 printk 等内核常用函数
#include <linux/init.h>     // 包含 __init 和 __exit 宏

// 1.这是模块加载时（插入U盘）会执行的函数
static int __init my_hello_init(void) {
    // printk 是内核版的 printf
    // KERN_INFO 是日志级别，相当于“普通消息”
    printk(KERN_INFO "Hello, Linux Kernel! I am coming!\n");
    return 0; // 返回 0 表示加载成功
}

// 2.这是模块卸载时（拔出U盘）会执行的函数
static void __exit my_hello_exit(void) {
    printk(KERN_INFO "Goodbye, Kernel! I will be back!\n");
}

// 3.这两行是“注册”，告诉内核哪个是入口，哪个是出口
module_init(my_hello_init);
module_exit(my_hello_exit);

// 4.必须加的版权声明，否则内核会抱怨你是“黑户”
MODULE_LICENSE("GPL");
MODULE_AUTHOR("YourName");
MODULE_DESCRIPTION("A simple Hello World Module");