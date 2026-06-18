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
    .space 512

    .section .text
    .globl _start
_start:
    la s0, signature

    # Byte add/sub families
    li t0, 0x01020304
    li t1, 0x01010101
    padd.b t2, t0, t1
    SIG t2

    li t0, 0x05060708
    li t1, 0x01020304
    psub.b t2, t0, t1
    SIG t2

    li t0, 0x02040608
    li t1, 0x02040608
    paadd.b t2, t0, t1
    SIG t2

    li t0, 0x00ff00ff
    li t1, 0xff00ff00
    paaddu.b t2, t0, t1
    SIG t2

    li t0, 0x00000000
    li t1, 0x01010101
    pasub.b t2, t0, t1
    SIG t2

    pasubu.b t2, t0, t1
    SIG t2

    li t0, 0xffffffff
    li t1, 0x01010101
    psaddu.b t2, t0, t1
    SIG t2

    li t0, 0x00000000
    li t1, 0xffffffff
    pssubu.b t2, t0, t1
    SIG t2

    li t0, 0x7f7f7f7f
    li t1, 0x01010101
    psadd.b t2, t0, t1
    SIG t2

    li t0, 0x80808080
    li t1, 0x01010101
    pssub.b t2, t0, t1
    SIG t2

    # Halfword add/sub families
    li t0, 0x12345678
    li t1, 0x11112222
    padd.h t2, t0, t1
    SIG t2

    li t0, 0x1030ff10
    li t1, 0x0800ff20
    psub.h t2, t0, t1
    SIG t2

    li t0, 0x20002000
    li t1, 0x20002000
    paadd.h t2, t0, t1
    SIG t2

    li t0, 0xffffffff
    li t1, 0xffffffff
    paaddu.h t2, t0, t1
    SIG t2

    li t0, 0x00000000
    li t1, 0x00010001
    pasub.h t2, t0, t1
    SIG t2

    pasubu.h t2, t0, t1
    SIG t2

    li t0, 0x7fff7fff
    li t1, 0x00010001
    psadd.h t2, t0, t1
    SIG t2

    li t0, 0x80008000
    li t1, 0x00010001
    pssub.h t2, t0, t1
    SIG t2

    li t0, 0xffffffff
    li t1, 0x00010001
    psaddu.h t2, t0, t1
    SIG t2

    li t0, 0x30004000
    li t1, 0x10002000
    pssubu.h t2, t0, t1
    SIG t2

    # Compare/min/max/clip
    li t0, 0x12348000
    li t1, 0x12347fff
    pmseq.h t2, t0, t1
    SIG t2

    li t0, 0x80000001
    li t1, 0x7fff0002
    pmslt.h t2, t0, t1
    SIG t2

    li t0, 0x00010002
    li t1, 0x00020001
    pmsltu.h t2, t0, t1
    SIG t2

    li t0, 0x80000005
    li t1, 0x7fff0003
    pmin.h t2, t0, t1
    SIG t2

    pmax.h t2, t0, t1
    SIG t2

    pminu.h t2, t0, t1
    SIG t2

    pmaxu.h t2, t0, t1
    SIG t2

    li t0, 0x8000fffd
    psabs.h t2, t0
    SIG t2

    li t0, 0x000afff0
    psati.h t2, t0, 3
    SIG t2

    pusati.h t2, t0, 3
    SIG t2

    # 4x8 MAC families
    li t2, 0
    li t0, 0x01010101
    li t1, 0x01010101
    pm4adda.b t2, t0, t1
    SIG t2

    li t2, 10
    li t0, 0xffffffff
    li t1, 0x01010101
    pm4adda.b t2, t0, t1
    SIG t2

    li t2, 0
    li t0, 0xffffffff
    li t1, 0x01010101
    pm4addau.b t2, t0, t1
    SIG t2

    li t2, 0
    li t0, 0xffffffff
    li t1, 0x01010101
    pm4addasu.b t2, t0, t1
    SIG t2

    la t0, _done_flag
    addi t1, x0, 1
    sw t1, 0(t0)

done:
    jal x0, done
