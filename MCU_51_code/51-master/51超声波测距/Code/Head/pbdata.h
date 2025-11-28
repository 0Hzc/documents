#ifndef __PBDATA_H__
#define __PBDATA_H__

#include <reg51.h>
#include"lcd1602.h"
#include"button.h"
#include"hcsr04.h"
#include"jq6500.h"
#include"intrins.h" 

#define uchar unsigned char
#define uint unsigned int
    
sbit LED = P1^6;
sbit k1 = P1^0;
sbit BEEP = P1^7;

char* data_str(unsigned int dat);        //声明数字转字符串函数,函数返回值即为字符串数组
void delay(unsigned long ten_us);
char *Dis_Str(char *str1,char *str2);
char Strlen(char *str);
void Timer1_Init();

#endif