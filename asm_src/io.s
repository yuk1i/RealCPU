
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
