// ==============================================================================
// Class: neuroedge_wb_access_test.sv
// Description: UVM Test for Wishbone Memory & Peripheral Access
// ==============================================================================

`ifndef NEUROEDGE_WB_ACCESS_TEST_SV
`define NEUROEDGE_WB_ACCESS_TEST_SV

class neuroedge_wb_access_test extends neuroedge_base_test;

    `uvm_component_utils(neuroedge_wb_access_test)

    function new(string name = "neuroedge_wb_access_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        neuroedge_wb_memory_vseq mem_vseq;
        neuroedge_peripheral_vseq periph_vseq;
        phase.raise_objection(this);

        `uvm_info(get_type_name(), "=== Starting Wishbone Memory & Peripheral Test ===", UVM_LOW)

        mem_vseq = neuroedge_wb_memory_vseq::type_id::create("mem_vseq");
        mem_vseq.start(env.v_seqr);

        periph_vseq = neuroedge_peripheral_vseq::type_id::create("periph_vseq");
        periph_vseq.start(env.v_seqr);

        #1000ns;
        `uvm_info(get_type_name(), "=== Wishbone Memory & Peripheral Test Completed ===", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

`endif // NEUROEDGE_WB_ACCESS_TEST_SV
