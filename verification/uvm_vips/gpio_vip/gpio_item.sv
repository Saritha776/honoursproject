// ==============================================================================
// Class: gpio_item.sv
// Description: GPIO Transaction Item
// ==============================================================================

`ifndef GPIO_ITEM_SV
`define GPIO_ITEM_SV

class gpio_item extends uvm_sequence_item;

    rand bit [7:0] gpio_in;
    bit [7:0]      gpio_out;
    bit [7:0]      gpio_dir;

    `uvm_object_utils_begin(gpio_item)
        `uvm_field_int(gpio_in, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(gpio_out, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(gpio_dir, UVM_ALL_ON | UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "gpio_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("GPIO: In=0x%02h Out=0x%02h Dir=0x%02h", gpio_in, gpio_out, gpio_dir);
    endfunction

endclass

`endif // GPIO_ITEM_SV
