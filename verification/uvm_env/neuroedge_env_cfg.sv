// ==============================================================================
// Class: neuroedge_env_cfg.sv
// Description: Configuration descriptor for NeuroEdge Top-Level UVM Environment
//              Configured for single GPIO VIP instantiation by default.
// ==============================================================================

`ifndef NEUROEDGE_ENV_CFG_SV
`define NEUROEDGE_ENV_CFG_SV

class neuroedge_env_cfg extends uvm_object;

    // Agent enable controls (Single GPIO VIP active by default)
    bit enable_lsu_axi        = 1'b0;
    bit enable_ifu_axi        = 1'b0;
    bit enable_wb             = 1'b0;
    bit enable_uart           = 1'b0;
    bit enable_systolic       = 1'b0;
    bit enable_spi            = 1'b0;
    bit enable_gpio           = 1'b1; // Single GPIO VIP active

    bit enable_soc_scoreboard = 1'b1;

    // Sub-VIP configurations
    axi4_cfg        lsu_axi_cfg;
    axi4_cfg        ifu_axi_cfg;
    wb_cfg          wb_cfg_inst;
    uart_cfg        uart_cfg_inst;
    systolic_cfg    systolic_cfg_inst;
    spi_flash_cfg   spi_cfg_inst;
    gpio_cfg        gpio_cfg_inst;

    `uvm_object_utils_begin(neuroedge_env_cfg)
        `uvm_field_int(enable_lsu_axi, UVM_ALL_ON)
        `uvm_field_int(enable_ifu_axi, UVM_ALL_ON)
        `uvm_field_int(enable_wb, UVM_ALL_ON)
        `uvm_field_int(enable_uart, UVM_ALL_ON)
        `uvm_field_int(enable_systolic, UVM_ALL_ON)
        `uvm_field_int(enable_spi, UVM_ALL_ON)
        `uvm_field_int(enable_gpio, UVM_ALL_ON)
        `uvm_field_object(gpio_cfg_inst, UVM_ALL_ON)
        `uvm_field_int(enable_soc_scoreboard, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "neuroedge_env_cfg");
        super.new(name);
        gpio_cfg_inst = gpio_cfg::type_id::create("gpio_cfg_inst");
    endfunction

endclass

`endif // NEUROEDGE_ENV_CFG_SV
