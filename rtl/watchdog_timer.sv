// ==============================================================================
// Module: watchdog_timer.sv
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: Safety-critical Watchdog Timer with magic heartbeat reload key
//              (0xA5A5_5A5A) and hardware system reset assertion.
// Base Address: 0x4000_5000
// ==============================================================================

`timescale 1ns / 1ps

module watchdog_timer (
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
    
    // Alert & Reset Outputs
    output logic        wdt_irq,
    output logic        wdt_reset_out
);

    // Register Offsets
    localparam REG_WDT_CTRL    = 8'h00;
    localparam REG_WDT_KICK    = 8'h04;
    localparam REG_WDT_TIMEOUT = 8'h08;
    localparam REG_WDT_STATUS  = 8'h0C;

    localparam KEY_RELOAD      = 32'hA5A5_5A5A;

    // Registers
    logic        reg_en;
    logic        reg_reset_en;
    logic [31:0] reg_timeout;
    logic        reg_bark;

    // Countdown counter
    logic [31:0] countdown_cnt;
    logic [4:0]  reset_pulse_cnt;
    logic        reset_asserted;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_en          <= 1'b1; // Default enabled
            reg_reset_en    <= 1'b0;
            reg_timeout     <= 32'h004C_4B40; // 5,000,000 cycles default
            reg_bark        <= 1'b0;
            countdown_cnt   <= 32'h004C_4B40;
            reset_pulse_cnt <= 5'd0;
            reset_asserted  <= 1'b0;
            wb_ack_o        <= 1'b0;
            wb_dat_o        <= 32'h0000_0000;
        end else begin
            wb_ack_o <= 1'b0;

            // Countdown operation
            if (reg_en && !reset_asserted) begin
                if (countdown_cnt == 32'd0) begin
                    reg_bark <= 1'b1;
                    if (reg_reset_en) begin
                        reset_asserted  <= 1'b1;
                        reset_pulse_cnt <= 5'd16; // 16-cycle reset pulse
                    end
                end else begin
                    countdown_cnt <= countdown_cnt - 1'b1;
                end
            end

            // Reset pulse generation
            if (reset_asserted) begin
                if (reset_pulse_cnt > 5'd0) begin
                    reset_pulse_cnt <= reset_pulse_cnt - 1'b1;
                end else begin
                    reset_asserted <= 1'b0;
                    countdown_cnt  <= reg_timeout;
                end
            end

            // Wishbone Read/Write
            if (wb_stb_i && wb_cyc_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;
                if (wb_we_i) begin
                    case (wb_adr_i[7:0])
                        REG_WDT_CTRL: begin
                            reg_en       <= wb_dat_i[0];
                            reg_reset_en <= wb_dat_i[1];
                        end
                        REG_WDT_KICK: begin
                            if (wb_dat_i == KEY_RELOAD) begin
                                countdown_cnt <= reg_timeout;
                                reg_bark      <= 1'b0;
                            end
                        end
                        REG_WDT_TIMEOUT: reg_timeout <= wb_dat_i;
                        REG_WDT_STATUS: begin
                            if (wb_dat_i[0]) reg_bark <= 1'b0;
                        end
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[7:0])
                        REG_WDT_CTRL:    wb_dat_o <= {30'b0, reg_reset_en, reg_en};
                        REG_WDT_KICK:    wb_dat_o <= 32'h0000_0000;
                        REG_WDT_TIMEOUT: wb_dat_o <= reg_timeout;
                        REG_WDT_STATUS:  wb_dat_o <= {31'b0, reg_bark};
                        default:         wb_dat_o <= 32'h0000_0000;
                    endcase
                end
            end
        end
    end

    assign wdt_irq       = reg_bark;
    assign wdt_reset_out = reset_asserted;

endmodule
