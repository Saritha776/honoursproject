class systolic_test extends uvm_test;
systolic_env env;
`uvm_component_utils(systolic_test)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); env=systolic_env::type_id::create("env",this); endfunction
endclass
