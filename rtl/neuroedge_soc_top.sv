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

module neuroedge_soc_top #(
    parameter BOOT_HEX        = "../firmware/neuroedge_test.hex",
    parameter ENABLE_VEER_CPU = 1
)(
    input  logic        clk,
    input  logic        rst_n,
    
    // CPU Bus Master Port (Wishbone Interface from Core or Bridge)
    input  logic        cpu_override_i,
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
    output logic        wdt_reset_out,

    // CPU Trace & Telemetry Monitoring
    output logic [31:0] cpu_trace_pc_o,
    output logic [31:0] cpu_trace_insn_o,
    output logic        cpu_trace_valid_o
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
    // Master 0: CPU Bus Signals & VeeR EL2 Subsystem
    // =========================================================================
    logic [31:0] core_m0_adr, core_m0_dat_w, core_m0_dat_r;
    logic [3:0]  core_m0_sel;
    logic        core_m0_we, core_m0_stb, core_m0_cyc, core_m0_ack, core_m0_err;

    // Bridge signals from VeeR AXI4 to Wishbone
    logic [31:0] bridge_wb_adr, bridge_wb_dat_w, bridge_wb_dat_r;
    logic [3:0]  bridge_wb_sel;
    logic        bridge_wb_we, bridge_wb_stb, bridge_wb_cyc, bridge_wb_ack, bridge_wb_err;

    // AXI4 Busses between VeeR Core and Dual-Master Bridge
    logic [7:0]  lsu_axi_awid, lsu_axi_bid, lsu_axi_arid, lsu_axi_rid;
    logic [31:0] lsu_axi_awaddr, lsu_axi_araddr;
    logic [7:0]  lsu_axi_awlen, lsu_axi_arlen;
    logic [2:0]  lsu_axi_awsize, lsu_axi_arsize;
    logic [1:0]  lsu_axi_awburst, lsu_axi_arburst;
    logic        lsu_axi_awvalid, lsu_axi_awready;
    logic [63:0] lsu_axi_wdata, lsu_axi_rdata;
    logic [7:0]  lsu_axi_wstrb;
    logic        lsu_axi_wlast, lsu_axi_wvalid, lsu_axi_wready;
    logic [1:0]  lsu_axi_bresp, lsu_axi_rresp;
    logic        lsu_axi_bvalid, lsu_axi_bready;
    logic        lsu_axi_arvalid, lsu_axi_arready;
    logic        lsu_axi_rlast, lsu_axi_rvalid, lsu_axi_rready;

    logic [2:0]  ifu_axi_arid, ifu_axi_rid;
    logic [31:0] ifu_axi_araddr;
    logic [7:0]  ifu_axi_arlen;
    logic [2:0]  ifu_axi_arsize;
    logic [1:0]  ifu_axi_arburst;
    logic        ifu_axi_arvalid, ifu_axi_arready;
    logic [63:0] ifu_axi_rdata;
    logic [1:0]  ifu_axi_rresp;
    logic        ifu_axi_rlast, ifu_axi_rvalid, ifu_axi_rready;

    logic [31:0] veer_pc, veer_insn;
    logic        veer_valid;

    generate
        if (ENABLE_VEER_CPU) begin : gen_veer_cpu
            assign cpu_trace_pc_o    = veer_pc;
            assign cpu_trace_insn_o  = veer_insn;
            assign cpu_trace_valid_o = veer_valid;

            veer_wrapper u_cpu (
                .clk                     (clk),
                .rst_l                   (rst_n),
                .dbg_rst_l               (rst_n),
                .rst_vec                 (31'd0), // Boot PC = 0x00000000
                .nmi_int                 (1'b0),
                .nmi_vec                 (31'd0),
                .jtag_id                 (31'd0),

                .trace_rv_i_insn_ip      (veer_insn),
                .trace_rv_i_address_ip   (veer_pc),
                .trace_rv_i_valid_ip     (veer_valid),
                .trace_rv_i_exception_ip (),
                .trace_rv_i_ecause_ip    (),
                .trace_rv_i_interrupt_ip (),
                .trace_rv_i_tval_ip      (),

                // LSU AXI
                .lsu_axi_awvalid         (lsu_axi_awvalid),
                .lsu_axi_awready         (lsu_axi_awready),
                .lsu_axi_awid            (lsu_axi_awid),
                .lsu_axi_awaddr          (lsu_axi_awaddr),
                .lsu_axi_awregion        (),
                .lsu_axi_awlen           (lsu_axi_awlen),
                .lsu_axi_awsize          (lsu_axi_awsize),
                .lsu_axi_awburst         (lsu_axi_awburst),
                .lsu_axi_awlock          (),
                .lsu_axi_awcache         (),
                .lsu_axi_awprot          (),
                .lsu_axi_awqos           (),

                .lsu_axi_wvalid          (lsu_axi_wvalid),
                .lsu_axi_wready          (lsu_axi_wready),
                .lsu_axi_wdata           (lsu_axi_wdata),
                .lsu_axi_wstrb           (lsu_axi_wstrb),
                .lsu_axi_wlast           (lsu_axi_wlast),

                .lsu_axi_bvalid          (lsu_axi_bvalid),
                .lsu_axi_bready          (lsu_axi_bready),
                .lsu_axi_bresp           (lsu_axi_bresp),
                .lsu_axi_bid             (lsu_axi_bid),

                .lsu_axi_arvalid         (lsu_axi_arvalid),
                .lsu_axi_arready         (lsu_axi_arready),
                .lsu_axi_arid            (lsu_axi_arid),
                .lsu_axi_araddr          (lsu_axi_araddr),
                .lsu_axi_arregion        (),
                .lsu_axi_arlen           (lsu_axi_arlen),
                .lsu_axi_arsize          (lsu_axi_arsize),
                .lsu_axi_arburst         (lsu_axi_arburst),
                .lsu_axi_arlock          (),
                .lsu_axi_arcache         (),
                .lsu_axi_arprot          (),
                .lsu_axi_arqos           (),

                .lsu_axi_rvalid          (lsu_axi_rvalid),
                .lsu_axi_rready          (lsu_axi_rready),
                .lsu_axi_rid             (lsu_axi_rid),
                .lsu_axi_rdata           (lsu_axi_rdata),
                .lsu_axi_rresp           (lsu_axi_rresp),
                .lsu_axi_rlast           (lsu_axi_rlast),

                // IFU AXI
                .ifu_axi_awvalid         (),
                .ifu_axi_awready         (1'b0),
                .ifu_axi_awid            (),
                .ifu_axi_awaddr          (),
                .ifu_axi_awregion        (),
                .ifu_axi_awlen           (),
                .ifu_axi_awsize          (),
                .ifu_axi_awburst         (),
                .ifu_axi_awlock          (),
                .ifu_axi_awcache         (),
                .ifu_axi_awprot          (),
                .ifu_axi_awqos           (),

                .ifu_axi_wvalid          (),
                .ifu_axi_wready          (1'b0),
                .ifu_axi_wdata           (),
                .ifu_axi_wstrb           (),
                .ifu_axi_wlast           (),

                .ifu_axi_bvalid          (1'b0),
                .ifu_axi_bready          (),
                .ifu_axi_bresp           (2'b00),
                .ifu_axi_bid             (3'b000),

                .ifu_axi_arvalid         (ifu_axi_arvalid),
                .ifu_axi_arready         (ifu_axi_arready),
                .ifu_axi_arid            (ifu_axi_arid),
                .ifu_axi_araddr          (ifu_axi_araddr),
                .ifu_axi_arregion        (),
                .ifu_axi_arlen           (ifu_axi_arlen),
                .ifu_axi_arsize          (ifu_axi_arsize),
                .ifu_axi_arburst         (ifu_axi_arburst),
                .ifu_axi_arlock          (),
                .ifu_axi_arcache         (),
                .ifu_axi_arprot          (),
                .ifu_axi_arqos           (),

                .ifu_axi_rvalid          (ifu_axi_rvalid),
                .ifu_axi_rready          (ifu_axi_rready),
                .ifu_axi_rid             (ifu_axi_rid),
                .ifu_axi_rdata           (ifu_axi_rdata),
                .ifu_axi_rresp           (ifu_axi_rresp),
                .ifu_axi_rlast           (ifu_axi_rlast),

                // SB AXI (Tied off)
                .sb_axi_awvalid          (),
                .sb_axi_awready          (1'b0),
                .sb_axi_awid             (),
                .sb_axi_awaddr           (),
                .sb_axi_awregion         (),
                .sb_axi_awlen            (),
                .sb_axi_awsize           (),
                .sb_axi_awburst          (),
                .sb_axi_awlock           (),
                .sb_axi_awcache          (),
                .sb_axi_awprot           (),
                .sb_axi_awqos            (),

                .sb_axi_wvalid           (),
                .sb_axi_wready           (1'b0),
                .sb_axi_wdata            (),
                .sb_axi_wstrb            (),
                .sb_axi_wlast            (),

                .sb_axi_bvalid           (1'b0),
                .sb_axi_bready           (),
                .sb_axi_bresp            (2'b00),
                .sb_axi_bid              (1'b0),

                .sb_axi_arvalid          (),
                .sb_axi_arready          (1'b0),
                .sb_axi_arid             (),
                .sb_axi_araddr           (),
                .sb_axi_arregion         (),
                .sb_axi_arlen            (),
                .sb_axi_arsize           (),
                .sb_axi_arburst          (),
                .sb_axi_arlock           (),
                .sb_axi_arcache          (),
                .sb_axi_arprot           (),
                .sb_axi_arqos            (),

                .sb_axi_rvalid           (1'b0),
                .sb_axi_rready           (),
                .sb_axi_rid              (1'b0),
                .sb_axi_rdata            (64'd0),
                .sb_axi_rresp            (2'b00),
                .sb_axi_rlast            (1'b0),

                // DMA Slave AXI (Tied off)
                .dma_axi_awvalid         (1'b0),
                .dma_axi_awready         (),
                .dma_axi_awid            (1'b0),
                .dma_axi_awaddr          (32'd0),
                .dma_axi_awsize          (3'd0),
                .dma_axi_awprot          (3'd0),
                .dma_axi_awlen           (8'd0),
                .dma_axi_awburst         (2'd0),

                .dma_axi_wvalid          (1'b0),
                .dma_axi_wready          (),
                .dma_axi_wdata           (64'd0),
                .dma_axi_wstrb           (8'd0),
                .dma_axi_wlast           (1'b0),

                .dma_axi_bvalid          (),
                .dma_axi_bready          (1'b0),
                .dma_axi_bresp           (),
                .dma_axi_bid             (),

                .dma_axi_arvalid         (1'b0),
                .dma_axi_arready         (),
                .dma_axi_arid            (1'b0),
                .dma_axi_araddr          (32'd0),
                .dma_axi_arsize          (3'd0),
                .dma_axi_arprot          (3'd0),
                .dma_axi_arlen           (8'd0),
                .dma_axi_arburst         (2'd0),

                .dma_axi_rvalid          (),
                .dma_axi_rready          (1'b0),
                .dma_axi_rid             (),
                .dma_axi_rdata           (),
                .dma_axi_rresp           (),
                .dma_axi_rlast           (),

                // Clock enable & Interrupts
                .lsu_bus_clk_en          (1'b1),
                .ifu_bus_clk_en          (1'b1),
                .dbg_bus_clk_en          (1'b1),
                .dma_bus_clk_en          (1'b1),
                .timer_int               (1'b0),
                .soft_int                (1'b0),
                .extintsrc_req           ({25'd0, cpu_irq_vec_o}),

                // JTAG
                .jtag_tck                (1'b0),
                .jtag_tms                (1'b0),
                .jtag_tdi                (1'b0),
                .jtag_trst_n             (1'b1),
                .jtag_tdo                (),
                .jtag_tdoEn              (),

                .core_id                 (28'd0),

                // Memory / ECC / Coverage
                .mem_clk                 (),
                .iccm_clken              (),
                .iccm_wren_bank          (),
                .iccm_addr_bank          (),
                .iccm_bank_wr_data       (),
                .iccm_bank_wr_ecc        (),
                .iccm_bank_dout          ('0),
                .iccm_bank_ecc           ('0),

                .dccm_clken              (),
                .dccm_wren_bank          (),
                .dccm_addr_bank          (),
                .dccm_wr_data_bank       (),
                .dccm_wr_ecc_bank        (),
                .dccm_bank_dout          ('0),
                .dccm_bank_ecc           ('0),

                .ic_b_sb_wren            (),
                .ic_b_sb_bit_en_vec      (),
                .ic_sb_wr_data           (),
                .ic_rw_addr_bank_q       (),
                .ic_bank_way_clken_final (),
                .ic_bank_way_clken_final_up(),
                .wb_packeddout_pre       ('0),
                .wb_dout_pre_up          ('0),

                .ic_tag_clken_final      (),
                .ic_tag_wren_q           (),
                .ic_tag_wren_biten_vec   (),
                .ic_tag_wr_data          (),
                .ic_rw_addr_q            (),
                .ic_tag_data_raw_pre     ('0),
                .ic_tag_data_raw_packed_pre('0),

                .iccm_ecc_single_error   (),
                .iccm_ecc_double_error   (),
                .dccm_ecc_single_error   (),
                .dccm_ecc_double_error   (),
                .dccm_write_readback_error(),

                .mpc_debug_halt_req      (1'b0),
                .mpc_debug_run_req       (1'b0),
                .mpc_reset_run_req       (1'b1), // Run immediately after reset!
                .mpc_debug_halt_ack      (),
                .mpc_debug_run_ack       (),
                .debug_brkpt_status      (),

                .i_cpu_halt_req          (1'b0),
                .o_cpu_halt_ack          (),
                .o_cpu_halt_status       (),
                .o_debug_mode_status     (),
                .i_cpu_run_req           (1'b0),
                .o_cpu_run_ack           (),
                .scan_mode               (1'b0),
                .mbist_mode              (1'b0),

                .dmi_core_enable         (1'b0),
                .dmi_uncore_enable       (1'b0),
                .dmi_uncore_en           (),
                .dmi_uncore_wr_en        (),
                .dmi_uncore_addr         (),
                .dmi_uncore_wdata        (),
                .dmi_uncore_rdata        (32'd0),
                .dmi_active              ()
            );

            // Dual-Channel AXI4 to Wishbone Bridge
            axi4_to_wishbone #(
                .LSU_ID_WIDTH (8),
                .IFU_ID_WIDTH (3)
            ) u_axi4_to_wb (
                .clk             (clk),
                .rst_n           (rst_n),

                // LSU AXI
                .lsu_axi_awid    (lsu_axi_awid),
                .lsu_axi_awaddr  (lsu_axi_awaddr),
                .lsu_axi_awlen   (lsu_axi_awlen),
                .lsu_axi_awsize  (lsu_axi_awsize),
                .lsu_axi_awburst (lsu_axi_awburst),
                .lsu_axi_awvalid (lsu_axi_awvalid),
                .lsu_axi_awready (lsu_axi_awready),

                .lsu_axi_wdata   (lsu_axi_wdata),
                .lsu_axi_wstrb   (lsu_axi_wstrb),
                .lsu_axi_wlast   (lsu_axi_wlast),
                .lsu_axi_wvalid  (lsu_axi_wvalid),
                .lsu_axi_wready  (lsu_axi_wready),

                .lsu_axi_bid     (lsu_axi_bid),
                .lsu_axi_bresp   (lsu_axi_bresp),
                .lsu_axi_bvalid  (lsu_axi_bvalid),
                .lsu_axi_bready  (lsu_axi_bready),

                .lsu_axi_arid    (lsu_axi_arid),
                .lsu_axi_araddr  (lsu_axi_araddr),
                .lsu_axi_arlen   (lsu_axi_arlen),
                .lsu_axi_arsize  (lsu_axi_arsize),
                .lsu_axi_arburst (lsu_axi_arburst),
                .lsu_axi_arvalid (lsu_axi_arvalid),
                .lsu_axi_arready (lsu_axi_arready),

                .lsu_axi_rid     (lsu_axi_rid),
                .lsu_axi_rdata   (lsu_axi_rdata),
                .lsu_axi_rresp   (lsu_axi_rresp),
                .lsu_axi_rlast   (lsu_axi_rlast),
                .lsu_axi_rvalid  (lsu_axi_rvalid),
                .lsu_axi_rready  (lsu_axi_rready),

                // IFU AXI
                .ifu_axi_arid    (ifu_axi_arid),
                .ifu_axi_araddr  (ifu_axi_araddr),
                .ifu_axi_arlen   (ifu_axi_arlen),
                .ifu_axi_arsize  (ifu_axi_arsize),
                .ifu_axi_arburst (ifu_axi_arburst),
                .ifu_axi_arvalid (ifu_axi_arvalid),
                .ifu_axi_arready (ifu_axi_arready),

                .ifu_axi_rid     (ifu_axi_rid),
                .ifu_axi_rdata   (ifu_axi_rdata),
                .ifu_axi_rresp   (ifu_axi_rresp),
                .ifu_axi_rlast   (ifu_axi_rlast),
                .ifu_axi_rvalid  (ifu_axi_rvalid),
                .ifu_axi_rready  (ifu_axi_rready),

                // Wishbone Master Interface
                .m_wb_adr_o      (bridge_wb_adr),
                .m_wb_dat_o      (bridge_wb_dat_w),
                .m_wb_dat_i      (bridge_wb_dat_r),
                .m_wb_sel_o      (bridge_wb_sel),
                .m_wb_we_o       (bridge_wb_we),
                .m_wb_stb_o      (bridge_wb_stb),
                .m_wb_cyc_o      (bridge_wb_cyc),
                .m_wb_ack_i      (bridge_wb_ack),
                .m_wb_err_i      (bridge_wb_err)
            );
        end else begin : gen_no_veer
            assign cpu_trace_pc_o    = 32'd0;
            assign cpu_trace_insn_o  = 32'd0;
            assign cpu_trace_valid_o = 1'b0;
            assign bridge_wb_adr     = 32'd0;
            assign bridge_wb_dat_w   = 32'd0;
            assign bridge_wb_sel     = 4'd0;
            assign bridge_wb_we      = 1'b0;
            assign bridge_wb_stb     = 1'b0;
            assign bridge_wb_cyc     = 1'b0;
        end
    endgenerate

    wire cpu_external_active = (!ENABLE_VEER_CPU) || cpu_override_i;

    // Interconnect Master 0 muxing
    assign core_m0_adr   = cpu_external_active ? cpu_wb_adr_i   : bridge_wb_adr;
    assign core_m0_dat_w = cpu_external_active ? cpu_wb_dat_i   : bridge_wb_dat_w;
    assign core_m0_sel   = cpu_external_active ? cpu_wb_sel_i   : bridge_wb_sel;
    assign core_m0_we    = cpu_external_active ? cpu_wb_we_i    : bridge_wb_we;
    assign core_m0_stb   = cpu_external_active ? cpu_wb_stb_i   : bridge_wb_stb;
    assign core_m0_cyc   = cpu_external_active ? cpu_wb_cyc_i   : bridge_wb_cyc;

    assign bridge_wb_dat_r = core_m0_dat_r;
    assign bridge_wb_ack   = cpu_external_active ? 1'b0 : core_m0_ack;
    assign bridge_wb_err   = cpu_external_active ? 1'b0 : core_m0_err;

    assign cpu_wb_dat_o = core_m0_dat_r;
    assign cpu_wb_ack_o = cpu_external_active ? core_m0_ack : 1'b0;
    assign cpu_wb_err_o = cpu_external_active ? core_m0_err : 1'b0;

    // =========================================================================
    // Interconnect Crossbar
    // =========================================================================
    soc_interconnect u_interconnect (
        .clk        (clk),
        .rst_n      (rst_n),

        // Masters
        .m0_wb_adr_i(core_m0_adr),
        .m0_wb_dat_i(core_m0_dat_w),
        .m0_wb_dat_o(core_m0_dat_r),
        .m0_wb_sel_i(core_m0_sel),
        .m0_wb_we_i (core_m0_we),
        .m0_wb_stb_i(core_m0_stb),
        .m0_wb_cyc_i(core_m0_cyc),
        .m0_wb_ack_o(core_m0_ack),
        .m0_wb_err_o(core_m0_err),

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
    sram_sp_32k #(
        .INIT_FILE(BOOT_HEX)
    ) u_isram (
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
