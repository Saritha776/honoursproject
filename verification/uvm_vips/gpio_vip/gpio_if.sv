// ==============================================================================
// Interface: gpio_if.sv
// Description: GPIO Interface with signal monitors, clocking blocks, modports,
//              and assertions for NeuroEdge SoC GPIO verification.
// ==============================================================================

`ifndef GPIO_IF_SV
`define GPIO_IF_SV

interface gpio_if (
    input logic clk,
    input logic rst_n
);

    // Actual GPIO pins matching NeuroEdge SoC
    logic [7:0] gpio_in;   // Inputs to DUT (driven by VIP Driver)
    logic [7:0] gpio_out;  // Outputs from DUT (sampled by VIP Monitor)
    logic [7:0] gpio_dir;  // Direction from DUT (sampled by VIP Monitor)

    // Driver Clocking Block (drives inputs to DUT, samples outputs from DUT)
    clocking drv_cb @(posedge clk);
        default input #1step output #100ps;
        output gpio_in;
        input  gpio_out;
        input  gpio_dir;
    endclocking

    // Monitor Clocking Block (samples all signals synchronously)
    clocking mon_cb @(posedge clk);
        default input #1step;
        input  gpio_in;
        input  gpio_out;
        input  gpio_dir;
    endclocking

    // Modports for Driver and Monitor
    modport DRV (clocking drv_cb, input clk, input rst_n, output gpio_in);
    modport MON (clocking mon_cb, input clk, input rst_n, input gpio_in, input gpio_out, input gpio_dir);

    // Assertions
    property p_gpio_out_known;
        @(posedge clk) disable iff (!rst_n)
        !$isunknown(gpio_out);
    endproperty
    assert_gpio_out_known: assert property (p_gpio_out_known)
        else $error("[GPIO_IF] GPIO out pins contain unknown states");

    property p_gpio_dir_known;
        @(posedge clk) disable iff (!rst_n)
        !$isunknown(gpio_dir);
    endproperty
    assert_gpio_dir_known: assert property (p_gpio_dir_known)
        else $error("[GPIO_IF] GPIO dir pins contain unknown states");

endinterface

`endif // GPIO_IF_SV
