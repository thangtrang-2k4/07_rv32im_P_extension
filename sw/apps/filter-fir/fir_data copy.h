#ifndef __FIR_DATA_H
#define __FIR_DATA_H

#include <stdint.h>

#define FIR_TAPS 32
#define INPUT_LEN 40
#define SCALE_SHIFT 7

static const int8_t fir_coeffs[FIR_TAPS] = { 0, 0, 0, 1, 1, 0, -1, -2, -3, -3, -2, 2, 8, 15, 21, 25, 25, 21, 15, 8, 2, -2, -3, -3, -2, -1, 0, 1, 1, 0, 0, 0 };
static const int8_t input_data[INPUT_LEN] = { 8, 0, -7, -5, -17, -7, -15, 3, 0, -3, 4, 1, 20, 4, -1, 0, 13, -12, 35, 19, 23, 12, 5, 2, -2, -11, -7, -22, -20, 29, -17, 0, 6, 20, -23, -8, 2, 3, -27, -7 };

#endif
