#include "utils/uart.h"

volatile int* mmio_sw = (int*) 0xFFFF0000;
volatile int* mmio_led = (int*) 0xFFFF0080;
volatile int* mmio_seg7 = (int*) 0xFFFF0100;


// ABCDEFG_DP
#define SEG7_CHAR_0 ((unsigned int) 0b11111100)
#define SEG7_CHAR_1 ((unsigned int) 0b01100000)
#define SEG7_CHAR_2 ((unsigned int) 0b11011010)
#define SEG7_CHAR_3 ((unsigned int) 0b11110010)
#define SEG7_CHAR_4 ((unsigned int) 0b01100110)
#define SEG7_CHAR_5 ((unsigned int) 0b10110110)
#define SEG7_CHAR_6 ((unsigned int) 0b10111110)
#define SEG7_CHAR_7 ((unsigned int) 0b11100000)
#define SEG7_CHAR_8 ((unsigned int) 0b11111110)
#define SEG7_CHAR_9 ((unsigned int) 0b11100110)
#define SEG7_CHAR_A ((unsigned int) 0b11101110)
#define SEG7_CHAR_b ((unsigned int) 0b00111110)
#define SEG7_CHAR_c ((unsigned int) 0b00011010)
#define SEG7_CHAR_d ((unsigned int) 0b01111010)
#define SEG7_CHAR_e ((unsigned int) 0b10011110)
#define SEG7_CHAR_f ((unsigned int) 0b10001110)
#define SEG7_CHAR_G ((unsigned int) 0b10111110)
#define SEG7_CHAR_H ((unsigned int) 0b01101110)
#define SEG7_CHAR_i ((unsigned int) 0b01100000)
#define SEG7_CHAR_j ((unsigned int) 0b01111000)
#define SEG7_CHAR_k ((unsigned int) 0b01011110)
#define SEG7_CHAR_L ((unsigned int) 0b00011100)
#define SEG7_CHAR_m ((unsigned int) 0b11101100)
#define SEG7_CHAR_n ((unsigned int) 0b00101010)
#define SEG7_CHAR_o ((unsigned int) 0b11111100)
#define SEG7_CHAR_p ((unsigned int) 0b11001110)
#define SEG7_CHAR_q ((unsigned int) 0b11100110)
#define SEG7_CHAR_r ((unsigned int) 0b10001100)
#define SEG7_CHAR_s ((unsigned int) 0b10110110)
#define SEG7_CHAR_t ((unsigned int) 0b11100000)
#define SEG7_CHAR_u ((unsigned int) 0b01111100)
#define SEG7_CHAR_v ((unsigned int) 0b00111000)
#define SEG7_CHAR_w ((unsigned int) 0b01111110)
#define SEG7_CHAR_x ((unsigned int) 0b00100110)
#define SEG7_CHAR_y ((unsigned int) 0b01110110)
#define SEG7_CHAR_z ((unsigned int) 0b11011010)

// unsigned char seg7_hex_to_char[] = {SEG7_CHAR_0,SEG7_CHAR_1,SEG7_CHAR_2,SEG7_CHAR_3,
//                                     SEG7_CHAR_4,SEG7_CHAR_5,SEG7_CHAR_6,SEG7_CHAR_7,
//                                     SEG7_CHAR_8,SEG7_CHAR_9,SEG7_CHAR_A,SEG7_CHAR_b,
//                                     SEG7_CHAR_c,SEG7_CHAR_d,SEG7_CHAR_e,SEG7_CHAR_f};

unsigned int seg7_char_int[] = {SEG7_CHAR_0, SEG7_CHAR_1, SEG7_CHAR_2, SEG7_CHAR_3, SEG7_CHAR_4, SEG7_CHAR_5, SEG7_CHAR_6, SEG7_CHAR_7, SEG7_CHAR_8, SEG7_CHAR_9};
unsigned int seg7_char_alpha[] = {SEG7_CHAR_A, SEG7_CHAR_b, SEG7_CHAR_c, SEG7_CHAR_d, SEG7_CHAR_e, SEG7_CHAR_f, SEG7_CHAR_G, SEG7_CHAR_H, SEG7_CHAR_i, SEG7_CHAR_j, SEG7_CHAR_k, SEG7_CHAR_L, SEG7_CHAR_m, SEG7_CHAR_n, SEG7_CHAR_o, SEG7_CHAR_p, SEG7_CHAR_q, SEG7_CHAR_r, SEG7_CHAR_s, SEG7_CHAR_t, SEG7_CHAR_u, SEG7_CHAR_v, SEG7_CHAR_w, SEG7_CHAR_x, SEG7_CHAR_y, SEG7_CHAR_z};

unsigned int get_seg7_char(char a) {
    // [0-9][a-z][A-Z]
    if (a >= '0' && a <= '9') return seg7_char_int[a - '0'];
    if (a >= 'a' && a <= 'z') return seg7_char_alpha[a - 'a'];
    if (a >= 'A' && a <= 'Z') return seg7_char_alpha[a - 'A'];
    return (unsigned int) 0b00000001;
}

// void display(unsigned int d) {
//     for(int i=0;i<8;i++) {
//         mmio_seg7[i] = seg7_hex_to_char[d & 0xF];
//         d = d >> 4;
//     }
// }
int bit[8] = {0b00000001, 0b00000010, 0b00000100, 0b00001000, 0b00010000, 0b00100000, 0b01000000, 0b10000000};

extern int main() {
    put_string("run demo1\n");
    register int c;
    unsigned int decide = 0;
    unsigned int a;
    unsigned int b;
    unsigned int highbit;
    unsigned int is_palindrome = 1;

    unsigned int last_decide = 0;
    while (1)
    {
        
        mmio_led[22] = mmio_sw[23];
        mmio_led[21] = mmio_sw[22];
        mmio_led[20] = mmio_sw[21];
        if (last_decide!=decide) {
            put_string("change mode to ");
            put_char(decide + '0');
            put_char('\n');
        }
        last_decide = decide;

        decide = (mmio_sw[23] << 2) | (mmio_sw[22] << 1) | mmio_sw[21];
        a = (mmio_sw[15] << 7) | (mmio_sw[14] << 6) | (mmio_sw[13] << 5) | (mmio_sw[12] << 4) | (mmio_sw[11] << 3) | (mmio_sw[10] << 2) | (mmio_sw[9] << 1) | mmio_sw[8];
        b = (mmio_sw[7] << 7) | (mmio_sw[6] << 6) | (mmio_sw[5] << 5) | (mmio_sw[4] << 4) | (mmio_sw[3] << 3) | (mmio_sw[2] << 2) | (mmio_sw[1] << 1) | mmio_sw[0];
        is_palindrome = 1;

        if (decide != 0){
            mmio_led[23] = 0;
        }
        if(decide == 0){
            for(int i = 0; i < 8; i++){
                mmio_led[i] = mmio_sw[i + 8];
            }
            highbit = 15;
            for(int i = 15; i >= 8; i--){
                if(mmio_sw[i] == 1){
                    highbit = i;
                    break;
                }
            }
            is_palindrome = 1;
            for(int i = 8; i <= 8 + ((highbit - 8) >> 1); i++){
                if(mmio_sw[i] != mmio_sw[highbit - (i - 8)]){
                    is_palindrome = 0;
                    break;
                }
            }
            mmio_led[23] = is_palindrome;
        }else if(decide == 1){
            mmio_led[23] = 0;
            for(int i = 0; i < 16; i++) {
                mmio_led[i] = mmio_sw[i];
            }
        }else if(decide == 2){
            mmio_led[23] = 0;
            for(int i = 0; i < 8; i++) {
                mmio_led[i] = mmio_sw[i + 8] & mmio_sw[i];
            }
        }else if(decide == 3){
            mmio_led[23] = 0;
            for(int i = 0; i < 8; i++) {
                mmio_led[i] = mmio_sw[i + 8] | mmio_sw[i];
            }
        }else if(decide == 4){
            mmio_led[23] = 0;
            for(int i = 0; i < 8; i++){
                mmio_led[i] = mmio_sw[i + 8] ^ mmio_sw[i];
            }
        }else if(decide == 5){
            mmio_led[23] = 0;
            c = a << b;
            for(int i = 0; i < 8; i++){
                mmio_led[i] = (bit[i] & c) != 0;
            }
        }else if(decide == 6){
            mmio_led[23] = 0;
            c = a >> b;
            for(int i = 0; i < 8; i++){
                mmio_led[i] = (bit[i] & c) != 0;
            }
        }else if(decide == 7){
            mmio_led[23] = 0;
            signed char sa = a & 0xFF;
            signed char sc = sa >> b;
            for(int i = 0; i < 8; i++){
                mmio_led[i] = ((1 << i) & sc) != 0;
            }
        }
    }
}
