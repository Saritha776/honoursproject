// ==============================================================================
// Source: hal_spi.c
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: SPI Flash Controller Driver Implementation
// ==============================================================================

#include "neuroedge_hw.h"
#include "hal_spi.h"

void spi_init(uint8_t clk_divisor) {
    SPI_REG_CLKDIV = (uint32_t)clk_divisor;
    SPI_REG_STATUS = SPI_STATUS_DONE; // Clear W1C
}

int spi_is_busy(void) {
    return (SPI_REG_STATUS & SPI_STATUS_BUSY) ? 1 : 0;
}

void spi_stream_flash_to_sram(uint32_t flash_addr, uint16_t byte_len) {
    while (spi_is_busy());

    // Program flash address (bits [23:0]) and command byte (0x03 Standard Read)
    SPI_REG_FLASH_ADDR = (0x03U << 24) | (flash_addr & 0x00FFFFFFU);
    SPI_REG_LENGTH     = (uint32_t)byte_len;

    // Clear done flag & trigger auto-read stream directly into DSRAM 0x2000_8000
    SPI_REG_STATUS     = SPI_STATUS_DONE;
    SPI_REG_CTRL       = SPI_CTRL_EN | SPI_CTRL_AUTO_READ | SPI_CTRL_START;
}

void spi_wait_done(void) {
    while (!(SPI_REG_STATUS & SPI_STATUS_DONE));
    SPI_REG_STATUS = SPI_STATUS_DONE; // Clear done
}
