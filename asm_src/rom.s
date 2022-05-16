.globl __rom_start
.text
__rom_start:
    li $a0, 1000
    li $sp, 0x18000
    .set noat
    li $at, 0x00001000
    jr $at
    


    # text: 0xE000 0b1110000000000000
    # data: 0xFA00 0b1111101000000000
    # end:  0xFFFF 0b1111111111111111
    # size: 0x2000      11111111111
    # 8K size
