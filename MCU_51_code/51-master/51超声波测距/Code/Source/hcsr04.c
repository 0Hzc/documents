#include"pbdata.h"
unsigned int distence;
void Timer_Init()//配置定时器0与1均在模式1工作  即16位定时/计数  用于记高电平时间
{
    TMOD=0X01; 
	TH0=0;
	TL0=0;	
	EA=1; 
	ET0=1; 
	TR0=0;
	TRIG = 0;
}

void StartModule()      //用于发射波，使用函数调用，每次执行时都能发送波，在while中实现不断发波
 {
 	TRIG = 1;
	delay(1844);        //延时一定时间，保证有高电平
	TRIG = 0;
 }
 
  void Conut(void)          //用于计算回波的距离
{	

	unsigned int time;      
	time=TH0*256+TL0;
	TH0=0;
	TL0=0;
	distence=(time)/58;
}
unsigned int Get_Distence()     //模块调用函数，测得返回距离，函数返回值即为距离
{           
            Timer_Init();
            StartModule();
			while(!ECHO); 
			TR0=1; 
			while(ECHO); 
			TR0=0; 
            Conut(); 
            TH0=0;	 
            TL0=0;  
            return distence;
}