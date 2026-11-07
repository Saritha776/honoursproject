// ==============================================================================
// Class: uart_monitor.sv
// Description: Protocol-aware UART Receiver Monitor (sampling TX pin of DUT)
// ==============================================================================

`ifndef UART_MONITOR_SV
`define UART_MONITOR_SV

class uart_monitor extends uvm_monitor;

    virtual uart_if vif;
    uart_cfg        cfg;

    uvm_analysis_port #(uart_item) item_collected_port;

    `uvm_component_utils(uart_monitor)

    function new(string name = "uart_monitor", uvm_component parent = null);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"});
        end
    endfunction

    task run_phase(uvm_phase phase);
        uart_item item;
        real bit_time;

        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        forever begin
            bit_time = (cfg != null) ? cfg.bit_period_ns : 340.0;

            // Detect Start Bit falling edge
            @(negedge vif.tx);
            if (!vif.rst_n) continue;

            // Wait 1.5 bit periods to align with center of Bit 0
            #(bit_time * 1.5 * 1ns);

            item = uart_item::type_id::create("mon_uart_item");
            for (int i = 0; i < 8; i++) begin
                item.data[i] = vif.tx;
                #(bit_time * 1ns);
            end

            // Check Stop Bit (should be 1'b1)
            item.frame_err = (vif.tx !== 1'b1);

            `uvm_info(get_type_name(), $sformatf("Monitored: %s", item.convert2string()), UVM_HIGH)
            item_collected_port.write(item);
        end
    endtask

endclass

`endif // UART_MONITOR_SV
