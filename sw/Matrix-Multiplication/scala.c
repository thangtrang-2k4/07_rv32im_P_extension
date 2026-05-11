#include <stdint.h>
#include "matrix_data.h"

// Destination buffer in BSS
static int32_t output_C[H_A * W_B] __attribute__((aligned(4)));

// Done flag for testbench (located at end of DMEM)
// Address: 0x80010000 + 64K - 4 = 0x8001FFFC
volatile uint32_t * const DONE_FLAG = (uint32_t *)0x8001FFFC;

void matmul_scalar(const int8_t * __restrict__ A_,
                    const int8_t * __restrict__ B_,
                    int32_t      * __restrict__ C_,
                    int hA, int wA, int wB)
{
    for (int i = 0; i < hA; i += 4)
        for (int j = 0; j < wB; j += 4) {

            int32_t acc00 = 0, acc01 = 0, acc02 = 0, acc03 = 0;
            int32_t acc10 = 0, acc11 = 0, acc12 = 0, acc13 = 0;
            int32_t acc20 = 0, acc21 = 0, acc22 = 0, acc23 = 0;
            int32_t acc30 = 0, acc31 = 0, acc32 = 0, acc33 = 0;

            for (int k = 0; k < wA; ++k) {
                int32_t A0 = (int32_t)A_[(i + 0) * wA + k];
                int32_t A1 = (int32_t)A_[(i + 1) * wA + k];
                int32_t A2 = (int32_t)A_[(i + 2) * wA + k];
                int32_t A3 = (int32_t)A_[(i + 3) * wA + k];

                int32_t B0 = (int32_t)B_[k * wB + j + 0];
                int32_t B1 = (int32_t)B_[k * wB + j + 1];
                int32_t B2 = (int32_t)B_[k * wB + j + 2];
                int32_t B3 = (int32_t)B_[k * wB + j + 3];

                acc00 += A0 * B0;  acc01 += A0 * B1;
                acc02 += A0 * B2;  acc03 += A0 * B3;

                acc10 += A1 * B0;  acc11 += A1 * B1;
                acc12 += A1 * B2;  acc13 += A1 * B3;

                acc20 += A2 * B0;  acc21 += A2 * B1;
                acc22 += A2 * B2;  acc23 += A2 * B3;

                acc30 += A3 * B0;  acc31 += A3 * B1;
                acc32 += A3 * B2;  acc33 += A3 * B3;
            }

            C_[(i+0)*wB + j + 0] = acc00;
            C_[(i+0)*wB + j + 1] = acc01;
            C_[(i+0)*wB + j + 2] = acc02;
            C_[(i+0)*wB + j + 3] = acc03;

            C_[(i+1)*wB + j + 0] = acc10;
            C_[(i+1)*wB + j + 1] = acc11;
            C_[(i+1)*wB + j + 2] = acc12;
            C_[(i+1)*wB + j + 3] = acc13;

            C_[(i+2)*wB + j + 0] = acc20;
            C_[(i+2)*wB + j + 1] = acc21;
            C_[(i+2)*wB + j + 2] = acc22;
            C_[(i+2)*wB + j + 3] = acc23;

            C_[(i+3)*wB + j + 0] = acc30;
            C_[(i+3)*wB + j + 1] = acc31;
            C_[(i+3)*wB + j + 2] = acc32;
            C_[(i+3)*wB + j + 3] = acc33;
        }
}

int main() {
    matmul_scalar(mat_A, mat_B, output_C, H_A, W_A, W_B);
    
    *DONE_FLAG = 1;
    while(1);
    return 0;
}
