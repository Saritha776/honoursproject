// ==============================================================================
// Class: uart_cfg.sv
// Description: Configuration object for UART VIP
// ==============================================================================

`ifndef UART_CFG_SV
`define UART_CFG_SV

class uart_cfg extends uvm_object;

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    real                    bit_period_ns = 340.0; // 17 cycles * 20ns for baud_div = 16 @ 50MHz
    bit                     enable_coverage = 1'b1;

    `uvm_object_utils_begin(uart_cfg)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
        `uvm_field_real(bit_period_ns, UVM_ALL_ON)
        `uvm_field_int(enable_coverage, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "uart_cfg");
        super.new(name);
    endfunction

endclass

`endif // UART_CFG_SV
