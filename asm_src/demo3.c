#include "utils/seg7.h"
#include "utils/uart.h"


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
        unsigned int c;
        c = a << b;
        // display(b | (a<<8) | (c<<16));
        // put_string("h1");
        for(int i = 0; i < 8; i++){
            mmio_led[i] = ((1<<i) & c) != 0;
            // put_char('0' + i);
        }
        // put_string("h2");
    }
}