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
    . = ALIGN(4);
    _bss_start = .;
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    _bss_end = .;
  } > DMEM

  _done_flag = ORIGIN(DMEM) + LENGTH(DMEM) - 4;
  _stack_top = ORIGIN(DMEM) + LENGTH(DMEM);

  ASSERT(_bss_end <= (_done_flag - 4), "DMEM overflow: .bss overlaps reserved done flag")
}
