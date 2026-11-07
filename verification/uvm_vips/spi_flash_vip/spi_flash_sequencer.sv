// ==============================================================================
// Class: spi_flash_sequencer.sv
// Description: SPI Flash Sequencer
// ==============================================================================

`ifndef SPI_FLASH_SEQUENCER_SV
`define SPI_FLASH_SEQUENCER_SV

class spi_flash_sequencer extends uvm_sequencer #(spi_flash_item);

    `uvm_component_utils(spi_flash_sequencer)

    function new(string name = "spi_flash_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass

`endif // SPI_FLASH_SEQUENCER_SV
