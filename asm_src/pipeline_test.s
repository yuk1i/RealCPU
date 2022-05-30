.globl main
.text
main:

    # li $a0, 1234
    # li $v0, 1
    # seleqz $v1, $a0, $v0
    # selnez $v1, $a0, $v0

    # li $v0, 0
    # seleqz $v1, $a0, $v0
    # selnez $v1, $a0, $v0

    # test multiply
    li $t0, 0xFFFFE000
    li $a0, 114
    li $a1, 514
    mulu $v0, $a0, $a1
    muhu $v0, $a0, $a1

    lw $s0, ($t0)
    div $v0, $a1, $a0

    mod $v0, $a1, $a0

    neg $a0
    mul $v0, $a0, $a1


    # test load
    la $a0, test
    lw $v0, ($a0)
    sw $a0, 4($v0) 

    # test special3

    li $a0, 0xF9        #         0b11111001
    li $a1, 0xFF0F00    # 0b111111110000111100000000
    
    move $v0, $a0
    ins $v0, $a0, 16, 8 # 0b011111 00100 00010 10110 01111 000100
    ext $v1, $v0, 16, 8 # 0b011111 00010 00011 00111 10000 000000

    move $v0, $a1    
    ins $v0, $a0, 7, 8
    ext $v1, $v0, 8, 8

    move $v0, $a1
    ins $v0, $a0, 7, 8
    ext $v1, $v0, 8, 8

    li $a0, 0x400
    li $a1, 0x100
    lsa $v0, $a0, $a1, 1    # 0x400 * 2 + 0x100
    lsa $v0, $a0, $a1, 2    # 0x400 * 8 + 0x100

    li $a0, 0xF9
    seb $v0, $a0
    sll $a0, $a0, 8
    seh $v0, $a0


    la $a0, test
    la $a1, test2

    lw $t0, ($a0)
    sw $t0, 8($a1)

    li $s0, 0
loop:
    li $a0, 0xFFFF0080
    li $a1, 0xFFFF0000
    addu $a0, $a0, $s0
    addu $a1, $a1, $s0
    lw $t0, ($a1)
    sw $t0, ($a0)
    addiu $s0, $s0, 4
    sltiu $t1, $s0, 96
    bnez $t1, loop
    li $s0, 0 
    b loop

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
test2: .word 0xAABBCCDD
