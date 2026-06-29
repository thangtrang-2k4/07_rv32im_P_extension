import sys
import matplotlib.pyplot as plt
import re
import struct

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

def read_input_from_h(filename):
    inputs = []
    with open(filename, 'r') as f:
        content = f.read()
        # Find the input_data array
        match = re.search(r'input_data\[.*?\]\s*=\s*\{([^}]+)\}', content)
        if match:
            arr_str = match.group(1)
            # Extract numbers
            inputs = [int(x.strip()) for x in arr_str.split(',') if x.strip()]
    return inputs

def main():
    golden_file = 'pext_goldenw.hex'
    final_file = 'final_output.hex'
    header_file = 'fir_data2.h'
    
    # 1. Read input data
    input_signal = read_input_from_h(header_file)
    if not input_signal:
        print("Could not parse input_data from", header_file)
        return
        
    # 2. Read expected and actual outputs
    golden_data = read_golden(golden_file)
    
    if not golden_data:
        print("Could not read golden data from", golden_file)
        return
        
    sorted_addrs = sorted(golden_data.keys())
    actual_data = read_final_output(final_file, sorted_addrs)
    
    output_expected = []
    output_actual = []
    
    for a in sorted_addrs:
        word_exp = golden_data[a]
        word_act = actual_data[a]
        
        # Unpack 4 bytes (little-endian)
        for i in range(4):
            b_exp = (word_exp >> (i * 8)) & 0xFF
            b_act = (word_act >> (i * 8)) & 0xFF
            
            # Sign extend 8-bit to integer
            if b_exp & 0x80: b_exp -= 256
            if b_act & 0x80: b_act -= 256
            
            output_expected.append(b_exp)
            output_actual.append(b_act)
            
    # FIR filter size is 400, truncate to actual length
    num_samples = len(input_signal)
    output_expected = output_expected[:num_samples]
    output_actual = output_actual[:num_samples]
    
    # 3. Plot
    plt.figure(figsize=(12, 6))
    
    plt.subplot(2, 1, 1)
    plt.title("FIR Filter - Input Signal")
    plt.plot(input_signal, label='Input (Noisy)', color='gray')
    plt.legend()
    plt.grid(True)
    
    plt.subplot(2, 1, 2)
    plt.title("FIR Filter - Output Signal")
    plt.plot(output_expected, label='Expected (Golden)', color='blue', linestyle='--', linewidth=2)
    plt.plot(output_actual, label='Actual (FPGA)', color='red', alpha=0.7)
    plt.legend()
    plt.grid(True)
    
    plt.tight_layout()
    plt.savefig('fir_plot.png')
    print("Plot saved to fir_plot.png")
    plt.show()

if __name__ == '__main__':
    main()
