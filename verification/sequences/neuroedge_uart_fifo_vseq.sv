// ==============================================================================
// Class: neuroedge_uart_fifo_vseq.sv
// Description: UART FIFO-Level Verification Sequence testing TX FIFO Depth,
//              Multi-Byte RX FIFO Ingestion, Status Flags, and Wishbone Readback
// ==============================================================================

`ifndef NEUROEDGE_UART_FIFO_VSEQ_SV
`define NEUROEDGE_UART_FIFO_VSEQ_SV

class neuroedge_uart_fifo_vseq extends neuroedge_base_vseq;

    `uvm_object_utils(neuroedge_uart_fifo_vseq)

    virtual uart_if uart_vif;

    function new(string name = "neuroedge_uart_fifo_vseq");
        super.new(name);
    endfunction

    task body();
        bit [31:0] rdata;
        bit [7:0]  expected_rx[4];
        bit [7:0]  actual_rx[4];
        bit        mismatch;

        void'(uvm_config_db#(virtual uart_if)::get(null, "", "uart_vif", uart_vif));

        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        `uvm_info(get_type_name(), "=== [Stage 1] Configuring UART Baud Rate Divisor ===", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        // UART_BASE = 0x4000_3000
        // REG_UART_BAUD_DIV = 0x4000_300C. Divisor = 31 (640ns per bit @ 50MHz)
        wb_write(32'h4000_300C, 32'h0000_001F);

        // Check initial Status: TX and RX FIFOs empty
        wb_read(32'h4000_3008, rdata);
        `uvm_info(get_type_name(), $sformatf("Initial UART Status (0x4000_3008): 0x%02h [Busy=%0d, TX_Full=%0d, RX_Valid=%0d, Overrun=%0d]",
                  rdata[3:0], rdata[0], rdata[1], rdata[2], rdata[3]), UVM_LOW)

        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        `uvm_info(get_type_name(), "=== [Stage 2] Testing TX FIFO Multi-Byte Load ===", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        // Write 4 bytes into TX FIFO via Wishbone
        wb_write(32'h4000_3000, 32'h0000_0055); // 'U'
        wb_write(32'h4000_3000, 32'h0000_0041); // 'A'
        wb_write(32'h4000_3000, 32'h0000_0052); // 'R'
        wb_write(32'h4000_3000, 32'h0000_0054); // 'T'

        wb_read(32'h4000_3008, rdata);
        `uvm_info(get_type_name(), $sformatf("Status during TX streaming: 0x%02h (tx_busy=%0d)", rdata[3:0], rdata[0]), UVM_LOW)

        // Wait for all 4 bytes to transmit over serial line (4 * 10 * 640ns = 25.6 us)
        #30000ns;

        wb_read(32'h4000_3008, rdata);
        `uvm_info(get_type_name(), $sformatf("Status after TX drain: 0x%02h (tx_busy=%0d)", rdata[3:0], rdata[0]), UVM_LOW)
        if (rdata[0] == 1'b0) begin
            `uvm_info(get_type_name(), "★ TX FIFO Multi-Byte Transmission Complete & Line Idle ★", UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), "TX transmitter failed to return to idle after draining FIFO!")
        end

        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        `uvm_info(get_type_name(), "=== [Stage 3] Testing RX FIFO Multi-Byte Ingestion ===", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        expected_rx[0] = 8'h57; // 'W'
        expected_rx[1] = 8'h42; // 'B'
        expected_rx[2] = 8'h46; // 'F'
        expected_rx[3] = 8'h49; // 'I'

        for (int i = 0; i < 4; i++) begin
            `uvm_info(get_type_name(), $sformatf("Injecting Serial Byte [%0d/4]: 0x%02h ('%c')",
                      i+1, expected_rx[i], expected_rx[i]), UVM_LOW)
            uart_send_byte(expected_rx[i]);
            #7500ns; // Wait for stop bit sample
        end

        #2000ns;
        // Verify Status: RX_VALID (bit 2) asserted
        wb_read(32'h4000_3008, rdata);
        `uvm_info(get_type_name(), $sformatf("Status after 4 RX bytes: 0x%02h [RX_Valid=%0d]", rdata[3:0], rdata[2]), UVM_LOW)
        if (rdata[2] == 1'b1) begin
            `uvm_info(get_type_name(), "★ RX_VALID Flag Asserted in Status Register ★", UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), "RX_VALID flag NOT asserted in STATUS register after 4 received bytes!")
        end

        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        `uvm_info(get_type_name(), "=== [Stage 4] Verifying Wishbone RX FIFO Readback ===", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        mismatch = 1'b0;
        for (int i = 0; i < 4; i++) begin
            wb_read(32'h4000_3004, rdata);
            actual_rx[i] = rdata[7:0];
            `uvm_info(get_type_name(), $sformatf("  RX FIFO Read [%0d/4]: Got 0x%02h ('%c') | Expected 0x%02h ('%c')",
                      i+1, actual_rx[i], actual_rx[i], expected_rx[i], expected_rx[i]), UVM_LOW)
            if (actual_rx[i] != expected_rx[i]) begin
                mismatch = 1'b1;
                `uvm_error(get_type_name(), $sformatf("FIFO Ordering Mismatch at index %0d: Got 0x%02h, Expected 0x%02h",
                           i, actual_rx[i], expected_rx[i]))
            end
        end

        if (!mismatch) begin
            `uvm_info(get_type_name(), "★ RX FIFO ALL 4 BYTES READ BACK IN EXACT FIRST-IN FIRST-OUT ORDER! ★", UVM_NONE)
        end

        // Verify Status: RX_VALID (bit 2) deasserted now that FIFO is empty
        wb_read(32'h4000_3008, rdata);
        `uvm_info(get_type_name(), $sformatf("Status after FIFO drained: 0x%02h [RX_Valid=%0d]", rdata[3:0], rdata[2]), UVM_LOW)
        if (rdata[2] == 1'b0) begin
            `uvm_info(get_type_name(), "★ RX_VALID Flag Successfully Deasserted on Empty FIFO ★", UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), "RX_VALID flag STILL asserted after reading all bytes!")
        end

        // Read from empty FIFO: should return 0x00
        wb_read(32'h4000_3004, rdata);
        if (rdata[7:0] == 8'h00) begin
            `uvm_info(get_type_name(), "★ Reading from Empty RX FIFO correctly returns 0x00 ★", UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), $sformatf("Empty RX FIFO read returned non-zero: 0x%02h", rdata[7:0]))
        end

        #2000ns;
    endtask

endclass

`endif // NEUROEDGE_UART_FIFO_VSEQ_SV
