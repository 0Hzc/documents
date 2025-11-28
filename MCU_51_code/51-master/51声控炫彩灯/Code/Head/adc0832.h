#ifndef __ADC0832_H__
#define __ADC0832_H__

#include<reg51.h>

sbit ADC_CS =   P1^0;
sbit ADC_CLK = P1^1;
sbit ADC_D = P1^2;



unsigned char Adc_Conv(); //ADC模数转换函数，返回值为转换后的结果

#endif 