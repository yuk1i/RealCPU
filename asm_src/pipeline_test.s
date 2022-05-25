.globl main
.text
main:
    move $t0, $ra
    li $t0, 1000
    li $t1, 10
    addu $t2, $t2, $t0
    addu $t2, $t2, $t1
    addu $t2, $t2, $t1
    addu $t2, $t2, $t1
    addiu $t2, $t2, 114

    li $t3, 3000
    slt $s0, $t2, $t3
    bnez $s0, main

    li $t0, 0x10000000
    lw $s0, test
    nop
    addu $s0, $s0, $t0
    nop

    lw $s0, test
    addu $s0, $s0, $t0
    nop
    nop
    nop
    nop
    nop
    jr $ra

.data
test: .word 0x12345678
