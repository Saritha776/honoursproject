# ==============================================================================
# Filelist: filelist.f
# Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
# Target: Synopsys VCS
# ==============================================================================

+define+RV_OPENSOURCE

+incdir+../Cores-VeeR-EL2-main/snapshots/default
+incdir+../Cores-VeeR-EL2-main/design/include
+incdir+../Cores-VeeR-EL2-main/testbench

# VeeR EL2 RISC-V Core Packages & Definitions
../Cores-VeeR-EL2-main/design/include/el2_def.sv
../Cores-VeeR-EL2-main/design/lib/el2_assert.sv
../Cores-VeeR-EL2-main/design/el2_mubi_pkg.sv

# VeeR EL2 Pipeline Modules
../Cores-VeeR-EL2-main/testbench/veer_wrapper.sv
../Cores-VeeR-EL2-main/design/el2_veer_wrapper.sv
../Cores-VeeR-EL2-main/design/el2_mem.sv
../Cores-VeeR-EL2-main/design/el2_pic_ctrl.sv
../Cores-VeeR-EL2-main/design/el2_veer.sv
../Cores-VeeR-EL2-main/design/el2_dma_ctrl.sv
../Cores-VeeR-EL2-main/design/el2_pmp.sv

../Cores-VeeR-EL2-main/design/ifu/el2_ifu_aln_ctl.sv
../Cores-VeeR-EL2-main/design/ifu/el2_ifu_compress_ctl.sv
../Cores-VeeR-EL2-main/design/ifu/el2_ifu_ifc_ctl.sv
../Cores-VeeR-EL2-main/design/ifu/el2_ifu_bp_ctl.sv
../Cores-VeeR-EL2-main/design/ifu/el2_ifu_ic_mem.sv
../Cores-VeeR-EL2-main/design/ifu/el2_ifu_mem_ctl.sv
../Cores-VeeR-EL2-main/design/ifu/el2_ifu_iccm_mem.sv
../Cores-VeeR-EL2-main/design/ifu/el2_ifu.sv

../Cores-VeeR-EL2-main/design/dec/el2_dec_decode_ctl.sv
../Cores-VeeR-EL2-main/design/dec/el2_dec_gpr_ctl.sv
../Cores-VeeR-EL2-main/design/dec/el2_dec_ib_ctl.sv
../Cores-VeeR-EL2-main/design/dec/el2_dec_pmp_ctl.sv
../Cores-VeeR-EL2-main/design/dec/el2_dec_tlu_ctl.sv
../Cores-VeeR-EL2-main/design/dec/el2_dec_trigger.sv
../Cores-VeeR-EL2-main/design/dec/el2_dec.sv

../Cores-VeeR-EL2-main/design/exu/el2_exu_alu_ctl.sv
../Cores-VeeR-EL2-main/design/exu/el2_exu_mul_ctl.sv
../Cores-VeeR-EL2-main/design/exu/el2_exu_div_ctl.sv
../Cores-VeeR-EL2-main/design/exu/el2_exu.sv

../Cores-VeeR-EL2-main/design/lsu/el2_lsu.sv
../Cores-VeeR-EL2-main/design/lsu/el2_lsu_clkdomain.sv
../Cores-VeeR-EL2-main/design/lsu/el2_lsu_addrcheck.sv
../Cores-VeeR-EL2-main/design/lsu/el2_lsu_lsc_ctl.sv
../Cores-VeeR-EL2-main/design/lsu/el2_lsu_stbuf.sv
../Cores-VeeR-EL2-main/design/lsu/el2_lsu_bus_buffer.sv
../Cores-VeeR-EL2-main/design/lsu/el2_lsu_bus_intf.sv
../Cores-VeeR-EL2-main/design/lsu/el2_lsu_ecc.sv
../Cores-VeeR-EL2-main/design/lsu/el2_lsu_dccm_mem.sv
../Cores-VeeR-EL2-main/design/lsu/el2_lsu_dccm_ctl.sv
../Cores-VeeR-EL2-main/design/lsu/el2_lsu_trigger.sv

../Cores-VeeR-EL2-main/design/dbg/el2_dbg.sv
../Cores-VeeR-EL2-main/design/dmi/dmi_mux.v
../Cores-VeeR-EL2-main/design/dmi/dmi_wrapper.v
../Cores-VeeR-EL2-main/design/dmi/dmi_jtag_to_core_sync.v
../Cores-VeeR-EL2-main/design/dmi/rvjtag_tap.v
../Cores-VeeR-EL2-main/design/lib/el2_lib.sv
../Cores-VeeR-EL2-main/design/lib/el2_mem_if.sv

-v ../Cores-VeeR-EL2-main/design/lib/beh_lib.sv
-v ../Cores-VeeR-EL2-main/design/lib/mem_lib.sv

# NeuroEdge SoC Peripherals & Interconnect
../rtl/pe.sv
../rtl/systolic_array_4x4.sv
../rtl/dma_controller.sv
../rtl/spi_flash_ctrl.sv
../rtl/uart_16550.sv
../rtl/timer_32bit.sv
../rtl/watchdog_timer.sv
../rtl/gpio_8bit.sv
../rtl/pic_controller.sv
../rtl/sram_sp_32k.sv
../rtl/sram_dp_64k.sv
../rtl/soc_interconnect.sv
../rtl/axi4_to_wishbone.sv
../rtl/neuroedge_soc_top.sv

# System Testbench
../tb/tb_neuroedge_soc.sv
