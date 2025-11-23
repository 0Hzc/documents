#include"pbdata.h"

void LCD1602_BusyCheck()       
{       
        unsigned int sta ;
        LCD1602_DATAPORT = 0XFF;   
        LCD1602_RS = 0;
        LCD1602_RW = 1;  
       do {     
        LCD1602_E = 1;
        sta = LCD1602_DATAPORT;
        LCD1602_E = 0;    
       }while((sta & 0x80 )== 0x80);    
}

void delay_lcd1602(unsigned int  ten_us)
{
        while(ten_us--);

}

void Lcd1602_Init()         //LCD初始化函数
{
      Lcd1602_Write_cmd(0X38);      //数据总线8位，显示2行
      Lcd1602_Write_cmd(0x0c);      //显示功能打开，无光标，光标闪烁
      Lcd1602_Write_cmd(0x06);      //写入新数据后光标右移，显示屏不移动
      Lcd1602_Write_cmd(0X01);      //清屏
      Lcd1602_Show_string(0,0,"      ");//先显示空白，解决LCD1602第一次显示数据时前6列不显示的bug
}
    

void Lcd1602_Write_cmd(unsigned int cmd)        //根据时序图编写lcd写命令函数
{
    LCD1602_RS = 0; //选择写命令     ，高数低命（数据，命令）
    LCD1602_RW = 0;//选择写    ，高读低写
    LCD1602_E = 0;
    LCD1602_DATAPORT = cmd;
    delay_lcd1602(1);
    LCD1602_E = 1;//上升沿写入
    delay_lcd1602(1);
    LCD1602_E = 0;//写入完成，将E拉低
}

void Lcd1602_Write_data(unsigned int dat)    //根据时序图编写lcd写数据函数
{
    LCD1602_RS = 1; //选择写数据     ，高数低命（数据，命令）
    LCD1602_RW = 0;//选择写    ，高读低写
    LCD1602_E = 0;
    LCD1602_DATAPORT = dat;
    delay_lcd1602(1);
    LCD1602_E = 1;//上升沿写入
    delay_lcd1602(1);
    LCD1602_E = 0;//写入完成，将E拉低
}

void Lcd1602_Clear()
{
    Lcd1602_Write_cmd(0x01);
}    

void Lcd1602_Show_string(unsigned char x,unsigned char y,unsigned char *str)//x为列，y为行,str为要显示的字符串
{
        unsigned char i = 0;//记录当前为字符串的第几个字符   
    LCD1602_BusyCheck();
    if(y>1||x>15)return;    //  若超过第一行，或者第15列，lcd无法显示，则直接退出函数
    
    if(y<1) //第一行显示
    {
        while(*str!='\0')    //字符串结尾为\0
        {
            if(i<16-x)//字符若不超过15列，则在第一行显示
            {
                    Lcd1602_Write_cmd(0x80+i+x);                
            }
            else//字符若超过15列，则将其在第二行继续显示
            {
                    Lcd1602_Write_cmd(0x40+0x80+i+x-16);
            }
            Lcd1602_Write_data(*str);//将字符串的第一个显示
            str++;//将地址往后一个推，依次显示直到推到字符串结尾为\0推出循环
            i++;        
        }        
    }
    else    //第二行显示
    {
         while(*str!='\0')    //字符串结尾为\0
        {
            if(i<16-x)  //如果字符长度不超过第二行，则在第二行显示
            {
                    Lcd1602_Write_cmd(0x80+0x40+i+x);                
            }
            else//如果字符长度超过第二行，则在第一行继续显示
            {
                    Lcd1602_Write_cmd(0x80+i+x-16);
            }
            Lcd1602_Write_data(*str);//将字符串的第一个显示
            str++;//将地址往后一个推，依次显示直到推到字符串结尾为\0推出循环
            i++;        
        }    
    }
    
}