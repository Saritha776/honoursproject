// ==============================================================================
// Module: dma_controller.sv
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: Dual-Channel Direct Memory Access (DMA) streaming controller.
//              - Channel 0: Moves activation vectors from Data SRAM to Systolic Array.
//              - Channel 1: Moves weight matrices from Data SRAM to Systolic Array.
//              - Master Wishbone interface for reading SRAM.
//              - Direct streaming port outputs to Systolic Array.
// Base Address: 0x4000_1000
// ==============================================================================

`timescale 1ns / 1ps

module dma_controller (
    input  logic        clk,
    input  logic        rst_n,
    
    // Wishbone Slave Interface (Register configuration from CPU)
    input  logic [31:0] s_wb_adr_i,
    input  logic [31:0] s_wb_dat_i,
    output logic [31:0] s_wb_dat_o,
    input  logic        s_wb_we_i,
    input  logic        s_wb_stb_i,
    input  logic        s_wb_cyc_i,
    output logic        s_wb_ack_o,
    
    // Wishbone Master Interface (Reading from SRAM)
    output logic [31:0] m_wb_adr_o,
    output logic [31:0] m_wb_dat_o,
    input  logic [31:0] m_wb_dat_i,
    output logic        m_wb_we_o,
    output logic        m_wb_stb_o,
    output logic        m_wb_cyc_o,
    input  logic        m_wb_ack_i,
    input  logic        m_wb_err_i,
    
    // Direct Streaming Ports to Systolic Array
    output logic        dma_act_valid,
    output logic [31:0] dma_act_data,
    output logic        dma_wgt_valid,
    output logic [31:0] dma_wgt_data,
    
    // Interrupt Output
    output logic        dma_irq
);

    // Register Offsets
    localparam REG_DMA_CTRL    = 8'h00;
    localparam REG_DMA_STATUS  = 8'h04;
    localparam REG_DMA_CH0_SRC = 8'h10;
    localparam REG_DMA_CH0_DST = 8'h14;
    localparam REG_DMA_CH0_LEN = 8'h18;
    localparam REG_DMA_CH1_SRC = 8'h20;
    localparam REG_DMA_CH1_DST = 8'h24;
    localparam REG_DMA_CH1_LEN = 8'h28;

    // Registers
    logic        reg_dma_en;
    logic        reg_ch0_en;
    logic        reg_ch1_en;
    logic        reg_busy;
    logic        reg_ch0_done;
    logic        reg_ch1_done;
    logic        reg_err;

    logic [31:0] reg_ch0_src, reg_ch0_dst;
    logic [15:0] reg_ch0_len, cur_ch0_cnt;
    logic [31:0] cur_ch0_addr;

    logic [31:0] reg_ch1_src, reg_ch1_dst;
    logic [15:0] reg_ch1_len, cur_ch1_cnt;
    logic [31:0] cur_ch1_addr;

    // DMA Master State Machine
    typedef enum logic [2:0] {
        DMA_IDLE      = 3'b000,
        DMA_CH1_READ  = 3'b001,
        DMA_CH1_STREAM= 3'b010,
        DMA_CH0_READ  = 3'b011,
        DMA_CH0_STREAM= 3'b100,
        DMA_ERROR     = 3'b101
    } dma_state_t;

    dma_state_t state;

    // Master bus outputs default
    assign m_wb_we_o  = 1'b0; // DMA only reads from memory
    assign m_wb_dat_o = 32'h0000_0000;

    // Register Read/Write logic (Slave Interface)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_dma_en   <= 1'b0;
            reg_ch0_en   <= 1'b0;
            reg_ch1_en   <= 1'b0;
            reg_ch0_done <= 1'b0;
            reg_ch1_done <= 1'b0;
            reg_err      <= 1'b0;
            reg_ch0_src  <= 32'h0000_0000;
            reg_ch0_dst  <= 32'h4000_2014; // Default ARRAY_ACT_PORT
            reg_ch0_len  <= 16'h0000;
            reg_ch1_src  <= 32'h0000_0000;
            reg_ch1_dst  <= 32'h4000_2010; // Default ARRAY_WEIGHT_PORT
            reg_ch1_len  <= 16'h0000;
            s_wb_ack_o   <= 1'b0;
            s_wb_dat_o   <= 32'h0000_0000;
        end else begin
            s_wb_ack_o <= 1'b0;

            if (s_wb_stb_i && s_wb_cyc_i && !s_wb_ack_o) begin
                s_wb_ack_o <= 1'b1;
                if (s_wb_we_i) begin
                    case (s_wb_adr_i[7:0])
                        REG_DMA_CTRL: begin
                            reg_dma_en <= s_wb_dat_i[0];
                            reg_ch0_en <= s_wb_dat_i[1];
                            reg_ch1_en <= s_wb_dat_i[2];
                        end
                        REG_DMA_STATUS: begin
                            if (s_wb_dat_i[1]) reg_ch0_done <= 1'b0;
                            if (s_wb_dat_i[2]) reg_ch1_done <= 1'b0;
                            if (s_wb_dat_i[8]) reg_err      <= 1'b0;
                        end
                        REG_DMA_CH0_SRC: reg_ch0_src <= s_wb_dat_i;
                        REG_DMA_CH0_DST: reg_ch0_dst <= s_wb_dat_i;
                        REG_DMA_CH0_LEN: reg_ch0_len <= s_wb_dat_i[15:0];
                        REG_DMA_CH1_SRC: reg_ch1_src <= s_wb_dat_i;
                        REG_DMA_CH1_DST: reg_ch1_dst <= s_wb_dat_i;
                        REG_DMA_CH1_LEN: reg_ch1_len <= s_wb_dat_i[15:0];
                        default: ;
                    endcase
                end else begin
                    case (s_wb_adr_i[7:0])
                        REG_DMA_CTRL:    s_wb_dat_o <= {29'b0, reg_ch1_en, reg_ch0_en, reg_dma_en};
                        REG_DMA_STATUS:  s_wb_dat_o <= {23'b0, reg_err, 5'b0, reg_ch1_done, reg_ch0_done, reg_busy};
                        REG_DMA_CH0_SRC: s_wb_dat_o <= reg_ch0_src;
                        REG_DMA_CH0_DST: s_wb_dat_o <= reg_ch0_dst;
                        REG_DMA_CH0_LEN: s_wb_dat_o <= {16'b0, reg_ch0_len};
                        REG_DMA_CH1_SRC: s_wb_dat_o <= reg_ch1_src;
                        REG_DMA_CH1_DST: s_wb_dat_o <= reg_ch1_dst;
                        REG_DMA_CH1_LEN: s_wb_dat_o <= {16'b0, reg_ch1_len};
                        default:         s_wb_dat_o <= 32'h0000_0000;
                    endcase
                end
            end

            // Transfer Completion Signals from Master State Machine
            if (state == DMA_CH1_STREAM && cur_ch1_cnt == 16'd0) begin
                reg_ch1_done <= 1'b1;
                reg_ch1_en   <= 1'b0;
            end
            if (state == DMA_CH0_STREAM && cur_ch0_cnt == 16'd0) begin
                reg_ch0_done <= 1'b1;
                reg_ch0_en   <= 1'b0;
            end
            if (state == DMA_ERROR) begin
                reg_err <= 1'b1;
            end
        end
    end

    // DMA Master Engine FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= DMA_IDLE;
            reg_busy      <= 1'b0;
            m_wb_adr_o    <= 32'h0000_0000;
            m_wb_stb_o    <= 1'b0;
            m_wb_cyc_o    <= 1'b0;
            dma_act_valid <= 1'b0;
            dma_act_data  <= 32'h0000_0000;
            dma_wgt_valid <= 1'b0;
            dma_wgt_data  <= 32'h0000_0000;
            cur_ch0_cnt   <= 16'd0;
            cur_ch1_cnt   <= 16'd0;
            cur_ch0_addr  <= 32'h0000_0000;
            cur_ch1_addr  <= 32'h0000_0000;
        end else begin
            dma_act_valid <= 1'b0;
            dma_wgt_valid <= 1'b0;

            case (state)
                DMA_IDLE: begin
                    m_wb_stb_o <= 1'b0;
                    m_wb_cyc_o <= 1'b0;
                    if (reg_dma_en) begin
                        // Channel 1 (Weights preloading) has priority
                        if (reg_ch1_en && reg_ch1_len > 0) begin
                            // Check 4-byte alignment
                            if (reg_ch1_src[1:0] != 2'b00) begin
                                state <= DMA_ERROR;
                            end else begin
                                cur_ch1_cnt  <= reg_ch1_len;
                                cur_ch1_addr <= reg_ch1_src;
                                m_wb_adr_o   <= reg_ch1_src;
                                m_wb_cyc_o   <= 1'b1;
                                m_wb_stb_o   <= 1'b1;
                                reg_busy     <= 1'b1;
                                state        <= DMA_CH1_READ;
                            end
                        end else if (reg_ch0_en && reg_ch0_len > 0) begin
                            // Check 4-byte alignment
                            if (reg_ch0_src[1:0] != 2'b00) begin
                                state <= DMA_ERROR;
                            end else begin
                                cur_ch0_cnt  <= reg_ch0_len;
                                cur_ch0_addr <= reg_ch0_src;
                                m_wb_adr_o   <= reg_ch0_src;
                                m_wb_cyc_o   <= 1'b1;
                                m_wb_stb_o   <= 1'b1;
                                reg_busy     <= 1'b1;
                                state        <= DMA_CH0_READ;
                            end
                        end else begin
                            reg_busy <= 1'b0;
                        end
                    end else begin
                        reg_busy <= 1'b0;
                    end
                end

                DMA_CH1_READ: begin
                    if (m_wb_err_i) begin
                        m_wb_cyc_o <= 1'b0;
                        m_wb_stb_o <= 1'b0;
                        state      <= DMA_ERROR;
                    end else if (m_wb_ack_i) begin
                        m_wb_cyc_o    <= 1'b0;
                        m_wb_stb_o    <= 1'b0;
                        dma_wgt_valid <= 1'b1;
                        dma_wgt_data  <= m_wb_dat_i;
                        cur_ch1_addr  <= cur_ch1_addr + 32'd4;
                        cur_ch1_cnt   <= cur_ch1_cnt - 1'b1;
                        state         <= DMA_CH1_STREAM;
                    end
                end

                DMA_CH1_STREAM: begin
                    if (cur_ch1_cnt > 0) begin
                        m_wb_adr_o <= cur_ch1_addr;
                        m_wb_cyc_o <= 1'b1;
                        m_wb_stb_o <= 1'b1;
                        state      <= DMA_CH1_READ;
                    end else begin
                        state <= DMA_IDLE;
                    end
                end

                DMA_CH0_READ: begin
                    if (m_wb_err_i) begin
                        m_wb_cyc_o <= 1'b0;
                        m_wb_stb_o <= 1'b0;
                        state      <= DMA_ERROR;
                    end else if (m_wb_ack_i) begin
                        m_wb_cyc_o    <= 1'b0;
                        m_wb_stb_o    <= 1'b0;
                        dma_act_valid <= 1'b1;
                        dma_act_data  <= m_wb_dat_i;
                        cur_ch0_addr  <= cur_ch0_addr + 32'd4;
                        cur_ch0_cnt   <= cur_ch0_cnt - 1'b1;
                        state         <= DMA_CH0_STREAM;
                    end
                end

                DMA_CH0_STREAM: begin
                    if (cur_ch0_cnt > 0) begin
                        m_wb_adr_o <= cur_ch0_addr;
                        m_wb_cyc_o <= 1'b1;
                        m_wb_stb_o <= 1'b1;
                        state      <= DMA_CH0_READ;
                    end else begin
                        state <= DMA_IDLE;
                    end
                end

                DMA_ERROR: begin
                    m_wb_cyc_o <= 1'b0;
                    m_wb_stb_o <= 1'b0;
                    reg_busy   <= 1'b0;
                    state      <= DMA_IDLE;
                end

                default: state <= DMA_IDLE;
            endcase
        end
    end

    // DMA interrupt asserts on channel done or error
    assign dma_irq = reg_ch0_done | reg_ch1_done | reg_err;

endmodule
