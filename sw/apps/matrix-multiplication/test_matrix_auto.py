import sys
import os

# Thêm đường dẫn tới thư mục sw/apps để import uart_receive
sys.path.append(os.path.abspath(".."))
import uart_receive

def parse_hex_word(hex_str):
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
                try:
                    actual[addr] = parse_hex_word(lines[line_idx])
                except ValueError:
                    actual[addr] = 0
            else:
                actual[addr] = 0
    return actual

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Sử dụng: python test_matrix_auto.py <CỔNG_COM> <mode>")
        print("Trong đó mode là: 'normal' hoặc 'transpose'")
        sys.exit(1)
        
    com_port = sys.argv[1]
    mode = sys.argv[2].lower()
    
    if mode == "normal":
        golden_file = "pextnor_goldenw.hex"
    elif mode == "transpose":
        golden_file = "pexttran_goldenw.hex"
    else:
        print("Lỗi: mode phải là 'normal' hoặc 'transpose'")
        sys.exit(1)
        
    result_path = "final_output_uart.hex"
    
    # 1. Nhận UART
    uart_receive.receive_uart_data(com_port, 115200, result_path)
    
    # 2. Đọc và So sánh
    if not os.path.exists(result_path):
        print("Lỗi: Không tìm thấy file output. Quá trình nhận UART đã thất bại (có thể sai cổng COM hoặc chưa cắm cáp).")
        sys.exit(1)
        
    if not os.path.exists(golden_file):
        print(f"Lỗi: Không tìm thấy file golden {golden_file}")
        sys.exit(1)
        
    print(f"\nĐang nạp file golden: {golden_file}...")
    golden_data = read_golden(golden_file)
    
    # Ở file Verilog dump, do output_data được ánh xạ ngay từ Word 0 (khi dump)
    # Nhưng địa chỉ trong golden file (.hex do objcopy xuất ra) đôi khi có dạng @ offset
    # Ta sẽ phải bù trừ cho đúng nếu cần. 
    # Do objcopy ghi theo địa chỉ byte, ví dụ @2002 thì addr = 0x8008. 
    # uart_receive đọc thẳng từ output_data, tức là word 0 = addr 0.
    # Trong các hàm verify trước, ta đọc đúng offset.
    
    # Ta sẽ so sánh từng địa chỉ có trong golden
    addresses = sorted(golden_data.keys())
    
    # UART dump bắt đầu từ 0x80011060.
    # File golden có thể lưu địa chỉ tuyệt đối hoặc offset.
    # Ở đây chúng ta sẽ kiểm tra xem địa chỉ đầu tiên của golden là bao nhiêu.
    # Nếu golden lưu từ 0 thì tốt.
    
    actual_data = read_final_output(result_path, addresses)
    
    print("\nTiến hành so sánh...")
    errors = 0
    checked = 0
    match_samples = []
    
    for addr in addresses:
        checked += 1
        expected = golden_data[addr]
        actual = actual_data[addr]
        
        if expected != actual:
            errors += 1
            if errors <= 10:
                print(f"❌ Lỗi tại addr 0x{addr:08x}: Expected 0x{expected:08x}, Got 0x{actual:08x}")
        else:
            # Lưu lại toàn bộ các dòng khớp
            match_samples.append(f"Golden: 0x{expected:08x} == UART: 0x{actual:08x}")
                
    if errors == 0:
        print(f"\n✅ THÀNH CÔNG! Đã kiểm tra {checked} words. Dữ liệu phần cứng khớp 100% với Golden.")
        print("Dưới đây là trích xuất dữ liệu thực tế nhận được từ Kit FPGA:")
        for line in match_samples:
            print(line)
    else:
        print(f"\n❌ THẤT BẠI! Lỗi {errors}/{checked} words.")
