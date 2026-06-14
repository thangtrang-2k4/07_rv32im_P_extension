#include <stdint.h>
#include "sobel_data.h"

/* ──────────────────────────────────────────────────────────────────── */
/*  Cấu hình tự động từ sobel_data.h                                   */
/* ──────────────────────────────────────────────────────────────────── */
#define WIDTH  IMG_WIDTH
#define HEIGHT IMG_HEIGHT

/* Linker symbols */
extern volatile uint32_t _done_flag;

// ===== OUTPUT: 8-bit =====
volatile uint8_t output[HEIGHT][WIDTH];


// Sobel filter
void sobel() {
for (int i = 1; i < HEIGHT - 1; i++) {
for (int j = 1; j < WIDTH - 1; j++) {

        // ===== WIDEN =====
        int gx = 0;
        int gy = 0;

        // Gx
        gx += -1 * (int)input[i-1][j-1];
        gx +=  1 * (int)input[i-1][j+1];

        gx += -2 * (int)input[i][j-1];
        gx +=  2 * (int)input[i][j+1];

        gx += -1 * (int)input[i+1][j-1];
        gx +=  1 * (int)input[i+1][j+1];

        // Gy
        gy += -1 * (int)input[i-1][j-1];
        gy += -2 * (int)input[i-1][j];
        gy += -1 * (int)input[i-1][j+1];

        gy +=  1 * (int)input[i+1][j-1];
        gy +=  2 * (int)input[i+1][j];
        gy +=  1 * (int)input[i+1][j+1];

        // ABS
        if (gx < 0) gx = -gx;
        if (gy < 0) gy = -gy;

        int mag = gx + gy;

        // CLIP
        if (mag > 255) mag = 255;

        // ===== NARROW =====
        output[i][j] = (uint8_t)mag;
    }
}

}

int main() {

// INIT
for (int i = 0; i < HEIGHT; i++) {
    for (int j = 0; j < WIDTH; j++) {
        output[i][j] = 0;
    }
}

sobel();

// Báo hiệu hoàn tất bằng cách ghi giá trị 1 vào bộ nhớ (địa chỉ vượt ngoài không gian biến output)
// Data Memory BaseAddr là 0x80010000
_done_flag = 1;

return 0;

}
