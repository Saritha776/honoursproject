// ==============================================================================
// Module: systolic_array_4x4.sv
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: 4x4 Weight-Stationary (WS) Systolic Array with skewed activation
//              injection, memory-mapped registers, direct DMA streaming port,
//              and 32-bit saturating output accumulation.
// Base Address: 0x4000_2000
// ==============================================================================

`timescale 1ns / 1ps

module systolic_array_4x4 (
    input  logic        clk,
    input  logic        rst_n,
    
    // Wishbone / Interconnect Slave Interface
    input  logic [31:0] wb_adr_i,
    input  logic [31:0] wb_dat_i,
    output logic [31:0] wb_dat_o,
    input  logic        wb_we_i,
    input  logic        wb_stb_i,
    input  logic        wb_cyc_i,
    output logic        wb_ack_o,
    
    // Direct DMA Streaming Interface
    input  logic        dma_act_valid,
    input  logic [31:0] dma_act_data,
    input  logic        dma_wgt_valid,
    input  logic [31:0] dma_wgt_data,
    
    // Interrupt Output
    output logic        array_irq
);

    // Register Offsets
    localparam REG_CTRL        = 8'h00;
    localparam REG_STATUS      = 8'h04;
    localparam REG_CFG         = 8'h08;
    localparam REG_WEIGHT_PORT = 8'h10;
    localparam REG_ACT_PORT    = 8'h14;
    localparam REG_RES_0       = 8'h20;
    localparam REG_RES_1       = 8'h24;
    localparam REG_RES_2       = 8'h28;
    localparam REG_RES_3       = 8'h2C;

    // Control & Status Registers
    logic        reg_en;
    logic        reg_start;
    logic        reg_busy;
    logic        reg_done;
    logic        reg_overflow;
    logic [1:0]  reg_mode;
    logic [3:0]  reg_dim;
    logic        reg_clear_acc;

    // Weight buffer index for sequential loading (16 weights = 4 words of 4 bytes)
    logic [1:0]  wgt_load_row;
    logic        wgt_load_strobe;
    logic [31:0] wgt_write_data;

    // Direct Port Inputs
    logic        act_strobe;
    logic [31:0] act_write_data;

    // Output Result Registers
    logic signed [31:0] res_reg [0:3];

    // Compute pipeline state machine
    typedef enum logic [2:0] {
        IDLE        = 3'b000,
        LOAD_WGT    = 3'b001,
        FEED_SKEW   = 3'b010,
        COMPUTE     = 3'b011,
        DRAIN       = 3'b100,
        FINISH      = 3'b101
    } state_t;

    state_t state;
    logic [3:0] cycle_cnt;

    // PE Interconnect Wires
    logic signed [7:0]  pe_act_h   [0:3][0:4];  // Horizontal activation links
    logic               pe_val_h   [0:3][0:4];  // Horizontal valid links
    logic signed [31:0] pe_psum_v  [0:4][0:3];  // Vertical partial-sum links
    logic               pe_ovf     [0:3][0:3];  // Individual PE overflow flags
    logic               pe_load_w  [0:3][0:3];  // Weight load enables
    logic signed [7:0]  pe_wgt_val [0:3][0:3];  // Weight input buses

    // Skewing / Stagger Delay Line for Activations:
    // Row 0: Skew 0
    // Row 1: Skew 1 (1 stage)
    // Row 2: Skew 2 (2 stages)
    // Row 3: Skew 3 (3 stages)
    logic signed [7:0] skew_r1_d1;
    logic              skew_r1_v1;

    logic signed [7:0] skew_r2_d1, skew_r2_d2;
    logic              skew_r2_v1, skew_r2_v2;

    logic signed [7:0] skew_r3_d1, skew_r3_d2, skew_r3_d3;
    logic              skew_r3_v1, skew_r3_v2, skew_r3_v3;

    // Unpack Activations from Port or DMA
    logic signed [7:0] raw_act [0:3];
    logic              raw_valid;

    assign raw_valid      = act_strobe || dma_act_valid;
    assign raw_act[0]     = act_strobe ? wb_dat_i[7:0]   : dma_act_data[7:0];
    assign raw_act[1]     = act_strobe ? wb_dat_i[15:8]  : dma_act_data[15:8];
    assign raw_act[2]     = act_strobe ? wb_dat_i[23:16] : dma_act_data[23:16];
    assign raw_act[3]     = act_strobe ? wb_dat_i[31:24] : dma_act_data[31:24];

    // Skew Delay Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            skew_r1_d1 <= 8'sh00; skew_r1_v1 <= 1'b0;
            skew_r2_d1 <= 8'sh00; skew_r2_d2 <= 8'sh00; skew_r2_v1 <= 1'b0; skew_r2_v2 <= 1'b0;
            skew_r3_d1 <= 8'sh00; skew_r3_d2 <= 8'sh00; skew_r3_d3 <= 8'sh00;
            skew_r3_v1 <= 1'b0;   skew_r3_v2 <= 1'b0;   skew_r3_v3 <= 1'b0;
        end else begin
            // Row 1 delay (1 cycle)
            skew_r1_d1 <= raw_act[1];
            skew_r1_v1 <= raw_valid;

            // Row 2 delay (2 cycles)
            skew_r2_d1 <= raw_act[2];
            skew_r2_v1 <= raw_valid;
            skew_r2_d2 <= skew_r2_d1;
            skew_r2_v2 <= skew_r2_v1;

            // Row 3 delay (3 cycles)
            skew_r3_d1 <= raw_act[3];
            skew_r3_v1 <= raw_valid;
            skew_r3_d2 <= skew_r3_d1;
            skew_r3_v2 <= skew_r3_v1;
            skew_r3_d3 <= skew_r3_d2;
            skew_r3_v3 <= skew_r3_v2;
        end
    end

    // Boundary Inputs to the PE Array
    assign pe_act_h[0][0] = raw_act[0];
    assign pe_val_h[0][0] = raw_valid;

    assign pe_act_h[1][0] = skew_r1_d1;
    assign pe_val_h[1][0] = skew_r1_v1;

    assign pe_act_h[2][0] = skew_r2_d2;
    assign pe_val_h[2][0] = skew_r2_v2;

    assign pe_act_h[3][0] = skew_r3_d3;
    assign pe_val_h[3][0] = skew_r3_v3;

    // Northern Boundary Partial Sums initialize to 0
    genvar col;
    generate
        for (col = 0; col < 4; col = col + 1) begin : gen_north_boundary
            assign pe_psum_v[0][col] = 32'sh0000_0000;
        end
    endgenerate

    // Instantiate 4x4 PE Grid
    genvar r, c;
    generate
        for (r = 0; r < 4; r = r + 1) begin : gen_pe_rows
            for (c = 0; c < 4; c = c + 1) begin : gen_pe_cols
                // Weight load mapping
                assign pe_load_w[r][c]  = wgt_load_strobe && (wgt_load_row == r[1:0]);
                assign pe_wgt_val[r][c] = (c == 0) ? wgt_write_data[7:0]   :
                                          (c == 1) ? wgt_write_data[15:8]  :
                                          (c == 2) ? wgt_write_data[23:16] :
                                                     wgt_write_data[31:24];

                pe u_pe (
                    .clk        (clk),
                    .rst_n      (rst_n),
                    .load_weight(pe_load_w[r][c]),
                    .clear_acc  (reg_clear_acc),
                    .valid_in   (pe_val_h[r][c]),
                    .act_in     (pe_act_h[r][c]),
                    .wgt_in     (pe_wgt_val[r][c]),
                    .psum_in    (pe_psum_v[r][c]),
                    .act_out    (pe_act_h[r][c+1]),
                    .valid_out  (pe_val_h[r][c+1]),
                    .psum_out   (pe_psum_v[r+1][c]),
                    .overflow   (pe_ovf[r][c])
                );
            end
        end
    endgenerate

    // Weight Port selection
    assign wgt_load_strobe = (wb_stb_i && wb_cyc_i && wb_we_i && !wb_ack_o && (wb_adr_i[7:0] == REG_WEIGHT_PORT)) || dma_wgt_valid;
    assign wgt_write_data  = dma_wgt_valid ? dma_wgt_data : wb_dat_i;

    // Activation Port selection
    assign act_strobe = wb_stb_i && wb_cyc_i && wb_we_i && !wb_ack_o && (wb_adr_i[7:0] == REG_ACT_PORT);

    // Any overflow in PE array?
    logic any_overflow;
    always_comb begin
        any_overflow = 1'b0;
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                any_overflow = any_overflow | pe_ovf[i][j];
            end
        end
    end

    // Computation Sequencing and Result Latching
    // Latency = 2N - 1 = 7 clock cycles for 4x4 matrix-vector multiplication pass
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            cycle_cnt    <= 4'd0;
            reg_busy     <= 1'b0;
            reg_done     <= 1'b0;
            reg_overflow <= 1'b0;
            wgt_load_row <= 2'd0;
            for (int i = 0; i < 4; i++) begin
                res_reg[i] <= 32'sh0000_0000;
            end
        end else begin
            // Weight buffer counter advance
            if (wgt_load_strobe) begin
                wgt_load_row <= wgt_load_row + 1'b1;
            end

            // Accumulate sticky overflow
            if (any_overflow) begin
                reg_overflow <= 1'b1;
            end

            // Compute Sequencing FSM
            case (state)
                IDLE: begin
                    if (reg_en && (reg_start || raw_valid)) begin
                        state     <= COMPUTE;
                        reg_busy  <= 1'b1;
                        cycle_cnt <= 4'd0;
                    end
                end

                COMPUTE: begin
                    // Latch each column result at its exact arrival cycle (3 + column index)
                    if (cycle_cnt == 4'd3) res_reg[0] <= pe_psum_v[4][0];
                    if (cycle_cnt == 4'd4) res_reg[1] <= pe_psum_v[4][1];
                    if (cycle_cnt == 4'd5) res_reg[2] <= pe_psum_v[4][2];
                    if (cycle_cnt >= 4'd6) begin
                        res_reg[3] <= pe_psum_v[4][3];
                        reg_done   <= 1'b1;
                        reg_busy   <= 1'b0;
                        state      <= IDLE;
                    end else begin
                        cycle_cnt <= cycle_cnt + 1'b1;
                    end
                end

                default: state <= IDLE;
            endcase

            // Register Clear & W1C overrides
            if (wb_stb_i && wb_cyc_i && wb_we_i) begin
                if (wb_adr_i[7:0] == REG_STATUS) begin
                    if (wb_dat_i[1]) reg_done     <= 1'b0;
                    if (wb_dat_i[2]) reg_overflow <= 1'b0;
                end
            end
        end
    end

    // Wishbone Register Access & Control
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_en        <= 1'b0;
            reg_start     <= 1'b0;
            reg_clear_acc <= 1'b0;
            reg_mode      <= 2'b00;
            reg_dim       <= 4'd4;
            wb_ack_o      <= 1'b0;
            wb_dat_o      <= 32'h0000_0000;
        end else begin
            wb_ack_o      <= 1'b0;
            reg_start     <= 1'b0;
            reg_clear_acc <= 1'b0;

            if (wb_stb_i && wb_cyc_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;
                if (wb_we_i) begin
                    case (wb_adr_i[7:0])
                        REG_CTRL: begin
                            reg_en        <= wb_dat_i[0];
                            reg_start     <= wb_dat_i[1];
                            reg_clear_acc <= wb_dat_i[2];
                        end
                        REG_CFG: begin
                            reg_mode <= wb_dat_i[1:0];
                            reg_dim  <= wb_dat_i[7:4];
                        end
                        default: ;
                    endcase
                end else begin
                    // Read Register
                    case (wb_adr_i[7:0])
                        REG_CTRL:   wb_dat_o <= {29'b0, reg_clear_acc, reg_start, reg_en};
                        REG_STATUS: wb_dat_o <= {29'b0, reg_overflow, reg_done, reg_busy};
                        REG_CFG:    wb_dat_o <= {24'b0, reg_dim, 2'b0, reg_mode};
                        REG_RES_0:  wb_dat_o <= res_reg[0];
                        REG_RES_1:  wb_dat_o <= res_reg[1];
                        REG_RES_2:  wb_dat_o <= res_reg[2];
                        REG_RES_3:  wb_dat_o <= res_reg[3];
                        default:    wb_dat_o <= 32'h0000_0000;
                    endcase
                end
            end
        end
    end

    // Array interrupt asserts when done and remains level-held until status is cleared
    assign array_irq = reg_done;

endmodule
