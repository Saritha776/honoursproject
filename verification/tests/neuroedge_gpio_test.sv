// ==============================================================================
// Class: neuroedge_gpio_test.sv
// Description: UVM Test verifying single GPIO VIP integration with NeuroEdge SoC:
//              - Injects single GPIO input value (0xA5) one time via VIP Driver
//              - VIP Monitor samples gpio_in, gpio_out, and gpio_dir
//              - Scoreboard verifies firmware completion milestone (0xAA)
// ==============================================================================

`ifndef NEUROEDGE_GPIO_TEST_SV
`define NEUROEDGE_GPIO_TEST_SV

class gpio_stim_seq extends uvm_sequence #(gpio_item);

    `uvm_object_utils(gpio_stim_seq)

    bit [7:0] inject_val;

    function new(string name = "gpio_stim_seq");
        super.new(name);
        inject_val = 8'hA5; // Single distinct injection value
    endfunction

    task body();
        gpio_item item;
        #100ns; // Delay past reset deassertion
        item = gpio_item::type_id::create("gpio_single_stim");
        start_item(item);
        item.gpio_in = inject_val;
        finish_item(item);
        `uvm_info("GPIO_INJ_DRIVER",
            $sformatf("★ Single GPIO Stimulus Injected by Driver: gpio_in = 0x%02h ★", inject_val), UVM_NONE)
    endtask

endclass

class neuroedge_gpio_test extends neuroedge_base_test;

    `uvm_component_utils(neuroedge_gpio_test)

    function new(string name = "neuroedge_gpio_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Explicitly ensure ONLY single GPIO VIP is enabled in environment
        cfg.enable_lsu_axi  = 1'b0;
        cfg.enable_ifu_axi  = 1'b0;
        cfg.enable_wb       = 1'b0;
        cfg.enable_uart     = 1'b0;
        cfg.enable_systolic = 1'b0;
        cfg.enable_spi      = 1'b0;
        cfg.enable_gpio     = 1'b1;
    endfunction

    task run_phase(uvm_phase phase);
        gpio_stim_seq stim_seq;
        phase.raise_objection(this);

        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        `uvm_info(get_type_name(), "   Starting Single GPIO VIP Injection Test        ", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================", UVM_LOW)

        stim_seq = gpio_stim_seq::type_id::create("stim_seq");
        stim_seq.inject_val = 8'hA5; // Set one time

        fork
            // Thread 1: Inject single value once into VIP driver
            begin
                stim_seq.start(env.gpio_agent_inst.seqr);
            end

            // Thread 2: Await VeeR CPU autonomous firmware execution and milestone 0xAA
            begin
                wait (env.gpio_agent_inst.sb.success_seen === 1'b1);
                `uvm_info(get_type_name(), "★ GPIO Scoreboard confirmed Milestone 0xAA from VeeR CPU! ★", UVM_NONE)
                #10000ns;
            end
        join

        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        `uvm_info(get_type_name(), "   Single GPIO VIP Test PASSED with Single Injection ", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

// Factory alias for compatibility with tests requesting "gpio_test"
class gpio_test extends neuroedge_gpio_test;
    `uvm_component_utils(gpio_test)
    function new(string name = "gpio_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

`endif // NEUROEDGE_GPIO_TEST_SV
