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

    li $t3, 5000
    slt $s0, $t2, $t3
    bnez $s0, main

