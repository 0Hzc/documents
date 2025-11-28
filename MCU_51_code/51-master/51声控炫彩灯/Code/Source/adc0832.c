#include"pbdata.h"
#include"intrins.h"
void Adc_Init()     //ADC初始化函数
{       
        ADC_CS = 1;     //将片选置高
        ADC_CLK = 0;        
        ADC_D = 0;  
}
unsigned char Adc_Conv()        //ADC模数转换
{   
     unsigned char i;
     unsigned char ad_result1;
     unsigned char ad_result2;
    Adc_Init();
       ADC_CS = 0;      // 片选使能，低电平时工作
       ADC_D = 1;      //在时钟第一个上升沿之前，拉高，并且在第一个下降沿之前仍然要保持为高
       ADC_CLK = 1;
       _nop_();
       ADC_CLK = 0; //产生第一个脉冲，第一次脉冲为保证片选正常工作
        //第二次脉冲与第三次脉冲用于选通道
        //ADC_D在两次脉冲输入  1  0  选择单通道1传入模拟量
       ADC_D = 1;
       _nop_();
       ADC_CLK = 1;
       _nop_();
       ADC_CLK = 0;     //第二个脉冲结束
        
       ADC_D = 0;
       _nop_();
       ADC_CLK = 1;
       _nop_();
       ADC_CLK = 0;    //第三个脉冲结束，此后再来脉冲 ，ADC_D将用于输出数据
       
       ADC_D = 1;   //把数据线拉高，准备接收数据
      //第一次读取数据,MSB
      for(i = 0;i<8;i++)
       {
         //ADC_D在下降沿时接收数据
         ADC_CLK = 1;
           _nop_();
         ADC_CLK = 0;
         ad_result1 = ad_result1<<1; //左移，让数据在循环中存入
         if(ADC_D ==1)      //将1存入ad_result1
             ad_result1 = ad_result1 | 0x01;           
       }
     //第二次读取数据，LSB
       for(i = 0;i<8;i++)
       {
         ad_result2 = ad_result2>>1; //右移，让数据在循环中存入  
         if(ADC_D ==1)      //将1存入ad_result1
         ad_result2 = ad_result2 | 0x80;    
         //ADC_D在下降沿时接收数据
         ADC_CLK = 1;
           _nop_();
         ADC_CLK = 0;      
       }                    
        //完成了一次操作,准备效验转换值是否正确     
       return (ad_result1 == ad_result2) ? ad_result1:0;  //若前后两次数据一致，随意返回一个即可，若不一致，返回0
}