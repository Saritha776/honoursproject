// ==============================================================================
// Class: gpio_agent.sv
// Description: UVM Agent for GPIO VIP
// ==============================================================================

`ifndef GPIO_AGENT_SV
`define GPIO_AGENT_SV

class gpio_agent extends uvm_agent;

    gpio_cfg        cfg;
    gpio_sequencer  seqr;
    gpio_driver     drv;
    gpio_monitor    mon;
    gpio_coverage   cov;
    gpio_scoreboard sb;

    uvm_analysis_port #(gpio_item) item_collected_port;

    `uvm_component_utils(gpio_agent)

    function new(string name = "gpio_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(gpio_cfg)::get(this, "", "cfg", cfg)) begin
            cfg = gpio_cfg::type_id::create("cfg");
        end

        mon = gpio_monitor::type_id::create("mon", this);
        mon.cfg = cfg;

        if (cfg.is_active == UVM_ACTIVE) begin
            seqr = gpio_sequencer::type_id::create("seqr", this);
            drv  = gpio_driver::type_id::create("drv", this);
            drv.cfg = cfg;
        end

        if (cfg.enable_coverage) begin
            cov = gpio_coverage::type_id::create("cov", this);
        end

        sb = gpio_scoreboard::type_id::create("sb", this);
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

`endif // GPIO_AGENT_SV
