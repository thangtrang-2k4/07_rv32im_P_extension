# Filter-FIR — So sánh Scalar vs P-Extension

## Tổng quan

| File | Mô tả |
|---|---|
| `scala.c` | FIR filter thuần RV32IM (`mul` + `add`) |
| `pext.c` | FIR filter dùng P-Extension `pm4adda.b` (4-way signed MAC) |
| `start.s` | Startup code (khởi tạo stack, clear BSS) |
| `link.ld` | Linker script (IMEM=0x80000000, DMEM=0x80010000) |

## Thuật toán FIR

- **32-tap** low-pass filter, hệ số int8_t (scaled ×1024)
- **200 mẫu** đầu vào int8_t
- **169 mẫu** output hợp lệ (index 31..199)
- Scale: `out[n] = clip8((acc + 512) >> 10)`

## Lệnh P-Extension dùng

```
pm4adda.b rd, rs1, rs2
  rd += rs1[7:0]*rs2[7:0] + rs1[15:8]*rs2[15:8]
      + rs1[23:16]*rs2[23:16] + rs1[31:24]*rs2[31:24]
  (Signed × Signed 4-way 8-bit MAC)
```

### Tối ưu so với Scalar

| | Scalar | P-Extension |
|---|---|---|
| Lệnh nhân/output | 32 × `mul` | 8 × `pm4adda.b` |
| Lệnh cộng/output | 32 × `add` | 0 (tích hợp trong pm4adda.b) |
| Lý thuyết speedup | 1× | ~4× trong inner loop |

## Cách biên dịch

```bash
# Biên dịch cả hai
make all

# Chỉ scalar
make scala

# Chỉ pext
make pext
```

Nếu không dùng make (Windows CMD/PowerShell):

```powershell
# Scalar
riscv32-unknown-elf-gcc -O2 -nostdlib -march=rv32im -mabi=ilp32 `
    -T link.ld start.s scala.c -o scala.elf
riscv32-unknown-elf-objcopy -O verilog --only-section=.text --only-section=.rodata `
    scala.elf scala_imem.hex
riscv32-unknown-elf-objcopy -O verilog --only-section=.data --only-section=.bss `
    scala.elf scala_dmem.hex

# P-Extension
riscv32-unknown-elf-gcc -O2 -nostdlib -march=rv32im -mabi=ilp32 `
    -T link.ld start.s pext.c -o pext.elf
riscv32-unknown-elf-objcopy -O verilog --only-section=.text --only-section=.rodata `
    pext.elf pext_imem.hex
riscv32-unknown-elf-objcopy -O verilog --only-section=.data --only-section=.bss `
    pext.elf pext_dmem.hex
```

## Cách chạy simulation (QuestaSim)

Cập nhật `tb/tb_rv32imp_pipeline.sv` để trỏ đến Filter-Fir:

```systemverilog
load_imem("../sw/Filter-Fir/scala_imem.hex");  // hoặc pext_imem.hex
load_dmem("../sw/Filter-Fir/scala_dmem.hex");  // hoặc pext_dmem.hex
```

## Địa chỉ bộ nhớ

| Vùng | Địa chỉ |
|---|---|
| IMEM (code) | `0x80000000` |
| DMEM (data) | `0x80010000` |
| `input_data[]` | `0x80010000` (`.data` section) |
| `output[]` | tiếp theo `input_data` trong `.bss` |
| `done_flag` | `0x80011000` |
