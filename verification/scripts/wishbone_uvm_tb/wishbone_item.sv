class wishbone_item extends uvm_sequence_item;

  rand bit [31:0] adr;
  rand bit [31:0] dat_w;
  bit [31:0] dat_r;
  rand bit [3:0] sel;
  rand bit we;
  rand bit stb;
  rand bit cyc;
  bit ack;
  bit err;

  `uvm_object_utils(wishbone_item)

  function new(string name="wishbone_item"); super.new(name); endfunction
endclass
