#include "uart.h"

volatile int * uart_rx_valid    = (int *) ADDR_UART_RX_VALID;
volatile int * uart_rx_fifo     = (int *) ADDR_UART_RX_FIFO;
volatile int * uart_tx_busy     = (int *) ADDR_UART_TX_BUSY;
volatile int * uart_tx_full     = (int *) ADDR_UART_TX_FULL;
volatile int * uart_tx_send     = (int *) ADDR_UART_TX_SEND;
volatile int * uart_tx_fifo     = (int *) ADDR_UART_TX_FIFO;

void put_char(char a) {
    // while (*uart_tx_full) asm volatile ("":::"memory");
    *uart_tx_fifo = (unsigned int) a;
    *uart_tx_send = 1;
}

void put_string(char* str) {
    while(*str) {
        // while (*uart_tx_full) asm volatile ("":::"memory");
        *uart_tx_fifo = (unsigned int) *str;
        str++;
    }
    *uart_tx_send = 1;
}

void put_hex_int32(unsigned int d) {
    for(int i=0;i<4;i++) {
        *uart_tx_fifo = (d & 0xFF000000U) >> 24;
        d = d << 8;
    }
}


int read_string(char* dst, int max_len) {
    register int len = 0;
    while (len < max_len) {
        while (!*uart_rx_valid) asm volatile ("":::"memory");
        // fifo is ready
        char get = (char) *uart_rx_fifo;
        if (get == ' ' || get == '\n' || get == '\t' || get == '\r')
            break;
        *dst = get;
        dst++;
        len++;
    }
    *dst = '\0';
    return len;
}

unsigned int read_hex_int32() {
    register unsigned int tmp = 0;
    for(int i=0;i<4;i++) {
        while (!*uart_rx_valid) asm volatile ("":::"memory");
        unsigned char get = (unsigned char) *uart_rx_fifo;
        tmp = tmp << 8;
        tmp = tmp | (get & 0xFF);
    }
    return tmp;
}

unsigned char read_byte() {
    while (!*uart_rx_valid) asm volatile ("":::"memory");
    unsigned int get = (unsigned int) *uart_rx_fifo;
    return (unsigned char) (get & 0xFF);
}

inline int uart_can_read() {
    return *uart_rx_valid;
}