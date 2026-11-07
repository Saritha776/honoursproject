// ==============================================================================
// Module: uart_16550.sv
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: Full-duplex asynchronous serial transceiver (UART) with 8-byte
//              TX/RX FIFOs and programmable 16-bit baud divisor.
// Base Address: 0x4000_3000
// ==============================================================================

`timescale 1ns / 1ps

module uart_16550 (
    input  logic        clk,
    input  logic        rst_n,
    
    // Wishbone Slave Interface
    input  logic [31:0] wb_adr_i,
    input  logic [31:0] wb_dat_i,
    output logic [31:0] wb_dat_o,
    input  logic        wb_we_i,
    input  logic        wb_stb_i,
    input  logic        wb_cyc_i,
    output logic        wb_ack_o,
    
    // External Serial Pins
    output logic        uart_tx,
    input  logic        uart_rx,
    
    // Interrupt Output
    output logic        uart_irq
);

    // Register Offsets
    localparam REG_UART_TX_DATA  = 8'h00;
    localparam REG_UART_RX_DATA  = 8'h04;
    localparam REG_UART_STATUS   = 8'h08;
    localparam REG_UART_BAUD_DIV = 8'h0C;

    // Registers & Status
    logic [15:0] baud_div;
    logic        rx_overrun;
    logic        rx_overrun_set;
    logic        tx_busy;
    
    // 8-byte TX FIFO
    logic [7:0] tx_fifo [0:7];
    logic [2:0] tx_wr_ptr, tx_rd_ptr;
    logic [3:0] tx_count;
    logic       tx_fifo_full, tx_fifo_empty;

    // 8-byte RX FIFO
    logic [7:0] rx_fifo [0:7];
    logic [2:0] rx_wr_ptr, rx_rd_ptr;
    logic [3:0] rx_count;
    logic       rx_fifo_full, rx_fifo_empty;

    assign tx_fifo_full  = (tx_count == 4'd8);
    assign tx_fifo_empty = (tx_count == 4'd0);
    assign rx_fifo_full  = (rx_count == 4'd8);
    assign rx_fifo_empty = (rx_count == 4'd0);

    // TX Baud Generator & Shift Register
    logic [15:0] tx_baud_cnt;
    logic [3:0]  tx_bit_idx;
    logic [9:0]  tx_shift_reg; // 1 start, 8 data, 1 stop

    // RX Synchronizer & Oversampling (16x baud)
    logic rx_sync1, rx_sync2;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= uart_rx;
            rx_sync2 <= rx_sync1;
        end
    end

    logic [15:0] rx_baud_cnt;
    logic [3:0]  rx_sample_cnt;
    logic [3:0]  rx_bit_idx;
    logic [7:0]  rx_shift_reg;
    logic        rx_busy;
    logic        rx_push_strobe;

    // Wishbone Read/Write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_div    <= 16'h01B2; // Default 434 for 115200 bps at 50 MHz
            rx_overrun  <= 1'b0;
            tx_wr_ptr   <= 3'd0;
            rx_rd_ptr   <= 3'd0;
            wb_ack_o    <= 1'b0;
            wb_dat_o    <= 32'h0000_0000;
            for (int i = 0; i < 8; i++) begin
                tx_fifo[i] <= 8'h00;
            end
        end else begin
            wb_ack_o <= 1'b0;

            if (rx_overrun_set) begin
                rx_overrun <= 1'b1;
            end

            if (wb_stb_i && wb_cyc_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;
                if (wb_we_i) begin
                    case (wb_adr_i[7:0])
                        REG_UART_TX_DATA: begin
                            if (!tx_fifo_full) begin
                                tx_fifo[tx_wr_ptr] <= wb_dat_i[7:0];
                                tx_wr_ptr          <= tx_wr_ptr + 1'b1;
                            end
                        end
                        REG_UART_STATUS: begin
                            if (wb_dat_i[3]) rx_overrun <= 1'b0;
                        end
                        REG_UART_BAUD_DIV: baud_div <= wb_dat_i[15:0];
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[7:0])
                        REG_UART_TX_DATA: wb_dat_o <= 32'h0000_0000;
                        REG_UART_RX_DATA: begin
                            if (!rx_fifo_empty) begin
                                wb_dat_o  <= {24'b0, rx_fifo[rx_rd_ptr]};
                                rx_rd_ptr <= rx_rd_ptr + 1'b1;
                            end else begin
                                wb_dat_o  <= 32'h0000_0000;
                            end
                        end
                        REG_UART_STATUS: wb_dat_o <= {28'b0, rx_overrun, !rx_fifo_empty, tx_fifo_full, tx_busy};
                        REG_UART_BAUD_DIV: wb_dat_o <= {16'b0, baud_div};
                        default: wb_dat_o <= 32'h0000_0000;
                    endcase
                end
            end
        end
    end

    // FIFO Counters
    wire tx_push = (wb_stb_i && wb_cyc_i && wb_we_i && !wb_ack_o && (wb_adr_i[7:0] == REG_UART_TX_DATA) && !tx_fifo_full);
    wire tx_pop  = (!tx_busy && !tx_fifo_empty);
    wire rx_push = rx_push_strobe;
    wire rx_pop  = (wb_stb_i && wb_cyc_i && !wb_we_i && !wb_ack_o && (wb_adr_i[7:0] == REG_UART_RX_DATA) && !rx_fifo_empty);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_count <= 4'd0;
            rx_count <= 4'd0;
        end else begin
            // TX count update
            if (tx_push && !tx_pop) tx_count <= tx_count + 1'b1;
            else if (!tx_push && tx_pop) tx_count <= tx_count - 1'b1;

            // RX count update
            if (rx_push && !rx_pop) rx_count <= rx_count + 1'b1;
            else if (!rx_push && rx_pop) rx_count <= rx_count - 1'b1;
        end
    end

    // UART Transmitter Engine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_busy      <= 1'b0;
            uart_tx      <= 1'b1;
            tx_baud_cnt  <= 16'd0;
            tx_bit_idx   <= 4'd0;
            tx_shift_reg <= 10'h3FF;
            tx_rd_ptr    <= 3'd0;
        end else begin
            if (!tx_busy) begin
                uart_tx <= 1'b1;
                if (!tx_fifo_empty) begin
                    tx_shift_reg <= {1'b1, tx_fifo[tx_rd_ptr], 1'b0}; // Stop(1), Data(8), Start(0)
                    tx_rd_ptr    <= tx_rd_ptr + 1'b1;
                    tx_busy      <= 1'b1;
                    tx_baud_cnt  <= 16'd0;
                    tx_bit_idx   <= 4'd0;
                end
            end else begin
                if (tx_baud_cnt >= baud_div) begin
                    tx_baud_cnt  <= 16'd0;
                    uart_tx      <= tx_shift_reg[0];
                    tx_shift_reg <= {1'b1, tx_shift_reg[9:1]};
                    tx_bit_idx   <= tx_bit_idx + 1'b1;
                    if (tx_bit_idx == 4'd9) begin
                        tx_busy <= 1'b0;
                    end
                end else begin
                    tx_baud_cnt <= tx_baud_cnt + 1'b1;
                end
            end
        end
    end

    // UART Receiver Engine (16x oversampling)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_busy        <= 1'b0;
            rx_baud_cnt    <= 16'd0;
            rx_sample_cnt  <= 4'd0;
            rx_bit_idx     <= 4'd0;
            rx_shift_reg   <= 8'h00;
            rx_wr_ptr      <= 3'd0;
            rx_overrun_set <= 1'b0;
            rx_push_strobe <= 1'b0;
            for (int i = 0; i < 8; i++) begin
                rx_fifo[i] <= 8'h00;
            end
        end else begin
            rx_overrun_set <= 1'b0;
            rx_push_strobe <= 1'b0;
            if (!rx_busy) begin
                if (!rx_sync2) begin // Detected Start bit falling edge
                    rx_busy       <= 1'b1;
                    rx_baud_cnt   <= 16'd0;
                    rx_sample_cnt <= 4'd0;
                    rx_bit_idx    <= 4'd0;
                end
            end else begin
                if (rx_baud_cnt >= (baud_div >> 4)) begin
                    rx_baud_cnt   <= 16'd0;
                    rx_sample_cnt <= rx_sample_cnt + 1'b1;

                    // Sample in the middle of bit (sample count 7)
                    if (rx_sample_cnt == 4'd7) begin
                        if (rx_bit_idx == 4'd0) begin
                            // Confirm start bit
                            if (rx_sync2 != 1'b0) rx_busy <= 1'b0; // False start
                            else rx_bit_idx <= rx_bit_idx + 1'b1;
                        end else if (rx_bit_idx <= 4'd8) begin
                            rx_shift_reg <= {rx_sync2, rx_shift_reg[7:1]};
                            rx_bit_idx   <= rx_bit_idx + 1'b1;
                        end else begin
                            // Stop bit sampled
                            if (!rx_fifo_full) begin
                                rx_fifo[rx_wr_ptr] <= rx_shift_reg;
                                rx_wr_ptr          <= rx_wr_ptr + 1'b1;
                                rx_push_strobe     <= 1'b1;
                            end else begin
                                rx_overrun_set <= 1'b1;
                            end
                            rx_busy <= 1'b0;
                        end
                    end
                end else begin
                    rx_baud_cnt <= rx_baud_cnt + 1'b1;
                end
            end
        end
    end

    // Interrupt asserts on TX FIFO empty or RX byte ready
    assign uart_irq = tx_fifo_empty | (!rx_fifo_empty);

endmodule
