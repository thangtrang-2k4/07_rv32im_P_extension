ENTRY(_start)

MEMORY
{
  IMEM (rx)  : ORIGIN = 0x80000000, LENGTH = 64K
  DMEM (rw)  : ORIGIN = 0x80010000, LENGTH = 64K
}

SECTIONS
{
  .text : {
    *(.text*)
  } > IMEM

  .rodata : {
    *(.rodata*)
  } > DMEM

  .data : {
    *(.data*)
  } > DMEM

  .bss : {
    _bss_start = .;
    *(.bss*)
    *(COMMON)
    _bss_end = .;
  } > DMEM

  _stack_top = ORIGIN(DMEM) + LENGTH(DMEM);
}
