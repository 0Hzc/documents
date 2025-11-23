#include"pbdata.h"
#include"intrins.h" 
    unsigned char dis_data[20]={0};
    unsigned char i,length,dat_length;
    unsigned char dis_str[20]={0};
    unsigned int time ;
    unsigned int time_flag;
char* data_str(unsigned int dat)
{        
        for(i=0;i<20;i++)
    {
        dis_data[i] = 0;
    }
		dat_length = dat;	
		for(length =0;dat_length!= 0;length++)	    
	{	
			dat_length = dat_length/10;
	}	
		for(i = 0;i<length;i++)           
	{
			dis_data[length-i-1] = ((dat%10)+'0');	       
			dat = dat/10;	
	}	

    return dis_data;
}

//char Strlen(char *str)
//{
//    char i = 0;
//    while(str[i] != '\0') i++;
//    return i;
//}

//char *Dis_Str(char *str1,char *str2)
//{
//    char inew = 0,i1 = 0, i2 = 0;
//    while(i1<Strlen(str1))
//    {
//       dis_str[inew++] = str1[i1++];
//    }
//    while(i2<Strlen(str2))
//    {
//       dis_str[inew++] = str2[i2++];
//    }
//    while(inew<16)
//    {
//        dis_str[inew++] =' ';
//    }
//    return dis_str;
//}

void delay(unsigned long ten_us)
{
    while(ten_us--)     
    {_nop_();_nop_();_nop_();_nop_();_nop_();_nop_();_nop_();_nop_();_nop_();_nop_();}
}

void Time1_init()                               
{
        TMOD|=0X10;     
        TH1 = (65536-1000)/256;
        TL1 = (65536-1000);   
        ET1=1;                        
        EA=1;                                                   
}

void Timer_1() interrupt 3
{
        TH1 = (65536-1000)/256;
        TL1 = (65536-1000);   
        time_flag++;
        if(time_flag==1000)
        {          
        time_flag = 0;      //定时到1s将time_flag清零 
         time++;        //time每1s加1
        }   
}
