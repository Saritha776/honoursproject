// ==============================================================================
// Class: uart_item.sv
// Description: UART Frame Transaction Item
// ==============================================================================

`ifndef UART_ITEM_SV
`define UART_ITEM_SV

class uart_item extends uvm_sequence_item;

    rand bit [7:0]  data;
    bit             frame_err;
    bit             parity_err;

    `uvm_object_utils_begin(uart_item)
        `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(frame_err, UVM_ALL_ON)
        `uvm_field_int(parity_err, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "uart_item");
        super.new(name);
    endfunction

    function string convert2string();
        if (data >= 8'h20 && data <= 8'h7E) begin
            return $sformatf("UART Frame: Char='%c' (0x%02h) FrameErr=%0b", data, data, frame_err);
        end else begin
            return $sformatf("UART Frame: Hex=0x%02h FrameErr=%0b", data, frame_err);
        end
    endfunction

endclass

`endif // UART_ITEM_SV
