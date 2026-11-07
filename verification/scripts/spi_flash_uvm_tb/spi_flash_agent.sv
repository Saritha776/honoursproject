class spi_flash_agent extends uvm_agent;
spi_flash_driver drv; spi_flash_monitor mon; spi_flash_sequencer seqr;
`uvm_component_utils(spi_flash_agent)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); drv=spi_flash_driver::type_id::create("drv",this); mon=spi_flash_monitor::type_id::create("mon",this); seqr=spi_flash_sequencer::type_id::create("seqr",this); endfunction
function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(seqr.seq_item_export); endfunction
endclass
