// ==============================================================================
// Class: neuroedge_env_cfg.sv
// Description: Configuration descriptor for NeuroEdge Top-Level UVM Environment
// ==============================================================================

`ifndef NEUROEDGE_ENV_CFG_SV
`define NEUROEDGE_ENV_CFG_SV

class neuroedge_env_cfg extends uvm_object;

    // Sub-VIP configurations
    axi4_cfg        lsu_axi_cfg;
    axi4_cfg        ifu_axi_cfg;
    wb_cfg          wb_cfg_inst;
    uart_cfg        uart_cfg_inst;
    systolic_cfg    systolic_cfg_inst;
    spi_flash_cfg   spi_cfg_inst;
    gpio_cfg        gpio_cfg_inst;

    bit             enable_soc_scoreboard = 1'b1;

    `uvm_object_utils_begin(neuroedge_env_cfg)
        `uvm_field_object(lsu_axi_cfg, UVM_ALL_ON)
        `uvm_field_object(ifu_axi_cfg, UVM_ALL_ON)
        `uvm_field_object(wb_cfg_inst, UVM_ALL_ON)
        `uvm_field_object(uart_cfg_inst, UVM_ALL_ON)
        `uvm_field_object(systolic_cfg_inst, UVM_ALL_ON)
        `uvm_field_object(spi_cfg_inst, UVM_ALL_ON)
        `uvm_field_object(gpio_cfg_inst, UVM_ALL_ON)
        `uvm_field_int(enable_soc_scoreboard, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "neuroedge_env_cfg");
        super.new(name);

        lsu_axi_cfg = axi4_cfg::type_id::create("lsu_axi_cfg");
        lsu_axi_cfg.is_active = UVM_PASSIVE; // Monitored from VeeR CPU

        ifu_axi_cfg = axi4_cfg::type_id::create("ifu_axi_cfg");
        ifu_axi_cfg.is_active = UVM_PASSIVE; // Monitored from VeeR CPU

        wb_cfg_inst = wb_cfg::type_id::create("wb_cfg_inst");
        wb_cfg_inst.is_active = UVM_ACTIVE;  // Drives external CPU bus port when cpu_override=1

        uart_cfg_inst = uart_cfg::type_id::create("uart_cfg_inst");
        uart_cfg_inst.bit_period_ns = 340.0; // 50 MHz clock with baud_div=16

        systolic_cfg_inst = systolic_cfg::type_id::create("systolic_cfg_inst");
        spi_cfg_inst      = spi_flash_cfg::type_id::create("spi_cfg_inst");
        gpio_cfg_inst     = gpio_cfg::type_id::create("gpio_cfg_inst");
    endfunction

endclass

`endif // NEUROEDGE_ENV_CFG_SV
