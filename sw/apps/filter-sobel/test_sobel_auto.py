import numpy as np
from PIL import Image
import sys
import os

# Thêm đường dẫn tới thư mục sw/apps để import uart_receive
sys.path.append(os.path.abspath(".."))
import uart_receive

# ===== MAIN PROCESS =====
if __name__ == "__main__":
    com_port = "COM3" if len(sys.argv) < 2 else sys.argv[1]
    result_path = "final_output_uart.hex"
    
    # 1. Nhận UART
    uart_receive.receive_uart_data(com_port, 115200, result_path)
    
    # 2. Đọc file Hex vừa nhận và Parse
    data_bytes = []
    if not os.path.exists(result_path):
        print("Lỗi: Không tìm thấy file output. Quá trình nhận UART đã thất bại (có thể sai cổng COM hoặc chưa cắm cáp).")
        sys.exit(1)
        
    with open(result_path, "r") as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try:
                val = int(line, 16)
            except ValueError:
                continue
            # little-endian: byte0 = LSB
            b0 = val & 0xFF
            b1 = (val >> 8) & 0xFF
            b2 = (val >> 16) & 0xFF
            b3 = (val >> 24) & 0xFF
            data_bytes.extend([b0, b1, b2, b3])

    # 3. Reshape và Vẽ ảnh
    img_size = 64
    if len(data_bytes) < img_size * img_size:
        print(f"Lỗi: Không nhận đủ dữ liệu ({len(data_bytes)}/{img_size*img_size} bytes)")
    else:
        arr = np.array(data_bytes[:img_size*img_size], dtype=np.uint8).reshape((img_size, img_size))
        
        img = Image.fromarray(arr, mode="L")
        img.show()
        
        save_path = "photo1_reconstructed.png"
        img.save(save_path)
        print(f"Ảnh Sobel 64x64 đã lưu tại {save_path} và hiển thị thành công.")
