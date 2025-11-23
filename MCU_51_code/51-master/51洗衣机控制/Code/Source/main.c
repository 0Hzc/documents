#include"pbdata.h"
unsigned int mode = 0;
unsigned char start_button = 0;
extern unsigned int time;  
extern  unsigned  int   dir1 ;
extern  unsigned  int   dir2 ;
extern  unsigned  int   dir3 ;
unsigned char warn_flag;
void main()
{      
        BEEP = 0;       
        LED = 1;        
        Time1_init();       //定时器1初始化，用于定时
        Time0_init();       //定时器0初始化,用于PWM控制电机转速
        Lcd1602_Init();        //LCD1602初始化
        Lcd1602_Show_string(5,1,"Waiting...");
        Lcd1602_Show_string(0,0,"Press Start");
    while(1)
    {   
        if(Button_Init()==4)    //按下开始按钮，并且将原显示清除
        {
            start_button = 1;
            Lcd1602_Clear();
            Lcd1602_Show_string(2,0,"Select Mode:");
            Lcd1602_Show_string(2,1,"HI/MED/LED");           
        }
        if(start_button==1)      //开始按键被按下后才能选择对应模式
    {           
        //检测那个按键被按下，对应执行该按键按下 执行的逻辑
        if(Button_Init()==1)        //按键1按下，将Mode设置为HI
        {          
            Lcd1602_Clear(); //将LCD1602原本显示的清除
            Lcd1602_Show_string(2,0,"Mode: HI");
            Lcd1602_Show_string(2,1,"Time:");   //LCD1602上显示Time: 
            Lcd1602_Show_string(12,1,"s");//LCD1602单位S
            mode = 9;               //设置占空比为50%
            time = 0;
            TR1 = 1;    //打开定时器1;               
        }                     
        
        else if(Button_Init()==2)
        {
            Lcd1602_Clear(); 
            Lcd1602_Show_string(2,0,"Mode: MED");
            Lcd1602_Show_string(2,1,"Time:");   //LCD1602上显示Time:
            Lcd1602_Show_string(12,1,"s");//LCD1602单位S            
            mode = 5;               //设置占空比为30%
            time = 0;
            TR1 = 1;
        }
        else if(Button_Init()==3)
        {
            Lcd1602_Clear(); 
            Lcd1602_Show_string(2,0,"Mode: LOW");
            Lcd1602_Show_string(2,1,"Time:");   //LCD1602上显示Time:   
            Lcd1602_Show_string(12,1,"s");//LCD1602单位S          
            mode = 3;               //设置占空比为20%
            time = 0;
            TR1 = 1;
        }  
    
        Lcd1602_Show_string(8,1,data_str(time));//LCD1602对应显示洗衣时间

            if((dir1 == 1)&&(time==60)) //此处为控制时间多久清零，执行接下来的逻辑
            {
                dir1 = 0;
                TR1 = 0;
                time = 0;
                Lcd1602_Clear(); //将LCD1602原本显示的清除
                Lcd1602_Show_string(5,0,"Over");//LCD1602对应显示洗衣时间    
                mode = 0;
                warn_flag = 1;

            }
             else if((dir2 == 2)&&(time==30)) //此处为控制时间多久清零,执行接下来的逻辑
            {
                dir2 = 0;
                TR1 = 0;
                time = 0;
                Lcd1602_Clear(); //将LCD1602原本显示的清除
                Lcd1602_Show_string(5,0,"Over");//LCD1602对应显示洗衣时间 
                mode = 0;
                warn_flag = 1;
            }
            else  if((dir3 == 3)&&(time==20)) //此处为控制时间多久清零，执行接下来的逻辑
            {
                dir3 = 0;
                TR1 = 0;
                time = 0;
                Lcd1602_Clear(); //将LCD1602原本显示的清除
                Lcd1602_Show_string(5,0,"Over");//LCD1602对应显示洗衣时间  
                mode = 0;
                warn_flag = 1;
            }
     } 
    //以下为报警条件逻辑部分
        if((start_button==1)&&(warn_flag ==1))      //开始按钮被按下，并且进入了over时间才会进入
        {
            LED = 0;
            BEEP = !BEEP;
            delay(450);
            LED = 1; 
            BEEP = 0;
            delay(450);            
        }
        
       }
 }

