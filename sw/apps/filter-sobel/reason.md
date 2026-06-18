Hãy để tôi xem mã máy (disassembly) của cả hai file ELF để so sánh số lượng lệnh thực tế.

Ran command: `riscv32-unknown-elf-objdump -d pext.elf > pext_disasm.txt 2>&1; riscv32-unknown-elf-objdump -d scala.elf > scala_disasm.txt 2>&1`

Toolchain không có trên máy Windows này. Không sao, tôi đã đọc xong cả hai file nguồn rồi - hãy để tôi phân tích trực tiếp từ code và kích thước file hex.

Quan sát kích thước file instruction memory:
- `scala_imem.hex`: **2877 bytes** 
- `pext_imem.hex`: **3201 bytes** ← lớn hơn ~11%

Đây chính là bằng chứng: **chương trình P-Extension có NHIỀU lệnh hơn** chứ không phải ít hơn.

---

## Nguyên nhân gốc rễ: Biên dịch không có cờ tối ưu (`-O0`)

Lệnh biên dịch của bạn là:
```bash
riscv32-unknown-elf-gcc -march=rv32im -nostdlib -T link.ld start.s pext.c -o pext.elf
```

**Không có cờ `-O2` hay `-O3`** → GCC mặc định dùng `-O0` (không tối ưu). Điều này gây ra **2 vấn đề chết người**:

### 1. `static inline` KHÔNG ĐƯỢC inline ở `-O0`

Ở `-O0`, GCC **bỏ qua** từ khóa `inline` và biến mỗi hàm thành một **function call thực sự**. Nghĩa là mỗi lần gọi `pm4addasu_b()`, `psabs_h()`, `padd_h()`, `pack_pixels()` đều phát sinh:

```
# Overhead cho MỖI lần gọi hàm:
addi sp, sp, -16    # mở stack frame
sw   ra, 12(sp)     # lưu return address
sw   a0, 8(sp)      # lưu tham số lên stack
sw   a1, 4(sp)      # lưu tham số lên stack
...                  # load lại từ stack vào register
...                  # thực hiện 1 lệnh P-Extension
...                  # lưu kết quả lên stack
lw   ra, 12(sp)     # load return address
addi sp, sp, 16     # đóng stack frame
ret                  # return
```

**~10 lệnh overhead** chỉ để bọc **1 lệnh** P-Extension! Trong vòng lặp inner, bạn gọi:
- `pack_pixels()` × 3 lần
- `pm4addasu_b()` × 5 lần
- `psabs_h()` × 1 lần
- `padd_h()` × 1 lần  
- `pusati_h()` × 1 lần (macro nên không bị ảnh hưởng)

→ **~10 function calls × ~10 lệnh overhead = ~100 lệnh overhead thừa** mỗi pixel!

### 2. `pack_pixels()` tốn rất nhiều lệnh

Hàm `pack_pixels()` phải:
- Load 3 byte riêng lẻ từ memory
- Shift trái 8 bit, shift trái 16 bit
- OR 3 giá trị lại

→ **~7-9 lệnh** cho mỗi lần gọi × 3 hàng = **~21-27 lệnh** chỉ để đóng gói dữ liệu.

Trong khi phiên bản scalar (`scala.c`) load trực tiếp `input[i][j]` và dùng ngay, **không cần bước đóng gói nào cả**.

### 3. Bước pack `gxgy_packed` cũng tốn thêm lệnh

```c
uint32_t gxgy_packed = ((uint32_t)(uint16_t)gx) | ((uint32_t)(uint16_t)gy << 16);
```
Dòng này sinh thêm nhiều lệnh: mask 16-bit, shift, OR — hoàn toàn không tồn tại ở bản scalar.

---

## So sánh trực quan

| | **Scalar (`scala.c`)** | **P-Extension (`pext.c`)** |
|---|---|---|
| **Tính Gx** | 6 load + 6 phép tính đơn giản | 3× `pack_pixels` (21+ lệnh) + 3× `pm4addasu_b` (3 lệnh) |
| **Tính Gy** | 6 load + 6 phép tính đơn giản | (reuse packed data) + 2× `pm4addasu_b` (2 lệnh) |
| **ABS** | 2 branch + 2 neg | pack gxgy (~5 lệnh) + 1× `psabs_h` |
| **Add** | 1 `add` | 1 shift + 1× `padd_h` |
| **Clip** | 1 branch + 1 `li` | 1× `pusati_h` |
| **Function call overhead** | **0** (tất cả inline) | **~100 lệnh** (ở `-O0`) |

→ Bước "chuẩn bị dữ liệu" (pack_pixels + pack gxgy) **tốn nhiều hơn** số lệnh mà P-Extension tiết kiệm được, đặc biệt khi cộng thêm function call overhead.

---

## Cách khắc phục

Thêm cờ `-O2` khi biên dịch:

```bash
riscv32-unknown-elf-gcc -O2 -march=rv32im -nostdlib -T link.ld start.s pext.c -o pext.elf
riscv32-unknown-elf-gcc -O2 -march=rv32im -nostdlib -T link.ld start.s scala.c -o scala.elf
```

Với `-O2`:
- Tất cả `static inline` sẽ được **inline thực sự** → triệt tiêu ~100 lệnh overhead
- GCC sẽ tối ưu `pack_pixels` tốt hơn (giữ giá trị trong register, không store/load stack liên tục)
- Lúc đó P-Extension mới thể hiện được lợi thế thực sự

**Lưu ý**: Để so sánh **công bằng**, phải biên dịch **CẢ HAI** file với cùng cờ `-O2`.