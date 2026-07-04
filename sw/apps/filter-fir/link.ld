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

  .output_data 0x80011060 : {
    *(.output_data)
  } > DMEM

  _done_flag = 0x80013FFC;
  _stack_top = ORIGIN(DMEM) + LENGTH(DMEM);

  ASSERT(_bss_end <= (_done_flag - 4), "DMEM overflow: .bss overlaps reserved done flag")
}
