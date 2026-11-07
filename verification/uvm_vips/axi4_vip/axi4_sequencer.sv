// ==============================================================================
// Class: axi4_sequencer.sv
// Description: AXI4 Sequencer
// ==============================================================================

`ifndef AXI4_SEQUENCER_SV
`define AXI4_SEQUENCER_SV

class axi4_sequencer extends uvm_sequencer #(axi4_item);

    `uvm_component_utils(axi4_sequencer)

    function new(string name = "axi4_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass

`endif // AXI4_SEQUENCER_SV
