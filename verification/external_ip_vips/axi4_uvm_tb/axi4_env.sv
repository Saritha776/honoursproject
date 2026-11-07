class axi4_env extends uvm_env;
axi4_agent agent; axi4_scoreboard sb;
`uvm_component_utils(axi4_env)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); agent=axi4_agent::type_id::create("agent",this); sb=axi4_scoreboard::type_id::create("sb",this); endfunction
endclass
