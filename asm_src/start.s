.globl __start
.globl cmain
.section .start
__start:
    addiu $sp, $sp, 0x8000
    jal cmain
