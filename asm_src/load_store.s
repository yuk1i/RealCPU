.data
   buf:   .word  0x00000055
   w01:   .word  0x11111111
   w02:   .word  0x22222222
   w03:   .word  0x33333333
   w04:   .word  0x44444444
   w05:   .word  0x55555555
   w06:   .word  0x66666666
   w07:   .word  0x77777777

.globl main
.text
main:
   lw $s0, buf
   sll $s1, $s0, 8
   or $s1, $s1, $s0
   sw $s1, buf
