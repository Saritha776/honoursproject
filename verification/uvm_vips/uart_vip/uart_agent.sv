// ==============================================================================
// Class: uart_agent.sv
// Description: UVM Agent for UART VIP encapsulating Driver, Seqr, Mon, Cov, SB
// ==============================================================================

`ifndef UART_AGENT_SV
`define UART_AGENT_SV

class uart_agent extends uvm_agent;

    uart_cfg        cfg;
    uart_sequencer  seqr;
    uart_driver     drv;
    uart_monitor    mon;
    uart_coverage   cov;
    uart_scoreboard sb;

    uvm_analysis_port #(uart_item) item_collected_port;

    `uvm_component_utils(uart_agent)

    function new(string name = "uart_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(uart_cfg)::get(this, "", "cfg", cfg)) begin
            cfg = uart_cfg::type_id::create("cfg");
        end

        mon = uart_monitor::type_id::create("mon", this);
        mon.cfg = cfg;

        if (cfg.is_active == UVM_ACTIVE) begin
            seqr = uart_sequencer::type_id::create("seqr", this);
            drv  = uart_driver::type_id::create("drv", this);
            drv.cfg = cfg;
        end

        if (cfg.enable_coverage) begin
            cov = uart_coverage::type_id::create("cov", this);
        end

        sb = uart_scoreboard::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (cfg.is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seqr.seq_item_export);
        end

        item_collected_port = mon.item_collected_port;

        if (cfg.enable_coverage) begin
            mon.item_collected_port.connect(cov.analysis_export);
        end

        mon.item_collected_port.connect(sb.item_collected_export);
    endfunction

endclass

`endif // UART_AGENT_SV
