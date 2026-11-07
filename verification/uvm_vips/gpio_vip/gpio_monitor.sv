// ==============================================================================
// Class: gpio_monitor.sv
// Description: Functional monitor for GPIO input, output, and direction transitions
// ==============================================================================

`ifndef GPIO_MONITOR_SV
`define GPIO_MONITOR_SV

class gpio_monitor extends uvm_monitor;

    virtual gpio_if vif;
    gpio_cfg        cfg;

    uvm_analysis_port #(gpio_item) item_collected_port;

    logic [7:0] prev_gpio_in  = 8'h00;
    logic [7:0] prev_gpio_out = 8'h00;
    logic [7:0] prev_gpio_dir = 8'h00;
    bit         first_sample  = 1'b1;

    `uvm_component_utils(gpio_monitor)

    function new(string name = "gpio_monitor", uvm_component parent = null);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual gpio_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"});
        end
    endfunction

    task run_phase(uvm_phase phase);
        gpio_item item;
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        forever begin
            @(posedge vif.clk);
            if (vif.rst_n) begin
                if (first_sample ||
                    (vif.gpio_in  !== prev_gpio_in)  ||
                    (vif.gpio_out !== prev_gpio_out) ||
                    (vif.gpio_dir !== prev_gpio_dir)) begin

                    item = gpio_item::type_id::create("mon_gpio_item");
                    item.gpio_in  = vif.gpio_in;
                    item.gpio_out = vif.gpio_out;
                    item.gpio_dir = vif.gpio_dir;

                    prev_gpio_in  = vif.gpio_in;
                    prev_gpio_out = vif.gpio_out;
                    prev_gpio_dir = vif.gpio_dir;
                    first_sample  = 1'b0;

                    `uvm_info(get_type_name(), $sformatf("Monitored GPIO Pin Transition: In=0x%02h Out=0x%02h Dir=0x%02h",
                              item.gpio_in, item.gpio_out, item.gpio_dir), UVM_MEDIUM)
                    item_collected_port.write(item);
                end
            end
        end
    endtask

endclass

`endif // GPIO_MONITOR_SV
