#include"pbdata.h"
#include"intrins.h"
unsigned char i,length,dat_length;
unsigned char dis_data[20],dis_data1[20];    
unsigned  long time0_flag; 
unsigned long h;
unsigned char dis_str[20]={0};
char* data_str(unsigned long dat)
{        
       for(i = 0;i<20;i++)
    {
        dis_data[i] = 0;
    
    }
		dat_length = dat;	
		for(length =0;dat_length!= 0;length++)	    //测量传递的数有多长
	{	
			dat_length = dat_length/10;
	}	
		for(i = 0;i<length;i++)            //将每一位对应的值存入数组dis_data1[]
	{
			dis_data1[i] = ((dat%10)+'0');	       
			dat = dat/10;	
	}	
    for(i = 0;i<length;i++)
    {
           dis_data[i] = dis_data1[(length-i-1)];
    }
    return dis_data;

}
void delay(unsigned long delay_ten)        
{
    while(delay_ten--)
        _nop_();
}

char Strlen(char *str)
{
    char i = 0;
    while(str[i] != '\0') i++;
    return i;
}

char *Dis_Str(char *str1,char *str2)
{
    char inew = 0,i1 = 0, i2 = 0;
    while(i1<Strlen(str1))
    {
       dis_str[inew++] = str1[i1++];
    }
    while(i2<Strlen(str2))
    {
       dis_str[inew++] = str2[i2++];
    }
//    while(inew<9)
//    {
//        dis_str[inew++] =' ';
//    }
    return dis_str;
}


