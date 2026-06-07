import numpy as np
import os

# Cấu hình
N = 32
np.random.seed(42)

# 1. Sinh ma trận ngẫu nhiên int8
mat_A = np.random.randint(-128, 127, (N, N), dtype=np.int8)
mat_B = np.random.randint(-128, 127, (N, N), dtype=np.int8)

# 2. Tính toán Golden Result (int32)
mat_C = np.matmul(mat_A.astype(np.int32), mat_B.astype(np.int32))

print(f"Ma trận A: {mat_A.shape}, B: {mat_B.shape}, C: {mat_C.shape}")
print("Ví dụ kết quả C[0,0]:", mat_C[0,0])
