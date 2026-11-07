// ==============================================================================
// Class: uart_driver.sv
// Description: Protocol-aware UART Transmitter Driver (driving RX pin of DUT)
// ==============================================================================

`ifndef UART_DRIVER_SV
`define UART_DRIVER_SV

class uart_driver extends uvm_driver #(uart_item);

    virtual uart_if vif;
    uart_cfg        cfg;

    `uvm_component_utils(uart_driver)

    function new(string name = "uart_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"});
        end
    endfunction

    task run_phase(uvm_phase phase);
        vif.rx <= 1'b1; // Idle high
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        forever begin
            seq_item_port.get_next_item(req);
            transmit_byte(req.data);
            seq_item_port.item_done();
        end
    endtask

    task transmit_byte(bit [7:0] data_byte);
        real bit_time;
        bit_time = (cfg != null) ? cfg.bit_period_ns : 340.0;

        // Start bit
        vif.rx <= 1'b0;
        #(bit_time * 1ns);

        // 8 data bits LSB to MSB
        for (int i = 0; i < 8; i++) begin
            vif.rx <= data_byte[i];
            #(bit_time * 1ns);
        end

        // Stop bit
        vif.rx <= 1'b1;
        #(bit_time * 1ns);
    endtask

endclass

`endif // UART_DRIVER_SV
