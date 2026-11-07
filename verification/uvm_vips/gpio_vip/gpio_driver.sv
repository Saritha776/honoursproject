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
        // Initialize GPIO inputs to default 0x00 (drives ONLY DUT input pins)
        vif.gpio_in <= 8'h00;
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_item(gpio_item req);
        @(posedge vif.clk);
        vif.gpio_in <= req.gpio_in;
        `uvm_info("GPIO_INJ_DRIVER", $sformatf("★ [GPIO_INJ_DRIVER] Injected Single Pin Value: gpio_in = 0x%02h ★", req.gpio_in), UVM_NONE)
    endtask

endclass

`endif // GPIO_DRIVER_SV
