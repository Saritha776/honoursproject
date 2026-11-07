// ==============================================================================
// Class: spi_flash_agent.sv
// Description: UVM Agent for SPI Flash VIP
// ==============================================================================

`ifndef SPI_FLASH_AGENT_SV
`define SPI_FLASH_AGENT_SV

class spi_flash_agent extends uvm_agent;

    spi_flash_cfg        cfg;
    spi_flash_sequencer  seqr;
    spi_flash_driver     drv;
    spi_flash_monitor    mon;
    spi_flash_coverage   cov;
    spi_flash_scoreboard sb;

    uvm_analysis_port #(spi_flash_item) item_collected_port;

    `uvm_component_utils(spi_flash_agent)

    function new(string name = "spi_flash_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(spi_flash_cfg)::get(this, "", "cfg", cfg)) begin
            cfg = spi_flash_cfg::type_id::create("cfg");
        end

        mon = spi_flash_monitor::type_id::create("mon", this);
        mon.cfg = cfg;

        if (cfg.is_active == UVM_ACTIVE) begin
            seqr = spi_flash_sequencer::type_id::create("seqr", this);
            drv  = spi_flash_driver::type_id::create("drv", this);
            drv.cfg = cfg;
        end

        if (cfg.enable_coverage) begin
            cov = spi_flash_coverage::type_id::create("cov", this);
        end

        sb = spi_flash_scoreboard::type_id::create("sb", this);
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

`endif // SPI_FLASH_AGENT_SV
