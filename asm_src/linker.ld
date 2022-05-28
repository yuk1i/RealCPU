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
    *(.text.*)
  }
  
  . = __DATA_START_AT;
  .data . : {
    *(.data)
    *(.data.*)
    *(.rodata)
    *(.rodata.*)
    *(.bss)
    *(.bss.*)
    LONG(0x00000000);
  }
}
start = __TEXT_START_AT;