#include "utils/seg7.h"


volatile int* mmio_sw = (int*) 0xFFFF0000;
volatile int* mmio_led = (int*) 0xFFFF0080;

extern int main() {
    while(1) {
        unsigned int b = 0;
        for(int i=0;i<8;i++) {
            b = b | ((mmio_sw[i] & 0x1) << (i));
        }
        unsigned int a = 0;
        for(int i=8;i<16;i++) {
            a = a | ((mmio_sw[i] & 0x1) << (i-8));
        }
        signed char sa = a & 0xFF;
        display((b) | (a << 16) | (sa << 8));
        for(int i=8;i<16;++i) {
            mmio_led[i] = (a & (1 << (i-8))) != 0;
        }

        for(int i=0;i<8;++i) {
            mmio_led[i] = (b & (1 << i)) != 0;
        }
    }
}