class systolic_sequencer extends uvm_sequencer #(systolic_item);
`uvm_component_utils(systolic_sequencer)
function new(string n,uvm_component p);super.new(n,p);endfunction
endclass
