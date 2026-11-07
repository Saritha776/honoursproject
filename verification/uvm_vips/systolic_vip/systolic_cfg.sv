// ==============================================================================
// Class: systolic_cfg.sv
// Description: Configuration object for Systolic Array VIP
// ==============================================================================

`ifndef SYSTOLIC_CFG_SV
`define SYSTOLIC_CFG_SV

class systolic_cfg extends uvm_object;

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    bit                     enable_coverage = 1'b1;

    `uvm_object_utils_begin(systolic_cfg)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
        `uvm_field_int(enable_coverage, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "systolic_cfg");
        super.new(name);
    endfunction

endclass

`endif // SYSTOLIC_CFG_SV
