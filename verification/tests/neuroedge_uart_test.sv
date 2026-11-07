// ==============================================================================
// Class: neuroedge_uart_test.sv
// Description: Dedicated UVM Test verifying UART Transmission and Reception
// ==============================================================================

`ifndef NEUROEDGE_UART_TEST_SV
`define NEUROEDGE_UART_TEST_SV

class neuroedge_uart_test extends neuroedge_base_test;

    `uvm_component_utils(neuroedge_uart_test)

    function new(string name = "neuroedge_uart_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        neuroedge_uart_vseq uart_vseq;
        phase.raise_objection(this);

        `uvm_info(get_type_name(), "=== Starting Dedicated UART Protocol Verification Test ===", UVM_LOW)

        // Configure UART VIP for 640 ns bit timing (baud_div = 31 @ 50 MHz)
        env.uart_agent_inst.cfg.bit_period_ns = 640.0;

        uart_vseq = neuroedge_uart_vseq::type_id::create("uart_vseq");
        uart_vseq.start(env.v_seqr);

        #2000ns;
        `uvm_info(get_type_name(), "=== UART Protocol Verification Test Completed ===", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

`endif // NEUROEDGE_UART_TEST_SV
