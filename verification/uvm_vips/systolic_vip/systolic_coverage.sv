// ==============================================================================
// Class: systolic_coverage.sv
// Description: Functional coverage collector for Systolic Array operations
// ==============================================================================

`ifndef SYSTOLIC_COVERAGE_SV
`define SYSTOLIC_COVERAGE_SV

class systolic_coverage extends uvm_subscriber #(systolic_item);

    `uvm_component_utils(systolic_coverage)

    systolic_item item_cov;

    covergroup cg_systolic;
        cp_res0: coverpoint item_cov.actual_results[0] {
            bins NEGATIVE = {[-2147483648 : -1]};
            bins ZERO     = {0};
            bins POSITIVE = {[1 : 2147483647]};
            bins EXP_VAL  = {-13};
        }

        cp_res1: coverpoint item_cov.actual_results[1] {
            bins NEGATIVE = {[-2147483648 : -1]};
            bins ZERO     = {0};
            bins POSITIVE = {[1 : 2147483647]};
            bins EXP_VAL  = {-41};
        }

        cp_res2: coverpoint item_cov.actual_results[2] {
            bins NEGATIVE = {[-2147483648 : -1]};
            bins ZERO     = {0};
            bins POSITIVE = {[1 : 2147483647]};
            bins EXP_VAL  = {94};
        }

        cp_res3: coverpoint item_cov.actual_results[3] {
            bins NEGATIVE = {[-2147483648 : -1]};
            bins ZERO     = {0};
            bins POSITIVE = {[1 : 2147483647]};
            bins EXP_VAL  = {7};
        }
    endgroup

    function new(string name = "systolic_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_systolic = new();
    endfunction

    function void write(systolic_item t);
        item_cov = t;
        cg_systolic.sample();
    endfunction

    function real get_coverage_pct();
        return cg_systolic.get_coverage();
    endfunction

endclass

`endif // SYSTOLIC_COVERAGE_SV
