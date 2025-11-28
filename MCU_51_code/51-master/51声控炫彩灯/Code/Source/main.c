#include"pbdata.h"
unsigned char ad_result= 0;
unsigned char flag = 0;
unsigned int time1= 1;
unsigned int time2= 1;
void Time0_Init();

void main()
{
    Time0_Init();
    LED = 0x00;//初始将LED灯全部熄灭
    Lcd1602_Init(); //LCD初始化
while(1)
{      
    ad_result = Adc_Conv();     //将采集的模拟量经过放大电路以及模数转换后存入ad_result变量中
    Lcd1602_Show_string(0,0,"Voice:");      //在LCD屏幕上显示Voice
    Lcd1602_Show_string(11,0,"dB");     //在LCD屏幕上显示dB
    Lcd1602_Show_string(2,1,"T1:");
    Lcd1602_Show_string(8,1,"T2:");
    Lcd1602_Show_string(7,0,data_str(ad_result));       //在LCD屏幕上显示声音值
    
        if(ad_result>10)
        { 
            TR0 = 1;
        Lcd1602_Show_string(5,1,Dis_Str(data_str(time1),"s"));   
        }
        else if(ad_result>20)
        {
            TR0 = 1;
        Lcd1602_Show_string(10,1,Dis_Str(data_str(time2),"s"));
        }
        else 
            TR0 = 0;

    //以下部分为实现达到一定分贝在LCD上显示对应字符
//    if(ad_result==50)       
//    flag=1;
//    if(ad_result==100)
//    flag=2;
//    if(ad_result==150)
//    flag=3;
//    switch(flag)
//    {
//        case 1:Lcd1602_Clear();Lcd1602_Show_string(0,1,"Didn't you eat?");flag = 0;delay(5000);break;
//        case 2:Lcd1602_Clear();Lcd1602_Show_string(0,1,"Louder");flag = 0;delay(5000);break;
//        case 3:Lcd1602_Clear();Lcd1602_Show_string(0,1,"Just so so");flag = 0;delay(5000);break;   
//    }
    Led_Show();     //执行炫彩灯
}

}

void Time0_Init()
{
        TMOD = (TMOD & 0XF0)  | 0X01;      
        TL0 =(65536-1000);		
        TH0 = (62236-1000)/256;
        TF0 = 0;
//        TR0 = 1;
        EA = 1;
        ET0 = 1;
}


void Time0() interrupt 1
{
   static  unsigned int time_flag = 0;
        TH0 = (65536-1000)/256;
        TL0 = (65536-1000);
        TF0 = 0;
        time_flag++;
    if(time_flag==1000)
    {
        time_flag = 0;
        time1++;
        time2++;
    }
}
