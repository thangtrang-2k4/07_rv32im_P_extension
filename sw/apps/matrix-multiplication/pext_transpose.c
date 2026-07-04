#include <stdint.h>
#include "matrix_data.h"

// Destination buffers in BSS
static int8_t  mat_Bt[W_B * W_A] __attribute__((aligned(4)));
static int32_t output_C[H_A * W_B] __attribute__((section(".output_data"), aligned(4)));

// Done flag for testbench (linker symbol)
extern volatile uint32_t _done_flag;

// P-extension wrapper
static inline int32_t pm4adda_b(int32_t acc, uint32_t rs1, uint32_t rs2)
{
    // pm4adda.b rd, rs1, rs2
    // rd += rs1[7:0]*rs2[7:0] + rs1[15:8]*rs2[15:8] + rs1[23:16]*rs2[23:16] + rs1[31:24]*rs2[31:24]
    asm volatile ("pm4adda.b %0, %1, %2" : "+r"(acc) : "r"(rs1), "r"(rs2));
    return acc;
}

static void transpose_B(const int8_t *Bsrc, int8_t *Bt_, int wA, int wB)
{
    for (int c = 0; c < wA; ++c)
        for (int r = 0; r < wB; ++r)
            Bt_[r * wA + c] = Bsrc[c * wB + r];
}

static void matmul_pext(const int8_t *A_, const int8_t *Bt_, int32_t *C, int hA, int wA, int wB)
{
    const uint32_t * __restrict__ A  = (const uint32_t *)A_;
    const uint32_t * __restrict__ Bt = (const uint32_t *)Bt_;
    const int wA4 = wA >> 2; // columns per row, in packed 32-bit words

    for (int i = 0; i < hA; i += 4)
        for (int j = 0; j < wB; j += 4) {

            int32_t acc00 = 0, acc01 = 0, acc02 = 0, acc03 = 0;
            int32_t acc10 = 0, acc11 = 0, acc12 = 0, acc13 = 0;
            int32_t acc20 = 0, acc21 = 0, acc22 = 0, acc23 = 0;
            int32_t acc30 = 0, acc31 = 0, acc32 = 0, acc33 = 0;

            for (int kb = 0; kb < wA4; ++kb) {
                uint32_t A0 = A[(i+0)*wA4 + kb];
                uint32_t A1 = A[(i+1)*wA4 + kb];
                uint32_t A2 = A[(i+2)*wA4 + kb];
                uint32_t A3 = A[(i+3)*wA4 + kb];

                uint32_t B0 = Bt[(j+0)*wA4 + kb];
                uint32_t B1 = Bt[(j+1)*wA4 + kb];
                uint32_t B2 = Bt[(j+2)*wA4 + kb];
                uint32_t B3 = Bt[(j+3)*wA4 + kb];

                acc00 = pm4adda_b(acc00, A0, B0);
                acc01 = pm4adda_b(acc01, A0, B1);
                acc02 = pm4adda_b(acc02, A0, B2);
                acc03 = pm4adda_b(acc03, A0, B3);

                acc10 = pm4adda_b(acc10, A1, B0);
                acc11 = pm4adda_b(acc11, A1, B1);
                acc12 = pm4adda_b(acc12, A1, B2);
                acc13 = pm4adda_b(acc13, A1, B3);

                acc20 = pm4adda_b(acc20, A2, B0);
                acc21 = pm4adda_b(acc21, A2, B1);
                acc22 = pm4adda_b(acc22, A2, B2);
                acc23 = pm4adda_b(acc23, A2, B3);

                acc30 = pm4adda_b(acc30, A3, B0);
                acc31 = pm4adda_b(acc31, A3, B1);
                acc32 = pm4adda_b(acc32, A3, B2);
                acc33 = pm4adda_b(acc33, A3, B3);
            }

            C[(i+0)*wB + j + 0] = acc00;
            C[(i+0)*wB + j + 1] = acc01;
            C[(i+0)*wB + j + 2] = acc02;
            C[(i+0)*wB + j + 3] = acc03;

            C[(i+1)*wB + j + 0] = acc10;
            C[(i+1)*wB + j + 1] = acc11;
            C[(i+1)*wB + j + 2] = acc12;
            C[(i+1)*wB + j + 3] = acc13;

            C[(i+2)*wB + j + 0] = acc20;
            C[(i+2)*wB + j + 1] = acc21;
            C[(i+2)*wB + j + 2] = acc22;
            C[(i+2)*wB + j + 3] = acc23;

            C[(i+3)*wB + j + 0] = acc30;
            C[(i+3)*wB + j + 1] = acc31;
            C[(i+3)*wB + j + 2] = acc32;
            C[(i+3)*wB + j + 3] = acc33;
        }
}

int main() {
    transpose_B(mat_B, mat_Bt, W_A, W_B);
    matmul_pext(mat_A, mat_Bt, output_C, H_A, W_A, W_B);
    
    _done_flag = 1;
    while(1);
    return 0;
}
