class wishbone_sequencer extends uvm_sequencer #(wishbone_item);
`uvm_component_utils(wishbone_sequencer)
function new(string n,uvm_component p);super.new(n,p);endfunction
endclass
