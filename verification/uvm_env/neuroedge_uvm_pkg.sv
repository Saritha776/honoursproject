// ==============================================================================
// Package: neuroedge_uvm_pkg.sv
// Description: NeuroEdge Top-Level UVM Package
// ==============================================================================

`ifndef NEUROEDGE_UVM_PKG_SV
`define NEUROEDGE_UVM_PKG_SV

package neuroedge_uvm_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import axi4_pkg::*;
    import wb_pkg::*;
    import uart_pkg::*;
    import systolic_pkg::*;
    import spi_flash_pkg::*;
    import gpio_pkg::*;

    `include "neuroedge_env_cfg.sv"
    `include "neuroedge_virtual_sequencer.sv"
    `include "neuroedge_scoreboard.sv"
    `include "neuroedge_env.sv"

endpackage

`endif // NEUROEDGE_UVM_PKG_SV
