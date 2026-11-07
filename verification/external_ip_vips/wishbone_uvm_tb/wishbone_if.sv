interface wishbone_if;
logic clk;
logic rst_n;
logic [31:0] adr;
logic [31:0] dat_w;
logic [31:0] dat_r;
logic [3:0] sel;
logic we;
logic stb;
logic cyc;
logic ack;
logic err;
endinterface
