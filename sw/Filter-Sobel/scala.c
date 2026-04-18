#include <stdint.h>
#include <stdio.h>

#define WIDTH  5
#define HEIGHT 5

// ===== INPUT: 8-bit (chuẩn image) =====
uint8_t input[HEIGHT][WIDTH] = {
{10, 10, 10, 10, 10},
{10, 50, 50, 50, 10},
{10, 50,100, 50, 10},
{10, 50, 50, 50, 10},
{10, 10, 10, 10, 10}
};

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
volatile uint32_t* done_flag = (volatile uint32_t*)0x80011000;
*done_flag = 1;

return 0;

}
