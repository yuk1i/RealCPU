
## Development Guide

1. Use Linux
2. Install cross-compile toolchains, mipsel-linux-gnu-{gcc, as, ld, objcopy, objdump}. For debain users: `sudo apt install gcc-mipsel-linux-gnu`
3. Install make, python3
4. Modify cputest.s
5. use `make` to compile, dump .text and .data sections, and generate coe files

## Makefile Guide

1. Create a .s asm file, such as test.s
2. use `make test` to compile it and generate coe files
3. Default target is cputest.s if executing `make`.

## References

1. gcc mips32 options https://gcc.gnu.org/onlinedocs/gcc/MIPS-Options.html


