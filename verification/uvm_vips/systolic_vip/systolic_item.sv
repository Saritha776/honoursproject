// ==============================================================================
// Class: systolic_item.sv
// Description: Systolic Array computation transaction with embedded Golden Model
// ==============================================================================

`ifndef SYSTOLIC_ITEM_SV
`define SYSTOLIC_ITEM_SV

typedef enum { SYSTOLIC_STREAM_WGT, SYSTOLIC_STREAM_ACT, SYSTOLIC_INFERENCE } systolic_mode_e;

class systolic_item extends uvm_sequence_item;

    systolic_mode_e         mode = SYSTOLIC_INFERENCE;
    rand byte signed        weights[4][4];       // 4x4 INT8 weight matrix
    rand byte signed        activations[4];      // 1x4 INT8 activation vector
    int signed              expected_results[4]; // Golden reference results
    int signed              actual_results[4];   // Results read from DUT registers

    `uvm_object_utils_begin(systolic_item)
        `uvm_field_enum(systolic_mode_e, mode, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "systolic_item");
        super.new(name);
    endfunction

    // Compute golden mathematical reference: y = x^T * W
    function void compute_golden();
        for (int c = 0; c < 4; c++) begin
            int signed sum = 0;
            for (int r = 0; r < 4; r++) begin
                sum += int'(activations[r]) * int'(weights[r][c]);
            end
            expected_results[c] = sum;
        end
    endfunction

    function string convert2string();
        string s;
        s = $sformatf("Systolic Array Inference:\n");
        s = {s, $sformatf("  Activations: [%0d, %0d, %0d, %0d]\n",
                activations[0], activations[1], activations[2], activations[3])};
        s = {s, "  Weights:\n"};
        for (int r = 0; r < 4; r++) begin
            s = {s, $sformatf("    Row %0d: [%4d, %4d, %4d, %4d]\n",
                    r, weights[r][0], weights[r][1], weights[r][2], weights[r][3])};
        end
        s = {s, $sformatf("  Expected: Col0=%0d, Col1=%0d, Col2=%0d, Col3=%0d\n",
                expected_results[0], expected_results[1], expected_results[2], expected_results[3])};
        s = {s, $sformatf("  Actual:   Col0=%0d, Col1=%0d, Col2=%0d, Col3=%0d",
                actual_results[0], actual_results[1], actual_results[2], actual_results[3])};
        return s;
    endfunction

endclass

`endif // SYSTOLIC_ITEM_SV
