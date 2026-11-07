// ==============================================================================
// Class: wb_agent.sv
// Description: UVM Agent for Wishbone VIP encapsulating Driver, Seqr, Mon, Cov, SB
// ==============================================================================

`ifndef WB_AGENT_SV
`define WB_AGENT_SV

class wb_agent extends uvm_agent;

    wb_cfg        cfg;
    wb_sequencer  seqr;
    wb_driver     drv;
    wb_monitor    mon;
    wb_coverage   cov;
    wb_scoreboard sb;

    uvm_analysis_port #(wb_item) item_collected_port;

    `uvm_component_utils(wb_agent)

    function new(string name = "wb_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(wb_cfg)::get(this, "", "cfg", cfg)) begin
            cfg = wb_cfg::type_id::create("cfg");
        end

        mon = wb_monitor::type_id::create("mon", this);
        mon.cfg = cfg;

        if (cfg.is_active == UVM_ACTIVE) begin
            seqr = wb_sequencer::type_id::create("seqr", this);
            drv  = wb_driver::type_id::create("drv", this);
            drv.cfg = cfg;
        end

        if (cfg.enable_coverage) begin
            cov = wb_coverage::type_id::create("cov", this);
        end

        sb = wb_scoreboard::type_id::create("sb", this);
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

`endif // WB_AGENT_SV
