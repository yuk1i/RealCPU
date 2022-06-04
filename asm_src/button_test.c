#include "utils/uart.h"
#include "io.h"
#include "utils/seg7.h"

#define ADDR_BTN 0xFFFF0200
#define ADDR_KEYPAD 0xFFFF0240

extern int main() {
    register volatile int * mmio_btn = (int*) ADDR_BTN;
    register volatile int * mmio_keypad = (int*) ADDR_KEYPAD;
    put_string("qwq");
    unsigned int num = 0;
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
        for(int i=0;i<16;i++) {
            if (mmio_keypad[i]) {
                put_string("keypad down:");
                put_char(i < 10 ? '0' + i : 'a' + i - 10);
                put_char('\n');
		num = num << 4 | i;
                while(mmio_keypad[i]) asm volatile ("":::"memory");
                put_string("keypad releases\n");
            }
        }
	display(num);
    }
}
