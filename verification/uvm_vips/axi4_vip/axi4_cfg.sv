// ==============================================================================
// Class: axi4_cfg.sv
// Description: Configuration object for AXI4 Agent
// ==============================================================================

`ifndef AXI4_CFG_SV
`define AXI4_CFG_SV

class axi4_cfg extends uvm_object;

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    bit                     is_master = 1'b1;
    int                     id_width  = 8;
    int                     data_width= 64;
    int                     addr_width= 32;

    bit                     enable_coverage = 1'b1;
    bit                     enable_assertions = 1'b1;

    `uvm_object_utils_begin(axi4_cfg)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
        `uvm_field_int(is_master, UVM_ALL_ON)
        `uvm_field_int(id_width, UVM_ALL_ON)
        `uvm_field_int(data_width, UVM_ALL_ON)
        `uvm_field_int(addr_width, UVM_ALL_ON)
        `uvm_field_int(enable_coverage, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi4_cfg");
        super.new(name);
    endfunction

endclass

`endif // AXI4_CFG_SV
