# NeuroEdge SoC Memory & Address Mapping Specification

This document provides the complete, authoritative address mapping and register specification for the **NeuroEdge SoC** (RISC-V VeeR EL2 Core with 4x4 Systolic Array AI Accelerator).

---

## 1. System Memory Map Summary

The NeuroEdge SoC uses a unified 32-bit physical address space accessed via the 32-bit synchronous Wishbone interconnect fabric.

| Region / Peripheral | Base Address | End Address | Size | Bus Master Access | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Instruction SRAM (ISRAM)** | `0x0000_0000` | `0x0000_7FFF` | 32 KB | CPU, Interconnect | Single-port 32-bit SRAM for instruction storage and bootloader code |
| *Reserved Space* | `0x0000_8000` | `0x1FFF_FFFF` | ~512 MB | — | Reserved for future instruction expansion |
| **Data SRAM (DSRAM)** | `0x2000_0000` | `0x2000_FFFF` | 64 KB | CPU, DMA, SPI | Dual-port 32-bit SRAM for stack, data, weights, activations, and results |
| *Reserved Space* | `0x2001_0000` | `0x3FFF_FFFF` | ~512 MB | — | Reserved for off-chip external memory |
| **SPI Flash Controller** | `0x4000_0000` | `0x4000_0FFF` | 4 KB | CPU (Registers) | Master SPI Flash controller with autonomous DMA SRAM streaming |
| **DMA Controller** | `0x4000_1000` | `0x4000_1FFF` | 4 KB | CPU (Registers) | Dual-channel high-speed direct memory access streaming engine |
| **4x4 Systolic Array** | `0x4000_2000` | `0x4000_2FFF` | 4 KB | CPU, DMA | Weight-Stationary 4x4 INT8 tensor processing unit accelerator |
| **UART 16550** | `0x4000_3000` | `0x4000_3FFF` | 4 KB | CPU (Registers) | Asynchronous full-duplex serial transceiver with 8-byte FIFOs |
| **32-bit Precision Timer** | `0x4000_4000` | `0x4000_4FFF` | 4 KB | CPU (Registers) | Precision interval timer with auto-reload and periodic interrupts |
| **Watchdog Timer (WDT)** | `0x4000_5000` | `0x4000_5FFF` | 4 KB | CPU (Registers) | Safety watchdog with magic reload heartbeat key (`0xA5A55A5A`) |
| **8-bit GPIO Controller** | `0x4000_6000` | `0x4000_6FFF` | 4 KB | CPU (Registers) | 8-bit bidirectional GPIO with 2-stage synchronizers & IRQs |
| **Platform Interrupt Ctrl (PIC)**| `0x4000_7000` | `0x4000_7FFF` | 4 KB | CPU (Registers) | Prioritized 6-source interrupt controller with vectored output |
| *Unmapped Space* | `0x4000_8000` | `0xFFFF_FFFF` | ~3 GB | — | Generates interconnect bus error (`timeout_err`) after 64 cycles |

---

## 2. Data SRAM Memory Partitioning

The 64 KB Data SRAM (`0x2000_0000` - `0x2000_FFFF`) is partitioned as follows:

| Section | Base Address | End Address | Size | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **Stack & BSS / Data** | `0x2000_0000` | `0x2000_7FFF` | 32 KB | Stack pointer top at `0x2000_7FE0`, global `.data` and `.bss` |
| **NN Weights Storage** | `0x2000_8000` | `0x2000_9FFF` | 8 KB | 4x4 matrix weights loaded from SPI Flash or CPU |
| **NN Activations Storage** | `0x2000_A000` | `0x2000_AFFF` | 4 KB | Input feature vectors for neural network inference |
| **NN Output Results** | `0x2000_B000` | `0x2000_BFFF` | 4 KB | Accumulated systolic array results & post-activation data |
| *Scratchpad / Free* | `0x2000_C000` | `0x2000_FFFF` | 16 KB | Available user buffer space |

---

## 3. Peripheral Register Maps

### 3.1 SPI Flash Controller (`0x4000_0000`)
| Offset | Register Name | Width | Access | Reset | Description |
| :--- | :--- | :---: | :---: | :---: | :--- |
| `0x00` | `SPI_REG_CTRL` | 32 | RW | `0x0` | Control register (`bit 0`: Enable, `bit 1`: Start transfer, `bit 2`: Auto-read stream) |
| `0x04` | `SPI_REG_STATUS` | 32 | RO | `0x4` | Status register (`bit 0`: Busy, `bit 1`: Done [W1C], `bit 2`: RX FIFO empty) |
| `0x08` | `SPI_REG_CLKDIV` | 32 | RW | `0x2` | 8-bit SPI SCLK clock divisor (`sclk = clk / (2 * (div + 1))`) |
| `0x0C` | `SPI_REG_FLASH_ADDR` | 32 | RW | `0x0` | 24-bit SPI Flash start memory address |
| `0x10` | `SPI_REG_LENGTH` | 32 | RW | `0x0` | 16-bit transfer length in bytes |

### 3.2 DMA Controller (`0x4000_1000`)
| Offset | Register Name | Width | Access | Reset | Description |
| :--- | :--- | :---: | :---: | :---: | :--- |
| `0x00` | `DMA_REG_CTRL` | 32 | RW | `0x0` | Control register (`bit 0`: DMA Enable, `bit 1`: CH0 Enable, `bit 2`: CH1 Enable) |
| `0x04` | `DMA_REG_STATUS` | 32 | RO | `0x0` | Status register (`bit 0`: Busy, `bit 1`: CH0 Done, `bit 2`: CH1 Done, `bit 8`: Error) |
| `0x10` | `DMA_REG_CH0_SRC` | 32 | RW | `0x0` | Channel 0 Source SRAM memory address (activations) |
| `0x14` | `DMA_REG_CH0_DST` | 32 | RW | `0x4000_2014` | Channel 0 Destination address (defaults to `ARRAY_REG_ACT_PORT`) |
| `0x18` | `DMA_REG_CH0_LEN` | 32 | RW | `0x0` | Channel 0 Transfer length (number of 32-bit words) |
| `0x20` | `DMA_REG_CH1_SRC` | 32 | RW | `0x0` | Channel 1 Source SRAM memory address (weights) |
| `0x24` | `DMA_REG_CH1_DST` | 32 | RW | `0x4000_2010` | Channel 1 Destination address (defaults to `ARRAY_REG_WEIGHT_PORT`) |
| `0x28` | `DMA_REG_CH1_LEN` | 32 | RW | `0x0` | Channel 1 Transfer length (number of 32-bit words) |

### 3.3 4x4 Systolic Array Accelerator (`0x4000_2000`)
| Offset | Register Name | Width | Access | Reset | Description |
| :--- | :--- | :---: | :---: | :---: | :--- |
| `0x00` | `ARRAY_REG_CTRL` | 32 | RW | `0x0` | Array Control (`bit 0`: Enable, `bit 1`: Start compute, `bit 2`: Clear accumulators) |
| `0x04` | `ARRAY_REG_STATUS` | 32 | RO | `0x0` | Array Status (`bit 0`: Busy, `bit 1`: Done, `bit 2`: Overflow error) |
| `0x08` | `ARRAY_REG_CFG` | 32 | RW | `0x0` | Configuration register (quantization shift, activation ReLU enable) |
| `0x10` | `ARRAY_REG_WEIGHT_PORT`| 32 | WO | `0x0` | Weight injection port (packed 4x 8-bit signed integer weights) |
| `0x14` | `ARRAY_REG_ACT_PORT` | 32 | WO | `0x0` | Activation injection port (packed 4x 8-bit signed integer activations) |
| `0x20` | `ARRAY_REG_RES_0` | 32 | RO | `0x0` | 32-bit signed integer accumulator result for Row 0 |
| `0x24` | `ARRAY_REG_RES_1` | 32 | RO | `0x0` | 32-bit signed integer accumulator result for Row 1 |
| `0x28` | `ARRAY_REG_RES_2` | 32 | RO | `0x0` | 32-bit signed integer accumulator result for Row 2 |
| `0x2C` | `ARRAY_REG_RES_3` | 32 | RO | `0x0` | 32-bit signed integer accumulator result for Row 3 |

### 3.4 UART 16550 Transceiver (`0x4000_3000`)
| Offset | Register Name | Width | Access | Reset | Description |
| :--- | :--- | :---: | :---: | :---: | :--- |
| `0x00` | `UART_REG_TX_DATA` | 32 | WO | `0x0` | 8-bit TX data write port (pushes into 8-byte TX FIFO) |
| `0x04` | `UART_REG_RX_DATA` | 32 | RO | `0x0` | 8-bit RX data read port (pops from 8-byte RX FIFO) |
| `0x08` | `UART_REG_STATUS` | 32 | RO | `0x0` | Status (`bit 0`: TX Busy, `bit 1`: TX Full, `bit 2`: RX Valid, `bit 3`: RX Overrun) |
| `0x0C` | `UART_REG_BAUD_DIV` | 32 | RW | `0x1F` | 16-bit Baud Divisor (`baud = clk / ((div + 1) * 16)`) |

### 3.5 32-bit Precision Timer (`0x4000_4000`)
| Offset | Register Name | Width | Access | Reset | Description |
| :--- | :--- | :---: | :---: | :---: | :--- |
| `0x00` | `TIMER_REG_CTRL` | 32 | RW | `0x0` | Control register (`bit 0`: Timer Enable, `bit 1`: Auto-Reload on compare match) |
| `0x04` | `TIMER_REG_CNT` | 32 | RW | `0x0` | 32-bit running timer counter value |
| `0x08` | `TIMER_REG_CMP` | 32 | RW | `0xFFFF_FFFF`| 32-bit comparison threshold value for interrupt trigger |
| `0x0C` | `TIMER_REG_STATUS` | 32 | RO | `0x0` | Status register (`bit 0`: Match flag [cleared upon write 1 or read]) |

### 3.6 Safety Watchdog Timer (`0x4000_5000`)
| Offset | Register Name | Width | Access | Reset | Description |
| :--- | :--- | :---: | :---: | :---: | :--- |
| `0x00` | `WDT_REG_CTRL` | 32 | RW | `0x0` | Control (`bit 0`: Watchdog Enable, `bit 1`: System Reset Output Enable) |
| `0x04` | `WDT_REG_KICK` | 32 | WO | `0x0` | Heartbeat reload register (must write magic word `0xA5A5_5A5A` to kick) |
| `0x08` | `WDT_REG_TIMEOUT` | 32 | RW | `0x0001_0000`| 32-bit timeout countdown period |
| `0x0C` | `WDT_REG_STATUS` | 32 | RO | `0x0` | Status register (`bit 0`: Bark indicator flag indicating impending reset) |

### 3.7 8-bit GPIO Controller (`0x4000_6000`)
| Offset | Register Name | Width | Access | Reset | Description |
| :--- | :--- | :---: | :---: | :---: | :--- |
| `0x00` | `GPIO_REG_IN` | 32 | RO | `0x0` | 8-bit input pin status after 2-stage metastability synchronizers |
| `0x04` | `GPIO_REG_OUT` | 32 | RW | `0x0` | 8-bit output drive data |
| `0x08` | `GPIO_REG_DIR` | 32 | RW | `0x0` | 8-bit pin direction register (`1` = Output mode, `0` = Input mode) |
| `0x0C` | `GPIO_REG_STATUS` | 32 | RO | `0x0` | Status register (`bit 0`: Input transition edge flag detected) |

### 3.8 Platform Interrupt Controller / PIC (`0x4000_7000`)
| Offset | Register Name | Width | Access | Reset | Description |
| :--- | :--- | :---: | :---: | :---: | :--- |
| `0x00` | `PIC_REG_ENABLE` | 32 | RW | `0x0` | 6-bit interrupt enable mask |
| `0x04` | `PIC_REG_PENDING` | 32 | RO | `0x0` | 6-bit pending interrupt status |
| `0x08` | `PIC_REG_PRIORITY` | 32 | RW | `0x0` | 6-bit priority scheme configuration |
| `0x0C` | `PIC_REG_ACK` | 32 | WO | `0x0` | Interrupt acknowledge (write `1` to clear corresponding IRQ flag) |

---

## 4. Platform Interrupt Controller (PIC) IRQ Allocation

The PIC maps peripheral interrupts directly to the VeeR EL2 RISC-V vectored interrupt port:

| IRQ Bit | Peripheral Source | Trigger Condition | Mask Flag |
| :---: | :--- | :--- | :--- |
| `IRQ 0` | **Watchdog Timer** | Countdown expired without reload key (`wdt_irq`) | `PIC_IRQ_WDT (1 << 0)` |
| `IRQ 1` | **32-bit Timer** | Counter matches compare threshold register (`timer_irq`) | `PIC_IRQ_TIMER (1 << 1)` |
| `IRQ 2` | **Systolic Array** | Matrix multiply computation done (`array_irq`) | `PIC_IRQ_ARRAY (1 << 2)` |
| `IRQ 3` | **DMA Controller** | Channel 0 or Channel 1 transfer complete (`dma_irq`) | `PIC_IRQ_DMA (1 << 3)` |
| `IRQ 4` | **UART 16550** | RX FIFO non-empty or TX FIFO empty (`uart_irq`) | `PIC_IRQ_UART (1 << 4)` |
| `IRQ 5` | **8-bit GPIO** | Transition edge detected on input pin (`gpio_irq`) | `PIC_IRQ_GPIO (1 << 5)` |

---

## 5. Wishbone Crossbar Interconnect Address Decoding

The `soc_interconnect` module decodes Wishbone addresses using the top address bits as follows:

```verilog
wire sel_isram  = (cur_adr[31:16] == 16'h0000);  // 0x0000_0000 - 0x0000_7FFF (32 KB ISRAM)
wire sel_dsram  = (cur_adr[31:16] == 16'h2000);  // 0x2000_0000 - 0x2000_FFFF (64 KB DSRAM)
wire sel_spi    = (cur_adr[31:12] == 20'h40000); // 0x4000_0000 - 0x4000_0FFF (SPI Controller)
wire sel_dma    = (cur_adr[31:12] == 20'h40001); // 0x4000_1000 - 0x4000_1FFF (DMA Controller)
wire sel_array  = (cur_adr[31:12] == 20'h40002); // 0x4000_2000 - 0x4000_2FFF (Systolic Array)
wire sel_uart   = (cur_adr[31:12] == 20'h40003); // 0x4000_3000 - 0x4000_3FFF (UART 16550)
wire sel_timer  = (cur_adr[31:12] == 20'h40004); // 0x4000_4000 - 0x4000_4FFF (Precision Timer)
wire sel_wdt    = (cur_adr[31:12] == 20'h40005); // 0x4000_5000 - 0x4000_5FFF (Watchdog Timer)
wire sel_gpio   = (cur_adr[31:12] == 20'h40006); // 0x4000_6000 - 0x4000_6FFF (8-bit GPIO)
wire sel_pic    = (cur_adr[31:12] == 20'h40007); // 0x4000_7000 - 0x4000_7FFF (PIC Controller)
```

**Bus Error Guard**: Any transaction initiated to an unmapped address or stalled without slave acknowledgment for 64 consecutive clock cycles will assert `timeout_err`, aborting the bus cycle and signaling `m0_wb_err_o` to the CPU.
