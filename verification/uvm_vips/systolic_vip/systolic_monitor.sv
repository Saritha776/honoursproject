// ==============================================================================
// Class: systolic_monitor.sv
// Description: Functional monitor for Systolic Array operations
// ==============================================================================

`ifndef SYSTOLIC_MONITOR_SV
`define SYSTOLIC_MONITOR_SV

class systolic_monitor extends uvm_monitor;

    virtual systolic_if vif;
    systolic_cfg        cfg;

    uvm_analysis_port #(systolic_item) item_collected_port;

    byte signed shadow_weights[4][4];
    byte signed shadow_activations[4];
    int wgt_row_idx = 0;

    `uvm_component_utils(systolic_monitor)

    function new(string name = "systolic_monitor", uvm_component parent = null);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual systolic_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"});
        end
    endfunction

    task run_phase(uvm_phase phase);
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        fork
            monitor_wb_traffic();
            monitor_streaming_traffic();
            monitor_completion();
        join
    endtask

    task monitor_wb_traffic();
        forever begin
            @(posedge vif.clk);
            if (vif.rst_n && vif.wb_cyc && vif.wb_stb && vif.wb_we && vif.wb_ack) begin
                // Weight port write at offset 0x10
                if (vif.wb_adr[7:0] == 8'h10) begin
                    shadow_weights[wgt_row_idx][0] = vif.wb_dat_w[7:0];
                    shadow_weights[wgt_row_idx][1] = vif.wb_dat_w[15:8];
                    shadow_weights[wgt_row_idx][2] = vif.wb_dat_w[23:16];
                    shadow_weights[wgt_row_idx][3] = vif.wb_dat_w[31:24];
                    wgt_row_idx = (wgt_row_idx + 1) % 4;
                end
                // Activation port write at offset 0x14
                else if (vif.wb_adr[7:0] == 8'h14) begin
                    shadow_activations[0] = vif.wb_dat_w[7:0];
                    shadow_activations[1] = vif.wb_dat_w[15:8];
                    shadow_activations[2] = vif.wb_dat_w[23:16];
                    shadow_activations[3] = vif.wb_dat_w[31:24];
                end
            end
        end
    endtask

    task monitor_streaming_traffic();
        forever begin
            @(posedge vif.clk);
            if (vif.rst_n && vif.dma_wgt_valid) begin
                shadow_weights[wgt_row_idx][0] = vif.dma_wgt_data[7:0];
                shadow_weights[wgt_row_idx][1] = vif.dma_wgt_data[15:8];
                shadow_weights[wgt_row_idx][2] = vif.dma_wgt_data[23:16];
                shadow_weights[wgt_row_idx][3] = vif.dma_wgt_data[31:24];
                wgt_row_idx = (wgt_row_idx + 1) % 4;
            end
            if (vif.rst_n && vif.dma_act_valid) begin
                shadow_activations[0] = vif.dma_act_data[7:0];
                shadow_activations[1] = vif.dma_act_data[15:8];
                shadow_activations[2] = vif.dma_act_data[23:16];
                shadow_activations[3] = vif.dma_act_data[31:24];
            end
        end
    endtask

    task monitor_completion();
        systolic_item item;
        forever begin
            @(posedge vif.clk);
            // Detect array completion pulse
            if (vif.rst_n && vif.array_irq) begin
                // Give 1 cycle for result register capture
                @(posedge vif.clk);
                item = systolic_item::type_id::create("mon_systolic_item");
                item.weights     = shadow_weights;
                item.activations = shadow_activations;
                item.compute_golden();

                item.actual_results[0] = vif.res_out[0];
                item.actual_results[1] = vif.res_out[1];
                item.actual_results[2] = vif.res_out[2];
                item.actual_results[3] = vif.res_out[3];

                `uvm_info(get_type_name(), $sformatf("Monitored Completion:\n%s", item.convert2string()), UVM_LOW)
                item_collected_port.write(item);
            end
        end
    endtask

endclass

`endif // SYSTOLIC_MONITOR_SV
