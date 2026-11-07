# ==============================================================================
# Filelist: filelist_uvm.f
# Project: NeuroEdge SoC UVM Verification Environment
# Target: Synopsys VCS U-2023.03 with UVM 1.2
# ==============================================================================

+define+RV_OPENSOURCE

+incdir+/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/snapshots/default
+incdir+/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/include
+incdir+/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/testbench

+incdir+/home/student/Documents/honoursproject/honoursproject/verification/uvm_vips/axi4_vip
+incdir+/home/student/Documents/honoursproject/honoursproject/verification/uvm_vips/wishbone_vip
+incdir+/home/student/Documents/honoursproject/honoursproject/verification/uvm_vips/uart_vip
+incdir+/home/student/Documents/honoursproject/honoursproject/verification/uvm_vips/systolic_vip
+incdir+/home/student/Documents/honoursproject/honoursproject/verification/uvm_vips/spi_flash_vip
+incdir+/home/student/Documents/honoursproject/honoursproject/verification/uvm_vips/gpio_vip
+incdir+/home/student/Documents/honoursproject/honoursproject/verification/uvm_env
+incdir+/home/student/Documents/honoursproject/honoursproject/verification/sequences
+incdir+/home/student/Documents/honoursproject/honoursproject/verification/tests

# VeeR EL2 RISC-V Core Packages & Definitions
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/include/el2_def.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/lib/el2_assert.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/el2_mubi_pkg.sv

# VeeR EL2 Pipeline Modules
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/testbench/veer_wrapper.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/el2_veer_wrapper.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/el2_mem.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/el2_pic_ctrl.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/el2_veer.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/el2_dma_ctrl.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/el2_pmp.sv

/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/ifu/el2_ifu_aln_ctl.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/ifu/el2_ifu_compress_ctl.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/ifu/el2_ifu_ifc_ctl.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/ifu/el2_ifu_bp_ctl.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/ifu/el2_ifu_ic_mem.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/ifu/el2_ifu_mem_ctl.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/ifu/el2_ifu_iccm_mem.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/ifu/el2_ifu.sv

/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/dec/el2_dec_decode_ctl.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/dec/el2_dec_gpr_ctl.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/dec/el2_dec_ib_ctl.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/dec/el2_dec_pmp_ctl.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/dec/el2_dec_tlu_ctl.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/dec/el2_dec_trigger.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/dec/el2_dec.sv

/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/exu/el2_exu_alu_ctl.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/exu/el2_exu_mul_ctl.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/exu/el2_exu_div_ctl.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/exu/el2_exu.sv

/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/lsu/el2_lsu.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/lsu/el2_lsu_clkdomain.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/lsu/el2_lsu_addrcheck.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/lsu/el2_lsu_lsc_ctl.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/lsu/el2_lsu_stbuf.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/lsu/el2_lsu_bus_buffer.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/lsu/el2_lsu_bus_intf.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/lsu/el2_lsu_ecc.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/lsu/el2_lsu_dccm_mem.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/lsu/el2_lsu_dccm_ctl.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/lsu/el2_lsu_trigger.sv

/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/dbg/el2_dbg.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/dmi/dmi_mux.v
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/dmi/dmi_wrapper.v
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/dmi/dmi_jtag_to_core_sync.v
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/dmi/rvjtag_tap.v
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/lib/el2_lib.sv
/home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/lib/el2_mem_if.sv

-v /home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/lib/beh_lib.sv
-v /home/student/Documents/honoursproject/honoursproject/Cores-VeeR-EL2-main/design/lib/mem_lib.sv

# NeuroEdge SoC Peripherals & Interconnect
/home/student/Documents/honoursproject/honoursproject/rtl/pe.sv
/home/student/Documents/honoursproject/honoursproject/rtl/systolic_array_4x4.sv
/home/student/Documents/honoursproject/honoursproject/rtl/dma_controller.sv
/home/student/Documents/honoursproject/honoursproject/rtl/spi_flash_ctrl.sv
/home/student/Documents/honoursproject/honoursproject/rtl/uart_16550.sv
/home/student/Documents/honoursproject/honoursproject/rtl/timer_32bit.sv
/home/student/Documents/honoursproject/honoursproject/rtl/watchdog_timer.sv
/home/student/Documents/honoursproject/honoursproject/rtl/gpio_8bit.sv
/home/student/Documents/honoursproject/honoursproject/rtl/pic_controller.sv
/home/student/Documents/honoursproject/honoursproject/rtl/sram_sp_32k.sv
/home/student/Documents/honoursproject/honoursproject/rtl/sram_dp_64k.sv
/home/student/Documents/honoursproject/honoursproject/rtl/soc_interconnect.sv
/home/student/Documents/honoursproject/honoursproject/rtl/axi4_to_wishbone.sv
/home/student/Documents/honoursproject/honoursproject/rtl/neuroedge_soc_top.sv

# UVM VIP Interfaces & Packages
/home/student/Documents/honoursproject/honoursproject/verification/uvm_vips/axi4_vip/axi4_if.sv
/home/student/Documents/honoursproject/honoursproject/verification/uvm_vips/axi4_vip/axi4_pkg.sv
/home/student/Documents/honoursproject/honoursproject/verification/uvm_vips/wishbone_vip/wb_if.sv
/home/student/Documents/honoursproject/honoursproject/verification/uvm_vips/wishbone_vip/wb_pkg.sv
/home/student/Documents/honoursproject/honoursproject/verification/uvm_vips/uart_vip/uart_if.sv
/home/student/Documents/honoursproject/honoursproject/verification/uvm_vips/uart_vip/uart_pkg.sv
/home/student/Documents/honoursproject/honoursproject/verification/uvm_vips/systolic_vip/systolic_if.sv
/home/student/Documents/honoursproject/honoursproject/verification/uvm_vips/systolic_vip/systolic_pkg.sv
/home/student/Documents/honoursproject/honoursproject/verification/uvm_vips/spi_flash_vip/spi_flash_if.sv
/home/student/Documents/honoursproject/honoursproject/verification/uvm_vips/spi_flash_vip/spi_flash_pkg.sv
/home/student/Documents/honoursproject/honoursproject/verification/uvm_vips/gpio_vip/gpio_if.sv
/home/student/Documents/honoursproject/honoursproject/verification/uvm_vips/gpio_vip/gpio_pkg.sv

# Top-Level UVM Packages
/home/student/Documents/honoursproject/honoursproject/verification/uvm_env/neuroedge_uvm_pkg.sv
/home/student/Documents/honoursproject/honoursproject/verification/sequences/neuroedge_seq_pkg.sv
/home/student/Documents/honoursproject/honoursproject/verification/tests/neuroedge_test_pkg.sv

# Top-Level Testbench
/home/student/Documents/honoursproject/honoursproject/verification/tb_neuroedge_uvm_top.sv
