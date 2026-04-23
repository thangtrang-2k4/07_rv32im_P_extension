#ifndef __FIR_DATA_H
#define __FIR_DATA_H

#define FIR_TAPS 32
#define INPUT_LEN 40

static const int8_t fir_coeffs[FIR_TAPS] = { -1, 1, 2, 4, 5, 3, -4, -15, -24, -27, -14, 18, 67, 123, 172, 201, 201, 172, 123, 67, 18, -14, -27, -24, -15, -4, 3, 5, 4, 2, 1, -1 };
static const int8_t input_data[INPUT_LEN] = {
    8, 0, -7, -5, -17, -7, -15, 3, 0, -3, 4, 1, 20, 4, -1, 0,
    13, -12, 35, 19, 23, 12, 5, 2, -2, -11, -7, -22, -20, 29, -17, 0,
    6, 20, -23, -8, 2, 3, -27, -7,
};

#endif