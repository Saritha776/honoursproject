// ==============================================================================
// Class: neuroedge_uart_fifo_test.sv
// Description: Dedicated UVM Test for UART FIFO Level Multi-Byte TX & RX
// ==============================================================================

`ifndef NEUROEDGE_UART_FIFO_TEST_SV
`define NEUROEDGE_UART_FIFO_TEST_SV

class neuroedge_uart_fifo_test extends neuroedge_base_test;

    `uvm_component_utils(neuroedge_uart_fifo_test)

    function new(string name = "neuroedge_uart_fifo_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        neuroedge_uart_fifo_vseq fifo_vseq;
        phase.raise_objection(this);

        `uvm_info(get_type_name(), "=== Starting Dedicated UART FIFO-Level Verification Test ===", UVM_LOW)

        // Configure UART VIP for 640 ns bit timing (baud_div = 31 @ 50 MHz)
        env.uart_agent_inst.cfg.bit_period_ns = 640.0;

        fifo_vseq = neuroedge_uart_fifo_vseq::type_id::create("fifo_vseq");
        fifo_vseq.start(env.v_seqr);

        #3000ns;
        `uvm_info(get_type_name(), "=== UART FIFO-Level Verification Test Completed ===", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

`endif // NEUROEDGE_UART_FIFO_TEST_SV
