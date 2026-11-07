// ==============================================================================
// Class: spi_flash_driver.sv
// Description: Protocol-aware SPI Flash NOR Slave Model
// ==============================================================================

`ifndef SPI_FLASH_DRIVER_SV
`define SPI_FLASH_DRIVER_SV

class spi_flash_driver extends uvm_driver #(spi_flash_item);

    virtual spi_flash_if vif;
    spi_flash_cfg        cfg;

    // Internal flash storage array
    bit [7:0] flash_mem [bit [23:0]];

    `uvm_component_utils(spi_flash_driver)

    function new(string name = "spi_flash_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_flash_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"});
        end
        init_default_flash_contents();
    endfunction

    function void init_default_flash_contents();
        // Pre-program INT8 4x4 weights at Flash address 0x000000:
        // Row 0: 2, -1, 4, 0 (0x02, 0xFF, 0x04, 0x00)
        flash_mem[24'h000000] = 8'h02;
        flash_mem[24'h000001] = 8'hFF;
        flash_mem[24'h000002] = 8'h04;
        flash_mem[24'h000003] = 8'h00;
        // Row 1: 1, 3, -2, 5 (0x01, 0x03, 0xFE, 0x05)
        flash_mem[24'h000004] = 8'h01;
        flash_mem[24'h000005] = 8'h03;
        flash_mem[24'h000006] = 8'hFE;
        flash_mem[24'h000007] = 8'h05;
        // Row 2: -3, 0, 1, 2 (0xFD, 0x00, 0x01, 0x02)
        flash_mem[24'h000008] = 8'hFD;
        flash_mem[24'h000009] = 8'h00;
        flash_mem[24'h00000A] = 8'h01;
        flash_mem[24'h00000B] = 8'h02;
        // Row 3: 4, -2, 3, -1 (0x04, 0xFE, 0x03, 0xFF)
        flash_mem[24'h00000C] = 8'h04;
        flash_mem[24'h00000D] = 8'hFE;
        flash_mem[24'h00000E] = 8'h03;
        flash_mem[24'h00000F] = 8'hFF;
    endfunction

    task run_phase(uvm_phase phase);
        vif.miso <= 1'b0;

        forever begin
            // Wait for Chip Select assertion (active low)
            @(negedge vif.cs_n);
            respond_to_spi_transaction();
        end
    endtask

    task respond_to_spi_transaction();
        bit [7:0]  cmd = 8'h0;
        bit [23:0] addr = 24'h0;
        bit [7:0]  tx_byte;

        // Sample 8-bit Command on posedge SCLK
        for (int i = 7; i >= 0; i--) begin
            @(posedge vif.sclk or posedge vif.cs_n);
            if (vif.cs_n) return;
            cmd[i] = vif.mosi;
        end

        // Sample 24-bit Address on posedge SCLK
        for (int i = 23; i >= 0; i--) begin
            @(posedge vif.sclk or posedge vif.cs_n);
            if (vif.cs_n) return;
            addr[i] = vif.mosi;
        end

        // If Read Command (0x03), stream data bytes on falling edge of SCLK
        if (cmd == 8'h03) begin
            while (!vif.cs_n) begin
                tx_byte = flash_mem.exists(addr) ? flash_mem[addr] : 8'h00;
                for (int b = 7; b >= 0; b--) begin
                    @(negedge vif.sclk or posedge vif.cs_n);
                    if (vif.cs_n) break;
                    vif.miso <= tx_byte[b];
                end
                addr++;
            end
        end

        vif.miso <= 1'b0;
    endtask

endclass

`endif // SPI_FLASH_DRIVER_SV
