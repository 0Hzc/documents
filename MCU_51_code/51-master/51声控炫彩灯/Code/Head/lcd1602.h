#ifndef __LCD1602_H__
#define __LCD1602_H__

#include<reg51.h>
sbit LCD1602_RS = P1^5;
sbit LCD1602_RW = P1^6;
sbit LCD1602_E = P1^7;

#define LCD1602_DATAPORT P2

void Lcd1602_Init();//LCD初始化函数
void Lcd1602_Write_cmd(unsigned int cmd);//lcd写命令函数
void Lcd1602_Write_data(unsigned int dat);//lcd写数据函数
void Lcd1602_Clear();//lcd清屏函数
void Lcd1602_Show_string(unsigned char x,unsigned char y,unsigned char *str);//x为列，y为行,str为要显示的字符串
#endif