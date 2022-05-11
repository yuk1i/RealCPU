const char * str = "asdfasf;";

struct pixel {
	
};
volatile unsigned short * ptr = (unsigned short*) 0xFFFF0004;

int main() {
	while(*ptr) {
		asm("nop");
		asm("nop");
		asm("nop");
		asm("nop");
		asm("nop");
		*ptr = 1234;
	}
	
}
