// ==============================================================================
// Class: wb_sequencer.sv
// Description: Wishbone Sequencer
// ==============================================================================

`ifndef WB_SEQUENCER_SV
`define WB_SEQUENCER_SV

class wb_sequencer extends uvm_sequencer #(wb_item);

    `uvm_component_utils(wb_sequencer)

    function new(string name = "wb_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass

`endif // WB_SEQUENCER_SV
