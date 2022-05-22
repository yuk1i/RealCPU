#include "utils/seg7.h"
#include "utils/uart.h"
#include "utils/string.h"

volatile int* mmio_sw = (int*) 0xFFFF0000;
volatile int* mmio_led = (int*) 0xFFFF0080;
volatile int* mmio_seg7 = (int*) 0xFFFF0100;

char buf[1024];
extern int main() {
    mmio_led[0] = 0;
    register int counter = 0;
    register int c2 = 0;
    put_string("Bootloader!");
    put_string("Yuki is a magic girl!");
    while (1)
    {
        if (uart_can_read()) {
            register int len = read_string(buf, 1024);
            // len = append(buf + len, " hello!", 1024 - len);
            put_string(buf);
            put_string(" hello!");
            counter++;
        }
        display(counter);
    }
}
