// ==============================================================================
// Class: gpio_cfg.sv
// Description: Configuration object for GPIO VIP
// ==============================================================================

`ifndef GPIO_CFG_SV
`define GPIO_CFG_SV

class gpio_cfg extends uvm_object;

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    bit                     enable_coverage = 1'b1;

    `uvm_object_utils_begin(gpio_cfg)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
        `uvm_field_int(enable_coverage, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "gpio_cfg");
        super.new(name);
    endfunction

endclass

`endif // GPIO_CFG_SV
