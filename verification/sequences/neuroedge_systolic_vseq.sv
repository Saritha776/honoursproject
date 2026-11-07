// ==============================================================================
// Class: neuroedge_systolic_vseq.sv
// Description: Systolic Array full verification sequence checking [-13, -41, 94, 7]
// ==============================================================================

`ifndef NEUROEDGE_SYSTOLIC_VSEQ_SV
`define NEUROEDGE_SYSTOLIC_VSEQ_SV

class neuroedge_systolic_vseq extends neuroedge_base_vseq;

    `uvm_object_utils(neuroedge_systolic_vseq)

    function new(string name = "neuroedge_systolic_vseq");
        super.new(name);
    endfunction

    task body();
        bit [31:0] rdata;
        int signed res[4];

        `uvm_info(get_type_name(), "=== [Step 1] Initializing & Clearing Systolic Array ===", UVM_LOW)
        // ARRAY_BASE = 0x4000_2000
        // Enable array: REG_CTRL = 0x01
        wb_write(32'h4000_2000, 32'h0000_0001);
        // Clear accumulators: REG_CTRL = 0x05 (bit 2: clear_acc, bit 0: enable)
        wb_write(32'h4000_2000, 32'h0000_0005);
        wb_write(32'h4000_2000, 32'h0000_0001);

        `uvm_info(get_type_name(), "=== [Step 2] Loading 4x4 INT8 Stationary Weights ===", UVM_LOW)
        // Row 0: [2, -1, 4, 0]   -> 0x0004_FF02
        wb_write(32'h4000_2010, 32'h0004_FF02);
        // Row 1: [1, 3, -2, 5]   -> 0x05FE_0301
        wb_write(32'h4000_2010, 32'h05FE_0301);
        // Row 2: [-3, 0, 1, 2]   -> 0x0201_00FD
        wb_write(32'h4000_2010, 32'h0201_00FD);
        // Row 3: [4, -2, 3, -1]  -> 0xFF03_FE04
        wb_write(32'h4000_2010, 32'hFF03_FE04);

        `uvm_info(get_type_name(), "=== [Step 3] Streaming Activation Vector [10, -5, 20, 8] ===", UVM_LOW)
        // Activations: [10, -5, 20, 8] -> [0x0A, 0xFB, 0x14, 0x08] -> 0x0814_FB0A
        // Writing to REG_ACT_PORT (0x4000_2014) auto-initiates computation
        wb_write(32'h4000_2014, 32'h0814_FB0A);

        `uvm_info(get_type_name(), "=== [Step 4] Waiting for Computation Completion ===", UVM_LOW)
        // Poll status register (0x4000_2004) until bit 1 (done) is asserted
        for (int i = 0; i < 50; i++) begin
            wb_read(32'h4000_2004, rdata);
            if (rdata[1] == 1'b1) break;
        end

        `uvm_info(get_type_name(), "=== [Step 5] Reading & Verifying Column Results ===", UVM_NONE)
        wb_read(32'h4000_2020, rdata); res[0] = int'(rdata);
        wb_read(32'h4000_2024, rdata); res[1] = int'(rdata);
        wb_read(32'h4000_2028, rdata); res[2] = int'(rdata);
        wb_read(32'h4000_202C, rdata); res[3] = int'(rdata);

        `uvm_info(get_type_name(), $sformatf("  Column 0: Result = %4d | Expected =  -13 [%s]",
                                             res[0], (res[0] == -13) ? "PASS" : "FAIL"), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("  Column 1: Result = %4d | Expected =  -41 [%s]",
                                             res[1], (res[1] == -41) ? "PASS" : "FAIL"), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("  Column 2: Result = %4d | Expected =   94 [%s]",
                                             res[2], (res[2] == 94)  ? "PASS" : "FAIL"), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("  Column 3: Result = %4d | Expected =    7 [%s]",
                                             res[3], (res[3] == 7)   ? "PASS" : "FAIL"), UVM_NONE)

        if (res[0] == -13 && res[1] == -41 && res[2] == 94 && res[3] == 7) begin
            `uvm_info(get_type_name(), "★ ALL ACCELERATOR RESULTS MATCHED GOLDEN MODEL: [-13, -41, 94, 7] ★", UVM_NONE)
        end else begin
            `uvm_error(get_type_name(), "Accelerator results mismatch against golden values!")
        end
    endtask

endclass

`endif // NEUROEDGE_SYSTOLIC_VSEQ_SV
