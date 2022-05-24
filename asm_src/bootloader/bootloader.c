#include "../utils/seg7.c"
#include "../utils/uart.c"

extern int bootloader() {
    put_string("[+] Hello Yuki!\n");
    put_string("[+] Bootloader is running.\n");
    put_string("[*] Reset Main Memory...\n");
    // display BL
    register unsigned int * seg7_addr = (unsigned int *) SEG7_BASE_ADDR;
    register unsigned int * led_addr = (unsigned int *) 0xFFFF0080;
    seg7_addr[7] = SEG7_CHAR_B;
    seg7_addr[6] = SEG7_CHAR_L;
    seg7_addr[5] = SEG7_CHAR_NONE;
    seg7_addr[4] = SEG7_CHAR_NONE;
    seg7_addr[3] = SEG7_CHAR_NONE;
    seg7_addr[2] = SEG7_CHAR_NONE;
    seg7_addr[1] = SEG7_CHAR_NONE;
    seg7_addr[0] = SEG7_CHAR_NONE;
    // Main Memory: 512K: 0x00000 - 0x7FC00, 0x7FC00 ~ 0x80000 1K: ROM Stack
    for(register int i = 0; i<0x7FC00;i++) {
        *((unsigned char*) i) = 0;
    }
    // reset main memory to all zero
    put_string("[+] Reset Main Memory Done!\n");

    seg7_addr[3] = SEG7_CHAR_U;
    seg7_addr[2] = SEG7_CHAR_A;
    seg7_addr[1] = SEG7_CHAR_R;
    seg7_addr[0] = SEG7_CHAR_T;

    put_string("[+] Enter UART Loader\n");
    unsigned int size = read_hex_int32();
    put_string("[*] MEM Size: 0x");
    put_hex_int32(size);
    display(size);
    put_string("\n");

    register unsigned char* mem_base = (unsigned char *) 0x1000;
    register int * uart_rx_valid = (int *) ADDR_UART_RX_VALID;
    register int * uart_rx_fifo = (int *) ADDR_UART_RX_FIFO;
    for(register int i=0;i<size;i++) {
        while (!*uart_rx_valid) asm volatile ("":::"memory");
        register unsigned char d = *uart_rx_fifo & 0xFF;
        *mem_base = d;
        mem_base++;
        display(i);
    }
    put_string("[+] MEM write done\n");
    seg7_addr[3] = SEG7_CHAR_A;
    seg7_addr[2] = SEG7_CHAR_B;
    seg7_addr[1] = SEG7_CHAR_C;
    seg7_addr[0] = SEG7_CHAR_D;
    led_addr[0] = 0;
    return 0;
}
