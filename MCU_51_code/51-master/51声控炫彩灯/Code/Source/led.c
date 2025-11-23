#include"pbdata.h"
extern  unsigned char ad_result;
void Led_Show()
{
        LED = ad_result;
    if(LED2==1&&LED0==1) LED1 = 1;
    if(LED3==1&&LED1==1) LED2 = 1;    
    if(LED4==1&&LED2==1) LED3 = 1;
    if(LED5==1&&LED3==1) LED4 = 1;
    if(LED6==1&&LED4==1) LED5 = 1;
    if(LED7==1&&LED5==1) LED6 = 1;
}