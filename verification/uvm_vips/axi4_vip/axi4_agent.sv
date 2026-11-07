// ==============================================================================
// Class: axi4_agent.sv
// Description: UVM Agent for AXI4 VIP encapsulating Driver, Seqr, Mon, Cov, SB
// ==============================================================================

`ifndef AXI4_AGENT_SV
`define AXI4_AGENT_SV

class axi4_agent extends uvm_agent;

    axi4_cfg        cfg;
    axi4_sequencer  seqr;
    axi4_driver     drv;
    axi4_monitor    mon;
    axi4_coverage   cov;
    axi4_scoreboard sb;

    uvm_analysis_port #(axi4_item) item_collected_port;

    `uvm_component_utils(axi4_agent)

    function new(string name = "axi4_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(axi4_cfg)::get(this, "", "cfg", cfg)) begin
            cfg = axi4_cfg::type_id::create("cfg");
        end

        mon = axi4_monitor::type_id::create("mon", this);
        mon.cfg = cfg;

        if (cfg.is_active == UVM_ACTIVE) begin
            seqr = axi4_sequencer::type_id::create("seqr", this);
            drv  = axi4_driver::type_id::create("drv", this);
            drv.cfg = cfg;
        end

        if (cfg.enable_coverage) begin
            cov = axi4_coverage::type_id::create("cov", this);
        end

        sb = axi4_scoreboard::type_id::create("sb", this);
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

`endif // AXI4_AGENT_SV
