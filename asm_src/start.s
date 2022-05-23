.globl __start
.globl main
.section .start
__start:
    # addiu $sp, $sp, 0x8000
    j main
