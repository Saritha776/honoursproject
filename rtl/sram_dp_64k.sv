// ==============================================================================
// Module: sram_dp_64k.sv
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: 64 KB Dual-Port Data SRAM (16384 x 32-bit words).
//              Port A: CPU / Interconnect Fabric
//              Port B: Dedicated DMA / High-Speed Engine
// Address Range: 0x2000_0000 - 0x2000_FFFF
// ==============================================================================

`timescale 1ns / 1ps

module sram_dp_64k #(
    parameter INIT_FILE = ""
)(
    input  logic        clk,
    input  logic        rst_n,
    
    // Port A: Wishbone Slave Interface
    input  logic [31:0] a_wb_adr_i,
    input  logic [31:0] a_wb_dat_i,
    output logic [31:0] a_wb_dat_o,
    input  logic [3:0]  a_wb_sel_i,
    input  logic        a_wb_we_i,
    input  logic        a_wb_stb_i,
    input  logic        a_wb_cyc_i,
    output logic        a_wb_ack_o,
    
    // Port B: Wishbone Slave Interface
    input  logic [31:0] b_wb_adr_i,
    input  logic [31:0] b_wb_dat_i,
    output logic [31:0] b_wb_dat_o,
    input  logic [3:0]  b_wb_sel_i,
    input  logic        b_wb_we_i,
    input  logic        b_wb_stb_i,
    input  logic        b_wb_cyc_i,
    output logic        b_wb_ack_o
);

    // 16384 words x 32 bits = 64 KB
    logic [31:0] ram [0:16383];

    wire [13:0] addr_a = a_wb_adr_i[15:2];
    wire [13:0] addr_b = b_wb_adr_i[15:2];

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, ram);
        end
    end

    // Port A Operation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_wb_ack_o <= 1'b0;
            a_wb_dat_o <= 32'h0000_0000;
        end else begin
            a_wb_ack_o <= 1'b0;

            if (a_wb_stb_i && a_wb_cyc_i && !a_wb_ack_o) begin
                a_wb_ack_o <= 1'b1;
                if (a_wb_we_i) begin
                    if (a_wb_sel_i[0]) ram[addr_a][7:0]   <= a_wb_dat_i[7:0];
                    if (a_wb_sel_i[1]) ram[addr_a][15:8]  <= a_wb_dat_i[15:8];
                    if (a_wb_sel_i[2]) ram[addr_a][23:16] <= a_wb_dat_i[23:16];
                    if (a_wb_sel_i[3]) ram[addr_a][31:24] <= a_wb_dat_i[31:24];
                end else begin
                    a_wb_dat_o <= ram[addr_a];
                end
            end
        end
    end

    // Port B Operation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b_wb_ack_o <= 1'b0;
            b_wb_dat_o <= 32'h0000_0000;
        end else begin
            b_wb_ack_o <= 1'b0;

            if (b_wb_stb_i && b_wb_cyc_i && !b_wb_ack_o) begin
                b_wb_ack_o <= 1'b1;
                if (b_wb_we_i) begin
                    if (b_wb_sel_i[0]) ram[addr_b][7:0]   <= b_wb_dat_i[7:0];
                    if (b_wb_sel_i[1]) ram[addr_b][15:8]  <= b_wb_dat_i[15:8];
                    if (b_wb_sel_i[2]) ram[addr_b][23:16] <= b_wb_dat_i[23:16];
                    if (b_wb_sel_i[3]) ram[addr_b][31:24] <= b_wb_dat_i[31:24];
                end else begin
                    b_wb_dat_o <= ram[addr_b];
                end
            end
        end
    end

endmodule
