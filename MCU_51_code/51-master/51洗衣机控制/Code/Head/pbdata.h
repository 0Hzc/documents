#ifndef __PBDATA_H__
#define __PBDATA_H__

#include<reg51.h>
#include"lcd1602.h"
#include"button.h"
#include"motor.h"

sbit BEEP = P1^4;
sbit LED = P3^2;


char* data_str(unsigned int dat);        //声明数字转字符串函数,函数返回值即为字符串数组
void Time1_init();//定时器1初始化函数
void delay(unsigned long ten_us);     //延时delay_ten   ms
//char *Dis_Str(char *str1,char *str2);
char* data_str(unsigned int dat);

#endif