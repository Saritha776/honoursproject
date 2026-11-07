class spi_flash_item extends uvm_sequence_item;

  bit sclk;
  bit mosi;
  rand bit miso;
  bit cs_n;

  `uvm_object_utils(spi_flash_item)

  function new(string name="spi_flash_item"); super.new(name); endfunction
endclass
