
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
#define SEG7_CHAR_G ((unsigned int) 0b10111110)
#define SEG7_CHAR_H ((unsigned int) 0b01101110)
#define SEG7_CHAR_f ((unsigned int) 0b10001110)
#define SEG7_CHAR_i ((unsigned int) 0b01100000)
#define SEG7_CHAR_j ((unsigned int) 0b01110000)
#define SEG7_CHAR_i ((unsigned int) 0b01100000)

unsigned int seg7_char_int[] = {SEG7_CHAR_0, SEG7_CHAR_1, SEG7_CHAR_2};
unsigned int seg7_char_alpha[] = {SEG7_CHAR_A, SEG7_CHAR_b, SEG7_CHAR_c};

unsigned int get_seg7_char(char a) {
    // [0-9][a-z][A-Z]
    if (a>='0' && a<='9') return seg7_char_int[a-'0'];
    if (a>='a' && a <= 'z') return seg7_char_alpha[a-'a'];
    return (unsigned int) 0b00000001;
}
int data0[257];
int data1[257];
int data2[257];
int data3[257];
int num0 = 0;
int num1 = 0;
int num2 = 0;
int num3 = 0;
int c = 0;
int needtime = 16666666665;
extern int cmain() {
    unsigned int decide;
    unsigned int a;
    int b;
    unsigned int highbit;
    unsigned int is_palindrome = 1;
    int temp;
    int joint;
    unsigned int dataset;
    unsigned int index;
    const unsigned int bit0 = 0b00000001;
    const unsigned int bit1 = 0b00000010;
    const unsigned int bit2 = 0b00000100;
    const unsigned int bit3 = 0b00001000;
    const unsigned int bit4 = 0b00010000;
    const unsigned int bit5 = 0b00100000;
    const unsigned int bit6 = 0b01000000;
    const unsigned int bit7 = 0b10000000;
    while (1)
    {
        decide = (mmio_sw[23] << 2) | (mmio_sw[22] << 1) | mmio_sw[21];
        a = (mmio_sw[7] << 7) | (mmio_sw[6] << 6) | (mmio_sw[5] << 5) | (mmio_sw[4] << 4) | (mmio_sw[3] << 3) | (mmio_sw[2] << 2) | (mmio_sw[1] << 1) | mmio_sw[0];
        //_sleep(5000);
        dataset = (mmio_sw[20] << 1) | mmio_sw[19];
        index = (mmio_sw[18] << 3) | (mmio_sw[17] << 2) | (mmio_sw[16] << 1) | mmio_sw[15];
        if(decide == 0){
            c = 0;
            for(int i = 0; i < num0; i++){
                if(a == data0[i]){
                    c = 1;
                    break;
                }
            }
            if(c == 0){
                data0[num0] = a;
                num0++;
            }
        }else if(decide == 1){
            num1 = num0;
            for(int i = 0; i < num0; i++){
                data1[i] = data0[i];
            }
            for(int i = 0; i < num1 - 1; i++) {
                int k = i;
                for(int j = k + 1; j < num1; j++){
                    if(data1[j] < data1[k]){ 
                        k = j;
                    }
                }
                if(i != k){
                    int temp = data1[i];
                    data1[i] = data1[k];
                    data1[k] = temp;
                }   
            }
        }else if(decide == 2){
            joint = 0;
            num2 = num0;
            for(int i = 0; i < num0; i++){
                c = data0[i];
                temp = c & bit7;
                if(temp == 0){
                    data2[i] = c;
                }else{
                    temp = c & bit0;
                    joint += temp;
                    temp = c & bit1;
                    joint += temp;
                    temp = c & bit2;
                    joint += temp;
                    temp = c & bit3;
                    joint += temp;
                    temp = c & bit4;
                    joint += temp;
                    temp = c & bit5;
                    joint += temp;
                    temp = c & bit6;
                    joint += temp;
                    data2[i] = -joint;
                }
            }
        }else if(decide == 3){
            num3 = num2;
            for(int i = 0; i < num2; i++){
                data3[i] = data2[i];
            }
            for(int i = 0; i < num2 - 1; i++) {
                int k = i;
                for(int j = k + 1; j < num2; j++){
                    if(data3[j] < data3[k]){ 
                        k = j;
                    }
                }
                if(i != k){
                    int temp = data3[i];
                    data3[i] = data3[k];
                    data3[k] = temp;
                }   
            }
        }else if(decide == 4){
            if(dataset == 1){
                c = data1[num1] - data1[0];
            }else if(dataset == 3){
                c = data3[num3] - data3[0];
            }else{
                c = 0;
            }
            temp = c & bit0;
            if(temp != 0){
                mmio_led[0] = 1;
            }else{
                mmio_led[0] = 0;
            }
            temp = c & bit1;
            if(temp != 0){
                mmio_led[1] = 1;
            }else{
                mmio_led[1] = 0;
            }
            temp = c & bit2;
            if(temp != 0){
                mmio_led[2] = 1;
            }else{
                mmio_led[2] = 0;
            }
            temp = c & bit3;
            if(temp != 0){
                mmio_led[3] = 1;
            }else{
                mmio_led[3] = 0;
            }
            temp = c & bit4;
            if(temp != 0){
                mmio_led[4] = 1;
            }else{
                mmio_led[4] = 0;
            }
            temp = c & bit5;
            if(temp != 0){
                mmio_led[5] = 1;
            }else{
                mmio_led[5] = 0;
            }
            temp = c & bit6;
            if(temp != 0){
                mmio_led[6] = 1;
            }else{
                mmio_led[6] = 0;
            }
            temp = c & bit7;
            if(temp != 0){
                mmio_led[7] = 1;
            }else{
                mmio_led[7] = 0;
            }
        }else if(decide == 5){
            if(dataset == 1){
                c = data1[index];
            }else if(dataset == 3){
                c = data3[index];
            }else{
                c = 0;
            }
            temp = c & bit0;
            if(temp != 0){
                mmio_led[0] = 1;
            }else{
                mmio_led[0] = 0;
            }
            temp = c & bit1;
            if(temp != 0){
                mmio_led[1] = 1;
            }else{
                mmio_led[1] = 0;
            }
            temp = c & bit2;
            if(temp != 0){
                mmio_led[2] = 1;
            }else{
                mmio_led[2] = 0;
            }
            temp = c & bit3;
            if(temp != 0){
                mmio_led[3] = 1;
            }else{
                mmio_led[3] = 0;
            }
            temp = c & bit4;
            if(temp != 0){
                mmio_led[4] = 1;
            }else{
                mmio_led[4] = 0;
            }
            temp = c & bit5;
            if(temp != 0){
                mmio_led[5] = 1;
            }else{
                mmio_led[5] = 0;
            }
            temp = c & bit6;
            if(temp != 0){
                mmio_led[6] = 1;
            }else{
                mmio_led[6] = 0;
            }
            temp = c & bit7;
            if(temp != 0){
                mmio_led[7] = 1;
            }else{
                mmio_led[7] = 0;
            }
        }else if(decide == 6){
            if(dataset == 1){
                c = data1[index];
            }else if(dataset == 2){
                c = data2[index];
            }else if(dataset == 3){
                c = data3[index];
            }else{
                c = 0;
            }
            if(c >= 0){
                mmio_led[8] = 0;
            }else if(c < 0){
                mmio_led[8] = 1;
                c = -c;
            }
            temp = c & bit7;
            if(temp != 0){
                b = 7;
            }else{
                temp = c & bit6;
                if(temp != 0){
                    b = 6;
                }else{
                    temp = c & bit5;
                    if(temp != 0){
                    b = 5;
                    }else{
                        temp = c & bit4;
                        if(temp != 0){
                            b = 4;
                        }else{
                            temp = b & bit3;
                            if(temp != 0){
                                b = 3;
                            }else{
                                temp = b & bit2;
                                if(temp != 0){
                                    b = 2;
                                }else{
                                    temp = b & bit1;
                                    if(temp != 0){
                                        b = 1;
                                    }else{
                                        b = 0;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            temp = b & bit0;
            if(temp != 0){
                mmio_led[0] = 1;
            }else{
                mmio_led[0] = 0;
            }
            temp = b & bit1;
            if(temp != 0){
                mmio_led[1] = 1;
            }else{
                mmio_led[1] = 0;
            }
            temp = b & bit2;
            if(temp != 0){
                mmio_led[2] = 1;
            }else{
                mmio_led[2] = 0;
            }
            temp = b & bit3;
            if(temp != 0){
                mmio_led[3] = 1;
            }else{
                mmio_led[3] = 0;
            }
            temp = b & bit4;
            if(temp != 0){
                mmio_led[4] = 1;
            }else{
                mmio_led[4] = 0;
            }
            temp = b & bit5;
            if(temp != 0){
                mmio_led[5] = 1;
            }else{
                mmio_led[5] = 0;
            }
            temp = b & bit6;
            if(temp != 0){
                mmio_led[6] = 1;
            }else{
                mmio_led[6] = 0;
            }
            temp = b & bit7;
            if(temp != 0){
                mmio_led[7] = 1;
            }else{
                mmio_led[7] = 0;
            }
        }else if(decide == 7){
            for(int i = 0; i < 16666666665; i++){
                i = 0;
            }
            c = data0[index];
            temp = c & bit0;
            if(temp != 0){
                mmio_led[0] = 1;
            }else{
                mmio_led[0] = 0;
            }
            temp = c & bit1;
            if(temp != 0){
                mmio_led[1] = 1;
            }else{
                mmio_led[1] = 0;
            }
            temp = c & bit2;
            if(temp != 0){
                mmio_led[2] = 1;
            }else{
                mmio_led[2] = 0;
            }
            temp = c & bit3;
            if(temp != 0){
                mmio_led[3] = 1;
            }else{
                mmio_led[3] = 0;
            }
            temp = c & bit4;
            if(temp != 0){
                mmio_led[4] = 1;
            }else{
                mmio_led[4] = 0;
            }
            temp = c & bit5;
            if(temp != 0){
                mmio_led[5] = 1;
            }else{
                mmio_led[5] = 0;
            }
            temp = c & bit6;
            if(temp != 0){
                mmio_led[6] = 1;
            }else{
                mmio_led[6] = 0;
            }
            temp = c & bit7;
            if(temp != 0){
                mmio_led[7] = 1;
            }else{
                mmio_led[7] = 0;
            }

            for(int i = 0; i < 16666666665; i++){
                i = 0;
            }

            temp = c & bit7;
            if(temp == 1){
                mmio_led[8] = 1;
            }else{
                mmio_led[8] = 0;
            }
            temp = c & bit6;
            if(temp != 0){
                b = 6;
            }else{
                temp = c & bit5;
                if(temp != 0){
                    b = 5;
                }else{
                    temp = c & bit4;
                    if(temp != 0){
                        b = 4;
                    }else{
                        temp = b & bit3;
                        if(temp != 0){
                            b = 3;
                        }else{
                            temp = b & bit2;
                            if(temp != 0){
                                b = 2;
                            }else{
                                temp = b & bit1;
                                if(temp != 0){
                                    b = 1;
                                }else{
                                    b = 0;
                                }
                            }
                        }
                    }
                }
            }
            temp = b & bit0;
            if(temp != 0){
                mmio_led[0] = 1;
            }else{
                mmio_led[0] = 0;
            }
            temp = b & bit1;
            if(temp != 0){
                mmio_led[1] = 1;
            }else{
                mmio_led[1] = 0;
            }
            temp = b & bit2;
            if(temp != 0){
                mmio_led[2] = 1;
            }else{
                mmio_led[2] = 0;
            }
            temp = b & bit3;
            if(temp != 0){
                mmio_led[3] = 1;
            }else{
                mmio_led[3] = 0;
            }
            temp = b & bit4;
            if(temp != 0){
                mmio_led[4] = 1;
            }else{
                mmio_led[4] = 0;
            }
            temp = b & bit5;
            if(temp != 0){
                mmio_led[5] = 1;
            }else{
                mmio_led[5] = 0;
            }
            temp = b & bit6;
            if(temp != 0){
                mmio_led[6] = 1;
            }else{
                mmio_led[6] = 0;
            }
            temp = b & bit7;
            if(temp != 0){
                mmio_led[7] = 1;
            }else{
                mmio_led[7] = 0;
            }
        }
    }

}
