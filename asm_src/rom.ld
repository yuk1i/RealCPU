__TEXT_START_AT = 0xFFFFE000;
__DATA_START_AT = 0xFFFFFA00;

SECTIONS
{
  . = __TEXT_START_AT;
  
  .text . : {
    tmp/bootloader/rom.o(.rom)
    *(.text) 
  }
  
  . = __DATA_START_AT;
  .data . : {
    *(.data)
    *(.data.*)
    *(.rodata)
    *(.rodata.*)
    *(.bss)
    LONG(0x00000000);
  }
}
start = __TEXT_START_AT;