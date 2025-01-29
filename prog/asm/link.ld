OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  . = 0x00000000;
  .text : { *(.text) }
  . = ALIGN(0x1000);
  .data : { *(.data) }
  _end = .;

  _uart = 0x80000000;
}
