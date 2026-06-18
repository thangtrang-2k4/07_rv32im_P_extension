    .option norelax
    .option norvc

    .macro SIG reg
        nop
        nop
        sw \reg, 0(s0)
        addi s0, s0, 4
    .endm

    .section .signature, "aw"
    .align 4
signature:
    .space 256

    .section .text
    .globl _start
_start:
    la s0, signature

    # MUL low word
    addi t0, x0, 7
    addi t1, x0, -3
    mul t2, t0, t1
    SIG t2

    li t0, 0x12345678
    addi t1, x0, 16
    mul t2, t0, t1
    SIG t2

    # High-word multiply variants
    addi t0, x0, -2
    li t1, 0x40000000
    mulh t2, t0, t1
    SIG t2

    li t0, 0xffffffff
    addi t1, x0, 2
    mulhu t2, t0, t1
    SIG t2

    addi t0, x0, -2
    li t1, 0xffffffff
    mulhsu t2, t0, t1
    SIG t2

    # Signed division/remainder
    addi t0, x0, 20
    addi t1, x0, -3
    div t2, t0, t1
    SIG t2

    rem t2, t0, t1
    SIG t2

    addi t0, x0, -20
    addi t1, x0, 3
    div t2, t0, t1
    SIG t2

    rem t2, t0, t1
    SIG t2

    # Unsigned division/remainder
    li t0, 0xfffffff0
    addi t1, x0, 16
    divu t2, t0, t1
    SIG t2

    remu t2, t0, t1
    SIG t2

    # Divide-by-zero behavior
    addi t0, x0, 123
    addi t1, x0, 0
    div t2, t0, t1
    SIG t2

    divu t2, t0, t1
    SIG t2

    rem t2, t0, t1
    SIG t2

    li t0, 0x89abcdef
    remu t2, t0, t1
    SIG t2

    # Signed overflow behavior
    li t0, 0x80000000
    addi t1, x0, -1
    div t2, t0, t1
    SIG t2

    rem t2, t0, t1
    SIG t2

    la t0, _done_flag
    addi t1, x0, 1
    sw t1, 0(t0)

done:
    jal x0, done
