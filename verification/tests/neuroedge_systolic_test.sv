// ==============================================================================
// Class: neuroedge_systolic_test.sv
// Description: UVM Test verifying 4x4 Systolic Array results [-13, -41, 94, 7]
// ==============================================================================

`ifndef NEUROEDGE_SYSTOLIC_TEST_SV
`define NEUROEDGE_SYSTOLIC_TEST_SV

class neuroedge_systolic_test extends neuroedge_base_test;

    `uvm_component_utils(neuroedge_systolic_test)

    function new(string name = "neuroedge_systolic_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        neuroedge_systolic_vseq vseq;
        phase.raise_objection(this);

        `uvm_info(get_type_name(), "=== Starting Dedicated Systolic Array Hardware Verification Test ===", UVM_LOW)

        vseq = neuroedge_systolic_vseq::type_id::create("vseq");
        vseq.start(env.v_seqr);

        #1000ns;
        `uvm_info(get_type_name(), "=== Systolic Array Verification Test Completed ===", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

`endif // NEUROEDGE_SYSTOLIC_TEST_SV
