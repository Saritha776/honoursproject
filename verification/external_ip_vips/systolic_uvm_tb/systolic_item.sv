class systolic_item extends uvm_sequence_item;

  rand bit [31:0] wb_adr;
  rand bit [31:0] wb_dat_w;
  bit [31:0] wb_dat_r;
  rand bit wb_we;
  rand bit wb_stb;
  rand bit wb_cyc;
  bit wb_ack;
  rand bit dma_act_valid;
  rand bit [31:0] dma_act_data;
  rand bit dma_wgt_valid;
  rand bit [31:0] dma_wgt_data;
  bit array_irq;

  `uvm_object_utils(systolic_item)

  function new(string name="systolic_item"); super.new(name); endfunction
endclass
