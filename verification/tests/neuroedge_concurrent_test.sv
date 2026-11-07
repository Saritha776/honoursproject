// ==============================================================================
// Class: neuroedge_concurrent_test.sv
// Description: UVM Test executing concurrent multi-interface transactions
// ==============================================================================

`ifndef NEUROEDGE_CONCURRENT_TEST_SV
`define NEUROEDGE_CONCURRENT_TEST_SV

class neuroedge_concurrent_test extends neuroedge_base_test;

    `uvm_component_utils(neuroedge_concurrent_test)

    function new(string name = "neuroedge_concurrent_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        neuroedge_concurrent_vseq vseq;
        phase.raise_objection(this);

        `uvm_info(get_type_name(), "=== Starting Concurrent Multi-Interface Verification Test ===", UVM_LOW)

        vseq = neuroedge_concurrent_vseq::type_id::create("vseq");
        vseq.start(env.v_seqr);

        #1000ns;
        `uvm_info(get_type_name(), "=== Concurrent Multi-Interface Test Completed ===", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

`endif // NEUROEDGE_CONCURRENT_TEST_SV
