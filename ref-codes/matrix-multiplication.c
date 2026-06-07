/* =======================================================================
 *  Requirements:  H_A, W_A, W_B multiples of 4   
 * ======================================================================= */
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#include <stdlib.h>

#include "a-core-utils.h"
#include "a-core.h"
#include "acore-gpio.h"
#include "a-core-csr.h"

#define USE_RANDOM_INPUT  1

#define H_A 64
#define W_A 64
#define W_B 64

/* --------------------------------------------------------------------------
 * Global buffers
 * -------------------------------------------------------------------------- */
static int8_t  A [H_A * W_A]         __attribute__((aligned(4)));
static int8_t  B [W_A * W_B]         __attribute__((aligned(4)));
static int32_t C_scalar[H_A * W_B]   __attribute__((aligned(4)));
static int32_t C_simd  [H_A * W_B]   __attribute__((aligned(4)));

/* buffer: B transposed ----------------------------------- */
static int8_t  Bt[W_B * W_A]         __attribute__((aligned(4)));

/* --------------------------------------------------------------------------
 * P-extension inline wrapper
 * -------------------------------------------------------------------------- */
static inline int32_t smaqa_accum(int32_t acc, uint32_t rs1, uint32_t rs2)
{
    asm volatile ("smaqa %0, %1, %2" : "+r"(acc) : "r"(rs1), "r"(rs2));
    return acc;
}

/* ======================================================================
 *   Scalar kernel - tiled matrix multiplication
 * ====================================================================== */
void matmul_seq_opt(const int8_t * restrict A_,
                    const int8_t * restrict B_,
                    int32_t      * restrict C_,
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

/* ======================================================================
 *    Transpose helper - gives Bt
 * ====================================================================== */
static void transpose_B(const int8_t *Bsrc, int8_t *Bt_,
                        int wA, int wB)
{
    for (int c = 0; c < wA; ++c)
        for (int r = 0; r < wB; ++r)
            Bt_[r * wA + c] = Bsrc[c * wB + r];
}

/* ======================================================================
 *   SIMD kernel – consumes A row-major, Bt row-major
 * ====================================================================== */
static void matmul_simd_opt(const int8_t *A_,
                            const int8_t *Bt_,
                            int32_t      *C,
                            int hA, int wA, int wB)
{
    const uint32_t * restrict A  = (const uint32_t *)A_;
    const uint32_t * restrict Bt = (const uint32_t *)Bt_;
    const int wA4 = wA >> 2;          /* columns per row, in packed words */

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

                acc00 = smaqa_accum(acc00, A0, B0);
                acc01 = smaqa_accum(acc01, A0, B1);
                acc02 = smaqa_accum(acc02, A0, B2);
                acc03 = smaqa_accum(acc03, A0, B3);

                acc10 = smaqa_accum(acc10, A1, B0);
                acc11 = smaqa_accum(acc11, A1, B1);
                acc12 = smaqa_accum(acc12, A1, B2);
                acc13 = smaqa_accum(acc13, A1, B3);

                acc20 = smaqa_accum(acc20, A2, B0);
                acc21 = smaqa_accum(acc21, A2, B1);
                acc22 = smaqa_accum(acc22, A2, B2);
                acc23 = smaqa_accum(acc23, A2, B3);

                acc30 = smaqa_accum(acc30, A3, B0);
                acc31 = smaqa_accum(acc31, A3, B1);
                acc32 = smaqa_accum(acc32, A3, B2);
                acc33 = smaqa_accum(acc33, A3, B3);
            }

            /* flat 4×4 write-back */
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

/* ======================================================================
 *   wrapper: transpose then call timed kernel
 * ====================================================================== */
void matmul_simd_8bit(const int8_t *A_, const int8_t *B_, int32_t *C_,
                      int hA, int wA, int wB)
{
    // transpose is not included in timing 
    transpose_B(B_, Bt, wA, wB);
    matmul_simd_opt(A_, Bt, C_, hA, wA, wB);
}

/* ======================================================================
 *   Main – benchmark
 * ====================================================================== */
int main(void)
{
    /* --  fill input  -- */
#if USE_RANDOM_INPUT
    srand(1);
    for (size_t i = 0; i < sizeof A; ++i) A[i] = (rand() % 255) - 128;
    for (size_t i = 0; i < sizeof B; ++i) B[i] = (rand() % 255) - 128;
#else
    /* Zero entire buffers, then provide an 8×8 custom test */
    memset(A, 0, sizeof A);
    memset(B, 0, sizeof B);

    static const int8_t A_custom[H_A][W_A] = {
        {  1,  -2,   3,  -4,   5,  -6,   7,  -8 },
        { -8,   7,  -6,   5,  -4,   3,  -2,   1 },
        {  2,  -3,   4,  -5,   6,  -7,   8,  -9 },
        { -9,   8,  -7,   6,  -5,   4,  -3,   2 },
        { 10, -11,  12, -13,  14, -15,  16, -17 },
        { -17, 16, -15,  14, -13,  12, -11,  10 },
        { 18, -19,  20, -21,  22, -23,  24, -25 },
        { -25, 24, -23,  22, -21,  20, -19,  18 }
    };

    static const int8_t B_custom[W_A][W_B] = {
        { -1,   2,  -3,   4,  -5,   6,  -7,   8 },
        {  8,  -7,   6,  -5,   4,  -3,   2,  -1 },
        { -2,   3,  -4,   5,  -6,   7,  -8,   9 },
        {  9,  -8,   7,  -6,   5,  -4,   3,  -2 },
        { -3,   4,  -5,   6,  -7,   8,  -9,  10 },
        { 10,  -9,   8,  -7,   6,  -5,   4,  -3 },
        { -4,   5,  -6,   7,  -8,   9, -10,  11 },
        { 11, -10,   9,  -8,   7,  -6,   5,  -4 }
    };

    for (int r = 0; r < 8; ++r)
        for (int c = 0; c < 8; ++c)
            A[r * W_A + c] = A_custom[r][c];

    for (int r = 0; r < 8; ++r)
        for (int c = 0; c < 8; ++c)
            B[r * W_B + c] = B_custom[r][c];
#endif

    /* --  scalar run  -- */
    clock_t t0 = clock();
    unsigned ir0 = get_instret();
    matmul_seq_opt(A, B, C_scalar, H_A, W_A, W_B);
    unsigned ir_seq  = get_instret() - ir0;
    unsigned cyc_seq = (unsigned)(clock() - t0);

    /* --  SIMD run (transpose outside timer)  -- */
    //transpose_B(B, Bt, W_A, W_B);

    t0  = clock();
    ir0 = get_instret();
    transpose_B(B, Bt, W_A, W_B);
    matmul_simd_opt(A, Bt, C_simd, H_A, W_A, W_B);
    unsigned ir_simd  = get_instret() - ir0;
    unsigned cyc_simd = (unsigned)(clock() - t0);

    /* --  report  -- */
    printf("Welcome to A-Core!\n");
    printf("%dx%d × %dx%d\n\n", H_A, W_A, W_A, W_B);
    printf("Scalar-best cycles : %u\n", cyc_seq);
    printf("SIMD   kernel cycles: %u\n", cyc_simd);
    printf("Cycle reduction     : %d %%\n",
           (int)((cyc_seq - cyc_simd) * 100 / cyc_seq));
    printf("Scalar-best instret : %u\n", ir_seq);
    printf("SIMD   instret      : %u\n", ir_simd);
    printf("Instret reduction   : %d %%\n\n",
           (int)((ir_seq - ir_simd) * 100 / ir_seq));

    /* -- quick correctness check for any mismatches -- */
    int mism = 0;
    for (int i = 0; i < H_A*W_B; ++i)
        if (C_scalar[i] != C_simd[i]) ++mism;
    printf("Mismatches: %d\n", mism);
    #if USE_RANDOM_INPUT
	    printf("Mismatches: %d\n",mism);
    #else
	    printf("Mismatches: %d\n",mism);
	    printf("\nResultant Matrix from regular matmul:\n");
	    for (int i = 0; i < H_A; i++) {
		for (int j = 0; j < W_B; j++) {
		    printf("%7d ", C_scalar[i*W_B + j]);
		}
		printf("\n");
	    }

	    printf("\nResultant Matrix from optimised matmul:\n");
	    for (int i = 0; i < H_A; i++) {
		for (int j = 0; j < W_B; j++) {
		    printf("%7d ", C_simd[i*W_B + j]);
		}
		printf("\n");
	    }
     #endif

    test_pass();
    return 0;
}

