class wishbone_monitor extends uvm_monitor;
virtual wishbone_if vif;
uvm_analysis_port #(wishbone_item) ap;
`uvm_component_utils(wishbone_monitor)
function new(string n,uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
endclass
