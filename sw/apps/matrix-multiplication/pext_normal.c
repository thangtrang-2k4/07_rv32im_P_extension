#include <stdint.h>
#include "matrix_data.h"

static int32_t output_C[H_A * W_B] __attribute__((aligned(4)));

volatile uint32_t * const DONE_FLAG = (uint32_t *)0x8001FFFC;

static inline int32_t pm4adda_b(int32_t acc, uint32_t rs1, uint32_t rs2)
{
    asm volatile (
        "pm4adda.b %0, %1, %2"
        : "+r"(acc)
        : "r"(rs1), "r"(rs2)
    );

    return acc;
}

static inline uint32_t pack_B_lane4(
    uint32_t row0,
    uint32_t row1,
    uint32_t row2,
    uint32_t row3,
    unsigned int lane
)
{
    const unsigned int shift = lane << 3;

    return ((row0 >> shift) & 0xFFu)
         | (((row1 >> shift) & 0xFFu) << 8)
         | (((row2 >> shift) & 0xFFu) << 16)
         | (((row3 >> shift) & 0xFFu) << 24);
}

static void matmul_pext(
    const uint32_t *A,
    const uint32_t *B,
    int32_t *C,
    int hA,
    int wA,
    int wB
)
{
    const int wA4 = wA >> 2;
    const int wB4 = wB >> 2;

    for (int i = 0; i < hA; i += 4) {
        for (int j = 0; j < wB; j += 4) {

            int32_t acc00 = 0, acc01 = 0, acc02 = 0, acc03 = 0;
            int32_t acc10 = 0, acc11 = 0, acc12 = 0, acc13 = 0;
            int32_t acc20 = 0, acc21 = 0, acc22 = 0, acc23 = 0;
            int32_t acc30 = 0, acc31 = 0, acc32 = 0, acc33 = 0;

            const int j_word = j >> 2;

            for (int kb = 0; kb < wA4; ++kb) {

                uint32_t A0 = A[(i + 0) * wA4 + kb];
                uint32_t A1 = A[(i + 1) * wA4 + kb];
                uint32_t A2 = A[(i + 2) * wA4 + kb];
                uint32_t A3 = A[(i + 3) * wA4 + kb];

                const int k = kb << 2;

                uint32_t Brow0 = B[(k + 0) * wB4 + j_word];
                uint32_t Brow1 = B[(k + 1) * wB4 + j_word];
                uint32_t Brow2 = B[(k + 2) * wB4 + j_word];
                uint32_t Brow3 = B[(k + 3) * wB4 + j_word];

                uint32_t B0 = pack_B_lane4(Brow0, Brow1, Brow2, Brow3, 0);
                uint32_t B1 = pack_B_lane4(Brow0, Brow1, Brow2, Brow3, 1);
                uint32_t B2 = pack_B_lane4(Brow0, Brow1, Brow2, Brow3, 2);
                uint32_t B3 = pack_B_lane4(Brow0, Brow1, Brow2, Brow3, 3);

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

            C[(i + 0) * wB + j + 0] = acc00;
            C[(i + 0) * wB + j + 1] = acc01;
            C[(i + 0) * wB + j + 2] = acc02;
            C[(i + 0) * wB + j + 3] = acc03;

            C[(i + 1) * wB + j + 0] = acc10;
            C[(i + 1) * wB + j + 1] = acc11;
            C[(i + 1) * wB + j + 2] = acc12;
            C[(i + 1) * wB + j + 3] = acc13;

            C[(i + 2) * wB + j + 0] = acc20;
            C[(i + 2) * wB + j + 1] = acc21;
            C[(i + 2) * wB + j + 2] = acc22;
            C[(i + 2) * wB + j + 3] = acc23;

            C[(i + 3) * wB + j + 0] = acc30;
            C[(i + 3) * wB + j + 1] = acc31;
            C[(i + 3) * wB + j + 2] = acc32;
            C[(i + 3) * wB + j + 3] = acc33;
        }
    }
}

int main(void)
{
    matmul_pext(
        (const uint32_t *)mat_A,
        (const uint32_t *)mat_B,
        output_C,
        H_A,
        W_A,
        W_B
    );

    *DONE_FLAG = 1;

    while (1);

    return 0;
}
