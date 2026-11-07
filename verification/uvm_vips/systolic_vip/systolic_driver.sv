// ==============================================================================
// Class: systolic_driver.sv
// Description: Protocol-aware driver for Systolic Array Streaming interfaces
// ==============================================================================

`ifndef SYSTOLIC_DRIVER_SV
`define SYSTOLIC_DRIVER_SV

class systolic_driver extends uvm_driver #(systolic_item);

    virtual systolic_if vif;
    systolic_cfg        cfg;

    `uvm_component_utils(systolic_driver)

    function new(string name = "systolic_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual systolic_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"});
        end
    endfunction

    task run_phase(uvm_phase phase);
        reset_ports();
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        forever begin
            seq_item_port.get_next_item(req);
            if (req.mode == SYSTOLIC_STREAM_WGT) begin
                stream_weights(req);
            end else if (req.mode == SYSTOLIC_STREAM_ACT) begin
                stream_activations(req);
            end
            seq_item_port.item_done();
        end
    endtask

    task reset_ports();
        vif.dma_act_valid <= 1'b0;
        vif.dma_act_data  <= '0;
        vif.dma_wgt_valid <= 1'b0;
        vif.dma_wgt_data  <= '0;
    endtask

    task stream_weights(systolic_item item);
        for (int r = 0; r < 4; r++) begin
            @(posedge vif.clk);
            vif.dma_wgt_valid <= 1'b1;
            vif.dma_wgt_data  <= {item.weights[r][3], item.weights[r][2], item.weights[r][1], item.weights[r][0]};
        end
        @(posedge vif.clk);
        vif.dma_wgt_valid <= 1'b0;
    endtask

    task stream_activations(systolic_item item);
        @(posedge vif.clk);
        vif.dma_act_valid <= 1'b1;
        vif.dma_act_data  <= {item.activations[3], item.activations[2], item.activations[1], item.activations[0]};
        @(posedge vif.clk);
        vif.dma_act_valid <= 1'b0;
    endtask

endclass

`endif // SYSTOLIC_DRIVER_SV
