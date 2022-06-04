#include "utils/uart.h"
#include "utils/seg7.h"

char a;
short b;

extern int main(){
 while (1)
 {
     int texta = read_hex_int32();
     display(texta);
     int textb = read_hex_int32();
     display(textb);
     put_string("\n mul:");
     put_hexstr_int32(texta * textb);

     put_string("\n div:");
     put_hexstr_int32((unsigned int)(texta / textb));

     put_string("\n mod:");
     put_hexstr_int32((unsigned int) (texta % textb));

    }
}