    .option norelax
    .option norvc

    .macro SIG reg
        sw \reg, 0(s0)
        addi s0, s0, 4
    .endm

    .section .signature, "aw"
    .align 4
signature:
    .space 512

    .section .bss
    .align 4
scratch:
    .space 128

    .section .text
    .globl _start
_start:
    la s0, signature
    la s1, scratch

    # 1. ALU -> ALU chain
    addi t0, x0, 1
    addi t1, t0, 2
    addi t2, t1, 3
    SIG t2

    # 2. ALU -> store data
    addi t0, x0, 0x55
    sw t0, 0(s1)
    lw t1, 0(s1)
    SIG t1

    # 3. ALU -> store base
    addi t6, s1, 4
    addi t0, x0, 0x66
    sw t0, 0(t6)
    lw t1, 4(s1)
    SIG t1

    # 4. Load-use into ALU
    addi t0, x0, 123
    sw t0, 8(s1)
    lw t1, 8(s1)
    addi t2, t1, 1
    SIG t2

    # 5. Load-use into store data
    lw t1, 8(s1)
    sw t1, 12(s1)
    lw t2, 12(s1)
    SIG t2

    # 6. Load-use into branch comparator
    addi t0, x0, 5
    sw t0, 16(s1)
    addi t2, x0, 0
    lw t1, 16(s1)
    beq t1, t0, 1f
    addi t2, x0, 99
1:
    addi t2, t2, 1
    SIG t2

    # 7. ALU -> branch comparator
    addi t1, x0, 9
    addi t2, t1, 0
    beq t2, t1, 2f
    addi t3, x0, 99
2:
    addi t3, x0, 7
    SIG t3

    # 8. Taken branch flush
    addi t0, x0, 0
    beq x0, x0, 3f
    addi t0, t0, 99
3:
    addi t0, t0, 1
    SIG t0

    # 9. JAL flush
    addi t0, x0, 0
    jal ra, 4f
    addi t0, t0, 99
4:
    addi t0, t0, 2
    SIG t0

    # 10. JALR clear bit 0 and flush
    la t1, 5f
    ori t1, t1, 1
    addi t0, x0, 0
    jalr ra, 0(t1)
    addi t0, t0, 99
5:
    addi t0, t0, 3
    SIG t0

    # 11. Load-use branch with taken flush
    addi t0, x0, 40
    sw t0, 20(s1)
    lw t1, 20(s1)
    beq t1, t0, 6f
    addi t3, x0, 99
6:
    addi t3, x0, 11
    SIG t3

    # 12. WB priority after load-use bubble
    addi t4, x0, 10
    lw t1, 8(s1)
    add t2, t1, t4
    add t3, t2, t4
    SIG t3

    # 13. M result -> ALU
    addi t0, x0, 7
    addi t1, x0, 6
    mul t2, t0, t1
    addi t3, t2, 1
    SIG t3

    # 14. M result -> store data
    addi t0, x0, 7
    addi t1, x0, 6
    mul t2, t0, t1
    sw t2, 24(s1)
    lw t3, 24(s1)
    SIG t3

    # 15. P result -> ALU
    li t0, 0x01010101
    li t1, 0x01010101
    padd.b t2, t0, t1
    addi t3, t2, 1
    SIG t3

    # 16. ALU result -> P operand
    li t0, 0x01010100
    addi t0, t0, 1
    li t1, 0x01010101
    padd.b t2, t0, t1
    SIG t2

    # 17. P result -> P operand
    li t0, 0x01010101
    li t1, 0x01010101
    padd.b t2, t0, t1
    padd.b t3, t2, t1
    SIG t3

    # 18. Back-to-back MAC accumulator forwarding
    li t2, 0
    li t0, 0x01010101
    li t1, 0x01010101
    pm4adda.b t2, t0, t1
    pm4adda.b t2, t0, t1
    pm4adda.b t2, t0, t1
    SIG t2

    # 19. Load-use into MAC rs operand
    li t0, 0x01010101
    sw t0, 40(s1)
    lw t1, 40(s1)
    li t2, 0
    pm4adda.b t2, t1, t1
    SIG t2

    # 20. Load-use into MAC accumulator rd source
    li t0, 0x01010101
    li t1, 0x01010101
    li t2, 5
    sw t2, 44(s1)
    lw t2, 44(s1)
    pm4adda.b t2, t0, t1
    SIG t2

    # 21. x0 must never forward a fake write
    addi x0, x0, 99
    addi t0, x0, 1
    SIG t0

    # 22. JAL PC+4 use at jump target
    jal ra, 7f
    addi t0, x0, 1
7:
    add t0, ra, x0
    auipc t1, 0
    addi t1, t1, -8
    sub t2, t0, t1
    SIG t2

    # 23. Mixed MAC accumulator forwarding
    li t2, 0
    li t0, 0xffffffff
    li t1, 0x01010101
    pm4adda.b t2, t0, t1
    pm4addau.b t2, t0, t1
    pm4addasu.b t2, t0, t1
    SIG t2

    # 24. MAC overwrite chain
    li t2, 5
    li t0, 0x01010101
    li t1, 0x01010101
    pm4adda.b t2, t0, t1
    pm4adda.b t2, t0, t1
    SIG t2

    # 25. P result -> store data
    li t0, 0x01010101
    li t1, 0x01010101
    padd.b t2, t0, t1
    sw t2, 52(s1)
    lw t3, 52(s1)
    SIG t3

    la t0, _done_flag
    addi t1, x0, 1
    sw t1, 0(t0)

done:
    jal x0, done
