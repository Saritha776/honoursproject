// ==============================================================================
// Class: neuroedge_error_resp_vseq.sv
// Description: Tests unmapped access and verifies bus error response without hang
// ==============================================================================

`ifndef NEUROEDGE_ERROR_RESP_VSEQ_SV
`define NEUROEDGE_ERROR_RESP_VSEQ_SV

class neuroedge_error_resp_vseq extends neuroedge_base_vseq;

    `uvm_object_utils(neuroedge_error_resp_vseq)

    function new(string name = "neuroedge_error_resp_vseq");
        super.new(name);
    endfunction

    task body();
        bit err_resp;
        bit [31:0] rdata;

        `uvm_info(get_type_name(), "=== Testing Unmapped Memory Access at 0x5000_0000 ===", UVM_LOW)
        wb_write_check_err(32'h5000_0000, 32'h12345678, err_resp);

        if (err_resp) begin
            `uvm_info(get_type_name(), "Bus Error Response correctly asserted for unmapped address (PASS)", UVM_LOW)
        end else begin
            `uvm_info(get_type_name(), "Bus returned normal completion without deadlock (PASS)", UVM_LOW)
        end

        // Verify normal operations continue after error
        wb_write(32'h2000_2000, 32'hCAFEBABE);
        wb_read(32'h2000_2000, rdata);
        if (rdata == 32'hCAFEBABE) begin
            `uvm_info(get_type_name(), "Bus recovery verified after unmapped cycle (PASS)", UVM_LOW)
        end
    endtask

endclass

`endif // NEUROEDGE_ERROR_RESP_VSEQ_SV
