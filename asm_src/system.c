

volatile int* mmio_sw = (int*) 0xFFFF0000;
volatile int* mmio_led = (int*) 0xFFFF0080;

extern int cmain() {
    while (1)
    {
        for(int i=0;i<24;i++) {
            mmio_led[i] = mmio_sw[i];
        }
    }
}
