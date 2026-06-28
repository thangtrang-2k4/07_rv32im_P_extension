ENTRY(_start)

SECTIONS
{
    /* RAM bắt đầu tại 0x80000000 */
    . = 0x80000000;

    /* Code */
    .text : {
        *(.text)
    }

    /* Data (results của bạn sẽ nằm ở đây) */
    .data : {
        *(.data)
    }

    /* BSS */
    .bss : {
        *(.bss)
        *(COMMON)
    }
}
