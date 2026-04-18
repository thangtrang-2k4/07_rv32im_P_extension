.section .text
.global _start

_start:
    # set stack
    la sp, _stack_top

    # clear .bss
    la t0, _bss_start
    la t1, _bss_end

clear_bss:
    bge t0, t1, done_bss
    sw zero, 0(t0)
    addi t0, t0, 4
    j clear_bss

done_bss:
    # call main
    call main

1:
    j 1b
