class wishbone_env extends uvm_env;
wishbone_agent agent; wishbone_scoreboard sb;
`uvm_component_utils(wishbone_env)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); agent=wishbone_agent::type_id::create("agent",this); sb=wishbone_scoreboard::type_id::create("sb",this); endfunction
endclass
