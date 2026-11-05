// ==============================================================================
// Header: hal_timer.h
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// ==============================================================================

#ifndef HAL_TIMER_H_
#define HAL_TIMER_H_

#include <stdint.h>
#include "neuroedge_hw.h"

static inline void timer_init(uint32_t compare_val, int auto_reload) {
    TIMER_REG_CNT = 0;
    TIMER_REG_CMP = compare_val;
    TIMER_REG_CTRL = TIMER_CTRL_EN | (auto_reload ? TIMER_CTRL_AUTO_RELOAD : 0);
}

static inline uint32_t timer_get_count(void) {
    return TIMER_REG_CNT;
}

static inline void timer_delay_cycles(uint32_t cycles) {
    uint32_t start = TIMER_REG_CNT;
    while ((TIMER_REG_CNT - start) < cycles);
}

#endif // HAL_TIMER_H_
