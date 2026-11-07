// ==============================================================================
// Module: tb_neuroedge_uvm_top.sv
// Description: UVM Top-Level Testbench integrating NeuroEdge SoC and all VIPs
// ==============================================================================

`timescale 1ns / 1ps

module tb_neuroedge_uvm_top;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import axi4_pkg::*;
    import wb_pkg::*;
    import uart_pkg::*;
    import systolic_pkg::*;
    import spi_flash_pkg::*;
    import gpio_pkg::*;
    import neuroedge_uvm_pkg::*;
    import neuroedge_seq_pkg::*;
    import neuroedge_test_pkg::*;

    // Clock and Reset Signals
    logic clk;
    logic rst_n;
    logic cpu_override;

    localparam real CLK_PERIOD = 20.0; // 50 MHz system clock

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2.0) clk = ~clk;
    end

    // Reset Generation
    initial begin
        rst_n = 1'b0;
        #100ns;
        @(posedge clk);
        rst_n = 1'b1;
        `uvm_info("TOP", "System Reset Deasserted", UVM_LOW)
    end

    // =========================================================================
    // VIP Interfaces Instantiation
    // =========================================================================
    axi4_if      u_lsu_axi_if (.clk(clk), .rst_n(rst_n));
    axi4_if      u_ifu_axi_if (.clk(clk), .rst_n(rst_n));
    wb_if        u_wb_if      (.clk(clk), .rst_n(rst_n));
    uart_if      u_uart_if    (.clk(clk), .rst_n(rst_n));
    systolic_if  u_systolic_if(.clk(clk), .rst_n(rst_n));
    spi_flash_if u_spi_if     (.clk(clk), .rst_n(rst_n));
    gpio_if      u_gpio_if    (.clk(clk), .rst_n(rst_n));

    // =========================================================================
    // NeuroEdge SoC DUT Instantiation
    // =========================================================================
    neuroedge_soc_top #(
        .BOOT_HEX        ("/home/student/Documents/honoursproject/honoursproject/firmware/neuroedge_test.hex"),
        .ENABLE_VEER_CPU (1)
    ) dut (
        .clk              (clk),
        .rst_n            (rst_n),

        // CPU Bus Master Port (Wishbone Interface from VIP Master)
        .cpu_override_i   (cpu_override),
        .cpu_wb_adr_i     (u_wb_if.adr),
        .cpu_wb_dat_i     (u_wb_if.dat_w),
        .cpu_wb_dat_o     (u_wb_if.dat_r),
        .cpu_wb_sel_i     (u_wb_if.sel),
        .cpu_wb_we_i      (u_wb_if.we),
        .cpu_wb_stb_i     (u_wb_if.stb),
        .cpu_wb_cyc_i     (u_wb_if.cyc),
        .cpu_wb_ack_o     (u_wb_if.ack),
        .cpu_wb_err_o     (u_wb_if.err),

        // Vectored Interrupt Output
        .cpu_irq_vec_o    (),

        // External SPI Flash Pins (Connected to SPI Flash VIP Responder)
        .spi_sclk         (u_spi_if.sclk),
        .spi_mosi         (u_spi_if.mosi),
        .spi_miso         (u_spi_if.miso),
        .spi_cs_n         (u_spi_if.cs_n),

        // External UART Pins (Connected to UART VIP)
        .uart_tx          (u_uart_if.tx),
        .uart_rx          (u_uart_if.rx),

        // External GPIO Pins (Connected to GPIO VIP)
        .gpio_in          (u_gpio_if.gpio_in),
        .gpio_out         (u_gpio_if.gpio_out),
        .gpio_dir         (u_gpio_if.gpio_dir),

        // Watchdog & Telemetry
        .wdt_reset_out    (),
        .cpu_trace_pc_o   (),
        .cpu_trace_insn_o (),
        .cpu_trace_valid_o()
    );

    // =========================================================================
    // Hierarchical Probes connecting Internal Interfaces to VIPs
    // Procedural assignments avoid structural/procedural driver conflict warnings
    // =========================================================================
    always @(*) begin
        // LSU AXI4 Monitoring Probe
        u_lsu_axi_if.awvalid = dut.lsu_axi_awvalid;
        u_lsu_axi_if.awready = dut.lsu_axi_awready;
        u_lsu_axi_if.awaddr  = dut.lsu_axi_awaddr;
        u_lsu_axi_if.awid    = dut.lsu_axi_awid;
        u_lsu_axi_if.awlen   = dut.lsu_axi_awlen;
        u_lsu_axi_if.awsize  = dut.lsu_axi_awsize;
        u_lsu_axi_if.awburst = dut.lsu_axi_awburst;

        u_lsu_axi_if.wvalid  = dut.lsu_axi_wvalid;
        u_lsu_axi_if.wready  = dut.lsu_axi_wready;
        u_lsu_axi_if.wdata   = dut.lsu_axi_wdata;
        u_lsu_axi_if.wstrb   = dut.lsu_axi_wstrb;
        u_lsu_axi_if.wlast   = dut.lsu_axi_wlast;

        u_lsu_axi_if.bvalid  = dut.lsu_axi_bvalid;
        u_lsu_axi_if.bready  = dut.lsu_axi_bready;
        u_lsu_axi_if.bid     = dut.lsu_axi_bid;
        u_lsu_axi_if.bresp   = dut.lsu_axi_bresp;

        u_lsu_axi_if.arvalid = dut.lsu_axi_arvalid;
        u_lsu_axi_if.arready = dut.lsu_axi_arready;
        u_lsu_axi_if.araddr  = dut.lsu_axi_araddr;
        u_lsu_axi_if.arid    = dut.lsu_axi_arid;
        u_lsu_axi_if.arlen   = dut.lsu_axi_arlen;
        u_lsu_axi_if.arsize  = dut.lsu_axi_arsize;
        u_lsu_axi_if.arburst = dut.lsu_axi_arburst;

        u_lsu_axi_if.rvalid  = dut.lsu_axi_rvalid;
        u_lsu_axi_if.rready  = dut.lsu_axi_rready;
        u_lsu_axi_if.rid     = dut.lsu_axi_rid;
        u_lsu_axi_if.rdata   = dut.lsu_axi_rdata;
        u_lsu_axi_if.rresp   = dut.lsu_axi_rresp;
        u_lsu_axi_if.rlast   = dut.lsu_axi_rlast;

        // IFU AXI4 Monitoring Probe
        u_ifu_axi_if.arvalid = dut.ifu_axi_arvalid;
        u_ifu_axi_if.arready = dut.ifu_axi_arready;
        u_ifu_axi_if.araddr  = dut.ifu_axi_araddr;
        u_ifu_axi_if.arid    = dut.ifu_axi_arid;
        u_ifu_axi_if.arlen   = dut.ifu_axi_arlen;
        u_ifu_axi_if.arsize  = dut.ifu_axi_arsize;
        u_ifu_axi_if.arburst = dut.ifu_axi_arburst;

        u_ifu_axi_if.rvalid  = dut.ifu_axi_rvalid;
        u_ifu_axi_if.rready  = dut.ifu_axi_rready;
        u_ifu_axi_if.rid     = dut.ifu_axi_rid;
        u_ifu_axi_if.rdata   = dut.ifu_axi_rdata;
        u_ifu_axi_if.rresp   = dut.ifu_axi_rresp;
        u_ifu_axi_if.rlast   = dut.ifu_axi_rlast;

        // Systolic Array Internal Interface & Output Probes
        u_systolic_if.wb_adr        = dut.s4_adr;
        u_systolic_if.wb_dat_w      = dut.s4_wdat;
        u_systolic_if.wb_dat_r      = dut.s4_rdat;
        u_systolic_if.wb_we         = dut.s4_we;
        u_systolic_if.wb_stb        = dut.s4_stb;
        u_systolic_if.wb_cyc        = dut.s4_cyc;
        u_systolic_if.wb_ack        = dut.s4_ack;
        u_systolic_if.dma_act_valid = dut.dma_act_valid;
        u_systolic_if.dma_act_data  = dut.dma_act_data;
        u_systolic_if.dma_wgt_valid = dut.dma_wgt_valid;
        u_systolic_if.dma_wgt_data  = dut.dma_wgt_data;
        u_systolic_if.array_irq     = dut.irq_array;

        u_systolic_if.res_out[0]    = dut.u_systolic_array.res_reg[0];
        u_systolic_if.res_out[1]    = dut.u_systolic_array.res_reg[1];
        u_systolic_if.res_out[2]    = dut.u_systolic_array.res_reg[2];
        u_systolic_if.res_out[3]    = dut.u_systolic_array.res_reg[3];

        // UART Internal Probe
        u_uart_if.rx_shift_reg_probe = dut.u_uart.rx_shift_reg;
    end

    // =========================================================================
    // UVM Config DB Setup & Simulation Entry
    // =========================================================================
    initial begin
        // Pass virtual interfaces into UVM Config DB
        uvm_config_db#(virtual axi4_if)::set(null, "*.lsu_axi_agent*", "vif", u_lsu_axi_if);
        uvm_config_db#(virtual axi4_if)::set(null, "*.ifu_axi_agent*", "vif", u_ifu_axi_if);
        uvm_config_db#(virtual wb_if)::set(null, "*.wb_agent_inst*", "vif", u_wb_if);
        uvm_config_db#(virtual uart_if)::set(null, "*.uart_agent_inst*", "vif", u_uart_if);
        uvm_config_db#(virtual uart_if)::set(null, "*", "uart_vif", u_uart_if);
        uvm_config_db#(virtual systolic_if)::set(null, "*.systolic_agent_inst*", "vif", u_systolic_if);
        uvm_config_db#(virtual spi_flash_if)::set(null, "*.spi_flash_agent_inst*", "vif", u_spi_if);
        uvm_config_db#(virtual gpio_if)::set(null, "*.gpio_agent_inst*", "vif", u_gpio_if);

        // Allow tests to select CPU override mode via plusarg: +CPU_OVERRIDE=1
        if ($test$plusargs("CPU_OVERRIDE")) begin
            cpu_override = 1'b1;
            `uvm_info("TOP", "CPU Override Mode ENABLED (+CPU_OVERRIDE=1): UVM Wishbone Master active", UVM_LOW)
        end else begin
            cpu_override = 1'b0;
            `uvm_info("TOP", "CPU Autonomous Mode ENABLED: VeeR EL2 Core active", UVM_LOW)
        end

        // FSDB Waveform Dumping
        $fsdbDumpfile("neuroedge_uvm_sim.fsdb");
        $fsdbDumpvars(0, tb_neuroedge_uvm_top, "+all");
        $fsdbDumpSVA;

        // Run Selected UVM Test
        run_test();
    end

endmodule
