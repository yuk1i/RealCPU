__TEXT_START_AT = 0x1000;
__DATA_START_AT = 0x9000;

SECTIONS
{
  . = 0x0000;
  .pad . : {
    LONG(0x00000000);
  }

  . = __TEXT_START_AT;
  
  .text . : {
    *(.start)
    *(.text) 
  }
  
  . = __DATA_START_AT;
  .data . : {
    *(.data)
    *(.rodata)
    *(.bss)
    LONG(0x00000000);
  }
}
start = __TEXT_START_AT;