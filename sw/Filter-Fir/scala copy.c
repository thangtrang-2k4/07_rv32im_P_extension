/*
 * FIR Filter — RV32IM Scalar (Reference)
 *
 * Thuật toán: lọc FIR N-tap, signed int8_t coefficients × signed int8_t samples
 *   - Tính acc = sum(coeff[k] * input[n-k])  k=0..TAPS-1
 *   - Scale: out[n] = (acc + (1<<(SCALE_SHIFT-1))) >> SCALE_SHIFT
 *
 * Tất cả tham số (FIR_TAPS, INPUT_LEN, SCALE_SHIFT) lấy từ fir_data.h
 *
 * Biên dịch:
 *   riscv32-unknown-elf-gcc -O2 -march=rv32im -nostdlib \
 *       -T link.ld start.s scala.c -o scala.elf
 */

#include <stdint.h>
#include "fir_data.h"

/* ──────────────────────────────────────────────────────────────────── */
/*  Cấu hình tự động từ fir_data.h                                     */
/* ──────────────────────────────────────────────────────────────────── */
#define VALID_START   (FIR_TAPS - 1)

/* Linker symbols */
extern volatile uint32_t _done_flag;

/* ──────────────────────────────────────────────────────────────────── */
/*  Output buffer                                                      */
/* ──────────────────────────────────────────────────────────────────── */
volatile int8_t output[INPUT_LEN];

/* ──────────────────────────────────────────────────────────────────── */
/*  Hàm FIR Scalar                                                     */
/*                                                                     */
/*  Với mỗi mẫu n (n = VALID_START .. INPUT_LEN-1):                   */
/*    acc = 0                                                           */
/*    for k = 0..31:  acc += coeff[k] * input[n-k]                    */
/*    output[n] = clip8( (acc + (1 << (SCALE_SHIFT - 1))) >> SCALE_SHIFT ) */
/* ──────────────────────────────────────────────────────────────────── */
static void fir_scalar(void)
{
    for (int n = VALID_START; n < INPUT_LEN; n++) {
        int32_t acc = 0;
        for (int k = 0; k < FIR_TAPS; k++) {
            acc += (int32_t)fir_coeffs[k] * (int32_t)input_data[n - k];
        }
        /* round & scale: chia 2^SCALE_SHIFT với làm tròn gần nhất */
        acc = (acc + (1 << (SCALE_SHIFT - 1))) >> SCALE_SHIFT;
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
    _done_flag = 1;

    return 0;
}
