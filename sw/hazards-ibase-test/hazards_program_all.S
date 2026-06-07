    .text
    .globl _start
_start:
# =========================================================
# SETUP
# =========================================================
    LUI   x12, 0x1              # x12 = 0x0000_1000  (base RAM hợp lệ)
    ADDI  x0,  x0, 0            # NOP (đảm bảo ổn định)

# =========================================================
# U-TYPE: LUI, AUIPC
# (Forwarding kiểm tra sau)
# =========================================================
    LUI   x1,  0x12345          # x1  = 0x12345_000
    AUIPC x2,  0x1              # x2  = PC + 0x1000 (kiểm tra ALU + PC path)

# =========================================================
# I-TYPE ALU: ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRAI
# (bao gồm SLTIU với toán hạng âm)
# =========================================================
    ADDI  x3,  x0, 10           # x3  = 10
    ADDI  x4,  x0, -5           # x4  = -5 (0xFFFF_FFFB)
    SLTI  x5,  x4, 0            # x5  = (x4 <s 0)  = 1
    SLTIU x6,  x4, 0            # x6  = (x4 <u 0)  = 0  [unsigned với toán hạng âm]
    XORI  x7,  x3, 0x3          # x7  = 10 ^ 3  = 9
    ORI   x8,  x0, 0xF0         # x8  = 0xF0
    ANDI  x9,  x8, 0x33         # x9  = 0x30
    SLLI  x10, x3, 1            # x10 = 10 << 1 = 20
    SRAI  x11, x4, 1            # x11 = (-5) >>> 1 = -3

# =========================================================
# MEM: SW/LW
#  - Hazard: ALU→STORE (forward vào cả base & data)
#  - Hazard: LOAD-USE chồng (2–3 lớp)
# =========================================================
    ADD   x13, x3,  x10         # x13 = 30         [data cho store]
    ADD   x14, x12, x10         # x14 = 0x1000+20  [base cho store]
    SW    x13, 0(x14)           # MEM[0x1000+20] = 30  (EX/MEM→MEM data+base)

    # Load-use 1: stall = 1, fwd từ MEM/WB
    LW    x15, 0(x14)           # x15 = 30
    ADD   x16, x15, x3          # x16 = 40

    # Load-use 2 (chồng tiếp): stall = 1
    ADD   x17, x16, x3          # x17 = 50 (EX/MEM→EX)
    SW    x17, 4(x14)           # MEM[+24] = 50 (ALU→STORE)
    LW    x18, 4(x14)           # x18 = 50 (tải vừa store)
    ADD   x19, x18, x3          # x19 = 60 (LOAD-USE lần 2)

# =========================================================
# R-TYPE ALU đầy đủ + fwd EX/MEM→EX liên tiếp
# =========================================================
    ADD   x20, x19, x1          # x20 = 60 + 0x12345_000 (quan sát wrap 32-bit)
    SUB   x21, x19, x3          # x21 = 60 - 10 = 50
    SLL   x22, x3,  x1          # x22 = 10 << (x1[4:0]) = 10  [mask 5-bit]
    SLT   x23, x4,  x3          # x23 = (-5) < 10  = 1
    SLTU  x24, x4,  x3          # x24 = (unsigned(-5) < 10) = 0
    XOR   x25, x8,  x9          # x25 = 0xF0 ^ 0x30 = 0xC0
    SRL   x26, x8,  x3          # x26 = 0xF0 >> 10 = 0
    SRA   x27, x4,  x3          # x27 = (-5) >>> 10 = -1
    OR    x28, x8,  x9          # x28 = 0xF0
    AND   x29, x8,  x9          # x29 = 0x30

# =========================================================
# BRANCHES với fwd vào comparator (ALU→BR)
#  + Nhánh liên tiếp: taken→taken, taken→not-taken
# =========================================================
    ADD   x5,  x3,  x3          # x5 = 20
    ADD   x6,  x10, x3          # x6 = 30

    BEQ   x5,  x6,  1f          # không bằng -> không nhảy
    ADDI  x7,  x0,  1           # thực thi
1:
    BNE   x5,  x6,  2f          # khác -> NHẢY (flush lệnh trẻ)
    ADDI  x7,  x0,  2           # (flush)
    ADDI  x7,  x7,  1           # (flush)
2:
    BLT   x4,  x3,  3f          # (-5) < 10 -> NHẢY
    ADDI  x7,  x0,  3           # (flush)
3:
    BGE   x3,  x4,  4f          # 10 >= -5 -> NHẢY  [taken→taken]
    ADDI  x7,  x0,  4           # (flush)
4:
    BLTU  x4,  x3,  5f          # unsigned: không nhảy  [taken→not-taken]
    ADDI  x7,  x0,  5           # thực thi
5:
    BGEU  x4,  x3,  6f          # unsigned: nhảy
    ADDI  x7,  x0,  6           # (flush)
6:

# =========================================================
# CONTROL: Jumps + Jump-use + back-to-back jumps
#  - JALR phải clear bit0: (rs1+imm)&~1
#  - Nếu không có fwd PC+4, kỳ vọng stall=1 cho jump-use
# =========================================================
    JAL   x1,  7f               # x1 = link (PC+4)
    ADD   x30, x1,  x3          # jump-use dùng rd ngay (cần fwd PC+4 hoặc stall=1)
7:
    AUIPC x31, 0                # x31 = PC
    ADDI  x31, x31, 16          # mục tiêu JALR
    JALR  x2,  x31, 0           # x2 = link; PC=(x31+0)&~1  [JALR clear bit0]
    ADDI  x30, x0, 999          # (flush nếu nhảy)
8:
    ADD   x30, x2,  x3          # jump-use sau JALR (fwd/stall hợp lệ)

# =========================================================
# Control: stall & flush trùng lúc
#  - Tạo load-use ngay trước nhánh taken để kiểm IF/ID hold + ID/EX flush
# =========================================================
    SW    x16,  8(x12)          # [0x1008] = 40
    LW    x5,   8(x12)          # x5 <- 40
    BEQ   x3,   x3,  9f         # taken
    ADD   x6,   x5,  x3         # lệnh “trẻ” cần bị flush nếu flush thắng
9:

# =========================================================
# WB ưu tiên hơn EX/MEM khi EX/MEM là bubble
#  - Sau load-use stall, consumer kế phải lấy từ MEM/WB (không lấy EX/MEM-bubble)
# =========================================================
    LW    x7,   0(x14)          # x7 = 30
    ADD   x8,   x7,   x3        # load-use (stall 1 chu kỳ)
    ADD   x9,   x8,   x3        # consumer kế → ưu tiên WB nếu EX/MEM bubble

# =========================================================
# ISA RULES: x0 luôn 0, shift mask 5-bit
# =========================================================
    ADDI  x0,   x0,  123        # cố ghi x0 -> phải vẫn = 0
    ADD   x10,  x0,  x3         # x10 = 10 (chứng minh x0 không đổi)

    ADDI  x5,   x0,  32         # rs2 = 32  (mask 5-bit -> dịch như 0)
    SLL   x11,  x3,  x5         # x11 = 10
    SRL   x11,  x3,  x5         # x11 = 10
    SRA   x11,  x4,  x5         # x11 = -5

# =========================================================
# EDGE CASES (mép dữ liệu): 0, -1, MAX/MIN
# =========================================================
    ADDI  x20,  x0,  0          # 0
    ADDI  x21,  x0, -1          # 0xFFFF_FFFF
    LUI   x22, 0x80000         # x22 ~ 0x7FFF_F000
    ADDI  x22, x22, -1       # x22 = 0x7FFF_FFFF (MAX)
    LUI   x23,  0x80000         # x23 = 0x8000_0000 (MIN)
    ADD   x24,  x22,  x21       # MAX + (-1) = 0x7FFF_FFFE
    SUB   x25,  x20,  x23       # 0 - MIN = 0x8000_0000 (2’s comp)

# =========================================================
# SIGNATURE: ghi một số kết quả ra RAM để quan sát
# =========================================================
    SW    x1,   0(x12)          # 0x1000 = link sau JAL
    SW    x2,   4(x12)          # 0x1004 = link sau JALR
    SW    x5,   8(x12)          # 0x1008 = 40 (load-use/flush test)
    SW    x6,  12(x12)          # 0x100C = 0 (SLTIU âm)
    SW    x10, 16(x12)          # 0x1010 = 10 (x0 rule check)
    SW    x11, 20(x12)          # 0x1014 = kết quả shift-mask
    SW    x16, 24(x12)          # 0x1018 = 40
    SW    x18, 28(x12)          # 0x101C = 30
    SW    x20, 32(x12)          # 0x1020 = 1
    SW    x21, 36(x12)          # 0x1024 = 0xFFFF_FFFF
    SW    x22, 40(x12)          # 0x1028 = 0x7FFF_FFFF
    SW    x23, 44(x12)          # 0x102C = 0x8000_0000
    SW    x24, 48(x12)          # 0x1030 = 0x7FFF_FFFE
    SW    x25, 52(x12)          # 0x1034 = 0x8000_0000
    SW    x27, 56(x12)          # 0x1038 = -1
    SW    x28, 60(x12)          # 0x103C = 0xF0
    SW    x29, 64(x12)          # 0x1040 = 0x30
    SW    x7,  68(x12)          # 0x1044 = 30 (chuỗi load-use)
    SW    x8,  72(x12)          # 0x1048 = 40 (WB ưu tiên hơn EX/MEM-bubble)
    SW    x9,  76(x12)          # 0x104C = 50 (nếu bạn thay đổi chuỗi trên)

# =========================================================
# PASS LOOP
# =========================================================
pass:
    J     pass

# (Optional) FAIL
fail:
    LUI   x13, 0xBAD0B
    ADDI  x13, x13, 0x2D1
    SW    x13, 0(x12)
    J     fail
