#ifndef __BUTTON_H__
#define __BUTTON_H__

#include<reg51.h>

sbit key1 = P1^0;
sbit key2 = P1^1;
sbit key3 = P1^2;
sbit key4 = P1^3;

/*
Button_Init()函数为按键初始化函数，若独立按键被按下，dir(1~4)++。
引用dir时需要再次声明 extern unsigned int dir1,dir2,dir3,dir4;
返回值为0，1，2，3，4对应按键按下
*/
extern unsigned char Button_Init();   

#endif