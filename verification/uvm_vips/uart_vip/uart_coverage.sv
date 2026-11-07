// ==============================================================================
// Class: uart_coverage.sv
// Description: Functional coverage for UART stream
// ==============================================================================

`ifndef UART_COVERAGE_SV
`define UART_COVERAGE_SV

class uart_coverage extends uvm_subscriber #(uart_item);

    `uvm_component_utils(uart_coverage)

    uart_item item_cov;

    covergroup cg_uart;
        cp_data_range: coverpoint item_cov.data {
            bins CONTROL_CHARS = {[8'h00 : 8'h1F]};
            bins PRINTABLE     = {[8'h20 : 8'h7E]};
            bins EXTENDED      = {[8'h80 : 8'hFF]};
        }

        cp_specific_chars: coverpoint item_cov.data {
            bins NEWLINE = {8'h0A};
            bins CR      = {8'h0D};
            bins SPACE   = {8'h20};
            bins EQUALS  = {8'h3D};
            bins LBRACKET= {8'h5B};
            bins RBRACKET= {8'h5D};
        }

        cp_frame_err: coverpoint item_cov.frame_err {
            bins NO_ERROR = {1'b0};
            bins ERROR    = {1'b1};
        }
    endgroup

    function new(string name = "uart_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_uart = new();
    endfunction

    function void write(uart_item t);
        item_cov = t;
        cg_uart.sample();
    endfunction

    function real get_coverage_pct();
        return cg_uart.get_coverage();
    endfunction

endclass

`endif // UART_COVERAGE_SV
