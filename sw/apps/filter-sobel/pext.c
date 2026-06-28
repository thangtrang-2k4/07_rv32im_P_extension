/*
 * Sobel Filter — RV32IMP (P-Extension Optimized)
 *
 * Sử dụng các lệnh P-Extension:
 *   1. PM4ADDASU.B  — Signed×Unsigned 4×8-bit MAC (kernel × pixel)
 *   2. PSABS.H      — SIMD 2×16-bit Absolute Value (|gx|, |gy|)
 *   3. PADD.H       — SIMD 2×16-bit Addition (|gx| + |gy|)
 *   4. PUSATI.H     — SIMD 2×16-bit Unsigned Saturate (clip [0, 255])
 *
 * Kỹ thuật tối ưu: Sliding Window (theo refcodes/sobel.c)
 *   - Seed 3 window words (mỗi word = 4 pixel packed) ở đầu mỗi outer row
 *   - Slide phải 1 byte mỗi inner iteration: W = (W>>8) | (new_byte<<24)
 *   - Chỉ load 1 byte mới/iter/row thay vì 9 lbu + 12 shift/or
 */

#include <stdint.h>
#include "sobel_data.h"

/* ──────────────────────────────────────────────────────────────────── */
/*  Cấu hình tự động từ sobel_data.h                                   */
/* ──────────────────────────────────────────────────────────────────── */
#define WIDTH  IMG_WIDTH
#define HEIGHT IMG_HEIGHT

/* Linker symbols */
extern volatile uint32_t _done_flag;

// ===== OUTPUT: 8-bit =====
volatile uint8_t output[HEIGHT][WIDTH];
volatile uint32_t _done_flag;

// ===========================================================
// Inline Assembly Wrappers cho P-Extension Instructions
// ===========================================================

// PM4ADDASU.B: rd = rd + sum(rs1[i]_signed x rs2[i]_unsigned), i=0..3
static inline int32_t pm4addasu_b(int32_t acc, uint32_t rs1, uint32_t rs2) {
    int32_t rd = acc;
    asm volatile ("pm4addasu.b %0, %1, %2"
        : "+r"(rd)
        : "r"(rs1), "r"(rs2));
    return rd;
}

// PSABS.H: |rs1[15:0]| va |rs1[31:16]| song song
static inline uint32_t psabs_h(uint32_t rs1) {
    uint32_t rd;
    asm volatile ("psabs.h %0, %1"
        : "=r"(rd)
        : "r"(rs1));
    return rd;
}

// PADD.H: rs1[15:0]+rs2[15:0] va rs1[31:16]+rs2[31:16] song song
static inline uint32_t padd_h(uint32_t rs1, uint32_t rs2) {
    uint32_t rd;
    asm volatile ("padd.h %0, %1, %2"
        : "=r"(rd)
        : "r"(rs1), "r"(rs2));
    return rd;
}

// PUSATI.H: unsigned clip [0, 2^imm-1] cho 2x16-bit
#define pusati_h(rs1, imm) ({           \
    uint32_t _rd;                       \
    asm volatile ("pusati.h %0, %1, %2" \
        : "=r"(_rd)                     \
        : "r"(rs1), "i"(imm));          \
    _rd;                                \
})

// ===========================================================
// load32u: load 4 byte lien tiep tu dia chi bat ky
// GCC se phat sinh 1 lenh LW neu aligned (aligned=4), rat nhanh.
// ===========================================================
static inline uint32_t load32u(const void *p) {
    uint32_t v;
    __builtin_memcpy(&v, p, 4);
    return v;
}

// ===========================================================
// Sobel Filter — P-Extension voi Sliding Window
//
// Ky thuat (theo refcodes/sobel.c):
//   Seed: load 4 byte dau hang vao W (1 lenh LW)
//   Slide: W = (W >> 8) | (pixel_moi << 24) — chi load 1 byte moi
//   Thay the 9 LBU + 12 shift/OR bang 3 LBU + 3 shift/OR moi iter
// ===========================================================
void sobel_pext() {
    // Kernel Gx row top/bot: [-1, 0, +1, 0]
    const uint32_t kx     = 0x000100FF;
    // Kernel Gx row mid:     [-2, 0, +2, 0]
    const uint32_t kx_mid = 0x000200FE;
    // Kernel Gy row top:     [-1, -2, -1, 0]
    const uint32_t ky_top = 0x00FFFEFF;
    // Kernel Gy row bot:     [+1, +2, +1, 0]
    const uint32_t ky_bot = 0x00010201;

    for (int i = 1; i < HEIGHT - 1; i++) {
        const uint8_t *r0 = &input[i-1][0];
        const uint8_t *r1 = &input[i  ][0];
        const uint8_t *r2 = &input[i+1][0];
        volatile uint8_t *d = &output[i][0];

        // Seed sliding window tai x=0:
        // W[byte0]=pixel[0], W[byte1]=pixel[1], W[byte2]=pixel[2], W[byte3]=pixel[3]
        // Tai j=1: kernel dung pixel[0..2] = W[byte0..byte2] -> dung luon
        uint32_t W0 = load32u(r0);
        uint32_t W1 = load32u(r1);
        uint32_t W2 = load32u(r2);

        for (int j = 1; j < WIDTH - 1; j++) {
            // W chua [pixel[j-1], pixel[j], pixel[j+1], pixel[j+2]]
            // PM4ADDASU.B tinh: kernel[0]*W[0] + kernel[1]*W[1] + kernel[2]*W[2] + 0*W[3]
            int32_t gx = 0;
            gx = pm4addasu_b(gx, kx,     W0);
            gx = pm4addasu_b(gx, kx_mid, W1);
            gx = pm4addasu_b(gx, kx,     W2);

            int32_t gy = 0;
            gy = pm4addasu_b(gy, ky_top, W0);
            gy = pm4addasu_b(gy, ky_bot, W2);

            // Pack gx (low 16-bit) va gy (high 16-bit) vao 1 word
            uint32_t gxgy = ((uint32_t)(uint16_t)gx) | ((uint32_t)(uint16_t)gy << 16);

            // |gx| va |gy| song song
            uint32_t abs_gxgy = psabs_h(gxgy);

            // mag = |gx| + |gy|
            uint32_t shifted    = abs_gxgy >> 16;
            uint32_t mag_packed = padd_h(abs_gxgy, shifted);

            // Clip [0, 255]
            uint32_t clipped = pusati_h(mag_packed, 8);
            d[j] = (uint8_t)(clipped & 0xFF);

            // Slide window phai 1 byte, load byte moi vao MSB
            W0 = (W0 >> 8) | ((uint32_t)r0[j+3] << 24);
            W1 = (W1 >> 8) | ((uint32_t)r1[j+3] << 24);
            W2 = (W2 >> 8) | ((uint32_t)r2[j+3] << 24);
        }
    }
}

int main() {

    // INIT: Clear output
    for (int i = 0; i < HEIGHT; i++) {
        for (int j = 0; j < WIDTH; j++) {
            output[i][j] = 0;
        }
    }

    // Run Sobel filter voi P-Extension (Sliding Window)
    sobel_pext();

    _done_flag = 1;

    return 0;
}
