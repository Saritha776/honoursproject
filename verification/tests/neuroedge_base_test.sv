// ==============================================================================
// Class: neuroedge_base_test.sv
// Description: Base UVM test creating environment and common reporting
// ==============================================================================

`ifndef NEUROEDGE_BASE_TEST_SV
`define NEUROEDGE_BASE_TEST_SV

class neuroedge_base_test extends uvm_test;

    neuroedge_env       env;
    neuroedge_env_cfg   cfg;

    `uvm_component_utils(neuroedge_base_test)

    function new(string name = "neuroedge_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg = neuroedge_env_cfg::type_id::create("cfg");
        uvm_config_db#(neuroedge_env_cfg)::set(this, "env", "cfg", cfg);
        env = neuroedge_env::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

    task run_phase(uvm_phase phase);
        uvm_objection objection = phase.get_objection();
        objection.set_drain_time(this, 1000ns);
    endtask

    function void report_phase(uvm_phase phase);
        uvm_report_server svr;
        super.report_phase(phase);
        svr = uvm_report_server::get_server();

        `uvm_info(get_type_name(), "--------------------------------------------------", UVM_NONE)
        if (svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) == 0) begin
            `uvm_info(get_type_name(), "             TEST RESULT: >>> PASSED <<<           ", UVM_NONE)
        end else begin
            `uvm_error(get_type_name(), "            TEST RESULT: >>> FAILED <<<           ")
        end
        `uvm_info(get_type_name(), "--------------------------------------------------", UVM_NONE)
    endfunction

endclass

`endif // NEUROEDGE_BASE_TEST_SV
