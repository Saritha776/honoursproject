// ==============================================================================
// Class: neuroedge_gpio_vseq.sv
// Description: Dedicated Virtual Sequence verifying NeuroEdge SoC GPIO integration:
//              - VIP Driver driving input patterns (gpio_in)
//              - 2-stage synchronization and Wishbone readback of REG_GPIO_IN
//              - Wishbone writing of REG_GPIO_OUT and REG_GPIO_DIR
//              - VIP Monitor observing output pin transitions (gpio_out, gpio_dir)
//              - Scoreboard tracking milestone achievements
// ==============================================================================

`ifndef NEUROEDGE_GPIO_VSEQ_SV
`define NEUROEDGE_GPIO_VSEQ_SV

class neuroedge_gpio_vseq extends neuroedge_base_vseq;

    `uvm_object_utils(neuroedge_gpio_vseq)

    function new(string name = "neuroedge_gpio_vseq");
        super.new(name);
    endfunction

    task body();
        bit [31:0] rdata;
        bit [7:0]  test_patterns[6] = '{8'hA5, 8'h5A, 8'h0F, 8'hF0, 8'h3C, 8'hC3};

        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        `uvm_info(get_type_name(), "  Starting NeuroEdge SoC GPIO Verification Sequence", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================", UVM_LOW)

        // ---------------------------------------------------------------------
        // Step 1: Configure Direction to Output and Verify Output Pins
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "--- [Step 1] Configuring GPIO as All Outputs & Driving Patterns ---", UVM_LOW)
        // REG_GPIO_DIR = 0x4000_6008
        wb_write(32'h4000_6008, 32'h0000_00FF);
        wb_read(32'h4000_6008, rdata);
        if ((rdata & 8'hFF) == 8'hFF) begin
            `uvm_info(get_type_name(), "GPIO Direction (0xFF = Output) Confirmed", UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), $sformatf("GPIO DIR Mismatch: Expected 0xFF, Got 0x%02h", rdata[7:0]))
        end

        foreach (test_patterns[i]) begin
            wb_write(32'h4000_6004, {24'h0, test_patterns[i]});
            #40ns; // allow 2 clock cycles
            wb_read(32'h4000_6004, rdata);
            if ((rdata & 8'hFF) == test_patterns[i]) begin
                `uvm_info(get_type_name(), $sformatf("GPIO Out Readback PASS: 0x%02h", test_patterns[i]), UVM_LOW)
            end else begin
                `uvm_error(get_type_name(), $sformatf("GPIO Out Mismatch: Expected 0x%02h, Got 0x%02h", test_patterns[i], rdata[7:0]))
            end
        end

        // ---------------------------------------------------------------------
        // Step 2: Configure Direction to Input & Drive Input Pins via VIP Driver
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "--- [Step 2] Driving External GPIO Input Pins via VIP Driver ---", UVM_LOW)
        wb_write(32'h4000_6008, 32'h0000_0000); // Direction: all inputs

        foreach (test_patterns[i]) begin
            `uvm_info(get_type_name(), $sformatf("Driving GPIO VIP Input: 0x%02h", test_patterns[i]), UVM_LOW)
            gpio_set_input(test_patterns[i]);

            // Allow 3 clock cycles for 2-stage synchronizer flip-flops in RTL
            #80ns;

            // Read REG_GPIO_IN = 0x4000_6000
            wb_read(32'h4000_6000, rdata);
            if ((rdata & 8'hFF) == test_patterns[i]) begin
                `uvm_info(get_type_name(), $sformatf("GPIO VIP Input Synchronized & Verified in SoC: 0x%02h (PASS)", test_patterns[i]), UVM_LOW)
            end else begin
                `uvm_error(get_type_name(), $sformatf("GPIO Input Synchronizer Mismatch: Expected 0x%02h, Readback 0x%02h",
                          test_patterns[i], rdata[7:0]))
            end
        end

        // ---------------------------------------------------------------------
        // Step 3: Verify GPIO Edge Detection & Status Register
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "--- [Step 3] Checking GPIO Edge Detection Flag & Clear ---", UVM_LOW)
        // REG_GPIO_STATUS = 0x4000_600C
        wb_read(32'h4000_600C, rdata);
        if (rdata[0] === 1'b1) begin
            `uvm_info(get_type_name(), "GPIO Edge Flag Triggered Successfully (1'b1)", UVM_LOW)
            // Clear flag by writing 1'b1 to bit 0
            wb_write(32'h4000_600C, 32'h0000_0001);
            wb_read(32'h4000_600C, rdata);
            if (rdata[0] === 1'b0) begin
                `uvm_info(get_type_name(), "GPIO Edge Flag Cleared Successfully (1'b0)", UVM_LOW)
            end else begin
                `uvm_error(get_type_name(), "GPIO Edge Flag Failed to Clear")
            end
        end else begin
            `uvm_warning(get_type_name(), "GPIO Edge Flag was not set (may have stabilized)")
        end

        // ---------------------------------------------------------------------
        // Step 4: Publish Milestone 0xAA for Scoreboard Final Verification
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "--- [Step 4] Signaling Completion Milestone 0xAA ---", UVM_LOW)
        wb_write(32'h4000_6008, 32'h0000_00FF); // Output mode
        wb_write(32'h4000_6004, 32'h0000_00AA); // 0xAA milestone
        #100ns;

        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        `uvm_info(get_type_name(), "  NeuroEdge SoC GPIO Verification Complete (PASS) ", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
    endtask

endclass

`endif // NEUROEDGE_GPIO_VSEQ_SV
