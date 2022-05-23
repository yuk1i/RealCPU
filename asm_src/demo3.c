#include "utils/uart.h"

volatile int* mmio_sw = (int*) 0xFFFF0000;
volatile int* mmio_led = (int*) 0xFFFF0080;

extern int main() {
    put_string("run demo3");
    while(1) {
        for(int i=0;i<23;i++) {
            mmio_led[i] = mmio_sw[i];
        }
    }
}