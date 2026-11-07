class wishbone_test extends uvm_test;
wishbone_env env;
`uvm_component_utils(wishbone_test)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); env=wishbone_env::type_id::create("env",this); endfunction
endclass
