#include "utils/seg7.h"
#include "utils/uart.h"
#include "io.h"

#define ADDR_BTN 0xFFFF0200

volatile int* mmio_sw = (int*) 0xFFFF0000;
volatile int* mmio_led = (int*) 0xFFFF0080;
int src[20] = {9,7,1,3,5 ,2,3,9,12,3 ,4};
int data1[20];

void delay(int ms) {
    for(int i=0;i<ms;i++) {
        delay_1ms();
    } 
}

extern int main() {
    while(1) {
        register volatile int * mmio_btn = (int*) ADDR_BTN;
        int len = 11;
        for (int i=0;i<len;i++) {
            put_hexstr_int32(src[i]);
            put_char(' ');
            float a = src[i];
            void * ptr = &a;
            int intf = *((int*)ptr);
            put_hexstr_int32(intf);
            put_char('\n');
        }
    }
}