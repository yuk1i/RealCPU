#include "utils/seg7.h"
#include "utils/uart.h"


char buf[1024];
extern int main() {
    register volatile int* mmio_led = (int*) 0xFFFF0080;
    register volatile int* mmio_seg7 = (int*) 0xFFFF0100;

    mmio_led[0] = 0;
    register int counter = 0;
    register int c2 = 0;
    put_string("Bootloader!\n");
    put_string("test UART send & recv");
    //put_string("Yuki is a magic girl lol!\n");
    mmio_seg7[0] = SEG7_CHAR_1;
    mmio_seg7[1] = SEG7_CHAR_2;
    mmio_seg7[2] = SEG7_CHAR_3;
    mmio_seg7[3] = SEG7_CHAR_4;
    while (1)
    {
        if (uart_can_read()) {
            register int len = read_string(buf, 1024);
            // len = append(buf + len, " hello!", 1024 - len);
            put_string(buf);
            put_string(" hello!");
            put_string(" echo\n");
            counter+=2;
            mmio_led[0] = mmio_led[0] ^ 1;
        }
        display(counter);
    }
}
