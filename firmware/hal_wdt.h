// ==============================================================================
// Header & Source: hal_wdt.h
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// ==============================================================================

#ifndef HAL_WDT_H_
#define HAL_WDT_H_

#include <stdint.h>
#include "neuroedge_hw.h"

static inline void wdt_init(uint32_t timeout_cycles, int enable_reset) {
    WDT_REG_TIMEOUT = timeout_cycles;
    WDT_REG_CTRL = WDT_CTRL_EN | (enable_reset ? WDT_CTRL_RESET_EN : 0);
    WDT_REG_KICK = WDT_KEY_RELOAD;
}

static inline void wdt_kick(void) {
    WDT_REG_KICK = WDT_KEY_RELOAD;
}

#endif // HAL_WDT_H_
