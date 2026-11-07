// ==============================================================================
// Class: neuroedge_peripheral_vseq.sv
// Description: Peripheral transactions sequence (Timer, WDT, GPIO, PIC)
// ==============================================================================

`ifndef NEUROEDGE_PERIPHERAL_VSEQ_SV
`define NEUROEDGE_PERIPHERAL_VSEQ_SV

class neuroedge_peripheral_vseq extends neuroedge_base_vseq;

    `uvm_object_utils(neuroedge_peripheral_vseq)

    function new(string name = "neuroedge_peripheral_vseq");
        super.new(name);
    endfunction

    task body();
        bit [31:0] rdata;

        `uvm_info(get_type_name(), "=== [Step 1] Testing Hardware Watchdog Reload ===", UVM_LOW)
        // Reload Watchdog Timer with magic key 0xA5A5_5A5A
        wb_write(32'h4000_5004, 32'hA5A5_5A5A);
        wb_read(32'h4000_500C, rdata);
        `uvm_info(get_type_name(), $sformatf("WDT Status Readback: 0x%08h", rdata), UVM_LOW)

        `uvm_info(get_type_name(), "=== [Step 2] Testing Precision 32-bit Timer ===", UVM_LOW)
        wb_write(32'h4000_4000, 32'h0000_0001); // Enable timer
        wb_read(32'h4000_4008, rdata);          // Read counter
        `uvm_info(get_type_name(), $sformatf("Timer Counter Value: %0d", rdata), UVM_LOW)

        `uvm_info(get_type_name(), "=== [Step 3] Testing GPIO Direction & Output ===", UVM_LOW)
        wb_write(32'h4000_6008, 32'h0000_00FF); // All outputs (covers ALL_OUTPUT)
        wb_write(32'h4000_6004, 32'h0000_005A); // Drive 0x5A
        wb_read(32'h4000_6004, rdata);
        if ((rdata & 8'hFF) == 8'h5A) begin
            `uvm_info(get_type_name(), "GPIO Output Readback PASS (0x5A)", UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), $sformatf("GPIO Output Mismatch: Got 0x%02h, Expected 0x5A", rdata[7:0]))
        end
        wb_write(32'h4000_6008, 32'h0000_0000); // All inputs (covers ALL_INPUT)

        `uvm_info(get_type_name(), "=== [Step 4] Testing PIC Status & Configuration ===", UVM_LOW)
        wb_write(32'h4000_7000, 32'h0000_003F); // Enable all IRQs (covers WRITE to PIC)
        wb_read(32'h4000_7000, rdata);
        `uvm_info(get_type_name(), $sformatf("PIC Mask Readback: 0x%08h", rdata), UVM_LOW)
        wb_read(32'h4000_7004, rdata);
        `uvm_info(get_type_name(), $sformatf("PIC Pending IRQs: 0x%08h", rdata), UVM_LOW)

        `uvm_info(get_type_name(), "=== [Step 5] Testing DMA Controller Registers ===", UVM_LOW)
        // DMA_BASE = 0x4000_1000
        wb_write(32'h4000_1010, 32'h2000_0000); // CH0 SRC
        wb_write(32'h4000_1014, 32'h4000_2010); // CH0 DST (Array Weight Port)
        wb_write(32'h4000_1018, 32'h0000_0010); // CH0 LEN 16 bytes
        wb_read(32'h4000_1010, rdata);
        `uvm_info(get_type_name(), $sformatf("DMA CH0 SRC Readback: 0x%08h", rdata), UVM_LOW)

        `uvm_info(get_type_name(), "=== [Step 6] Testing SPI Flash Controller & Auto-Stream ===", UVM_LOW)
        // SPI_BASE = 0x4000_0000
        // Transfer 1: 16 bytes at Flash address 0x000000 (Hits READ_DATA, MATRIX_16B, BASE_ZERO)
        wb_write(32'h4000_0008, 32'h0000_0002);              // CLKDIV
        wb_write(32'h4000_000C, {8'h03, 24'h000000});        // Read Command 0x03, Flash Addr 0
        wb_write(32'h4000_0010, 32'h0000_0010);              // 16 bytes
        wb_write(32'h4000_0000, 32'h0000_0007);              // EN=1, START=1, AUTO_READ=1
        rdata = 32'd0;
        while (!rdata[1]) begin
            #100;
            wb_read(32'h4000_0004, rdata);
        end
        wb_write(32'h4000_0004, 32'h0000_0002);              // W1C clear DONE
        `uvm_info(get_type_name(), "SPI Flash 16-byte Auto-Stream PASS", UVM_LOW)

        // Transfer 2: 4 bytes at Flash address 0x000010 (Hits WORD, HIGHER)
        wb_write(32'h4000_000C, {8'h03, 24'h000010});
        wb_write(32'h4000_0010, 32'h0000_0004);              // 4 bytes
        wb_write(32'h4000_0000, 32'h0000_0007);
        rdata = 32'd0;
        while (!rdata[1]) begin
            #100;
            wb_read(32'h4000_0004, rdata);
        end
        wb_write(32'h4000_0004, 32'h0000_0002);              // W1C clear DONE
        `uvm_info(get_type_name(), "SPI Flash 4-byte Auto-Stream PASS", UVM_LOW)

        // Transfer 3: 1 byte at Flash address 0x000020 (Hits SINGLE_BYTE)
        wb_write(32'h4000_000C, {8'h03, 24'h000020});
        wb_write(32'h4000_0010, 32'h0000_0001);              // 1 byte
        wb_write(32'h4000_0000, 32'h0000_0007);
        rdata = 32'd0;
        while (!rdata[1]) begin
            #100;
            wb_read(32'h4000_0004, rdata);
        end
        wb_write(32'h4000_0004, 32'h0000_0002);              // W1C clear DONE
        `uvm_info(get_type_name(), "SPI Flash 1-byte Auto-Stream PASS", UVM_LOW)
    endtask

endclass

`endif // NEUROEDGE_PERIPHERAL_VSEQ_SV
