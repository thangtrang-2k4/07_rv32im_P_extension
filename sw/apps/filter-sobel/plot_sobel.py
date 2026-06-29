import sys
import matplotlib.pyplot as plt
import re
import numpy as np

def parse_hex_word(hex_str):
    """Convert 8-char hex string to unsigned 32-bit int"""
    return int(hex_str, 16)

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

def read_image_from_h(filename, h=64, w=64):
    img = np.zeros((h, w), dtype=np.uint8)
    with open(filename, 'r') as f:
        content = f.read()
        match = re.search(r'image\[.*?\]\s*=\s*\{([^}]+)\}', content)
        if match:
            arr_str = match.group(1)
            vals = [int(x.strip()) for x in arr_str.split(',') if x.strip()]
            if len(vals) >= h * w:
                img = np.array(vals[:h*w], dtype=np.uint8).reshape((h, w))
    return img

def construct_image_from_words(data_dict, h=64, w=64):
    """Reconstruct 64x64 image from a dict of {address: 32-bit word}"""
    img = np.zeros((h, w), dtype=np.uint8)
    sorted_addrs = sorted(data_dict.keys())
    
    idx = 0
    for addr in sorted_addrs:
        word = data_dict[addr]
        # little endian: byte0, byte1, byte2, byte3
        b0 = word & 0xFF
        b1 = (word >> 8) & 0xFF
        b2 = (word >> 16) & 0xFF
        b3 = (word >> 24) & 0xFF
        
        if idx < h * w:
            img[idx // w, idx % w] = b0
        if idx + 1 < h * w:
            img[(idx+1) // w, (idx+1) % w] = b1
        if idx + 2 < h * w:
            img[(idx+2) // w, (idx+2) % w] = b2
        if idx + 3 < h * w:
            img[(idx+3) // w, (idx+3) % w] = b3
        idx += 4
        
    return img

def main():
    photo_num = "1"
    if len(sys.argv) > 1:
        photo_num = sys.argv[1]
        
    golden_file = f'pext{photo_num}_goldenw.hex'
    final_file = f'pext{photo_num}_final_output.hex'
    header_file = f'sobel_photo{photo_num}.h'
    
    # 1. Read input image
    input_img = read_image_from_h(header_file)
    
    # 2. Read expected and actual outputs
    try:
        golden_data = read_golden(golden_file)
    except FileNotFoundError:
        print(f"Could not find {golden_file}. Did you compile and run the test?")
        return

    sorted_addrs = sorted(golden_data.keys())
    
    try:
        actual_data = read_final_output(final_file, sorted_addrs)
    except FileNotFoundError:
        print(f"Could not find {final_file}. Did you extract memory using Quartus?")
        return
    
    img_expected = construct_image_from_words(golden_data)
    img_actual = construct_image_from_words(actual_data)
    
    # 3. Plot
    fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    
    axes[0].imshow(input_img, cmap='gray', vmin=0, vmax=255)
    axes[0].set_title(f"Original Image (Photo {photo_num})")
    axes[0].axis('off')
    
    axes[1].imshow(img_expected, cmap='gray', vmin=0, vmax=255)
    axes[1].set_title("Expected Sobel Output (Golden)")
    axes[1].axis('off')
    
    axes[2].imshow(img_actual, cmap='gray', vmin=0, vmax=255)
    axes[2].set_title("Actual FPGA Output")
    axes[2].axis('off')
    
    plt.tight_layout()
    plt.savefig(f'sobel_plot_photo{photo_num}.png')
    print(f"Plot saved to sobel_plot_photo{photo_num}.png")
    plt.show()

if __name__ == '__main__':
    main()
