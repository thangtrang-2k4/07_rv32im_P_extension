/*
 * FIR Filter — RV32IM Scalar (Reference)
 *
 * Thuật toán: lọc FIR 32-tap, signed 8-bit coefficients × signed 8-bit samples
 *   - Tính acc = sum(coeff[k] * input[n-k])  k=0..31
 *   - Scale: out[n] = (acc + 512) >> 10  (hệ số được nhân sẵn 2^10)
 *
 * Dữ liệu vào: 200 mẫu signed 8-bit (int8_t)
 * Dữ liệu ra:  169 mẫu hợp lệ (index 31..199), signed 32-bit → clip int8_t
 *
 * Biên dịch:
 *   riscv32-unknown-elf-gcc -O2 -march=rv32im -nostdlib \
 *       -T link.ld start.s scala.c -o scala.elf
 */

#include <stdint.h>

/* ──────────────────────────────────────────────────────────────────── */
/*  Cấu hình                                                           */
/* ──────────────────────────────────────────────────────────────────── */
#define FIR_TAPS     32   /* Số hệ số FIR — phải là bội số 4          */
#define INPUT_LEN   200   /* Số mẫu đầu vào                           */
#define VALID_START  31   /* first_valid = FIR_TAPS - 1               */
#define VALID_LEN   169   /* INPUT_LEN - FIR_TAPS + 1                 */

/* ──────────────────────────────────────────────────────────────────── */
/*  Hệ số FIR (low-pass, signed 8-bit, scale x1024)                   */
/*  Tham khảo refcodes/fir.c                                           */
/* ──────────────────────────────────────────────────────────────────── */
static const int8_t fir_coeffs[FIR_TAPS] = {
    -2, -2, -3, -3, -3, -1,  2,  8,
    18, 30, 44, 60, 75, 88, 98,103,
   103, 98, 88, 75, 60, 44, 30, 18,
     8,  2, -1, -3, -3, -3, -2, -2
};

/* ──────────────────────────────────────────────────────────────────── */
/*  Dữ liệu vào (hand-written test vector từ refcodes/fir.c)           */
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
/*  Output buffer (đặt trong .bss — DMEM)                              */
/*  Chỉ index [VALID_START .. INPUT_LEN-1] có giá trị hợp lệ          */
/* ──────────────────────────────────────────────────────────────────── */
volatile int8_t output[INPUT_LEN];

/* ──────────────────────────────────────────────────────────────────── */
/*  Hàm FIR Scalar                                                     */
/*                                                                     */
/*  Với mỗi mẫu n (n = VALID_START .. INPUT_LEN-1):                   */
/*    acc = 0                                                           */
/*    for k = 0..31:  acc += coeff[k] * input[n-k]                    */
/*    output[n] = clip8( (acc + 512) >> 10 )                           */
/* ──────────────────────────────────────────────────────────────────── */
static void fir_scalar(void)
{
    for (int n = VALID_START; n < INPUT_LEN; n++) {
        int32_t acc = 0;
        for (int k = 0; k < FIR_TAPS; k++) {
            acc += (int32_t)fir_coeffs[k] * (int32_t)input_data[n - k];
        }
        /* round & scale: chia 2^10 với làm tròn gần nhất */
        acc = (acc + (1 << 9)) >> 10;
        /* clip vào [-128, 127] */
        if      (acc >  127) acc =  127;
        else if (acc < -128) acc = -128;
        output[n] = (int8_t)acc;
    }
}

/* ──────────────────────────────────────────────────────────────────── */
int main(void)
{
    /* Chạy bộ lọc */
    fir_scalar();

    /* Báo hiệu hoàn tất: ghi 1 vào địa chỉ 0x80011000 */
    volatile uint32_t *done_flag = (volatile uint32_t *)0x80011000;
    *done_flag = 1;

    return 0;
}
