// ==============================================================================
// Package: axi4_pkg.sv
// Description: Top-level package for AXI4 VIP
// ==============================================================================

`ifndef AXI4_PKG_SV
`define AXI4_PKG_SV

package axi4_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "axi4_item.sv"
    `include "axi4_cfg.sv"
    `include "axi4_sequencer.sv"
    `include "axi4_driver.sv"
    `include "axi4_monitor.sv"
    `include "axi4_coverage.sv"
    `include "axi4_scoreboard.sv"
    `include "axi4_agent.sv"

endpackage

`endif // AXI4_PKG_SV
