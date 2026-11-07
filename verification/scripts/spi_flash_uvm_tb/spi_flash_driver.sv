class spi_flash_driver extends uvm_driver #(spi_flash_item);
virtual spi_flash_if vif;
`uvm_component_utils(spi_flash_driver)
function new(string n,uvm_component p);super.new(n,p);endfunction
task run_phase(uvm_phase phase); forever begin seq_item_port.get_next_item(req); @(posedge vif.clk); seq_item_port.item_done(); end endtask
endclass
