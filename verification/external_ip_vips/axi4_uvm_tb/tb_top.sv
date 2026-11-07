module tb_top;
import uvm_pkg::*; import axi4_pkg::*;
axi4_if vif();
initial run_test("axi4_test");
endmodule
