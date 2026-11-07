// ==============================================================================
// Class: axi4_item.sv
// Description: AXI4 Transaction / Sequence Item supporting bursts & responses
// ==============================================================================

`ifndef AXI4_ITEM_SV
`define AXI4_ITEM_SV

typedef enum bit { AXI_READ = 1'b0, AXI_WRITE = 1'b1 } axi_xfer_type_e;
typedef enum bit [1:0] { AXI_BURST_FIXED = 2'b00, AXI_BURST_INCR = 2'b01, AXI_BURST_WRAP = 2'b10 } axi_burst_e;
typedef enum bit [1:0] { AXI_RESP_OKAY = 2'b00, AXI_RESP_EXOKAY = 2'b01, AXI_RESP_SLVERR = 2'b10, AXI_RESP_DECERR = 2'b11 } axi_resp_e;

class axi4_item extends uvm_sequence_item;

    rand axi_xfer_type_e        xfer_type;
    rand bit [7:0]              id;
    rand bit [31:0]             addr;
    rand bit [7:0]              len;     // Burst length: 0 = 1 beat, 1 = 2 beats...
    rand bit [2:0]              size;    // 3'b011 = 8 bytes (64-bit), 3'b010 = 4 bytes (32-bit)
    rand axi_burst_e            burst;
    rand bit [63:0]             data[];
    rand bit [7:0]              strb[];
    axi_resp_e                  resp[];
    bit [1:0]                   bresp;

    // Constraints
    constraint c_len {
        len inside {[0:15]};
    }

    constraint c_size {
        size inside {3'b000, 3'b001, 3'b010, 3'b011}; // 1, 2, 4, 8 bytes
    }

    constraint c_burst {
        burst == AXI_BURST_INCR;
    }

    constraint c_payload_size {
        data.size() == len + 1;
        strb.size() == len + 1;
    }

    constraint c_align {
        if (size == 3'b011) addr[2:0] == 3'b000;
        else if (size == 3'b010) addr[1:0] == 2'b00;
        else if (size == 3'b001) addr[0] == 1'b0;
    }

    `uvm_object_utils_begin(axi4_item)
        `uvm_field_enum(axi_xfer_type_e, xfer_type, UVM_ALL_ON)
        `uvm_field_int(id, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(len, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(size, UVM_ALL_ON | UVM_DEC)
        `uvm_field_enum(axi_burst_e, burst, UVM_ALL_ON)
        `uvm_field_array_int(data, UVM_ALL_ON | UVM_HEX)
        `uvm_field_array_int(strb, UVM_ALL_ON | UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "axi4_item");
        super.new(name);
    endfunction

    function string convert2string();
        string s;
        s = $sformatf("AXI4 [%s] ID=0x%0h Addr=0x%08h Len=%0d Size=%0d Burst=%0s Beats=%0d",
                      xfer_type.name(), id, addr, len, size, burst.name(), data.size());
        foreach (data[i]) begin
            s = {s, $sformatf(" [Beat %0d: D=0x%016h, Strb=0x%02h]", i, data[i], (i < strb.size() ? strb[i] : 8'h00))};
        end
        return s;
    endfunction

endclass

`endif // AXI4_ITEM_SV
