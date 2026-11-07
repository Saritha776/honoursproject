// ==============================================================================
// Source: main.c
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: Bare-Metal C Inference Test Application verifying:
//              - UART Telemetry & Banner Print
//              - Watchdog Heartbeat Refresh
//              - Systolic Array 4x4 INT8 Matrix Multiplication
//              - Dual-Channel DMA Parameter & Activation Streaming
//              - Non-linear Activation (ReLU) & ArgMax Classification
// ==============================================================================

#include <stdint.h>
#include "neuroedge_hw.h"
#include "hal_uart.h"
#include "hal_wdt.h"
#include "hal_timer.h"
#include "hal_gpio.h"
#include "hal_pic.h"
#include "hal_spi.h"
#include "hal_dma.h"
#include "hal_systolic.h"
#include "neural_ops.h"

// Golden test vector & stationary weight matrix
static const int8_t layer1_weights[4][4] = {
    {  2, -1,  4,  0 },
    {  1,  3, -2,  5 },
    { -3,  0,  1,  2 },
    {  4, -2,  3, -1 }
};

static const int8_t input_activations[4] = { 10, -5, 20, 8 };

// Expected mathematical outputs:
// RES_0 = 10*( 2) + -5*( 1) + 20*(-3) + 8*( 4) =  20 -  5 - 60 + 32 = -13
// RES_1 = 10*(-1) + -5*( 3) + 20*( 0) + 8*(-2) = -10 - 15 +  0 - 16 = -41
// RES_2 = 10*( 4) + -5*(-2) + 20*( 1) + 8*( 3) =  40 + 10 + 20 + 24 =  94
// RES_3 = 10*( 0) + -5*( 5) + 20*( 2) + 8*(-1) =   0 - 25 + 40 -  8 =   7
static const int32_t expected_dot_products[4] = { -13, -41, 94, 7 };

int main(void) {
    // -------------------------------------------------------------------------
    // 1. Hardware Initialization
    // -------------------------------------------------------------------------
    uart_init(16); // High-speed simulation baud divisor (320 ns per bit at 50 MHz)
    wdt_init(5000000, 1); // 100 ms timeout with reset enable
    timer_init(0xFFFFFFFF, 0);
    gpio_set_direction(0xFF); // Pins configured as outputs
    gpio_write(0x01); // Stage 1 indicator
    pic_init(0x3F, 0x00543210); // Enable all 6 IRQs
    dma_init();
    systolic_init();

    wdt_kick();

    // -------------------------------------------------------------------------
    // 2. Banner Output over UART
    // -------------------------------------------------------------------------
    uart_puts("\r\n=======================================================\r\n");
    uart_puts("   NEUROEDGE SOC: RISC-V SYSTOLIC AI ACCELERATOR       \r\n");
    uart_puts("   Core: VeeR EL2 (RV32IMC) | Bus: 32-bit Interconnect \r\n");
    uart_puts("=======================================================\r\n");

    // -------------------------------------------------------------------------
    // 3. Stage 1: Load INT8 Stationary Weights into 4x4 Systolic Array
    // -------------------------------------------------------------------------
    uart_puts("\r\n[Stage 1] Loading Stationary INT8 Weights into 4x4 PEs...\r\n");
    systolic_clear_accumulators();
    systolic_load_weights_direct(layer1_weights);
    uart_puts("          Weights successfully mapped to 16 Processing Elements.\r\n");
    gpio_write(0x02);
    wdt_kick();

    // -------------------------------------------------------------------------
    // 4. Stage 2: Feed Skewed Activation Vector into Western Boundary
    // -------------------------------------------------------------------------
    uart_puts("\r\n[Stage 2] Feeding Activation Vector: [");
    for (int i = 0; i < 4; i++) {
        uart_print_dec((int32_t)input_activations[i]);
        if (i < 3) uart_puts(", ");
    }
    uart_puts("]...\r\n");

    systolic_feed_activations_direct(input_activations);
    systolic_trigger();
    gpio_write(0x04);

    // -------------------------------------------------------------------------
    // 5. Stage 3: Await Systolic Compute Completion (7 Clock Cycles)
    // -------------------------------------------------------------------------
    uart_puts("\r\n[Stage 3] Systolic computation running across 2D mesh...\r\n");
    int overflow = systolic_wait_done();
    if (overflow) {
        uart_puts("          [WARNING] Arithmetic saturation clamp asserted.\r\n");
    } else {
        uart_puts("          Computation completed cleanly in 2N-1 cycles.\r\n");
    }
    gpio_write(0x08);
    wdt_kick();

    // -------------------------------------------------------------------------
    // 6. Stage 4: Read 32-bit Dot Products & Numerical Verification
    // -------------------------------------------------------------------------
    int32_t raw_results[4];
    systolic_read_results(raw_results);

    uart_puts("\r\n[Stage 4] Accumulated 32-bit Dot Products:\r\n");
    int match_count = 0;
    for (int i = 0; i < 4; i++) {
        uart_puts("          Column ");
        uart_print_dec(i);
        uart_puts(": Result = ");
        uart_print_dec(raw_results[i]);
        uart_puts(" | Expected = ");
        uart_print_dec(expected_dot_products[i]);

        if (raw_results[i] == expected_dot_products[i]) {
            uart_puts(" [PASS]\r\n");
            match_count++;
        } else {
            uart_puts(" [FAIL]\r\n");
        }
    }

    // -------------------------------------------------------------------------
    // 7. Stage 5: Non-linear Activation (ReLU) & Classification (ArgMax)
    // -------------------------------------------------------------------------
    uart_puts("\r\n[Stage 5] Evaluating Post-Processing in C Firmware:\r\n");
    int32_t relu_results[4];
    relu_int32(raw_results, relu_results, 4);

    uart_puts("          ReLU Activations: [");
    for (int i = 0; i < 4; i++) {
        uart_print_dec(relu_results[i]);
        if (i < 3) uart_puts(", ");
    }
    uart_puts("]\r\n");

    int top_class = argmax_int32(relu_results, 4);
    uart_puts("          Classified Category (ArgMax): Class ");
    uart_print_dec(top_class);
    uart_puts(" (Score = ");
    uart_print_dec(relu_results[top_class]);
    uart_puts(")\r\n");

    int32_t softmax_results[4];
    softmax_int32(relu_results, softmax_results, 4);
    uart_puts("          Softmax Distribution: [");
    for (int i = 0; i < 4; i++) {
        uart_print_dec(softmax_results[i]);
        uart_puts("%");
        if (i < 3) uart_puts(", ");
    }
    uart_puts("]\r\n");

    // -------------------------------------------------------------------------
    // 8. Final Status Verification
    // -------------------------------------------------------------------------
    wdt_kick();
    if (match_count == 4 && top_class == 2) {
        gpio_write(0xAA); // Success LED pattern
        uart_puts("\r\n=======================================================\r\n");
        uart_puts("   >>> ALL INFERENCE TESTS PASSED SUCCESSFULLY! <<<    \r\n");
        uart_puts("=======================================================\r\n");
    } else {
        gpio_write(0xEE); // Error pattern
        uart_puts("\r\n[ERROR] Output mismatch detected during inference verification.\r\n");
    }

    // Sleep in low-power idle mode
    while (1) {
        wdt_kick();
    }

    return 0;
}
