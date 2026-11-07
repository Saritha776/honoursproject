// ==============================================================================
// Class: gpio_coverage.sv
// Description: Functional coverage collector for GPIO VIP
// ==============================================================================

`ifndef GPIO_COVERAGE_SV
`define GPIO_COVERAGE_SV

class gpio_coverage extends uvm_subscriber #(gpio_item);

    `uvm_component_utils(gpio_coverage)

    gpio_item item_cov;

    covergroup cg_gpio;
        cp_milestones: coverpoint item_cov.gpio_out {
            bins STAGE1 = {8'h01};
            bins STAGE2 = {8'h02};
            bins STAGE3 = {8'h04};
            bins STAGE4 = {8'h08};
            bins SUCCESS= {8'hAA};
            bins OTHER  = default;
        }

        cp_dir: coverpoint item_cov.gpio_dir {
            bins ALL_OUTPUT = {8'hFF};
            bins ALL_INPUT  = {8'h00};
        }
    endgroup

    function new(string name = "gpio_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_gpio = new();
    endfunction

    function void write(gpio_item t);
        item_cov = t;
        cg_gpio.sample();
    endfunction

    function real get_coverage_pct();
        return cg_gpio.get_coverage();
    endfunction

endclass

`endif // GPIO_COVERAGE_SV
