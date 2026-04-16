.section .data
result_buffer:
    .space 4096  # Tăng kích thước buffer để chứa đủ tất cả các test

.section .text
.global _start

_start:
    la x20, result_buffer

##################################################
# PM4ADDA.B (SMAQA Signed 4x8-bit MAC)
##################################################
    li x12, 0
    li x10, 0x01010101
    li x11, 0x01010101
    pm4adda.b x12, x10, x11      # 0 + (1*1 + 1*1 + 1*1 + 1*1) = 4
    sw x12, 0(x20)
    addi x20, x20, 4

    li x10, 0xFFFFFFFF       # -1, -1, -1, -1
    li x11, 0x01010101       # 1, 1, 1, 1
    pm4adda.b x12, x10, x11      # 4 + (-1*1 + -1*1 + -1*1 + -1*1) = 0
    sw x12, 0(x20)
    addi x20, x20, 4

##################################################
# PM4ADDAU.B (UMAQA Unsigned 4x8-bit MAC)
##################################################
    li x12, 0
    li x10, 0x01010101
    li x11, 0x01010101
    pm4addau.b x12, x10, x11      # 0 + (1*1 + 1*1 + 1*1 + 1*1) = 4
    sw x12, 0(x20)
    addi x20, x20, 4

    li x10, 0xFFFFFFFF       # 255, 255, 255, 255
    li x11, 0x01010101       # 1, 1, 1, 1
    pm4addau.b x12, x10, x11      # 4 + (255*4) = 4 + 1020 = 1024
    sw x12, 0(x20)
    addi x20, x20, 4

##################################################
# PM4ADDASU.B (SMAQASU Signed-Unsigned 4x8-bit MAC)
##################################################
    li x12, 10
    li x10, 0xFFFFFFFF       # -1, -1, -1, -1
    li x11, 0x01010101       # 1, 1, 1, 1 (Unsigned)
    pm4addasu.b x12, x10, x11    # 10 + (-1*1 + -1*1 + -1*1 + -1*1) = 6
    sw x12, 0(x20)
    addi x20, x20, 4

##################################################
# HAZARD TEST 1: RAW (Back-to-back accumulate)
##################################################
    li x12, 0
    li x10, 0x01010101
    li x11, 0x01010101

    pm4adda.b x12, x10, x11   # x12 = 4
    pm4adda.b x12, x10, x11   # x12 = 8 (RAW hazard)
    pm4adda.b x12, x10, x11   # x12 = 12

    sw x12, 0(x20)
    addi x20, x20, 4

##################################################
# HAZARD TEST 2: RAW different registers
##################################################
    li x5, 0
    li x6, 0x01010101
    li x7, 0x01010101

    pm4adda.b x5, x6, x7      # x5 = 4
    add x8, x5, x0            # dùng ngay x5 (RAW)
    pm4adda.b x8, x6, x7      # x8 = 8

    sw x8, 0(x20)
    addi x20, x20, 4

##################################################
# HAZARD TEST 3: Load-use
##################################################
    li x6, 0x01010101
    sw x6, 0(x20)

    lw x10, 0(x20)            # load
    pm4adda.b x12, x10, x10   # dùng ngay → hazard

    sw x12, 4(x20)
    addi x20, x20, 8

##################################################
# HAZARD TEST 4: Long MAC chain
##################################################
    li x12, 0
    li x10, 0x02020202
    li x11, 0x01010101

    pm4adda.b x12, x10, x11   # +8
    pm4adda.b x12, x10, x11   # +8
    pm4adda.b x12, x10, x11   # +8
    pm4adda.b x12, x10, x11   # +8

    # expected = 32
    sw x12, 0(x20)
    addi x20, x20, 4

##################################################
# HAZARD TEST 5: Mixed instructions hazard
##################################################
    li x12, 0
    li x10, 0xFFFFFFFF   # -1
    li x11, 0x01010101   # 1

    pm4adda.b x12, x10, x11      # -4
    pm4addau.b x12, x10, x11     # +1020 (RAW)
    pm4addasu.b x12, x10, x11    # -4

    sw x12, 0(x20)
    addi x20, x20, 4

##################################################
# HAZARD TEST 6: WAW-like overwrite
##################################################
    li x12, 5
    li x10, 0x01010101
    li x11, 0x01010101

    pm4adda.b x12, x10, x11   # x12 = 9
    pm4adda.b x12, x10, x11   # x12 = 13

    sw x12, 0(x20)
    addi x20, x20, 4
##################################################
# Lệnh Kết Thúc (Infinite Loop)
##################################################
end:
    j end
