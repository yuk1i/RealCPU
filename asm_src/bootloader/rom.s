.globl __rom_start
.globl bootloader
.section .rom
__rom_start:
.rept 10
    nop
.endr
    sync 17
    # enable write through

    li $v0, 0
# loop0:
#     addiu $v0, $v0, 1
#     sltiu $v1, $v0, 10
#     bnez $v1, loop0

    li $v0, 0xFFFF0080
    li $v1, 1
    sw $v1, 0($v0)
    
    li $v0, 0
    li $v1, 0

    li $sp, 0x80000
    
    li $v0, 0xFFFFFF00
    li $v1, 0x7FFFFF00

    sltu $a0, $v0, $v1
    sltu $a0, $v1, $v0

    slt $a0, $v0, $v1
    slt $a0, $v1, $v0
    
    # # test ROM with dcache write through
    # li $v1, 0x7A8B
    # sw $v1, -4($sp)
    # sw $v1, -8($sp)
    # sw $v1, -12($sp)

    # # cache line: 32B
    # sync 16
    # # disable write through
    # addiu $v1, $v1, 1
    # sw $v1, -32($sp)
    # sw $v1, -36($sp)

    # sync 17
    # # enable write through
    # li $v0, 0x00001000
    # li $v1, 0x03e00009
    # sw $v1, 0($v0)
    # sync 16
    # # disable write through

    # sync 01
    # # invalid all i cache

    # ROM Stack: 0x80000 - 0x7FC00
    jal bootloader

    sync 16
    sync 01

    li $v0, 0xFFFF0080
    li $v1, 1
    sw $v1, 0($v0)
    sw $v1, 4($v0)

    li $sp, 0x18000
    .set noat
    li $at, 0x00001000
    jalr $at
    j __rom_start


    # text: 0xE000 0b1110000000000000
    # data: 0xFA00 0b1111101000000000
    # end:  0xFFFF 0b1111111111111111
    # size: 0x2000      11111111111
    # 8K size


    # text: 0x1000
    # data: 0xf000
    # sp  : 0x17000
