import numpy as np
import cv2
import matplotlib.pyplot as plt

# =========================
# CONFIG
# =========================
H = 48
W = 48

gold_path = "C:/Users/ADMIN/Downloads/gold.hex"
test_path = "C:/Users/ADMIN/Downloads/sobel.hex"


# =========================
# READ HEX (pack 4 pixel)
# =========================
def read_hex(path):
    data = []
    with open(path) as f:
        for line in f:
            val = int(line.strip(), 16)

            # unpack 4 pixel (little endian)
            p0 = val & 0xFF
            p1 = (val >> 8) & 0xFF
            p2 = (val >> 16) & 0xFF
            p3 = (val >> 24) & 0xFF

            data.extend([p0, p1, p2, p3])

    return np.array(data[:H*W], dtype=np.uint8).reshape(H, W)


gold = read_hex(gold_path)
test = read_hex(test_path)

# =========================
# COMPARE
# =========================
diff = np.abs(gold.astype(int) - test.astype(int))

num_err = np.sum(diff != 0)
print(f"❌ Số pixel sai: {num_err}")

# =========================
# SAVE IMAGE
# =========================
cv2.imwrite("gold.png", gold)
cv2.imwrite("test.png", test)
cv2.imwrite("diff.png", diff.astype(np.uint8))

# =========================
# SHOW
# =========================
plt.figure(figsize=(10,4))

plt.subplot(1,3,1)
plt.title("GOLD")
plt.imshow(gold, cmap='gray')
plt.axis('off')

plt.subplot(1,3,2)
plt.title("TEST")
plt.imshow(test, cmap='gray')
plt.axis('off')

plt.subplot(1,3,3)
plt.title("DIFF")
plt.imshow(diff, cmap='hot')
plt.axis('off')

plt.show()