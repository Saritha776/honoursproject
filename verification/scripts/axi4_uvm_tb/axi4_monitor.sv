class axi4_monitor extends uvm_monitor;
virtual axi4_if vif;
uvm_analysis_port #(axi4_item) ap;
`uvm_component_utils(axi4_monitor)
function new(string n,uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
endclass
