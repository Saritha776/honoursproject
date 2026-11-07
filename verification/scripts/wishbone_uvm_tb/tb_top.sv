module tb_top;
import uvm_pkg::*; import wishbone_pkg::*;
wishbone_if vif();
initial run_test("wishbone_test");
endmodule
