// ==============================================================================
// Package: spi_flash_pkg.sv
// Description: Top-level package for SPI Flash VIP
// ==============================================================================

`ifndef SPI_FLASH_PKG_SV
`define SPI_FLASH_PKG_SV

package spi_flash_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "spi_flash_item.sv"
    `include "spi_flash_cfg.sv"
    `include "spi_flash_sequencer.sv"
    `include "spi_flash_driver.sv"
    `include "spi_flash_monitor.sv"
    `include "spi_flash_coverage.sv"
    `include "spi_flash_scoreboard.sv"
    `include "spi_flash_agent.sv"

endpackage

`endif // SPI_FLASH_PKG_SV
