class systolic_agent extends uvm_agent;
systolic_driver drv; systolic_monitor mon; systolic_sequencer seqr;
`uvm_component_utils(systolic_agent)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); drv=systolic_driver::type_id::create("drv",this); mon=systolic_monitor::type_id::create("mon",this); seqr=systolic_sequencer::type_id::create("seqr",this); endfunction
function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(seqr.seq_item_export); endfunction
endclass
