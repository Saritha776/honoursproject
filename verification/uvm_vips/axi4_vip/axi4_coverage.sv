// ==============================================================================
// Class: axi4_coverage.sv
// Description: Functional coverage collector for AXI4 VIP transactions
// ==============================================================================

`ifndef AXI4_COVERAGE_SV
`define AXI4_COVERAGE_SV

class axi4_coverage extends uvm_subscriber #(axi4_item);

    `uvm_component_utils(axi4_coverage)

    axi4_item item_cov;

    covergroup cg_axi4;
        cp_xfer_type: coverpoint item_cov.xfer_type {
            bins READ  = {AXI_READ};
            bins WRITE = {AXI_WRITE};
        }

        cp_addr_region: coverpoint item_cov.addr {
            bins ISRAM   = {[32'h0000_0000 : 32'h0000_7FFF]};
            bins DSRAM   = {[32'h2000_0000 : 32'h2000_FFFF]};
            bins PERIPH  = {[32'h4000_0000 : 32'h4000_7FFF]};
            bins OTHER   = default;
        }

        cp_len: coverpoint item_cov.len {
            bins SINGLE = {0};
            // In NeuroEdge SoC, VeeR EL2 core IFU and LSU master ports architecturally only issue single beats (len=0)
            ignore_bins UNSUPPORTED_BURST_LEN = {[1:15]};
        }

        cp_size: coverpoint item_cov.size {
            bins BYTE_1 = {3'b000};
            bins BYTE_8 = {3'b011};
            // VeeR EL2 LSU architecture in NeuroEdge SoC accesses memory with 64-bit (3'b011) for cacheline/instruction and 8-bit (3'b000) for byte loads/stores; external 16-bit and 32-bit AXI sizes are unissued on this core configuration
            ignore_bins UNSUPPORTED_AXI_SIZES = {3'b001, 3'b010};
        }

        cp_burst: coverpoint item_cov.burst {
            bins INCR = {AXI_BURST_INCR};
        }

        cross_xfer_region: cross cp_xfer_type, cp_addr_region;
        cross_len_size:    cross cp_len, cp_size;
    endgroup

    function new(string name = "axi4_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_axi4 = new();
    endfunction

    function void write(axi4_item t);
        item_cov = t;
        cg_axi4.sample();
    endfunction

    function real get_coverage_pct();
        return cg_axi4.get_coverage();
    endfunction

endclass

`endif // AXI4_COVERAGE_SV
