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

    .section .bss
    .align 4
scratch:
    .space 64

    .section .text
    .globl _start
_start:
    la s0, signature

    # U-type
    lui t0, 0x12345
    SIG t0

    auipc t0, 0
    auipc t1, 0
    sub t2, t1, t0
    SIG t2

    # I/R ALU
    addi t0, x0, 10
    addi t1, x0, -5
    add t2, t0, t1
    SIG t2

    sub t2, t0, t1
    SIG t2

    addi t3, x0, 2
    sll t2, t0, t3
    SIG t2

    li t0, 0xf0000000
    srli t2, t0, 4
    SIG t2

    srai t2, t0, 4
    SIG t2

    addi t0, x0, 10
    addi t1, x0, -5
    slt t2, t1, t0
    SIG t2

    sltu t2, t1, t0
    SIG t2

    addi t0, x0, 0x55
    xori t2, t0, 0x0f
    SIG t2

    ori t2, x0, 0x5f
    SIG t2

    andi t2, t2, 0x33
    SIG t2

    addi t0, x0, 3
    slli t2, t0, 5
    SIG t2

    li t0, 0x80000000
    srli t2, t0, 31
    SIG t2

    srai t2, t0, 31
    SIG t2

    addi t0, x0, -5
    slti t2, t0, 0
    SIG t2

    sltiu t2, t0, 0
    SIG t2

    # Load/store and sign/zero extension
    la t0, scratch
    li t1, 0xa1b2c3d4
    sw t1, 0(t0)

    lw t2, 0(t0)
    SIG t2

    lb t2, 0(t0)
    SIG t2

    lbu t2, 0(t0)
    SIG t2

    lh t2, 0(t0)
    SIG t2

    lhu t2, 0(t0)
    SIG t2

    addi t3, x0, 0x55
    sb t3, 1(t0)
    lw t2, 0(t0)
    SIG t2

    li t3, 0x1234
    sh t3, 2(t0)
    lw t2, 0(t0)
    SIG t2

    # Branch taken/not-taken mix
    addi t0, x0, 0
    addi t1, x0, 5
    addi t2, x0, 5

    beq t1, t2, 1f
    addi t0, x0, 99
1:
    addi t0, t0, 1

    bne t1, t2, 2f
    addi t0, t0, 2
2:
    blt t1, t2, 3f
    addi t0, t0, 4
3:
    bge t1, t2, 4f
    addi t0, x0, 99
4:
    bltu t1, t2, 5f
    addi t0, t0, 8
5:
    bgeu t1, t2, 6f
    addi t0, x0, 99
6:
    SIG t0

    # JAL link when target is the next instruction
    jal t0, 7f
7:
    auipc t1, 0
    sub t2, t1, t0
    SIG t2

    # JALR clears bit 0 and flushes the skipped instruction
    la t1, 8f
    ori t1, t1, 1
    jalr t0, 0(t1)
    addi t2, x0, 1
8:
    auipc t3, 0
    sub t4, t3, t0
    SIG t4

    # x0 remains zero
    addi x0, x0, 123
    add t0, x0, x0
    SIG t0

    la t0, _done_flag
    addi t1, x0, 1
    sw t1, 0(t0)

done:
    jal x0, done
