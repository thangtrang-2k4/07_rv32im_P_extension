import numpy as np
import pandas as pd
from scipy import signal
import kagglehub
import os

# --- 1. Load Dataset ---
print("Downloading dataset...")
path = kagglehub.dataset_download("apithm/ecg-and-eeg-stress-features")
ecg_file = [os.path.join(path, f) for f in os.listdir(path) if 'ECG' in f and f.endswith('.xlsx')][0]
df = pd.read_excel(ecg_file, sheet_name='AC1')

max_samples = 1024
raw_input = df['Mean HR (bpm)'].values[:max_samples]
input_centered = raw_input - np.mean(raw_input)
input_int8 = np.clip(input_centered, -128, 127).astype(np.int8)

# --- 2. Reference Models ---
TAPS = 32
SCALE = 128
SCALE_SHIFT = 7

h_float = signal.firwin(TAPS, cutoff=10, fs=100, window='hamming')
h_q7 = np.round(h_float * SCALE).astype(np.int32)

raw_mac = np.convolve(input_int8, h_q7, mode='full')[:len(input_int8)]
integer_ref = np.clip((raw_mac + 64) >> 7, -128, 127).astype(np.int8)
integer_ref[:TAPS-1] = 0

# --- 3. Export Files ---
def save_as_hex_word(data_array, filename):
    flat_data = data_array.flatten().astype(np.uint8)
    padding = (4 - len(flat_data) % 4) % 4
    if padding > 0: flat_data = np.pad(flat_data, (0, padding), mode='constant')
    with open(filename, 'w') as f:
        for i in range(0, len(flat_data), 4):
            p = [int(x) for x in flat_data[i:i+4]]
            word = (p[3] << 24) | (p[2] << 16) | (p[1] << 8) | p[0]
            f.write(f"{word:08x}\n")

def save_c_header(input_arr, h_arr, scale_shift, filename):
    with open(filename, 'w') as f:
        f.write("#ifndef __FIR_DATA_H\n#define __FIR_DATA_H\n\n")
        f.write("#include <stdint.h>\n\n")
        f.write(f"#define FIR_TAPS {len(h_arr)}\n")
        f.write(f"#define INPUT_LEN {len(input_arr)}\n")
        f.write(f"#define SCALE_SHIFT {scale_shift}\n\n")
        f.write("static const int8_t fir_coeffs[FIR_TAPS] = { " + ", ".join(map(str, h_arr)) + " };\n")
        f.write("static const int8_t input_data[INPUT_LEN] = { " + ", ".join(map(str, input_arr)) + " };\n")
        f.write("\n#endif\n")

# Chạy từ thư mục py-ref-model/Fir
os.chdir('d:/Workspace/04_Projects/01_GitHub/07_rv32im_P_extension/py-ref-model/Fir')
save_as_hex_word(input_int8, 'input.hex')
save_as_hex_word(integer_ref, 'golden.hex')
save_c_header(input_int8, h_q7, SCALE_SHIFT, 'fir_data.h')
# Copy sang thư mục sw
with open('d:/Workspace/04_Projects/01_GitHub/07_rv32im_P_extension/sw/Filter-Fir/fir_data.h', 'w') as f_out:
    with open('fir_data.h', 'r') as f_in:
        f_out.write(f_in.read())

print(f"Successfully generated 1024 samples!")
