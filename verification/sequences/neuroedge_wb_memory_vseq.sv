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

        `uvm_info(get_type_name(), "=== [Step 1] Reading Instruction SRAM Boot Header ===", UVM_LOW)
        // Address 0x0000_0000 contains first firmware instruction (0x30047073: csrci mstatus, 8)
        wb_read(32'h0000_0000, rdata);
        `uvm_info(get_type_name(), $sformatf("ISRAM @ 0x00000000: 0x%08h", rdata), UVM_LOW)

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
        wb_read(32'h2000_1004, rdata);
        if ((rdata & 32'h0000_FFFF) == 32'h0000_AA55) begin
            `uvm_info(get_type_name(), "DSRAM Byte Strobe Write/Read PASS (0xAA55)", UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), $sformatf("DSRAM Byte Strobe Mismatch: Got 0x%08h, Expected 0xAA55", rdata))
        end
    endtask

endclass

`endif // NEUROEDGE_WB_MEMORY_VSEQ_SV
