#include "seg7.h"



unsigned char seg7_hex_to_char[] = {SEG7_CHAR_0,SEG7_CHAR_1,SEG7_CHAR_2,SEG7_CHAR_3,
                                    SEG7_CHAR_4,SEG7_CHAR_5,SEG7_CHAR_6,SEG7_CHAR_7,
                                    SEG7_CHAR_8,SEG7_CHAR_9,SEG7_CHAR_A,SEG7_CHAR_B,
                                    SEG7_CHAR_C,SEG7_CHAR_D,SEG7_CHAR_E,SEG7_CHAR_F};
                                    
void display(unsigned int d) {
    volatile int* mmio_seg7 = (int*) SEG7_BASE_ADDR;
    for(int i=0;i<8;i++) {
        mmio_seg7[i] = seg7_hex_to_char[d & 0xF];
        d = d >> 4;
    }
}