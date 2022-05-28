#include "uart.h"
#include "../io.h"

// volatile int * uart_rx_valid    = (int *) ADDR_UART_RX_VALID;
// volatile int * uart_rx_fifo     = (int *) ADDR_UART_RX_FIFO;
// volatile int * uart_tx_busy     = (int *) ADDR_UART_TX_BUSY;
// volatile int * uart_tx_full     = (int *) ADDR_UART_TX_FULL;
// volatile int * uart_tx_send     = (int *) ADDR_UART_TX_SEND;
// volatile int * uart_tx_fifo     = (int *) ADDR_UART_TX_FIFO;

void put_char(char a) {
    while (read_io_u32(ADDR_UART_TX_FULL)) asm volatile ("":::"memory");
    write_io_u32(ADDR_UART_TX_FIFO, (unsigned int) a);
    write_io_u32(ADDR_UART_TX_SEND, 1);
}

void put_string(char* str) {
    while(*str) {
    while (read_io_u32(ADDR_UART_TX_FULL)) asm volatile ("":::"memory");
        write_io_u32(ADDR_UART_TX_FIFO, (unsigned int) *str);
        str++;
    }
    write_io_u32(ADDR_UART_TX_SEND, 1);
}

void put_hex_int32(unsigned int d) {
    for(int i=0;i<4;i++) {
        register unsigned int tmp = (d & 0xFF000000U) >> 24;
        write_io_u32(ADDR_UART_TX_FIFO, tmp);
        d = d << 8;
    }
}


int read_string(char* dst, int max_len) {
    register int len = 0;
    while (len < max_len) {
        while (!read_io_u32(ADDR_UART_RX_VALID)) asm volatile ("":::"memory");
        // fifo is ready
        char get = read_io_u32(ADDR_UART_RX_FIFO) & 0xFF;
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
        while (!read_io_u32(ADDR_UART_RX_VALID)) asm volatile ("":::"memory");
        unsigned char get = read_io_u32(ADDR_UART_RX_FIFO) & 0xFF;
        tmp = tmp << 8;
        tmp = tmp | (get & 0xFF);
    }
    return tmp;
}

unsigned char read_byte() {
    while (!read_io_u32(ADDR_UART_RX_VALID)) asm volatile ("":::"memory");
    unsigned int get = read_io_u32(ADDR_UART_RX_FIFO);
    return (unsigned char) (get & 0xFF);
}

inline int uart_can_read() {
    return read_io_u32(ADDR_UART_RX_VALID) != 0;
}