.data
   buf:   .word  0x00000055
   str:		.asciiz "you suck"

.globl main
.text
main:
		li $a0,11
		li $a1,12
		mul $a2,$a1,$a0
		


