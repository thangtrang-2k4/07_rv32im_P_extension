import numpy as np
from scipy.signal import firwin
import matplotlib.pyplot as plt
import os

# ===== CONFIG =====
fs = 200
N = 200
TAPS = 32

np.random.seed(0)  # để kết quả cố định

# ===== STEP 1: SIGNAL =====
t = np.arange(0, 1, 1/fs)

x = np.sin(2*np.pi*5*t)                 # signal 5Hz
x += 0.5*np.sin(2*np.pi*50*t)           # noise 50Hz
x += 0.2 * np.random.randn(len(t))      # noise trắng

# ===== STEP 2: FIR COEFF =====
h = firwin(TAPS, cutoff=10, fs=fs, window='hamming')

# ===== STEP 3: QUANTIZE =====
x_norm = x / np.max(np.abs(x))
x_int = np.clip(np.round(x_norm * 127), -128, 127).astype(np.int8)

h_int = np.clip(np.round(h * 1024), -128, 127).astype(np.int8)

# ===== STEP 4: EXPORT HEADER =====
output_path = "C:/Users/ADMIN/Downloads/fir_data1.h"

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
y_float = np.convolve(x, h, mode='same')

# ===== STEP 6: FIR INT (GIỐNG CODE C) =====
y_int = np.zeros(N, dtype=np.int32)

for n in range(N):
    acc = 0
    for k in range(TAPS):
        acc += int(x_int[n-k]) * int(h_int[k])
    y_int[n] = (acc + (1 << 9)) >> 10

# ===== STEP 8: LOAD RISC-V RESULT =====
def load_hex_file(path, N):
    data = []
    with open(path, "r") as f:
        for line in f:
            val = int(line.strip(), 16)

            # convert signed 32-bit
            if val & (1 << 31):
                val -= (1 << 32)

            data.append(val)

    return np.array(data[:N], dtype=np.int32)


# 👉 sửa path đúng với file bạn dump
result_path = "C:/Users/ADMIN/Downloads/result2.hex"

y_riscv = load_hex_file(result_path, N)
# ===== STEP 9: CHECK ERROR =====
max_err = np.max(np.abs(y_int - y_riscv))
print("Max absolute error:", max_err)
# ===== STEP 7: PLOT =====
plt.figure(figsize=(12, 12))

# --- Input ---
plt.subplot(4,1,1)
plt.plot(x, label="Input (float)")
plt.title("Input Signal (5Hz + 50Hz noise)")
plt.grid()
plt.legend()

# --- FIR coeff ---
plt.subplot(4,1,2)
plt.stem(h, linefmt='r-', markerfmt='ro', basefmt='k-')
plt.title("FIR Coefficients (Low-pass)")
plt.grid()

# --- Output compare ---
plt.subplot(4,1,3)
plt.plot(y_float, label="Float FIR (reference)")
plt.plot(y_int, '--', label="Fixed-point FIR (C)")
plt.plot(y_riscv, ':', label="RISC-V FIR")
plt.title("Output Comparison")
plt.grid()
plt.legend()

# --- Error ---
plt.subplot(4,1,4)
plt.plot(y_int - y_riscv, label="Error (C - RISC-V)")
plt.title("Error between C and RISC-V")
plt.grid()
plt.legend()

plt.tight_layout()
plt.show()
# ===== CHECK MATCH =====
if np.array_equal(y_int, y_riscv):
    print("✅ RISC-V matches C exactly!")
else:
    diff = np.where(y_int != y_riscv)[0]
    print(f"❌ Mismatch at {len(diff)} positions")
    print("First 10 mismatches:", diff[:10])