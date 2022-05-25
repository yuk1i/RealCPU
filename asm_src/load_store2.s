.globl main
.text
main:
    la $a0, test
    la $a1, test2

    # read uncached
    addu $zero, $zero, $zero
    lw $v1, ($a0)
    
    # write cached
    addiu $v1, $v1, 0x11
    addu $zero, $zero, $zero
    sw $v1, 8($a0)
    addu $zero, $zero, $zero
    lw $zero, 8($a0)

    # write uncached
    addu $zero, $zero, $zero
    sw $v1, 32($a0)
    addu $zero, $zero, $zero
    lw $zero, 32($a0)

    # read on dirty cl
    addiu $t0, $a0, 0x8000
    addu $zero, $zero, $zero
    lw $zero, ($t0)

    # write uncached
    addu $zero, $zero, $zero
    sw $v1, 8($a0)
    addu $zero, $zero, $zero
    lw $zero, 8($a0)

    # read on dirty cl
    addu $zero, $zero, $zero
    lw $zero, 0x8000($a0)

    lw $zero, 0($a0)
    lw $zero, 4($a0)
    lw $zero, 32($a0)
    lw $zero, 8($a0)

    sync 17
    li $t2, 0xFFEEDDCC
    sw $t2,  12($a0)
    sw $t2,  4($a1)
    

    j main

.data
test:   .word 0x12345678
test2:  .word 0xAABBCCDD
