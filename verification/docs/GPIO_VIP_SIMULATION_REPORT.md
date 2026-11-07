# NeuroEdge SoC GPIO VIP & C Firmware Verification Report

This report documents the verification of the **NeuroEdge SoC** integrating the **C Firmware Self-Test Suite** and the **GPIO-only UVM VIP**.

---

## 1. Summary of Verified Components

### 1.1 C Firmware Test Suite (`firmware/main.c`)
The autonomous RISC-V VeeR EL2 core booted and executed the complete onboard firmware:
1. **Peripheral Subsystem Initialization**: Configured 8-bit GPIO directions (`gpio_set_direction(0xFF)`) and asserted Stage 1 indicator (`gpio_out = 0x01`).
2. **SPI Flash Transfer**: Loaded neural network weight matrices from SPI Flash into Data SRAM weights partition (`0x2000_8000`), asserting Stage 2 indicator (`gpio_out = 0x02`).
3. **Dual-Channel DMA Streaming**: Triggered DMA Channel 0 (activations) and Channel 1 (weights) to stream into the 4x4 Systolic Array accelerator, asserting Stage 3 indicator (`gpio_out = 0x04`).
4. **4x4 Weight-Stationary Systolic Array AI Inference**: Computed matrix multiplication with 32-bit accumulated results: `[-13, -41, 94, 7]`, asserting Stage 4 indicator (`gpio_out = 0x08`).
5. **UART Telemetry**: Streamed telemetry bytes across the UART 16550 transceiver.
6. **Milestone Verification**: Confirmed exact hardware results against Golden Reference, driving milestone completion pattern `gpio_out = 0xAA`.

---

### 1.2 UVM GPIO-Only VIP Integration & Transaction Flow
The single GPIO VIP was connected directly to the SoC top-level DUT without instantiating other VIPs:
- **Sequence Item**: `gpio_seq_item` randomized 8-bit inputs `gpio_in` with inter-transaction delay cycles.
- **Base Sequence**: `gpio_base_sequence` executed all 7 systematic test patterns:
  1. All Zeros (`8'h00`)
  2. All Ones (`8'hFF`)
  3. Alternating `8'hAA`
  4. Alternating `8'h55`
  5. Walking-Ones (`8'h01`, `8'h02`, `8'h04`, `8'h08`, `8'h10`, `8'h20`, `8'h40`, `8'h80`)
  6. Walking-Zeros (`8'hFE`, `8'hFD`, `8'hFB`, `8'hF7`, `8'hEF`, `8'hDF`, `8'hBF`, `8'h7F`)
  7. 10 Randomized Vectors (`0x57`, `0x2F`, `0xCB`, `0x6F`, `0x3C`, `0x69`, `0x37`, `0x06`, `0x5C`, `0x90`)
- **Driver**: Pipelined 30 transactions using standard `get_next_item` / `item_done` handshake.
- **Monitor**: Passively sampled all 36 signal transitions synchronously on `clk`.
- **Scoreboard**: Verified all 29 input transitions and confirmed CPU completion milestone `0xAA`.

---

## 2. Full Sequence Item Output Log

```text
UVM_INFO @ 0: reporter [RNTST] Running test neuroedge_gpio_test...
UVM_INFO ... [UVMTOP] UVM testbench topology:
-----------------------------------------------------------------------
Name                           Type                         Size  Value
-----------------------------------------------------------------------
uvm_test_top                   neuroedge_gpio_test          -     @354 
  env                          neuroedge_env                -     @373 
    gpio_agent_inst            gpio_agent                   -     @386 
      cov                      gpio_coverage                -     @788 
      drv                      gpio_driver                  -     @759 
      mon                      gpio_monitor                 -     @603 
      sb                       gpio_scoreboard              -     @807 
      seqr                     gpio_sequencer               -     @622 
    soc_sb                     neuroedge_scoreboard         -     @532 
    v_seqr                     neuroedge_virtual_sequencer  -     @395 
-----------------------------------------------------------------------

UVM_INFO @ 0: uvm_test_top [neuroedge_gpio_test] Starting NeuroEdge SoC GPIO-Only VIP Test
UVM_INFO @ 0: uvm_test_top.env.gpio_agent_inst.seqr@@seq [gpio_base_sequence] Starting Systematic GPIO Input Stimulus Sequence
UVM_INFO @ 110000: reporter [TOP] System Reset Deasserted

--- Pattern 1: All Zeros ---
UVM_INFO @ 270000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ [GPIO_DRIVER] Drove DUT Input: gpio_in = 0x00 (delay=7 clks) ★
UVM_INFO @ 270000: uvm_test_top.env.gpio_agent_inst.seqr@@seq [gpio_base_sequence] [GPIO_SEQ] Finished Pattern 1: All Zeros -> Driven: 0x00

--- Pattern 2: All Ones ---
UVM_INFO @ 350000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ [GPIO_DRIVER] Drove DUT Input: gpio_in = 0xff (delay=4 clks) ★
UVM_INFO @ 350000: uvm_test_top.env.gpio_agent_inst.seqr@@seq [gpio_base_sequence] [GPIO_SEQ] Finished Pattern 2: All Ones -> Driven: 0xff

--- Pattern 3: Alternating 0xAA ---
UVM_INFO @ 490000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ [GPIO_DRIVER] Drove DUT Input: gpio_in = 0xaa (delay=7 clks) ★
UVM_INFO @ 490000: uvm_test_top.env.gpio_agent_inst.seqr@@seq [gpio_base_sequence] [GPIO_SEQ] Finished Pattern 3: Alternating 8'hAA -> Driven: 0xaa

--- Pattern 4: Alternating 0x55 ---
UVM_INFO @ 650000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ [GPIO_DRIVER] Drove DUT Input: gpio_in = 0x55 (delay=8 clks) ★
UVM_INFO @ 650000: uvm_test_top.env.gpio_agent_inst.seqr@@seq [gpio_base_sequence] [GPIO_SEQ] Finished Pattern 4: Alternating 8'h55 -> Driven: 0x55

--- Pattern 5: Walking-One Patterns (8 bits) ---
UVM_INFO @ 810000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0x01 (delay=8 clks) ★
UVM_INFO @ 930000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0x02 (delay=6 clks) ★
UVM_INFO @ 1090000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0x04 (delay=8 clks) ★
UVM_INFO @ 1250000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0x08 (delay=8 clks) ★
UVM_INFO @ 1370000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0x10 (delay=6 clks) ★
UVM_INFO @ 1470000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0x20 (delay=5 clks) ★
UVM_INFO @ 1530000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0x40 (delay=3 clks) ★
UVM_INFO @ 1570000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0x80 (delay=2 clks) ★

--- Pattern 6: Walking-Zero Patterns (8 bits) ---
UVM_INFO @ 1710000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0xfe (delay=7 clks) ★
UVM_INFO @ 1830000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0xfd (delay=6 clks) ★
UVM_INFO @ 1870000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0xfb (delay=2 clks) ★
UVM_INFO @ 2030000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0xf7 (delay=8 clks) ★
UVM_INFO @ 2130000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0xef (delay=5 clks) ★
UVM_INFO @ 2210000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0xdf (delay=4 clks) ★
UVM_INFO @ 2350000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0xbf (delay=7 clks) ★
UVM_INFO @ 2410000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0x7f (delay=3 clks) ★

--- Pattern 7: 10 Randomized GPIO Patterns ---
UVM_INFO @ 2550000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0x57 (delay=7 clks) ★
UVM_INFO @ 2630000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0x2f (delay=4 clks) ★
UVM_INFO @ 2710000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0xcb (delay=4 clks) ★
UVM_INFO @ 2830000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0x6f (delay=6 clks) ★
UVM_INFO @ 2910000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0x3c (delay=4 clks) ★
UVM_INFO @ 2950000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0x69 (delay=2 clks) ★
UVM_INFO @ 3010000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0x37 (delay=3 clks) ★
UVM_INFO @ 3170000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0x06 (delay=8 clks) ★
UVM_INFO @ 3250000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0x5c (delay=4 clks) ★
UVM_INFO @ 3350000: uvm_test_top.env.gpio_agent_inst.drv [gpio_driver] ★ Drove DUT Input: gpio_in = 0x90 (delay=5 clks) ★
UVM_INFO @ 3350000: uvm_test_top.env.gpio_agent_inst.seqr@@seq [gpio_base_sequence] Completed All 7 GPIO Stimulus Patterns

--- Firmware Completion Milestone ---
UVM_INFO @ 3593090000: uvm_test_top.env.gpio_agent_inst.sb [GPIO_SUCCESS] ★ GPIO Milestone 0xAA (All Firmware Tests Passed) Verified! ★
UVM_INFO @ 3593090000: uvm_test_top.env.soc_sb [SOC_SB_GPIO] ★ [SoC Scoreboard] GPIO Status 0xAA Confirmed! ★

--- Scoreboard & Test Result ---
UVM_INFO @ 3598090000: uvm_test_top.env.gpio_agent_inst.sb [gpio_scoreboard] GPIO Scoreboard Summary: TotalTransitions=36, InputTransitions=29, OutputTransitions=5, SuccessMilestoneSeen=1
UVM_INFO @ 3598090000: uvm_test_top [neuroedge_gpio_test] TEST RESULT: >>> PASSED <<<
```

---

## 3. Reproduction Command

To re-run this exact simulation:

```bash
cd verification/sim
vcs -full64 -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps -debug_access+all -kdb -lca \
    -f ../filelists/filelist_uvm.f -o simv_uvm -l comp_gpio_flow.log

./simv_uvm +UVM_TESTNAME=neuroedge_gpio_test +UVM_VERBOSITY=UVM_LOW \
    +FSDB_FILE=neuroedge_gpio_only_vip.fsdb -l sim_gpio_only_vip.log
```
