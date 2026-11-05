// ==============================================================================
// Module: spi_flash_ctrl.sv
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: Master SPI Flash Controller (Mode 0: CPOL=0, CPHA=0) with
//              programmable clock division and autonomous burst SRAM streaming.
// Base Address: 0x4000_0000
// ==============================================================================

`timescale 1ns / 1ps

module spi_flash_ctrl (
    input  logic        clk,
    input  logic        rst_n,
    
    // Wishbone Slave Interface (CPU register access)
    input  logic [31:0] s_wb_adr_i,
    input  logic [31:0] s_wb_dat_i,
    output logic [31:0] s_wb_dat_o,
    input  logic        s_wb_we_i,
    input  logic        s_wb_stb_i,
    input  logic        s_wb_cyc_i,
    output logic        s_wb_ack_o,
    
    // Wishbone Master Interface (Auto-stream writes to Data SRAM 0x2000_8000)
    output logic [31:0] m_wb_adr_o,
    output logic [31:0] m_wb_dat_o,
    output logic        m_wb_we_o,
    output logic        m_wb_stb_o,
    output logic        m_wb_cyc_o,
    input  logic        m_wb_ack_i,
    
    // External SPI Flash Pins
    output logic        spi_sclk,
    output logic        spi_mosi,
    input  logic        spi_miso,
    output logic        spi_cs_n,
    
    // Interrupt Output
    output logic        spi_irq
);

    // Register Offsets
    localparam REG_SPI_CTRL       = 8'h00;
    localparam REG_SPI_STATUS     = 8'h04;
    localparam REG_SPI_CLKDIV     = 8'h08;
    localparam REG_SPI_FLASH_ADDR = 8'h0C;
    localparam REG_SPI_LENGTH     = 8'h10;

    // Registers
    logic        reg_en;
    logic        reg_start;
    logic        reg_auto_read;
    logic        reg_busy;
    logic        reg_done;
    logic        reg_rx_empty;
    logic [7:0]  reg_clkdiv;
    logic [23:0] reg_flash_addr;
    logic [7:0]  reg_cmd_byte;
    logic [15:0] reg_byte_len;

    // Internal FSM
    typedef enum logic [3:0] {
        SPI_IDLE        = 4'h0,
        SPI_SEND_CMD    = 4'h1,
        SPI_SEND_ADDR   = 4'h2,
        SPI_READ_BYTE   = 4'h3,
        SPI_WRITE_SRAM  = 4'h4,
        SPI_FINISH      = 4'h5
    } spi_state_t;

    spi_state_t state;

    logic [7:0]  clk_cnt;
    logic        sclk_int;
    logic [31:0] shift_out;
    logic [7:0]  shift_in;
    logic [5:0]  bit_cnt;
    logic [15:0] bytes_remaining;
    logic [31:0] sram_dest_addr;
    logic [31:0] word_buffer;
    logic [1:0]  byte_in_word;

    // Clock generation for SPI (CPOL=0, CPHA=0)
    logic sclk_edge_rise;
    logic sclk_edge_fall;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt        <= 8'd0;
            sclk_int       <= 1'b0;
            sclk_edge_rise <= 1'b0;
            sclk_edge_fall <= 1'b0;
        end else begin
            sclk_edge_rise <= 1'b0;
            sclk_edge_fall <= 1'b0;

            if (state != SPI_IDLE && state != SPI_WRITE_SRAM && state != SPI_FINISH) begin
                if (clk_cnt >= reg_clkdiv) begin
                    clk_cnt  <= 8'd0;
                    sclk_int <= ~sclk_int;
                    if (!sclk_int) sclk_edge_rise <= 1'b1;
                    else           sclk_edge_fall <= 1'b1;
                end else begin
                    clk_cnt <= clk_cnt + 1'b1;
                end
            end else begin
                clk_cnt  <= 8'd0;
                sclk_int <= 1'b0;
            end
        end
    end

    assign spi_sclk = sclk_int;

    // Slave Register Read/Write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_en         <= 1'b0;
            reg_start      <= 1'b0;
            reg_auto_read  <= 1'b1;
            reg_done       <= 1'b0;
            reg_clkdiv     <= 8'd4; // Default prescaler
            reg_flash_addr <= 24'h000000;
            reg_cmd_byte   <= 8'h03; // Standard Read
            reg_byte_len   <= 16'd0;
            s_wb_ack_o     <= 1'b0;
            s_wb_dat_o     <= 32'h0000_0000;
        end else begin
            s_wb_ack_o <= 1'b0;
            reg_start  <= 1'b0;

            if (s_wb_stb_i && s_wb_cyc_i && !s_wb_ack_o) begin
                s_wb_ack_o <= 1'b1;
                if (s_wb_we_i) begin
                    case (s_wb_adr_i[7:0])
                        REG_SPI_CTRL: begin
                            reg_en        <= s_wb_dat_i[0];
                            reg_start     <= s_wb_dat_i[1];
                            reg_auto_read <= s_wb_dat_i[2];
                        end
                        REG_SPI_STATUS: begin
                            if (s_wb_dat_i[1]) reg_done <= 1'b0;
                        end
                        REG_SPI_CLKDIV:     reg_clkdiv     <= s_wb_dat_i[7:0];
                        REG_SPI_FLASH_ADDR: begin
                            reg_flash_addr <= s_wb_dat_i[23:0];
                            reg_cmd_byte   <= s_wb_dat_i[31:24];
                        end
                        REG_SPI_LENGTH:     reg_byte_len   <= s_wb_dat_i[15:0];
                        default: ;
                    endcase
                end else begin
                    case (s_wb_adr_i[7:0])
                        REG_SPI_CTRL:       s_wb_dat_o <= {29'b0, reg_auto_read, 1'b0, reg_en};
                        REG_SPI_STATUS:     s_wb_dat_o <= {29'b0, reg_rx_empty, reg_done, reg_busy};
                        REG_SPI_CLKDIV:     s_wb_dat_o <= {24'b0, reg_clkdiv};
                        REG_SPI_FLASH_ADDR: s_wb_dat_o <= {reg_cmd_byte, reg_flash_addr};
                        REG_SPI_LENGTH:     s_wb_dat_o <= {16'b0, reg_byte_len};
                        default:            s_wb_dat_o <= 32'h0000_0000;
                    endcase
                end
            end

            if (state == SPI_FINISH) begin
                reg_done <= 1'b1;
            end
        end
    end

    // Master Engine FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= SPI_IDLE;
            reg_busy        <= 1'b0;
            reg_rx_empty    <= 1'b1;
            spi_cs_n        <= 1'b1;
            spi_mosi        <= 1'b1;
            shift_out       <= 32'h0000_0000;
            shift_in        <= 8'h00;
            bit_cnt         <= 6'd0;
            bytes_remaining <= 16'd0;
            sram_dest_addr  <= 32'h2000_8000; // Weight staging buffer base
            word_buffer     <= 32'h0000_0000;
            byte_in_word    <= 2'd0;
            m_wb_adr_o      <= 32'h0000_0000;
            m_wb_dat_o      <= 32'h0000_0000;
            m_wb_we_o       <= 1'b0;
            m_wb_stb_o      <= 1'b0;
            m_wb_cyc_o      <= 1'b0;
        end else begin
            case (state)
                SPI_IDLE: begin
                    spi_cs_n     <= 1'b1;
                    spi_mosi     <= 1'b1;
                    m_wb_stb_o   <= 1'b0;
                    m_wb_cyc_o   <= 1'b0;
                    m_wb_we_o    <= 1'b0;
                    byte_in_word <= 2'd0;
                    
                    if (reg_en && reg_start && reg_byte_len > 0) begin
                        reg_busy        <= 1'b1;
                        spi_cs_n        <= 1'b0;
                        shift_out       <= {reg_cmd_byte, 24'b0};
                        bit_cnt         <= 6'd8;
                        bytes_remaining <= reg_byte_len;
                        sram_dest_addr  <= 32'h2000_8000;
                        state           <= SPI_SEND_CMD;
                    end else begin
                        reg_busy <= 1'b0;
                    end
                end

                // Transmit 8-bit command (0x03)
                SPI_SEND_CMD: begin
                    spi_mosi <= shift_out[31];
                    if (sclk_edge_fall) begin
                        shift_out <= {shift_out[30:0], 1'b0};
                        bit_cnt   <= bit_cnt - 1'b1;
                        if (bit_cnt == 6'd1) begin
                            shift_out <= {reg_flash_addr, 8'b0};
                            bit_cnt   <= 6'd24;
                            state     <= SPI_SEND_ADDR;
                        end
                    end
                end

                // Transmit 24-bit Flash memory address
                SPI_SEND_ADDR: begin
                    spi_mosi <= shift_out[31];
                    if (sclk_edge_fall) begin
                        shift_out <= {shift_out[30:0], 1'b0};
                        bit_cnt   <= bit_cnt - 1'b1;
                        if (bit_cnt == 6'd1) begin
                            bit_cnt <= 6'd8;
                            state   <= SPI_READ_BYTE;
                        end
                    end
                end

                // Ingest INT8 byte from Flash over MISO
                SPI_READ_BYTE: begin
                    if (sclk_edge_rise) begin
                        shift_in <= {shift_in[6:0], spi_miso};
                        bit_cnt  <= bit_cnt - 1'b1;
                        if (bit_cnt == 6'd1) begin
                            // Pack byte into 32-bit word
                            case (byte_in_word)
                                2'd0: word_buffer[7:0]   <= {shift_in[6:0], spi_miso};
                                2'd1: word_buffer[15:8]  <= {shift_in[6:0], spi_miso};
                                2'd2: word_buffer[23:16] <= {shift_in[6:0], spi_miso};
                                2'd3: word_buffer[31:24] <= {shift_in[6:0], spi_miso};
                            endcase

                            bytes_remaining <= bytes_remaining - 1'b1;
                            bit_cnt         <= 6'd8;

                            if (byte_in_word == 2'd3 || bytes_remaining == 16'd1) begin
                                // 32-bit word ready -> write to SRAM via Wishbone Master
                                byte_in_word <= 2'd0;
                                m_wb_adr_o   <= sram_dest_addr;
                                m_wb_dat_o   <= (byte_in_word == 2'd3) ? 
                                                { {shift_in[6:0], spi_miso}, word_buffer[23:0] } :
                                                word_buffer;
                                m_wb_we_o    <= 1'b1;
                                m_wb_cyc_o   <= 1'b1;
                                m_wb_stb_o   <= 1'b1;
                                state        <= SPI_WRITE_SRAM;
                            end else begin
                                byte_in_word <= byte_in_word + 1'b1;
                            end
                        end
                    end
                end

                // Write packed 32-bit word into Data SRAM
                SPI_WRITE_SRAM: begin
                    if (m_wb_ack_i) begin
                        m_wb_stb_o     <= 1'b0;
                        m_wb_cyc_o     <= 1'b0;
                        m_wb_we_o      <= 1'b0;
                        sram_dest_addr <= sram_dest_addr + 32'd4;
                        if (bytes_remaining == 16'd0) begin
                            state <= SPI_FINISH;
                        end else begin
                            state <= SPI_READ_BYTE;
                        end
                    end
                end

                SPI_FINISH: begin
                    spi_cs_n <= 1'b1;
                    reg_busy <= 1'b0;
                    state    <= SPI_IDLE;
                end

                default: state <= SPI_IDLE;
            endcase
        end
    end

    assign spi_irq = reg_done;

endmodule
