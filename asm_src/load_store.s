.data
   buf:   .word  0x00000055

.globl main
.text
main:
    lw $s0, buf
    