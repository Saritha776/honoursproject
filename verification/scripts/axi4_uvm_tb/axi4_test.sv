class axi4_test extends uvm_test;
axi4_env env;
`uvm_component_utils(axi4_test)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); env=axi4_env::type_id::create("env",this); endfunction
endclass
