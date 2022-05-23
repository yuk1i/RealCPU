

volatile int* mmio_sw = (int*) 0xFFFF0000;
volatile int* mmio_led = (int*) 0xFFFF0080;
volatile int* mmio_seg7 = (int*) 0xFFFF0100;

volatile int* uart_rx_valid = (int*) 0xFFFF0120;
volatile int* uart_rx_fifo  = (int*) 0xFFFF0124;
volatile int* uart_tx_busy  = (int*) 0xFFFF0128;
volatile int* uart_tx_full  = (int*) 0xFFFF012C;
volatile int* uart_tx_send  = (int*) 0xFFFF0130;
volatile int* uart_tx_fifo  = (int*) 0xFFFF0134;

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
#define SEG7_CHAR_f ((unsigned int) 0b10001110)
#define SEG7_CHAR_i ((unsigned int) 0b01100000)
#define SEG7_CHAR_j ((unsigned int) 0b01110000)
#define SEG7_CHAR_i ((unsigned int) 0b01100000)


unsigned char seg7_hex_to_char[] = {SEG7_CHAR_0,SEG7_CHAR_1,SEG7_CHAR_2,SEG7_CHAR_3,
                                    SEG7_CHAR_4,SEG7_CHAR_5,SEG7_CHAR_6,SEG7_CHAR_7,
                                    SEG7_CHAR_8,SEG7_CHAR_9,SEG7_CHAR_A,SEG7_CHAR_b,
                                    SEG7_CHAR_c,SEG7_CHAR_d,SEG7_CHAR_e,SEG7_CHAR_f};

void display(unsigned int d) {
    for(int i=0;i<8;i++) {
        mmio_seg7[i] = seg7_hex_to_char[d & 0xF];
        d = d >> 4;
    }
}
int bit[8] = {0b00000001, 0b00000010, 0b00000100, 0b00001000, 0b00010000, 0b00100000, 0b01000000, 0b10000000};

extern int cmain() {
    register int c;
    unsigned int decide;
    unsigned int a;
    unsigned int b;
    unsigned int highbit;
    unsigned int is_palindrome = 1;

    const unsigned int bit0 = 0b00000001;
    const unsigned int bit1 = 0b00000010;
    const unsigned int bit2 = 0b00000100;
    const unsigned int bit3 = 0b00001000;
    const unsigned int bit4 = 0b00010000;
    const unsigned int bit5 = 0b00100000;
    const unsigned int bit6 = 0b01000000;
    const unsigned int bit7 = 0b10000000;
    while (1)
    {
        decide = (mmio_sw[23] << 2) | (mmio_sw[22] << 1) | mmio_sw[21];
        a = (mmio_sw[15] << 7) | (mmio_sw[14] << 6) | (mmio_sw[13] << 5) | (mmio_sw[12] << 4) | (mmio_sw[11] << 3) | (mmio_sw[10] << 2) | (mmio_sw[9] << 1) | mmio_sw[8];
        b = (mmio_sw[7] << 7) | (mmio_sw[6] << 6) | (mmio_sw[5] << 5) | (mmio_sw[4] << 4) | (mmio_sw[3] << 3) | (mmio_sw[2] << 2) | (mmio_sw[1] << 1) | mmio_sw[0];
        is_palindrome = 1;
        if(decide == 0){
            for(int i = 0; i < 8; i++){
                mmio_led[i] = mmio_sw[i + 8];
            }
            for(int i = 15; i >= 8; i--){
                c = mmio_sw[i];
                if(c == 1){
                    highbit = i;
                    break;
                }
            }
            for(int i = 8; i <= 8 + (highbit - 8) / 2; i++){
                if(mmio_sw[i] != mmio_sw[highbit - (i - 8)]){
                    is_palindrome = 0;
                    break;
                }
            }  
            if(is_palindrome == 1){
                mmio_led[23] = 1;
            }else{
                mmio_led[23] = 0;
            }
        }else if(decide == 1){
            mmio_led[23] = 0;
            for(int i = 0; i < 16; i++){
                c = mmio_sw[i];
                mmio_led[i] = c;
            }
        }else if(decide == 2){
            mmio_led[23] = 0;
            for(int i = 0; i < 8; i++){
                mmio_led[i] = mmio_sw[i + 8] & mmio_sw[i];
            }
        }else if(decide == 3){
            mmio_led[23] = 0;
            for(int i = 0; i < 8; i++){
                c = mmio_sw[i + 8] | mmio_sw[i];
                mmio_led[i] = c;
            }
        }else if(decide == 4){
            mmio_led[23] = 0;
            for(int i = 0; i < 8; i++){
                c = mmio_sw[i + 8] ^ mmio_sw[i];
                mmio_led[i] = c;
            }
        }else if(decide == 5){
            mmio_led[23] = 0;
            c = a << b;
            int temp;
            for(int i = 0; i < 8; i++){
                temp = bit[i] & c;
                if(temp != 0){
                    mmio_led[i] = 1;
                }else{
                    mmio_led[i] = 0;
                }
            }
        }else if(decide == 6){
            mmio_led[23] = 0;
            c = a >> b;
            int temp;
            for(int i = 0; i < 8; i++){
                temp = bit[i] & c;
                if(temp != 0){
                    mmio_led[i] = 1;
                }else{
                    mmio_led[i] = 0;
                }
            }
        }else if(decide == 7){
            mmio_led[23] = 0;
            c = ((int)a) >> b;
            int temp;
            for(int i = 0; i < 8; i++){
                temp = bit[i] & c;
                if(temp != 0){
                    mmio_led[i] = 1;
                }else{
                    mmio_led[i] = 0;
                }
            }
        }
        }

    }
