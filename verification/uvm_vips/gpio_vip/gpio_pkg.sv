// ==============================================================================
// Package: gpio_pkg.sv
// Description: Top-level package for GPIO VIP
// ==============================================================================

`ifndef GPIO_PKG_SV
`define GPIO_PKG_SV

package gpio_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "gpio_item.sv"
    `include "gpio_cfg.sv"
    `include "gpio_sequencer.sv"
    `include "gpio_driver.sv"
    `include "gpio_monitor.sv"
    `include "gpio_coverage.sv"
    `include "gpio_scoreboard.sv"
    `include "gpio_agent.sv"

endpackage

`endif // GPIO_PKG_SV
