interface systolic_if;
logic clk;
logic rst_n;
logic [31:0] wb_adr;
logic [31:0] wb_dat_w;
logic [31:0] wb_dat_r;
logic wb_we;
logic wb_stb;
logic wb_cyc;
logic wb_ack;
logic dma_act_valid;
logic [31:0] dma_act_data;
logic dma_wgt_valid;
logic [31:0] dma_wgt_data;
logic array_irq;
endinterface
