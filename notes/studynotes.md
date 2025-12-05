## python相关学习
### Subprocess模块
作用：允许生成新的进程执行命令行指令<br>
```shell
subprocess.run(args, *, stdin=None, input=None, stdout=None, stderr=None, capture_output=False, shell=False, cwd=None, timeout=None, check=False, encoding=None, text=None, env=None)
```
返回值：subprocess.CompletedProcess<br>
主要参数：<br>
args：表示要执行的命令。必须是以字符串为元素的 list or tuple 。<br>
stdin、stdout 、stderr：进程的标准输入、输出和错误。<br>
{可取值：<br>
subprocess.PIPE,      #subprocess.PIPE 表示为子进程创建新的管道<br>
subprocess.DEVNULL,   #subprocess.DEVNULL 表示使用 os.devnull<br>
一个已经存在的文件描述符, <br>
已经打开的文件对象,<br>
None                  #默认使用的是 None，表示什么都不做。<br>
}<br>
encoding: 如果指定了该参数，则 stdin、stdout 和 stderr 可以接收字符串数据，并以该编码方式编码。否则只接收 bytes 类型的数据。<br>
shell：如果该参数为 True，将通过操作系统的 shell 执行指定的命令。<br>
check: 如check=true, 当进程退出码为非0时，将生成 CalledProcessError 异常<br>

使用python脚本在终端执行 <fron color=Blue>yolo predict model=yolo11n.pt source='cat.jpg'</font><br>
```python
import subprocess

def run_yolo_predict(model, source):
    command = f"yolo predict model={model} source={source}"
    process = subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    print(process.stdout.decode())
    if process.returncode != 0:
        print(process.stderr.decode())

if __name__ == "__main__":
    model_path = r"/root/yolo/yolo11n.pt"  
    image_path = r"/root/yolo/cat.png"    

    run_yolo_predict(model_path, image_path)
```



## C++相关学习
### 类的定义

创建头文件以及源文件
1.新建一个名为test.cpp的源文件
```cpp
#include "test.h"       //包含自定义的头文件使用双引号
#include <iostream>     //使用提供的头文件使用<>

test_print::test_print(){   //定义构造函数，使用::指明类
}

test_print::~test_print(){
    //清理代码
}

void test_print::print{     //定义自定义print函数
    std::cout <<"Hello" << std::endl;
    /*
    这一句是C++中的输出语句
    "std"是类名，"std::"是标准命名空间
    "cout"是控制台输出
    "<<"是输出运算符
    "Hello"是要输出的字符串
    "endl"是结束当前行并刷新输出缓冲区
    */ 
    int age = 18;
    std::cout << "年龄是：" << age <<std::endl;
}
```

1.2 进阶版，使用构造函数来传递变量
```cpp
#include "test.h"
#include <iostream>

test_print::test_print(){
    test_age =18;   //此处不能使用int test_age ,使用了int 会被认定为构造函数的局部变量
}
test_print::~test_print(){
}
void test_print::print_test(int age){
    int ages =18;
    std::cout << "Hello\n" << std::endl;
    std::cout << "初始化年龄是：" << test_age << std::endl;
    std::cout << "年龄是：" << age << std::endl;
    std::cout << "年龄是：" << ages << std::endl;
}
```




2.新建一个名为test.h的头文件
```cpp
//
//使用ifndef endif语句来实现头文件包含
#ifndef TEST_H
#define TEST_H

//主体内容中声明在源文件中定义的类
class test_print {    //此行用于声明类名
public:             //此行用于声明类中的公共成员
    test_print();   //此行用于声明类的构造函数
    ~test_print();  //此行用于声明类的析构函数
    void print();   //此行用于声明类中编写的函数
private:            //此行用于声明类中的私有成员
    //与公共成员一致
};
#endif
```

3.新建main.cpp
```cpp
#include "test.h"

int main(){
    test_print tp;
    tp.print();
    return 0;
}
```

运行c++程序，与C的程序一致，编辑器没有提供一键编译的话，使用命令进行编译
```shell
#使用g++编译源文件
g++ main.cpp test.cpp -o test

#参数说明，-o表示生产一个名为test可执行程序,不使用-o的话，会自动生成a.out文件
```
### .h中相关内容
#### 类的继承
```cpp
class yolo_UI : public QMainWindow
{
//.......省略
};
```
在头文件中，使用“：”表示继承
表示yolo_UI类继承公共类QMainWindow

#### 命名空间
```cpp
/*
定义：
QT_BEGIN_NAMESPACE
namespace Ui {
    class yolo_UI;  //前向类的声明
}
QT_END_NAMESPACE

解释：
1. namespace Ui创建了一个名为Ui的命名空间，在Qt中用来存放由*.ui文件生成的界面类的地方
2. 前向声明是为了告诉编译器，前向声明里的类会在其他地方进行定义

作用：
主要是避免名称冲突
不同城市可以有相同名字的街道
不同文件夹可以有相同名字的文件
*/
```



### .cpp中相关内容
#### 初始化列表
基本语法
```cpp
/*类名::构造函数():初始化内容1,初始化内容2,初始化内容3
{
    //构造函数体
}
*/
```