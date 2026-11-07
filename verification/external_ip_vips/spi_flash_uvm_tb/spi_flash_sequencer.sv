class spi_flash_sequencer extends uvm_sequencer #(spi_flash_item);
`uvm_component_utils(spi_flash_sequencer)
function new(string n,uvm_component p);super.new(n,p);endfunction
endclass
