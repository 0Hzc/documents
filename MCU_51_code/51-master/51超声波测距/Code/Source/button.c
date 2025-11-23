#include"pbdata.h"
        unsigned  int   dir1 = 0;
        unsigned  int   dir2 = 0;   
unsigned char Button_Init()
{
        unsigned int i = 1000;

    if(key1==0||key2==0)
        {
        while(i--);
        if(key1==0)
        { dir1++;return 1;}
        else if(key2==0)
        {dir2++;return 2;}
        else
            return 0;
        }
      else 
          return 0;
}
