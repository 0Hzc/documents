#include"pbdata.h"
        unsigned  int   dir1 = 0;
        unsigned  int   dir2 = 0;
        unsigned  int   dir3 = 0;
        unsigned  int   dir4 = 0;        
unsigned char Button_Init()
{
        unsigned int i = 1000;

    if(key1==0||key2==0||key3==0||key4==0)
        {
        while(i--);
        if(key1==0)
        { dir1=1;return 1;}
        else if(key2==0)
        {dir2=2;return 2;}
        else if(key3==0)
        {dir3=3;return 3;}
        else if(key4==0)
        {dir4=4;return 4;}
        else
            return 0;
        }
      else 
          return 0;
}
