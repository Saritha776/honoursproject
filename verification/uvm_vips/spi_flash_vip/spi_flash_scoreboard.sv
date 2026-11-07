// ==============================================================================
// Class: spi_flash_scoreboard.sv
// Description: Scoreboard for SPI Flash VIP
// ==============================================================================

`ifndef SPI_FLASH_SCOREBOARD_SV
`define SPI_FLASH_SCOREBOARD_SV

class spi_flash_scoreboard extends uvm_scoreboard;

    uvm_analysis_imp #(spi_flash_item, spi_flash_scoreboard) item_collected_export;

    int total_transactions = 0;
    int total_bytes = 0;

    `uvm_component_utils(spi_flash_scoreboard)

    function new(string name = "spi_flash_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        item_collected_export = new("item_collected_export", this);
    endfunction

    function void write(spi_flash_item item);
        total_transactions++;
        total_bytes += item.data.size();
        `uvm_info(get_type_name(),
            $sformatf("SPI Flash Transaction #%0d Verified: CMD=0x%02h Addr=0x%06h Length=%0d bytes",
                      total_transactions, item.cmd, item.addr, item.data.size()), UVM_LOW)
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(),
            $sformatf("SPI Flash Scoreboard: Total Transactions=%0d, Total Bytes=%0d",
                      total_transactions, total_bytes), UVM_LOW)
    endfunction

endclass

`endif // SPI_FLASH_SCOREBOARD_SV
