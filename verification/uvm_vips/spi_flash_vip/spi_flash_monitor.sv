// ==============================================================================
// Class: spi_flash_monitor.sv
// Description: Protocol monitor for SPI Flash bus
// ==============================================================================

`ifndef SPI_FLASH_MONITOR_SV
`define SPI_FLASH_MONITOR_SV

class spi_flash_monitor extends uvm_monitor;

    virtual spi_flash_if vif;
    spi_flash_cfg        cfg;

    uvm_analysis_port #(spi_flash_item) item_collected_port;

    `uvm_component_utils(spi_flash_monitor)

    function new(string name = "spi_flash_monitor", uvm_component parent = null);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_flash_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"});
        end
    endfunction

    task run_phase(uvm_phase phase);
        spi_flash_item item;
        bit [7:0] cmd;
        bit [23:0] addr;
        bit [7:0] byte_q[$];
        bit [7:0] current_byte;

        forever begin
            @(negedge vif.cs_n);
            byte_q.delete();

            // Sample 8-bit Command
            for (int i = 7; i >= 0; i--) begin
                @(posedge vif.sclk or posedge vif.cs_n);
                if (vif.cs_n) break;
                cmd[i] = vif.mosi;
            end
            if (vif.cs_n) continue;

            // Sample 24-bit Address
            for (int i = 23; i >= 0; i--) begin
                @(posedge vif.sclk or posedge vif.cs_n);
                if (vif.cs_n) break;
                addr[i] = vif.mosi;
            end
            if (vif.cs_n) continue;

            // Sample read payload bytes
            while (!vif.cs_n) begin
                current_byte = 8'h0;
                for (int b = 7; b >= 0; b--) begin
                    @(posedge vif.sclk or posedge vif.cs_n);
                    if (vif.cs_n) break;
                    current_byte[b] = vif.miso;
                end
                if (!vif.cs_n) byte_q.push_back(current_byte);
            end

            item = spi_flash_item::type_id::create("mon_spi_item");
            item.cmd  = cmd;
            item.addr = addr;
            item.data = new[byte_q.size()];
            foreach (byte_q[i]) item.data[i] = byte_q[i];

            `uvm_info(get_type_name(), $sformatf("Monitored: %s", item.convert2string()), UVM_HIGH)
            item_collected_port.write(item);
        end
    endtask

endclass

`endif // SPI_FLASH_MONITOR_SV
