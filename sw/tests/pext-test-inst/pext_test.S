.section .data
.align 4
results:
    .space 64     # đủ chỗ cho tất cả test

.section .text
.global _start

_start:
    la x20, results

# =========================================================
# =============== PADD.B TEST =============================
# =========================================================

# 1. Zero
li x10, 0x00000000
li x11, 0x00000000
padd.b x12, x10, x11        # expect: 0x00000000
sw x12, 0(x20)

# 2. Simple (no overflow)
li x10, 0x01020304
li x11, 0x01010101
padd.b x12, x10, x11        # expect: 0x02030405
sw x12, 4(x20)

# 3. Wrap-around (+ overflow)
li x10, 0xFFFFFFFF          # [-1,-1,-1,-1]
li x11, 0x01010101          # [1,1,1,1]
padd.b x12, x10, x11        # expect: 0x00000000
sw x12, 8(x20)

# 4. Mixed pattern (lane independence)
li x10, 0xFE10F0F0          # [-2,16,-16,-16]
li x11, 0x01FF1011          # [1,-1,16,17]
padd.b x12, x10, x11        # expect: 0xFF0F0001
sw x12, 12(x20)

# 5. Positive overflow edge
li x10, 0x7F7F7F7F
li x11, 0x01010101
padd.b x12, x10, x11        # expect: 0x80808080
sw x12, 16(x20)

# 6. Negative overflow edge
li x10, 0x80808080
li x11, 0xFFFFFFFF
padd.b x12, x10, x11        # expect: 0x7F7F7F7F
sw x12, 20(x20)

# =========================================================
# =============== PAADD.B TEST ============================
# =========================================================

# paadd.b = (a + b) >> 1 (signed average)

# 7. Zero
li x10, 0x00000000
li x11, 0x00000000
paadd.b x12, x10, x11       # expect: 0x00000000
sw x12, 24(x20)

# 8. Positive average
li x10, 0x02040608
li x11, 0x02040608
paadd.b x12, x10, x11       # expect: 0x02040608
sw x12, 28(x20)

# 9. Mixed sign (quan trọng)
li x10, 0x40000000          # [64,0,0,0]
li x11, 0x80000000          # [-128,0,0,0]
paadd.b x12, x10, x11       
# byte0: (64 + -128)/2 = -32 = 0xE0
# expect: 0xE0000000
sw x12, 32(x20)

# 10. Negative edge (-128)
li x10, 0x80808080
li x11, 0x80808080
paadd.b x12, x10, x11       # expect: 0x80808080
sw x12, 36(x20)

# 11. Real mixed case
li x10, 0x7F804000          # [127,-128,64,0]
li x11, 0x7F808000          # [127,-128,-128,0]
paadd.b x12, x10, x11
# [127+127]/2 = 127
# [-128-128]/2 = -128
# [64-128]/2 = -32
# [0+0]/2 = 0
# expect: 0x7F80E000
sw x12, 40(x20)

# =========================================================
# =============== PAADDU.B TEST ===========================
# =========================================================

# 1. Zero
li x10, 0x00000000
li x11, 0x00000000
paaddu.b x12, x10, x11     # expect: 0x00000000
sw x12, 44(x20)

# 2. Simple unsigned avg
li x10, 0x02040608
li x11, 0x02040608
paaddu.b x12, x10, x11     # expect: 0x02040608
sw x12, 48(x20)

# 3. Max + Max
li x10, 0xFFFFFFFF
li x11, 0xFFFFFFFF
paaddu.b x12, x10, x11     # (255+255)/2 = 255 → 0xFF
# expect: 0xFFFFFFFF
sw x12, 52(x20)

# 4. Cross values (important)
li x10, 0x00FF00FF
li x11, 0xFF00FF00
paaddu.b x12, x10, x11
# (0+255)/2 = 127 → 0x7F
# expect: 0x7F7F7F7F
sw x12, 56(x20)

# 5. Your case (fixed)
li x10, 0x7F804000
li x11, 0x7F808000
paaddu.b x12, x10, x11
# expect: 0x7F806000
sw x12, 60(x20)

# =========================================================
# =============== PSADDU.B TEST ===========================
# =========================================================

# 1. Zero
li x10, 0x00000000
li x11, 0x00000000
psaddu.b x12, x10, x11     # expect: 0x00000000
sw x12, 64(x20)

# 2. No overflow
li x10, 0x01020304
li x11, 0x05060708
psaddu.b x12, x10, x11     # expect: 0x06080A0C
sw x12, 68(x20)

# 3. Full saturation
li x10, 0xFFFFFFFF
li x11, 0x01010101
psaddu.b x12, x10, x11     # expect: 0xFFFFFFFF
sw x12, 72(x20)

# 4. Cross pattern (important)
li x10, 0x00FF00FF
li x11, 0xFF00FF00
psaddu.b x12, x10, x11
# (0+255)=255, (255+0)=255
# expect: 0xFFFFFFFF
sw x12, 76(x20)

# 5. Mixed (your case fixed)
li x10, 0xFFFF8040
li x11, 0x02018080
psaddu.b x12, x10, x11     # expect: 0xFFFFFFC0
sw x12, 78(x20)

# =========================================================
# =============== PSUB.B TEST =============================
# =========================================================

# 1. Zero
li x10, 0x00000000
li x11, 0x00000000
psub.b x12, x10, x11     # expect: 0x00000000
sw x12, 82(x20)

# 2. Simple subtract
li x10, 0x05060708
li x11, 0x01020304
psub.b x12, x10, x11     # expect: 0x04040404
sw x12, 86(x20)

# 3. Underflow (important)
li x10, 0x00000000
li x11, 0x01010101
psub.b x12, x10, x11     # expect: 0xFFFFFFFF
sw x12, 90(x20)

# 4. Cross pattern
li x10, 0x00FF00FF
li x11, 0x01000100
psub.b x12, x10, x11
# (0-1)=FF, (255-0)=FF
# expect: 0xFFFF00FF
sw x12, 94(x20)

# 5. Your case (fixed)
li x10, 0xFFF1EFDF
li x11, 0x000DF302
psub.b x12, x10, x11     # expect: 0xFFE4FCDD
sw x12, 98(x20)

# =========================================================
# =============== PASUB.B TEST ============================
# =========================================================

# pasub.b = (a - b) >> 1 (signed)

# 1. Zero
li x10, 0x00000000
li x11, 0x00000000
pasub.b x12, x10, x11     # expect: 0x00000000
sw x12, 102(x20)

# 2. Simple
li x10, 0x08080808
li x11, 0x02020202
pasub.b x12, x10, x11     # (8-2)/2 = 3 → 0x03
# expect: 0x03030303
sw x12, 106(x20)

# 3. Mixed sign
li x10, 0x40000000        # [64,0,0,0]
li x11, 0x80000000        # [-128,0,0,0]
pasub.b x12, x10, x11
# (64 - (-128)) = 192 → /2 = 96 = 0x60
# expect: 0x60000000
sw x12, 110(x20)

# 4. Negative rounding (important)
li x10, 0x00000000
li x11, 0x01010101
pasub.b x12, x10, x11
# (0 - 1) = -1 → >>1 = -1
# expect: 0xFFFFFFFF
sw x12, 114(x20)

# 5. Your case (fixed)
li x10, 0x7F808080
li x11, 0x807F4080
pasub.b x12, x10, x11     # expect: 0x7F80A000
sw x12, 118(x20)

# =========================================================
# =============== PASUBU.B TEST ===========================
# =========================================================

# pasubu.b = (a - b) >> 1 (unsigned)

# 1. Zero
li x10, 0x00000000
li x11, 0x00000000
pasubu.b x12, x10, x11     # expect: 0x00000000
sw x12, 122(x20)

# 2. Simple
li x10, 0x08080808
li x11, 0x02020202
pasubu.b x12, x10, x11     # (8-2)/2 = 3
# expect: 0x03030303
sw x12, 126(x20)

# 3. Underflow (important)
li x10, 0x00000000
li x11, 0x01010101
pasubu.b x12, x10, x11
# (0-1)=255 → >>1 = 127
# expect: 0x7F7F7F7F
sw x12, 130(x20)

# 4. Cross pattern
li x10, 0x00FF00FF
li x11, 0x01000100
pasubu.b x12, x10, x11
# (0-1)=255→127, (255-0)=255→127
# expect: 0x7F7F007F
sw x12, 134(x20)

# 5. Your case (fixed)
li x10, 0x7F808081
li x11, 0x807F4001
pasubu.b x12, x10, x11     # expect: 0x7F002040
sw x12, 138(x20)

# =========================================================
# =============== PSSUB.B TEST ============================
# =========================================================

# 1. Zero
li x10, 0x00000000
li x11, 0x00000000
pssub.b x12, x10, x11     # expect: 0x00000000
sw x12, 142(x20)

# 2. No saturation
li x10, 0x10101010
li x11, 0x01020304
pssub.b x12, x10, x11     # expect: 0x0F0E0D0C
sw x12, 146(x20)

# 3. Positive saturation
li x10, 0x7F7F7F7F
li x11, 0x80808080
pssub.b x12, x10, x11
# 127 - (-128) = 255 → clamp → 127
# expect: 0x7F7F7F7F
sw x12, 150(x20)

# 4. Negative saturation
li x10, 0x80808080
li x11, 0x7F7F7F7F
pssub.b x12, x10, x11
# -128 - 127 = -255 → clamp → -128
# expect: 0x80808080
sw x12, 154(x20)

# 5. Your case (fixed)
li x10, 0x008020FF
li x11, 0x81803001
pssub.b x12, x10, x11     # expect: 0x7F00F0FE
sw x12, 158(x20)

# 6. Your case (fixed)
li x10, 0x407F8180
li x11, 0xC07F7F00
pssub.b x12, x10, x11
sw x12, 162(x20)

# =========================================================
# =============== PSSUBU.B TEST ===========================
# =========================================================

# 1. Zero
li x10, 0x00000000
li x11, 0x00000000
pssubu.b x12, x10, x11     # expect: 0x00000000
sw x12, 166(x20)

# 2. No saturation
li x10, 0x50505050
li x11, 0x10101010
pssubu.b x12, x10, x11     # expect: 0x40404040
sw x12, 170(x20)

# 3. Full saturation (all underflow)
li x10, 0x00000000
li x11, 0xFFFFFFFF
pssubu.b x12, x10, x11     # expect: 0x00000000
sw x12, 174(x20)

# 4. Mixed case
li x10, 0x5040FF10
li x11, 0x30200010
pssubu.b x12, x10, x11     # expect: 0x2020FF00
sw x12, 178(x20)

# 5. Your overflow case
li x10, 0x0564A0F0
li x11, 0x1032B0FF
pssubu.b x12, x10, x11     # expect: 0x00320000
sw x12, 182(x20)

# =========================================================
# =============== PADD.H TEST =============================
# =========================================================

# 1. Zero
li x10, 0x00000000
li x11, 0x00000000
padd.h x12, x10, x11     # expect: 0x00000000
sw x12, 186(x20)

# 2. Simple add (no overflow)
li x10, 0x12345678       # [1234, 5678]
li x11, 0x11112222       # [1111, 2222]
padd.h x12, x10, x11     # expect: 0x2345789A
sw x12, 190(x20)

# 3. Halfword independence (no cross carry)
li x10, 0x0000FFFF       # [0000, FFFF]
li x11, 0x00010001       # [0001, 0001]
padd.h x12, x10, x11     
# FFFF + 0001 = 0000 (wrap)
# 0000 + 0001 = 0001
# expect: 0x00010000
sw x12, 194(x20)

# 4. Overflow (wrap-around)
li x10, 0xFFFF0001       # [FFFF, 0001]
li x11, 0x00020002       # [0002, 0002]
padd.h x12, x10, x11     
# FFFF + 0002 = 0001
# 0001 + 0002 = 0003
# expect: 0x00010003
sw x12, 198(x20)

# 5. Mixed values
li x10, 0x80007FFF       # [-32768, 32767]
li x11, 0x80007FFF       # [-32768, 32767]
padd.h x12, x10, x11     
# 8000 + 8000 = 0000 (wrap)
# 7FFF + 7FFF = FFFE
# expect: 0x0000FFFE
sw x12, 202(x20)

# =========================================================
# =============== PAADD.H TEST ============================
# =========================================================

# paadd.h = (a + b) >> 1  (signed)

# 1. Zero
li x10, 0x00000000
li x11, 0x00000000
paadd.h x12, x10, x11     # expect: 0x00000000
sw x12, 206(x20)

# 2. Same values (no change)
li x10, 0x7FFF8000        # [32767, -32768]
li x11, 0x7FFF8000        # [32767, -32768]
paadd.h x12, x10, x11     
# (a + a) >> 1 = a
# expect: 0x7FFF8000
sw x12, 230(x20)

# 3. Mixed sign (important)
li x10, 0x4000FF01        # [16384, -255]
li x11, 0x800000FE        # [-32768, 254]
paadd.h x12, x10, x11

# lane 0: (16384 + -32768) = -16384 → /2 = -8192 = 0xE000
# lane 1: (-255 + 254) = -1 → >>1 = -1 = 0xFFFF
# expect: 0xE000FFFF
sw x12, 234(x20)

# 4. Positive + positive
li x10, 0x20002000        # [8192, 8192]
li x11, 0x20002000
paadd.h x12, x10, x11     # expect: 0x20002000
sw x12, 238(x20)

# 5. Negative rounding (QUAN TRỌNG)
li x10, 0x00000000
li x11, 0x00010001
paadd.h x12, x10, x11
# (0 + 1) >> 1 = 0
# expect: 0x00000000
sw x12, 242(x20)

# =========================================================
# =============== PAADDU.H TEST ===========================
# =========================================================

# paaddu.h = (a + b) >> 1 (unsigned)

# 1. Zero
li x10, 0x00000000
li x11, 0x00000000
paaddu.h x12, x10, x11     # expect: 0x00000000
sw x12, 246(x20)

# 2. Same values
li x10, 0x7FFF8000         # [32767, 32768]
li x11, 0x7FFF8000
paaddu.h x12, x10, x11     
# (a + a) >> 1 = a
# expect: 0x7FFF8000
sw x12, 250(x20)

# 3. Mixed values (your case)
li x10, 0x40001234         # [16384, 4660]
li x11, 0x80005678         # [32768, 22136]
paaddu.h x12, x10, x11

# lane 0: (16384 + 32768) = 49152 → /2 = 24576 = 0x6000
# lane 1: (4660 + 22136) = 26796 → /2 = 13398 = 0x3456
# expect: 0x60003456
sw x12, 254(x20)

# 4. Max values (no overflow after avg)
li x10, 0xFFFFFFFF         # [65535, 65535]
li x11, 0xFFFFFFFF
paaddu.h x12, x10, x11     
# (65535 + 65535) >> 1 = 65535
# expect: 0xFFFFFFFF
sw x12, 258(x20)

# 5. Rounding down (QUAN TRỌNG)
li x10, 0x00010001
li x11, 0x00000000
paaddu.h x12, x10, x11
# (1 + 0) >> 1 = 0
# expect: 0x00000000
sw x12, 262(x20)

# =========================================================
# =============== PSADD.H TEST ============================
# =========================================================

# psadd.h = signed saturating addition

# 1. Zero
li x10, 0x00000000
li x11, 0x00000000
psadd.h x12, x10, x11     # expect: 0x00000000
sw x12, 266(x20)

# 2. No saturation (your case)
li x10, 0x70008000        # [28672, -32768]
li x11, 0x90001000        # [-28672, 4096]
psadd.h x12, x10, x11     
# 7000 + 9000 = 0000
# 8000 + 1000 = 9000
# expect: 0x00009000
sw x12, 270(x20)

# 3. Positive saturation
li x10, 0x7FFF7FFF        # [32767, 32767]
li x11, 0x00010001
psadd.h x12, x10, x11
# 32767 + 1 = 32768 → clamp → 32767
# expect: 0x7FFF7FFF
sw x12, 274(x20)

# 4. Negative saturation
li x10, 0x80008000        # [-32768, -32768]
li x11, 0xFFFF0000        # [-1, 0]
psadd.h x12, x10, x11
# -32768 + -1 = -32769 → clamp → -32768
# expect: 0x80008000
sw x12, 278(x20)

# 5. Your saturation case
li x10, 0x7FFF8000        # [32767, -32768]
li x11, 0x0001FFFF        # [1, -1]
psadd.h x12, x10, x11
# 32767 + 1 → clamp → 32767
# -32768 + -1 → clamp → -32768
# expect: 0x7FFF8000
sw x12, 282(x20)

# =========================================================
# =============== PSADDU.H TEST ===========================
# =========================================================

# psaddu.h = unsigned saturating addition

# 1. Zero
li x10, 0x00000000
li x11, 0x00000000
psaddu.h x12, x10, x11     # expect: 0x00000000
sw x12, 286(x20)

# 2. No saturation (your case)
li x10, 0x20003000         # [8192, 12288]
li x11, 0x10004000         # [4096, 16384]
psaddu.h x12, x10, x11     
# 2000 + 1000 = 3000
# 3000 + 4000 = 7000
# expect: 0x30007000
sw x12, 290(x20)

# 3. Partial saturation
li x10, 0x2000FFFF         # [8192, 65535]
li x11, 0x30000001         # [12288, 1]
psaddu.h x12, x10, x11
# 2000 + 3000 = 5000
# FFFF + 0001 = 10000 → clamp → FFFF
# expect: 0x5000FFFF
sw x12, 294(x20)

# 4. Mixed saturation (your case)
li x10, 0x70008000         # [28672, 32768]
li x11, 0x10009000         # [4096, 36864]
psaddu.h x12, x10, x11
# 7000 + 1000 = 8000
# 8000 + 9000 = 11000 → clamp → FFFF
# expect: 0x8000FFFF
sw x12, 298(x20)

# 5. Full saturation
li x10, 0xFFFFFFFF         # [65535, 65535]
li x11, 0x00010001
psaddu.h x12, x10, x11
# all overflow → clamp
# expect: 0xFFFFFFFF
sw x12, 302(x20)

# =========================================================
# =============== PSUB.H TEST =============================
# =========================================================

# psub.h = a - b (wrap modulo 2^16)

# 1. Zero
li x10, 0x00000000
li x11, 0x00000000
psub.h x12, x10, x11     # expect: 0x00000000
sw x12, 306(x20)

# 2. No overflow (your case)
li x10, 0x1030FF10       # [1030, FF10]
li x11, 0x0800FF20       # [0800, FF20]
psub.h x12, x10, x11
# 1030 - 0800 = 0830
# FF10 - FF20 = FFF0
# expect: 0x0830FFF0
sw x12, 310(x20)

# 3. Underflow (wrap)
li x10, 0x00000000
li x11, 0x00010001
psub.h x12, x10, x11
# 0000 - 0001 = FFFF
# expect: 0xFFFFFFFF
sw x12, 314(x20)

# 4. Mixed values (your case)
li x10, 0x80008000       # [-32768, -32768]
li x11, 0x7FFF0001       # [32767, 1]
psub.h x12, x10, x11
# 8000 - 7FFF = 0001
# 8000 - 0001 = 7FFF
# expect: 0x00017FFF
sw x12, 318(x20)

# 5. Cross pattern
li x10, 0x0000FFFF
li x11, 0x00010000
psub.h x12, x10, x11
# 0000 - 0001 = FFFF
# FFFF - 0000 = FFFF
# expect: 0xFFFFFFFF
sw x12, 322(x20)

# =========================================================
# =============== PASUB.H TEST ============================
# =========================================================

# pasub.h = (a - b) >> 1 (signed)

# 1. Zero
li x10, 0x00000000
li x11, 0x00000000
pasub.h x12, x10, x11     # expect: 0x00000000
sw x12, 326(x20)

# 2. Opposite values (your case)
li x10, 0x7FFF8000        # [32767, -32768]
li x11, 0x80007FFF        # [-32768, 32767]
pasub.h x12, x10, x11
# (32767 - (-32768)) = 65535 → /2 = 32767 = 0x7FFF
# (-32768 - 32767) = -65535 → >>1 = -32768 = 0x8000
# expect: 0x7FFF8000
sw x12, 330(x20)

# 3. Mixed values (your case)
li x10, 0x80007FFF        # [-32768, 32767]
li x11, 0x40002000        # [16384, 8192]
pasub.h x12, x10, x11
# (-32768 - 16384) = -49152 → >>1 = -24576 = 0xA000
# (32767 - 8192) = 24575 → >>1 = 12287 = 0x2FFF
# expect: 0xA0002FFF
sw x12, 334(x20)

# 4. Positive rounding
li x10, 0x00020002
li x11, 0x00010001
pasub.h x12, x10, x11
# (2 - 1) >>1 = 0
# expect: 0x00000000
sw x12, 338(x20)

# 5. Negative rounding (QUAN TRỌNG)
li x10, 0x00000000
li x11, 0x00010001
pasub.h x12, x10, x11
# (0 - 1) = -1 → >>1 = -1
# expect: 0xFFFFFFFF
sw x12, 342(x20)

# =========================================================
# =============== PASUBU.H TEST ===========================
# =========================================================

# pasubu.h = (a - b) >> 1 (unsigned)

# 1. Zero
li x10, 0x00000000
li x11, 0x00000000
pasubu.h x12, x10, x11     # expect: 0x00000000
sw x12, 346(x20)

# 2. Normal case (your case)
li x10, 0x80008001         # [32768, 32769]
li x11, 0x40000001         # [16384, 1]
pasubu.h x12, x10, x11
# (8000 - 4000) = 4000 → >>1 = 2000
# (8001 - 0001) = 8000 → >>1 = 4000
# expect: 0x20004000
sw x12, 350(x20)

# 3. Underflow (QUAN TRỌNG)
li x10, 0x00000000
li x11, 0x00010001
pasubu.h x12, x10, x11
# (0 - 1) = FFFF → >>1 = 7FFF
# expect: 0x7FFF7FFF
sw x12, 354(x20)

# 4. Mixed wrap (your case)
li x10, 0x7FFF8000         # [32767, 32768]
li x11, 0x80007FFF         # [32768, 32767]
pasubu.h x12, x10, x11
# (7FFF - 8000) = FFFF → >>1 = 7FFF
# (8000 - 7FFF) = 0001 → >>1 = 0000
# expect: 0x7FFF0000
sw x12, 358(x20)

# 5. Full range values
li x10, 0xFFFFFFFF         # [65535, 65535]
li x11, 0x00010001
pasubu.h x12, x10, x11
# (FFFF - 0001) = FFFE → >>1 = 7FFF
# expect: 0x7FFF7FFF
sw x12, 362(x20)

# =========================================================
# =============== PSSUB.H TEST ============================
# =========================================================

# pssub.h = signed saturating subtraction

# 1. Zero
li x10, 0x00000000
li x11, 0x00000000
pssub.h x12, x10, x11     # expect: 0x00000000
sw x12, 366(x20)

# 2. No overflow (your case)
li x10, 0x3F2E5D4C        # [16174, 23884]
li x11, 0x1A1B2C3D        # [6683, 11325]
pssub.h x12, x10, x11
# 3F2E - 1A1B = 2513
# 5D4C - 2C3D = 310F
# expect: 0x2513310F
sw x12, 370(x20)

# 3. Positive saturation
li x10, 0x7FFF7FFF        # [32767, 32767]
li x11, 0x80008000        # [-32768, -32768]
pssub.h x12, x10, x11
# 32767 - (-32768) = 65535 → clamp → 32767
# expect: 0x7FFF7FFF
sw x12, 374(x20)

# 4. Negative saturation
li x10, 0x80008000        # [-32768, -32768]
li x11, 0x7FFF7FFF        # [32767, 32767]
pssub.h x12, x10, x11
# -32768 - 32767 = -65535 → clamp → -32768
# expect: 0x80008000
sw x12, 378(x20)

# 5. Your saturation case
li x10, 0x7FFF8000        # [32767, -32768]
li x11, 0x80007FFF        # [-32768, 32767]
pssub.h x12, x10, x11
# 32767 - (-32768) → clamp → 32767
# -32768 - 32767 → clamp → -32768
# expect: 0x7FFF8000
sw x12, 382(x20)

# 6. Mixed no overflow
li x10, 0x40008001        # [16384, -32767]
li x11, 0x20000001        # [8192, 1]
pssub.h x12, x10, x11
# 4000 - 2000 = 2000
# 8001 - 0001 = 8000 (-32768)
# expect: 0x20008000
sw x12, 386(x20)

# =========================================================
# =============== PSSUBU.H TEST ===========================
# =========================================================

# pssubu.h = unsigned saturating subtraction
# result = max(a - b, 0)

# 1. Zero
li x10, 0x00000000
li x11, 0x00000000
pssubu.h x12, x10, x11     # expect: 0x00000000
sw x12, 390(x20)

# 2. No saturation
li x10, 0x30004000         # [12288, 16384]
li x11, 0x10002000         # [4096, 8192]
pssubu.h x12, x10, x11
# 3000 - 1000 = 2000
# 4000 - 2000 = 2000
# expect: 0x20002000
sw x12, 394(x20)

# 3. Mixed case (your case)
li x10, 0x7A5B1357         # [7A5B, 1357]
li x11, 0x6A5C2468         # [6A5C, 2468]
pssubu.h x12, x10, x11
# 7A5B - 6A5C = 0FFF
# 1357 - 2468 = negative → clamp 0000
# expect: 0x0FFF0000
sw x12, 398(x20)

# 4. Full saturation (your case)
li x10, 0x1234ABCD
li x11, 0x5678DCBA
pssubu.h x12, x10, x11
# both lanes negative → clamp
# expect: 0x00000000
sw x12, 402(x20)

# 5. Edge case
li x10, 0x0001FFFF
li x11, 0x00010001
pssubu.h x12, x10, x11
# 0001 - 0001 = 0000
# FFFF - 0001 = FFFE
# expect: 0x0000FFFE
sw x12, 404(x20)
# =========================
# END
# =========================
end:
    j end
