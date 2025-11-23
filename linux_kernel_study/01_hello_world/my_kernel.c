#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>

static int __init  my_hello_init(void){
    printk(KERN_INFO "Hello,Linux Kernel ! I am coming!\n");
    return 0;
}
static void __exit my_hello_exit(void){
    printk(KERN_INFO "Goodbye,Linux Kernel ! I will be back!\n");
}

module_init(my_hello_init);
module_exit(my_hello_exit);

MODULE_LICENSE("GPL");

MODULE_AUTHOR("0hzc");

MODULE_DESCRIPTION("A simple Hello World Module");

