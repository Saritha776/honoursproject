// ==============================================================================
// Header: hal_systolic.h
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: 4x4 Systolic Array Hardware Abstraction Layer
// ==============================================================================

#ifndef HAL_SYSTOLIC_H_
#define HAL_SYSTOLIC_H_

#include <stdint.h>

void systolic_init(void);
void systolic_clear_accumulators(void);
void systolic_load_weights_direct(const int8_t weights[4][4]);
void systolic_feed_activations_direct(const int8_t activations[4]);
void systolic_trigger(void);
int  systolic_wait_done(void);
void systolic_read_results(int32_t results[4]);

#endif // HAL_SYSTOLIC_H_
