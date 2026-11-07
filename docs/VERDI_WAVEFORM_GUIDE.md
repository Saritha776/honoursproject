# Synopsys Verdi Waveform Inspection & Debugging Guide

**Project:** NeuroEdge RISC-V SoC with Systolic Array AI Accelerator  
**Simulator / Viewer:** Synopsys VCS U-2023.03 & Verdi U-2023.03-SP1  
**Waveform Format:** Fast Signal Database (FSDB)  

---

## 1. Quick Launch Commands

To open the pre-generated FSDB waveforms in Synopsys Verdi:

### Mode A: Open UVM Regression Simulation Waveform
```bash
make wave-uvm
# Or manually:
verdi -ssf verification/sim/neuroedge_uvm_sim.fsdb &
```

### Mode B: Open Non-UVM Firmware Execution Waveform
```bash
make wave-sim
# Or manually:
verdi -ssf sim/neuroedge_sim.fsdb -simv sim/simv &
```

---

## 2. Key Signal Hierarchies & What to Observe

### 2.1 4×4 Systolic Array Accelerator
* **Location:** `tb_neuroedge_soc.dut.u_systolic_array` (or `tb_neuroedge_uvm_top.dut.u_systolic_array`)
* **Signals to Add:**
  * `clk`: System clock (50 MHz).
  * `rst_n`: Active-low synchronous reset.
  * `acc_enable`: Compute array enable line.
  * `pe_weight[3:0][3:0]`: 16 local stationary INT8 weights inside each processing element.
  * `pe_act_h[3:0][4:0]`: Horizontal activation streaming from west to east across columns.
  * `pe_psum_v[4:0][3:0]`: Vertical partial sum accumulation from north to south across rows.
  * `res_reg[3:0]`: 32-bit latched column dot product outputs:
    - `res_reg[0]` = `-13` (`0xFFFF_FFF3`)
    - `res_reg[1]` = `-41` (`0xFFFF_FFD7`)
    - `res_reg[2]` = `94` (`0x0000_005E`)
    - `res_reg[3]` = `7` (`0x0000_0007`)
  * `array_irq`: Hardware completion interrupt pulsed to Platform Interrupt Controller.

---

### 2.2 Dual-Channel DMA Streaming Controller
* **Location:** `tb_neuroedge_soc.dut.u_dma`
* **Signals to Add:**
  * `dma_act_valid`: Handshake valid strobe from Channel 0 to systolic western boundary.
  * `dma_act_ready`: Systolic array ready strobe accepting activation stream.
  * `dma_act_data[31:0]`: Packed 4×INT8 activation vector `[10, -5, 20, 8]`.
  * `dma_wgt_valid`: Handshake valid strobe from Channel 1 preloading stationary weights.
  * `dma_wgt_ready`: PE mesh ready strobe accepting weight parameters.
  * `dma_irq`: Interrupt asserting completion of DMA streaming transfers.

---

### 2.3 Wishbone B4 Crossbar Interconnect & Timeout Guard
* **Location:** `tb_neuroedge_soc.dut.u_interconnect`
* **Signals to Add:**
  * `cpu_wb_cyc_i`, `cpu_wb_stb_i`: CPU / VIP Master bus transaction strobes.
  * `cpu_wb_adr_i[31:0]`: Memory-mapped slave address.
  * `cpu_wb_we_i`: Read (`0`) vs Write (`1`) indicator.
  * `cpu_wb_dat_i[31:0]`, `cpu_wb_dat_o[31:0]`: Write data and read data buses.
  * `active_ack`: Acknowledge returned by addressed peripheral slave.
  * `cpu_wb_err_o`: Bus error signal asserted by 64-cycle hardware timeout guard on unmapped address access.

---

### 2.4 Western Digital VeeR EL2 Instruction & Data Traces
* **Location:** `tb_neuroedge_soc.dut.gen_veer_cpu.u_cpu`
* **Signals to Add:**
  * `trace_rv_i_insn_ip`: Instruction opcode currently retiring in the pipeline.
  * `trace_rv_i_pc_ip`: Program counter of retiring instruction (starts at `0x0000_0000`).
  * `trace_rv_i_valid_ip`: Instruction retirement strobe. Total count reaches **16,832**.
  * `lsu_axi_awvalid`, `lsu_axi_wvalid`: Load/Store Unit AXI4 write channels.
  * `ifu_axi_arvalid`, `ifu_axi_rvalid`: Instruction Fetch Unit AXI4 fetch channels.

---

### 2.5 16550 UART Serial Telemetry
* **Location:** `tb_neuroedge_soc.dut.u_uart`
* **Signals to Add:**
  * `uart_tx`: Serial transmit line streaming ASCII inference results to external host.
  * `uart_rx`: Serial receive line ingesting external commands.
  * `tx_fifo_count[3:0]`: Current fill level of 8-byte transmit FIFO.
  * `rx_fifo_count[3:0]`: Current fill level of 8-byte receive FIFO.
  * `rx_push_strobe`: Single-cycle strobe latching completed byte into RX FIFO.

---

### 2.6 GPIO & Watchdog Timer Diagnostics
* **Signals to Add:**
  * `gpio_out[7:0]`: Visual diagnostic pattern. Drives `0xAA` upon successful inference verification.
  * `wdt_reset_out`: System-wide watchdog reset pulse (remains `0` when software periodically writes `0xA5A55A5A`).
  * `wdt_irq`: Watchdog early bark warning interrupt.

---

## 3. Recommended Verdi Display Settings
1. **Radix Formatting:**
   * Right-click `res_reg[3:0]` $\rightarrow$ Radix $\rightarrow$ **Decimal (Signed)** to clearly observe `-13`, `-41`, `94`, `7`.
   * Set `trace_rv_i_pc_ip` and `cpu_wb_adr_i` to **Hexadecimal**.
   * Set `gpio_out` to **Hexadecimal** (to see `AA`).
2. **Saving Signal Sessions:**
   * In Verdi, click `File` $\rightarrow$ `Save Signal List...` and save as `neuroedge_debug.rc` to reload your preferred signal layout in one click.
