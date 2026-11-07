// ==============================================================================
// Module: sram_sp_32k.sv
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: 32 KB Single-Port Instruction SRAM (8192 x 32-bit words).
//              Synchronous read/write with byte enable masks.
// Address Range: 0x0000_0000 - 0x0000_7FFF
// ==============================================================================

`timescale 1ns / 1ps

module sram_sp_32k #(
    parameter INIT_FILE = ""
)(
    input  logic        clk,
    input  logic        rst_n,
    
    // Wishbone Slave Interface
    input  logic [31:0] wb_adr_i,
    input  logic [31:0] wb_dat_i,
    output logic [31:0] wb_dat_o,
    input  logic [3:0]  wb_sel_i,
    input  logic        wb_we_i,
    input  logic        wb_stb_i,
    input  logic        wb_cyc_i,
    output logic        wb_ack_o
);

    // 8192 words x 32 bits = 32768 bytes = 32 KB
    logic [31:0] ram [0:8191];

    // Word address: adr[14:2]
    wire [12:0] word_addr = wb_adr_i[14:2];

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, ram);
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_ack_o <= 1'b0;
            wb_dat_o <= 32'h0000_0000;
        end else begin
            wb_ack_o <= 1'b0;

            if (wb_stb_i && wb_cyc_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;
                if (wb_we_i) begin
                    if (wb_sel_i[0]) ram[word_addr][7:0]   <= wb_dat_i[7:0];
                    if (wb_sel_i[1]) ram[word_addr][15:8]  <= wb_dat_i[15:8];
                    if (wb_sel_i[2]) ram[word_addr][23:16] <= wb_dat_i[23:16];
                    if (wb_sel_i[3]) ram[word_addr][31:24] <= wb_dat_i[31:24];
                end else begin
                    wb_dat_o <= ram[word_addr];
                end
            end
        end
    end

endmodule
