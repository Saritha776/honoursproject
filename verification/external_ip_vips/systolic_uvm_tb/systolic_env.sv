class systolic_env extends uvm_env;
systolic_agent agent; systolic_scoreboard sb;
`uvm_component_utils(systolic_env)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); agent=systolic_agent::type_id::create("agent",this); sb=systolic_scoreboard::type_id::create("sb",this); endfunction
endclass
