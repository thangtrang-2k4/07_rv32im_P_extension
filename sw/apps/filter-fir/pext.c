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
 */

#include <stdint.h>
#include "fir_data3.h"

/* ──────────────────────────────────────────────────────────────────── */
/*  Cấu hình tự động từ fir_data.h                                     */
/* ──────────────────────────────────────────────────────────────────── */
#define NUM_BLOCKS    (FIR_TAPS / 4)
#define VALID_START   (FIR_TAPS - 1)

/* Linker symbols */
extern volatile uint32_t _done_flag;

/* ──────────────────────────────────────────────────────────────────── */
/*  Output buffer                                                      */
/* ──────────────────────────────────────────────────────────────────── */
volatile int8_t output[INPUT_LEN] __attribute__((section(".output_data")));

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
static inline int32_t load_word_lw(const void *p)
{
    int32_t v;

    asm volatile (
        "lw %0, 0(%1)"
        : "=r"(v)
        : "r"(p)
    );

    return v;
}

/*
 * Scale + clip giống code cũ.
 */
static inline int32_t scale_and_clip(int32_t acc)
{
    acc = (acc + (1 << (SCALE_SHIFT - 1))) >> SCALE_SHIFT;


    return acc;
}

/* ──────────────────────────────────────────────────────────────────── */
/*  Hàm FIR P-Extension                                               */
/*                                                                     */
/*  Prepack hệ số 1 lần trước vòng lặp ngoài. Bên trong:             */
/*    acc = 0                                                           */
/*    for i = 0..7 (mỗi block 4 hệ số):                               */
/*      sample_word = pack4(input[n-4i], input[n-4i-1], ..., [n-4i-3])*/
/*      acc = PM4ADDA.B(acc, sample_word, coeff_blocks[i])             */
/*    output[n] = clip8((acc + ROUND) >> SCALE_SHIFT)                */
/*                                                                     */
/*  Giảm từ 32 MUL + 32 ADD (scalar) xuống còn 8 × PM4ADDA.B         */
/* ──────────────────────────────────────────────────────────────────── */
static __attribute__((noinline)) void fir_pext(void)
{
    /* Prepack 32 hệ số thành 8 word 32-bit — chỉ tính 1 lần          */
    /*                                                                   */
    /* Layout: coeff_blocks[i] = { c[4i], c[4i+1], c[4i+2], c[4i+3] } */
    /*   byte0 (LSB) = c[4i+0], byte1 = c[4i+1], ...                  */
    /* PM4ADDA.B tính:  acc += b0*a0 + b1*a1 + b2*a2 + b3*a3          */
    /* Ta muốn:  acc += c[4i]*in[n-4i] + c[4i+1]*in[n-4i-1] + ...     */
    /* Nên pack sample cũng theo thứ tự: s0=in[n-4i], s1=in[n-4i-1]   */
    int32_t coeff_blocks[NUM_BLOCKS];

    /*
     * Load hệ số h bằng lw trực tiếp.
     *
     * coeff_blocks[i]:
     *   byte0 = h[4i + 0]
     *   byte1 = h[4i + 1]
     *   byte2 = h[4i + 2]
     *   byte3 = h[4i + 3]
     */
    for (int i = 0; i < NUM_BLOCKS; i++) {
        coeff_blocks[i] = load_word_lw(&fir_coeffs[i * 4]);
    }

    /*
     * PHẦN 1: zero-padding cho 31 mẫu đầu.
     *
     * Với n < 31, các mẫu x[n-k] có chỉ số âm được coi là 0.
     * Do đó chỉ cộng tới k <= n.
     */
    for (int n = 0; n < VALID_START; n++) {
        int32_t acc = 0;

        for (int k = 0; k <= n; k++) {
            acc += (int32_t)input_data[n - k] * (int32_t)fir_coeffs[k];
        }

        output[n] = scale_and_clip(acc);
    }

    /*
     * PHẦN 2: vùng đủ mẫu hợp lệ, dùng P-extension.
     */
    for (int n = VALID_START; n < INPUT_LEN; n++) {
        int32_t acc = 0;

        for (int i = 0; i < NUM_BLOCKS; i++) {
            int idx = n - i * 4;
            const int8_t *p = &input_data[idx];

            /*
             * Pack input theo đúng thứ tự FIR:
             *
             * byte0 = x[n - 4i]
             * byte1 = x[n - 4i - 1]
             * byte2 = x[n - 4i - 2]
             * byte3 = x[n - 4i - 3]
             *
             * Không dùng lw cho x ở đây vì thứ tự bộ nhớ bị ngược.
             */
            int32_t sample_block =
                ((int32_t)(uint8_t)p[ 0])        |
                ((int32_t)(uint8_t)p[-1] <<  8) |
                ((int32_t)(uint8_t)p[-2] << 16) |
                ((int32_t)(uint8_t)p[-3] << 24);

            acc = pm4adda_b(acc, sample_block, coeff_blocks[i]);
        }

        output[n] = scale_and_clip(acc);
    }
}

/* ──────────────────────────────────────────────────────────────────── */
int main(void)
{
    fir_pext();

    /* Báo hiệu hoàn tất */
    _done_flag = 1;

    return 0;
}
