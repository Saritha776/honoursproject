// ==============================================================================
// Package: neuroedge_addr_pkg.sv
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: System-wide address map, peripheral base addresses, register
//              offsets, and bitfield masks for RTL and Verification.
// ==============================================================================

`ifndef NEUROEDGE_ADDR_PKG_SV
`define NEUROEDGE_ADDR_PKG_SV

package neuroedge_addr_pkg;

    // =========================================================================
    // Memory Subsystem Base Addresses & Limits
    // =========================================================================
    localparam logic [31:0] ISRAM_BASE              = 32'h0000_0000;
    localparam logic [31:0] ISRAM_LIMIT             = 32'h0000_7FFF; // 32 KB
    localparam logic [31:0] ISRAM_SIZE              = 32'h0000_8000;

    localparam logic [31:0] DSRAM_BASE              = 32'h2000_0000;
    localparam logic [31:0] DSRAM_LIMIT             = 32'h2000_FFFF; // 64 KB
    localparam logic [31:0] DSRAM_SIZE              = 32'h0001_0000;

    // Data SRAM Internal Layout
    localparam logic [31:0] DSRAM_STACK_BASE        = 32'h2000_0000;
    localparam logic [31:0] DSRAM_STACK_TOP         = 32'h2000_7FE0;
    localparam logic [31:0] DSRAM_WEIGHTS_BASE      = 32'h2000_8000; // 8 KB
    localparam logic [31:0] DSRAM_ACTS_BASE         = 32'h2000_A000; // 4 KB
    localparam logic [31:0] DSRAM_OUTS_BASE         = 32'h2000_B000; // 4 KB

    // =========================================================================
    // Peripheral Base Addresses (4 KB Aperture Each)
    // =========================================================================
    localparam logic [31:0] SPI_BASE                = 32'h4000_0000;
    localparam logic [31:0] DMA_BASE                = 32'h4000_1000;
    localparam logic [31:0] ARRAY_BASE              = 32'h4000_2000;
    localparam logic [31:0] UART_BASE               = 32'h4000_3000;
    localparam logic [31:0] TIMER_BASE              = 32'h4000_4000;
    localparam logic [31:0] WDT_BASE                = 32'h4000_5000;
    localparam logic [31:0] GPIO_BASE               = 32'h4000_6000;
    localparam logic [31:0] PIC_BASE                = 32'h4000_7000;

    // =========================================================================
    // 1. SPI Controller Register Offsets & Bitfields
    // =========================================================================
    localparam logic [7:0]  SPI_REG_CTRL_OFFSET     = 8'h00;
    localparam logic [7:0]  SPI_REG_STATUS_OFFSET   = 8'h04;
    localparam logic [7:0]  SPI_REG_CLKDIV_OFFSET   = 8'h08;
    localparam logic [7:0]  SPI_REG_FLASH_ADDR_OFF  = 8'h0C;
    localparam logic [7:0]  SPI_REG_LENGTH_OFFSET   = 8'h10;

    localparam logic [31:0] SPI_REG_CTRL_ADDR       = SPI_BASE + 32'h00;
    localparam logic [31:0] SPI_REG_STATUS_ADDR     = SPI_BASE + 32'h04;
    localparam logic [31:0] SPI_REG_CLKDIV_ADDR     = SPI_BASE + 32'h08;
    localparam logic [31:0] SPI_REG_FLASH_ADDR_ADDR = SPI_BASE + 32'h0C;
    localparam logic [31:0] SPI_REG_LENGTH_ADDR     = SPI_BASE + 32'h10;

    localparam logic [31:0] SPI_CTRL_EN             = 32'h0000_0001;
    localparam logic [31:0] SPI_CTRL_START          = 32'h0000_0002;
    localparam logic [31:0] SPI_CTRL_AUTO_READ      = 32'h0000_0004;

    localparam logic [31:0] SPI_STATUS_BUSY         = 32'h0000_0001;
    localparam logic [31:0] SPI_STATUS_DONE         = 32'h0000_0002;
    localparam logic [31:0] SPI_STATUS_RX_EMPTY     = 32'h0000_0004;

    // =========================================================================
    // 2. DMA Controller Register Offsets & Bitfields
    // =========================================================================
    localparam logic [7:0]  DMA_REG_CTRL_OFFSET     = 8'h00;
    localparam logic [7:0]  DMA_REG_STATUS_OFFSET   = 8'h04;
    localparam logic [7:0]  DMA_REG_CH0_SRC_OFFSET  = 8'h10;
    localparam logic [7:0]  DMA_REG_CH0_DST_OFFSET  = 8'h14;
    localparam logic [7:0]  DMA_REG_CH0_LEN_OFFSET  = 8'h18;
    localparam logic [7:0]  DMA_REG_CH1_SRC_OFFSET  = 8'h20;
    localparam logic [7:0]  DMA_REG_CH1_DST_OFFSET  = 8'h24;
    localparam logic [7:0]  DMA_REG_CH1_LEN_OFFSET  = 8'h28;

    localparam logic [31:0] DMA_REG_CTRL_ADDR       = DMA_BASE + 32'h00;
    localparam logic [31:0] DMA_REG_STATUS_ADDR     = DMA_BASE + 32'h04;
    localparam logic [31:0] DMA_REG_CH0_SRC_ADDR    = DMA_BASE + 32'h10;
    localparam logic [31:0] DMA_REG_CH0_DST_ADDR    = DMA_BASE + 32'h14;
    localparam logic [31:0] DMA_REG_CH0_LEN_ADDR    = DMA_BASE + 32'h18;
    localparam logic [31:0] DMA_REG_CH1_SRC_ADDR    = DMA_BASE + 32'h20;
    localparam logic [31:0] DMA_REG_CH1_DST_ADDR    = DMA_BASE + 32'h24;
    localparam logic [31:0] DMA_REG_CH1_LEN_ADDR    = DMA_BASE + 32'h28;

    localparam logic [31:0] DMA_CTRL_EN             = 32'h0000_0001;
    localparam logic [31:0] DMA_CTRL_CH0_EN         = 32'h0000_0002;
    localparam logic [31:0] DMA_CTRL_CH1_EN         = 32'h0000_0004;

    localparam logic [31:0] DMA_STATUS_BUSY         = 32'h0000_0001;
    localparam logic [31:0] DMA_STATUS_CH0_DONE     = 32'h0000_0002;
    localparam logic [31:0] DMA_STATUS_CH1_DONE     = 32'h0000_0004;
    localparam logic [31:0] DMA_STATUS_ERR          = 32'h0000_0100;

    // =========================================================================
    // 3. 4x4 Systolic Array Register Offsets & Bitfields
    // =========================================================================
    localparam logic [7:0]  ARRAY_REG_CTRL_OFFSET   = 8'h00;
    localparam logic [7:0]  ARRAY_REG_STATUS_OFFSET = 8'h04;
    localparam logic [7:0]  ARRAY_REG_CFG_OFFSET    = 8'h08;
    localparam logic [7:0]  ARRAY_REG_WGT_OFFSET    = 8'h10;
    localparam logic [7:0]  ARRAY_REG_ACT_OFFSET    = 8'h14;
    localparam logic [7:0]  ARRAY_REG_RES0_OFFSET   = 8'h20;
    localparam logic [7:0]  ARRAY_REG_RES1_OFFSET   = 8'h24;
    localparam logic [7:0]  ARRAY_REG_RES2_OFFSET   = 8'h28;
    localparam logic [7:0]  ARRAY_REG_RES3_OFFSET   = 8'h2C;

    localparam logic [31:0] ARRAY_REG_CTRL_ADDR     = ARRAY_BASE + 32'h00;
    localparam logic [31:0] ARRAY_REG_STATUS_ADDR   = ARRAY_BASE + 32'h04;
    localparam logic [31:0] ARRAY_REG_CFG_ADDR      = ARRAY_BASE + 32'h08;
    localparam logic [31:0] ARRAY_REG_WEIGHT_PORT   = ARRAY_BASE + 32'h10;
    localparam logic [31:0] ARRAY_REG_ACT_PORT      = ARRAY_BASE + 32'h14;
    localparam logic [31:0] ARRAY_REG_RES_0         = ARRAY_BASE + 32'h20;
    localparam logic [31:0] ARRAY_REG_RES_1         = ARRAY_BASE + 32'h24;
    localparam logic [31:0] ARRAY_REG_RES_2         = ARRAY_BASE + 32'h28;
    localparam logic [31:0] ARRAY_REG_RES_3         = ARRAY_BASE + 32'h2C;

    localparam logic [31:0] ARRAY_CTRL_EN           = 32'h0000_0001;
    localparam logic [31:0] ARRAY_CTRL_START        = 32'h0000_0002;
    localparam logic [31:0] ARRAY_CTRL_CLEAR_ACC    = 32'h0000_0004;

    localparam logic [31:0] ARRAY_STATUS_BUSY       = 32'h0000_0001;
    localparam logic [31:0] ARRAY_STATUS_DONE       = 32'h0000_0002;
    localparam logic [31:0] ARRAY_STATUS_OVERFLOW   = 32'h0000_0004;

    // =========================================================================
    // 4. UART 16550 Register Offsets & Bitfields
    // =========================================================================
    localparam logic [7:0]  UART_REG_TX_DATA_OFFSET = 8'h00;
    localparam logic [7:0]  UART_REG_RX_DATA_OFFSET = 8'h04;
    localparam logic [7:0]  UART_REG_STATUS_OFFSET  = 8'h08;
    localparam logic [7:0]  UART_REG_BAUD_DIV_OFF   = 8'h0C;

    localparam logic [31:0] UART_REG_TX_DATA_ADDR   = UART_BASE + 32'h00;
    localparam logic [31:0] UART_REG_RX_DATA_ADDR   = UART_BASE + 32'h04;
    localparam logic [31:0] UART_REG_STATUS_ADDR    = UART_BASE + 32'h08;
    localparam logic [31:0] UART_REG_BAUD_DIV_ADDR  = UART_BASE + 32'h0C;

    localparam logic [31:0] UART_STATUS_TX_BUSY     = 32'h0000_0001;
    localparam logic [31:0] UART_STATUS_TX_FULL     = 32'h0000_0002;
    localparam logic [31:0] UART_STATUS_RX_VALID    = 32'h0000_0004;
    localparam logic [31:0] UART_STATUS_RX_OVERRUN  = 32'h0000_0008;

    // =========================================================================
    // 5. 32-bit Precision Timer Register Offsets & Bitfields
    // =========================================================================
    localparam logic [7:0]  TIMER_REG_CTRL_OFFSET   = 8'h00;
    localparam logic [7:0]  TIMER_REG_CNT_OFFSET    = 8'h04;
    localparam logic [7:0]  TIMER_REG_CMP_OFFSET    = 8'h08;
    localparam logic [7:0]  TIMER_REG_STATUS_OFFSET = 8'h0C;

    localparam logic [31:0] TIMER_REG_CTRL_ADDR     = TIMER_BASE + 32'h00;
    localparam logic [31:0] TIMER_REG_CNT_ADDR      = TIMER_BASE + 32'h04;
    localparam logic [31:0] TIMER_REG_CMP_ADDR      = TIMER_BASE + 32'h08;
    localparam logic [31:0] TIMER_REG_STATUS_ADDR   = TIMER_BASE + 32'h0C;

    localparam logic [31:0] TIMER_CTRL_EN           = 32'h0000_0001;
    localparam logic [31:0] TIMER_CTRL_AUTO_RELOAD  = 32'h0000_0002;
    localparam logic [31:0] TIMER_STATUS_MATCH      = 32'h0000_0001;

    // =========================================================================
    // 6. Safety Watchdog Timer Register Offsets & Bitfields
    // =========================================================================
    localparam logic [7:0]  WDT_REG_CTRL_OFFSET     = 8'h00;
    localparam logic [7:0]  WDT_REG_KICK_OFFSET     = 8'h04;
    localparam logic [7:0]  WDT_REG_TIMEOUT_OFFSET  = 8'h08;
    localparam logic [7:0]  WDT_REG_STATUS_OFFSET   = 8'h0C;

    localparam logic [31:0] WDT_REG_CTRL_ADDR       = WDT_BASE + 32'h00;
    localparam logic [31:0] WDT_REG_KICK_ADDR       = WDT_BASE + 32'h04;
    localparam logic [31:0] WDT_REG_TIMEOUT_ADDR    = WDT_BASE + 32'h08;
    localparam logic [31:0] WDT_REG_STATUS_ADDR     = WDT_BASE + 32'h0C;

    localparam logic [31:0] WDT_KEY_RELOAD          = 32'hA5A5_5A5A;
    localparam logic [31:0] WDT_CTRL_EN             = 32'h0000_0001;
    localparam logic [31:0] WDT_CTRL_RESET_EN       = 32'h0000_0002;
    localparam logic [31:0] WDT_STATUS_BARK         = 32'h0000_0001;

    // =========================================================================
    // 7. 8-bit GPIO Controller Register Offsets & Bitfields
    // =========================================================================
    localparam logic [7:0]  GPIO_REG_IN_OFFSET      = 8'h00;
    localparam logic [7:0]  GPIO_REG_OUT_OFFSET     = 8'h04;
    localparam logic [7:0]  GPIO_REG_DIR_OFFSET     = 8'h08;
    localparam logic [7:0]  GPIO_REG_STATUS_OFFSET  = 8'h0C;

    localparam logic [31:0] GPIO_REG_IN_ADDR        = GPIO_BASE + 32'h00;
    localparam logic [31:0] GPIO_REG_OUT_ADDR       = GPIO_BASE + 32'h04;
    localparam logic [31:0] GPIO_REG_DIR_ADDR       = GPIO_BASE + 32'h08;
    localparam logic [31:0] GPIO_REG_STATUS_ADDR    = GPIO_BASE + 32'h0C;

    // =========================================================================
    // 8. Platform Interrupt Controller (PIC) Register Offsets & Bitfields
    // =========================================================================
    localparam logic [7:0]  PIC_REG_ENABLE_OFFSET   = 8'h00;
    localparam logic [7:0]  PIC_REG_PENDING_OFFSET  = 8'h04;
    localparam logic [7:0]  PIC_REG_PRIORITY_OFFSET = 8'h08;
    localparam logic [7:0]  PIC_REG_ACK_OFFSET      = 8'h0C;

    localparam logic [31:0] PIC_REG_ENABLE_ADDR     = PIC_BASE + 32'h00;
    localparam logic [31:0] PIC_REG_PENDING_ADDR    = PIC_BASE + 32'h04;
    localparam logic [31:0] PIC_REG_PRIORITY_ADDR   = PIC_BASE + 32'h08;
    localparam logic [31:0] PIC_REG_ACK_ADDR        = PIC_BASE + 32'h0C;

    localparam logic [5:0]  PIC_IRQ_WDT             = 6'b000001; // IRQ 0
    localparam logic [5:0]  PIC_IRQ_TIMER           = 6'b000010; // IRQ 1
    localparam logic [5:0]  PIC_IRQ_ARRAY           = 6'b000100; // IRQ 2
    localparam logic [5:0]  PIC_IRQ_DMA             = 6'b001000; // IRQ 3
    localparam logic [5:0]  PIC_IRQ_UART            = 6'b010000; // IRQ 4
    localparam logic [5:0]  PIC_IRQ_GPIO            = 6'b100000; // IRQ 5

endpackage : neuroedge_addr_pkg

`endif // NEUROEDGE_ADDR_PKG_SV
