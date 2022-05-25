.globl main
.text
main:

    li $a0, test
    li $a1, test2

    # read uncached
    lw $v1, ($a0)
    
    # write cached
    addiu $v1, $v1, 0x11
    sw $v1, 4($a0)

    # write uncached
    sw $v1, 32($a0)

    # read on dirty cl
    lw $zero, 0x8000($a0)

    # write uncached
    sw $v1, 8($a0)

    # read on dirty cl
    lw $zero, 0x8000($a0)





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

