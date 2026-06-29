import sys
import matplotlib.pyplot as plt
import re
import numpy as np

def parse_hex_word(hex_str):
    """Convert 8-char hex string to signed 32-bit int"""
    val = int(hex_str, 16)
    if val & 0x80000000:
        val -= 0x100000000
    return val

def read_golden(filename):
    golden = {}
    addr = 0
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            if line.startswith('@'):
                addr = int(line[1:], 16) * 4
            else:
                for word in line.split():
                    golden[addr] = parse_hex_word(word)
                    addr += 4
    return golden

def read_final_output(filename, addresses):
    actual = {}
    with open(filename, 'r') as f:
        lines = [l.strip() for l in f.readlines()]
        for addr in addresses:
            line_idx = addr // 4
            if line_idx < len(lines):
                actual[addr] = parse_hex_word(lines[line_idx])
            else:
                actual[addr] = 0
    return actual

def construct_matrix_from_words(data_dict, h=32, w=32):
    """Reconstruct 32x32 int32 matrix from a dict of {address: 32-bit word}"""
    mat = np.zeros((h, w), dtype=np.int32)
    sorted_addrs = sorted(data_dict.keys())
    
    idx = 0
    for addr in sorted_addrs:
        word = data_dict[addr]
        if idx < h * w:
            mat[idx // w, idx % w] = word
        idx += 1
        
    return mat

def read_input_matrix_from_h(filename, mat_name, h=32, w=32):
    mat = np.zeros((h, w), dtype=np.int8)
    with open(filename, 'r') as f:
        content = f.read()
        match = re.search(f'{mat_name}\[.*?\]\s*=\s*{{([^}}]+)}}', content)
        if match:
            arr_str = match.group(1)
            vals = [int(x.strip()) for x in arr_str.split(',') if x.strip()]
            if len(vals) >= h * w:
                mat = np.array(vals[:h*w], dtype=np.int8).reshape((h, w))
    return mat

def main():
    mode = "nor"
    if len(sys.argv) > 1:
        mode = sys.argv[1] # "nor" or "tran"
        
    golden_file = f'pext{mode}_goldenw.hex'
    final_file = f'pext{mode}_final_output.hex'
    header_file = 'matrix_data.h'
    
    # 1. Read input matrices
    mat_A = read_input_matrix_from_h(header_file, "mat_A")
    mat_B = read_input_matrix_from_h(header_file, "mat_B")
    
    # 2. Read expected and actual outputs
    try:
        golden_data = read_golden(golden_file)
    except FileNotFoundError:
        print(f"Could not find {golden_file}.")
        return

    sorted_addrs = sorted(golden_data.keys())
    
    try:
        actual_data = read_final_output(final_file, sorted_addrs)
    except FileNotFoundError:
        print(f"Could not find {final_file}.")
        return
    
    mat_expected = construct_matrix_from_words(golden_data)
    mat_actual = construct_matrix_from_words(actual_data)
    
    # 3. Plot
    fig, axes = plt.subplots(2, 2, figsize=(10, 10))
    
    # Top left: Mat A
    im0 = axes[0, 0].imshow(mat_A, cmap='viridis')
    axes[0, 0].set_title("Input Matrix A (32x32)")
    plt.colorbar(im0, ax=axes[0, 0])
    
    # Top right: Mat B
    im1 = axes[0, 1].imshow(mat_B, cmap='viridis')
    axes[0, 1].set_title("Input Matrix B (32x32)")
    plt.colorbar(im1, ax=axes[0, 1])
    
    # Bottom left: Expected Output
    im2 = axes[1, 0].imshow(mat_expected, cmap='plasma')
    axes[1, 0].set_title("Expected Output C")
    plt.colorbar(im2, ax=axes[1, 0])
    
    # Bottom right: Actual Output
    im3 = axes[1, 1].imshow(mat_actual, cmap='plasma')
    axes[1, 1].set_title("Actual FPGA Output C")
    plt.colorbar(im3, ax=axes[1, 1])
    
    plt.tight_layout()
    plt.savefig(f'matrix_plot_{mode}.png')
    print(f"Plot saved to matrix_plot_{mode}.png")
    
    # Print mismatch stats
    mismatches = np.sum(mat_expected != mat_actual)
    if mismatches == 0:
        print("SUCCESS: 100% Match!")
    else:
        print(f"FAILED: {mismatches} mismatches found!")
    
    plt.show()

if __name__ == '__main__':
    main()
