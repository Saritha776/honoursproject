// ==============================================================================
// Module: pic_controller.sv
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: Platform Interrupt Controller (PIC) aggregating 6 prioritized
//              interrupt lines and presenting vectored IRQs to VeeR EL2 core.
// Base Address: 0x4000_7000
// ==============================================================================

`timescale 1ns / 1ps

module pic_controller (
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
    
    // Peripheral Interrupt Inputs
    // [0]: WDT
    // [1]: Timer
    // [2]: Systolic Array
    // [3]: DMA
    // [4]: UART
    // [5]: GPIO
    input  logic [5:0]  irq_lines_i,
    
    // Vectored Interrupt Output to CPU
    output logic [5:0]  irq_vec_o
);

    // Register Offsets
    localparam REG_PIC_ENABLE   = 8'h00;
    localparam REG_PIC_PENDING  = 8'h04;
    localparam REG_PIC_PRIORITY = 8'h08;
    localparam REG_PIC_ACK      = 8'h0C;

    // Registers
    logic [5:0]  reg_enable;
    logic [5:0]  reg_pending;
    logic [23:0] reg_priority;

    // Edge latching of raw interrupt lines
    logic [5:0] irq_prev;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_enable   <= 6'b000000;
            reg_pending  <= 6'b000000;
            reg_priority <= 24'h54_3210; // Default priority map (0=highest)
            irq_prev     <= 6'b000000;
            wb_ack_o     <= 1'b0;
            wb_dat_o     <= 32'h0000_0000;
        end else begin
            wb_ack_o <= 1'b0;
            irq_prev <= irq_lines_i;

            // Capture rising edges or active levels into pending register
            for (int i = 0; i < 6; i++) begin
                if (irq_lines_i[i]) begin
                    reg_pending[i] <= 1'b1;
                end
            end

            // Wishbone Read/Write
            if (wb_stb_i && wb_cyc_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;
                if (wb_we_i) begin
                    case (wb_adr_i[7:0])
                        REG_PIC_ENABLE:   reg_enable   <= wb_dat_i[5:0];
                        REG_PIC_PRIORITY: reg_priority <= wb_dat_i[23:0];
                        REG_PIC_ACK: begin
                            // Write 1 to clear pending
                            reg_pending <= reg_pending & (~wb_dat_i[5:0]);
                        end
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[7:0])
                        REG_PIC_ENABLE:   wb_dat_o <= {26'b0, reg_enable};
                        REG_PIC_PENDING:  wb_dat_o <= {26'b0, reg_pending};
                        REG_PIC_PRIORITY: wb_dat_o <= {8'b0,  reg_priority};
                        REG_PIC_ACK:      wb_dat_o <= 32'h0000_0000;
                        default:          wb_dat_o <= 32'h0000_0000;
                    endcase
                end
            end
        end
    end

    // Route masked pending interrupts to CPU
    assign irq_vec_o = reg_pending & reg_enable;

endmodule
