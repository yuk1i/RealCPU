const char * str = "asdfasf;";

struct pixel {
	
};
volatile unsigned short * ptr = (unsigned short*) 0xFFFF0004;

int test(int a, int b) {
	return a*b;
}
int main() {
	register int a;
	while(*ptr) {
		asm("nop");
		asm("nop");
		asm("nop");
		asm("nop");
		asm("nop");
		a = *ptr / 10;
		a += test(a, a+2);
	}
	
}
