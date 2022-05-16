.globl __start
.globl cmain
.section .start
__start:
    .set noat
    li $at, 0x123123
    jal cmain
