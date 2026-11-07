class axi4_item extends uvm_sequence_item;

  rand bit [7:0] awid;
  rand bit [31:0] awaddr;
  rand bit [7:0] awlen;
  rand bit [2:0] awsize;
  rand bit [1:0] awburst;
  rand bit awvalid;
  bit awready;
  rand bit [63:0] wdata;
  rand bit [7:0] wstrb;
  rand bit wlast;
  rand bit wvalid;
  bit wready;
  bit [7:0] bid;
  bit [1:0] bresp;
  bit bvalid;
  rand bit bready;
  rand bit [7:0] arid;
  rand bit [31:0] araddr;
  rand bit [7:0] arlen;
  rand bit [2:0] arsize;
  rand bit [1:0] arburst;
  rand bit arvalid;
  bit arready;
  bit [7:0] rid;
  bit [63:0] rdata;
  bit [1:0] rresp;
  bit rlast;
  bit rvalid;
  rand bit rready;

  `uvm_object_utils(axi4_item)

  function new(string name="axi4_item"); super.new(name); endfunction
endclass
