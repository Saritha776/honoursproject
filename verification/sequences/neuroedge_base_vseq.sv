// ==============================================================================
// Class: neuroedge_base_vseq.sv
// Description: Base Virtual Sequence providing utility tasks for SoC VIP operations
// ==============================================================================

`ifndef NEUROEDGE_BASE_VSEQ_SV
`define NEUROEDGE_BASE_VSEQ_SV

class neuroedge_base_vseq extends uvm_sequence #(uvm_sequence_item);

    `uvm_object_utils(neuroedge_base_vseq)
    `uvm_declare_p_sequencer(neuroedge_virtual_sequencer)

    function new(string name = "neuroedge_base_vseq");
        super.new(name);
    endfunction

    // Wishbone Master Write Task
    task wb_write(bit [31:0] addr, bit [31:0] data, bit [3:0] sel = 4'b1111);
        wb_item item;
        item = wb_item::type_id::create("vseq_wb_write");
        start_item(item, -1, p_sequencer.wb_seqr);
        item.op    = WB_WRITE;
        item.addr  = addr;
        item.data  = data;
        item.sel   = sel;
        item.delay = 0;
        finish_item(item);
    endtask

    // Wishbone Master Read Task
    task wb_read(input bit [31:0] addr, output bit [31:0] data, input bit [3:0] sel = 4'b1111);
        wb_item item;
        item = wb_item::type_id::create("vseq_wb_read");
        start_item(item, -1, p_sequencer.wb_seqr);
        item.op    = WB_READ;
        item.addr  = addr;
        item.sel   = sel;
        item.delay = 0;
        finish_item(item);
        data = item.data;
    endtask

    // Wishbone Write with Expected ACK/ERR check
    task wb_write_check_err(bit [31:0] addr, bit [31:0] data, output bit err_out);
        wb_item item;
        item = wb_item::type_id::create("vseq_wb_write_err");
        start_item(item, -1, p_sequencer.wb_seqr);
        item.op    = WB_WRITE;
        item.addr  = addr;
        item.data  = data;
        item.sel   = 4'b1111;
        item.delay = 0;
        finish_item(item);
        err_out = item.err;
    endtask

    // Send byte into SoC UART RX
    task uart_send_byte(bit [7:0] data_byte);
        uart_item item;
        item = uart_item::type_id::create("vseq_uart_send");
        start_item(item, -1, p_sequencer.uart_seqr);
        item.data = data_byte;
        finish_item(item);
    endtask

    // Drive external GPIO input pins
    task gpio_set_input(bit [7:0] val);
        gpio_item item;
        item = gpio_item::type_id::create("vseq_gpio_in");
        start_item(item, -1, p_sequencer.gpio_seqr);
        item.gpio_in = val;
        finish_item(item);
    endtask

endclass

`endif // NEUROEDGE_BASE_VSEQ_SV
