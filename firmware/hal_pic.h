// ==============================================================================
// Header: hal_pic.h
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: Platform Interrupt Controller (PIC) Hardware Abstraction Layer
// ==============================================================================

#ifndef HAL_PIC_H_
#define HAL_PIC_H_

#include <stdint.h>
#include "neuroedge_hw.h"

static inline void pic_init(uint32_t enable_mask, uint32_t priority_map) {
    PIC_REG_ENABLE   = enable_mask;
    PIC_REG_PRIORITY = priority_map;
    PIC_REG_ACK      = 0x3F; // Clear any stale pending interrupts
}

static inline void pic_enable_irq(uint32_t irq_mask) {
    PIC_REG_ENABLE |= irq_mask;
}

static inline void pic_disable_irq(uint32_t irq_mask) {
    PIC_REG_ENABLE &= ~irq_mask;
}

static inline uint32_t pic_get_pending(void) {
    return PIC_REG_PENDING;
}

static inline void pic_ack_irq(uint32_t irq_mask) {
    PIC_REG_ACK = irq_mask;
}

#endif // HAL_PIC_H_
