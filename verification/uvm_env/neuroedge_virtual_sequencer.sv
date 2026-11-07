// ==============================================================================
// Class: neuroedge_virtual_sequencer.sv
// Description: Virtual Sequencer coordinating multi-VIP sequences
// ==============================================================================

`ifndef NEUROEDGE_VIRTUAL_SEQUENCER_SV
`define NEUROEDGE_VIRTUAL_SEQUENCER_SV

class neuroedge_virtual_sequencer extends uvm_sequencer;

    axi4_sequencer      lsu_seqr;
    axi4_sequencer      ifu_seqr;
    wb_sequencer        wb_seqr;
    uart_sequencer      uart_seqr;
    systolic_sequencer  systolic_seqr;
    spi_flash_sequencer spi_seqr;
    gpio_sequencer      gpio_seqr;

    `uvm_component_utils(neuroedge_virtual_sequencer)

    function new(string name = "neuroedge_virtual_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass

`endif // NEUROEDGE_VIRTUAL_SEQUENCER_SV
