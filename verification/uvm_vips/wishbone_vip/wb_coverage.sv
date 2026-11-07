// ==============================================================================
// Class: wb_coverage.sv
// Description: Functional coverage collector for Wishbone VIP transactions
// ==============================================================================

`ifndef WB_COVERAGE_SV
`define WB_COVERAGE_SV

class wb_coverage extends uvm_subscriber #(wb_item);

    `uvm_component_utils(wb_coverage)

    wb_item item_cov;

    covergroup cg_wb;
        cp_op: coverpoint item_cov.op {
            bins READ  = {WB_READ};
            bins WRITE = {WB_WRITE};
        }

        cp_slaves: coverpoint item_cov.addr {
            bins ISRAM   = {[32'h0000_0000 : 32'h0000_7FFF]};
            bins DSRAM   = {[32'h2000_0000 : 32'h2000_FFFF]};
            bins SPI     = {[32'h4000_0000 : 32'h4000_001F]};
            bins DMA     = {[32'h4000_1000 : 32'h4000_102F]};
            bins ARRAY   = {[32'h4000_2000 : 32'h4000_203F]};
            bins UART    = {[32'h4000_3000 : 32'h4000_301F]};
            bins TIMER   = {[32'h4000_4000 : 32'h4000_400F]};
            bins WDT     = {[32'h4000_5000 : 32'h4000_500F]};
            bins GPIO    = {[32'h4000_6000 : 32'h4000_600F]};
            bins PIC     = {[32'h4000_7000 : 32'h4000_700F]};
            bins UNMAPPED= default;
        }

        cp_sel: coverpoint item_cov.sel {
            bins FULL_WORD = {4'b1111};
            bins LOWER_HW  = {4'b0011};
            bins UPPER_HW  = {4'b1100};
            bins BYTE_0    = {4'b0001};
            bins BYTE_1    = {4'b0010};
            bins BYTE_2    = {4'b0100};
            bins BYTE_3    = {4'b1000};
        }

        cp_resp: coverpoint item_cov.err {
            bins ACK = {1'b0};
            bins ERR = {1'b1};
        }

        cross_op_slave: cross cp_op, cp_slaves;
        cross_op_sel:   cross cp_op, cp_sel;
    endgroup

    function new(string name = "wb_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_wb = new();
    endfunction

    function void write(wb_item t);
        item_cov = t;
        cg_wb.sample();
    endfunction

    function real get_coverage_pct();
        return cg_wb.get_coverage();
    endfunction

endclass

`endif // WB_COVERAGE_SV
