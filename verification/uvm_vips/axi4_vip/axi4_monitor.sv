// ==============================================================================
// Class: axi4_monitor.sv
// Description: Functional monitor for AXI4 Read and Write channels
// ==============================================================================

`ifndef AXI4_MONITOR_SV
`define AXI4_MONITOR_SV

class axi4_monitor extends uvm_monitor;

    virtual axi4_if vif;
    axi4_cfg        cfg;

    uvm_analysis_port #(axi4_item) item_collected_port;

    `uvm_component_utils(axi4_monitor)

    function new(string name = "axi4_monitor", uvm_component parent = null);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi4_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"});
        end
    endfunction

    task run_phase(uvm_phase phase);
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        fork
            monitor_writes();
            monitor_reads();
        join
    endtask

    task monitor_writes();
        axi4_item item;
        forever begin
            // Wait for Address Write Handshake
            do begin
                @(posedge vif.clk);
            end while (!(vif.awvalid && vif.awready && vif.rst_n));

            item = axi4_item::type_id::create("mon_axi4_write");
            item.xfer_type = AXI_WRITE;
            item.id        = vif.awid;
            item.addr      = vif.awaddr;
            item.len       = vif.awlen;
            item.size      = vif.awsize;
            item.burst     = axi_burst_e'(vif.awburst);

            item.data = new[item.len + 1];
            item.strb = new[item.len + 1];

            // Collect Write Beats
            for (int i = 0; i <= item.len; i++) begin
                do begin
                    @(posedge vif.clk);
                end while (!(vif.wvalid && vif.wready && vif.rst_n));
                item.data[i] = vif.wdata;
                item.strb[i] = vif.wstrb;
            end

            // Collect Response
            do begin
                @(posedge vif.clk);
            end while (!(vif.bvalid && vif.bready && vif.rst_n));
            item.bresp = vif.bresp;

            `uvm_info(get_type_name(), $sformatf("Monitored Write: %s", item.convert2string()), UVM_HIGH)
            item_collected_port.write(item);
        end
    endtask

    task monitor_reads();
        axi4_item item;
        forever begin
            // Wait for Address Read Handshake
            do begin
                @(posedge vif.clk);
            end while (!(vif.arvalid && vif.arready && vif.rst_n));

            item = axi4_item::type_id::create("mon_axi4_read");
            item.xfer_type = AXI_READ;
            item.id        = vif.arid;
            item.addr      = vif.araddr;
            item.len       = vif.arlen;
            item.size      = vif.arsize;
            item.burst     = axi_burst_e'(vif.arburst);

            item.data = new[item.len + 1];
            item.resp = new[item.len + 1];

            // Collect Read Beats
            for (int i = 0; i <= item.len; i++) begin
                do begin
                    @(posedge vif.clk);
                end while (!(vif.rvalid && vif.rready && vif.rst_n));
                item.data[i] = vif.rdata;
                item.resp[i] = axi_resp_e'(vif.rresp);
            end

            `uvm_info(get_type_name(), $sformatf("Monitored Read: %s", item.convert2string()), UVM_HIGH)
            item_collected_port.write(item);
        end
    endtask

endclass

`endif // AXI4_MONITOR_SV
