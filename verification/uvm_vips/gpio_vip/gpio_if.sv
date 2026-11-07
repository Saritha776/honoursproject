// ==============================================================================
// Interface: gpio_if.sv
// Description: GPIO Interface with signal monitors and assertions
// ==============================================================================

interface gpio_if (
    input logic clk,
    input logic rst_n
);

    logic [7:0] gpio_in;
    logic [7:0] gpio_out;
    logic [7:0] gpio_dir;

    // Assertions
    property p_gpio_out_known;
        @(posedge clk) disable iff (!rst_n)
        $isunknown(gpio_out) == 0;
    endproperty
    assert_gpio_out_known: assert property (p_gpio_out_known)
        else $error("[GPIO_IF] GPIO out pins contain unknown states");

endinterface
