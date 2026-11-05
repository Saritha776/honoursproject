// ==============================================================================
// Source: hal_systolic.c
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: 4x4 Systolic Array Driver Implementation
// ==============================================================================

#include "neuroedge_hw.h"
#include "hal_systolic.h"

void systolic_init(void) {
    ARRAY_REG_CFG    = 0x40; // Mode 00 (Weight-Stationary), Dim 4 (4x4)
    ARRAY_REG_CTRL   = ARRAY_CTRL_EN;
    ARRAY_REG_STATUS = ARRAY_STATUS_DONE | ARRAY_STATUS_OVERFLOW; // Clear W1C
}

void systolic_clear_accumulators(void) {
    ARRAY_REG_CTRL |= ARRAY_CTRL_CLEAR_ACC;
}

void systolic_load_weights_direct(const int8_t weights[4][4]) {
    // Pack 4 rows of 4 INT8 weights into 32-bit words
    for (int r = 0; r < 4; r++) {
        uint32_t packed_word = ((uint32_t)(uint8_t)weights[r][0])       |
                               (((uint32_t)(uint8_t)weights[r][1]) << 8)  |
                               (((uint32_t)(uint8_t)weights[r][2]) << 16) |
                               (((uint32_t)(uint8_t)weights[r][3]) << 24);
        ARRAY_REG_WEIGHT_PORT = packed_word;
    }
}

void systolic_feed_activations_direct(const int8_t activations[4]) {
    uint32_t packed_act = ((uint32_t)(uint8_t)activations[0])       |
                          (((uint32_t)(uint8_t)activations[1]) << 8)  |
                          (((uint32_t)(uint8_t)activations[2]) << 16) |
                          (((uint32_t)(uint8_t)activations[3]) << 24);
    ARRAY_REG_ACT_PORT = packed_act;
}

void systolic_trigger(void) {
    ARRAY_REG_CTRL |= ARRAY_CTRL_START;
}

int systolic_wait_done(void) {
    while (!(ARRAY_REG_STATUS & ARRAY_STATUS_DONE));
    int overflow = (ARRAY_REG_STATUS & ARRAY_STATUS_OVERFLOW) ? 1 : 0;
    ARRAY_REG_STATUS = ARRAY_STATUS_DONE; // Clear done flag
    return overflow;
}

void systolic_read_results(int32_t results[4]) {
    results[0] = ARRAY_REG_RES_0;
    results[1] = ARRAY_REG_RES_1;
    results[2] = ARRAY_REG_RES_2;
    results[3] = ARRAY_REG_RES_3;
}
