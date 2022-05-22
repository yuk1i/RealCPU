#ifndef UART_H
#define UART_H

#define ADDR_UART_RX_VALID   0xFFFF0120
#define ADDR_UART_RX_FIFO    0xFFFF0124
#define ADDR_UART_TX_BUSY    0xFFFF0128
#define ADDR_UART_TX_FULL    0xFFFF012C
#define ADDR_UART_TX_SEND    0xFFFF0130
#define ADDR_UART_TX_FIFO    0xFFFF0134

void put_char(char a);
void put_string(char* str);
int read_string(char* dst, int max_len);
void put_hex_int32(int d);
int uart_can_read();
unsigned int read_hex_int32();

#endif