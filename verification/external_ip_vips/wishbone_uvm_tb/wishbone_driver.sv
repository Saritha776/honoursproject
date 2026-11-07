class wishbone_driver extends uvm_driver #(wishbone_item);
virtual wishbone_if vif;
`uvm_component_utils(wishbone_driver)
function new(string n,uvm_component p);super.new(n,p);endfunction
task run_phase(uvm_phase phase); forever begin seq_item_port.get_next_item(req); @(posedge vif.clk); seq_item_port.item_done(); end endtask
endclass
