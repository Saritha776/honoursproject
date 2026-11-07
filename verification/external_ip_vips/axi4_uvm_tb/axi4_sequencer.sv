class axi4_sequencer extends uvm_sequencer #(axi4_item);
`uvm_component_utils(axi4_sequencer)
function new(string n,uvm_component p);super.new(n,p);endfunction
endclass
