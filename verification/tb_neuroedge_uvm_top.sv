// ==============================================================================
// Module: tb_neuroedge_uvm_top.sv
// Description: UVM Top-Level Testbench instantiating ONLY the single GPIO VIP
//              connected directly to the NeuroEdge SoC top-level DUT.
// ==============================================================================

`timescale 1ns / 1ps

module tb_neuroedge_uvm_top;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import gpio_pkg::*;
    import neuroedge_uvm_pkg::*;
    import neuroedge_seq_pkg::*;
    import neuroedge_test_pkg::*;

    // Clock and Reset Signals
    logic clk;
    logic rst_n;

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
    // Single VIP Interface Instantiation (GPIO VIP Only)
    // Reference Structure: gpio_if u_if (.clk(clk), .rst_n(rst_n));
    // =========================================================================
    gpio_if u_gpio_if (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // =========================================================================
    // NeuroEdge SoC Top-Level DUT Instantiation
    // Reference Structure: gpio_dut u_dut (.clk(clk), .rst_n(rst_n), ...)
    // =========================================================================
    neuroedge_soc_top #(
        .BOOT_HEX        ("/home/student/Documents/honoursproject/honoursproject/firmware/neuroedge_test.hex"),
        .ENABLE_VEER_CPU (1)
    ) dut (
        .clk              (clk),
        .rst_n            (rst_n),

        // CPU Bus Master Port (Wishbone Interface) - autonomous CPU mode
        .cpu_override_i   (1'b0),
        .cpu_wb_adr_i     (32'h0),
        .cpu_wb_dat_i     (32'h0),
        .cpu_wb_dat_o     (),
        .cpu_wb_sel_i     (4'h0),
        .cpu_wb_we_i      (1'b0),
        .cpu_wb_stb_i     (1'b0),
        .cpu_wb_cyc_i     (1'b0),
        .cpu_wb_ack_o     (),
        .cpu_wb_err_o     (),

        // Vectored Interrupt Output
        .cpu_irq_vec_o    (),

        // External SPI Flash Pins
        .spi_sclk         (),
        .spi_mosi         (),
        .spi_miso         (1'b1),
        .spi_cs_n         (),

        // External UART Pins
        .uart_tx          (),
        .uart_rx          (1'b1),

        // External GPIO Pins (Connected directly to single GPIO VIP)
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
    // UVM Config DB Setup & Simulation Entry
    // =========================================================================
    initial begin
        // Pass single GPIO virtual interface into UVM Config DB strictly ONE time
        uvm_config_db#(virtual gpio_if)::set(null, "*", "vif", u_gpio_if);

        // FSDB Waveform Dumping: captures single GPIO VIP and DUT GPIO clearly
        $fsdbDumpfile("neuroedge_uvm_sim.fsdb");
        $fsdbDumpvars(0, tb_neuroedge_uvm_top, "+all");
        $fsdbDumpSVA;

        // Run Selected UVM Test
        run_test();
    end

endmodule
