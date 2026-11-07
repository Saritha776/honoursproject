// ==============================================================================
// Class: neuroedge_gpio_test.sv
// Description: UVM Test verifying GPIO-only VIP transaction flow with NeuroEdge SoC:
//              - Creates and runs gpio_base_sequence on env.gpio_agent_inst.seqr
//              - Drives all 7 patterns: 0x00, 0xFF, 0xAA, 0x55, walking-1s,
//                walking-0s, and randomized vectors.
//              - VIP Monitor samples input/output transitions synchronously
//              - Scoreboard verifies firmware completion milestone (0xAA)
// ==============================================================================

`ifndef NEUROEDGE_GPIO_TEST_SV
`define NEUROEDGE_GPIO_TEST_SV

class neuroedge_gpio_test extends neuroedge_base_test;

    `uvm_component_utils(neuroedge_gpio_test)

    function new(string name = "neuroedge_gpio_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Explicitly instantiate ONLY single GPIO VIP agent in environment
        cfg.enable_lsu_axi  = 1'b0;
        cfg.enable_ifu_axi  = 1'b0;
        cfg.enable_wb       = 1'b0;
        cfg.enable_uart     = 1'b0;
        cfg.enable_systolic = 1'b0;
        cfg.enable_spi      = 1'b0;
        cfg.enable_gpio     = 1'b1;
    endfunction

    task run_phase(uvm_phase phase);
        gpio_base_sequence seq;
        phase.raise_objection(this);

        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        `uvm_info(get_type_name(), "   Starting NeuroEdge SoC GPIO-Only VIP Test      ", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================", UVM_LOW)

        seq = gpio_base_sequence::type_id::create("seq");

        fork
            // Thread 1: Execute complete 7-pattern stimulus sequence on GPIO agent sequencer
            begin
                seq.start(env.gpio_agent_inst.seqr);
                `uvm_info(get_type_name(), "★ GPIO Base Sequence Completed All Stimulus Patterns ★", UVM_LOW)
            end

            // Thread 2: Await VeeR CPU autonomous firmware execution and milestone 0xAA
            begin
                wait (env.gpio_agent_inst.sb.success_seen === 1'b1);
                `uvm_info(get_type_name(), "★ GPIO Scoreboard Confirmed Milestone 0xAA from VeeR CPU! ★", UVM_NONE)
            end
        join

        // Observation period after all patterns & firmware completion
        #5000ns;

        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        `uvm_info(get_type_name(), "   GPIO-Only VIP Test PASSED with Full Sequence   ", UVM_LOW)
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
