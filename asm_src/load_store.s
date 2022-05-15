.data
   d1:    .word  0x1000FFFF
   .org 0x8000
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
   la $a0, buf
   lw $s0, ($a0)
   sll $s1, $s0, 8
   or $s1, $s1, $s0
   sw $s1, ($a0)       # 0x00005555
   la $a0, w02
   lb $t0, ($a0)       # 0xFFFFFF80
   lbu $t0, ($a0)      # 0x00000080
   lh $t0,  ($a0)       # 0x00000080

   sw $zero, ($a0)   # 0x00000000
   addiu $t0, $zero, 0x11
   sb $t0, ($a0)
   addiu $t0, $t0, 1
   sb $t0, 1($a0)
   addiu $t0, $t0, 1
   sb $t0, 2($a0)
   addiu $t0, $t0, 1
   sb $t0, 3($a0)

   lw $t1, ($a0)
   lh $t1, ($a0)
   lh $t1, 2($a0)

   lb $t1, ($a0)
   lb $t1, 1($a0)
   lb $t1, 2($a0)
   lb $t1, 3($a0)

   sw $zero, ($a0)   # 0x00000000
   addiu $t0, $zero, 0x2233
   sh $t0, ($a0)
   addiu $t0, $t0, 1
   sh $t0, 2($a0)

   lw $t1, ($a0)

   la $s0, d1
   la $s1, d2
   lw $t0, ($s0)
   lw $t0, ($s1)
   sb $zero, 1($s0)
   lh $t0, 2($s1)
   lw $t0, ($s0)

   j from

   .org 0x1100;
from:
   b test     # 0b0_010000100000000

   .org 0x9100;
test:
   j main      # 0b1_01000_01000_00000
