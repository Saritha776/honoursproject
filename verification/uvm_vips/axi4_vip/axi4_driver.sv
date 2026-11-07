// ==============================================================================
// Class: axi4_driver.sv
// Description: Protocol-aware AXI4 Driver supporting Master read/write channels
// ==============================================================================

`ifndef AXI4_DRIVER_SV
`define AXI4_DRIVER_SV

class axi4_driver extends uvm_driver #(axi4_item);

    virtual axi4_if vif;
    axi4_cfg        cfg;

    `uvm_component_utils(axi4_driver)

    function new(string name = "axi4_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi4_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"});
        end
    endfunction

    task run_phase(uvm_phase phase);
        reset_signals();
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        forever begin
            seq_item_port.get_next_item(req);
            if (req.xfer_type == AXI_WRITE) begin
                drive_write(req);
            end else begin
                drive_read(req);
            end
            seq_item_port.item_done();
        end
    endtask

    task reset_signals();
        vif.awid    <= '0;
        vif.awaddr  <= '0;
        vif.awlen   <= '0;
        vif.awsize  <= '0;
        vif.awburst <= '0;
        vif.awvalid <= 1'b0;

        vif.wdata   <= '0;
        vif.wstrb   <= '0;
        vif.wlast   <= 1'b0;
        vif.wvalid  <= 1'b0;

        vif.bready  <= 1'b0;

        vif.arid    <= '0;
        vif.araddr  <= '0;
        vif.arlen   <= '0;
        vif.arsize  <= '0;
        vif.arburst <= '0;
        vif.arvalid <= 1'b0;

        vif.rready  <= 1'b0;
    endtask

    task drive_write(axi4_item item);
        fork
            // Thread 1: Drive Address Write (AW)
            begin
                @(posedge vif.clk);
                vif.awid    <= item.id;
                vif.awaddr  <= item.addr;
                vif.awlen   <= item.len;
                vif.awsize  <= item.size;
                vif.awburst <= item.burst;
                vif.awvalid <= 1'b1;

                do begin
                    @(posedge vif.clk);
                end while (!vif.awready);
                vif.awvalid <= 1'b0;
            end

            // Thread 2: Drive Write Data Beats (W)
            begin
                for (int i = 0; i <= item.len; i++) begin
                    @(posedge vif.clk);
                    vif.wdata  <= item.data[i];
                    vif.wstrb  <= item.strb[i];
                    vif.wlast  <= (i == item.len) ? 1'b1 : 1'b0;
                    vif.wvalid <= 1'b1;

                    do begin
                        @(posedge vif.clk);
                    end while (!vif.wready);
                end
                vif.wvalid <= 1'b0;
                vif.wlast  <= 1'b0;
            end
        join

        // Thread 3: Receive Write Response (B)
        vif.bready <= 1'b1;
        do begin
            @(posedge vif.clk);
        end while (!vif.bvalid);
        item.bresp = vif.bresp;
        vif.bready <= 1'b0;
    endtask

    task drive_read(axi4_item item);
        // Step 1: Drive Read Address Channel (AR)
        @(posedge vif.clk);
        vif.arid    <= item.id;
        vif.araddr  <= item.addr;
        vif.arlen   <= item.len;
        vif.arsize  <= item.size;
        vif.arburst <= item.burst;
        vif.arvalid <= 1'b1;

        do begin
            @(posedge vif.clk);
        end while (!vif.arready);
        vif.arvalid <= 1'b0;

        // Step 2: Receive Read Data Channel Beats (R)
        item.data = new[item.len + 1];
        item.resp = new[item.len + 1];
        vif.rready <= 1'b1;

        for (int i = 0; i <= item.len; i++) begin
            do begin
                @(posedge vif.clk);
            end while (!vif.rvalid);
            item.data[i] = vif.rdata;
            item.resp[i] = axi_resp_e'(vif.rresp);
        end
        vif.rready <= 1'b0;
    endtask

endclass

`endif // AXI4_DRIVER_SV
