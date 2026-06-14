# Phân Tích: P-Extension Instructions cho Sobel Filter

## 1. Tổng quan thuật toán Sobel hiện tại (RV32IM)

Sobel filter trong [scala.c](file:///d:/Workspace/04_Projects/01_GitHub/07_rv32im_P_extension/sw/Filter-Sobel/scala.c) thực hiện các bước sau cho mỗi pixel:

| Bước | Mô tả | Kiểu dữ liệu |
|------|--------|---------------|
| **WIDEN** | Đọc 6 pixel 8-bit xung quanh, mở rộng lên `int` (32-bit) | `uint8_t` → `int32_t` |
| **Multiply-Accumulate** | Nhân pixel với hệ số kernel (-1, -2, 0, +1, +2) rồi cộng dồn → `gx`, `gy` | `int32_t` |
| **ABS** | Lấy giá trị tuyệt đối: `gx = abs(gx)`, `gy = abs(gy)` | `int32_t` |
| **ADD** | `mag = gx + gy` | `int32_t` |
| **CLIP** | Giới hạn `mag` trong [0, 255] | `int32_t` → `uint8_t` |
| **NARROW** | Ghi kết quả 8-bit ra output | `uint8_t` |

---

## 2. Danh sách P-Ext Instructions được hỗ trợ trong [alup.sv](file:///d:/Workspace/04_Projects/01_GitHub/07_rv32im_P_extension/rtl/alup.sv)

### Nhóm SIMD 8-bit (Byte)
| Instruction | ALUSel | Mô tả |
|------------|--------|--------|
| `PADD.B` | `ALU_PADD_B` | SIMD 4×8-bit cộng |
| `PAADD.B` | `ALU_PAADD_B` | SIMD 4×8-bit cộng trung bình (signed) |
| `PAADDU.B` | `ALU_PAADDU_B` | SIMD 4×8-bit cộng trung bình (unsigned) |
| `PSADDU.B` | `ALU_PSADDU_B` | SIMD 4×8-bit cộng bão hòa (unsigned) |
| `PSUB.B` | `ALU_PSUB_B` | SIMD 4×8-bit trừ |
| `PASUB.B` | `ALU_PASUB_B` | SIMD 4×8-bit trừ trung bình (signed) |
| `PASUBU.B` | `ALU_PASUBU_B` | SIMD 4×8-bit trừ trung bình (unsigned) |
| `PSSUB.B` | `ALU_PSSUB_B` | SIMD 4×8-bit trừ bão hòa (signed) |
| `PSSUBU.B` | `ALU_PSSUBU_B` | SIMD 4×8-bit trừ bão hòa (unsigned) |

### Nhóm SIMD 16-bit (Halfword)
| Instruction | ALUSel | Mô tả |
|------------|--------|--------|
| `PADD.H` | `ALU_PADD_H` | SIMD 2×16-bit cộng |
| `PAADD.H` | `ALU_PAADD_H` | SIMD 2×16-bit cộng trung bình (signed) |
| `PAADDU.H` | `ALU_PAADDU_H` | SIMD 2×16-bit cộng trung bình (unsigned) |
| `PSADD.H` | `ALU_PSADD_H` | SIMD 2×16-bit cộng bão hòa (signed) |
| `PSADDU.H` | `ALU_PSADDU_H` | SIMD 2×16-bit cộng bão hòa (unsigned) |
| `PSUB.H` | `ALU_PSUB_H` | SIMD 2×16-bit trừ |
| `PASUB.H` | `ALU_PASUB_H` | SIMD 2×16-bit trừ trung bình (signed) |
| `PASUBU.H` | `ALU_PASUBU_H` | SIMD 2×16-bit trừ trung bình (unsigned) |
| `PSSUB.H` | `ALU_PSSUB_H` | SIMD 2×16-bit trừ bão hòa (signed) |
| `PSSUBU.H` | `ALU_PSSUBU_H` | SIMD 2×16-bit trừ bão hòa (unsigned) |

### Nhóm Cross HX (Add-Sub / Sub-Add)
| Instruction | ALUSel | Mô tả |
|------------|--------|--------|
| `PAS.HX` | `ALU_PAS_HX` | Cross: lo = sub, hi = add |
| `PAAS.HX` | `ALU_PAAS_HX` | Cross averaging (signed) |
| `PSAS.HX` | `ALU_PSAS_HX` | Cross saturating (signed) |
| `PSA.HX` | `ALU_PSA_HX` | Cross: lo = add, hi = sub |
| `PASA.HX` | `ALU_PASA_HX` | Cross averaging (signed) |
| `PSSA.HX` | `ALU_PSSA_HX` | Cross saturating (signed) |

### Nhóm So sánh 16-bit
| Instruction | ALUSel | Mô tả |
|------------|--------|--------|
| `PMSEQ.H` | `ALU_PMSEQ_H` | 2×16-bit so sánh bằng |
| `PMSLT.H` | `ALU_PMSLT_H` | 2×16-bit so sánh nhỏ hơn (signed) |
| `PMSLTU.H` | `ALU_PMSLTU_H` | 2×16-bit so sánh nhỏ hơn (unsigned) |
| `PMIN.H` | `ALU_PMIN_H` | 2×16-bit min (signed) |
| `PMINU.H` | `ALU_PMINU_H` | 2×16-bit min (unsigned) |
| `PMAX.H` | `ALU_PMAX_H` | 2×16-bit max (signed) |
| `PMAXU.H` | `ALU_PMAXU_H` | 2×16-bit max (unsigned) |

### Nhóm Đặc biệt
| Instruction | ALUSel | Mô tả |
|------------|--------|--------|
| `PSABS.H` | `ALU_PSABS_H` | 2×16-bit absolute value (saturating) |
| `PSATI.H` | `ALU_PSATI_H` | 2×16-bit signed clip (immediate) |
| `PUSATI.H` | `ALU_PUSATI_H` | 2×16-bit unsigned clip (immediate) |
| **`PM4ADDA.B`** | `ALU_PM4ADDA_B` | **4×8-bit MAC: rd += Σ(A[i] × B[i]), signed** |
| **`PM4ADDASU.B`** | `ALU_PM4ADDASU_B` | **4×8-bit MAC: rd += Σ(A[i]s × B[i]u)** |
| **`PM4ADDAU.B`** | `ALU_PM4ADDAU_B` | **4×8-bit MAC: rd += Σ(A[i]u × B[i]u), unsigned** |

---

## 3. Mapping: Sobel Operations → P-Extension Instructions

> [!IMPORTANT]
> **Ý tưởng chính**: Pack 4 pixel 8-bit vào 1 thanh ghi 32-bit, rồi dùng SIMD để xử lý song song.

### Bước 1: Pack Pixels — Dùng thao tác bộ nhớ + shift thông thường

Sobel kernel cần 3 hàng × 3 cột = 9 pixel. Với mỗi pixel cần xử lý, ta load 3 pixel liên tiếp từ mỗi hàng:
```
row_top    = [p(i-1,j-1), p(i-1,j), p(i-1,j+1), 0]  // Pack vào 1 word
row_mid    = [p(i,j-1),   p(i,j),   p(i,j+1),   0]
row_bot    = [p(i+1,j-1), p(i+1,j), p(i+1,j+1), 0]
```

### Bước 2: Tính Gx & Gy — ⭐ `PM4ADDA.B` (Multiply-Accumulate 4×8-bit)

Đây là lệnh **quan trọng nhất** cho Sobel filter. `PM4ADDA.B` thực hiện:
```
rd = rd + (A[0]*B[0] + A[1]*B[1] + A[2]*B[2] + A[3]*B[3])
```

Sobel kernel Gx và Gy:
```
Gx = [-1  0  +1]     Gy = [-1 -2 -1]
     [-2  0  +2]          [ 0  0  0]
     [-1  0  +1]          [+1 +2 +1]
```

**Cách dùng:**

```c
// Gx kernel coefficients (mỗi byte là 1 hệ số signed)
uint32_t kx_top = pack_bytes(-1,  0, +1, 0);  // 0xFF_00_01_00
uint32_t kx_mid = pack_bytes(-2,  0, +2, 0);  // 0xFE_00_02_00  
uint32_t kx_bot = pack_bytes(-1,  0, +1, 0);  // 0xFF_00_01_00

// Gy kernel coefficients
uint32_t ky_top = pack_bytes(-1, -2, -1, 0);  // 0xFF_FE_FF_00
uint32_t ky_bot = pack_bytes(+1, +2, +1, 0);  // 0x01_02_01_00

// Tính Gx bằng PM4ADDA.B (signed × unsigned)
int32_t gx = 0;
gx = PM4ADDASU_B(gx, kx_top, row_top);  // gx += Σ(kx_top[i] × row_top[i])
gx = PM4ADDASU_B(gx, kx_mid, row_mid);  // gx += Σ(kx_mid[i] × row_mid[i])
gx = PM4ADDASU_B(gx, kx_bot, row_bot);  // gx += Σ(kx_bot[i] × row_bot[i])

// Tính Gy bằng PM4ADDASU.B
int32_t gy = 0;
gy = PM4ADDASU_B(gy, ky_top, row_top);
gy = PM4ADDASU_B(gy, ky_bot, row_bot);  // ky_mid = 0, bỏ qua
```

> [!TIP]
> **`PM4ADDASU.B`** (signed × unsigned) là phù hợp nhất vì kernel coefficients là **signed** (-2,-1,0,+1,+2) trong khi pixel là **unsigned** (0~255). Lệnh này thay thế **12 phép nhân + 12 phép cộng** chỉ bằng **5 lệnh P-ext**!

### Bước 3: Tính ABS — ⭐ `PSABS.H` (SIMD Absolute Value 16-bit)

Sau khi tính xong `gx` và `gy` (cả hai đều là int16 vì kernel 3×3 pixel 8-bit cho ra giá trị max ±1020), ta có thể **pack cả hai vào 1 thanh ghi 16×2**:

```c
// Pack gx (16-bit) và gy (16-bit) vào 1 word 32-bit
uint32_t gxgy = ((uint16_t)gx) | ((uint16_t)gy << 16);

// Lấy ABS của cả 2 cùng lúc bằng 1 lệnh!
uint32_t abs_gxgy = PSABS_H(gxgy);
// abs_gxgy[15:0]  = |gx|
// abs_gxgy[31:16] = |gy|
```

> [!NOTE]
> `PSABS.H` thay thế 2 lệnh `if (gx < 0) gx = -gx; if (gy < 0) gy = -gy;` (mỗi cái cần branch + negate = ~4 instructions) chỉ bằng **1 lệnh duy nhất**.

### Bước 4: Cộng |gx| + |gy| — `PADD.H` hoặc ADD thông thường

```c
// Tách |gx| và |gy| ra
uint16_t abs_gx = abs_gxgy & 0xFFFF;
uint16_t abs_gy = abs_gxgy >> 16;
int mag = abs_gx + abs_gy;  // ADD thông thường (RV32IM)
```

### Bước 5: Clip [0, 255] — ⭐ `PUSATI.H` (Unsigned Saturate Immediate)

```c
// Clip mag vào [0, 2^8 - 1] = [0, 255]
// PUSATI.H với imm = 8: clip(val, 0, 255)
uint32_t clipped = PUSATI_H(mag, 8);
output[i][j] = (uint8_t)clipped;
```

> [!NOTE]
> `PUSATI.H` thay cho `if (mag > 255) mag = 255;` — không cần branch!

---

## 4. Tóm tắt: Lệnh P-Ext nên sử dụng cho Sobel

| Bước Sobel | Lệnh RV32IM gốc | Lệnh P-Ext thay thế | Lý do |
|-----------|-----------------|---------------------|-------|
| Multiply-Accumulate Gx | 6 MUL + 5 ADD | **`PM4ADDASU.B`** × 3 lệnh | Kernel signed × pixel unsigned, MAC trong 1 cycle |
| Multiply-Accumulate Gy | 6 MUL + 5 ADD | **`PM4ADDASU.B`** × 2 lệnh | Hàng giữa ky = 0, chỉ cần 2 lệnh |
| ABS(gx), ABS(gy) | 2 branches + 2 negates | **`PSABS.H`** × 1 lệnh | SIMD abs cả 2 giá trị 16-bit |
| Clip [0,255] | 1 branch + 1 move | **`PUSATI.H`** × 1 lệnh | Unsigned clip, branchless |

### Tiềm năng bổ sung (nếu xử lý nhiều pixel cùng lúc)
| Lệnh | Ứng dụng |
|-------|---------|
| `PSUB.B` / `PSUB.H` | Trừ SIMD giữa 2 hàng pixel để tính gradient |
| `PADD.B` / `PADD.H` | Cộng SIMD kết quả partial |
| `PSADDU.B` | Cộng bão hòa unsigned (giới hạn tự động 255) |
| `PMINU.H` | Min unsigned — có thể dùng clip thay thế |

---

## 5. Ước lượng hiệu suất

| Metric | RV32IM | RV32IMP (P-Ext) | Cải thiện |
|--------|--------|-----------------|-----------|
| Lệnh cho Gx kernel | ~12 (MUL+ADD) | **3** (PM4ADDASU.B) | **4×** |
| Lệnh cho Gy kernel | ~10 (MUL+ADD) | **2** (PM4ADDASU.B) | **5×** |
| Lệnh cho ABS | ~8 (branch+negate) | **1** (PSABS.H) | **8×** |
| Lệnh cho Clip | ~3 (branch+move) | **1** (PUSATI.H) | **3×** |
| **Tổng inner loop** | **~33+** | **~7** | **~4-5×** |

> [!IMPORTANT]
> **4 lệnh P-Extension chính cần dùng:**
> 1. **`PM4ADDASU.B`** — MAC kernel (trọng tâm)
> 2. **`PSABS.H`** — Absolute value
> 3. **`PUSATI.H`** — Unsigned clip
> 4. **`PADD.H`** hoặc ADD — Cộng |gx|+|gy|
