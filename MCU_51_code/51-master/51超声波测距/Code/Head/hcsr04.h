#ifndef __HCSR04__
#define __HCSR04__

#include<reg51.h>

sbit TRIG = P2^0;
sbit ECHO = P2^1;



unsigned int Get_Distence();        




#endif