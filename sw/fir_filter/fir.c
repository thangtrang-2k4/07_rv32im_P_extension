#include <stdint.h>

#define N     200
#define TAPS  32

// ===== MEMORY BASE =====
#define X_BASE  0x80000000
#define H_BASE  0x80000100
#define Y_BASE  0x80000200

// ===== READ BYTE FROM WORD MEMORY =====
static inline int8_t load_byte(uint32_t addr)
{
    // word aligned address
    volatile uint32_t *mem = (uint32_t *)(addr & ~0x3);

    uint32_t word = *mem;

    uint32_t offset = addr & 0x3;

    return (int8_t)((word >> (8 * offset)) & 0xFF);
}

// ===== WRITE BYTE =====
static inline void store_byte(uint32_t addr, int8_t value)
{
    volatile uint32_t *mem = (uint32_t *)(addr & ~0x3);

    uint32_t word = *mem;

    uint32_t offset = addr & 0x3;

    uint32_t mask = ~(0xFF << (8 * offset));

    word = (word & mask) | ((uint32_t)(uint8_t)value << (8 * offset));

    *mem = word;
}

// ===== FIR FILTER =====
void fir_baseline()
{
    for (int n = TAPS - 1; n < N; n++)
    {
        int32_t acc = 0;

        for (int k = 0; k < TAPS; k++)
        {
            int8_t x_val = load_byte(X_BASE + (n - k));
            int8_t h_val = load_byte(H_BASE + k);

            acc += x_val * h_val;
        }

        // rounding + scale back (Q0.10)
        int8_t y_val = (acc + (1 << 9)) >> 10;

        store_byte(Y_BASE + n, y_val);
    }
}

// ===== MAIN =====
int main()
{
    fir_baseline();

    while (1);  // giữ CPU

    return 0;
}
