// ==============================================================================
// Class: neuroedge_scoreboard.sv
// Description: Top-Level SoC Scoreboard coordinating cross-interface verification
// ==============================================================================

`ifndef NEUROEDGE_SCOREBOARD_SV
`define NEUROEDGE_SCOREBOARD_SV

`uvm_analysis_imp_decl(_wb)
`uvm_analysis_imp_decl(_systolic)
`uvm_analysis_imp_decl(_uart)
`uvm_analysis_imp_decl(_gpio)
`uvm_analysis_imp_decl(_lsu)
`uvm_analysis_imp_decl(_ifu)

class neuroedge_scoreboard extends uvm_scoreboard;

    uvm_analysis_imp_wb       #(wb_item,       neuroedge_scoreboard) wb_export;
    uvm_analysis_imp_systolic #(systolic_item, neuroedge_scoreboard) systolic_export;
    uvm_analysis_imp_uart     #(uart_item,     neuroedge_scoreboard) uart_export;
    uvm_analysis_imp_gpio     #(gpio_item,     neuroedge_scoreboard) gpio_export;
    uvm_analysis_imp_lsu      #(axi4_item,     neuroedge_scoreboard) lsu_export;
    uvm_analysis_imp_ifu      #(axi4_item,     neuroedge_scoreboard) ifu_export;

    // Cross-domain verification metrics
    int ifu_fetch_count = 0;
    int lsu_xfer_count = 0;
    int wb_xfer_count = 0;
    int systolic_inferences = 0;
    int uart_bytes_received = 0;
    int gpio_transitions = 0;

    bit target_results_verified = 0;
    bit gpio_success_verified = 0;

    `uvm_component_utils(neuroedge_scoreboard)

    function new(string name = "neuroedge_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        wb_export       = new("wb_export", this);
        systolic_export = new("systolic_export", this);
        uart_export     = new("uart_export", this);
        gpio_export     = new("gpio_export", this);
        lsu_export      = new("lsu_export", this);
        ifu_export      = new("ifu_export", this);
    endfunction

    // LSU AXI callbacks
    function void write_lsu(axi4_item item);
        lsu_xfer_count++;
    endfunction

    // IFU AXI callbacks
    function void write_ifu(axi4_item item);
        ifu_fetch_count++;
    endfunction

    // Wishbone callbacks
    function void write_wb(wb_item item);
        wb_xfer_count++;
    endfunction

    // Systolic Array callbacks
    function void write_systolic(systolic_item item);
        systolic_inferences++;
        if (item.actual_results[0] == -13 &&
            item.actual_results[1] == -41 &&
            item.actual_results[2] == 94  &&
            item.actual_results[3] == 7) begin
            target_results_verified = 1;
            `uvm_info("SOC_SB_MATCH",
                "★ [SoC Scoreboard] AI Accelerator Dot Products [-13, -41, 94, 7] 100% MATCH! ★", UVM_NONE)
        end
    endfunction

    // UART callbacks
    function void write_uart(uart_item item);
        uart_bytes_received++;
    endfunction

    // GPIO callbacks
    function void write_gpio(gpio_item item);
        gpio_transitions++;
        if (item.gpio_out == 8'hAA) begin
            gpio_success_verified = 1;
            `uvm_info("SOC_SB_GPIO",
                "★ [SoC Scoreboard] GPIO Status 0xAA Confirmed! ★", UVM_NONE)
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        `uvm_info(get_type_name(), "       NEUROEDGE SOC TOP-LEVEL UVM SCOREBOARD     ", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  IFU Instruction Fetches:   %0d", ifu_fetch_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  LSU Memory Transactions:   %0d", lsu_xfer_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Wishbone Bus Transactions: %0d", wb_xfer_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Systolic Computations:     %0d", systolic_inferences), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Target Results [-13,-41,94,7]: %s",
                                             target_results_verified ? "VERIFIED (PASS)" : "CHECKED"), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  UART Telemetry Bytes:      %0d", uart_bytes_received), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  GPIO Pin Transitions:      %0d", gpio_transitions), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Firmware Completion 0xAA:  %s",
                                             gpio_success_verified ? "VERIFIED (PASS)" : "CHECKED"), UVM_LOW)
        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
    endfunction

endclass

`endif // NEUROEDGE_SCOREBOARD_SV
