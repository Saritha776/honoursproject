// ==============================================================================
// Package: neuroedge_test_pkg.sv
// Description: Package containing all NeuroEdge UVM Tests
// ==============================================================================

`ifndef NEUROEDGE_TEST_PKG_SV
`define NEUROEDGE_TEST_PKG_SV

package neuroedge_test_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import axi4_pkg::*;
    import wb_pkg::*;
    import uart_pkg::*;
    import systolic_pkg::*;
    import spi_flash_pkg::*;
    import gpio_pkg::*;
    import neuroedge_uvm_pkg::*;
    import neuroedge_seq_pkg::*;

    `include "neuroedge_base_test.sv"
    `include "neuroedge_firmware_test.sv"
    `include "neuroedge_systolic_test.sv"
    `include "neuroedge_wb_access_test.sv"
    `include "neuroedge_uart_test.sv"
    `include "neuroedge_concurrent_test.sv"
    `include "neuroedge_error_resp_test.sv"

endpackage

`endif // NEUROEDGE_TEST_PKG_SV
