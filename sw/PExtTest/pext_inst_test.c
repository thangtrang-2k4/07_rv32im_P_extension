/*This is the C test program for testing the P-Extension instructions using inline assembly.
==Random and corner cases for instructions have been written in test_p_extension_instructions() function
==and the output is tested against an expected values.
*/
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <time.h>

#include "a-core-utils.h"
#include "a-core.h"
#include "acore-gpio.h"


static int tests_passed = 0;
static int tests_failed = 0;

void test_p_extension_instructions();

//===============Macros for instruction types=================//
// Test macro for 3-operand instructions: op rd, rs1, rs2
#define TEST_INSTRUCTION(name, op, rs1_val, rs2_val, expected_rd) \
do { \
    uint32_t rd; \
    asm volatile ( \
        op " %0, %1, %2" \
        : "=r" (rd) \
        : "r" (rs1_val), "r" (rs2_val) \
    ); \
    if (rd == expected_rd) { \
        tests_passed++; \
    } else { \
        tests_failed++; \
        printf("[FAIL] %s: rs1=0x%08x rs2=0x%08x | Expected 0x%08x Got 0x%08x\n", \
               name, rs1_val, rs2_val, (unsigned int)expected_rd, (unsigned int)rd); \
    } \
} while (0)

// Test macro for instructions with 2 operands: op rd, rs
#define TEST_INSTRUCTION_SINGLE(name, op, rs_val, expected_rd) \
do { \
    uint32_t rd; \
    asm volatile ( \
        op " %0, %1" \
        : "=r" (rd) \
        : "r" (rs_val) \
    ); \
    if (rd == (expected_rd)) { \
        tests_passed++; \
    } else { \
        tests_failed++; \
        printf("[FAIL] %s: rs=0x%08X | Expected 0x%08X, Got 0x%08X\n", \
               name, (unsigned int)rs_val, (unsigned int)expected_rd, (unsigned int)rd); \
    } \
} while (0)

// Test macro for instructions with a register + immediate: op rd, rs, imm
#define TEST_INSTRUCTION_IMM(name, op, rs_val, imm_val, expected_rd) \
do { \
    uint32_t rd; \
    asm volatile ( \
        op " %0, %1, %2" \
        : "=r" (rd) \
        : "r" (rs_val), "i" (imm_val) \
    ); \
    if (rd == (expected_rd)) { \
        tests_passed++; \
    } else { \
        tests_failed++; \
        printf("[FAIL] %s: rs=0x%08X imm=%d | Expected 0x%08X, Got 0x%08X\n", \
               name, (unsigned int)rs_val, imm_val, (unsigned int)expected_rd, (unsigned int)rd); \
    } \
} while (0)


//===============MAIN FUNCTION=================//
void main() {
    printf("Welcome to A-Core!\n");
// Init UART
    volatile uint32_t* uart_base_addr = (volatile uint32_t*) A_CORE_AXI4LUART;
    init_uart(uart_base_addr, BAUDRATE);

    test_p_extension_instructions();

    test_pass();
}

//===================TEST FUNCTIONS==================//


void test_p_extension_instructions() {

    // Test PADD.B (SIMD 8-bit Addition)
    TEST_INSTRUCTION("PADD.B", "paddb",
        0xFE10F0F0,  // [0xFE, 0x10, 0xF0, 0xF0] (Decimal: [254, 16, 240, 240])
        0x01FF1011,  // [0x01, 0xFF, 0x10, 0x11] (Decimal: [1, 255, 16, 17])
        0xFF0F0001); // Result: [0xFF, 0x0F, 0x00, 0x01] (Decimal: [255, 15, 0, 1])

    // Test PADD.B (Signed Case)
    TEST_INSTRUCTION("PADD.B", "paddb",
        0x9B47E3B2,  // [0x9B, 0x47, 0xE3, 0xB2] (Decimal: [-101, 71, -29, -78])
        0x2D98C4FF,  // [0x2D, 0x98, 0xC4, 0xFF] (Decimal: [45, -104, -60, -1])
        0xC8DFA7B1); // Result: [0xC8, 0xDF, 0xA7, 0xB1] (Decimal: [-63, -33, -89, -79])

    // Test PADD.B (Unsigned Case)
    TEST_INSTRUCTION("PADD.B", "paddb",
        0x9B47E3B2,  // [0x9B, 0x47, 0xE3, 0xB2] (Decimal: [155, 71, 227, 178])
        0x2D98C4FF,  // [0x2D, 0x98, 0xC4, 0xFF] (Decimal: [45, 152, 196, 255])
        0xC8DFA7B1); // Result: [0xC8, 0xDF, 0xA7, 0xB1] (Decimal: [193, 223, 167, 177])

    // Test PAADD.B (SIMD 8-bit Signed Averaging Addition)
    TEST_INSTRUCTION("PAADD.B", "paaddb",
        0x7F804000,  // [0x7F, 0x80, 0x40, 0x00] (Decimal: [127, -128, 64, 0])
        0x7F808000,  // [0x7F, 0x80, 0x80, 0x00] (Decimal: [127, -128, -128, 0])
        0x7F80E000); // Result: [0x7F, 0x80, 0xE0, 0x00] (Decimal: [127, -128, -32, 0])

    // Test PAADDU.B (SIMD 8-bit Unsigned Averaging Addition)
    TEST_INSTRUCTION("PAADDU.B", "paaddub",
        0x7F804000,  // [0x7F, 0x80, 0x40, 0x00] (Decimal: [127, 128, 64, 0])
        0x7F808000,  // [0x7F, 0x80, 0x80, 0x00] (Decimal: [127, 128, 128, 0])
        0x7F806000); // Result: [0x7F, 0x80, 0x60, 0x00] (Decimal: [127, 128, 96, 0])

    // Test PSADDU.B (SIMD 8-bit Unsigned Saturating Addition)
    TEST_INSTRUCTION("PSADDU.B", "psaddub",
        0xFFFF8040,  // [0xFF, 0xFF, 0x80, 0x40] (Decimal: [255, 255, 128, 64])
        0x02018080,  // [0x02, 0x01, 0x80, 0x80] (Decimal: [2, 1, 128, 128])
        0xFFFFFFC0); // Result: [0xFF, 0xFF, 0xFF, 0xC0] (Decimal: [255, 255, 255, 192])

    // Test PSUB.B (SIMD 8-bit Subtraction)
    TEST_INSTRUCTION("PSUB.B", "psubb",
        0xFFF1EFDF,  // [0xFF, 0xF1, 0xEF, 0xDF] (Decimal: [255, -15, -17, -33])
        0x000DF302,  // [0x00, 0x0D, 0xF3, 0x02] (Decimal: [0, 13, -13, 2])
        0xFFE4FCDD); // Result: [0xFF, 0xE4, 0xFC, 0xDD] (Decimal: [255, -28, -4, -35])

    // Test PASUB.B (SIMD 8-bit Signed Averaging Subtraction)
    TEST_INSTRUCTION("PASUB.B", "pasubb",
        0x7F808080,  // [0x7F, 0x80, 0x80, 0x80] (Decimal: [127, -128, -128, -128])
        0x807F4080,  // [0x80, 0x7F, 0x40, 0x80] (Decimal: [-128, 127, 64, -128])
        0x7F80A000); // Result: [0x7F, 0x80, 0xA0, 0x00] (Decimal: [127, -128, -96, 0])

    // Test PASUBU.B (SIMD 8-bit Unsigned Averaging Subtraction)
    TEST_INSTRUCTION("PASUBU.B", "pasubub",
        0x7F808081,  // [0x7F, 0x80, 0x80, 0x81] (Decimal: [127, -128, -128, -127])
        0x807F4001,  // [0x80, 0x7F, 0x40, 0x01] (Decimal: [-128, 127, 64, 1])
        0xFF002040); // Result: [0xFF, 0x00, 0x20, 0x40] (Decimal: [255, 0, 32, 64])

    // Test PSSUB.B (SIMD 8-bit Signed Saturating Subtraction)
    TEST_INSTRUCTION("PSSUB.B", "pssubb",
        0x008020FF,  // [0x00, 0x80, 0x20, 0xFF] (Decimal: [0, -128, 32, -1])
        0x81803001,  // [0x81, 0x80, 0x30, 0x01] (Decimal: [-127, -128, 48, 1])
        0x7F00F0FE); // Result: [0x7F, 0x00, 0xF0, 0xFE] (Decimal: [127, 0, -16, -2])

    // Test PSSUB.B (Overflow Case)
    TEST_INSTRUCTION("PSSUB.B", "pssubb",
        0x407F8180,  // [0x40, 0x7F, 0x81, 0x80] (Decimal: [64, 127, -127, -128])
        0xC07F7F00,  // [0xC0, 0x7F, 0x7F, 0x00] (Decimal: [-64, 127, 127, 0])
        0x7F008080); // Result: [0x7F, 0x00, 0x80, 0x80] (Decimal: [127, 0, -128, -128])

    // Test PSSUBU.B (SIMD 8-bit Unsigned Saturating Subtraction)
    TEST_INSTRUCTION("PSSUBU.B", "pssubub",
        0x5040FF10,  // [0x50, 0x40, 0xFF, 0x10] (Decimal: [80, 64, 255, 16])
        0x30200010,  // [0x30, 0x20, 0x00, 0x10] (Decimal: [48, 32, 0, 16])
        0x2020FF00); // Result: [0x20, 0x20, 0xFF, 0x00] (Decimal: [32, 32, 255, 0])

    // Test PSSUBU.B (Overflow Case)
    TEST_INSTRUCTION("PSSUBU.B", "pssubub",
        0x0564A0F0,  // [0x05, 0x64, 0xA0, 0xF0] (Decimal: [5, 100, 160, 240])
        0x1032B0FF,  // [0x10, 0x32, 0xB0, 0xFF] (Decimal: [16, 50, 176, 255])
        0x00320000); // Result: [0x00, 0x32, 0x00, 0x00] (Decimal: [0, 50, 0, 0])


    // Test PADD.H (SIMD 16-bit Addition)
    TEST_INSTRUCTION("PADD.H", "paddh",
        0x12345678,  // [0x1234, 0x5678] (Decimal: [4660, 22136])
        0x11112222,  // [0x1111, 0x2222] (Decimal: [4369, 8738])
        0x2345789A); // Result: [0x2345, 0x789A] (Decimal: [9030, 30874])

    // Test PAADD.H (SIMD 16-bit Signed Averaging Addition)
    TEST_INSTRUCTION("PAADD.H", "paaddh",
        0x7FFF8000,  // [0x7FFF, 0x8000] (Decimal: [32767, -32768])
        0x7FFF8000,  // [0x7FFF, 0x8000] (Decimal: [32767, -32768])
        0x7FFF8000); // No overflow for averaging addition

    // Test PAADD.H (SIMD 16-bit Signed Averaging Addition)
    TEST_INSTRUCTION("PAADD.H", "paaddh",
        0x4000FF01,  // [0x4000, 0xFF01] (Decimal: [16384, -255])
        0x800000FE,  // [0x8000, 0x00FE] (Decimal: [-32768, 254])
        0xE000FFFF); // Result: [0xE000, 0xFFFF] (Decimal: [-8192, -1])

    // Test PAADDU.H (SIMD 16-bit Unsigned Averaging Addition)
    TEST_INSTRUCTION("PAADDU.H", "paadduh",
        0x7FFF8000,  // [0x7FFF, 0x8000] (Decimal: [32767, 32768])
        0x7FFF8000,  // [0x7FFF, 0x8000] (Decimal: [32767, 32768])
        0x7FFF8000); // No overflow for unsigned averaging addition

    // Test PAADDU.H (SIMD 16-bit Unsigned Averaging Addition)
    TEST_INSTRUCTION("PAADDU.H", "paadduh",
        0x40001234,  // [0x4000, 0x1234] (Decimal: [16384, 4660])
        0x80005678,  // [0x8000, 0x5678] (Decimal: [32768, 22136])
        0x60003456); // Result: [0x6000, 0x3456] (Decimal: [24576, 13398])

    // Test PSADD.H (SIMD 16-bit Signed Saturating Addition)
    TEST_INSTRUCTION("PSADD.H", "psaddh",
        0x70008000,  // [0x7000, 0x8000] (Decimal: [28672, -32768])
        0x90001000,  // [0x9000, 0x1000] (Decimal: [-28672, 4096])
        0x00009000); // Result: [0x0000, 0x9000] (Decimal: [0, -28672])

    // Test PSADD.H (SIMD 16-bit Signed Saturating Addition, Saturation Case)
    TEST_INSTRUCTION("PSADD.H", "psaddh",
        0x7FFF8000,  // [0x7FFF, 0x8000] (Decimal: [32767, -32768])
        0x0001FFFF,  // [0x0001, 0xFFFF] (Decimal: [1, -1])
        0x7FFF8000); // Result: [0x7FFF, 0x8000] (Saturation occurred)

    // Test PSADDU.H (SIMD 16-bit Unsigned Saturating Addition)
    TEST_INSTRUCTION("PSADDU.H", "psadduh",
        0x20003000,  // [0x2000, 0x3000] (Decimal: [8192, 12288])
        0x10004000,  // [0x1000, 0x4000] (Decimal: [4096, 16384])
        0x30007000); // Result: [0x3000, 0x7000] (Decimal: [12288, 28672])

    // Test PSADDU.H (SIMD 16-bit Unsigned Saturating Addition, Saturation Case)
    TEST_INSTRUCTION("PSADDU.H", "psadduh",
        0x2000FFFF,  // [0x2000, 0xFFFF] (Decimal: [8192, 65535])
        0x30000001,  // [0x3000, 0x0001] (Decimal: [12288, 1])
        0x5000FFFF); // Result: [0x5000, 0xFFFF] (Saturation occurred in the second segment)

    // Test PSADDU.H (SIMD 16-bit Unsigned Saturating Addition, Saturation Case)
    TEST_INSTRUCTION("PSADDU.H", "psadduh",
        0x70008000,  // [0x7000, 0x8000] (Decimal: [28672, 32768])
        0x10009000,  // [0x1000, 0x9000] (Decimal: [4096, 36864])
        0x8000FFFF); // Result: [0x8000, 0xFFFF] (Saturation occurred in the second segment)
 

    // Test PSUB.H (SIMD 16-bit Subtraction)
    TEST_INSTRUCTION("PSUB.H", "psubh",
        0x1030FF10,  // [0x1030, 0xFF10] (Decimal: [4144, -240])
        0x0800FF20,  // [0x0800, 0xFF20] (Decimal: [2048, -224])
        0x0830FFF0); // Result: [0x0830, 0xFFF0] (Decimal: [2096, -16])

    // Test PSUB.H (SIMD 16-bit Subtraction, Negative Case)
    TEST_INSTRUCTION("PSUB.H", "psubh",
        0x80008000,  // [0x8000, 0x8000] (Decimal: [-32768, -32768])
        0x7FFF0001,  // [0x7FFF, 0x0001] (Decimal: [32767, 1])
        0x00017FFF); // Result: [0x0001, 0x7FFF] (Decimal: [1, 32767])

    // Test PASUB.H (SIMD 16-bit Signed Averaging Subtraction)
    TEST_INSTRUCTION("PASUB.H", "pasubh",
        0x7FFF8000,  // [0x7FFF, 0x8000] (Decimal: [32767, -32768])
        0x80007FFF,  // [0x8000, 0x7FFF] (Decimal: [-32768, 32767])
        0x7FFF8000); // No saturation occurs in averaging subtraction

    // Test PASUB.H (SIMD 16-bit Signed Averaging Subtraction)
    TEST_INSTRUCTION("PASUB.H", "pasubh",
        0x80007FFF,  // [0x8000, 0x7FFF] (Decimal: [-32768, 32767])
        0x40002000,  // [0x4000, 0x2000] (Decimal: [16384, 8192])
        0xA0002FFF); // Result: [0xA000, 0x2FFF] (Decimal: [-24576, 12287])

    // Test PASUBU.H (SIMD 16-bit Unsigned Averaging Subtraction)
    TEST_INSTRUCTION("PASUBU.H", "pasubuh",
        0x80008001,  // [0x8000, 0x8001] (Decimal: [32768, 32769])
        0x40000001,  // [0x4000, 0x0001] (Decimal: [16384, 1])
        0x20004000); // Result: [0x2000, 0x4000] (Decimal: [8192, 16384])

    // Test PASUBU.H (SIMD 16-bit Unsigned Averaging Subtraction, Negative Case)
    TEST_INSTRUCTION("PASUBU.H", "pasubuh",
        0x7FFF8000,  // [0x7FFF, 0x8000] (Decimal: [32767, 32768])
        0x80007FFF,  // [0x8000, 0x7FFF] (Decimal: [32768, 32767])
        0xFFFF0000); // Result: [0xFFFF, 0x0000] (Decimal: [-1, 0])

    // Test PSSUB.H (SIMD 16-bit Signed Saturating Subtraction)
    TEST_INSTRUCTION("PSSUB.H", "pssubh",
        0x3F2E5D4C,  // [0x3F2E, 0x5D4C] (Decimal: [16174, 23884])
        0x1A1B2C3D,  // [0x1A1B, 0x2C3D] (Decimal: [6683, 11325])
        0x2513310F); // Result: [0x2513, 0x310F] (Decimal: [9491, 12559])

    // Test PSSUB.H (SIMD 16-bit Signed Saturating Subtraction, Saturation Case)
    TEST_INSTRUCTION("PSSUB.H", "pssubh",
        0x7FFF8000,  // [0x7FFF, 0x8000] (Decimal: [32767, -32768])
        0x80007FFF,  // [0x8000, 0x7FFF] (Decimal: [-32768, 32767])
        0x7FFF8000); // Result: [0x7FFF, 0x8000] (Saturation occurs)

    // Test PSSUB.H (SIMD 16-bit Signed Saturating Subtraction, No Overflow)
    TEST_INSTRUCTION("PSSUB.H", "pssubh",
        0x40008001,  // [0x4000, 0x8001] (Decimal: [16384, -32767])
        0x20000001,  // [0x2000, 0x0001] (Decimal: [8192, 1])
        0x20008000); // Result: [0x2000, 0x8000] (Decimal: [8192, -32768])

    // Test PSSUBU.H (SIMD 16-bit Unsigned Saturating Subtraction)
    TEST_INSTRUCTION("PSSUBU.H", "pssubuh",
        0x7A5B1357,  // [0x7A5B, 0x1357] (Decimal: [31323, 4951])
        0x6A5C2468,  // [0x6A5C, 0x2468] (Decimal: [27228, 9320])
        0x0FFF0000); // Result: [0x0FFF, 0x0000] (Saturation occurred)

    // Test PSSUBU.H (SIMD 16-bit Unsigned Saturating Subtraction, Full Saturation)
    TEST_INSTRUCTION("PSSUBU.H", "pssubuh",
        0x1234ABCD,  // [0x1234, 0xABCD] (Decimal: [4660, 43981])
        0x5678DCBA,  // [0x5678, 0xDCBA] (Decimal: [22136, 56506])
        0x00000000); // Result: [0x0000, 0x0000] (Saturation occurred)

   
    // Test PAS.HX (SIMD 16-bit Cross Addition & Subtraction)
    TEST_INSTRUCTION("PAS.HX", "pashx",
        0x7A5B6A5C,  // [0x7A5B, 0x6A5C] (Decimal: [31323, 27228])
        0x13572468,  // [0x1357, 0x2468] (Decimal: [4951, 9320])
        0x9EC35705); // Result: [0x9EC3, 0x5705] (Cross Add & Sub without saturation)

    // Test PAAS.HX (SIMD 16-bit Signed Averaging Cross Addition & Subtraction)
    TEST_INSTRUCTION("PAAS.HX", "paashx",
        0x7A5B6A5C,  // [0x7A5B, 0x6A5C] (Decimal: [31323, 27228])
        0x13572468,  // [0x1357, 0x2468] (Decimal: [4951, 9320])
        0x4F612B82); // Result: [0x4F61, 0x2B82] (Averaged results of Cross Addition & Subtraction)

    // Test PAAS.HX (SIMD 16-bit Signed Averaging Cross Addition & Subtraction, Boundary Case)
    TEST_INSTRUCTION("PAAS.HX", "paashx",
        0x7FFF8000,  // [0x7FFF, 0x8000] (Decimal: [32767, -32768])
        0x7FFF7FFF,  // [0x7FFF, 0x7FFF] (Decimal: [32767, 32767])
        0x7FFF8000); // No change, boundary case

    // Test PAAS.HX (SIMD 16-bit Signed Averaging Cross Addition & Subtraction, Negative Case)
    TEST_INSTRUCTION("PAAS.HX", "paashx",
        0x80008000,  // [0x8000, 0x8000] (Decimal: [-32768, -32768])
        0x40008000,  // [0x4000, 0x8000] (Decimal: [16384, -32768])
        0x8000A000); // Result: [0x8000, 0xA000] (Averaged results of Cross Addition & Subtraction)


    // Test PSAS.HX (SIMD 16-bit Saturating Cross Addition & Subtraction)
    TEST_INSTRUCTION("PSAS.HX", "psashx",
        0x1A5B6A5C,  // [0x1A5B, 0x6A5C] (Decimal: [6747, 27228])
        0x23572468,  // [0x2357, 0x2468] (Decimal: [9047, 9320])
        0x3EC34705); // Result: [0x3EC3, 0x4705] (Cross Add & Sub without saturation)

    // Test PSAS.HX (SIMD 16-bit Saturating Cross Addition & Subtraction, Saturation Case)
    TEST_INSTRUCTION("PSAS.HX", "psashx",
        0x7FFF8000,  // [0x7FFF, 0x8000] (Decimal: [32767, -32768])
        0x7FFF0001,  // [0x7FFF, 0x0001] (Decimal: [32767, 1])
        0x7FFF8000); // Result: [0x7FFF, 0x8000] (Saturation occurs)

    // Test PSA.HX (SIMD 16-bit Cross Subtraction & Addition)
    TEST_INSTRUCTION("PSA.HX", "psahx",
        0x6A5C7A5B,  // [0x6A5C, 0x7A5B] (Decimal: [27228, 31323])
        0x24681357,  // [0x2468, 0x1357] (Decimal: [9320, 4951])
        0x57059EC3); // Result: [0x5705, 0x9EC3] (Cross Subtraction: 0x6A5C - 0x1357, Cross Addition: 0x7A5B + 0x2468)


    // Test PASA.HX (SIMD 16-bit Signed Averaging Cross Subtraction & Addition)
    TEST_INSTRUCTION("PASA.HX", "pasahx",
        0x6A5C7A5B,  // [0x6A5C, 0x7A5B] (Decimal: [27228, 31323])
        0x24681357,  // [0x2468, 0x1357] (Decimal: [9320, 4951])
        0x2B824F61); // Result: [0x2B82, 0x4F61] (Averaged results of Cross Subtraction & Addition)

    // Test PASA.HX (SIMD 16-bit Signed Averaging Cross Subtraction & Addition, Boundary Case)
    TEST_INSTRUCTION("PASA.HX", "pasahx",
        0x80007FFF,  // [0x8000, 0x7FFF] (Decimal: [-32768, 32767])
        0x7FFF7FFF,  // [0x7FFF, 0x7FFF] (Decimal: [32767, 32767])
        0x80007FFF); // No change, boundary case

    // Test PASA.HX (SIMD 16-bit Signed Averaging Cross Subtraction & Addition, Negative Case)
    TEST_INSTRUCTION("PASA.HX", "pasahx",
        0x80008000,  // [0x8000, 0x8000] (Decimal: [-32768, -32768])
        0x80004000,  // [0x8000, 0x4000] (Decimal: [-32768, 16384])
        0xA0008000); // Result: [0xA000, 0x8000] (Cross Sub & Add with averaging) 

    // Test PSSA.HX (SIMD 16-bit Saturating Cross Subtraction & Addition)
    TEST_INSTRUCTION("PSSA.HX", "pssahx",
        0x6A5C1A5B,  // [0x6A5C, 0x1A5B] (Decimal: [27228, 6747])
        0x24682357,  // [0x2468, 0x2357] (Decimal: [9320, 9047])
        0x47053EC3); // Result: [0x4705, 0x3EC3] (Cross Sub & Add without saturation)

    // Test PSSA.HX (SIMD 16-bit Saturating Cross Subtraction & Addition, Saturation Case)
    TEST_INSTRUCTION("PSSA.HX", "pssahx",
        0x80007FFF,  // [0x8000, 0x7FFF] (Decimal: [-32768, 32767])
        0x7FFF0001,  // [0x7FFF, 0x0001] (Decimal: [32767, 1])
        0x80007FFF); // Result: [0x8000, 0x7FFF] (Saturation occurs)


    // Test PMSEQ.H (16-bit Integer Compare Equal)
    TEST_INSTRUCTION("PMSEQ.H", "pmseqh",
        0x1234807F,  // [0x1234, 0x807F]
        0x1234807F,  // [0x1234, 0x807F]
        0xFFFFFFFF); // Result: [0xFFFF, 0xFFFF] (Both parts are equal)

    // Test PMSEQ.H (16-bit Integer Compare Not Equal)
    TEST_INSTRUCTION("PMSEQ.H", "pmseqh",
        0x1234807F,  // [0x1234, 0x807F]
        0x807F1234,  // [0x807F, 0x1234]
        0x00000000); // Result: [0x0000, 0x0000] (Both parts are different)

    // Test PMSLT.H (16-bit Signed Compare Less Than)
    TEST_INSTRUCTION("PMSLT.H", "pmslth",
        0x1234FFFF,  // [0x1234, 0xFFFF] (Decimal: [4660, -1])
        0x56787FFF,  // [0x5678, 0x7FFF] (Decimal: [22136, 32767])
        0xFFFFFFFF); // Result: [0xFFFF, 0xFFFF] (Both parts are true)

    // Test PMSLT.H (16-bit Signed Compare Greater Than)
    TEST_INSTRUCTION("PMSLT.H", "pmslth",
        0x7FFF7FFF,  // [0x7FFF, 0x7FFF] (Decimal: [32767, 32767])
        0xFFFF8000,  // [0xFFFF, 0x8000] (Decimal: [-1, -32768])
        0x00000000); // Result: [0x0000, 0x0000] (Both parts are false)

    // Test PMSLTU.H (16-bit Unsigned Compare Less Than)
    TEST_INSTRUCTION("PMSLTU.H", "pmsltuh",
        0x12340001,  // [0x1234, 0x0001] (Decimal: [4660, 1])
        0x56788000,  // [0x5678, 0x8000] (Decimal: [22136, 32768])
        0xFFFFFFFF); // Result: [0xFFFF, 0xFFFF] (Both parts are true)

    // Test PMSLTU.H (16-bit Unsigned Compare Greater Than)
    TEST_INSTRUCTION("PMSLTU.H", "pmsltuh",
        0x80015678,  // [0x8001, 0x5678] (Decimal: [32769, 22136])
        0x43211234,  // [0x4321, 0x1234] (Decimal: [17185, 4660])
        0x00000000); // Result: [0x0000, 0x0000] (Both parts are false)

    // Test PMSLE.H (16-bit Signed Compare Less Than or Equal)
    TEST_INSTRUCTION("PMSLE.H", "pmsleh",
        0xF2348000,  // [0xF234, 0x8000] (Decimal: [-3532, -32768])
        0xF234F000,  // [0xF234, 0xF000] (Decimal: [-3532, -4096])
        0xFFFFFFFF); // Result: [0xFFFF, 0xFFFF] (Both parts are true)

    // Test PMSLE.H (16-bit Signed Compare Less Than or Equal)
    TEST_INSTRUCTION("PMSLE.H", "pmsleh",
        0x7FFF8001,  // [0x7FFF, 0x8001] (Decimal: [32767, -32767])
        0xFFFF8001,  // [0xFFFF, 0x8001] (Decimal: [-1, -32767])
        0x0000FFFF); // Result: [0x0000, 0xFFFF] (Only lower half is true)

    // Test PMSLEU.H (16-bit Unsigned Compare Less Than or Equal)
    TEST_INSTRUCTION("PMSLEU.H", "pmsleuh",
        0x1234807F,  // [0x1234, 0x807F]
        0x1234807F,  // [0x1234, 0x807F]
        0xFFFFFFFF); // Result: [0xFFFF, 0xFFFF] (Equal values)

    // Test PMSLEU.H (16-bit Unsigned Compare Less Than or Equal)
    TEST_INSTRUCTION("PMSLEU.H", "pmsleuh",
        0x8FFF5678,  // [0x8FFF, 0x5678] (Decimal: [36863, 22136])
        0x80011234,  // [0x8001, 0x1234] (Decimal: [32769, 4660])
        0x00000000); // Result: [0x0000, 0x0000] (Both parts are false)
 

    // Test PMIN.H (16-bit Signed Minimum)
    TEST_INSTRUCTION("PMIN.H", "pminh",
        0x12348000,  // [0x1234, 0x8000] (Decimal: [4660, -32768])
        0x7FFF0001,  // [0x7FFF, 0x0001] (Decimal: [32767, 1])
        0x12348000); // Result: [0x1234, 0x8000] (Minimum of each pair: [4660, -32768])

   // Test PMIN.H (16-bit Signed Minimum)
    TEST_INSTRUCTION("PMIN.H", "pminh",
        0x7FFF0001,  // [0x7FFF, 0x0001] (Decimal: [32767, 1])
        0xE789FFFF,  // [0xE789, 0xFFFF] (Decimal: [-6295, -1])
        0xE789FFFF); // Result: [0xE789, 0xFFFF] (Minimum of each pair: [-6295, -1])

   // Test PMIN.H (16-bit Signed Minimum)
    TEST_INSTRUCTION("PMIN.H", "pminh",
        0x7FFF0001,  // [0x7FFF, 0x0001] (Decimal: [32767, 1])
        0x7FFF0001,  // [0x7FFF, 0x0001] (Decimal: [32767, 1])
        0x7FFF0001); // Result: [0x7FFF, 0x0001] (Equal values)

    // Test PMINU.H (16-bit Unsigned Minimum)
    TEST_INSTRUCTION("PMINU.H", "pminuh",
        0x12348000,  // [0x1234, 0x8000] (Decimal: [4660, 32768])
        0x7FFF0001,  // [0x7FFF, 0x0001] (Decimal: [32767, 1])
        0x12340001); // Result: [0x1234, 0x0001] (Minimum of each pair: [4660, 1])

    // Test PMINU.H (16-bit Unsigned Minimum)
    TEST_INSTRUCTION("PMINU.H", "pminuh",
        0xFFFF0001,  // [0xFFFF, 0x0001] (Decimal: [65535, 1])
        0x1234FFFF,  // [0x1234, 0xFFFF] (Decimal: [4660, 65535])
        0x12340001); // Result: [0x1234, 0x0001] (Minimum of each pair: [4660, 1])

    // Test PMAX.H (16-bit Signed Maximum)
    TEST_INSTRUCTION("PMAX.H", "pmaxh",
        0x12348000,  // [0x1234, 0x8000] (Decimal: [4660, -32768])
        0x7FFF0001,  // [0x7FFF, 0x0001] (Decimal: [32767, 1])
        0x7FFF0001); // Result: [0x7FFF, 0x0001] (Maximum of each pair: [32767, 1])

    // Test PMAX.H (16-bit Signed Maximum)
    TEST_INSTRUCTION("PMAX.H", "pmaxh",
        0x7FFF0001,  // [0x7FFF, 0x0001] (Decimal: [32767, 1])
        0xE789FFFF,  // [0xE789, 0xFFFF] (Decimal: [-6295, -1])
        0x7FFF0001); // Result: [0x7FFF, 0x0001] (Maximum of each pair: [32767, 1])

    // Test PMAX.H (16-bit Signed Maximum)
    TEST_INSTRUCTION("PMAX.H", "pmaxh",
        0x7FFF0001,  // [0x7FFF, 0x0001] (Decimal: [32767, 1])
        0x7FFF0001,  // [0x7FFF, 0x0001] (Decimal: [32767, 1])
        0x7FFF0001); // Result: [0x7FFF, 0x0001] (Equal values)

    // Test PMAXU.H (16-bit Unsigned Maximum)
    TEST_INSTRUCTION("PMAXU.H", "pmaxuh",
        0x12348000,  // [0x1234, 0x8000] (Decimal: [4660, 32768])
        0x7FFF0001,  // [0x7FFF, 0x0001] (Decimal: [32767, 1])
        0x7FFF8000); // Result: [0x7FFF, 0x8000] (Maximum of each pair: [32767, 32768])

    // Test PMAXU.H (16-bit Unsigned Maximum)
    TEST_INSTRUCTION("PMAXU.H", "pmaxuh",
        0xFFFF0001,  // [0xFFFF, 0x0001] (Decimal: [65535, 1])
        0x1234FFFF,  // [0x1234, 0xFFFF] (Decimal: [4660, 65535])
        0xFFFFFFFF); // Result: [0xFFFF, 0xFFFF] (Maximum of each pair: [65535, 65535])

    

    // Test PCLIP.H (16-bit Signed Clip Value)
    TEST_INSTRUCTION_IMM("PCLIP.H", "pcliph",
        0x12348000,  // [0x1234, 0x8000] (Decimal: [4660, -32768])
        0x003,           // imm 0011 [-8 7]
        0x0007FFF8); // Clipped result: [0x0007, 0xFFF8] (Decimal: [7, -8])

    // Test PCLIP.H (16-bit Signed Clip Value)
    TEST_INSTRUCTION_IMM("PCLIP.H", "pcliph",
        0x80001234,  // [0x8000, 0x1234] (Decimal: [-32768, 4660])
        0x003,           // imm 0011 [-8 7]
        0xFFF80007); // Clipped result: [0xFFF8, 0x0007] (Decimal: [-8, 7])

    // Test PCLIP.H (16-bit Signed Clip Value)
    TEST_INSTRUCTION_IMM("PCLIP.H", "pcliph",
        0x0004FFFF,  // [0x0004, 0xFFFF] (Decimal: [4, -1])
        0x003,           // imm 0011 [-8 7]
        0x0004FFFF); // Clipped result: [0x0004, 0xFFFF] (No clipping needed)
    
    // Test PCLIPU.H (16-bit Unsigned Clip Value)
    TEST_INSTRUCTION_IMM("PCLIPU.H", "pclipuh",
        0x12348000,  // [0x1234, 0x8000] (Decimal: [4660, 32768])
        0x003,           // imm 0011 [0 7]
        0x00070000); // Clipped result: [0x0007, 0x0000] (Decimal: [7, 0])

    // Test PCLIPU.H (16-bit Unsigned Clip Value)
    TEST_INSTRUCTION_IMM("PCLIPU.H", "pclipuh",
        0x8000F234,  // [0x8000, 0xF234] (Decimal: [32768, 62004])
        0x003,           // imm 0011 [0 7]
        0x00000000); // Clipped result: [0x0000, 0x0000] (Both clipped to zero)

    // Test PCLIPU.H (16-bit Unsigned Clip Value)
    TEST_INSTRUCTION_IMM("PCLIPU.H", "pclipuh",
        0x7FFF0005,  // [0x7FFF, 0x0001] (Decimal: [32767, 5])
        0x003,           // imm 0011 [0 7]
        0x00070005); // Clipped result: [0x0007, 0x0005] (32767 clipped to 7)

    // Test PCLIPU.H (16-bit Unsigned Clip Value)
    TEST_INSTRUCTION_IMM("PCLIPU.H", "pclipuh",
        0x00040006,  // [0x0004, 0x0006] (Decimal: [4, 6])
        0x003,  	     // imm 0011 [0 7]
        0x00040006); // No clipping needed


    // Test PABS.H (16-bit SIMD Absolute Value)
    TEST_INSTRUCTION_SINGLE("PABS.H", "pabsh",
        0x1234FFFD,  // [0x1234, 0xFFFD] (Decimal: [4660, -3])
        0x12340003); // Absolute result: [0x1234, 0x0003] (Decimal: [4660, 3])

    // Test PABS.H (16-bit SIMD Absolute Value)
    TEST_INSTRUCTION_SINGLE("PABS.H", "pabsh",
        0xFFFFFFED,  // [0xFFFF, 0xFFED] (Decimal: [-1, -19])
        0x00010013); // Absolute result: [0x0001, 0x0013] (Decimal: [1, 19])

    // Test PABS.H (16-bit SIMD Absolute Value)
    TEST_INSTRUCTION_SINGLE("PABS.H", "pabsh",
        0xFFFD1234,  // [0xFFFD, 0x1234] (Decimal: [-3, 4660])
        0x00031234); // Absolute result: [0x0003, 0x1234] (Decimal: [3, 4660])

    printf("=== RISC-V P-Extension Instruction Tests ===\n");
    printf("\nTest Summary:\n");
    printf("Passed: %d\n", tests_passed);
    printf("Failed: %d\n", tests_failed);
    if(tests_failed == 0) {
      test_pass();
    } else {
      test_fail();
    }

}
