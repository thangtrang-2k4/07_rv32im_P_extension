.section .text
.global _start

_start:
    la sp, 0x80040000   # set stack pointer (quan trọng)
    call main

1:
    j 1b
