ENTRY(_start)

SECTIONS
{
/* ===== CODE ===== */
. = 0x80000000;
.text : {
*(.text)
}

/* ===== READ-ONLY DATA ===== */
. = 0x80010000;
.rodata : {
    *(.rodata)
}

/* ===== DATA (input image) ===== */
. = 0x80020000;
.data : {
    *(.data)
}

/* ===== BSS (output image) ===== */
. = 0x80030000;
.bss : {
    *(.bss)
    *(COMMON)
}

}
