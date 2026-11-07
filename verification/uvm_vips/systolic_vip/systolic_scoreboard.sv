// ==============================================================================
// Class: systolic_scoreboard.sv
// Description: Scoreboard with Golden INT8 Matrix Predictor for Systolic Array
// ==============================================================================

`ifndef SYSTOLIC_SCOREBOARD_SV
`define SYSTOLIC_SCOREBOARD_SV

class systolic_scoreboard extends uvm_scoreboard;

    uvm_analysis_imp #(systolic_item, systolic_scoreboard) item_collected_export;

    int total_inferences = 0;
    int pass_inferences = 0;
    int fail_inferences = 0;

    `uvm_component_utils(systolic_scoreboard)

    function new(string name = "systolic_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        item_collected_export = new("item_collected_export", this);
    endfunction

    function void write(systolic_item item);
        bit match = 1;
        total_inferences++;

        for (int c = 0; c < 4; c++) begin
            if (item.actual_results[c] !== item.expected_results[c]) begin
                match = 0;
                `uvm_error("SYSTOLIC_MISMATCH",
                    $sformatf("Column %0d Mismatch: Actual=%0d, Expected=%0d",
                              c, item.actual_results[c], item.expected_results[c]))
            end
        end

        // Specific Check for Target AI Inference: [-13, -41, 94, 7]
        if (item.actual_results[0] == -13 &&
            item.actual_results[1] == -41 &&
            item.actual_results[2] == 94  &&
            item.actual_results[3] == 7) begin
            `uvm_info("ACCELERATOR_GOLDEN_MATCH",
                "★ TARGET INFERENCE VERIFIED: [-13, -41, 94, 7] MATCHES EXACTLY! ★", UVM_NONE)
        end

        if (match) begin
            pass_inferences++;
            `uvm_info("SYSTOLIC_PASS",
                $sformatf("Inference #%0d Passed Golden Match: [%0d, %0d, %0d, %0d]",
                          total_inferences,
                          item.actual_results[0], item.actual_results[1],
                          item.actual_results[2], item.actual_results[3]), UVM_LOW)
        end else begin
            fail_inferences++;
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(),
            $sformatf("Systolic Array Scoreboard: Inferences=%0d, PASS=%0d, FAIL=%0d",
                      total_inferences, pass_inferences, fail_inferences), UVM_LOW)
    endfunction

endclass

`endif // SYSTOLIC_SCOREBOARD_SV
