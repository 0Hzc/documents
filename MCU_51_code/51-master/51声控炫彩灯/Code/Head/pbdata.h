#ifndef __PBDATA_H__
#define __PBDATA_H__

#include<reg51.h>
#include"lcd1602.h"
#include"adc0832.h"
#include"led.h"




char* data_str(unsigned long dat);        //声明数字转字符串函数,函数返回值即为字符串数组
//void Time1_init();//定时器1初始化函数
void delay(unsigned long delay_ten);     //延时delay_ten   ms
char *Dis_Str(char *str1,char *str2);

#endif