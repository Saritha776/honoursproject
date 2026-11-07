// ==============================================================================
// Class: neuroedge_firmware_test.sv
// Description: UVM Test executing bare-metal C firmware on VeeR with VIP monitors
// ==============================================================================

`ifndef NEUROEDGE_FIRMWARE_TEST_SV
`define NEUROEDGE_FIRMWARE_TEST_SV

class neuroedge_firmware_test extends neuroedge_base_test;

    `uvm_component_utils(neuroedge_firmware_test)

    function new(string name = "neuroedge_firmware_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "=== Launching Autonomous VeeR Firmware Execution under UVM VIP Monitoring ===", UVM_LOW)

        // Wait for firmware execution milestone or completion
        // Autonomous execution takes ~3.8ms in simulation
        fork
            begin
                // Thread 1: Wait for milestone marker 0xAA in GPIO monitor
                wait (env.soc_sb.gpio_success_verified == 1);
                `uvm_info(get_type_name(), "Detected Firmware GPIO Milestone 0xAA! Draining UART final banner...", UVM_LOW)
                #250000ns;
            end
            begin
                // Thread 2: Timeout guard
                #4500us;
                `uvm_info(get_type_name(), "Firmware simulation time elapsed. Finishing test...", UVM_LOW)
            end
        join_any

        if (!env.soc_sb.gpio_success_verified) begin
            `uvm_error(get_type_name(), "Firmware test timed out before achieving GPIO milestone 0xAA!")
        end else begin
            `uvm_info(get_type_name(), "★ Full Autonomous VeeR Firmware Execution Verified (PASS)! ★", UVM_NONE)
        end

        `uvm_info(get_type_name(), "=== VeeR Firmware Execution Completed ===", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

`endif // NEUROEDGE_FIRMWARE_TEST_SV
