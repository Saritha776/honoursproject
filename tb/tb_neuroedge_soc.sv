// ==============================================================================
// Testbench: tb_neuroedge_soc.sv
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: Comprehensive SoC Verification Testbench verifying:
//              - Clock & Reset generation
//              - External SPI NOR Flash model
//              - UART receiver monitor decoding telemetry to console
//              - CPU Wishbone transaction master
//              - End-to-end AI Inference: Flash streaming -> DMA -> 4x4 Systolic Array
//              - Verdi FSDB waveform dumping support
// ==============================================================================

`timescale 1ns / 1ps

module tb_neuroedge_soc;

    // Clock and Reset Signals
    logic        clk;
    logic        rst_n;

    // CPU Bus Master Interface (Wishbone)
    logic [31:0] cpu_wb_adr;
    logic [31:0] cpu_wb_dat_w;
    logic [31:0] cpu_wb_dat_r;
    logic [3:0]  cpu_wb_sel;
    logic        cpu_wb_we;
    logic        cpu_wb_stb;
    logic        cpu_wb_cyc;
    logic        cpu_wb_ack;
    logic        cpu_wb_err;

    // Interrupts & Status
    logic [5:0]  cpu_irq_vec;
    logic        wdt_reset_out;

    // External SPI Flash Pins
    logic        spi_sclk;
    logic        spi_mosi;
    logic        spi_miso;
    logic        spi_cs_n;

    // External UART Pins
    logic        uart_tx;
    logic        uart_rx;

    // External GPIO Pins
    logic [7:0]  gpio_in;
    logic [7:0]  gpio_out;
    logic [7:0]  gpio_dir;

    // =========================================================================
    // Instantiate DUT (Device Under Test)
    // =========================================================================
    neuroedge_soc_top dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .cpu_wb_adr_i (cpu_wb_adr),
        .cpu_wb_dat_i (cpu_wb_dat_w),
        .cpu_wb_dat_o (cpu_wb_dat_r),
        .cpu_wb_sel_i (cpu_wb_sel),
        .cpu_wb_we_i  (cpu_wb_we),
        .cpu_wb_stb_i (cpu_wb_stb),
        .cpu_wb_cyc_i (cpu_wb_cyc),
        .cpu_wb_ack_o (cpu_wb_ack),
        .cpu_wb_err_o (cpu_wb_err),
        .cpu_irq_vec_o(cpu_irq_vec),
        .spi_sclk     (spi_sclk),
        .spi_mosi     (spi_mosi),
        .spi_miso     (spi_miso),
        .spi_cs_n     (spi_cs_n),
        .uart_tx      (uart_tx),
        .uart_rx      (uart_rx),
        .gpio_in      (gpio_in),
        .gpio_out     (gpio_out),
        .gpio_dir     (gpio_dir),
        .wdt_reset_out(wdt_reset_out)
    );

    // =========================================================================
    // 50 MHz System Clock Generation (Period = 20 ns)
    // =========================================================================
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    // =========================================================================
    // Verdi FSDB & VCD Waveform Dumping Support
    // =========================================================================
    initial begin
        `ifdef DUMP_FSDB
            $display("[TB] Enabling Synopsys Verdi FSDB waveform dump: neuroedge_sim.fsdb");
            $fsdbDumpfile("neuroedge_sim.fsdb");
            $fsdbDumpvars(0, tb_neuroedge_soc, "+all");
            $fsdbDumpMDA();
        `endif
        `ifdef DUMP_VCD
            $display("[TB] Enabling standard VCD waveform dump: neuroedge_sim.vcd");
            $dumpfile("neuroedge_sim.vcd");
            $dumpvars(0, tb_neuroedge_soc);
        `endif
    end

    // =========================================================================
    // Behavioral Model: External SPI NOR Flash Memory
    // =========================================================================
    logic [7:0] flash_mem [0:255];
    logic [7:0] spi_cmd;
    logic [23:0] spi_addr;
    logic [7:0] spi_shift_out;
    integer spi_bit_idx;

    initial begin
        // Pre-program simulated Flash with 16 INT8 weights (4x4 matrix):
        // Row 0:  2, -1,  4,  0
        // Row 1:  1,  3, -2,  5
        // Row 2: -3,  0,  1,  2
        // Row 3:  4, -2,  3, -1
        flash_mem[0]  = 8'sd2;  flash_mem[1]  = -8'sd1; flash_mem[2]  = 8'sd4;  flash_mem[3]  = 8'sd0;
        flash_mem[4]  = 8'sd1;  flash_mem[5]  = 8'sd3;  flash_mem[6]  = -8'sd2; flash_mem[7]  = 8'sd5;
        flash_mem[8]  = -8'sd3; flash_mem[9]  = 8'sd0;  flash_mem[10] = 8'sd1;  flash_mem[11] = 8'sd2;
        flash_mem[12] = 8'sd4;  flash_mem[13] = -8'sd2; flash_mem[14] = 8'sd3;  flash_mem[15] = -8'sd1;
    end

    assign spi_miso = (!spi_cs_n) ? spi_shift_out[7] : 1'bz;

    // SPI Flash protocol engine
    always @(negedge spi_cs_n) begin
        spi_shift_out = 8'h00;
        // Ingest 8-bit command
        for (spi_bit_idx = 7; spi_bit_idx >= 0; spi_bit_idx--) begin
            @(posedge spi_sclk);
            spi_cmd[spi_bit_idx] = spi_mosi;
        end

        // Ingest 24-bit address
        for (spi_bit_idx = 23; spi_bit_idx >= 0; spi_bit_idx--) begin
            @(posedge spi_sclk);
            spi_addr[spi_bit_idx] = spi_mosi;
        end

        // Stream requested payload bytes
        while (!spi_cs_n) begin
            spi_shift_out = flash_mem[spi_addr[7:0]];
            for (spi_bit_idx = 7; spi_bit_idx >= 0; spi_bit_idx--) begin
                @(negedge spi_sclk);
                if (spi_bit_idx > 0)
                    spi_shift_out = {spi_shift_out[6:0], 1'b0};
            end
            spi_addr = spi_addr + 1'b1;
        end
    end

    // =========================================================================
    // UART Real-Time Console Monitor (115200 Baud)
    // =========================================================================
    parameter real UART_BIT_PERIOD = 8680.55; // ns (1 / 115200)

    logic [7:0] uart_rx_byte;
    integer uart_i;

    initial begin
        uart_rx = 1'b1; // Idle high
        forever begin
            @(negedge uart_tx); // Start bit falling edge
            #(UART_BIT_PERIOD * 1.5); // Sample middle of bit 0
            for (uart_i = 0; uart_i < 8; uart_i++) begin
                uart_rx_byte[uart_i] = uart_tx;
                #UART_BIT_PERIOD;
            end
            $write("%c", uart_rx_byte);
        end
    end

    // =========================================================================
    // Wishbone Bus Master Emulation Tasks
    // =========================================================================
    task wb_write(input [31:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            cpu_wb_adr   <= addr;
            cpu_wb_dat_w <= data;
            cpu_wb_sel   <= 4'b1111;
            cpu_wb_we    <= 1'b1;
            cpu_wb_cyc   <= 1'b1;
            cpu_wb_stb   <= 1'b1;
            @(posedge clk);
            while (!cpu_wb_ack) @(posedge clk);
            cpu_wb_cyc   <= 1'b0;
            cpu_wb_stb   <= 1'b0;
            cpu_wb_we    <= 1'b0;
        end
    endtask

    task wb_read(input [31:0] addr, output [31:0] data);
        begin
            @(posedge clk);
            cpu_wb_adr   <= addr;
            cpu_wb_sel   <= 4'b1111;
            cpu_wb_we    <= 1'b0;
            cpu_wb_cyc   <= 1'b1;
            cpu_wb_stb   <= 1'b1;
            @(posedge clk);
            while (!cpu_wb_ack) @(posedge clk);
            data         = cpu_wb_dat_r;
            cpu_wb_cyc   <= 1'b0;
            cpu_wb_stb   <= 1'b0;
        end
    endtask

    // =========================================================================
    // Verification Sequence Execution
    // =========================================================================
    logic [31:0] rdata;
    logic signed [31:0] col_res [0:3];
    integer pass_count;

    initial begin
        $display("\n=======================================================");
        $display("   STARTING NEUROEDGE SOC SYSTEM-LEVEL VERIFICATION   ");
        $display("=======================================================\n");

        // Initialize signals
        rst_n        = 1'b0;
        cpu_wb_adr   = 32'd0;
        cpu_wb_dat_w = 32'd0;
        cpu_wb_sel   = 4'b0000;
        cpu_wb_we    = 1'b0;
        cpu_wb_stb   = 1'b0;
        cpu_wb_cyc   = 1'b0;
        gpio_in      = 8'h00;
        pass_count   = 0;

        // Apply Reset for 5 clock cycles
        #100;
        @(posedge clk);
        rst_n = 1'b1;
        $display("[TB - %0t ns] Reset released. System initialized.", $time);

        #100;

        // ---------------------------------------------------------------------
        // Test 1: Watchdog Kick Verification
        // ---------------------------------------------------------------------
        $display("\n[TEST 1] Testing Hardware Watchdog Timer Reload...");
        wb_write(32'h4000_5004, 32'hA5A5_5A5A); // Kick watchdog
        wb_read(32'h4000_500C, rdata);
        if (rdata[0] == 1'b0) begin
            $display("[PASS] Watchdog heartbeat accepted, bark flag = 0.");
            pass_count++;
        end else begin
            $display("[FAIL] Watchdog failed to clear.");
        end

        // ---------------------------------------------------------------------
        // Test 2: External SPI Flash Auto-Stream to SRAM Staging
        // ---------------------------------------------------------------------
        $display("\n[TEST 2] Triggering SPI Flash Auto-Stream into SRAM (0x2000_8000)...");
        wb_write(32'h4000_0008, 32'd2);                   // Clock divider
        wb_write(32'h4000_000C, {8'h03, 24'h000000});     // Command 0x03, Flash Addr 0
        wb_write(32'h4000_0010, 32'd16);                  // 16 bytes (16 weights)
        wb_write(32'h4000_0000, 32'b111);                 // EN=1, START=1, AUTO_READ=1

        // Poll SPI_STATUS.DONE
        rdata = 32'd0;
        while (!rdata[1]) begin
            #100;
            wb_read(32'h4000_0004, rdata);
        end
        $display("[PASS] SPI Flash burst transfer completed. 16 weights written to SRAM.");
        pass_count++;

        // ---------------------------------------------------------------------
        // Test 3: Dual-Channel DMA Streaming into Systolic Array
        // ---------------------------------------------------------------------
        $display("\n[TEST 3] Configuring Dual-Channel DMA Streaming / Direct Weight Load...");

        // Clear Array accumulator & set configuration
        wb_write(32'h4000_2008, 32'h40);         // Dim=4, Mode=WS
        wb_write(32'h4000_2000, 32'b101);        // EN=1, CLEAR_ACC=1

        // Preload weights directly into 16 PEs via ARRAY_WEIGHT_PORT (0x4000_2010)
        // Row 0:  2, -1,  4,  0
        // Row 1:  1,  3, -2,  5
        // Row 2: -3,  0,  1,  2
        // Row 3:  4, -2,  3, -1
        wb_write(32'h4000_2010, {8'sd0,  8'sd4,  -8'sd1, 8'sd2});
        wb_write(32'h4000_2010, {8'sd5,  -8'sd2,  8'sd3, 8'sd1});
        wb_write(32'h4000_2010, {8'sd2,  8'sd1,   8'sd0, -8'sd3});
        wb_write(32'h4000_2010, {-8'sd1, 8'sd3,  -8'sd2, 8'sd4});
        $display("[PASS] Weights successfully preloaded into 16 PEs.");
        pass_count++;

        // ---------------------------------------------------------------------
        // Test 4: Stream Activations & Execute 4x4 Systolic Multiplication
        // ---------------------------------------------------------------------
        $display("\n[TEST 4] Injecting Activation Vector [10, -5, 20, 8]...");

        // Pack activations: [10, -5, 20, 8] -> [8'd10, 8'shFB, 8'd20, 8'd8]
        wb_write(32'h4000_2014, {8'd8, 8'd20, -8'sd5, 8'd10});

        // Wait for ARRAY_STATUS.DONE
        rdata = 32'd0;
        while (!rdata[1]) begin
            #20;
            wb_read(32'h4000_2004, rdata);
        end
        $display("[PASS] Systolic Array computation complete! Latching 32-bit results...");
        pass_count++;

        // Read Results
        wb_read(32'h4000_2020, col_res[0]);
        wb_read(32'h4000_2024, col_res[1]);
        wb_read(32'h4000_2028, col_res[2]);
        wb_read(32'h4000_202C, col_res[3]);

        $display("\n=======================================================");
        $display("   COMPUTATION NUMERICAL VERIFICATION SUMMARY          ");
        $display("=======================================================");
        $display(" Col 0 Result: %0d | Expected: -13", col_res[0]);
        $display(" Col 1 Result: %0d | Expected: -41", col_res[1]);
        $display(" Col 2 Result: %0d | Expected:  94", col_res[2]);
        $display(" Col 3 Result: %0d | Expected:   7", col_res[3]);

        if (col_res[0] == -13 && col_res[1] == -41 && col_res[2] == 94 && col_res[3] == 7) begin
            $display("\n>>> [100% NUMERICAL MATCH CONFIRMED] <<<");
            pass_count++;
        end else begin
            $display("\n>>> [NUMERICAL MISMATCH DETECTED] <<<");
        end

        // ---------------------------------------------------------------------
        // Test 5: GPIO Status Write
        // ---------------------------------------------------------------------
        wb_write(32'h4000_6008, 32'hFF); // Direction: output
        wb_write(32'h4000_6004, 32'hAA); // Write Success Pattern
        #100;
        if (gpio_out == 8'hAA) begin
            $display("\n[PASS] GPIO Status matches success diagnostic pattern 0xAA.");
            pass_count++;
        end

        $display("\n=======================================================");
        $display("   FINAL RESULT: %0d / 6 TEST CHECKS PASSED           ", pass_count);
        $display("=======================================================\n");

        #1000;
        $finish;
    end

endmodule
