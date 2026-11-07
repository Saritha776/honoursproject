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
        wb_write(32'h4000_6008, 32'h0000_00FF); // All outputs
        wb_write(32'h4000_6004, 32'h0000_005A); // Drive 0x5A
        wb_read(32'h4000_6004, rdata);
        if ((rdata & 8'hFF) == 8'h5A) begin
            `uvm_info(get_type_name(), "GPIO Output Readback PASS (0x5A)", UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), $sformatf("GPIO Output Mismatch: Got 0x%02h, Expected 0x5A", rdata[7:0]))
        end

        `uvm_info(get_type_name(), "=== [Step 4] Testing PIC Status ===", UVM_LOW)
        wb_read(32'h4000_7000, rdata);
        `uvm_info(get_type_name(), $sformatf("PIC Pending IRQs: 0x%08h", rdata), UVM_LOW)
    endtask

endclass

`endif // NEUROEDGE_PERIPHERAL_VSEQ_SV
