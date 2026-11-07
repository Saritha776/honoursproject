// ==============================================================================
// Class: wb_cfg.sv
// Description: Configuration object for Wishbone VIP
// ==============================================================================

`ifndef WB_CFG_SV
`define WB_CFG_SV

class wb_cfg extends uvm_object;

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    bit                     is_master = 1'b1;
    bit                     enable_coverage = 1'b1;
    bit                     enable_assertions = 1'b1;
    int                     timeout_cycles = 64;

    `uvm_object_utils_begin(wb_cfg)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
        `uvm_field_int(is_master, UVM_ALL_ON)
        `uvm_field_int(enable_coverage, UVM_ALL_ON)
        `uvm_field_int(timeout_cycles, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "wb_cfg");
        super.new(name);
    endfunction

endclass

`endif // WB_CFG_SV
