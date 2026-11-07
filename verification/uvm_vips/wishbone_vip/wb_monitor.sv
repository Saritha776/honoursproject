// ==============================================================================
// Class: wb_monitor.sv
// Description: Wishbone Bus Monitor capturing transactions on ACK/ERR
// ==============================================================================

`ifndef WB_MONITOR_SV
`define WB_MONITOR_SV

class wb_monitor extends uvm_monitor;

    virtual wb_if   vif;
    wb_cfg          cfg;

    uvm_analysis_port #(wb_item) item_collected_port;

    `uvm_component_utils(wb_monitor)

    function new(string name = "wb_monitor", uvm_component parent = null);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual wb_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"});
        end
    endfunction

    task run_phase(uvm_phase phase);
        wb_item item;
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        forever begin
            @(posedge vif.clk);
            if (vif.rst_n && vif.cyc && vif.stb && (vif.ack || vif.err)) begin
                item = wb_item::type_id::create("mon_wb_item");
                item.op   = vif.we ? WB_WRITE : WB_READ;
                item.addr = vif.adr;
                item.data = vif.we ? vif.dat_w : vif.dat_r;
                item.sel  = vif.sel;
                item.ack  = vif.ack;
                item.err  = vif.err;

                `uvm_info(get_type_name(), $sformatf("Monitored: %s", item.convert2string()), UVM_HIGH)
                item_collected_port.write(item);
            end
        end
    endtask

endclass

`endif // WB_MONITOR_SV
