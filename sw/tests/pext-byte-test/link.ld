OUTPUT_ARCH(riscv)
ENTRY(_start)

SECTIONS
{
  /* 👉 Đổi base address về 0 */
  . = 0x80000000;

  /* Code */
  .text : {
    *(.text*)
  }

  /* Read-only data (nên có) */
  .rodata : {
    *(.rodata*)
  }

  /* Data */
  .data : {
    *(.data*)
  }

  /* BSS */
  .bss : {
    *(.bss*)
    *(COMMON)
  }

  /* 👉 vùng results riêng để dump */
  .results (NOLOAD) : {
    . = ALIGN(4);
    results = .;
    . += 256;   /* tăng size cho thoải mái */
  }
}
