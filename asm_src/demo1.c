#include "utils/uart.h"
#include "utils/seg7.h"
#include "io.h"

#define ADDR_BTN 0xFFFF0200
volatile int* mmio_sw = (int*) 0xFFFF0000;
volatile int* mmio_led = (int*) 0xFFFF0080;
volatile int* mmio_seg7 = (int*) 0xFFFF0100;



// unsigned char seg7_hex_to_char[] = {SEG7_CHAR_0,SEG7_CHAR_1,SEG7_CHAR_2,SEG7_CHAR_3,
//                                     SEG7_CHAR_4,SEG7_CHAR_5,SEG7_CHAR_6,SEG7_CHAR_7,
//                                     SEG7_CHAR_8,SEG7_CHAR_9,SEG7_CHAR_A,SEG7_CHAR_b,
//                                     SEG7_CHAR_c,SEG7_CHAR_d,SEG7_CHAR_e,SEG7_CHAR_f};

// unsigned int seg7_char_int[] = {SEG7_CHAR_0, SEG7_CHAR_1, SEG7_CHAR_2, SEG7_CHAR_3, SEG7_CHAR_4, SEG7_CHAR_5, SEG7_CHAR_6, SEG7_CHAR_7, SEG7_CHAR_8, SEG7_CHAR_9};
// unsigned int seg7_char_alpha[] = {SEG7_CHAR_A, SEG7_CHAR_b, SEG7_CHAR_c, SEG7_CHAR_d, SEG7_CHAR_e, SEG7_CHAR_f, SEG7_CHAR_G, SEG7_CHAR_H, SEG7_CHAR_i, SEG7_CHAR_j, SEG7_CHAR_k, SEG7_CHAR_L, SEG7_CHAR_m, SEG7_CHAR_n, SEG7_CHAR_o, SEG7_CHAR_p, SEG7_CHAR_q, SEG7_CHAR_r, SEG7_CHAR_s, SEG7_CHAR_t, SEG7_CHAR_u, SEG7_CHAR_v, SEG7_CHAR_w, SEG7_CHAR_x, SEG7_CHAR_y, SEG7_CHAR_z};

// unsigned int get_seg7_char(char a) {
//     // [0-9][a-z][A-Z]
//     if (a >= '0' && a <= '9') return seg7_char_int[a - '0'];
//     if (a >= 'a' && a <= 'z') return seg7_char_alpha[a - 'a'];
//     if (a >= 'A' && a <= 'Z') return seg7_char_alpha[a - 'A'];
//     return (unsigned int) 0b00000001;
// }

// void display(unsigned int d) {
//     for(int i=0;i<8;i++) {
//         mmio_seg7[i] = seg7_hex_to_char[d & 0xF];
//         d = d >> 4;
//     }
// }

unsigned int last_decide = 0;
int replace[16];
int bit[16] = {0b00000001, 0b00000010, 0b00000100, 0b00001000, 0b00010000, 0b00100000, 0b01000000, 0b10000000, 0b100000000, 0b1000000000,0b10000000000,0b100000000000,0b1000000000000,0b10000000000000,0b100000000000000,0b1000000000000000};
extern int main() {
    put_string("run demo1\n");
    register volatile int * mmio_btn = (int*) ADDR_BTN;
    register int c = 0;
    unsigned int decide = 0;
    unsigned int a = 0;
    unsigned int b = 0;
    unsigned int highbit;
    unsigned int is_palindrome = 0;

    while (1)
    {
        
        mmio_led[23] = mmio_sw[23];
        mmio_led[22] = mmio_sw[22];
        mmio_led[21] = mmio_sw[21];
        
        if (last_decide != decide) {
            put_string("change mode to ");
            put_char(decide + '0');
            put_char('\n');
            last_decide = decide;
        }

        decide = (mmio_sw[23] << 2) | (mmio_sw[22] << 1) | mmio_sw[21];
        a = (mmio_sw[15] << 15) |(mmio_sw[14] << 14) |(mmio_sw[13] << 13) |(mmio_sw[12] << 12) |(mmio_sw[11] << 11) |(mmio_sw[10] << 10) |(mmio_sw[9] << 9) |(mmio_sw[8] << 8) |(mmio_sw[7] << 7) | (mmio_sw[6] << 6) | (mmio_sw[5] << 5) | (mmio_sw[4] << 4) | (mmio_sw[3] << 3) | (mmio_sw[2] << 2) | (mmio_sw[1] << 1) | mmio_sw[0];
        for(int i=0;i<16;i++) {
            a = a | ((mmio_sw[i] & 0x1) << (i-8));
        }
        for(int i=0;i<8;i++) {
            b = b | ((mmio_sw[i] & 0x1) << (i));
        }
        is_palindrome = 0;

        if(decide == 1) {
            // use least 8 bit
            mmio_led[19] = 0;
            mmio_led[15] = mmio_sw[15];
            for(int i = 0; i < 15; i++){
                mmio_led[i] = mmio_sw[i];
            }
            highbit = 15;
            for(int i = 15; i >= 0; i--){
                if(mmio_sw[i] == 1){
                    highbit = i;
                    break;
                }
            }
            is_palindrome = 1;
            register unsigned int left = 0;
            while(highbit>left) {
                if ((mmio_sw[highbit] == 1 && mmio_sw[left] == 0) || (mmio_sw[highbit] == 0 && mmio_sw[left] == 1)) {
                    is_palindrome = 0;
                    break;
                }
                highbit--;
                left++;
            }
            display(highbit | (is_palindrome << 4) | (left << 8) | (1<<12));
            mmio_led[20] = is_palindrome;
        }else if(decide == 0){
            mmio_led[20] = 0;
            mmio_led[19] = 0;
            if (mmio_btn[0]) {
                while(mmio_btn[0]) asm volatile ("":::"memory");
                for(int i = 0; i < 24; i++){
                    mmio_led[i] = mmio_sw[i];
                }
            }
        }else if(decide == 2){
            mmio_led[20] = 0;
            mmio_led[19] = 1;
            mmio_led[18] = 0;
            if (mmio_btn[0]) {
                while(mmio_btn[0]) asm volatile ("":::"memory");
                put_string("1");
                int a1 = (mmio_sw[15] << 15) |(mmio_sw[14] << 14) |(mmio_sw[13] << 13) |(mmio_sw[12] << 12) |(mmio_sw[11] << 11) |(mmio_sw[10] << 10) |(mmio_sw[9] << 9) |(mmio_sw[8] << 8) |(mmio_sw[7] << 7) | (mmio_sw[6] << 6) | (mmio_sw[5] << 5) | (mmio_sw[4] << 4) | (mmio_sw[3] << 3) | (mmio_sw[2] << 2) | (mmio_sw[1] << 1) | mmio_sw[0];
                put_char('0' + a1);
                for(int i = 0; i < 16; i++){
                    replace[i] = mmio_sw[i];
                }
                mmio_led[19] = 0;
                mmio_led[18] = 1;
                while(!mmio_btn[0]) asm volatile ("":::"memory");
                if (mmio_btn[0]) {
                    while(mmio_btn[0]) asm volatile ("":::"memory");
                    put_string("2");
                    int b1 = (mmio_sw[15] << 15) |(mmio_sw[14] << 14) |(mmio_sw[13] << 13) |(mmio_sw[12] << 12) |(mmio_sw[11] << 11) |(mmio_sw[10] << 10) |(mmio_sw[9] << 9) |(mmio_sw[8] << 8) |(mmio_sw[7] << 7) | (mmio_sw[6] << 6) | (mmio_sw[5] << 5) | (mmio_sw[4] << 4) | (mmio_sw[3] << 3) | (mmio_sw[2] << 2) | (mmio_sw[1] << 1) | mmio_sw[0];
                    for(int i = 0; i < 16; i++){
                        mmio_led[i] = replace[i] & mmio_sw[i];
                    }
                }
                mmio_led[18] = 0;
            }
        }else if(decide == 3){
            mmio_led[20] = 0;
            mmio_led[19] = 1;
            mmio_led[18] = 0;
            if (mmio_btn[0]) {
                while(mmio_btn[0]) asm volatile ("":::"memory");
                put_string("1");
                int a1 = (mmio_sw[15] << 15) |(mmio_sw[14] << 14) |(mmio_sw[13] << 13) |(mmio_sw[12] << 12) |(mmio_sw[11] << 11) |(mmio_sw[10] << 10) |(mmio_sw[9] << 9) |(mmio_sw[8] << 8) |(mmio_sw[7] << 7) | (mmio_sw[6] << 6) | (mmio_sw[5] << 5) | (mmio_sw[4] << 4) | (mmio_sw[3] << 3) | (mmio_sw[2] << 2) | (mmio_sw[1] << 1) | mmio_sw[0];
                put_char('0' + a1);
                for(int i = 0; i < 16; i++){
                    replace[i] = mmio_sw[i];
                }
                mmio_led[19] = 0;
                mmio_led[18] = 1;
                while(!mmio_btn[0]) asm volatile ("":::"memory");
                if (mmio_btn[0]) {
                    while(mmio_btn[0]) asm volatile ("":::"memory");
                    put_string("2");
                    int b1 = (mmio_sw[15] << 15) |(mmio_sw[14] << 14) |(mmio_sw[13] << 13) |(mmio_sw[12] << 12) |(mmio_sw[11] << 11) |(mmio_sw[10] << 10) |(mmio_sw[9] << 9) |(mmio_sw[8] << 8) |(mmio_sw[7] << 7) | (mmio_sw[6] << 6) | (mmio_sw[5] << 5) | (mmio_sw[4] << 4) | (mmio_sw[3] << 3) | (mmio_sw[2] << 2) | (mmio_sw[1] << 1) | mmio_sw[0];
                    for(int i = 0; i < 16; i++){
                        mmio_led[i] = replace[i] | mmio_sw[i];
                    }
                }
            }
        }else if(decide == 4){
            mmio_led[20] = 0;
            mmio_led[19] = 1;
            mmio_led[18] = 0;
            if (mmio_btn[0]) {
                while(mmio_btn[0]) asm volatile ("":::"memory");
                put_string("1");
                int a1 = (mmio_sw[15] << 15) |(mmio_sw[14] << 14) |(mmio_sw[13] << 13) |(mmio_sw[12] << 12) |(mmio_sw[11] << 11) |(mmio_sw[10] << 10) |(mmio_sw[9] << 9) |(mmio_sw[8] << 8) |(mmio_sw[7] << 7) | (mmio_sw[6] << 6) | (mmio_sw[5] << 5) | (mmio_sw[4] << 4) | (mmio_sw[3] << 3) | (mmio_sw[2] << 2) | (mmio_sw[1] << 1) | mmio_sw[0];
                put_char('0' + a1);
                for(int i = 0; i < 16; i++){
                    replace[i] = mmio_sw[i];
                }
                mmio_led[19] = 0;
                mmio_led[18] = 1;
                while(!mmio_btn[0]) asm volatile ("":::"memory");
                if (mmio_btn[0]) {
                    while(mmio_btn[0]) asm volatile ("":::"memory");
                    put_string("2");
                    int b1 = (mmio_sw[15] << 15) |(mmio_sw[14] << 14) |(mmio_sw[13] << 13) |(mmio_sw[12] << 12) |(mmio_sw[11] << 11) |(mmio_sw[10] << 10) |(mmio_sw[9] << 9) |(mmio_sw[8] << 8) |(mmio_sw[7] << 7) | (mmio_sw[6] << 6) | (mmio_sw[5] << 5) | (mmio_sw[4] << 4) | (mmio_sw[3] << 3) | (mmio_sw[2] << 2) | (mmio_sw[1] << 1) | mmio_sw[0];
                    for(int i = 0; i < 16; i++){
                        mmio_led[i] = replace[i] ^ mmio_sw[i];
                    }
                }
            }
        }else if(decide == 5){
            mmio_led[20] = 0;
            mmio_led[19] = 1;
            mmio_led[18] = 0;
            if (mmio_btn[0]) {
                while(mmio_btn[0]) asm volatile ("":::"memory");
                put_string("1");
                int a1 = (mmio_sw[15] << 15) |(mmio_sw[14] << 14) |(mmio_sw[13] << 13) |(mmio_sw[12] << 12) |(mmio_sw[11] << 11) |(mmio_sw[10] << 10) |(mmio_sw[9] << 9) |(mmio_sw[8] << 8) |(mmio_sw[7] << 7) | (mmio_sw[6] << 6) | (mmio_sw[5] << 5) | (mmio_sw[4] << 4) | (mmio_sw[3] << 3) | (mmio_sw[2] << 2) | (mmio_sw[1] << 1) | mmio_sw[0];
                put_char('0' + a1);
                for(int i = 0; i < 16; i++){
                    replace[i] = mmio_sw[i];
                }
                mmio_led[19] = 0;
                mmio_led[18] = 1;
                while(!mmio_btn[0]) asm volatile ("":::"memory");
                if (mmio_btn[0]) {
                    while(mmio_btn[0]) asm volatile ("":::"memory");
                    
                    int b1 = (mmio_sw[15] << 15) |(mmio_sw[14] << 14) |(mmio_sw[13] << 13) |(mmio_sw[12] << 12) |(mmio_sw[11] << 11) |(mmio_sw[10] << 10) |(mmio_sw[9] << 9) |(mmio_sw[8] << 8) |(mmio_sw[7] << 7) | (mmio_sw[6] << 6) | (mmio_sw[5] << 5) | (mmio_sw[4] << 4) | (mmio_sw[3] << 3) | (mmio_sw[2] << 2) | (mmio_sw[1] << 1) | mmio_sw[0];
                    int c = a1 << b1;
                    put_char('0' + c);
                    for(int i = 0; i < 16; i++){
                        mmio_led[i] = ((1<<i) & c) != 0;
                    }
                }
            }
            // a = (mmio_sw[15] << 7) | (mmio_sw[14] << 6) | (mmio_sw[13] << 5) | (mmio_sw[12] << 4) | (mmio_sw[11] << 3) | (mmio_sw[10] << 2) | (mmio_sw[9] << 1) | mmio_sw[8];
            // b = (mmio_sw[7] << 7) | (mmio_sw[6] << 6) | (mmio_sw[5] << 5) | (mmio_sw[4] << 4) | (mmio_sw[3] << 3) | (mmio_sw[2] << 2) | (mmio_sw[1] << 1) | mmio_sw[0];
            // // c = a << b;
            // for(int i = 0; i < 8; i++){
            //     mmio_led[i] = ((1<<i) & c) != 0;
            // }
        }else if(decide == 6){
            mmio_led[20] = 0;
            mmio_led[19] = 1;
            mmio_led[18] = 0;
            if (mmio_btn[0]) {
                while(mmio_btn[0]) asm volatile ("":::"memory");
                put_string("1");
                int a1 = (mmio_sw[15] << 15) |(mmio_sw[14] << 14) |(mmio_sw[13] << 13) |(mmio_sw[12] << 12) |(mmio_sw[11] << 11) |(mmio_sw[10] << 10) |(mmio_sw[9] << 9) |(mmio_sw[8] << 8) |(mmio_sw[7] << 7) | (mmio_sw[6] << 6) | (mmio_sw[5] << 5) | (mmio_sw[4] << 4) | (mmio_sw[3] << 3) | (mmio_sw[2] << 2) | (mmio_sw[1] << 1) | mmio_sw[0];
                put_char('0' + a1);
                for(int i = 0; i < 16; i++){
                    replace[i] = mmio_sw[i];
                }
                mmio_led[19] = 0;
                mmio_led[18] = 1;
                while(!mmio_btn[0]) asm volatile ("":::"memory");
                if (mmio_btn[0]) {
                    while(mmio_btn[0]) asm volatile ("":::"memory");
                    
                    int b1 = (mmio_sw[15] << 15) |(mmio_sw[14] << 14) |(mmio_sw[13] << 13) |(mmio_sw[12] << 12) |(mmio_sw[11] << 11) |(mmio_sw[10] << 10) |(mmio_sw[9] << 9) |(mmio_sw[8] << 8) |(mmio_sw[7] << 7) | (mmio_sw[6] << 6) | (mmio_sw[5] << 5) | (mmio_sw[4] << 4) | (mmio_sw[3] << 3) | (mmio_sw[2] << 2) | (mmio_sw[1] << 1) | mmio_sw[0];
                    int c = a1 >> b1;
                    put_char('0' + c);
                    for(int i = 0; i < 16; i++){
                        mmio_led[i] = ((1<<i) & c) != 0;
                    }
                }
            }
        }else if(decide == 7) {
            mmio_led[20] = 0;
            mmio_led[19] = 1;
            mmio_led[18] = 0;
            if (mmio_btn[0]) {
                while(mmio_btn[0]) asm volatile ("":::"memory");
                put_string("1");
                int a1 = (mmio_sw[15] << 15) |(mmio_sw[14] << 14) |(mmio_sw[13] << 13) |(mmio_sw[12] << 12) |(mmio_sw[11] << 11) |(mmio_sw[10] << 10) |(mmio_sw[9] << 9) |(mmio_sw[8] << 8) |(mmio_sw[7] << 7) | (mmio_sw[6] << 6) | (mmio_sw[5] << 5) | (mmio_sw[4] << 4) | (mmio_sw[3] << 3) | (mmio_sw[2] << 2) | (mmio_sw[1] << 1) | mmio_sw[0];
                put_char('0' + a1);
                for(int i = 0; i < 16; i++){
                    replace[i] = mmio_sw[i];
                }
                mmio_led[19] = 0;
                mmio_led[18] = 1;
                while(!mmio_btn[0]) asm volatile ("":::"memory");
                if (mmio_btn[0]) {
                    while(mmio_btn[0]) asm volatile ("":::"memory");
                    
                    int b1 = (mmio_sw[15] << 15) |(mmio_sw[14] << 14) |(mmio_sw[13] << 13) |(mmio_sw[12] << 12) |(mmio_sw[11] << 11) |(mmio_sw[10] << 10) |(mmio_sw[9] << 9) |(mmio_sw[8] << 8) |(mmio_sw[7] << 7) | (mmio_sw[6] << 6) | (mmio_sw[5] << 5) | (mmio_sw[4] << 4) | (mmio_sw[3] << 3) | (mmio_sw[2] << 2) | (mmio_sw[1] << 1) | mmio_sw[0];
                    signed short sa = a1 & 0xFFFF;
                    signed short sc = sa >> b1;
                    put_char('0' + c);
                    for(int i = 0; i < 16; i++) {
                        mmio_led[i] = ((1 << i) & ((unsigned short) sc)) != 0;
                    }
                }
            }
            // signed char sa = a & 0xFF;
            // signed char sc = sa >> b;
            // display((sa << 16) | (b & 0xFF));
            // for(int i = 0; i < 8; i++) {
            //     mmio_led[i] = ((1 << i) & ((unsigned char) sc)) != 0;
            // }
        }
    }
}
