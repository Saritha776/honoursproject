// ==============================================================================
// Module: pe.sv
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: Processing Element (PE) for 2D Weight-Stationary Systolic Array.
//              - INT8 x INT8 signed multiplication with 32-bit accumulation.
//              - Signed saturation logic (clamps at +2^31-1 and -2^31).
//              - Horizontal activation forwarding and vertical partial-sum forwarding.
// ==============================================================================

`timescale 1ns / 1ps

module pe (
    input  logic        clk,
    input  logic        rst_n,
    
    // Control
    input  logic        load_weight,
    input  logic        clear_acc,
    input  logic        valid_in,
    
    // Data Inputs
    input  logic signed [7:0]  act_in,      // From West
    input  logic signed [7:0]  wgt_in,      // Weight load port
    input  logic signed [31:0] psum_in,     // From North
    
    // Outputs
    output logic signed [7:0]  act_out,     // To East
    output logic        valid_out,   // To East
    output logic signed [31:0] psum_out,    // To South
    output logic        overflow     // Saturation indicator
);

    // Internal Registers
    logic signed [7:0]  w_reg;
    logic signed [7:0]  a_reg;
    logic signed [31:0] p_reg;
    logic               v_reg;
    logic               ovf_reg;

    // Multiplier & Saturation intermediate signals
    logic signed [15:0] mult_product;
    logic signed [32:0] psum_next_wide; // 33-bit for overflow detection

    // Multiplier: Signed 8-bit x Signed 8-bit
    assign mult_product = valid_in ? (act_in * w_reg) : 16'sh0000;

    // 33-bit Addition
    assign psum_next_wide = clear_acc ? 
        (33'(signed'({{16{mult_product[15]}}, mult_product}))) : 
        (33'(signed'(psum_in)) + 33'(signed'({{16{mult_product[15]}}, mult_product})));

    // Sequential update
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_reg       <= 8'sh00;
            a_reg       <= 8'sh00;
            p_reg       <= 32'sh0000_0000;
            v_reg       <= 1'b0;
            ovf_reg     <= 1'b0;
        end else begin
            // Weight loading
            if (load_weight) begin
                w_reg <= wgt_in;
                // $display("[PE @ %0t] loaded w_reg = %0d", $time, wgt_in);
            end

            // Activation forwarding
            a_reg <= act_in;
            v_reg <= valid_in;

            // Partial sum accumulation with saturation
            if (clear_acc && !valid_in) begin
                p_reg   <= 32'sh0000_0000;
                ovf_reg <= 1'b0;
            end else if (valid_in || psum_in != 32'sh0000_0000) begin
                if (psum_next_wide > 33'sh0_7FFF_FFFF) begin
                    p_reg   <= 32'sh7FFF_FFFF;
                    ovf_reg <= 1'b1;
                end else if (psum_next_wide < -33'sh0_8000_0000) begin
                    p_reg   <= 32'sh8000_0000;
                    ovf_reg <= 1'b1;
                end else begin
                    p_reg   <= psum_next_wide[31:0];
                end
            end
        end
    end

    assign act_out   = a_reg;
    assign valid_out = v_reg;
    assign psum_out  = p_reg;
    assign overflow  = ovf_reg;

endmodule
