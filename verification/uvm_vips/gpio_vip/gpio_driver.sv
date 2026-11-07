// ==============================================================================
// Class: gpio_driver.sv
// Description: Driver for GPIO input pins implementing standard UVM handshake flow
// ==============================================================================

`ifndef GPIO_DRIVER_SV
`define GPIO_DRIVER_SV

class gpio_driver extends uvm_driver #(gpio_seq_item);

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

            // Drive GPIO input transaction through virtual interface
            drive_item(req);

            seq_item_port.item_done();
        end
    endtask

    task drive_item(gpio_seq_item req);
        // Wait specified inter-transaction delay
        repeat (req.delay > 0 ? req.delay : 2) @(posedge vif.clk);

        // Drive DUT input pin gpio_in synchronously
        vif.gpio_in <= req.gpio_in;

        `uvm_info(get_type_name(),
            $sformatf("★ [GPIO_DRIVER] Drove DUT Input: gpio_in = 0x%02h (delay=%0d clks) | %s ★",
                      req.gpio_in, req.delay, req.convert2string()), UVM_LOW)
    endtask

endclass

`endif // GPIO_DRIVER_SV
