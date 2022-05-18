

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

extern int cmain() {
    register int counter = 0;
    register int c2 = 0;
    *uart_tx_fifo = 'B';
    *uart_tx_fifo = 'o';
    *uart_tx_fifo = 'o';
    *uart_tx_fifo = 't';
    *uart_tx_send = 1;
    while(*uart_tx_busy) {
        asm volatile("":::"memory");
    }
    while (1)
    {
        // int rx_valid = *uart_rx_valid;
        // int get = *uart_rx_fifo;
        if (*uart_rx_valid && !*uart_tx_busy && mmio_sw[0]) {
            while(*uart_rx_valid) {
                *uart_tx_fifo = *uart_rx_fifo;
                asm volatile("":::"memory");
            }
            *uart_tx_send = 1;
            while(*uart_tx_busy) {
                mmio_led[0] = *uart_tx_busy;
                asm volatile("":::"memory");
            }
            counter++;
        }
        display(counter);
        mmio_led[0] = *uart_rx_valid;
        mmio_led[1] = *uart_tx_busy;
        mmio_led[2] = *uart_tx_full;
        mmio_led[3] = *uart_tx_send;
    }
}
