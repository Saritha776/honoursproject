// ==============================================================================
// Class: gpio_driver.sv
// Description: Driver for GPIO input pins
// ==============================================================================

`ifndef GPIO_DRIVER_SV
`define GPIO_DRIVER_SV

class gpio_driver extends uvm_driver #(gpio_item);

    virtual gpio_if vif;
    gpio_cfg        cfg;

    `uvm_component_utils(gpio_driver)

    function new(string name = "gpio_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual gpio_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"});
        end
    endfunction

    task run_phase(uvm_phase phase);
        vif.gpio_in <= 8'h00;
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        forever begin
            seq_item_port.get_next_item(req);
            @(posedge vif.clk);
            vif.gpio_in <= req.gpio_in;
            seq_item_port.item_done();
        end
    endtask

endclass

`endif // GPIO_DRIVER_SV
