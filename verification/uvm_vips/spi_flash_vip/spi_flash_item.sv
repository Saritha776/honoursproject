// ==============================================================================
// Class: spi_flash_item.sv
// Description: SPI Flash Transaction Item
// ==============================================================================

`ifndef SPI_FLASH_ITEM_SV
`define SPI_FLASH_ITEM_SV

class spi_flash_item extends uvm_sequence_item;

    rand bit [7:0]  cmd;
    rand bit [23:0] addr;
    rand bit [7:0]  data[];

    `uvm_object_utils_begin(spi_flash_item)
        `uvm_field_int(cmd, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(addr, UVM_ALL_ON | UVM_HEX)
        `uvm_field_array_int(data, UVM_ALL_ON | UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "spi_flash_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("SPI Flash: CMD=0x%02h Addr=0x%06h Bytes=%0d", cmd, addr, data.size());
    endfunction

endclass

`endif // SPI_FLASH_ITEM_SV
