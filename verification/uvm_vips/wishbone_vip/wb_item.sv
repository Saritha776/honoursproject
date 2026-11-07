// ==============================================================================
// Class: wb_item.sv
// Description: Wishbone Transaction / Sequence Item
// ==============================================================================

`ifndef WB_ITEM_SV
`define WB_ITEM_SV

typedef enum bit { WB_READ = 1'b0, WB_WRITE = 1'b1 } wb_op_e;

class wb_item extends uvm_sequence_item;

    rand wb_op_e    op;
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit [3:0]  sel;
    rand int        delay;
    bit             ack;
    bit             err;

    constraint c_sel_valid {
        sel inside {4'b0001, 4'b0010, 4'b0100, 4'b1000, 4'b0011, 4'b1100, 4'b1111};
    }

    constraint c_delay {
        delay inside {[0:5]};
    }

    constraint c_align {
        if (sel == 4'b1111) addr[1:0] == 2'b00;
        else if (sel inside {4'b0011, 4'b1100}) addr[0] == 1'b0;
    }

    `uvm_object_utils_begin(wb_item)
        `uvm_field_enum(wb_op_e, op, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(sel, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(delay, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(ack, UVM_ALL_ON)
        `uvm_field_int(err, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "wb_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("WB [%s] Addr=0x%08h Data=0x%08h Sel=4'b%04b ACK=%0b ERR=%0b Delay=%0d",
                        op.name(), addr, data, sel, ack, err, delay);
    endfunction

endclass

`endif // WB_ITEM_SV
