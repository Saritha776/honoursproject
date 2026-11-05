# NeuroEdge: RISC-V SoC with Systolic-Array AI Acceleration

NeuroEdge is a 32-bit RISC-V System-on-Chip (SoC) designed for edge neural-network inference. It integrates a **VeeR EL2 (RV32IMC)** core with a 2D **4×4 Weight-Stationary Systolic Array Accelerator**, **Dual-Channel DMA**, **SPI Flash Master**, **16550 UART**, **Timer**, **Watchdog**, **GPIO**, and a **Platform Interrupt Controller (PIC)**.

---

## 🚀 Quickstart: Running in Synopsys VCS & Verdi on Linux

No zip files needed! Simply clone and run directly on your college Linux workstation:

### Step 1: Clone Repository
```bash
git clone https://github.com/Saritha776/honoursproject.git
cd honoursproject
```

---

### Step 2: Load EDA Tool Environment
Depending on your college lab setup, load VCS and Verdi:
```bash
module load vcs
module load verdi
```
*(Or source your lab's Synopsys license script: e.g., `source /tools/synopsys/env.sh`).*

---

### Step 3: Run the Simulation (1-Click Automated)
```bash
cd sim
chmod +x run_sim_vcs.sh
./run_sim_vcs.sh
```
This automatically compiles the SystemVerilog RTL, runs the testbench, dumps the **FSDB** waveform, and launches **Verdi**!

---

### Step 4: (Alternative) Run Step-by-Step Manually

#### 1. Compile with Synopsys VCS
```bash
cd sim
vcs -full64 \
    -sverilog \
    -kdb \
    -debug_access+all \
    -lca \
    -timescale=1ns/1ps \
    +define+DUMP_FSDB \
    -f ../tb/filelist.f \
    -top tb_neuroedge_soc \
    -l vcs_compile.log
```

#### 2. Run Simulation Executable (`simv`)
```bash
./simv -l vcs_sim.log
```

You will see:
```
=======================================================
   COMPUTATION NUMERICAL VERIFICATION SUMMARY          
=======================================================
 Col 0 Result: -13 | Expected: -13
 Col 1 Result: -41 | Expected: -41
 Col 2 Result:  94 | Expected:  94
 Col 3 Result:   7 | Expected:   7

>>> [100% NUMERICAL MATCH CONFIRMED] <<<

[PASS] GPIO Status matches success diagnostic pattern 0xAA.
=======================================================
   FINAL RESULT: 6 / 6 TEST CHECKS PASSED           
=======================================================
```

#### 3. Open Waveforms in Synopsys Verdi
```bash
verdi -ssf neuroedge_sim.fsdb -simv simv &
```

---

## 🔍 Key Signals to Trace in Verdi
* **Systolic 32-bit Results:** `tb_neuroedge_soc.dut.u_systolic_array.res_reg[3:0]`
* **PE Mesh Partial Sums:** `tb_neuroedge_soc.dut.u_systolic_array.pe_psum_v[4:0][3:0]`
* **DMA Streaming Handshake:** `tb_neuroedge_soc.dut.u_dma.dma_act_valid`, `dma_wgt_valid`
* **Bus Crossbar Transactions:** `tb_neuroedge_soc.dut.u_interconnect.grant`, `active_ack`
* **Watchdog Heartbeat:** `tb_neuroedge_soc.dut.u_wdt.wdt_reset_out`, `wdt_irq`
* **UART Telemetry Output:** `tb_neuroedge_soc.dut.u_uart.uart_tx`

---

## 💻 Compiling the Bare-Metal C Test Firmware
To build the C test firmware for the RISC-V target using `riscv32-unknown-elf-gcc`:
```bash
cd firmware
make
```
This generates:
* `neuroedge_test.elf` — Target binary with symbol table.
* `neuroedge_test.hex` — 32-bit words for `$readmemh` instruction memory loading.

To run the standalone C test on the host CPU using standard GCC:
```bash
cd firmware
gcc -O2 -Wall -I. test_neural_ops_host.c neural_ops.c -o test_host
./test_host
```
