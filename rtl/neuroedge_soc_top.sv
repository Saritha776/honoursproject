// ==============================================================================
// Module: neuroedge_soc_top.sv
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: Top-Level System-on-Chip integrating:
//              - 32 KB Instruction SRAM (0x0000_0000)
//              - 64 KB Dual-Port Data SRAM (0x2000_0000)
//              - 32-bit Crossbar Interconnect with 64-cycle timeout guard
//              - Dual-Channel DMA Controller (0x4000_1000)
//              - 4x4 Weight-Stationary Systolic Array Accelerator (0x4000_2000)
//              - Master SPI Flash Controller (0x4000_0000)
//              - 16550 UART Transceiver (0x4000_3000)
//              - 32-bit Precision Timer (0x4000_4000)
//              - Hardware Watchdog Timer (0x4000_5000)
//              - 8-bit GPIO Module (0x4000_6000)
//              - Platform Interrupt Controller (0x4000_7000)
// ==============================================================================

`timescale 1ns / 1ps

module neuroedge_soc_top (
    input  logic        clk,
    input  logic        rst_n,
    
    // CPU Bus Master Port (Wishbone Interface from Core or Bridge)
    input  logic [31:0] cpu_wb_adr_i,
    input  logic [31:0] cpu_wb_dat_i,
    output logic [31:0] cpu_wb_dat_o,
    input  logic [3:0]  cpu_wb_sel_i,
    input  logic        cpu_wb_we_i,
    input  logic        cpu_wb_stb_i,
    input  logic        cpu_wb_cyc_i,
    output logic        cpu_wb_ack_o,
    output logic        cpu_wb_err_o,
    
    // Vectored Interrupt Output to CPU Core
    output logic [5:0]  cpu_irq_vec_o,

    // External SPI Flash Pins
    output logic        spi_sclk,
    output logic        spi_mosi,
    input  logic        spi_miso,
    output logic        spi_cs_n,

    // External UART Pins
    output logic        uart_tx,
    input  logic        uart_rx,

    // External GPIO Pins
    input  logic [7:0]  gpio_in,
    output logic [7:0]  gpio_out,
    output logic [7:0]  gpio_dir,

    // Watchdog Reset Line
    output logic        wdt_reset_out
);

    // =========================================================================
    // Internal Wires & Buses
    // =========================================================================

    // DMA Master Bus (M1)
    logic [31:0] dma_wb_adr;
    logic [31:0] dma_wb_dat_w;
    logic [31:0] dma_wb_dat_r;
    logic [3:0]  dma_wb_sel;
    logic        dma_wb_we;
    logic        dma_wb_stb;
    logic        dma_wb_cyc;
    logic        dma_wb_ack;
    logic        dma_wb_err;
    assign dma_wb_sel = 4'b1111;

    // SPI Auto-Loader Master Bus (M2)
    logic [31:0] spi_m_wb_adr;
    logic [31:0] spi_m_wb_dat_w;
    logic [31:0] spi_m_wb_dat_r;
    logic [3:0]  spi_m_wb_sel;
    logic        spi_m_wb_we;
    logic        spi_m_wb_stb;
    logic        spi_m_wb_cyc;
    logic        spi_m_wb_ack;
    logic        spi_m_wb_err;
    assign spi_m_wb_sel = 4'b1111;

    // Slave 0: ISRAM
    logic [31:0] s0_adr, s0_wdat, s0_rdat;
    logic [3:0]  s0_sel;
    logic        s0_we, s0_stb, s0_cyc, s0_ack;

    // Slave 1: DSRAM Port A
    logic [31:0] s1_adr, s1_wdat, s1_rdat;
    logic [3:0]  s1_sel;
    logic        s1_we, s1_stb, s1_cyc, s1_ack;

    // Slave 2: SPI
    logic [31:0] s2_adr, s2_wdat, s2_rdat;
    logic        s2_we, s2_stb, s2_cyc, s2_ack;

    // Slave 3: DMA
    logic [31:0] s3_adr, s3_wdat, s3_rdat;
    logic        s3_we, s3_stb, s3_cyc, s3_ack;

    // Slave 4: Systolic Array
    logic [31:0] s4_adr, s4_wdat, s4_rdat;
    logic        s4_we, s4_stb, s4_cyc, s4_ack;

    // Slave 5: UART
    logic [31:0] s5_adr, s5_wdat, s5_rdat;
    logic        s5_we, s5_stb, s5_cyc, s5_ack;

    // Slave 6: Timer
    logic [31:0] s6_adr, s6_wdat, s6_rdat;
    logic        s6_we, s6_stb, s6_cyc, s6_ack;

    // Slave 7: Watchdog
    logic [31:0] s7_adr, s7_wdat, s7_rdat;
    logic        s7_we, s7_stb, s7_cyc, s7_ack;

    // Slave 8: GPIO
    logic [31:0] s8_adr, s8_wdat, s8_rdat;
    logic        s8_we, s8_stb, s8_cyc, s8_ack;

    // Slave 9: PIC
    logic [31:0] s9_adr, s9_wdat, s9_rdat;
    logic        s9_we, s9_stb, s9_cyc, s9_ack;

    // Direct High-Speed Streaming Links: DMA -> Systolic Array
    logic        dma_act_valid;
    logic [31:0] dma_act_data;
    logic        dma_wgt_valid;
    logic [31:0] dma_wgt_data;

    // Interrupt Lines: Peripherals -> PIC
    logic        irq_wdt;
    logic        irq_timer;
    logic        irq_array;
    logic        irq_dma;
    logic        irq_uart;
    logic        irq_gpio;

    // =========================================================================
    // Interconnect Crossbar
    // =========================================================================
    soc_interconnect u_interconnect (
        .clk        (clk),
        .rst_n      (rst_n),

        // Masters
        .m0_wb_adr_i(cpu_wb_adr_i),
        .m0_wb_dat_i(cpu_wb_dat_i),
        .m0_wb_dat_o(cpu_wb_dat_o),
        .m0_wb_sel_i(cpu_wb_sel_i),
        .m0_wb_we_i (cpu_wb_we_i),
        .m0_wb_stb_i(cpu_wb_stb_i),
        .m0_wb_cyc_i(cpu_wb_cyc_i),
        .m0_wb_ack_o(cpu_wb_ack_o),
        .m0_wb_err_o(cpu_wb_err_o),

        .m1_wb_adr_i(dma_wb_adr),
        .m1_wb_dat_i(dma_wb_dat_w),
        .m1_wb_dat_o(dma_wb_dat_r),
        .m1_wb_sel_i(dma_wb_sel),
        .m1_wb_we_i (dma_wb_we),
        .m1_wb_stb_i(dma_wb_stb),
        .m1_wb_cyc_i(dma_wb_cyc),
        .m1_wb_ack_o(dma_wb_ack),
        .m1_wb_err_o(dma_wb_err),

        .m2_wb_adr_i(spi_m_wb_adr),
        .m2_wb_dat_i(spi_m_wb_dat_w),
        .m2_wb_dat_o(spi_m_wb_dat_r),
        .m2_wb_sel_i(spi_m_wb_sel),
        .m2_wb_we_i (spi_m_wb_we),
        .m2_wb_stb_i(spi_m_wb_stb),
        .m2_wb_cyc_i(spi_m_wb_cyc),
        .m2_wb_ack_o(spi_m_wb_ack),
        .m2_wb_err_o(spi_m_wb_err),

        // Slaves
        .s0_wb_adr_o(s0_adr),
        .s0_wb_dat_o(s0_wdat),
        .s0_wb_dat_i(s0_rdat),
        .s0_wb_sel_o(s0_sel),
        .s0_wb_we_o (s0_we),
        .s0_wb_stb_o(s0_stb),
        .s0_wb_cyc_o(s0_cyc),
        .s0_wb_ack_i(s0_ack),

        .s1_wb_adr_o(s1_adr),
        .s1_wb_dat_o(s1_wdat),
        .s1_wb_dat_i(s1_rdat),
        .s1_wb_sel_o(s1_sel),
        .s1_wb_we_o (s1_we),
        .s1_wb_stb_o(s1_stb),
        .s1_wb_cyc_o(s1_cyc),
        .s1_wb_ack_i(s1_ack),

        .s2_wb_adr_o(s2_adr),
        .s2_wb_dat_o(s2_wdat),
        .s2_wb_dat_i(s2_rdat),
        .s2_wb_we_o (s2_we),
        .s2_wb_stb_o(s2_stb),
        .s2_wb_cyc_o(s2_cyc),
        .s2_wb_ack_i(s2_ack),

        .s3_wb_adr_o(s3_adr),
        .s3_wb_dat_o(s3_wdat),
        .s3_wb_dat_i(s3_rdat),
        .s3_wb_we_o (s3_we),
        .s3_wb_stb_o(s3_stb),
        .s3_wb_cyc_o(s3_cyc),
        .s3_wb_ack_i(s3_ack),

        .s4_wb_adr_o(s4_adr),
        .s4_wb_dat_o(s4_wdat),
        .s4_wb_dat_i(s4_rdat),
        .s4_wb_we_o (s4_we),
        .s4_wb_stb_o(s4_stb),
        .s4_wb_cyc_o(s4_cyc),
        .s4_wb_ack_i(s4_ack),

        .s5_wb_adr_o(s5_adr),
        .s5_wb_dat_o(s5_wdat),
        .s5_wb_dat_i(s5_rdat),
        .s5_wb_we_o (s5_we),
        .s5_wb_stb_o(s5_stb),
        .s5_wb_cyc_o(s5_cyc),
        .s5_wb_ack_i(s5_ack),

        .s6_wb_adr_o(s6_adr),
        .s6_wb_dat_o(s6_wdat),
        .s6_wb_dat_i(s6_rdat),
        .s6_wb_we_o (s6_we),
        .s6_wb_stb_o(s6_stb),
        .s6_wb_cyc_o(s6_cyc),
        .s6_wb_ack_i(s6_ack),

        .s7_wb_adr_o(s7_adr),
        .s7_wb_dat_o(s7_wdat),
        .s7_wb_dat_i(s7_rdat),
        .s7_wb_we_o (s7_we),
        .s7_wb_stb_o(s7_stb),
        .s7_wb_cyc_o(s7_cyc),
        .s7_wb_ack_i(s7_ack),

        .s8_wb_adr_o(s8_adr),
        .s8_wb_dat_o(s8_wdat),
        .s8_wb_dat_i(s8_rdat),
        .s8_wb_we_o (s8_we),
        .s8_wb_stb_o(s8_stb),
        .s8_wb_cyc_o(s8_cyc),
        .s8_wb_ack_i(s8_ack),

        .s9_wb_adr_o(s9_adr),
        .s9_wb_dat_o(s9_wdat),
        .s9_wb_dat_i(s9_rdat),
        .s9_wb_we_o (s9_we),
        .s9_wb_stb_o(s9_stb),
        .s9_wb_cyc_o(s9_cyc),
        .s9_wb_ack_i(s9_ack)
    );

    // =========================================================================
    // Memory Subsystem
    // =========================================================================
    sram_sp_32k u_isram (
        .clk        (clk),
        .rst_n      (rst_n),
        .wb_adr_i   (s0_adr),
        .wb_dat_i   (s0_wdat),
        .wb_dat_o   (s0_rdat),
        .wb_sel_i   (s0_sel),
        .wb_we_i    (s0_we),
        .wb_stb_i   (s0_stb),
        .wb_cyc_i   (s0_cyc),
        .wb_ack_o   (s0_ack)
    );

    sram_dp_64k u_dsram (
        .clk        (clk),
        .rst_n      (rst_n),
        // Port A (Interconnect)
        .a_wb_adr_i (s1_adr),
        .a_wb_dat_i (s1_wdat),
        .a_wb_dat_o (s1_rdat),
        .a_wb_sel_i (s1_sel),
        .a_wb_we_i  (s1_we),
        .a_wb_stb_i (s1_stb),
        .a_wb_cyc_i (s1_cyc),
        .a_wb_ack_o (s1_ack),
        // Port B (Unused / Tied)
        .b_wb_adr_i (32'd0),
        .b_wb_dat_i (32'd0),
        .b_wb_dat_o (),
        .b_wb_sel_i (4'b0000),
        .b_wb_we_i  (1'b0),
        .b_wb_stb_i (1'b0),
        .b_wb_cyc_i (1'b0),
        .b_wb_ack_o ()
    );

    // =========================================================================
    // Accelerators & Direct Streaming
    // =========================================================================
    systolic_array_4x4 u_systolic_array (
        .clk           (clk),
        .rst_n         (rst_n),
        .wb_adr_i      (s4_adr),
        .wb_dat_i      (s4_wdat),
        .wb_dat_o      (s4_rdat),
        .wb_we_i       (s4_we),
        .wb_stb_i      (s4_stb),
        .wb_cyc_i      (s4_cyc),
        .wb_ack_o      (s4_ack),
        // Streaming Ports
        .dma_act_valid (dma_act_valid),
        .dma_act_data  (dma_act_data),
        .dma_wgt_valid (dma_wgt_valid),
        .dma_wgt_data  (dma_wgt_data),
        .array_irq     (irq_array)
    );

    dma_controller u_dma (
        .clk           (clk),
        .rst_n         (rst_n),
        // Slave Register Port
        .s_wb_adr_i    (s3_adr),
        .s_wb_dat_i    (s3_wdat),
        .s_wb_dat_o    (s3_rdat),
        .s_wb_we_i     (s3_we),
        .s_wb_stb_i    (s3_stb),
        .s_wb_cyc_i    (s3_cyc),
        .s_wb_ack_o    (s3_ack),
        // Master Bus Port
        .m_wb_adr_o    (dma_wb_adr),
        .m_wb_dat_o    (dma_wb_dat_w),
        .m_wb_dat_i    (dma_wb_dat_r),
        .m_wb_we_o     (dma_wb_we),
        .m_wb_stb_o    (dma_wb_stb),
        .m_wb_cyc_o    (dma_wb_cyc),
        .m_wb_ack_i    (dma_wb_ack),
        .m_wb_err_i    (dma_wb_err),
        // Direct Streaming Outputs
        .dma_act_valid (dma_act_valid),
        .dma_act_data  (dma_act_data),
        .dma_wgt_valid (dma_wgt_valid),
        .dma_wgt_data  (dma_wgt_data),
        .dma_irq       (irq_dma)
    );

    // =========================================================================
    // Peripherals
    // =========================================================================
    spi_flash_ctrl u_spi (
        .clk         (clk),
        .rst_n       (rst_n),
        // Slave Port
        .s_wb_adr_i  (s2_adr),
        .s_wb_dat_i  (s2_wdat),
        .s_wb_dat_o  (s2_rdat),
        .s_wb_we_i   (s2_we),
        .s_wb_stb_i  (s2_stb),
        .s_wb_cyc_i  (s2_cyc),
        .s_wb_ack_o  (s2_ack),
        // Master Auto-Write Port
        .m_wb_adr_o  (spi_m_wb_adr),
        .m_wb_dat_o  (spi_m_wb_dat_w),
        .m_wb_we_o   (spi_m_wb_we),
        .m_wb_stb_o  (spi_m_wb_stb),
        .m_wb_cyc_o  (spi_m_wb_cyc),
        .m_wb_ack_i  (spi_m_wb_ack),
        // Physical Pins
        .spi_sclk    (spi_sclk),
        .spi_mosi    (spi_mosi),
        .spi_miso    (spi_miso),
        .spi_cs_n    (spi_cs_n),
        .spi_irq     ()
    );

    uart_16550 u_uart (
        .clk         (clk),
        .rst_n       (rst_n),
        .wb_adr_i    (s5_adr),
        .wb_dat_i    (s5_wdat),
        .wb_dat_o    (s5_rdat),
        .wb_we_i     (s5_we),
        .wb_stb_i    (s5_stb),
        .wb_cyc_i    (s5_cyc),
        .wb_ack_o    (s5_ack),
        .uart_tx     (uart_tx),
        .uart_rx     (uart_rx),
        .uart_irq    (irq_uart)
    );

    timer_32bit u_timer (
        .clk         (clk),
        .rst_n       (rst_n),
        .wb_adr_i    (s6_adr),
        .wb_dat_i    (s6_wdat),
        .wb_dat_o    (s6_rdat),
        .wb_we_i     (s6_we),
        .wb_stb_i    (s6_stb),
        .wb_cyc_i    (s6_cyc),
        .wb_ack_o    (s6_ack),
        .timer_irq   (irq_timer)
    );

    watchdog_timer u_wdt (
        .clk          (clk),
        .rst_n        (rst_n),
        .wb_adr_i     (s7_adr),
        .wb_dat_i     (s7_wdat),
        .wb_dat_o     (s7_rdat),
        .wb_we_i      (s7_we),
        .wb_stb_i     (s7_stb),
        .wb_cyc_i     (s7_cyc),
        .wb_ack_o     (s7_ack),
        .wdt_irq      (irq_wdt),
        .wdt_reset_out(wdt_reset_out)
    );

    gpio_8bit u_gpio (
        .clk         (clk),
        .rst_n       (rst_n),
        .wb_adr_i    (s8_adr),
        .wb_dat_i    (s8_wdat),
        .wb_dat_o    (s8_rdat),
        .wb_we_i     (s8_we),
        .wb_stb_i    (s8_stb),
        .wb_cyc_i    (s8_cyc),
        .wb_ack_o    (s8_ack),
        .gpio_in     (gpio_in),
        .gpio_out    (gpio_out),
        .gpio_dir_o  (gpio_dir),
        .gpio_irq    (irq_gpio)
    );

    pic_controller u_pic (
        .clk         (clk),
        .rst_n       (rst_n),
        .wb_adr_i    (s9_adr),
        .wb_dat_i    (s9_wdat),
        .wb_dat_o    (s9_rdat),
        .wb_we_i     (s9_we),
        .wb_stb_i    (s9_stb),
        .wb_cyc_i    (s9_cyc),
        .wb_ack_o    (s9_ack),
        .irq_lines_i ({irq_gpio, irq_uart, irq_dma, irq_array, irq_timer, irq_wdt}),
        .irq_vec_o   (cpu_irq_vec_o)
    );

endmodule
