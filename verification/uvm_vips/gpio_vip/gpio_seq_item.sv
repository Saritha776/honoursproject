// ==============================================================================
// Class: gpio_seq_item.sv
// Description: GPIO UVM Sequence Item extending uvm_sequence_item for NeuroEdge SoC.
//              Contains randomized GPIO input data and transaction delay,
//              with monitored (non-random) DUT output and direction signals.
// ==============================================================================

`ifndef GPIO_SEQ_ITEM_SV
`define GPIO_SEQ_ITEM_SV

class gpio_seq_item extends uvm_sequence_item;

    // Driven by Testbench VIP Driver onto DUT input pins
    rand bit [7:0]         gpio_in;

    // Inter-transaction delay in clock cycles (useful for synchronizer settling)
    rand int unsigned      delay;

    // Monitored from DUT output pins (Do NOT randomize DUT output signals)
    bit [7:0]              gpio_out;
    bit [7:0]              gpio_dir;

    // Constraints supported by 8-bit GPIO design
    constraint c_default_delay {
        delay inside {[2:8]};
    }

    `uvm_object_utils_begin(gpio_seq_item)
        `uvm_field_int(gpio_in,   UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(delay,     UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(gpio_out,  UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(gpio_dir,  UVM_ALL_ON | UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "gpio_seq_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("GPIO_ITEM: In=0x%02h (delay=%0d clks) | DUT Out=0x%02h Dir=0x%02h",
                         gpio_in, delay, gpio_out, gpio_dir);
    endfunction

endclass

// Typedef for seamless compatibility with components expecting gpio_item
typedef gpio_seq_item gpio_item;

`endif // GPIO_SEQ_ITEM_SV
