import numpy as np
from scipy.signal import firwin
import matplotlib.pyplot as plt
import os
import sys

# Thêm đường dẫn tới thư mục sw/apps để import uart_receive
sys.path.append(os.path.abspath(".."))
import uart_receive

# ===== CONFIG =====
fs = 400
N = 400
TAPS = 32

np.random.seed(0)

# ===== STEP 1: SIGNAL =====
t = np.arange(0, 1, 1 / fs)
x_original = np.sin(2 * np.pi * 10 * t)
x = x_original.copy()
x += 0.5 * np.sin(2 * np.pi * 100 * t)  
x += 0.2 * np.random.randn(len(t))      

# ===== STEP 2: FIR COEFF =====
h = firwin(TAPS, cutoff=15, fs=fs, window="hamming")

# ===== STEP 3: QUANTIZE =====
scale = np.max(np.abs(x))
x_norm = x / scale
x_int = np.clip(np.round(x_norm * 127), -128, 127).astype(np.int8)
x_original_int = np.clip(np.round(x_original / scale * 127), -128, 127).astype(np.int8)
h_int = np.clip(np.round(h * 1024), -128, 127).astype(np.int8)

# ===== MAIN PROCESS =====
if __name__ == "__main__":
    com_port = "COM3" if len(sys.argv) < 2 else sys.argv[1]
    result_path = "final_output_uart.hex"
    
    # 1. Nhận UART
    uart_receive.receive_uart_data(com_port, 115200, result_path)
    
    # 2. Đọc file Hex vừa nhận
    def load_hex_file(path, N):
        data = []
        with open(path, "r") as f:
            for line in f:
                line = line.strip()
                if not line: continue
                try:
                    val = int(line, 16)
                except ValueError:
                    continue
                # Unpack 4 bytes (little endian)
                for i in range(4):
                    b = (val >> (i * 8)) & 0xFF
                    # Sign extend 8-bit to integer
                    if b & 0x80: b -= 256
                    data.append(b)
                    if len(data) == N:
                        return np.array(data, dtype=np.int32)
        return np.array(data, dtype=np.int32)

    # Không cần bỏ qua skip_words nữa vì sram_dump_uart trỏ thẳng vào .output_data 0x80011060
    y_riscv = load_hex_file(result_path, N)

    # 3. Vẽ đồ thị
    fig, axes = plt.subplots(3, 1, figsize=(10, 8), dpi=100)

    axes[0].plot(t, x_original_int, color="green", marker="o", linestyle="-", markersize=3, label="Tín hiệu gốc 10 Hz")
    axes[0].set_title("Tín hiệu gốc", pad=10)
    axes[0].grid(True)
    axes[0].legend(loc="upper right", fontsize=8)

    axes[1].plot(t, x_int, color="blue", marker="o", linestyle="-", markersize=3, label="Tín hiệu đầu vào (400 mẫu)")
    axes[1].set_title("Tín hiệu đầu vào (10Hz + 100Hz nhiễu)", pad=10)
    axes[1].grid(True)
    axes[1].legend(loc="upper right", fontsize=8)

    axes[2].plot(t, y_riscv, color="red", marker="o", linestyle="-", markersize=3, label="Tín hiệu đầu ra")
    axes[2].set_title("Tín hiệu đầu ra khi qua bộ lọc FIR", pad=10)
    axes[2].grid(True)
    axes[2].legend(loc="upper right", fontsize=8)

    plt.tight_layout(pad=2.5, h_pad=3.0)
    plt.show()
