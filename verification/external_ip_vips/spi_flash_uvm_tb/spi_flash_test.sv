class spi_flash_test extends uvm_test;
spi_flash_env env;
`uvm_component_utils(spi_flash_test)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); env=spi_flash_env::type_id::create("env",this); endfunction
endclass
