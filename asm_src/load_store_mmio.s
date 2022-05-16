.data
   d1:    .word  0x1000FFFF
   d2:    .word  0x2000FFFF
   buf:   .word  0x00000055
   w01:   .word  0x12345678
   w02:   .word  0x00000080
   w03:   .word  0x00008000
   w04:   .word  0x44444444
   w05:   .word  0x55555555
   w06:   .word  0x66666666
   w07:   .word  0x77777777

.globl main
.text
main:
    lw $t0, d1
    li $s0, 0xFFFF0000
    lw $t0, ($s0)
    lw $t0, 4($s0)
    lw $t0, 8($s0)
    j main
