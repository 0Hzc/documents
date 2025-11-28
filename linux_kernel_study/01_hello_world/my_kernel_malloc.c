#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/slab.h> // kmalloc 和 kfree 所在的头文件

// 声明一个全局指针，用于在 init 和 exit 之间传递内存地址
static int *my_buffer;

static int __init mem_init(void) {
    // 申请 100 个整数（int）大小的内存
    // sizeof(int) * 100 是内存大小
    // GFP_KERNEL 是分配标志，允许内核在内存不足时休眠等待
    my_buffer = kmalloc(sizeof(int) * 100, GFP_KERNEL);

    if (!my_buffer) {
        printk(KERN_ERR "Error: Failed to allocate kernel memory!\n");
        return -ENOMEM; // -ENOMEM 是内核标准的“内存不足”错误码
    }

    // 成功申请内存后，打印其地址（指针）
    printk(KERN_INFO "Memory allocated successfully at address: 0x%p\n", my_buffer);

    // 尝试往内存的第0个位置写入数据
    *my_buffer = 42; 
    
    return 0;
}

static void __exit mem_exit(void) {
    // 在卸载时必须释放内存，否则会导致内存泄漏！
    if (my_buffer) {
        printk(KERN_INFO "Data read from buffer: %d\n", *my_buffer);
        kfree(my_buffer);
        printk(KERN_INFO "Memory at 0x%p successfully freed.\n", my_buffer);
    }
}

module_init(mem_init);
module_exit(mem_exit);
MODULE_LICENSE("GPL");