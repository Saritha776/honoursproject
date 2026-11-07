// ==============================================================================
// Interface: spi_flash_if.sv
// Description: SPI Flash physical interface and assertions
// ==============================================================================

interface spi_flash_if (
    input logic clk,
    input logic rst_n
);

    logic sclk;
    logic mosi;
    logic miso;
    logic cs_n;

    // Assertions
    property p_spi_cs_known;
        @(posedge clk) disable iff (!rst_n)
        $isunknown(cs_n) == 0;
    endproperty
    assert_spi_cs_known: assert property (p_spi_cs_known)
        else $error("[SPI_FLASH_IF] SPI CS_N contains unknown state");

endinterface
