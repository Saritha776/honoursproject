// ==============================================================================
// Class: wb_driver.sv
// Description: Protocol-aware Wishbone Master Driver
// ==============================================================================

`ifndef WB_DRIVER_SV
`define WB_DRIVER_SV

class wb_driver extends uvm_driver #(wb_item);

    virtual wb_if   vif;
    wb_cfg          cfg;

    `uvm_component_utils(wb_driver)

    function new(string name = "wb_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual wb_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"});
        end
    endfunction

    task run_phase(uvm_phase phase);
        reset_bus();
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        forever begin
            seq_item_port.get_next_item(req);
            drive_transaction(req);
            seq_item_port.item_done();
        end
    endtask

    task reset_bus();
        vif.adr   <= '0;
        vif.dat_w <= '0;
        vif.sel   <= '0;
        vif.we    <= 1'b0;
        vif.stb   <= 1'b0;
        vif.cyc   <= 1'b0;
    endtask

    task drive_transaction(wb_item item);
        // Inter-transaction delay
        repeat (item.delay) @(posedge vif.clk);

        @(posedge vif.clk);
        vif.cyc   <= 1'b1;
        vif.stb   <= 1'b1;
        vif.adr   <= item.addr;
        vif.sel   <= item.sel;
        vif.we    <= (item.op == WB_WRITE) ? 1'b1 : 1'b0;
        if (item.op == WB_WRITE) begin
            vif.dat_w <= item.data;
        end else begin
            vif.dat_w <= '0;
        end

        @(posedge vif.clk);
        while (!(vif.ack || vif.err)) begin
            @(posedge vif.clk);
        end

        item.ack = vif.ack;
        item.err = vif.err;
        if (item.op == WB_READ) begin
            item.data = vif.dat_r;
        end

        // Deassert Wishbone strobes synchronously
        vif.cyc   <= 1'b0;
        vif.stb   <= 1'b0;
        vif.we    <= 1'b0;
    endtask

endclass

`endif // WB_DRIVER_SV
