import serial
import time
import sys

def receive_uart_data(com_port, baud_rate=115200, output_file="final_output.hex"):
    print(f"Bắt đầu lắng nghe {com_port} ở tốc độ {baud_rate}...")
    try:
        ser = serial.Serial()
        ser.port = com_port
        ser.baudrate = baud_rate
        ser.timeout = 2
        # Tắt các chân tín hiệu điều khiển phần cứng để tránh làm treo chip CH340
        ser.dtr = False
        ser.rts = False
        ser.open()
    except Exception as e:
        print(f"Lỗi mở cổng COM: {e}")
        return

    print("Vui lòng ấn nút KEY0 trên Board DE2 để chạy mạch!")
    
    with open(output_file, "w") as f:
        count = 0
        while True:
            try:
                line = ser.readline().decode(errors="ignore").strip()
            except Exception as e:
                print(f"Lỗi đọc UART: {e}")
                break
                
            if not line:
                # Timeout
                continue

            if line == "DONE":
                print(f"\n[THÀNH CÔNG] Đã nhận đủ dữ liệu và lưu vào {output_file} ({count} lines)")
                break

            # Kiểm tra xem có đúng định dạng Hex không
            if len(line) <= 8:
                f.write(line + "\n")
                f.flush()
                count += 1
                if count % 100 == 0:
                    print(f"Đã nhận {count} dòng...", end="\r")

    ser.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Cách sử dụng: python uart_receive.py COM3 [tên_file_đầu_ra.hex]")
        sys.exit(1)
        
    port = sys.argv[1]
    out_file = sys.argv[2] if len(sys.argv) > 2 else "final_output.hex"
    
    receive_uart_data(port, 115200, out_file)
