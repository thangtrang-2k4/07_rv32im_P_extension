import numpy as np
from PIL import Image

# đường dẫn file HEX output Sobel (1 word/hàng)
hex_file = r"D:\01_Projects\2025-12_Graduation_Thesis\02-rv32im-pext\sw\apps\filter-sobel\pext1_final_output_test.hex"

data_bytes = []

with open(hex_file, "r") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        # parse word
        val = int(line, 16)
        # little-endian: byte0 = LSB
        b0 = val & 0xFF
        b1 = (val >> 8) & 0xFF
        b2 = (val >> 16) & 0xFF
        b3 = (val >> 24) & 0xFF
        data_bytes.extend([b0, b1, b2, b3])

# reshape thành ảnh 64x64
img_size = 64
arr = np.array(data_bytes[:img_size*img_size], dtype=np.uint8).reshape((img_size,img_size))

# tạo ảnh và hiển thị
img = Image.fromarray(arr, mode="L")
img.show()

# lưu ảnh
img.save(r"D:\01_Projects\2025-12_Graduation_Thesis\02-rv32im-pext\sw\apps\filter-sobel\photo1_reconstructed.png")
print("Ảnh Sobel 64x64 đã lưu và hiển thị.")