li x20, 0x80001000   # base addr dump

# Test 1
li x10, 0xFE10F0F0
li x11, 0x01FF1011
padd.b x12, x10, x11
sw x12, 0(x20)

# Test 2 (signed)
li x10, 0x9B47E3B2
li x11, 0x2D98C4FF
padd.b x12, x10, x11
sw x12, 4(x20)

# Test 3 (unsigned)
li x10, 0x9B47E3B2
li x11, 0x2D98C4FF
padd.b x12, x10, x11
sw x12, 8(x20)

li x10, 0x7F804000
li x11, 0x7F808000
paadd.b x12, x10, x11
sw x12, 12(x20)

li x10, 0x7F804000
li x11, 0x7F808000
paaddu.b x12, x10, x11
sw x12, 16(x20)

li x10, 0xFFFF8040
li x11, 0x02018080
psaddu.b x12, x10, x11
sw x12, 20(x20)

li x10, 0xFFF1EFDF
li x11, 0x000DF302
psub.b x12, x10, x11
sw x12, 24(x20)

li x10, 0x7F808080
li x11, 0x807F4080
pasub.b x12, x10, x11
sw x12, 28(x20)

li x10, 0x7F808081
li x11, 0x807F4001
pasubu.b x12, x10, x11
sw x12, 32(x20)

# case 1
li x10, 0x008020FF
li x11, 0x81803001
pssub.b x12, x10, x11
sw x12, 36(x20)

# overflow case
li x10, 0x407F8180
li x11, 0xC07F7F00
pssub.b x12, x10, x11
sw x12, 40(x20)

# case 1
li x10, 0x5040FF10
li x11, 0x30200010
pssubu.b x12, x10, x11
sw x12, 44(x20)

# overflow case
li x10, 0x0564A0F0
li x11, 0x1032B0FF
pssubu.b x12, x10, x11
sw x12, 48(x20)
