
.text

.globl read_io_u32
read_io_u32:
    lw $v0, ($a0)
    nop
    jr $ra

.globl write_io_u32
write_io_u32:
    sw $a1, ($a0)
    nop
    jr $ra 

.globl delay_1ms
delay_1ms:
    addiu $sp, $sp, -8
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    li $a1, 10000
    li $a0, 0
loop:
    addiu $a0, $a0, 1
    bne $a0, $a1, loop
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    jr $ra

