compile by gcc: mipsel-linux-gnu-gcc -fomit-frame-pointer -fno-pic -Qn -nostdlib -Werror -c cputest.s

ld: mipsel-linux-gnu-ld -o bin -Ttext 0x0 cputest.o --entry start

objcopy:  
