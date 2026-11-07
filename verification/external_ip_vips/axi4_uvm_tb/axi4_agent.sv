class axi4_agent extends uvm_agent;
axi4_driver drv; axi4_monitor mon; axi4_sequencer seqr;
`uvm_component_utils(axi4_agent)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); drv=axi4_driver::type_id::create("drv",this); mon=axi4_monitor::type_id::create("mon",this); seqr=axi4_sequencer::type_id::create("seqr",this); endfunction
function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(seqr.seq_item_export); endfunction
endclass
