// ==============================================================================
// Header: hal_spi.h
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: SPI Flash Controller Hardware Abstraction Layer
// ==============================================================================

#ifndef HAL_SPI_H_
#define HAL_SPI_H_

#include <stdint.h>

void spi_init(uint8_t clk_divisor);
void spi_stream_flash_to_sram(uint32_t flash_addr, uint16_t byte_len);
int  spi_is_busy(void);
void spi_wait_done(void);

#endif // HAL_SPI_H_
