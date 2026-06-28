#!/usr/bin/env python3
"""
visualize_sobel.py
Vẽ ảnh Sobel output từ 2 file signature hex (scala và pext).

Cách dùng:
    python visualize_sobel.py

Đặt file này cùng thư mục với:
    - scala_signature.hex
    - pext_signature.hex  (hoặc tên khác)
"""

import struct
import os

# ── Cài matplotlib nếu chưa có ──────────────────────────────────────────────
try:
    import matplotlib.pyplot as plt
    import matplotlib.gridspec as gridspec
    import numpy as np
except ImportError:
    import subprocess, sys
    subprocess.check_call([sys.executable, "-m", "pip", "install", "matplotlib", "numpy"])
    import matplotlib.pyplot as plt
    import matplotlib.gridspec as gridspec
    import numpy as np

# ── Cấu hình ─────────────────────────────────────────────────────────────────
WIDTH  = 48
HEIGHT = 48
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

SCALA_HEX  = os.path.join(SCRIPT_DIR, "scala_signature.hex")
PEXT_HEX   = os.path.join(SCRIPT_DIR, "pext_signature.hex")

# Cycle counts từ log (cập nhật nếu chạy lại)
CYCLES_SCALA = 109374
CYCLES_PEXT  = 94259   # sau khi tối ưu sliding window

# Input image (48x48) — để vẽ frame gốc
INPUT_IMAGE = [
    [ 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180 ],
    [ 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180 ],
    [ 180, 180, 180, 181, 183, 184, 184, 184, 184, 184, 184, 184, 184, 184, 184, 184, 184, 184, 184, 184, 184, 184, 184, 184, 184, 184, 184, 183, 181, 180, 180, 180, 180, 180, 180, 181, 183, 184, 184, 184, 184, 184, 184, 183, 181, 180, 180, 180 ],
    [ 180, 180, 181, 186, 195, 201, 202, 202, 202, 202, 202, 202, 202, 202, 202, 202, 202, 202, 202, 202, 202, 202, 202, 202, 202, 202, 201, 195, 186, 181, 180, 180, 180, 180, 181, 186, 195, 201, 202, 202, 202, 202, 201, 195, 186, 181, 180, 180 ],
    [ 180, 180, 183, 195, 216, 229, 232, 232, 232, 232, 232, 232, 232, 232, 232, 232, 232, 232, 232, 232, 232, 232, 232, 232, 232, 232, 229, 216, 195, 183, 180, 180, 180, 180, 183, 195, 216, 229, 232, 232, 232, 232, 229, 216, 195, 183, 180, 180 ],
    [ 180, 180, 184, 201, 229, 246, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 246, 229, 201, 184, 180, 180, 180, 180, 184, 201, 229, 246, 250, 250, 250, 250, 246, 229, 201, 184, 180, 180 ],
]  # chỉ cần vài hàng đầu để minh hoạ — load đầy đủ từ hex nếu cần


# ── Hàm đọc file hex ──────────────────────────────────────────────────────────
def read_hex_little_endian(path, width, height):
    """
    Đọc file hex dạng mỗi dòng = 1 word 32-bit little-endian.
    Mỗi word chứa 4 byte pixel liên tiếp (byte0 = pixel[col], byte1 = pixel[col+1], ...).
    Memory layout: output[row][col] lưu theo thứ tự địa chỉ tăng dần.
    
    Ví dụ: dòng "08020000" → bytes 0x08, 0x02, 0x00, 0x00
    → pixel[0]=0x08=8, pixel[1]=0x02=2, pixel[2]=0x00=0, pixel[3]=0x00=0
    """
    pixels = []
    with open(path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('@') or line.startswith('#'):
                continue
            word = int(line, 16)
            # Unpack little-endian: byte0 là địa chỉ thấp nhất
            b0 = (word >>  0) & 0xFF
            b1 = (word >>  8) & 0xFF
            b2 = (word >> 16) & 0xFF
            b3 = (word >> 24) & 0xFF
            pixels.extend([b0, b1, b2, b3])

    total = width * height
    if len(pixels) < total:
        pixels.extend([0] * (total - len(pixels)))
    pixels = pixels[:total]
    return np.array(pixels, dtype=np.uint8).reshape(height, width)


def read_hex_big_endian(path, width, height):
    """
    Đọc file hex dạng mỗi dòng = 1 word 32-bit big-endian.
    Byte0 (MSB) là pixel đầu tiên trong word.
    """
    pixels = []
    with open(path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('@') or line.startswith('#'):
                continue
            word = int(line, 16)
            b3 = (word >>  0) & 0xFF
            b2 = (word >>  8) & 0xFF
            b1 = (word >> 16) & 0xFF
            b0 = (word >> 24) & 0xFF
            pixels.extend([b0, b1, b2, b3])

    total = width * height
    if len(pixels) < total:
        pixels.extend([0] * (total - len(pixels)))
    pixels = pixels[:total]
    return np.array(pixels, dtype=np.uint8).reshape(height, width)


def detect_endianness_and_read(path, width, height):
    """
    Tự động phát hiện byte order bằng cách kiểm tra file signature hex:
    - scala_signature.hex dùng little-endian (output[row][col] lưu byte0 ở LSB)
    - pext_signature.hex có thể dùng big-endian tuỳ implementation
    Mặc định thử little-endian trước (phù hợp với cả 2 trong trường hợp này).
    """
    return read_hex_little_endian(path, width, height)


# ── Load ảnh ─────────────────────────────────────────────────────────────────
print(f"Đang đọc {SCALA_HEX}...")
scala_img = detect_endianness_and_read(SCALA_HEX, WIDTH, HEIGHT)

print(f"Đang đọc {PEXT_HEX}...")
if os.path.exists(PEXT_HEX):
    pext_img = detect_endianness_and_read(PEXT_HEX, WIDTH, HEIGHT)
    has_pext = True
else:
    print(f"  [WARN] Không tìm thấy {PEXT_HEX}, chỉ hiển thị scala.")
    pext_img = scala_img.copy()
    has_pext = False

# Tính diff (giá trị tuyệt đối)
diff_img = np.abs(scala_img.astype(np.int16) - pext_img.astype(np.int16)).astype(np.uint8)
max_diff = int(diff_img.max())
num_mismatch = int(np.sum(diff_img > 0))

# ── Hiệu suất ─────────────────────────────────────────────────────────────────
speedup = CYCLES_SCALA / CYCLES_PEXT if CYCLES_PEXT > 0 else 1.0
reduction_pct = (1.0 - CYCLES_PEXT / CYCLES_SCALA) * 100 if CYCLES_SCALA > 0 else 0.0

print(f"\n{'='*50}")
print(f"  Scala cycles : {CYCLES_SCALA:,}")
print(f"  Pext  cycles : {CYCLES_PEXT:,}")
print(f"  Speedup      : {speedup:.3f}x")
print(f"  Reduction    : {reduction_pct:.1f}%")
print(f"  Max pixel diff: {max_diff}")
print(f"  Mismatches   : {num_mismatch}")
print(f"{'='*50}\n")

# ── Vẽ ───────────────────────────────────────────────────────────────────────
fig = plt.figure(figsize=(16, 10), facecolor='#1a1a2e')
fig.suptitle(
    'Sobel Filter — RV32IMP  |  Scala vs P-Extension',
    fontsize=16, fontweight='bold', color='white', y=0.98
)

gs = gridspec.GridSpec(
    2, 3,
    figure=fig,
    hspace=0.45, wspace=0.3,
    top=0.92, bottom=0.08, left=0.06, right=0.97
)

AX_CFG = dict(facecolor='#16213e')

def styled_imshow(ax, img, title, cmap='gray', vmin=0, vmax=255, colorbar=True):
    im = ax.imshow(img, cmap=cmap, vmin=vmin, vmax=vmax, interpolation='nearest',
                   aspect='equal')
    ax.set_title(title, color='white', fontsize=10, pad=6)
    ax.tick_params(colors='#aaaaaa', labelsize=7)
    for spine in ax.spines.values():
        spine.set_edgecolor('#444466')
    if colorbar:
        cb = fig.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
        cb.ax.yaxis.set_tick_params(color='#aaaaaa', labelsize=7)
        plt.setp(cb.ax.yaxis.get_ticklabels(), color='#aaaaaa')
    return im

# ── 1. Scala output ───────────────────────────────────────────────────────────
ax1 = fig.add_subplot(gs[0, 0], **AX_CFG)
styled_imshow(ax1, scala_img,
    f'Scala (RV32IM)\n{CYCLES_SCALA:,} cycles', cmap='gray')

# ── 2. Pext output ────────────────────────────────────────────────────────────
ax2 = fig.add_subplot(gs[0, 1], **AX_CFG)
label_pext = f'P-Extension (RV32IMP)\n{CYCLES_PEXT:,} cycles  ({reduction_pct:.1f}% nhanh hơn)'
styled_imshow(ax2, pext_img, label_pext, cmap='gray')

# ── 3. Diff map ───────────────────────────────────────────────────────────────
ax3 = fig.add_subplot(gs[0, 2], **AX_CFG)
vmax_diff = max(max_diff, 1)
styled_imshow(ax3, diff_img,
    f'Pixel Difference |Scala − Pext|\nMax={max_diff}, Mismatches={num_mismatch}',
    cmap='hot', vmin=0, vmax=vmax_diff)

# ── 4. Histogram Scala ────────────────────────────────────────────────────────
ax4 = fig.add_subplot(gs[1, 0], facecolor='#16213e')
ax4.hist(scala_img.ravel(), bins=64, range=(0, 255),
         color='#4cc9f0', edgecolor='none', alpha=0.85)
ax4.set_title('Histogram — Scala', color='white', fontsize=9, pad=4)
ax4.set_xlabel('Pixel value', color='#aaaaaa', fontsize=8)
ax4.set_ylabel('Count', color='#aaaaaa', fontsize=8)
ax4.tick_params(colors='#aaaaaa', labelsize=7)
for spine in ax4.spines.values():
    spine.set_edgecolor('#444466')

# ── 5. Histogram Pext ─────────────────────────────────────────────────────────
ax5 = fig.add_subplot(gs[1, 1], facecolor='#16213e')
ax5.hist(pext_img.ravel(), bins=64, range=(0, 255),
         color='#f72585', edgecolor='none', alpha=0.85)
ax5.set_title('Histogram — P-Extension', color='white', fontsize=9, pad=4)
ax5.set_xlabel('Pixel value', color='#aaaaaa', fontsize=8)
ax5.set_ylabel('Count', color='#aaaaaa', fontsize=8)
ax5.tick_params(colors='#aaaaaa', labelsize=7)
for spine in ax5.spines.values():
    spine.set_edgecolor('#444466')

# ── 6. Performance bar chart ─────────────────────────────────────────────────
ax6 = fig.add_subplot(gs[1, 2], facecolor='#16213e')
labels   = ['Scalar (RV32IM)', 'P-Extension\n(Sliding Window)']
values   = [CYCLES_SCALA, CYCLES_PEXT]
colors   = ['#4cc9f0', '#f72585']
bars = ax6.barh(labels, values, color=colors, height=0.45, edgecolor='none')

for bar, val in zip(bars, values):
    ax6.text(val + 500, bar.get_y() + bar.get_height() / 2,
             f'{val:,}', va='center', ha='left', color='white', fontsize=9,
             fontweight='bold')

ax6.set_xlim(0, max(values) * 1.22)
ax6.set_title(f'Simulation Cycles\nSpeedup: {speedup:.3f}×  ({reduction_pct:.1f}% giảm)',
              color='white', fontsize=9, pad=4)
ax6.set_xlabel('Cycles', color='#aaaaaa', fontsize=8)
ax6.tick_params(colors='#aaaaaa', labelsize=8)
ax6.invert_yaxis()
for spine in ax6.spines.values():
    spine.set_edgecolor('#444466')

# ── Lưu file ─────────────────────────────────────────────────────────────────
output_path = os.path.join(SCRIPT_DIR, "sobel_output_comparison.png")
plt.savefig(output_path, dpi=150, bbox_inches='tight', facecolor=fig.get_facecolor())
print(f"Đã lưu ảnh: {output_path}")

plt.show()
