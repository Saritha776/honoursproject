// ==============================================================================
// Class: systolic_sequencer.sv
// Description: Systolic Array Sequencer
// ==============================================================================

`ifndef SYSTOLIC_SEQUENCER_SV
`define SYSTOLIC_SEQUENCER_SV

class systolic_sequencer extends uvm_sequencer #(systolic_item);

    `uvm_component_utils(systolic_sequencer)

    function new(string name = "systolic_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass

`endif // SYSTOLIC_SEQUENCER_SV
