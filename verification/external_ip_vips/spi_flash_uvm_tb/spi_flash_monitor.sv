class spi_flash_monitor extends uvm_monitor;
virtual spi_flash_if vif;
uvm_analysis_port #(spi_flash_item) ap;
`uvm_component_utils(spi_flash_monitor)
function new(string n,uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
endclass
