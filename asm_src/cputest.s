.data
   buf:   .word  0x00000055
   str:		.asciiz "you suck"

.globl main
.text
main:
		li $a0,0x12345678
		la $v0, buf
		addiu $v0, $v0, 2
		lw $a0, ($v0)
		la $t0, str
		lb $s0, ($t0)
		li $s7, 0
		li $s3, -1024
		sra $s3, $s3, 3
		li $t0, 2
		sll $s3, $s3, $t0
		nop
test:
		addiu $s7, $s7, 1
		beq $s7, 10, out
		beq $s0, 'a', test
		li $t1, -1
		li $t2, 9
		slt $s0, $t1, $t2
		sltu $s1, $t1, $t2
		slti $s2, $t1, 10
		slti $s2, $t1, 0
		slti $s2, $t1, -2
		li $a0, 1
		bgez $a0, testqq
		addiu $zero, $zero, 1234
testqq:
		bal back
		# nal back
		bal qqq		# test bal
		j test

qqq:
	li $t0,1
	li $t2,2
	and $t3, $t1, $t2
	or $t4, $t1, 0x1111
	jr $ra

out:
	# test mtc0
	mfc0 $t0, $0
	addiu $t0, 0xFF
	mtc0 $t0, $0
	li $t0, 0
	mfc0 $t0, $0
	andi $t0, $t0, 0x0F
.set noat
	li $at, 0xFF000000
	or $t0, $t0, $at

back:
	jr $ra
