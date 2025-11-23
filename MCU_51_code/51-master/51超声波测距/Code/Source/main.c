#include "pbdata.h"
   static unsigned int data_warn = 15;
    extern unsigned int distence;
void main()
{        
        BEEP = 1;
        k1 = 1;
        Lcd1602_Init();
        Timer1_Init();
while(1)
{        
        if((Button_Init())==1)                //检测那个按键被按下，执行对应的逻辑
        {
            data_warn++; 
            delay(5000);
        }     
        else if((Button_Init())==2)
        {
            data_warn--; 
            delay(5000);
            if(data_warn==0)
                    break;
        } 
            Lcd1602_Show_string( 0,0,Dis_Str ("Distence:",data_str( Get_Distence() ) ) );      
            Lcd1602_Show_string(0,1,Dis_Str("Warning:",data_str(data_warn)));
        if(Get_Distence()<data_warn) 
        {
            TR1 = 1;
            LED = ~LED; 
            BEEP =!BEEP;
        }
}
}

void Timer1() interrupt 3
{
    unsigned long i = 10000;
    k1 = 0;
    while(i--)  {_nop_();}
    k1 = 1;
    TR1 = 0;
}


