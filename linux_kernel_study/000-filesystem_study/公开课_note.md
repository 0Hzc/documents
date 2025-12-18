# 说明
此文档记录，观看linux内核学习公开课视频中，如何在linux下实现一个文件系统，所记录的笔记

## 知识点
做一个文件系统，要具备三个结构体，file_system_type、file_operations、inode_operations
 - file_system_type结构体的作用：是用来形容这个文件系统，它的名字叫什么，它挂载执行哪个函数，它卸载执行哪个函数，是用来表述这个文件系统的。
 - file_operations结构体的作用：是对应这个文件系统具体的文件，进行操作时执行的函数是什么。
 - inode_operations结构体的作用：是对应的具体的每一个文件里面具体的内容，该怎么存，数据的组织格式，内容怎么存。

### code
```c
//继承（重写）一个结构体的时候，其中的方法（函数）同样也需要重写，例如下面的.mount和.kill_sb就是两个方法，因为定义的是自己定义的方法，则需要重写自定义的方法
// 重写方法，则需查看源码
struct file_system_type smallfs_type = {
    .owner = THIS_MODULE,
    .name = "smallfs", //定义的.name是在后续进行mount挂载命令时使用到的名字
    .mount = smallfs_mount,
    .kill_sb = smallfs_kill_sb,


};


struct file_operations smallfs_file_ops={
    .read = small_read,
    .write = small_write,

}

ssize_t small_read(struct file *, char __user *, size_t, loff_t *){


}

ssize_t small_write(struct file *, const char __user *, size_t, loff_t *){


}
/*说明：
作用：是“在一个文件里面具体存储内容”的实现，
*/
struct inode_operations smallfs_inode_ops = {

    .create = smallfs_create,

}

int smallfs_create(struct mnt_idmap *mnt_idmap, struct inode *inode , struct dentry *dty, umode_t mode, bool excl){


}

/*说明：
原因：smallfs_fill_super函数是重写原fill_super函数，因为在执行mount_nodev函数时，需要传递这个函数的返回值。
作用：是在执行完mount -t smallfs none /mnt，后会在挂载的路径下创建那些文件内容的
*/
int smallfs_fill_super (struct super_block *sb, void *data, int client){



}


/*说明：
原因：smallfs_mount函数是重写原mount函数，因为在重写file_system_type结构体smallfs_type时，初始化内部需要有.mount方法以及.kill_sb方法
*/
struct dentry *smallfs_mount (struct file_system_type *fs_type, int flags, const char *devname, void *data){


    //在使用命令 mount -t smallfs none /mnt时，其中none的是通过mount_nodev()来实现的
    return mount_nodev(fs_type, flags, data, smallfs_fill_super);

}

/*说明：
原因：smallfs_mount函数是重写原mount函数，因为在重写file_system_type结构体smallfs_type时，初始化内部需要有.mount方法以及.kill_sb方法
*/
void smallfs_kill_sb (struct super_block *sb){


}

```
附：
```bash
# linux下文件系统能够运行，是依靠mount命令,例如：
mount -t smallfs none /mnt/
# 而这个mount方法就是在file_system_type这个结构体中有定义的
```

贴上基于 Linux 6.6 内核的 include/linux/fs.h，struct file_system_type 定义如下，且中文简要说明各字段含义
```c
struct file_system_type {
    const char *name;                           /* 文件系统名，mount -t 使用 */
    int fs_flags;                               /* 能力/特性位：FS_REQUIRES_DEV 等 */
    int (*init_fs_context)(struct fs_context *);/* 新式挂载入口，解析选项+建 superblock */
    const struct fs_parameter_spec *parameters; /* fs_context 可接受的参数表 */
    struct dentry *(*mount)(struct file_system_type *, int,
                            const char *, void *); /* 旧式挂载入口 */
    void (*kill_sb)(struct super_block *);      /* 卸载/清理 superblock */
    struct module *owner;                       /* 通常 THIS_MODULE，防卸载 */
    struct file_system_type *next;              /* 内核注册表链表 */
    struct hlist_head fs_supers;                /* 该类型已挂载的 superblock 列表 */

    /* 下面一组是锁依赖（lockdep）用的 key，不影响功能 */
    struct lock_class_key s_lock_key;
    struct lock_class_key s_umount_key;
    struct lock_class_key s_vfs_rename_key;
    struct lock_class_key s_writers_key[SB_FREEZE_LEVELS];
    struct lock_class_key i_lock_key;
    struct lock_class_key i_mutex_key;
    struct lock_class_key invalidate_lock_key;
    struct lock_class_key iop_permission_key;
    struct lock_class_key dqio_mutex_key;
    struct lock_class_key dqonoff_mutex_key;
    struct lock_class_key i_flctx_lock_key;
    struct lock_class_key i_dio_done_lock_key;
    struct lock_class_key i_dio_counter_lock_key;
};
```
贴上基于 Linux 6.6 内核的 include/linux/fs.h，struct inode_operations 定义
```c
struct inode_operations {
    struct dentry *(*lookup)(struct inode *, struct dentry *, unsigned int);
    const char *(*get_link)(struct dentry *, struct inode *,
                            struct delayed_call *);
    int (*permission)(struct mnt_idmap *, struct inode *, int);
    struct posix_acl *(*get_acl)(struct mnt_idmap *, struct dentry *, int);
    int (*readlink)(struct dentry *, char __user *, int);
    int (*create)(struct mnt_idmap *, struct inode *, struct dentry *,
                  umode_t, bool);
    int (*link)(struct dentry *, struct inode *, struct dentry *);
    int (*unlink)(struct inode *, struct dentry *);
    int (*symlink)(struct mnt_idmap *, struct inode *, struct dentry *,
                   const char *);
    int (*mkdir)(struct mnt_idmap *, struct inode *, struct dentry *,
                 umode_t);
    int (*rmdir)(struct inode *, struct dentry *);
    int (*mknod)(struct mnt_idmap *, struct inode *, struct dentry *,
                 umode_t, dev_t);
    int (*rename)(struct mnt_idmap *, struct inode *, struct dentry *,
                  struct inode *, struct dentry *, unsigned int);
    int (*setattr)(struct mnt_idmap *, struct dentry *, struct iattr *);
    int (*getattr)(struct mnt_idmap *, const struct path *,
                   struct kstat *, u32, unsigned int);
    ssize_t (*listxattr)(struct dentry *, char *, size_t);
    int (*fiemap)(struct inode *, struct fiemap_extent_info *,
                  u64, u64);
    int (*update_time)(struct inode *, struct timespec64 *, int);
    int (*atomic_open)(struct inode *, struct dentry *, struct file *,
                       unsigned int, umode_t);
    int (*tmpfile)(struct mnt_idmap *, struct inode *, struct file *,
                   umode_t);
    int (*set_acl)(struct mnt_idmap *, struct dentry *,
                   struct posix_acl *, int);
    int (*fileattr_set)(struct mnt_idmap *, struct dentry *,
                        struct fileattr *);
    int (*fileattr_get)(struct dentry *, struct fileattr *);
};
```
贴上基于 Linux 6.6 内核的 include/linux/fs.h，struct file_operations 定义如下
```c
struct file_operations {
    struct module *owner;
    loff_t (*llseek)(struct file *, loff_t, int);
    ssize_t (*read)(struct file *, char __user *, size_t, loff_t *);
    ssize_t (*write)(struct file *, const char __user *, size_t, loff_t *);
    ssize_t (*read_iter)(struct kiocb *, struct iov_iter *);
    ssize_t (*write_iter)(struct kiocb *, struct iov_iter *);
    int (*iopoll)(struct kiocb *kiocb, bool spin);
    int (*iterate)(struct file *, struct dir_context *);
    int (*iterate_shared)(struct file *, struct dir_context *);
    __poll_t (*poll)(struct file *, struct poll_table_struct *);
    long (*unlocked_ioctl)(struct file *, unsigned int, unsigned long);
    long (*compat_ioctl)(struct file *, unsigned int, unsigned long);
    int (*mmap)(struct file *, struct vm_area_struct *);
    unsigned long mmap_supported_flags;

    int (*open)(struct inode *, struct file *);
    int (*flush)(struct file *, fl_owner_t id);
    int (*release)(struct inode *, struct file *);
    int (*fsync)(struct file *, loff_t, loff_t, int datasync);
    int (*fasync)(int, struct file *, int);
    int (*lock)(struct file *, int, struct file_lock *);
    unsigned long (*get_unmapped_area)(struct file *,
                                       unsigned long, unsigned long,
                                       unsigned long, unsigned long);
    int (*check_flags)(int);
    int (*setfl)(struct file *, unsigned long);
    int (*flock)(struct file *, int, struct file_lock *);
    ssize_t (*splice_write)(struct pipe_inode_info *, struct file *,
                            loff_t *, size_t, unsigned int);
    ssize_t (*splice_read)(struct file *, loff_t *,
                           struct pipe_inode_info *, size_t, unsigned int);
    int (*setlease)(struct file *, long, struct file_lock **, void **);
    long (*fallocate)(struct file *file, int mode, loff_t offset,
                      loff_t len);
    void (*show_fdinfo)(struct seq_file *m, struct file *f);
#ifndef CONFIG_MMU
    unsigned (*mmap_capabilities)(struct file *);
#endif
    ssize_t (*copy_file_range)(struct file *, loff_t, struct file *,
                               loff_t, size_t, unsigned int);
    loff_t (*remap_file_range)(struct file *file_in, loff_t pos_in,
                               struct file *file_out, loff_t pos_out,
                               loff_t len, unsigned int remap_flags);
    int (*fadvise)(struct file *, loff_t, loff_t, int);
    int (*uring_cmd)(struct io_uring_cmd *ioucmd, unsigned int issue_flags);
    int (*uring_cmd_iopoll)(struct io_uring_cmd *cmd, struct io_comp_batch *);
    int (*uring_cmd_flush)(struct file *file, void *sqe);
};
```