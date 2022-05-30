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
        for(int i=0;i<len;i++) {
            data1[i] = src[i];
        }
        for(int i=0;i<len;i++) {
            put_hexstr_int32(data1[i]);
            put_char(' ');
            delay(500);
        }
        put_string("\n");
        for(int i = 0; i < len - 1; i++) {
            put_string("i: ");
            put_hexstr_int32(i);
            put_string("\n");
            int k = i;
            for(int j = i + 1; j < len; j++){
                if(data1[j] < data1[k]){ 
                    k = j;
                    // put_string("find k: ");
                    // put_hexstr_int32(k);
                    // put_string("\n");
                }
            }
            if(i != k){
                put_string("swap ik, i: ");
                put_hexstr_int32(data1[i]);
                put_string(" k:");
                put_hexstr_int32(data1[k]);
                put_string("\n");
                delay(500);
                int temp = data1[i];
                data1[i] = data1[k];
                data1[k] = temp;
            }
            put_char('\n');
            put_string("current:");
            for(int i=0;i<len;i++) {
                put_hexstr_int32(data1[i]);
                put_char(' ');
                delay(500);
            }
            put_char('\n');
        }
        while(!mmio_btn[0]) asm volatile ("":::"memory");
        for(int i=0;i<len;i++) {
            put_hexstr_int32(data1[i]);
            put_char(' ');
        }
        put_char('\n');
    }
}