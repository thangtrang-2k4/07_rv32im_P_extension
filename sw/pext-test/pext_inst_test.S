.section .data
.align 4
results:
    .space 8192

.section .text
.global _start

_start:
    la x20, results

# =========================================================
# ================= BYTE OPERATIONS ========================
# =========================================================

li x10, 0xFE10F0F0
li x11, 0x01FF1011
padd.b x12, x10, x11
sw x12, 0(x20)

li x10, 0x9B47E3B2
li x11, 0x2D98C4FF
padd.b x12, x10, x11
sw x12, 4(x20)

li x10, 0x7F804000
li x11, 0x7F808000
paadd.b x12, x10, x11
sw x12, 8(x20)

li x10, 0x7F804000
li x11, 0x7F808000
paaddu.b x12, x10, x11
sw x12, 12(x20)

li x10, 0xFFFF8040
li x11, 0x02018080
psaddu.b x12, x10, x11
sw x12, 16(x20)

li x10, 0xFFF1EFDF
li x11, 0x000DF302
psub.b x12, x10, x11
sw x12, 20(x20)

li x10, 0x7F808080
li x11, 0x807F4080
pasub.b x12, x10, x11
sw x12, 24(x20)

li x10, 0x7F808081
li x11, 0x807F4001
pasubu.b x12, x10, x11
sw x12, 28(x20)

li x10, 0x008020FF
li x11, 0x81803001
pssub.b x12, x10, x11
sw x12, 32(x20)

li x10, 0x407F8180
li x11, 0xC07F7F00
pssub.b x12, x10, x11
sw x12, 36(x20)

li x10, 0x5040FF10
li x11, 0x30200010
pssubu.b x12, x10, x11
sw x12, 40(x20)

li x10, 0x0564A0F0
li x11, 0x1032B0FF
pssubu.b x12, x10, x11
sw x12, 44(x20)

# =========================================================
# ================= HALFWORD OPERATIONS ====================
# =========================================================

li x10, 0x12345678
li x11, 0x11112222
padd.h x12, x10, x11
sw x12, 48(x20)

li x10, 0x7FFF8000
li x11, 0x7FFF8000
paadd.h x12, x10, x11
sw x12, 52(x20)

li x10, 0x4000FF01
li x11, 0x800000FE
paadd.h x12, x10, x11
sw x12, 56(x20)

li x10, 0x7FFF8000
li x11, 0x7FFF8000
paaddu.h x12, x10, x11
sw x12, 60(x20)

li x10, 0x40001234
li x11, 0x80005678
paaddu.h x12, x10, x11
sw x12, 64(x20)

li x10, 0x70008000
li x11, 0x90001000
psadd.h x12, x10, x11
sw x12, 68(x20)

li x10, 0x7FFF8000
li x11, 0x0001FFFF
psadd.h x12, x10, x11
sw x12, 72(x20)

li x10, 0x20003000
li x11, 0x10004000
psaddu.h x12, x10, x11
sw x12, 76(x20)

li x10, 0x2000FFFF
li x11, 0x30000001
psaddu.h x12, x10, x11
sw x12, 80(x20)

li x10, 0x70008000
li x11, 0x10009000
psaddu.h x12, x10, x11
sw x12, 84(x20)

li x10, 0x1030FF10
li x11, 0x0800FF20
psub.h x12, x10, x11
sw x12, 88(x20)

li x10, 0x80008000
li x11, 0x7FFF0001
psub.h x12, x10, x11
sw x12, 92(x20)

li x10, 0x7FFF8000
li x11, 0x80007FFF
pasub.h x12, x10, x11
sw x12, 96(x20)

li x10, 0x80007FFF
li x11, 0x40002000
pasub.h x12, x10, x11
sw x12, 100(x20)

li x10, 0x80008001
li x11, 0x40000001
pasubu.h x12, x10, x11
sw x12, 104(x20)

li x10, 0x7FFF8000
li x11, 0x80007FFF
pasubu.h x12, x10, x11
sw x12, 108(x20)

li x10, 0x3F2E5D4C
li x11, 0x1A1B2C3D
pssub.h x12, x10, x11
sw x12, 112(x20)

li x10, 0x7FFF8000
li x11, 0x80007FFF
pssub.h x12, x10, x11
sw x12, 116(x20)

li x10, 0x40008001
li x11, 0x20000001
pssub.h x12, x10, x11
sw x12, 120(x20)

li x10, 0x7A5B1357
li x11, 0x6A5C2468
pssubu.h x12, x10, x11
sw x12, 124(x20)

li x10, 0x1234ABCD
li x11, 0x5678DCBA
pssubu.h x12, x10, x11
sw x12, 128(x20)

# =========================================================
# ================= SPECIAL (HX / COMPARE / CLIP / ABS) ===
# =========================================================

li x10, 0x7A5B6A5C
li x11, 0x13572468
pashx x12, x10, x11
sw x12, 132(x20)

li x10, 0x7A5B6A5C
li x11, 0x13572468
paashx x12, x10, x11
sw x12, 136(x20)

li x10, 0x7FFF8000
li x11, 0x7FFF7FFF
paashx x12, x10, x11
sw x12, 140(x20)

li x10, 0x80008000
li x11, 0x40008000
paashx x12, x10, x11
sw x12, 144(x20)

li x10, 0x1A5B6A5C
li x11, 0x23572468
psashx x12, x10, x11
sw x12, 148(x20)

li x10, 0x7FFF8000
li x11, 0x7FFF0001
psashx x12, x10, x11
sw x12, 152(x20)

li x10, 0x6A5C7A5B
li x11, 0x24681357
psahx x12, x10, x11
sw x12, 156(x20)

li x10, 0x6A5C7A5B
li x11, 0x24681357
pasahx x12, x10, x11
sw x12, 160(x20)

li x10, 0x80007FFF
li x11, 0x7FFF7FFF
pasahx x12, x10, x11
sw x12, 164(x20)

li x10, 0x80008000
li x11, 0x80004000
pasahx x12, x10, x11
sw x12, 168(x20)

li x10, 0x6A5C1A5B
li x11, 0x24682357
pssahx x12, x10, x11
sw x12, 172(x20)

li x10, 0x80007FFF
li x11, 0x7FFF0001
pssahx x12, x10, x11
sw x12, 176(x20)

# ABS
li x10, 0x1234FFFD
pabs.h x12, x10
sw x12, 180(x20)

li x10, 0xFFFFFFED
pabs.h x12, x10
sw x12, 184(x20)

li x10, 0xFFFD1234
pabs.h x12, x10
sw x12, 188(x20)
