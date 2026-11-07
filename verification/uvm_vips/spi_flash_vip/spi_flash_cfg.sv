// ==============================================================================
// Class: spi_flash_cfg.sv
// Description: Configuration object for SPI Flash VIP
// ==============================================================================

`ifndef SPI_FLASH_CFG_SV
`define SPI_FLASH_CFG_SV

class spi_flash_cfg extends uvm_object;

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    bit                     enable_coverage = 1'b1;
    int                     flash_size_bytes = 65536;

    `uvm_object_utils_begin(spi_flash_cfg)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
        `uvm_field_int(enable_coverage, UVM_ALL_ON)
        `uvm_field_int(flash_size_bytes, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "spi_flash_cfg");
        super.new(name);
    endfunction

endclass

`endif // SPI_FLASH_CFG_SV
