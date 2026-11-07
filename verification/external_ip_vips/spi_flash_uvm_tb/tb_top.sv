module tb_top;
import uvm_pkg::*; import spi_flash_pkg::*;
spi_flash_if vif();
initial run_test("spi_flash_test");
endmodule
