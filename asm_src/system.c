

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

unsigned int seg7_char_int[] = {SEG7_CHAR_0, SEG7_CHAR_1, SEG7_CHAR_2};
unsigned int seg7_char_alpha[] = {SEG7_CHAR_A, SEG7_CHAR_b, SEG7_CHAR_c};

unsigned int get_seg7_char(char a) {
    // [0-9][a-z][A-Z]
    if (a>='0' && a<='9') return seg7_char_int[a-'0'];
    if (a>='a' && a <= 'z') return seg7_char_alpha[a-'a'];
    return (unsigned int) 0b00000001;
}


extern int cmain() {
    register int a;
    while (1)
    {
        mmio_seg7[0] = SEG7_CHAR_0;
        mmio_seg7[1] = SEG7_CHAR_1;
        mmio_seg7[2] = SEG7_CHAR_2;
        mmio_seg7[3] = SEG7_CHAR_3;
        mmio_seg7[4] = SEG7_CHAR_4;
        mmio_seg7[5] = SEG7_CHAR_5;
        mmio_seg7[6] = SEG7_CHAR_6;
        mmio_seg7[7] = SEG7_CHAR_7;
        for(int i=0;i<24;i++) {
            a = mmio_sw[i];
            mmio_led[i] = a;
        }
    }
}
