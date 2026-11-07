// ==============================================================================
// Class: neuroedge_wb_memory_vseq.sv
// Description: Memory access tests for ISRAM (0x0000_0000) and DSRAM (0x2000_0000)
// ==============================================================================

`ifndef NEUROEDGE_WB_MEMORY_VSEQ_SV
`define NEUROEDGE_WB_MEMORY_VSEQ_SV

class neuroedge_wb_memory_vseq extends neuroedge_base_vseq;

    `uvm_object_utils(neuroedge_wb_memory_vseq)

    function new(string name = "neuroedge_wb_memory_vseq");
        super.new(name);
    endfunction

    task body();
        bit [31:0] rdata;

        `uvm_info(get_type_name(), "=== [Step 1] Reading & Writing Instruction SRAM ===", UVM_LOW)
        // Address 0x0000_0000 contains first firmware instruction (0x30047073: csrci mstatus, 8)
        wb_read(32'h0000_0000, rdata);
        `uvm_info(get_type_name(), $sformatf("ISRAM @ 0x00000000: 0x%08h", rdata), UVM_LOW)
        // Exercise ISRAM write to top of memory (hits WRITE to ISRAM in wb_coverage)
        wb_write(32'h0000_7FFC, 32'hA5A5_5A5A);
        wb_read(32'h0000_7FFC, rdata);
        if (rdata == 32'hA5A5_5A5A) begin
            `uvm_info(get_type_name(), "ISRAM Write/Read PASS (0xA5A55A5A)", UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), $sformatf("ISRAM Readback Mismatch: Got 0x%08h, Expected 0xA5A55A5A", rdata))
        end

        `uvm_info(get_type_name(), "=== [Step 2] Testing Data SRAM Read/Write (0x2000_1000) ===", UVM_LOW)
        wb_write(32'h2000_1000, 32'hDEADBEEF);
        wb_read(32'h2000_1000, rdata);
        if (rdata == 32'hDEADBEEF) begin
            `uvm_info(get_type_name(), "DSRAM Word Write/Read PASS (0xDEADBEEF)", UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), $sformatf("DSRAM Readback Mismatch: Got 0x%08h, Expected 0xDEADBEEF", rdata))
        end

        `uvm_info(get_type_name(), "=== [Step 3] Testing Byte Strobes in Data SRAM ===", UVM_LOW)
        wb_write(32'h2000_1004, 32'h0000_0055, 4'b0001); // Write byte 0
        wb_write(32'h2000_1004, 32'h0000_AA00, 4'b0010); // Write byte 1
        wb_write(32'h2000_1004, 32'h00CC_0000, 4'b0100); // Write byte 2
        wb_write(32'h2000_1004, 32'h3300_0000, 4'b1000); // Write byte 3
        wb_read(32'h2000_1004, rdata);
        if (rdata == 32'h33CC_AA55) begin
            `uvm_info(get_type_name(), "DSRAM Byte Strobe Write/Read PASS (0x33CCAA55)", UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), $sformatf("DSRAM Byte Strobe Mismatch: Got 0x%08h, Expected 0x33CCAA55", rdata))
        end
        // Read byte strobes to hit all read sel combinations
        wb_read(32'h2000_1004, rdata, 4'b0001); // Read byte 0
        wb_read(32'h2000_1004, rdata, 4'b0010); // Read byte 1
        wb_read(32'h2000_1004, rdata, 4'b0100); // Read byte 2
        wb_read(32'h2000_1004, rdata, 4'b1000); // Read byte 3

        `uvm_info(get_type_name(), "=== [Step 4] Testing Halfword Strobes in Data SRAM ===", UVM_LOW)
        wb_write(32'h2000_1008, 32'h0000_1234, 4'b0011); // Lower Halfword
        wb_write(32'h2000_1008, 32'h5678_0000, 4'b1100); // Upper Halfword
        wb_read(32'h2000_1008, rdata);
        if (rdata == 32'h5678_1234) begin
            `uvm_info(get_type_name(), "DSRAM Halfword Strobe Write/Read PASS (0x56781234)", UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), $sformatf("DSRAM Halfword Strobe Mismatch: Got 0x%08h, Expected 0x56781234", rdata))
        end
        // Read halfword strobes
        wb_read(32'h2000_1008, rdata, 4'b0011); // Read lower halfword
        wb_read(32'h2000_1008, rdata, 4'b1100); // Read upper halfword
    endtask

endclass

`endif // NEUROEDGE_WB_MEMORY_VSEQ_SV
