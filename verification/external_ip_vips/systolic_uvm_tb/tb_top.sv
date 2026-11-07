module tb_top;
import uvm_pkg::*; import systolic_pkg::*;
systolic_if vif();
initial run_test("systolic_test");
endmodule
