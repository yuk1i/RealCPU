.data
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
   lw $s0, buf
   sll $s1, $s0, 8
   or $s1, $s1, $s0
   sw $s1, buf       # 0x00005555
   lb $t0, w02       # 0xFFFFFF80
   lbu $t0, w02      # 0x00000080
   lh $t0, w02       # 0x00000080

   lh $t0, w03
   lhu $t0, w03
   la $a0, w03
   lb $t0, 1($a0)
