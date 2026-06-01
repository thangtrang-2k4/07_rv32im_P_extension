#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#include <stdlib.h>

#include "a-core-utils.h"
#include "a-core.h"
#include "acore-gpio.h"

//------------------------------------------------------------------
// Configuration
#define FIR_TAPS 32      // Must be multiple of 4
#define INPUT_LENGTH 200  // Number of input samples
#define USE_RANDOM     0                 // 0 = hand vector, 1 = random numbers 

//------------------------------------------------------------------
/* FIR coefficients
* Generated using Py script.
* 
*/
static int8_t fir_coeffs[FIR_TAPS] = {
      
     /*0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, -1, -1, -1, 0, 0, 1, 1, 1, 0, -1, -1, -2, -2, -1, 1, 2, 3, 3, 1, -1, -4, -5, -5, -2, 3, 9, 16, 22, 25, 25, 22, 16, 9, 3, -2, -5, -5, -4, -1, 1, 3, 3, 2, 1, -1, -2, -2, -1, -1, 0, 1, 1, 1, 0, 0, -1, -1, -1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     /*0, 0, 4, 11, 21, 28, 28, 21, 11, 4, 0, 0*/
      
      -2, -2, -3, -3, -3, -1, 2, 8, 18, 30, 44, 60, 75, 88, 98, 103, 103, 98, 88, 75, 60, 44, 30, 18, 8, 2, -1, -3, -3, -3, -2, -2
};

// Output buffers (valid outputs: INPUT_LENGTH - FIR_TAPS + 1)
static int32_t output_sisd[INPUT_LENGTH];
static int32_t output_smaqa[INPUT_LENGTH];

//------------------------------------------------------------------
// 1) SISD FIR implementation 
void fir_sisd(const int8_t *in, int32_t *out) {
    // Only compute valid outputs starting from FIR_TAPS-1
    for (int n = FIR_TAPS-1; n < INPUT_LENGTH; n++) {
        int32_t acc = 0;
        for (int k = 0; k < FIR_TAPS; k++) {
            acc += (int32_t)in[n - k] * (int32_t)fir_coeffs[k];
        }
        // round‑to‑nearest then scale down: (acc / 2^10). Because FIR coefficients are scaled up.
        out[n] = (acc + (1 << 9)) >> 10;
    }
}

//------------------------------------------------------------------
// 2) SIMD (smaqa) FIR implementation
static inline int32_t mac4_smaqa(int32_t acc, int32_t a, int32_t b) {
    asm volatile ("smaqa %0, %1, %2" : "+r" (acc) : "r" (a), "r" (b));
    return acc;
}

void fir_smaqa(const int8_t *in, int32_t *out) {
    const int num_blocks = FIR_TAPS / 4;
    int32_t coeff_blocks[num_blocks];

    // Precompute coefficient blocks
    for (int i = 0; i < num_blocks; i++) {
        coeff_blocks[i] = 
            ((int32_t)(uint8_t)fir_coeffs[i*4 + 0])       |
            ((int32_t)(uint8_t)fir_coeffs[i*4 + 1] << 8)  |
            ((int32_t)(uint8_t)fir_coeffs[i*4 + 2] << 16) |
            ((int32_t)(uint8_t)fir_coeffs[i*4 + 3] << 24);  
    }  

    // Process starting from first valid sample
    for (int n = FIR_TAPS-1; n < INPUT_LENGTH; n++) {
        int32_t acc = 0;
        for (int i = 0; i < num_blocks; i++) {
            // Calculate sample indices relative to current n
            int idx = n - i*4;
            int32_t sample_block = 
                ((int32_t)(uint8_t)in[idx - 0])       |
                ((int32_t)(uint8_t)in[idx - 1] << 8)  |
                ((int32_t)(uint8_t)in[idx - 2] << 16) |
                ((int32_t)(uint8_t)in[idx - 3] << 24);

            acc = mac4_smaqa(acc, sample_block, coeff_blocks[i]);
        }
        out[n] = (acc + (1 << 9)) >> 10;
    }
}

//------------------------------------------------------------------
// Main test routine
void main() {

    // Init UART
    volatile uint32_t* uart_base_addr = (volatile uint32_t*) A_CORE_AXI4LUART;
    init_uart(uart_base_addr, BAUDRATE);

    static int8_t input_data[INPUT_LENGTH];
    #if USE_RANDOM
            srand(time(NULL));
	    for (int i = 0; i < INPUT_LENGTH; i++)
		input_data[i] = (int8_t)(rand() % 256 - 128);
    #else
	    /* HAND‑WRITTEN TEST VECTOR 
	       For pen-paper verification of FIR outputs.  */
	    const int8_t known[INPUT_LENGTH] = {
		      39,   67,   32,    7,   54,   79,   84,   36,   74,  106,
		     102,   54,   62,  111,   74,   21,   78,   98,   55,   28,
		       7,   46,   23,  -22,  -19,  -24,  -34,  -53,  -14,   11,
		     -43,  -43,  -53,    7,  -28,  -78,   -4,    9,   19,   -5,
		     -12,   51,   59,    6,   43,  107,   48,   52,   59,  127,
		      96,   50,   50,   85,   67,   62,   30,   72,   49,    6,
		      37,   35,   27,  -27,  -12,   -4,  -25,  -66,  -35,  -30,
		     -61,  -84,  -32,   -2,  -32,  -73,   -2,   37,   25,    5,
		      42,   77,   39,   15,   66,   71,   85,   68,   99,  107,
		     105,   58,   72,  105,   96,   61,   71,   44,   43,    3,
		      26,   53,  -16,  -19,  -40,  -17,  -13,  -70,  -20,  -41,
		     -63,  -53,  -66,   -7,   -6,  -46,   -6,  -14,    8,   -9,
		      23,   45,   29,   50,   25,   56,   94,   29,   52,   84,
		      96,   79,   46,   91,   43,   22,   37,   78,   28,  -16,
		      18,    5,  -24,   -4,  -35,   -9,  -17,  -39,  -14,  -37,
		     -32,  -37,  -66,   -1,  -10,  -58,  -32,   21,   -4,  -35,
		      16,   46,   41,   22,   42,   76,   87,   33,   79,   72,
		      92,   43,   48,   82,   51,   64,   44,   57,   28,   30,
		      26,   40,   12,  -40,  -22,    9,  -60,  -78,  -49,  -33,
		     -34,  -73,  -17,   -7,  -36,  -54,   -5,   10,    9,  -43 
                       };
            // copy the data to FIR filter buffer
	    memcpy(input_data, known, sizeof(input_data));
	#endif

    //--------------Run filters-----------------
    // Measure SISD execution
    clock_t start = clock();
    unsigned instret_start = get_instret();
    fir_sisd(input_data, output_sisd);
    unsigned instret_end = get_instret();
    clock_t end = clock();   
    unsigned cycles_sisd = (unsigned)(end - start);
    unsigned instr_ret_sisd = instret_end - instret_start;

     // Measure SIMD execution
    start = clock();
    instret_start = get_instret();
    fir_smaqa(input_data, output_smaqa);
    instret_end = get_instret();
    end = clock();
    unsigned cycles_smaqa = (unsigned)(end - start);
    unsigned instr_ret_simd = instret_end - instret_start;
   
    printf("Welcome to A-Core!\n");
    printf("Filter Length: %d | Input samples: %d\n", FIR_TAPS,INPUT_LENGTH);
    printf("Seq CPU cyles: %u\n", cycles_sisd);
    printf("SIMD CPU cycles: %u\n", cycles_smaqa);
    printf("CPU Time reduction: %d%%\n", 
        (int)((cycles_sisd - cycles_smaqa) * 100 / cycles_sisd));
    printf("SISD Instret: %u\n", instr_ret_sisd);
    printf("SIMD Instret: %u\n", instr_ret_simd);
    printf("Instret reduction: %d%%\n",
           (int)((instr_ret_sisd - instr_ret_simd) * 100 / instr_ret_sisd));

    // Verify results (only check valid outputs)
    int mismatches = 0;
    const int first_valid = FIR_TAPS-1;
    const int last_valid  = INPUT_LENGTH - 1;
    for (int i = first_valid; i < INPUT_LENGTH; i++) {
        if (output_sisd[i] != output_smaqa[i]) {
            mismatches++;
        }
    }
    
    printf("Mismatches: %d\n", mismatches);

	#if USE_RANDOM

	    // Print 5 random output samples for inspection
	    printf("\nRandomly sampled outputs (n | SISD | SIMD):\n");
	    for (int j = 0; j < 5; j++) {
		int n = first_valid + rand() % (last_valid - first_valid + 1);
		printf("n=%3d | %7ld | %7ld\n", n, output_sisd[n], output_smaqa[n]);
	    }
	#else
	    const int COLS = 8;

	    printf("\n--- SISD Output ---\n");
	    for (int n = first_valid; n <= last_valid; n++) {
		printf("%7d  ", output_sisd[n]);
		if ((n - first_valid + 1) % COLS == 0)
		    printf("\n");
	    }
	    if ((last_valid - first_valid + 1) % COLS != 0)
		printf("\n");

	    printf("\n--- SIMD Output ---\n");
	    for (int n = first_valid; n <= last_valid; n++) {
		printf("%7d  ", output_smaqa[n]);
		if ((n - first_valid + 1) % COLS == 0)
		    printf("\n");
	    }
	    if ((last_valid - first_valid + 1) % COLS != 0)
		printf("\n");
	#endif
    test_pass();
}


