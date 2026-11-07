// ==============================================================================
// Package: neuroedge_seq_pkg.sv
// Description: Package containing all NeuroEdge SoC Virtual Sequences
// ==============================================================================

`ifndef NEUROEDGE_SEQ_PKG_SV
`define NEUROEDGE_SEQ_PKG_SV

package neuroedge_seq_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import axi4_pkg::*;
    import wb_pkg::*;
    import uart_pkg::*;
    import systolic_pkg::*;
    import spi_flash_pkg::*;
    import gpio_pkg::*;
    import neuroedge_uvm_pkg::*;

    `include "neuroedge_base_vseq.sv"
    `include "neuroedge_wb_memory_vseq.sv"
    `include "neuroedge_peripheral_vseq.sv"
    `include "neuroedge_systolic_vseq.sv"
    `include "neuroedge_uart_vseq.sv"
    `include "neuroedge_uart_fifo_vseq.sv"
    `include "neuroedge_error_resp_vseq.sv"
    `include "neuroedge_concurrent_vseq.sv"

endpackage

`endif // NEUROEDGE_SEQ_PKG_SV
