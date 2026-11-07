class wishbone_agent extends uvm_agent;
wishbone_driver drv; wishbone_monitor mon; wishbone_sequencer seqr;
`uvm_component_utils(wishbone_agent)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); drv=wishbone_driver::type_id::create("drv",this); mon=wishbone_monitor::type_id::create("mon",this); seqr=wishbone_sequencer::type_id::create("seqr",this); endfunction
function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(seqr.seq_item_export); endfunction
endclass
