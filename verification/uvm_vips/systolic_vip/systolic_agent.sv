// ==============================================================================
// Class: systolic_agent.sv
// Description: UVM Agent for Systolic Array VIP encapsulating Drv, Seqr, Mon, Cov, SB
// ==============================================================================

`ifndef SYSTOLIC_AGENT_SV
`define SYSTOLIC_AGENT_SV

class systolic_agent extends uvm_agent;

    systolic_cfg        cfg;
    systolic_sequencer  seqr;
    systolic_driver     drv;
    systolic_monitor    mon;
    systolic_coverage   cov;
    systolic_scoreboard sb;

    uvm_analysis_port #(systolic_item) item_collected_port;

    `uvm_component_utils(systolic_agent)

    function new(string name = "systolic_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(systolic_cfg)::get(this, "", "cfg", cfg)) begin
            cfg = systolic_cfg::type_id::create("cfg");
        end

        mon = systolic_monitor::type_id::create("mon", this);
        mon.cfg = cfg;

        if (cfg.is_active == UVM_ACTIVE) begin
            seqr = systolic_sequencer::type_id::create("seqr", this);
            drv  = systolic_driver::type_id::create("drv", this);
            drv.cfg = cfg;
        end

        if (cfg.enable_coverage) begin
            cov = systolic_coverage::type_id::create("cov", this);
        end

        sb = systolic_scoreboard::type_id::create("sb", this);
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

`endif // SYSTOLIC_AGENT_SV
