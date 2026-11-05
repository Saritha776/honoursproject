// ==============================================================================
// Module: soc_interconnect.sv
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: Synchronous 32-bit Crossbar Interconnect with Round-Robin
//              arbitration, address decoding, and 64-cycle timeout bus error guard.
// ==============================================================================

`timescale 1ns / 1ps

module soc_interconnect (
    input  logic        clk,
    input  logic        rst_n,
    
    // Master 0: CPU Bus Master
    input  logic [31:0] m0_wb_adr_i,
    input  logic [31:0] m0_wb_dat_i,
    output logic [31:0] m0_wb_dat_o,
    input  logic [3:0]  m0_wb_sel_i,
    input  logic        m0_wb_we_i,
    input  logic        m0_wb_stb_i,
    input  logic        m0_wb_cyc_i,
    output logic        m0_wb_ack_o,
    output logic        m0_wb_err_o,
    
    // Master 1: DMA Bus Master
    input  logic [31:0] m1_wb_adr_i,
    input  logic [31:0] m1_wb_dat_i,
    output logic [31:0] m1_wb_dat_o,
    input  logic [3:0]  m1_wb_sel_i,
    input  logic        m1_wb_we_i,
    input  logic        m1_wb_stb_i,
    input  logic        m1_wb_cyc_i,
    output logic        m1_wb_ack_o,
    output logic        m1_wb_err_o,

    // Master 2: SPI Auto-Loader Master
    input  logic [31:0] m2_wb_adr_i,
    input  logic [31:0] m2_wb_dat_i,
    output logic [31:0] m2_wb_dat_o,
    input  logic [3:0]  m2_wb_sel_i,
    input  logic        m2_wb_we_i,
    input  logic        m2_wb_stb_i,
    input  logic        m2_wb_cyc_i,
    output logic        m2_wb_ack_o,
    output logic        m2_wb_err_o,

    // Slaves:
    // Slave 0: Instruction SRAM (0x0000_0000 - 0x0000_7FFF)
    output logic [31:0] s0_wb_adr_o,
    output logic [31:0] s0_wb_dat_o,
    input  logic [31:0] s0_wb_dat_i,
    output logic [3:0]  s0_wb_sel_o,
    output logic        s0_wb_we_o,
    output logic        s0_wb_stb_o,
    output logic        s0_wb_cyc_o,
    input  logic        s0_wb_ack_i,

    // Slave 1: Data SRAM Port A (0x2000_0000 - 0x2000_FFFF)
    output logic [31:0] s1_wb_adr_o,
    output logic [31:0] s1_wb_dat_o,
    input  logic [31:0] s1_wb_dat_i,
    output logic [3:0]  s1_wb_sel_o,
    output logic        s1_wb_we_o,
    output logic        s1_wb_stb_o,
    output logic        s1_wb_cyc_o,
    input  logic        s1_wb_ack_i,

    // Slave 2: SPI Controller (0x4000_0000 - 0x4000_001F)
    output logic [31:0] s2_wb_adr_o,
    output logic [31:0] s2_wb_dat_o,
    input  logic [31:0] s2_wb_dat_i,
    output logic        s2_wb_we_o,
    output logic        s2_wb_stb_o,
    output logic        s2_wb_cyc_o,
    input  logic        s2_wb_ack_i,

    // Slave 3: DMA Controller Registers (0x4000_1000 - 0x4000_102F)
    output logic [31:0] s3_wb_adr_o,
    output logic [31:0] s3_wb_dat_o,
    input  logic [31:0] s3_wb_dat_i,
    output logic        s3_wb_we_o,
    output logic        s3_wb_stb_o,
    output logic        s3_wb_cyc_o,
    input  logic        s3_wb_ack_i,

    // Slave 4: Systolic Array (0x4000_2000 - 0x4000_203F)
    output logic [31:0] s4_wb_adr_o,
    output logic [31:0] s4_wb_dat_o,
    input  logic [31:0] s4_wb_dat_i,
    output logic        s4_wb_we_o,
    output logic        s4_wb_stb_o,
    output logic        s4_wb_cyc_o,
    input  logic        s4_wb_ack_i,

    // Slave 5: UART (0x4000_3000 - 0x4000_301F)
    output logic [31:0] s5_wb_adr_o,
    output logic [31:0] s5_wb_dat_o,
    input  logic [31:0] s5_wb_dat_i,
    output logic        s5_wb_we_o,
    output logic        s5_wb_stb_o,
    output logic        s5_wb_cyc_o,
    input  logic        s5_wb_ack_i,

    // Slave 6: Timer (0x4000_4000 - 0x4000_401F)
    output logic [31:0] s6_wb_adr_o,
    output logic [31:0] s6_wb_dat_o,
    input  logic [31:0] s6_wb_dat_i,
    output logic        s6_wb_we_o,
    output logic        s6_wb_stb_o,
    output logic        s6_wb_cyc_o,
    input  logic        s6_wb_ack_i,

    // Slave 7: Watchdog (0x4000_5000 - 0x4000_501F)
    output logic [31:0] s7_wb_adr_o,
    output logic [31:0] s7_wb_dat_o,
    input  logic [31:0] s7_wb_dat_i,
    output logic        s7_wb_we_o,
    output logic        s7_wb_stb_o,
    output logic        s7_wb_cyc_o,
    input  logic        s7_wb_ack_i,

    // Slave 8: GPIO (0x4000_6000 - 0x4000_600F)
    output logic [31:0] s8_wb_adr_o,
    output logic [31:0] s8_wb_dat_o,
    input  logic [31:0] s8_wb_dat_i,
    output logic        s8_wb_we_o,
    output logic        s8_wb_stb_o,
    output logic        s8_wb_cyc_o,
    input  logic        s8_wb_ack_i,

    // Slave 9: PIC (0x4000_7000 - 0x4000_701F)
    output logic [31:0] s9_wb_adr_o,
    output logic [31:0] s9_wb_dat_o,
    input  logic [31:0] s9_wb_dat_i,
    output logic        s9_wb_we_o,
    output logic        s9_wb_stb_o,
    output logic        s9_wb_cyc_o,
    input  logic        s9_wb_ack_i
);

    // Arbiter grant: 2'b00 = CPU (M0), 2'b01 = DMA (M1), 2'b10 = SPI (M2)
    logic [1:0] grant;
    logic       master_active;

    wire m0_req = m0_wb_cyc_i && m0_wb_stb_i;
    wire m1_req = m1_wb_cyc_i && m1_wb_stb_i;
    wire m2_req = m2_wb_cyc_i && m2_wb_stb_i;

    // Timeout counter for 64-cycle bus error guard
    logic [5:0] timeout_cnt;
    logic       timeout_err;

    // Mux Slave Read Response signals declaration
    logic [31:0] active_dat_r;
    logic        active_ack;

    // Round-robin arbitration
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant         <= 2'b00;
            master_active <= 1'b0;
            timeout_cnt   <= 6'd0;
            timeout_err   <= 1'b0;
        end else begin
            timeout_err <= 1'b0;

            if (!master_active) begin
                if (m0_req) begin
                    grant         <= 2'b00;
                    master_active <= 1'b1;
                    timeout_cnt   <= 6'd0;
                end else if (m1_req) begin
                    grant         <= 2'b01;
                    master_active <= 1'b1;
                    timeout_cnt   <= 6'd0;
                end else if (m2_req) begin
                    grant         <= 2'b10;
                    master_active <= 1'b1;
                    timeout_cnt   <= 6'd0;
                end
            end else begin
                // Watch for transaction completion or timeout
                if (active_ack || timeout_err) begin
                    master_active <= 1'b0;
                end else begin
                    if (timeout_cnt == 6'd63) begin
                        timeout_err <= 1'b1;
                    end else begin
                        timeout_cnt <= timeout_cnt + 1'b1;
                    end
                end
            end
        end
    end

    // Selected Master signals
    logic [31:0] cur_adr;
    logic [31:0] cur_dat_w;
    logic [3:0]  cur_sel;
    logic        cur_we;
    logic        cur_stb;
    logic        cur_cyc;

    always_comb begin
        case (grant)
            2'b01: begin
                cur_adr   = m1_wb_adr_i;
                cur_dat_w = m1_wb_dat_i;
                cur_sel   = m1_wb_sel_i;
                cur_we    = m1_wb_we_i;
                cur_stb   = m1_wb_stb_i;
                cur_cyc   = m1_wb_cyc_i;
            end
            2'b10: begin
                cur_adr   = m2_wb_adr_i;
                cur_dat_w = m2_wb_dat_i;
                cur_sel   = m2_wb_sel_i;
                cur_we    = m2_wb_we_i;
                cur_stb   = m2_wb_stb_i;
                cur_cyc   = m2_wb_cyc_i;
            end
            default: begin
                cur_adr   = m0_wb_adr_i;
                cur_dat_w = m0_wb_dat_i;
                cur_sel   = m0_wb_sel_i;
                cur_we    = m0_wb_we_i;
                cur_stb   = m0_wb_stb_i;
                cur_cyc   = m0_wb_cyc_i;
            end
        endcase
    end

    // Address Decoding
    // 0x0000_0000 - 0x0000_7FFF : ISRAM
    // 0x2000_0000 - 0x2000_FFFF : DSRAM
    // 0x4000_0000 - 0x4000_0FFF : SPI
    // 0x4000_1000 - 0x4000_1FFF : DMA
    // 0x4000_2000 - 0x4000_2FFF : Systolic Array
    // 0x4000_3000 - 0x4000_3FFF : UART
    // 0x4000_4000 - 0x4000_4FFF : Timer
    // 0x4000_5000 - 0x4000_5FFF : Watchdog
    // 0x4000_6000 - 0x4000_6FFF : GPIO
    // 0x4000_7000 - 0x4000_7FFF : PIC

    wire sel_isram  = (cur_adr[31:16] == 16'h0000);
    wire sel_dsram  = (cur_adr[31:16] == 16'h2000);
    wire sel_spi    = (cur_adr[31:12] == 20'h40000);
    wire sel_dma    = (cur_adr[31:12] == 20'h40001);
    wire sel_array  = (cur_adr[31:12] == 20'h40002);
    wire sel_uart   = (cur_adr[31:12] == 20'h40003);
    wire sel_timer  = (cur_adr[31:12] == 20'h40004);
    wire sel_wdt    = (cur_adr[31:12] == 20'h40005);
    wire sel_gpio   = (cur_adr[31:12] == 20'h40006);
    wire sel_pic    = (cur_adr[31:12] == 20'h40007);

    // Drive Slave 0 (ISRAM)
    assign s0_wb_adr_o = cur_adr;
    assign s0_wb_dat_o = cur_dat_w;
    assign s0_wb_sel_o = cur_sel;
    assign s0_wb_we_o  = cur_we;
    assign s0_wb_stb_o = cur_stb && sel_isram;
    assign s0_wb_cyc_o = cur_cyc && sel_isram;

    // Drive Slave 1 (DSRAM)
    assign s1_wb_adr_o = cur_adr;
    assign s1_wb_dat_o = cur_dat_w;
    assign s1_wb_sel_o = cur_sel;
    assign s1_wb_we_o  = cur_we;
    assign s1_wb_stb_o = cur_stb && sel_dsram;
    assign s1_wb_cyc_o = cur_cyc && sel_dsram;

    // Drive Slave 2 (SPI)
    assign s2_wb_adr_o = cur_adr;
    assign s2_wb_dat_o = cur_dat_w;
    assign s2_wb_we_o  = cur_we;
    assign s2_wb_stb_o = cur_stb && sel_spi;
    assign s2_wb_cyc_o = cur_cyc && sel_spi;

    // Drive Slave 3 (DMA)
    assign s3_wb_adr_o = cur_adr;
    assign s3_wb_dat_o = cur_dat_w;
    assign s3_wb_we_o  = cur_we;
    assign s3_wb_stb_o = cur_stb && sel_dma;
    assign s3_wb_cyc_o = cur_cyc && sel_dma;

    // Drive Slave 4 (Systolic Array)
    assign s4_wb_adr_o = cur_adr;
    assign s4_wb_dat_o = cur_dat_w;
    assign s4_wb_we_o  = cur_we;
    assign s4_wb_stb_o = cur_stb && sel_array;
    assign s4_wb_cyc_o = cur_cyc && sel_array;

    // Drive Slave 5 (UART)
    assign s5_wb_adr_o = cur_adr;
    assign s5_wb_dat_o = cur_dat_w;
    assign s5_wb_we_o  = cur_we;
    assign s5_wb_stb_o = cur_stb && sel_uart;
    assign s5_wb_cyc_o = cur_cyc && sel_uart;

    // Drive Slave 6 (Timer)
    assign s6_wb_adr_o = cur_adr;
    assign s6_wb_dat_o = cur_dat_w;
    assign s6_wb_we_o  = cur_we;
    assign s6_wb_stb_o = cur_stb && sel_timer;
    assign s6_wb_cyc_o = cur_cyc && sel_timer;

    // Drive Slave 7 (Watchdog)
    assign s7_wb_adr_o = cur_adr;
    assign s7_wb_dat_o = cur_dat_w;
    assign s7_wb_we_o  = cur_we;
    assign s7_wb_stb_o = cur_stb && sel_wdt;
    assign s7_wb_cyc_o = cur_cyc && sel_wdt;

    // Drive Slave 8 (GPIO)
    assign s8_wb_adr_o = cur_adr;
    assign s8_wb_dat_o = cur_dat_w;
    assign s8_wb_we_o  = cur_we;
    assign s8_wb_stb_o = cur_stb && sel_gpio;
    assign s8_wb_cyc_o = cur_cyc && sel_gpio;

    // Drive Slave 9 (PIC)
    assign s9_wb_adr_o = cur_adr;
    assign s9_wb_dat_o = cur_dat_w;
    assign s9_wb_we_o  = cur_we;
    assign s9_wb_stb_o = cur_stb && sel_pic;
    assign s9_wb_cyc_o = cur_cyc && sel_pic;

    // Mux Slave Read Response
    always_comb begin
        if (sel_isram) begin
            active_dat_r = s0_wb_dat_i;
            active_ack   = s0_wb_ack_i;
        end else if (sel_dsram) begin
            active_dat_r = s1_wb_dat_i;
            active_ack   = s1_wb_ack_i;
        end else if (sel_spi) begin
            active_dat_r = s2_wb_dat_i;
            active_ack   = s2_wb_ack_i;
        end else if (sel_dma) begin
            active_dat_r = s3_wb_dat_i;
            active_ack   = s3_wb_ack_i;
        end else if (sel_array) begin
            active_dat_r = s4_wb_dat_i;
            active_ack   = s4_wb_ack_i;
        end else if (sel_uart) begin
            active_dat_r = s5_wb_dat_i;
            active_ack   = s5_wb_ack_i;
        end else if (sel_timer) begin
            active_dat_r = s6_wb_dat_i;
            active_ack   = s6_wb_ack_i;
        end else if (sel_wdt) begin
            active_dat_r = s7_wb_dat_i;
            active_ack   = s7_wb_ack_i;
        end else if (sel_gpio) begin
            active_dat_r = s8_wb_dat_i;
            active_ack   = s8_wb_ack_i;
        end else if (sel_pic) begin
            active_dat_r = s9_wb_dat_i;
            active_ack   = s9_wb_ack_i;
        end else begin
            active_dat_r = 32'h0000_0000;
            active_ack   = 1'b0;
        end
    end

    // Route response back to granted Master
    assign m0_wb_dat_o = active_dat_r;
    assign m0_wb_ack_o = (grant == 2'b00) ? active_ack   : 1'b0;
    assign m0_wb_err_o = (grant == 2'b00) ? timeout_err  : 1'b0;

    assign m1_wb_dat_o = active_dat_r;
    assign m1_wb_ack_o = (grant == 2'b01) ? active_ack   : 1'b0;
    assign m1_wb_err_o = (grant == 2'b01) ? timeout_err  : 1'b0;

    assign m2_wb_dat_o = active_dat_r;
    assign m2_wb_ack_o = (grant == 2'b10) ? active_ack   : 1'b0;
    assign m2_wb_err_o = (grant == 2'b10) ? timeout_err  : 1'b0;

endmodule
