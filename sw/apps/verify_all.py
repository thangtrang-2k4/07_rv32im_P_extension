import sys
import os

CONFIGS = {
    'fir': {
        'dir': 'filter-fir',
        'golden': 'pext_goldenw.hex',
        'actual': 'final_output.hex'
    },
    'sobel1': {
        'dir': 'filter-sobel',
        'golden': 'pext1_goldenw.hex',
        'actual': 'pext1_final_output.hex'
    },
    'sobel2': {
        'dir': 'filter-sobel',
        'golden': 'pext2_goldenw.hex',
        'actual': 'pext2_final_output.hex'
    },
    'matrix_nor': {
        'dir': 'matrix-multiplication',
        'golden': 'pextnor_goldenw.hex',
        'actual': 'pextnor_final_output.hex'
    },
    'matrix_tran': {
        'dir': 'matrix-multiplication',
        'golden': 'pexttran_goldenw.hex',
        'actual': 'pexttran_final_output.hex'
    }
}

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

def print_help():
    print("Sử dụng: python verify_all.py <app_name>")
    print("Các app hỗ trợ:")
    for key in CONFIGS.keys():
        print(f"  - {key}")

def main():
    if len(sys.argv) < 2:
        print_help()
        return
        
    app = sys.argv[1]
    if app not in CONFIGS:
        print(f"Lỗi: Không tìm thấy ứng dụng '{app}'")
        print_help()
        return
        
    cfg = CONFIGS[app]
    
    # Resolve paths relative to this script's location
    base_dir = os.path.dirname(os.path.abspath(__file__))
    app_dir = os.path.join(base_dir, cfg['dir'])
    
    golden_path = os.path.join(app_dir, cfg['golden'])
    actual_path = os.path.join(app_dir, cfg['actual'])
    
    print(f"=== ĐANG KIỂM TRA: {app.upper()} ===")
    print(f"Thư mục: {cfg['dir']}")
    
    if not os.path.exists(golden_path):
        print(f"[LỖI] Không tìm thấy file Golden: {golden_path}")
        return
        
    if not os.path.exists(actual_path):
        print(f"[LỖI] Không tìm thấy file FPGA Output: {actual_path}")
        return
        
    # Read data
    golden_data = read_golden(golden_path)
    addresses = sorted(golden_data.keys())
    actual_data = read_final_output(actual_path, addresses)
    
    # Compare
    mismatches = []
    for addr in addresses:
        val_exp = golden_data[addr]
        val_act = actual_data[addr]
        if val_exp != val_act:
            mismatches.append((addr, val_exp, val_act))
            
    # Report
    if len(mismatches) == 0:
        print(f"\n[THÀNH CÔNG] 100% Khớp dữ liệu! Đã kiểm tra {len(addresses)} words ({(len(addresses)*4)} bytes).")
    else:
        print(f"\n[THẤT BẠI] Phát hiện {len(mismatches)} lỗi sai trên tổng số {len(addresses)} words!")
        print("Chi tiết 20 lỗi đầu tiên:")
        print("-" * 50)
        print(f"{'Address':^12} | {'Expected (Golden)':^16} | {'Actual (FPGA)':^16}")
        print("-" * 50)
        for addr, val_exp, val_act in mismatches[:20]:
            print(f" 0x{addr:08X}  |     0x{val_exp:08X}     |     0x{val_act:08X}    ")
        print("-" * 50)
        if len(mismatches) > 20:
            print(f"... và {len(mismatches) - 20} lỗi khác bị ẩn.")

if __name__ == '__main__':
    main()
