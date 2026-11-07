// ==============================================================================
// Class: spi_flash_coverage.sv
// Description: Functional coverage collector for SPI Flash VIP
// ==============================================================================

`ifndef SPI_FLASH_COVERAGE_SV
`define SPI_FLASH_COVERAGE_SV

class spi_flash_coverage extends uvm_subscriber #(spi_flash_item);

    `uvm_component_utils(spi_flash_coverage)

    spi_flash_item item_cov;

    covergroup cg_spi_flash;
        cp_cmd: coverpoint item_cov.cmd {
            bins READ_DATA = {8'h03};
            bins OTHER_CMD = default;
        }

        cp_len: coverpoint item_cov.data.size() {
            bins SINGLE_BYTE = {1};
            bins WORD        = {4};
            bins MATRIX_16B  = {16};
            bins OTHER_LEN   = default;
        }

        cp_addr: coverpoint item_cov.addr {
            bins BASE_ZERO = {24'h000000};
            bins HIGHER    = {[24'h000001 : 24'hFFFFFF]};
        }
    endgroup

    function new(string name = "spi_flash_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_spi_flash = new();
    endfunction

    function void write(spi_flash_item t);
        item_cov = t;
        cg_spi_flash.sample();
    endfunction

    function real get_coverage_pct();
        return cg_spi_flash.get_coverage();
    endfunction

endclass

`endif // SPI_FLASH_COVERAGE_SV
