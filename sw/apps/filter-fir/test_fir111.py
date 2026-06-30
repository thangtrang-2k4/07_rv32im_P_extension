import numpy as np
from scipy.signal import firwin
import matplotlib.pyplot as plt
import os

# ===== CONFIG =====
fs = 400
N = 400
TAPS = 32

np.random.seed(0)  # để kết quả cố định

# ===== STEP 1: SIGNAL =====
t = np.arange(0, 1, 1 / fs)

# Tín hiệu gốc ban đầu
x_original = np.sin(2 * np.pi * 10 * t)

# Tín hiệu sau khi thêm nhiễu
x = x_original.copy()
x += 0.5 * np.sin(2 * np.pi * 100 * t)  # noise 100Hz
x += 0.2 * np.random.randn(len(t))      # noise trắng

# ===== STEP 2: FIR COEFF =====
h = firwin(TAPS, cutoff=15, fs=fs, window="hamming")

# ===== STEP 2b: IN RA H GỐC =====
print("\nFIR coefficients (float, gốc, nhiều chữ số thập phân):")
for i, val in enumerate(h):
    print(f"{i}\t{val:.18f}")

# ===== STEP 3: QUANTIZE =====
scale = np.max(np.abs(x))

x_norm = x / scale
x_int = np.clip(
    np.round(x_norm * 127),
    -128,
    127
).astype(np.int8)

# Tín hiệu gốc ban đầu đã scale cùng hệ số với x_int
x_original_int = np.clip(
    np.round(x_original / scale * 127),
    -128,
    127
).astype(np.int8)

h_int = np.clip(
    np.round(h * 1024),
    -128,
    127
).astype(np.int8)

# ===== STEP 4: EXPORT HEADER =====
output_path = "D:/01_Projects/2025-12_Graduation_Thesis/02-rv32im-pext/sw/apps/filter-fir/fir_data2.h"

FREEZE_HEADER = True  # True = nếu file đã tồn tại thì không ghi đè nữa

if FREEZE_HEADER and os.path.exists(output_path):
    print(f"⚠️ fir_data2.h đã tồn tại, không ghi đè: {output_path}")
else:
    with open(output_path, "w") as f:
        f.write("#include <stdint.h>\n\n")
        f.write(f"#define N {N}\n")
        f.write(f"#define TAPS {TAPS}\n\n")

        f.write("int8_t x[N] = {\n")
        f.write(",".join(map(str, x_int)))
        f.write("\n};\n\n")

        f.write("int8_t h[TAPS] = {\n")
        f.write(",".join(map(str, h_int)))
        f.write("\n};\n")

    print(f"✅ Generated header at: {output_path}")

# ===== STEP 5: FIR FLOAT (REFERENCE) =====
y_float = np.convolve(x, h, mode="same")

# ===== STEP 6: FIR INT (GIỐNG CODE C) =====
y_int = np.zeros(N, dtype=np.int32)

for n in range(N):
    acc = 0
    for k in range(TAPS):
        acc += int(x_int[n - k]) * int(h_int[k])

    y_int[n] = (acc + (1 << 9)) >> 10

# ===== STEP 8: LOAD RISC-V RESULT =====
def load_hex_file(path, N):
    data = []

    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if not line: continue
            val = int(line, 16)

            # Unpack 4 bytes (little endian)
            for i in range(4):
                b = (val >> (i * 8)) & 0xFF
                # Sign extend 8-bit to integer
                if b & 0x80: b -= 256
                data.append(b)
                
                if len(data) == N:
                    return np.array(data, dtype=np.int32)

    return np.array(data, dtype=np.int32)


# 👉 sửa path đúng với file bạn dump
result_path = "D:/01_Projects/2025-12_Graduation_Thesis/02-rv32im-pext/sw/apps/filter-fir/final_output_test.hex"

y_riscv = load_hex_file(result_path, N)

# ===== STEP 9: CHECK ERROR =====
# ===== STEP 7: PLOT =====
# ===== STEP 7: PLOT =====
fig, axes = plt.subplots(
    3,
    1,
    figsize=(18, 14),
    dpi=120
)

# --- Original scaled signal ---
axes[0].plot(
    t,
    x_original_int,
    color="green",
    marker="o",
    linestyle="-",
    markersize=3,
    label="Tín hiệu gốc 10 Hz"
)
axes[0].set_title("Tín hiệu gốc", pad=10)
axes[0].grid(True)
axes[0].legend(
    loc="upper right",
    fontsize=8,
    markerscale=0.7,
    handlelength=1.5,
    borderpad=0.4,
    labelspacing=0.3
)

# --- Input ---
axes[1].plot(
    t,
    x_int,
    color="blue",
    marker="o",
    linestyle="-",
    markersize=3,
    label="Tín hiệu đầu vào (400 mẫu)"
)
axes[1].set_title("Tín hiệu đầu vào (10Hz + 100Hz nhiễu)", pad=10)
axes[1].grid(True)
axes[1].legend(
    loc="upper right",
    fontsize=8,
    markerscale=0.7,
    handlelength=1.5,
    borderpad=0.4,
    labelspacing=0.3
)

# --- Output ---
axes[2].plot(
    t,
    y_riscv,
    color="red",
    marker="o",
    linestyle="-",
    markersize=3,
    label="Tín hiệu đầu ra"
)
axes[2].set_title("Tín hiệu đầu ra khi qua bộ lọc FIR", pad=10)
axes[2].grid(True)
axes[2].legend(
    loc="upper right",
    fontsize=8,
    markerscale=0.7,
    handlelength=1.5,
    borderpad=0.4,
    labelspacing=0.3
)

plt.tight_layout(
    pad=2.5,
    h_pad=2.2
)

plt.tight_layout(pad=2.5, h_pad=3.0)
plt.subplots_adjust(hspace=0.35)
plt.show()