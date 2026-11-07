class spi_flash_env extends uvm_env;
spi_flash_agent agent; spi_flash_scoreboard sb;
`uvm_component_utils(spi_flash_env)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); agent=spi_flash_agent::type_id::create("agent",this); sb=spi_flash_scoreboard::type_id::create("sb",this); endfunction
endclass
