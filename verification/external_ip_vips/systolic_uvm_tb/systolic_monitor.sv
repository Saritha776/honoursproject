class systolic_monitor extends uvm_monitor;
virtual systolic_if vif;
uvm_analysis_port #(systolic_item) ap;
`uvm_component_utils(systolic_monitor)
function new(string n,uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
endclass
