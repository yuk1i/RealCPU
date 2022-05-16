.globl __rom_start
.globl cmain
.text
__rom_start:
    li $sp, 0x18000
    .set noat
    li $at, 0x00001000
    jr $at
    


    # text: 0xE000 0b1110000000000000
    # data: 0xFA00 0b1111101000000000
    # end:  0xFFFF 0b1111111111111111
    # size: 0x2000      11111111111
    # 8K size


    # text: 0x1000
    # data: 0xf000
    # sp  : 0x17000
