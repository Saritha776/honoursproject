// ==============================================================================
// Package: systolic_pkg.sv
// Description: Top-level package for Systolic Array VIP
// ==============================================================================

`ifndef SYSTOLIC_PKG_SV
`define SYSTOLIC_PKG_SV

package systolic_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "systolic_item.sv"
    `include "systolic_cfg.sv"
    `include "systolic_sequencer.sv"
    `include "systolic_driver.sv"
    `include "systolic_monitor.sv"
    `include "systolic_coverage.sv"
    `include "systolic_scoreboard.sv"
    `include "systolic_agent.sv"

endpackage

`endif // SYSTOLIC_PKG_SV
