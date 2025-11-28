#ifndef __LED_H__
#define __LED_H__

#include<reg51.h>
#define LED P3

sbit LED0 = P3^0;
sbit LED1 = P3^1;
sbit LED2 = P3^2;
sbit LED3 = P3^3;
sbit LED4 = P3^4;
sbit LED5 = P3^5;
sbit LED6 = P3^6;
sbit LED7 = P3^7;

void Led_Show();    //ìÅ²ÊµÆº¯Êý

#endif