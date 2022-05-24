
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
#define SEG7_CHAR_i ((unsigned int) 0b01100000)
#define SEG7_CHAR_j ((unsigned int) 0b01111000)
#define SEG7_CHAR_k ((unsigned int) 0b01011110)
#define SEG7_CHAR_L ((unsigned int) 0b00011100)
#define SEG7_CHAR_m ((unsigned int) 0b11101100)
#define SEG7_CHAR_n ((unsigned int) 0b00101010)
#define SEG7_CHAR_o ((unsigned int) 0b11111100)
#define SEG7_CHAR_p ((unsigned int) 0b11001110)
#define SEG7_CHAR_q ((unsigned int) 0b11100110)
#define SEG7_CHAR_r ((unsigned int) 0b10001100)
#define SEG7_CHAR_s ((unsigned int) 0b10110110)
#define SEG7_CHAR_t ((unsigned int) 0b11100000)
#define SEG7_CHAR_u ((unsigned int) 0b01111100)
#define SEG7_CHAR_v ((unsigned int) 0b00111000)
#define SEG7_CHAR_w ((unsigned int) 0b01111110)
#define SEG7_CHAR_x ((unsigned int) 0b00100110)
#define SEG7_CHAR_y ((unsigned int) 0b01110110)
#define SEG7_CHAR_z ((unsigned int) 0b11011010)

unsigned int seg7_char_int[] = {SEG7_CHAR_0, SEG7_CHAR_1, SEG7_CHAR_2, SEG7_CHAR_3, SEG7_CHAR_4, SEG7_CHAR_5, SEG7_CHAR_6, SEG7_CHAR_7, SEG7_CHAR_8, SEG7_CHAR_9};
unsigned int seg7_char_alpha[] = {SEG7_CHAR_A, SEG7_CHAR_b, SEG7_CHAR_c, SEG7_CHAR_d, SEG7_CHAR_e, SEG7_CHAR_f, SEG7_CHAR_G, SEG7_CHAR_H, SEG7_CHAR_i, SEG7_CHAR_j, SEG7_CHAR_k, SEG7_CHAR_L, SEG7_CHAR_m, SEG7_CHAR_n, SEG7_CHAR_o, SEG7_CHAR_p, SEG7_CHAR_q, SEG7_CHAR_r, SEG7_CHAR_s, SEG7_CHAR_t, SEG7_CHAR_u, SEG7_CHAR_v, SEG7_CHAR_w, SEG7_CHAR_x, SEG7_CHAR_y, SEG7_CHAR_z};

unsigned int get_seg7_char(char a) {
    // [0-9][a-z][A-Z]
    if (a >= '0' && a <= '9') return seg7_char_int[a - '0'];
    if (a >= 'a' && a <= 'z') return seg7_char_alpha[a - 'a'];
    if (a >= 'A' && a <= 'Z') return seg7_char_alpha[a - 'A'];
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
int needtime = 3333333333;
int bit[8] = {0b00000001, 0b00000010, 0b00000100, 0b00001000, 0b00010000, 0b00100000, 0b01000000, 0b10000000};
extern int main() {
    unsigned int decide;
    unsigned int a;
    int b;
    unsigned int highbit;
    unsigned int is_palindrome = 1;
    int temp;
    int joint;
    unsigned int dataset;
    unsigned int index;
    int complement;
    while (1)
    {
        decide = (mmio_sw[23] << 2) | (mmio_sw[22] << 1) | mmio_sw[21];
        a = (mmio_sw[7] << 7) | (mmio_sw[6] << 6) | (mmio_sw[5] << 5) | (mmio_sw[4] << 4) | (mmio_sw[3] << 3) | (mmio_sw[2] << 2) | (mmio_sw[1] << 1) | mmio_sw[0];
        dataset = (mmio_sw[20] << 1) | mmio_sw[19];
        index = (mmio_sw[18] << 3) | (mmio_sw[17] << 2) | (mmio_sw[16] << 1) | mmio_sw[15];
        complement = -(mmio_sw[7] << 7) + (mmio_sw[6] << 6) + (mmio_sw[5] << 5) + (mmio_sw[4] << 4) + (mmio_sw[3] << 3) + (mmio_sw[2] << 2) + (mmio_sw[1] << 1) + mmio_sw[0];
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
                temp = c & (1 << 7);
                if(temp == 0){
                    data2[i] = c;
                }else{
                    for(int i = 0; i < 7; i++){
                        joint += c & (1 << i);
                    }
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
                c = data1[num1 - 1] - data1[0];
            }else if(dataset == 3){
                c = data3[num3 - 1] - data3[0];
            }else{
                c = 0;
            }

            for(int i = 0; i < 8; i++){
                mmio_led[i] = (bit[i] & c) != 0;
            }
        
        }else if(decide == 5){
            if(dataset == 1){
                c = data1[index];
            }else if(dataset == 3){
                c = data3[index];
            }else{
                c = 0;
            }
            for(int i = 0; i < 8; i++){
                mmio_led[i] = (bit[i] & c) != 0;
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
            b = 0;
            for(int i = 7; i >= 0; i--){
                if((c & (1 << i)) != 0){
                    b = i;
                    break;
                }
            }
            
            for(int i = 0; i < 8; i++){
                mmio_led[i] = (bit[i] & b) != 0;
            }
            
        }else if(decide == 7){
            for(int j = 0; j < 5; j++){
                for(int i = 0; i < 3333333333; i++){
                    i = 0;
                }
            }
            
            c = data0[index];
            for(int i = 0; i < 8; i++){
                mmio_led[i] = (bit[i] & c) != 0;
            }

            for(int j = 0; j < 5; j++){
                for(int i = 0; i < 3333333333; i++){
                    i = 0;
                }
            }
            if(complement > 0){
                c = complement;
                mmio_led[8] = 1;
            }else{
                c = -complement;
                mmio_led[8] = 0;
            }

            b = 0;
            for(int i = 7; i >= 0; i--){
                if((c & (1 << i)) != 0){
                    b = i;
                    break;
                }
            }

            for(int i = 0; i < 8; i++){
                mmio_led[i] = (bit[i] & b) != 0;
            }
        }
    }
}
