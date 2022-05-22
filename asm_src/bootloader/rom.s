.globl __rom_start
.globl bootloader
.section .rom
__rom_start:
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
    # ROM Stack: 0x80000 - 0x7FC00
    jal bootloader


    li $v0, 0xFFFF0080
    li $v1, 1
    sw $v1, 0($v0)
    sw $v1, 4($v0)

    li $sp, 0x18000
    .set noat
    li $at, 0x00001000
    jr $at
    j __rom_start


    # text: 0xE000 0b1110000000000000
    # data: 0xFA00 0b1111101000000000
    # end:  0xFFFF 0b1111111111111111
    # size: 0x2000      11111111111
    # 8K size


    # text: 0x1000
    # data: 0xf000
    # sp  : 0x17000
