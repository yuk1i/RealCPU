__TEXT_START_AT = 0x1000;
__DATA_START_AT = 0xf000;

SECTIONS
{
  . = 0x0000;
  .pad . : {
    LONG(0x00000000);
  }

  . = __TEXT_START_AT;
  
  .text . : {
    . = ALIGN(4);
    *(.text) 
  }
  
  . = __DATA_START_AT;
  
  .data . : { *(.data) } 
  .bss  . : { *(.bss) } 
}
start = __TEXT_START_AT;