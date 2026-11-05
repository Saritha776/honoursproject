// ==============================================================================
// Header: hal_gpio.h
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// ==============================================================================

#ifndef HAL_GPIO_H_
#define HAL_GPIO_H_

#include <stdint.h>
#include "neuroedge_hw.h"

static inline void gpio_set_direction(uint8_t dir_mask) {
    GPIO_REG_DIR = (uint32_t)dir_mask;
}

static inline void gpio_write(uint8_t val) {
    GPIO_REG_OUT = (uint32_t)val;
}

static inline uint8_t gpio_read(void) {
    return (uint8_t)(GPIO_REG_IN & 0xFF);
}

#endif // HAL_GPIO_H_
