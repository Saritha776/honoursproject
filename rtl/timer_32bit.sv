// ==============================================================================
// Module: timer_32bit.sv
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: 32-bit Precision Timer with programmable compare threshold
//              and auto-reload for periodic inference scheduling.
// Base Address: 0x4000_4000
// ==============================================================================

`timescale 1ns / 1ps

module timer_32bit (
    input  logic        clk,
    input  logic        rst_n,
    
    // Wishbone Slave Interface
    input  logic [31:0] wb_adr_i,
    input  logic [31:0] wb_dat_i,
    output logic [31:0] wb_dat_o,
    input  logic        wb_we_i,
    input  logic        wb_stb_i,
    input  logic        wb_cyc_i,
    output logic        wb_ack_o,
    
    // Interrupt Output
    output logic        timer_irq
);

    // Register Offsets
    localparam REG_TIMER_CTRL   = 8'h00;
    localparam REG_TIMER_CNT    = 8'h04;
    localparam REG_TIMER_CMP    = 8'h08;
    localparam REG_TIMER_STATUS = 8'h0C;

    // Registers
    logic        reg_en;
    logic        reg_auto_reload;
    logic [31:0] reg_cnt;
    logic [31:0] reg_cmp;
    logic        reg_match;

    // Wishbone Interface
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_en          <= 1'b0;
            reg_auto_reload <= 1'b0;
            reg_cnt         <= 32'h0000_0000;
            reg_cmp         <= 32'hFFFF_FFFF;
            reg_match       <= 1'b0;
            wb_ack_o        <= 1'b0;
            wb_dat_o        <= 32'h0000_0000;
        end else begin
            wb_ack_o <= 1'b0;

            // Timer counter progression
            if (reg_en) begin
                if (reg_cnt == reg_cmp) begin
                    reg_match <= 1'b1;
                    if (reg_auto_reload) begin
                        reg_cnt <= 32'h0000_0000;
                    end else begin
                        reg_cnt <= reg_cnt + 1'b1;
                    end
                end else begin
                    reg_cnt <= reg_cnt + 1'b1;
                end
            end

            // Wishbone Read/Write
            if (wb_stb_i && wb_cyc_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;
                if (wb_we_i) begin
                    case (wb_adr_i[7:0])
                        REG_TIMER_CTRL: begin
                            reg_en          <= wb_dat_i[0];
                            reg_auto_reload <= wb_dat_i[1];
                        end
                        REG_TIMER_CNT: reg_cnt <= wb_dat_i;
                        REG_TIMER_CMP: reg_cmp <= wb_dat_i;
                        REG_TIMER_STATUS: begin
                            if (wb_dat_i[0]) reg_match <= 1'b0;
                        end
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[7:0])
                        REG_TIMER_CTRL:   wb_dat_o <= {30'b0, reg_auto_reload, reg_en};
                        REG_TIMER_CNT:    wb_dat_o <= reg_cnt;
                        REG_TIMER_CMP:    wb_dat_o <= reg_cmp;
                        REG_TIMER_STATUS: wb_dat_o <= {31'b0, reg_match};
                        default:          wb_dat_o <= 32'h0000_0000;
                    endcase
                end
            end
        end
    end

    assign timer_irq = reg_match;

endmodule
