// ==============================================================================
// Class: neuroedge_concurrent_vseq.sv
// Description: Simultaneous multi-interface activity verification sequence
// ==============================================================================

`ifndef NEUROEDGE_CONCURRENT_VSEQ_SV
`define NEUROEDGE_CONCURRENT_VSEQ_SV

class neuroedge_concurrent_vseq extends neuroedge_base_vseq;

    `uvm_object_utils(neuroedge_concurrent_vseq)

    function new(string name = "neuroedge_concurrent_vseq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), "=== Launching Simultaneous Multi-Interface Activity ===", UVM_LOW)

        fork
            // Thread 1: SRAM traffic
            begin
                for (int i = 0; i < 10; i++) begin
                    bit [31:0] val = 32'h1000_0000 + i;
                    bit [31:0] rval;
                    wb_write(32'h2000_3000 + (i*4), val);
                    wb_read(32'h2000_3000 + (i*4), rval);
                end
            end

            // Thread 2: UART background characters
            begin
                uart_send_byte(8'h41); // 'A'
                #2000ns;
                uart_send_byte(8'h49); // 'I'
            end

            // Thread 3: GPIO input transitions
            begin
                gpio_set_input(8'h01);
                #1000ns;
                gpio_set_input(8'h02);
                #1000ns;
                gpio_set_input(8'h04);
            end

            // Thread 4: Systolic Array inference
            begin
                neuroedge_systolic_vseq syst_seq;
                syst_seq = neuroedge_systolic_vseq::type_id::create("concurrent_syst_seq");
                syst_seq.start(p_sequencer);
            end
        join

        `uvm_info(get_type_name(), "=== Simultaneous Multi-Interface Activity Completed (PASS) ===", UVM_LOW)
    endtask

endclass

`endif // NEUROEDGE_CONCURRENT_VSEQ_SV
