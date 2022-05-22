#include "uart.h"

volatile int * uart_rx_valid    = (int *) ADDR_UART_RX_VALID;
volatile int * uart_rx_fifo     = (int *) ADDR_UART_RX_FIFO;
volatile int * uart_tx_busy     = (int *) ADDR_UART_TX_BUSY;
volatile int * uart_tx_full     = (int *) ADDR_UART_TX_FULL;
volatile int * uart_tx_send     = (int *) ADDR_UART_TX_SEND;
volatile int * uart_tx_fifo     = (int *) ADDR_UART_TX_FIFO;

void put_char(char a) {
    if (*uart_tx_full) return;
    *uart_tx_fifo = (unsigned int) a;
    if (!*uart_tx_send) *uart_tx_send = 1;
}

void put_string(char* str) {
    if (*uart_tx_full) return;
    while(*str && !*uart_tx_full) {
        *uart_tx_fifo = *str;
        str++;
    }
    if (!*uart_tx_send) *uart_tx_send = 1;
}

void put_hex_int32(int d) {
    for(int i=0;i<8;i++) {
        while (*uart_tx_full) asm volatile ("":::"memory");
        *uart_tx_fifo = d & 0xF0000000U;
        d = d << 4;
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
    for(int i=0;i<8;i++) {
        while (!*uart_rx_valid) asm volatile ("":::"memory");
        unsigned char get = (unsigned char) *uart_rx_fifo;
        tmp = tmp << 4;
        tmp = tmp | get;
    }
    return tmp;
}

int uart_can_read() {
    return *uart_rx_valid;
}