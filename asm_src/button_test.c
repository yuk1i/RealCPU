#include "utils/uart.h"
#include "io.h"

#define ADDR_BTN 0xFFFF0140

extern int main() {
    register volatile int * mmio_btn = (int*) 0xFFFF0140;
    put_string("qwq");
    while(1) {
        for(int i=0;i<5;i++) {
            if (mmio_btn[i]) {
                put_string("btn down:");
                put_char('0' + i);
                put_char('\n');
                while(mmio_btn[i]) asm volatile ("":::"memory");
                put_string("btn releases\n");
            }
        }
    }
}