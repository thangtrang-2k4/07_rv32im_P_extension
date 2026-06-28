/*
 * FIR Filter — RV32IMP P-Extension Optimized
 *
 * Dùng lệnh PM4ADDA.B (smaqa tương đương trong thiết kế này):
 *   PM4ADDA.B rd, rs1, rs2
 *   rd += rs1[0]*rs2[0] + rs1[1]*rs2[1] + rs1[2]*rs2[2] + rs1[3]*rs2[3]
 *   (signed × signed, 4×8-bit MAC trong 1 chu kỳ)
 *
 * Kỹ thuật tối ưu:
 *   1. Prepack hệ số FIR vào 8 word 32-bit (8 blocks × 4 hệ số/block)
 *   2. Với mỗi mẫu n: vòng lặp 8 lần × PM4ADDA.B = 32 phép nhân cộng
 *      (thay vì 32 lần MUL + ADD của phiên bản scalar)
 *   3. Pack 4 mẫu liên tiếp từ bộ nhớ (load 4 bytes unsigned rồi cast)
 *
 * Biên dịch:
 *   riscv32-unknown-elf-gcc -O2 -march=rv32im -nostdlib \
 *       -T link.ld start.s pext.c -o pext.elf
 *
 * Lưu ý: PM4ADDA.B trong thiết kế của bạn là lệnh signed×signed.
 *   input_data là int8_t (signed) — khớp hoàn toàn.
 */

#include <stdint.h>

/* ──────────────────────────────────────────────────────────────────── */
/*  Cấu hình                                                           */
/* ──────────────────────────────────────────────────────────────────── */
#define FIR_TAPS     32
#define INPUT_LEN   200
#define VALID_START  31   /* FIR_TAPS - 1 */
#define NUM_BLOCKS    8   /* FIR_TAPS / 4 */

/* ──────────────────────────────────────────────────────────────────── */
/*  Hệ số FIR (giống scala.c để so sánh công bằng)                    */
/* ──────────────────────────────────────────────────────────────────── */
static const int8_t fir_coeffs[FIR_TAPS] = {
    -2, -2, -3, -3, -3, -1,  2,  8,
    18, 30, 44, 60, 75, 88, 98,103,
   103, 98, 88, 75, 60, 44, 30, 18,
     8,  2, -1, -3, -3, -3, -2, -2
};

/* ──────────────────────────────────────────────────────────────────── */
/*  Dữ liệu vào (giống scala.c)                                       */
/* ──────────────────────────────────────────────────────────────────── */
static const int8_t input_data[INPUT_LEN] = {
     39,  67,  32,   7,  54,  79,  84,  36,  74, 106,
    102,  54,  62, 111,  74,  21,  78,  98,  55,  28,
      7,  46,  23, -22, -19, -24, -34, -53, -14,  11,
    -43, -43, -53,   7, -28, -78,  -4,   9,  19,  -5,
    -12,  51,  59,   6,  43, 107,  48,  52,  59, 127,
     96,  50,  50,  85,  67,  62,  30,  72,  49,   6,
     37,  35,  27, -27, -12,  -4, -25, -66, -35, -30,
    -61, -84, -32,  -2, -32, -73,  -2,  37,  25,   5,
     42,  77,  39,  15,  66,  71,  85,  68,  99, 107,
    105,  58,  72, 105,  96,  61,  71,  44,  43,   3,
     26,  53, -16, -19, -40, -17, -13, -70, -20, -41,
    -63, -53, -66,  -7,  -6, -46,  -6, -14,   8,  -9,
     23,  45,  29,  50,  25,  56,  94,  29,  52,  84,
     96,  79,  46,  91,  43,  22,  37,  78,  28, -16,
     18,   5, -24,  -4, -35,  -9, -17, -39, -14, -37,
    -32, -37, -66,  -1, -10, -58, -32,  21,  -4, -35,
     16,  46,  41,  22,  42,  76,  87,  33,  79,  72,
     92,  43,  48,  82,  51,  64,  44,  57,  28,  30,
     26,  40,  12, -40, -22,   9, -60, -78, -49, -33,
    -34, -73, -17,  -7, -36, -54,  -5,  10,   9, -43
};

/* ──────────────────────────────────────────────────────────────────── */
/*  Output buffer                                                      */
/* ──────────────────────────────────────────────────────────────────── */
volatile int8_t output[INPUT_LEN];


/* ──────────────────────────────────────────────────────────────────── */
/*  PM4ADDA.B wrapper                                                  */
/*                                                                     */
/*  rd += rs1[7:0]*rs2[7:0] + rs1[15:8]*rs2[15:8]                    */
/*       + rs1[23:16]*rs2[23:16] + rs1[31:24]*rs2[31:24]              */
/*  Signed × Signed 4-way 8-bit MAC                                   */
/*                                                                     */
/*  Tên lệnh trong alup.sv: PM4ADDA.B (ALU_PM4ADDA_B)                */
/* ──────────────────────────────────────────────────────────────────── */
static inline int32_t pm4adda_b(int32_t acc, int32_t a, int32_t b)
{
    asm volatile ("pm4adda.b %0, %1, %2"
                  : "+r"(acc)
                  : "r"(a), "r"(b));
    return acc;
}

/* ──────────────────────────────────────────────────────────────────── */
/*  Pack 4 bytes int8_t → int32_t word (little-endian byte packing)  */
/*  byte0 = p[0] (LSB), byte1 = p[1], byte2 = p[2], byte3 = p[3]     */
/*  Dùng __builtin_memcpy để compiler sinh lệnh LW nếu aligned        */
/* ──────────────────────────────────────────────────────────────────── */
static inline int32_t load32_i8(const int8_t *p)
{
    int32_t v;
    __builtin_memcpy(&v, p, 4);
    return v;
}

/* ──────────────────────────────────────────────────────────────────── */
/*  Hàm FIR P-Extension                                               */
/*                                                                     */
/*  Prepack hệ số 1 lần trước vòng lặp ngoài. Bên trong:             */
/*    acc = 0                                                           */
/*    for i = 0..7 (mỗi block 4 hệ số):                               */
/*      sample_word = pack4(input[n-4i], input[n-4i-1], ..., [n-4i-3])*/
/*      acc = PM4ADDA.B(acc, sample_word, coeff_blocks[i])             */
/*    output[n] = clip8((acc + 512) >> 10)                             */
/*                                                                     */
/*  Giảm từ 32 MUL + 32 ADD (scalar) xuống còn 8 × PM4ADDA.B         */
/* ──────────────────────────────────────────────────────────────────── */
static void fir_pext(void)
{
    /* Prepack 32 hệ số thành 8 word 32-bit — chỉ tính 1 lần          */
    /*                                                                   */
    /* Layout: coeff_blocks[i] = { c[4i], c[4i+1], c[4i+2], c[4i+3] } */
    /*   byte0 (LSB) = c[4i+0], byte1 = c[4i+1], ...                  */
    /* PM4ADDA.B tính:  acc += b0*a0 + b1*a1 + b2*a2 + b3*a3          */
    /* Ta muốn:  acc += c[4i]*in[n-4i] + c[4i+1]*in[n-4i-1] + ...     */
    /* Nên pack sample cũng theo thứ tự: s0=in[n-4i], s1=in[n-4i-1]   */
    int32_t coeff_blocks[NUM_BLOCKS];
    for (int i = 0; i < NUM_BLOCKS; i++) {
        const int8_t *c = &fir_coeffs[i * 4];
        /* Cast mỗi int8_t lên uint8_t trước khi pack để tránh sign-ext */
        coeff_blocks[i] =
            ((int32_t)(uint8_t)c[0])        |
            ((int32_t)(uint8_t)c[1] <<  8)  |
            ((int32_t)(uint8_t)c[2] << 16)  |
            ((int32_t)(uint8_t)c[3] << 24);
    }

    /* Vòng lặp xử lý từng mẫu đầu ra hợp lệ */
    for (int n = VALID_START; n < INPUT_LEN; n++) {
        int32_t acc = 0;

        for (int i = 0; i < NUM_BLOCKS; i++) {
            /*
             * Lấy 4 mẫu đầu vào ứng với block i:
             *   input[n - 4i - 0], input[n - 4i - 1],
             *   input[n - 4i - 2], input[n - 4i - 3]
             *
             * Pack: byte0(LSB)=in[n-4i], byte1=in[n-4i-1], ...
             * → pointer bắt đầu tại &input[n - 4i - 3], đọc ngược
             *   hoặc pack thủ công để correct với coeff order.
             *
             * PM4ADDA.B: acc += (a[7:0]*b[7:0]) + (a[15:8]*b[15:8]) + ...
             * Ta cần: c[4i+0]*in[n-4i-0] + c[4i+1]*in[n-4i-1] + ...
             * coeff_blocks[i].byte0 = c[4i+0], .byte1 = c[4i+1], ...
             * sample_block.byte0 = in[n-4i], .byte1 = in[n-4i-1], ...
             */
            int idx = n - i * 4;
            const int8_t *p = &input_data[idx];
            int32_t sample_block =
                ((int32_t)(uint8_t)p[ 0])        |
                ((int32_t)(uint8_t)p[-1] <<  8)  |
                ((int32_t)(uint8_t)p[-2] << 16)  |
                ((int32_t)(uint8_t)p[-3] << 24);

            acc = pm4adda_b(acc, sample_block, coeff_blocks[i]);
        }

        /* Round & scale: chia 2^10 */
        acc = (acc + (1 << 9)) >> 10;

        /* Clip vào [-128, 127] */
        if      (acc >  127) acc =  127;
        else if (acc < -128) acc = -128;
        output[n] = (int8_t)acc;
    }
}

/* ──────────────────────────────────────────────────────────────────── */
int main(void)
{
    fir_pext();

    /* Báo hiệu hoàn tất */
    volatile uint32_t *done_flag = (volatile uint32_t *)0x80011000;
    *done_flag = 1;

    return 0;
}
