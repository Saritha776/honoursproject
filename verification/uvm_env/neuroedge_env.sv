// ==============================================================================
// Class: neuroedge_env.sv
// Description: Top-Level UVM Environment integrating VIP Agents & Scoreboard
//              Supports single GPIO VIP instantiation mode.
// ==============================================================================

`ifndef NEUROEDGE_ENV_SV
`define NEUROEDGE_ENV_SV

class neuroedge_env extends uvm_env;

    neuroedge_env_cfg           cfg;
    neuroedge_virtual_sequencer v_seqr;
    neuroedge_scoreboard        soc_sb;

    // Sub-VIP Agents
    axi4_agent                  lsu_axi_agent;
    axi4_agent                  ifu_axi_agent;
    wb_agent                    wb_agent_inst;
    uart_agent                  uart_agent_inst;
    systolic_agent              systolic_agent_inst;
    spi_flash_agent             spi_flash_agent_inst;
    gpio_agent                  gpio_agent_inst;

    `uvm_component_utils(neuroedge_env)

    function new(string name = "neuroedge_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(neuroedge_env_cfg)::get(this, "", "cfg", cfg)) begin
            cfg = neuroedge_env_cfg::type_id::create("cfg");
        end

        // Conditionally instantiate agents based on configuration
        if (cfg.enable_lsu_axi) begin
            if (cfg.lsu_axi_cfg == null) cfg.lsu_axi_cfg = axi4_cfg::type_id::create("lsu_axi_cfg");
            uvm_config_db#(axi4_cfg)::set(this, "lsu_axi_agent", "cfg", cfg.lsu_axi_cfg);
            lsu_axi_agent = axi4_agent::type_id::create("lsu_axi_agent", this);
        end

        if (cfg.enable_ifu_axi) begin
            if (cfg.ifu_axi_cfg == null) cfg.ifu_axi_cfg = axi4_cfg::type_id::create("ifu_axi_cfg");
            uvm_config_db#(axi4_cfg)::set(this, "ifu_axi_agent", "cfg", cfg.ifu_axi_cfg);
            ifu_axi_agent = axi4_agent::type_id::create("ifu_axi_agent", this);
        end

        if (cfg.enable_wb) begin
            if (cfg.wb_cfg_inst == null) cfg.wb_cfg_inst = wb_cfg::type_id::create("wb_cfg_inst");
            uvm_config_db#(wb_cfg)::set(this, "wb_agent_inst", "cfg", cfg.wb_cfg_inst);
            wb_agent_inst = wb_agent::type_id::create("wb_agent_inst", this);
        end

        if (cfg.enable_uart) begin
            if (cfg.uart_cfg_inst == null) cfg.uart_cfg_inst = uart_cfg::type_id::create("uart_cfg_inst");
            uvm_config_db#(uart_cfg)::set(this, "uart_agent_inst", "cfg", cfg.uart_cfg_inst);
            uart_agent_inst = uart_agent::type_id::create("uart_agent_inst", this);
        end

        if (cfg.enable_systolic) begin
            if (cfg.systolic_cfg_inst == null) cfg.systolic_cfg_inst = systolic_cfg::type_id::create("systolic_cfg_inst");
            uvm_config_db#(systolic_cfg)::set(this, "systolic_agent_inst", "cfg", cfg.systolic_cfg_inst);
            systolic_agent_inst = systolic_agent::type_id::create("systolic_agent_inst", this);
        end

        if (cfg.enable_spi) begin
            if (cfg.spi_cfg_inst == null) cfg.spi_cfg_inst = spi_flash_cfg::type_id::create("spi_cfg_inst");
            uvm_config_db#(spi_flash_cfg)::set(this, "spi_flash_agent_inst", "cfg", cfg.spi_cfg_inst);
            spi_flash_agent_inst = spi_flash_agent::type_id::create("spi_flash_agent_inst", this);
        end

        if (cfg.enable_gpio) begin
            if (cfg.gpio_cfg_inst == null) cfg.gpio_cfg_inst = gpio_cfg::type_id::create("gpio_cfg_inst");
            uvm_config_db#(gpio_cfg)::set(this, "gpio_agent_inst", "cfg", cfg.gpio_cfg_inst);
            gpio_agent_inst = gpio_agent::type_id::create("gpio_agent_inst", this);
        end

        v_seqr = neuroedge_virtual_sequencer::type_id::create("v_seqr", this);

        if (cfg.enable_soc_scoreboard) begin
            soc_sb = neuroedge_scoreboard::type_id::create("soc_sb", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect Virtual Sequencer sub-sequencer handles
        if (cfg.enable_lsu_axi   && lsu_axi_agent != null)        v_seqr.lsu_seqr      = lsu_axi_agent.seqr;
        if (cfg.enable_ifu_axi   && ifu_axi_agent != null)        v_seqr.ifu_seqr      = ifu_axi_agent.seqr;
        if (cfg.enable_wb        && wb_agent_inst != null)        v_seqr.wb_seqr       = wb_agent_inst.seqr;
        if (cfg.enable_uart      && uart_agent_inst != null)      v_seqr.uart_seqr     = uart_agent_inst.seqr;
        if (cfg.enable_systolic  && systolic_agent_inst != null)  v_seqr.systolic_seqr = systolic_agent_inst.seqr;
        if (cfg.enable_spi       && spi_flash_agent_inst != null) v_seqr.spi_seqr      = spi_flash_agent_inst.seqr;
        if (cfg.enable_gpio      && gpio_agent_inst != null)      v_seqr.gpio_seqr     = gpio_agent_inst.seqr;

        // Connect Top-Level SoC Scoreboard
        if (cfg.enable_soc_scoreboard && soc_sb != null) begin
            if (cfg.enable_lsu_axi  && lsu_axi_agent != null)        lsu_axi_agent.mon.item_collected_port.connect(soc_sb.lsu_export);
            if (cfg.enable_ifu_axi  && ifu_axi_agent != null)        ifu_axi_agent.mon.item_collected_port.connect(soc_sb.ifu_export);
            if (cfg.enable_wb       && wb_agent_inst != null)        wb_agent_inst.mon.item_collected_port.connect(soc_sb.wb_export);
            if (cfg.enable_uart     && uart_agent_inst != null)      uart_agent_inst.mon.item_collected_port.connect(soc_sb.uart_export);
            if (cfg.enable_systolic && systolic_agent_inst != null)  systolic_agent_inst.mon.item_collected_port.connect(soc_sb.systolic_export);
            if (cfg.enable_gpio     && gpio_agent_inst != null)      gpio_agent_inst.mon.item_collected_port.connect(soc_sb.gpio_export);
        end
    endfunction

endclass

`endif // NEUROEDGE_ENV_SV
