// ==============================================================================
// Package: wb_pkg.sv
// Description: Top-level package for Wishbone VIP
// ==============================================================================

`ifndef WB_PKG_SV
`define WB_PKG_SV

package wb_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "wb_item.sv"
    `include "wb_cfg.sv"
    `include "wb_sequencer.sv"
    `include "wb_driver.sv"
    `include "wb_monitor.sv"
    `include "wb_coverage.sv"
    `include "wb_scoreboard.sv"
    `include "wb_agent.sv"

endpackage

`endif // WB_PKG_SV
