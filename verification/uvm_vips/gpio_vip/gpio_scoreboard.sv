// ==============================================================================
// Class: gpio_scoreboard.sv
// Description: Scoreboard for GPIO VIP tracking both input stimulus patterns
//              and SoC firmware milestone output transitions.
// ==============================================================================

`ifndef GPIO_SCOREBOARD_SV
`define GPIO_SCOREBOARD_SV

class gpio_scoreboard extends uvm_scoreboard;

    uvm_analysis_imp #(gpio_seq_item, gpio_scoreboard) item_collected_export;

    int transition_count = 0;
    int input_transition_count = 0;
    int output_transition_count = 0;
    bit stage1_seen = 0;
    bit stage2_seen = 0;
    bit stage3_seen = 0;
    bit stage4_seen = 0;
    bit success_seen = 0;

    bit [7:0] last_in  = 8'h00;
    bit [7:0] last_out = 8'h00;

    `uvm_component_utils(gpio_scoreboard)

    function new(string name = "gpio_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        item_collected_export = new("item_collected_export", this);
    endfunction

    function void write(gpio_seq_item item);
        transition_count++;

        if (item.gpio_in !== last_in) begin
            input_transition_count++;
            last_in = item.gpio_in;
        end

        if (item.gpio_out !== last_out) begin
            output_transition_count++;
            last_out = item.gpio_out;
            if (item.gpio_out == 8'h01) stage1_seen = 1;
            if (item.gpio_out == 8'h02) stage2_seen = 1;
            if (item.gpio_out == 8'h04) stage3_seen = 1;
            if (item.gpio_out == 8'h08) stage4_seen = 1;
            if (item.gpio_out == 8'hAA) begin
                success_seen = 1;
                `uvm_info("GPIO_SUCCESS", "★ GPIO Milestone 0xAA (All Firmware Tests Passed) Verified! ★", UVM_NONE)
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(),
            $sformatf("GPIO Scoreboard Summary: TotalTransitions=%0d, InputTransitions=%0d, OutputTransitions=%0d, SuccessMilestoneSeen=%0b",
                      transition_count, input_transition_count, output_transition_count, success_seen), UVM_LOW)
    endfunction

endclass

`endif // GPIO_SCOREBOARD_SV
