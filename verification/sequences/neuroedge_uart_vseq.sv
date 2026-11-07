// ==============================================================================
// Class: neuroedge_uart_vseq.sv
// Description: UART verification sequence testing transmission and reception
// ==============================================================================

`ifndef NEUROEDGE_UART_VSEQ_SV
`define NEUROEDGE_UART_VSEQ_SV

class neuroedge_uart_vseq extends neuroedge_base_vseq;

    `uvm_object_utils(neuroedge_uart_vseq)

    virtual uart_if uart_vif;

    function new(string name = "neuroedge_uart_vseq");
        super.new(name);
    endfunction

    task body();
        bit [31:0] rdata;

        void'(uvm_config_db#(virtual uart_if)::get(null, "", "uart_vif", uart_vif));

        `uvm_info(get_type_name(), "=== [Step 1] Configuring UART Baud Rate Divisor ===", UVM_LOW)
        // UART_BASE = 0x4000_3000
        // REG_UART_BAUD_DIV = 0x4000_300C. Divisor = 31 ((31 >> 4 + 1) * 16 * 20ns = 640ns, (31+1)*20ns = 640ns)
        wb_write(32'h4000_300C, 32'h0000_001F);

        `uvm_info(get_type_name(), "=== [Step 2] Sending Serial Byte 'K' (0x4B) via VIP Driver ===", UVM_LOW)
        uart_send_byte(8'h4B);

        // Wait for serial reception into UART RX FIFO (10 bits * 640ns = 6400ns)
        #9000ns;

        `uvm_info(get_type_name(), "=== [Step 3] Verifying Received Byte in UART Hardware ===", UVM_LOW)
        wb_read(32'h4000_3004, rdata);
        `uvm_info(get_type_name(), $sformatf("UART RX Wishbone Readback: 0x%02h", rdata[7:0]), UVM_LOW)
        if (uart_vif != null) begin
            `uvm_info(get_type_name(), $sformatf("UART RX Hardware Shift Register: 0x%02h ('%c')",
                      uart_vif.rx_shift_reg_probe, uart_vif.rx_shift_reg_probe), UVM_LOW)
            if (uart_vif.rx_shift_reg_probe == 8'h4B) begin
                `uvm_info(get_type_name(), "★ UART Receiver Verified: Transmitted 0x4B ('K') successfully captured in RX hardware! ★", UVM_NONE)
            end else begin
                `uvm_error(get_type_name(), $sformatf("UART RX Hardware Mismatch: Got 0x%02h, Expected 0x4B", uart_vif.rx_shift_reg_probe))
            end
        end

        `uvm_info(get_type_name(), "=== [Step 4] Transmitting Test Byte 'U' (0x55) via UART TX FIFO (0x4000_3000) ===", UVM_LOW)
        wb_write(32'h4000_3000, 32'h0000_0055);
        #9000ns;
    endtask

endclass

`endif // NEUROEDGE_UART_VSEQ_SV
