# Phân Tích Chi Tiết: Tại Sao pext (606 cycles) > scala (598 cycles)?

## 1. Quan sát đầu tiên: Scalar KHÔNG dùng phép nhân MUL

> [!IMPORTANT]
> Nhìn vào disassembly của [scala.s](file:///d:/Workspace/04_Projects/01_GitHub/07_rv32im_P_extension/sw/Filter-Sobel/scala.s), **KHÔNG có lệnh MUL nào cả!** GCC đã tự động tối ưu tất cả phép nhân với hệ số kernel (-1, -2, 0, +1, +2) thành các phép **shift + add/sub**.

### Cách GCC tối ưu phép nhân kernel:

| Phép nhân gốc (`scala.c`) | Được biên dịch thành |
|---|---|
| `*(-1)` → `-x` | `neg` hoặc `sub` (1 lệnh) |
| `*(-2)` → `-(x<<1)` | `slli` + `sub` hoặc ngược lại (đã kết hợp trong luồng) |
| `*(+1)` → `x` | Trực tiếp, không cần lệnh |
| `*(+2)` → `x<<1` | `slli x, 1` (1 lệnh) |
| `*(0)` | Bỏ qua hoàn toàn |

**Kết quả**: Scalar version thực chất chỉ dùng `slli`, `add`, `sub`, `neg` — toàn bộ đều là **1-cycle ALU operations** trong pipeline, **KHÔNG có lệnh MUL multi-cycle nào cả**.

→ **Vậy: Đúng rồi, phép nhân bên scala nó dùng shift-add nên rất nhanh!**

---

## 2. Đếm lệnh tĩnh (Static Instruction Count)

| | **scala** | **pext** |
|---|---|---|
| File imem.hex | 120 lệnh (30 dòng × 4) | 124 lệnh (31 dòng × 4) |
| Hàm `sobel`/`sobel_pext` | 0x80000030 → 0x8000017C (84 lệnh) | 0x80000030 → 0x8000018C (88 lệnh) |
| Hàm `main` | 0x80000180 → 0x800001DC (24 lệnh) | 0x80000190 → 0x800001EC (24 lệnh) |
| `_start` + `clear_bss` | 12 lệnh | 12 lệnh |

> [!NOTE]
> Pext có nhiều hơn 4 lệnh tĩnh ở hàm sobel, chủ yếu từ việc **setup kernel constants** (6 lệnh `lui`/`addi` cho kx_top, kx_mid, ky_top, ky_bot, v.v.) — đây là overhead 1 lần.

---

## 3. Phân tích vòng lặp inner loop – nơi chiếm phần lớn cycles

### 3.1. Scalar inner loop (0x800000A8 → 0x8000014C)

Vòng lặp inner `j=1..3` (3 iterations), mỗi iteration chạy từ `0x800000A8` đến `0x8000014C`:

```
# --- Mỗi iteration inner loop (j) ---
00a8: add   s4, t4, a3        # tính output address
00ac: addi  a3, a3, 1
00b0: add   a4, a2, a3        # tính input address dòng giữa
00b4: lbu   a0, 0(a4)         # load pixel mới  ⚠️ load-use nếu dùng ngay
00b8: neg   s5, t1            # -top_left (tính toán song song)
00bc: slli  s5, s5, 1         # ×2
00c0: sub   a4, a0, s6        # dùng a0 vừa load → CÓ THỂ forwarding từ MEM
00c4: sub   s5, s5, s6
00c8: slli  a5, a5, 1         # ×2 top_center  
00cc: add   a6, t2, a3
00d0: sub   a5, a4, a5
00d4: lbu   a6, 0(a6)         # load pixel bottom ⚠️
00d8: slli  a4, a7, 1         # ×2
00dc: sub   s5, s5, a0
00e0: add   a4, a4, a5
00e4: add   s5, a1, s5
00e8: slli  a5, t3, 1
00ec: add   a5, a5, s5
00f0: sub   a4, a4, a1
00f4: add   a4, a6, a4        # dùng a6 vừa load → forwarding
00f8: add   a5, a6, a5
00fc: srai  s6, a4, 31        # abs trick
0100: srai  s5, a5, 31
0104: xor   a4, s6, a4
0108: xor   a5, s5, a5
010c: sub   a4, a4, s6
0110: sub   a5, a5, s5
0114: add   a5, a5, a4        # mag = |gx| + |gy|
0118: bge   s2, a5, 0x120     # clip check
011c: li    a5, 255
0120: sb    a5, 0(s4)         # store output
0124-0148: mv registers (shift window) ×8 lệnh
014c: j     0x00a8 (hoặc beq → exit)
```

**Đếm**: ~40 lệnh/iteration × 3 iterations = **~120 lệnh động** cho inner loop
(Nhưng iteration đầu tiên bắt đầu sớm hơn vì tải pixel ban đầu ngoài loop)

**Đặc điểm scalar**:
- **Rất ít load-use stall**: Chỉ có 2 `lbu` trong loop, và compiler đã **xen kẽ** (schedule) các lệnh tính toán giữa load và sử dụng:
  - `lbu a0` ở 0x00b4 → dùng a0 ở 0x00c0 (3 lệnh cách = **0 stall**, forwarding từ MEM)
  - `lbu a6` ở 0x00d4 → dùng a6 ở 0x00f4 (8 lệnh cách = **0 stall**)
- **ABS dùng shift-xor-sub trick** (branchless): không có branch penalty
- **Chỉ 1 branch** (`bge` cho clip) → taken 1 lần/penalty nhỏ

### 3.2. P-ext inner loop (0x800000AC → 0x80000158)

```
# --- Mỗi iteration inner loop (j) ---
00ac: add   a5, t1, a3        # tính base address
00b0: add   s3, a5, a7
00b4: lbu   a1, 2(s3)         # load top-right     ⚠️
00b8: add   a5, a5, t3
00bc: lbu   s4, 1(s3)         # load top-center    ⚠️
00c0: lbu   a4, 2(a5)         # load bot-right     ⚠️
00c4: lbu   s2, 1(a5)         # load bot-center    ⚠️
00c8: lbu   s5, 0(s3)         # load top-left      ⚠️
00cc: slli  s4, s4, 8         # ← dùng s4 vừa lbu ở 00bc → ⚡ LOAD-USE STALL!
00d0: lbu   s3, 0(a5)         # load bot-left
00d4: slli  a5, a1, 16        # ← dùng a1 vừa lbu ở 00b4 (5 lệnh cách → OK, forwarding)
00d8: or    s4, s4, a5        # pack top row part 2
00dc: slli  s2, s2, 8         # ← dùng s2 vừa lbu ở 00c4 (6 lệnh cách → OK)
00e0: slli  a5, a4, 16
00e4: or    s2, s2, a5        # pack bot row part 2
00e8: li    a4, 0             # gx = 0
00ec: add   a1, a0, a2        # output addr
00f0: or    s4, s4, s5        # pack top row final  ← dùng s5 lbu ở 00c8 (10 lệnh → OK)
00f4: or    s2, s2, s3        # pack bot row final  ← dùng s3 lbu ở 00d0 (9 lệnh → OK)
00f8: mv    a5, a4            # gy = 0
00fc: addi  a2, a2, 1

0100: pm4addasu.b a5, a6, s4  # gx += kx_top × row_top
0104: lbu   s3, 1(a3)         # load mid-center     ⚠️
0108: lbu   s5, 2(a3)         # load mid-right      ⚠️
010c: lbu   s6, 0(a3)         # load mid-left       ⚠️
0110: slli  s3, s3, 8         # ← dùng s3 vừa lbu ở 0104 → ⚡ LOAD-USE STALL!
0114: slli  s5, s5, 16
0118: or    s3, s3, s5        # pack mid row part 2
011c: or    s3, s3, s6        # ← dùng s6 vừa lbu ở 010c (4 lệnh → OK)
0120: pm4addasu.b a5, t0, s3  # gx += kx_mid × row_mid ← dùng s3 ngay ⚠️ có thể stall?
0124: pm4addasu.b a5, a6, s2  # gx += kx_bot × row_bot ← phụ thuộc a5 → forwarding
0128: pm4addasu.b a4, t6, s4  # gy += ky_top × row_top
012c: pm4addasu.b a4, t5, s2  # gy += ky_bot × row_bot ← phụ thuộc a4 → forwarding

0130: slli  a5, a5, 16        # gx << 16 (isolate lower 16-bit)
0134: slli  a4, a4, 16        # gy << 16
0138: srli  a5, a5, 16        # gx & 0xFFFF
013c: or    a5, a5, a4        # pack gxgy = {gy[15:0], gx[15:0]}
0140: psabs.h a5, a5          # |gx|, |gy| song song
0144: srli  a4, a5, 16        # extract |gy|
0148: padd.h a5, a5, a4       # mag = |gx|+|gy| (low half)
014c: pusati.h a5, a5, 8      # clip [0, 255]
0150: sb    a5, 0(a1)         # store output

0154: addi  a3, a3, 1         # j++
0158: bne   a2, t2, 0x00ac    # loop back
```

**Đếm**: ~44 lệnh/iteration × 3 iterations = **~132 lệnh động** cho inner loop

---

## 4. Phân tích nguyên nhân pext chậm hơn

### 4.1. ⚡ Load-Use Stall — Nguyên nhân chính!

Trong vòng lặp pext, có **2 load-use stall rõ ràng** mỗi iteration:

| Stall | LBU instruction | Dependent instruction | Khoảng cách | Stall cycles |
|---|---|---|---|---|
| **#1** | `lbu s4, 1(s3)` @ 0x00BC | `slli s4, s4, 8` @ 0x00CC | 4 lệnh (nhưng pipeline 5-stage: load có sẵn cuối MEM stage, slli cần ở EX) → **1 stall** | **1** |
| **#2** | `lbu s3, 1(a3)` @ 0x0104 | `slli s3, s3, 8` @ 0x0110 | 3 lệnh (tương tự) → cần kiểm tra thực tế | **1** |

> [!WARNING]
> Từ [hazard_detection.sv](file:///d:/Workspace/04_Projects/01_GitHub/07_rv32im_P_extension/rtl/hazard_detection.sv): Stall xảy ra khi `opcode_EX == OC_I_LOAD && rd_EX == rs1_ID`. Với pipeline 5-stage, **load kết quả có ở cuối MEM** → lệnh **ngay sau load** dùng rd sẽ stall 1 cycle.
> 
> Thực tế kiểm tra kỹ hơn:
> - `lbu s4` @ 0x00BC → 0x00C0 dùng a5 (khác), 0x00C4 dùng a5 (khác), 0x00C8 dùng s3 (khác), **0x00CC dùng s4** → 3 lệnh giữa → **KHÔNG stall** (load kết quả đã qua MEM/WB forwarding)

Hmm, hãy kiểm tra cẩn thận hơn. Trong pipeline 5-stage: IF → ID → EX → MEM → WB.

- LBU ở cycle N: IF(N) → ID(N+1) → EX(N+2) → **MEM(N+3)** [data available end] → WB(N+4)
- Lệnh ngay sau (N+1): IF(N+1) → ID(N+2) → **EX(N+3)** [cần data] → nhưng data chỉ có cuối MEM(N+3) → **STALL 1 cycle**
- Lệnh cách 1 (N+2): IF(N+2) → ID(N+3) → **EX(N+4)** [cần data] → data đã WB(N+4) → **forwarding OK, no stall**

Vậy stall chỉ xảy ra nếu lệnh **NGAY SAU** load dùng rd:

| LBU | Lệnh ngay sau | Dùng cùng rd? | Stall? |
|---|---|---|---|
| `lbu a1, 2(s3)` @ 0xB4 | `add a5, a5, t3` @ 0xB8 | Không | ❌ |
| `lbu s4, 1(s3)` @ 0xBC | `lbu a4, 2(a5)` @ 0xC0 | Không | ❌ |
| `lbu a4, 2(a5)` @ 0xC0 | `lbu s2, 1(a5)` @ 0xC4 | Không | ❌ |
| `lbu s2, 1(a5)` @ 0xC4 | `lbu s5, 0(s3)` @ 0xC8 | Không | ❌ |
| `lbu s5, 0(s3)` @ 0xC8 | **`slli s4, s4, 8`** @ 0xCC | **s4? Không!** s4 load ở 0xBC, cách 3 lệnh → **forwarding OK** | ❌ |
| `lbu s3, 0(a5)` @ 0xD0 | `slli a5, a1, 16` @ 0xD4 | Không (dùng a1) | ❌ |
| `lbu s3, 1(a3)` @ 0x104 | `lbu s5, 2(a3)` @ 0x108 | Không | ❌ |
| `lbu s5, 2(a3)` @ 0x108 | `lbu s6, 0(a3)` @ 0x10C | Không | ❌ |
| `lbu s6, 0(a3)` @ 0x10C | **`slli s3, s3, 8`** @ 0x110 | **s3? s3 load ở 0x104**, cách 2 lệnh → **forwarding từ MEM/WB OK** | ❌ |

> [!NOTE]
> **Correction**: Sau khi kiểm tra kỹ, các load trong pext loop đều được compiler schedule tốt — **không có load-use stall nào** trong pipeline! GCC đã xen kẽ nhiều `lbu` liên tiếp và tách load khỏi consumer đủ xa.

### 4.2. Chênh lệch số lệnh động (Dynamic Instruction Count) — Nguyên nhân thực sự!

So sánh chi tiết hơn giữa 2 phiên bản:

#### Phần khởi tạo (chạy 1 lần):
| | scala | pext | Chênh lệch |
|---|---|---|---|
| `_start` + `clear_bss` | ~12 | ~12 | 0 |
| `main` init loop (5×5 clear) | ~45 | ~45 | 0 |
| `jal main → jal sobel` | ~2 | ~2 | 0 |
| Sobel prologue (save regs) | ~10 | ~15 | **+5** (thêm `lui`/`addi` setup kernel) |

#### Outer loop (i=1..3, 3 iterations):
| | scala | pext | Ghi chú |
|---|---|---|---|
| Outer loop setup | ~5 lệnh/iter | ~7 lệnh/iter | pext setup nhiều hơn |
| **Tải pixel ban đầu** | **10 lệnh `lbu`** (tải window 3×4=12 pixel) | Không (load trong inner loop) | scala preload nhiều pixel |

#### Inner loop (j=1..3, 3 iterations mỗi outer, tổng 9 iterations):

| Phần | scala (lệnh/iter) | pext (lệnh/iter) | Ghi chú |
|---|---|---|---|
| Load pixels | **2 `lbu`** (chỉ load pixel mới, reuse cũ) | **9 `lbu`** | ⚠️ **pext load lại toàn bộ 3×3 window mỗi iteration!** |
| Pack pixels | 0 | **12** (`slli`, `or`) | ⚠️ **Overhead đóng gói dữ liệu** |
| Compute Gx | ~12 (`slli`, `add`, `sub`) | **3** (`pm4addasu.b`) | ✅ pext tốt hơn |
| Compute Gy | ~8 (`slli`, `add`, `sub`) | **2** (`pm4addasu.b`) | ✅ pext tốt hơn |
| ABS | ~6 (`srai`, `xor`, `sub` ×2) | **5** (`slli`, `srli`, `or`, `psabs.h`, `srli`) | Gần bằng (pext cần pack trước) |
| ADD mag | 1 | **1** (`padd.h`) | Bằng nhau |
| CLIP | ~2 (`bge` + `li`) | **1** (`pusati.h`) | ✅ pext tốt hơn |
| Store + loop | ~12 (sb + 8 `mv` window shift + branch) | **3** (`sb` + `addi` + `bne`) | ✅ **pext tốt hơn nhiều!** |
| **Tổng** | **~43** | **~36** | pext ít hơn ~7 lệnh/iter |

> [!IMPORTANT]
> **Nhưng scale KHÔNG load lại toàn bộ window mỗi iteration!** Scala dùng kỹ thuật **sliding window** — shift các register cũ sang (8 lệnh `mv`) và chỉ load 2 pixel mới. Tuy phải dùng 8 lệnh `mv`, nhưng tiết kiệm 7 lệnh `lbu` + không cần pack.

### 4.3. Phân tích tổng cycles chính xác

#### Branch penalty considerations:
- Pipeline giải quyết branch ở EX stage → branch taken = **2 cycle penalty** (flush IF và ID)
- Branch not-taken = **0 penalty** (predict not-taken)

| Branch | scala (taken/not-taken × iterations) | pext |
|---|---|---|
| Inner loop back-jump | `j 0xA8` (unconditional) × 2 taken + 1 `beq` exit | `bne` × 2 taken + 1 not-taken exit |
| Outer loop back-jump | `bne` × 2 taken + 1 not-taken exit | `bne` × 2 taken + 1 not-taken exit |
| Clip branch | `bge` × 9 (tùy data, hầu hết taken) | Không có branch (dùng `pusati.h`) ✅ |
| BSS clear loop | `j` × ~6 taken + 1 `bge` exit | Tương tự |

Ước tính branch penalty (mỗi taken branch = 2 cycles):
- **scala**: ~(2+1) inner ×3 outer + 2 outer + ~6 bss + 2 (jal main + jal sobel) + clip branches ≈ **~22-28 penalty cycles**
- **pext**: ~2 inner ×3 outer + 2 outer + ~6 bss + 2 ≈ **~16-18 penalty cycles**

> pext có ít branch penalty hơn ~6-10 cycles nhờ `pusati.h` thay branch clip

### 4.4. Load-use stall analysis for scala:
- `lbu a0, 0(a4)` @ 0xB4 → lệnh ngay sau: `neg s5, t1` @ 0xB8 (không dùng a0) → OK, **0 stall**
- `lbu a6, 0(a6)` @ 0xD4 → lệnh ngay sau: `slli a4, a7, 1` @ 0xD8 (không dùng a6) → OK, **0 stall**

→ scala: **0 load-use stalls**

### 4.5. Load-use stall analysis for pext:

Kiểm tra lại mỗi `lbu` → lệnh kế tiếp:
- Tất cả `lbu` đều không bị dùng ngay bởi lệnh kế tiếp (GCC schedule tốt)
- → pext: **0 load-use stalls** (hoặc rất ít)

---

## 5. Tổng kết: Tính tổng cycles

### Ước tính sơ bộ:

| Component | scala | pext |
|---|---|---|
| `_start` + BSS clear (~7 words) | ~25 + stalls/branches | ~25 |
| `main` init loop (5 iters) | ~45 + branches | ~45 |
| `jal` to sobel | ~3 | ~3 |
| Sobel prologue | ~10 | ~15 |
| **Outer loop × 3** (setup + pixel preload) | ~15 × 3 = 45 | ~10 × 3 = 30 |
| **Inner loop × 9** | ~43 × 9 = **387** | ~36 × 9 = **324** |
| Sobel epilogue | ~10 | ~10 |
| `main` epilogue + done_flag | ~8 | ~8 |
| **Branch penalties** | ~25 | ~18 |
| **Load-use stalls** | ~0 | ~0 |
| **Pipeline startup** | ~4 | ~4 |
| **Total ước tính** | ~**572** | ~**482** |

> [!WARNING]
> Ước tính trên cho thấy pext **nên nhanh hơn** ~90 cycles, nhưng thực tế đo được pext (606) > scala (598). Điều này cho thấy assumption của tôi ở bước nào đó chưa chính xác.

### Nghi ngờ: Đếm lại inner loop cẩn thận hơn

Khi nhìn kỹ hơn scala inner loop, tôi nhận thấy iteration đầu tiên của mỗi outer loop khác biệt: **10 pixel đã được preload trước vòng lặp** (dòng 0x70-0x98), và **8 lệnh `mv` ở cuối mỗi inner iteration** thực hiện "window sliding". Vì vậy:

**Scala inner iteration thực tế**:
- Code chính: 0x00A8 → 0x0120 = **31 lệnh** tính toán
- Window shift: 0x0124 → 0x0148 = **10 lệnh** (mv + branch check + mv + mv + j)
- Iteration cuối (exit): không chạy `j`, chạy `beq` → exit
- **Tổng: ~41 lệnh × 2 (mid iters) + ~39 (last iter) + ~31 (first iter preloaded)**

**Pext inner iteration thực tế**:
- Code: 0x00AC → 0x0158 = **44 lệnh** (bao gồm tất cả load + pack + compute + store)

Vậy scalar: ~41 lệnh/iter (trung bình), pext: ~44 lệnh/iter → **pext nhiều hơn ~3 lệnh/iter × 9 = 27 lệnh**

Cộng thêm pext prologue nhiều hơn ~5 lệnh (setup kernel constants), tổng chênh lệch ~32 lệnh ≈ ~32 cycles. Nhưng pext tiết kiệm branch penalty... nên chênh lệch thực tế nhỏ hơn.

---

## 6. Kết luận cuối cùng

> [!IMPORTANT]  
> **Tại sao pext (606) nhiều hơn scala (598) = chênh 8 cycles?**

Nguyên nhân **KHÔNG PHẢI** do phép nhân (vì scalar không dùng MUL). Nguyên nhân chính:

### ① Scalar KHÔNG dùng MUL → đã rất nhanh
GCC đã tối ưu `×(-1)`, `×(-2)`, `×(+1)`, `×(+2)` thành `neg`/`slli`/`add`/`sub` — toàn bộ 1-cycle ALU operations. **Đây chính là lý do bạn nghi ngờ, và bạn đúng!**

### ② Pext tốn overhead "pack pixels" 
Mỗi inner iteration phải:
- Load **9 bytes** riêng lẻ (9 lệnh `lbu`)
- Shift + OR đóng gói thành 3 word 32-bit (**12 lệnh** `slli`/`or`)
- → **21 lệnh** chỉ để chuẩn bị data cho 5 lệnh `pm4addasu.b`

### ③ Scalar dùng "sliding window" hiệu quả
Scala chỉ load **2 pixel mới** mỗi iteration (dùng 8 lệnh `mv` để shift window), trong khi pext **load lại toàn bộ 9 pixel** mỗi lần. Tuy `mv` tốn 8 lệnh, nhưng vẫn rẻ hơn 9 `lbu` + 12 shift/or = 21 lệnh.

### ④ Chuỗi P-ext phụ thuộc tuần tự
Từ dòng 0x0100 đến 0x014C, các lệnh P-ext phụ thuộc chặt nhau:
```
pm4addasu.b a5 → pm4addasu.b a5 → pm4addasu.b a5  (chain gx)
pm4addasu.b a4 → pm4addasu.b a4                    (chain gy)  
slli a5 → srli a5 → or a5 → psabs.h a5 → srli → padd.h a5 → pusati.h a5
```
Dù pipeline có forwarding, chuỗi dài này vẫn phải chạy tuần tự, không overlap được.

### ⑤ Pext tiết kiệm branch penalty nhưng không đủ bù
`pusati.h` (branchless clip) tiết kiệm ~9 branch penalty cycles, nhưng tổng overhead pack pixels vẫn lớn hơn.

---

## 7. Cải thiện đề xuất

| Giải pháp | Hiệu quả |
|---|---|
| **Dùng `lw` load 4 bytes cùng lúc** thay vì 4× `lbu` | Giảm 6+ lệnh load mỗi iteration |
| **Reuse packed data** qua iterations (sliding window) | Giảm load+pack từ 21 → ~7 lệnh |
| **Tăng kích thước ảnh** (ví dụ 32×32, 64×64) | Overhead setup bị pha loãng, P-ext sẽ thắng |
| **Biên dịch với `-O2`** | GCC tối ưu schedule tốt hơn |

> [!TIP]
> Với ảnh 5×5 (chỉ 9 pixel output), overhead setup chiếm tỉ lệ quá lớn. P-Extension sẽ phát huy hiệu quả rõ rệt hơn với ảnh lớn hơn (16×16+) khi chi phí cố định bị amortized.

# Tổng kết phân tích
Tôi đã phân tích chi tiết cả 2 file assembly và tạo báo cáo đầy đủ. Đây là tóm tắt ngắn:

Bạn đúng rồi — Scalar KHÔNG dùng phép nhân MUL!
GCC đã tự động tối ưu tất cả phép nhân kernel (×1, ×2, ×(-1), ×(-2)) thành shift + add/sub, đều là 1-cycle ALU operations. Không có lệnh mul nào trong scala.s cả.

3 nguyên nhân chính khiến pext chậm hơn 8 cycles:
#	Nguyên nhân	Chi tiết
1	Pack pixels overhead	Pext phải load 9 byte riêng lẻ (lbu) rồi slli + or đóng gói thành 3 word = ~21 lệnh/iteration chỉ để chuẩn bị data
2	Scalar dùng sliding window	Scala chỉ load 2 pixel mới, reuse pixel cũ bằng 8 lệnh mv (shift window) — rẻ hơn nhiều so với reload toàn bộ
3	Ảnh quá nhỏ (5×5)	Chỉ có 9 pixel output → overhead setup kernel constants bị "chia" cho quá ít iterations, P-ext chưa kịp "bù"
Gợi ý cải thiện:
Tăng kích thước ảnh (16×16+) → P-ext sẽ thắng rõ rệt
Dùng lw thay lbu để load 4 bytes cùng lúc
Implement sliding window trong phiên bản pext
Chi tiết đầy đủ trong báo cáo sobel_cycle_analysis.md.