#include"pbdata.h"
extern unsigned int mode;
unsigned char pwm_flag;

void Time0_init()                                //使用定时器0实现1MS的定时
{
        TMOD = (TMOD & 0XF0)  | 0X01;       //选择定时器0以工作模式1工作
        TL0 =(65536-1000);		
        TH0 = (62236-1000)/256;
        TR0 = 1;                                     //打开定时器0
        ET0 = 1;                                        //打开定时器中断
        EA = 1;                                         //打开总中断
}

void Timer_0() interrupt 1      //定时器0的中断函数
{
        TL0 =(65536-1000);		
        TH0 = (62236-1000)/256;          //重装初值
        pwm_flag++;

//下面为实现PWM部分所需  
      if(pwm_flag>10)   pwm_flag = 0;
      //下面为设计对应所需占空比，所需实现的效果 
        if(pwm_flag<mode)  
        {
            Motor_IO = 1;
        }
        else 
        {
            Motor_IO = 0;
        }     
}
   