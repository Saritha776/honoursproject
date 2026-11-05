// ==============================================================================
// Module: gpio_8bit.sv
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: 8-bit bidirectional General Purpose I/O with 2-stage synchronizers
//              and pin direction configuration.
// Base Address: 0x4000_6000
// ==============================================================================

`timescale 1ns / 1ps

module gpio_8bit (
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
    
    // External GPIO Pins
    input  logic [7:0]  gpio_in,
    output logic [7:0]  gpio_out,
    output logic [7:0]  gpio_dir_o,
    
    // Interrupt Output
    output logic        gpio_irq
);

    // Register Offsets
    localparam REG_GPIO_IN     = 8'h00;
    localparam REG_GPIO_OUT    = 8'h04;
    localparam REG_GPIO_DIR    = 8'h08;
    localparam REG_GPIO_STATUS = 8'h0C;

    // Registers
    logic [7:0] reg_gpio_out;
    logic [7:0] reg_gpio_dir;
    logic       reg_gpio_flag;

    // 2-stage synchronization flip-flops
    logic [7:0] sync_ff1, sync_ff2, sync_ff2_prev;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1      <= 8'h00;
            sync_ff2      <= 8'h00;
            sync_ff2_prev <= 8'h00;
        end else begin
            sync_ff1      <= gpio_in;
            sync_ff2      <= sync_ff1;
            sync_ff2_prev <= sync_ff2;
        end
    end

    // Wishbone Interface
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_gpio_out  <= 8'h00;
            reg_gpio_dir  <= 8'h00; // Default all inputs
            reg_gpio_flag <= 1'b0;
            wb_ack_o      <= 1'b0;
            wb_dat_o      <= 32'h0000_0000;
        end else begin
            wb_ack_o <= 1'b0;

            // Edge detection on input pins
            if (sync_ff2 != sync_ff2_prev) begin
                reg_gpio_flag <= 1'b1;
            end

            // Read / Write
            if (wb_stb_i && wb_cyc_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;
                if (wb_we_i) begin
                    case (wb_adr_i[7:0])
                        REG_GPIO_OUT: reg_gpio_out <= wb_dat_i[7:0];
                        REG_GPIO_DIR: reg_gpio_dir <= wb_dat_i[7:0];
                        REG_GPIO_STATUS: begin
                            if (wb_dat_i[0]) reg_gpio_flag <= 1'b0;
                        end
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[7:0])
                        REG_GPIO_IN:     wb_dat_o <= {24'b0, sync_ff2};
                        REG_GPIO_OUT:    wb_dat_o <= {24'b0, reg_gpio_out};
                        REG_GPIO_DIR:    wb_dat_o <= {24'b0, reg_gpio_dir};
                        REG_GPIO_STATUS: wb_dat_o <= {31'b0, reg_gpio_flag};
                        default:         wb_dat_o <= 32'h0000_0000;
                    endcase
                end
            end
        end
    end

    assign gpio_out   = reg_gpio_out;
    assign gpio_dir_o = reg_gpio_dir;
    assign gpio_irq   = reg_gpio_flag;

endmodule
