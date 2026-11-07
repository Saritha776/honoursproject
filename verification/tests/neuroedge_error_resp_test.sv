// ==============================================================================
// Class: neuroedge_error_resp_test.sv
// Description: UVM Test verifying bus error and timeout conditions
// ==============================================================================

`ifndef NEUROEDGE_ERROR_RESP_TEST_SV
`define NEUROEDGE_ERROR_RESP_TEST_SV

class neuroedge_error_resp_test extends neuroedge_base_test;

    `uvm_component_utils(neuroedge_error_resp_test)

    function new(string name = "neuroedge_error_resp_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        neuroedge_error_resp_vseq vseq;
        phase.raise_objection(this);

        `uvm_info(get_type_name(), "=== Starting Bus Error Response Verification Test ===", UVM_LOW)

        vseq = neuroedge_error_resp_vseq::type_id::create("vseq");
        vseq.start(env.v_seqr);

        #1000ns;
        `uvm_info(get_type_name(), "=== Bus Error Response Test Completed ===", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

`endif // NEUROEDGE_ERROR_RESP_TEST_SV
