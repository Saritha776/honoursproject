// ==============================================================================
// Module: axi4_to_wishbone.sv
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: Bridge converting 64-bit AXI4 Master requests from VeeR EL2
//              into 32-bit Pipelined Wishbone B4 transactions.
// ==============================================================================

`timescale 1ns / 1ps

module axi4_to_wishbone #(
    parameter ID_WIDTH = 8
)(
    input  logic        clk,
    input  logic        rst_n,

    // AXI4 Write Address Channel
    input  logic [ID_WIDTH-1:0] s_axi_awid,
    input  logic [31:0]         s_axi_awaddr,
    input  logic [7:0]          s_axi_awlen,
    input  logic [2:0]          s_axi_awsize,
    input  logic [1:0]          s_axi_awburst,
    input  logic                s_axi_awvalid,
    output logic                s_axi_awready,

    // AXI4 Write Data Channel
    input  logic [63:0]         s_axi_wdata,
    input  logic [7:0]          s_axi_wstrb,
    input  logic                s_axi_wlast,
    input  logic                s_axi_wvalid,
    output logic                s_axi_wready,

    // AXI4 Write Response Channel
    output logic [ID_WIDTH-1:0] s_axi_bid,
    output logic [1:0]          s_axi_bresp,
    output logic                s_axi_bvalid,
    input  logic                s_axi_bready,

    // AXI4 Read Address Channel
    input  logic [ID_WIDTH-1:0] s_axi_arid,
    input  logic [31:0]         s_axi_araddr,
    input  logic [7:0]          s_axi_arlen,
    input  logic [2:0]          s_axi_arsize,
    input  logic [1:0]          s_axi_arburst,
    input  logic                s_axi_arvalid,
    output logic                s_axi_arready,

    // AXI4 Read Data Channel
    output logic [ID_WIDTH-1:0] s_axi_rid,
    output logic [63:0]         s_axi_rdata,
    output logic [1:0]          s_axi_rresp,
    output logic                s_axi_rlast,
    output logic                s_axi_rvalid,
    input  logic                s_axi_rready,

    // Wishbone Master Interface
    output logic [31:0]         m_wb_adr_o,
    output logic [31:0]         m_wb_dat_o,
    input  logic [31:0]         m_wb_dat_i,
    output logic [3:0]          m_wb_sel_o,
    output logic                m_wb_we_o,
    output logic                m_wb_stb_o,
    output logic                m_wb_cyc_o,
    input  logic                m_wb_ack_i,
    input  logic                m_wb_err_i
);

    typedef enum logic [2:0] {
        ST_IDLE     = 3'b000,
        ST_WRITE_WB = 3'b001,
        ST_WRITE_RSP= 3'b010,
        ST_READ_WB  = 3'b011,
        ST_READ_RSP = 3'b100
    } bridge_state_t;

    bridge_state_t state;

    logic [ID_WIDTH-1:0] reg_id;
    logic [31:0]         reg_addr;
    logic [63:0]         reg_wdata;
    logic [7:0]          reg_wstrb;
    logic [31:0]         reg_rdata;
    logic [1:0]          reg_resp;

    // 64-bit to 32-bit muxing based on addr[2]
    wire is_upper_word = reg_addr[2];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= ST_IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bid     <= '0;
            s_axi_bresp   <= 2'b00;
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rid     <= '0;
            s_axi_rdata   <= 64'd0;
            s_axi_rresp   <= 2'b00;
            s_axi_rlast   <= 1'b0;
            m_wb_adr_o    <= 32'd0;
            m_wb_dat_o    <= 32'd0;
            m_wb_sel_o    <= 4'b1111;
            m_wb_we_o     <= 1'b0;
            m_wb_stb_o    <= 1'b0;
            m_wb_cyc_o    <= 1'b0;
            reg_id        <= '0;
            reg_addr      <= 32'd0;
            reg_wdata     <= 64'd0;
            reg_wstrb     <= 8'd0;
            reg_rdata     <= 32'd0;
            reg_resp      <= 2'b00;
        end else begin
            case (state)
                ST_IDLE: begin
                    s_axi_bvalid <= 1'b0;
                    s_axi_rvalid <= 1'b0;
                    m_wb_cyc_o   <= 1'b0;
                    m_wb_stb_o   <= 1'b0;

                    // Prioritize Write if both address & data valid
                    if (s_axi_awvalid && s_axi_wvalid) begin
                        s_axi_awready <= 1'b1;
                        s_axi_wready  <= 1'b1;
                        reg_id        <= s_axi_awid;
                        reg_addr      <= s_axi_awaddr;
                        reg_wdata     <= s_axi_wdata;
                        reg_wstrb     <= s_axi_wstrb;

                        // Issue Wishbone Write
                        m_wb_adr_o <= s_axi_awaddr;
                        m_wb_dat_o <= s_axi_awaddr[2] ? s_axi_wdata[63:32] : s_axi_wdata[31:0];
                        m_wb_sel_o <= s_axi_awaddr[2] ? s_axi_wstrb[7:4]   : s_axi_wstrb[3:0];
                        m_wb_we_o  <= 1'b1;
                        m_wb_cyc_o <= 1'b1;
                        m_wb_stb_o <= 1'b1;
                        state      <= ST_WRITE_WB;
                    end else if (s_axi_arvalid) begin
                        s_axi_arready <= 1'b1;
                        reg_id        <= s_axi_arid;
                        reg_addr      <= s_axi_araddr;

                        // Issue Wishbone Read
                        m_wb_adr_o <= s_axi_araddr;
                        m_wb_sel_o <= 4'b1111;
                        m_wb_we_o  <= 1'b0;
                        m_wb_cyc_o <= 1'b1;
                        m_wb_stb_o <= 1'b1;
                        state      <= ST_READ_WB;
                    end
                end

                ST_WRITE_WB: begin
                    s_axi_awready <= 1'b0;
                    s_axi_wready  <= 1'b0;

                    if (m_wb_ack_i || m_wb_err_i) begin
                        m_wb_cyc_o   <= 1'b0;
                        m_wb_stb_o   <= 1'b0;
                        m_wb_we_o    <= 1'b0;
                        s_axi_bid    <= reg_id;
                        s_axi_bresp  <= m_wb_err_i ? 2'b10 : 2'b00; // SLVERR on wb_err
                        s_axi_bvalid <= 1'b1;
                        state        <= ST_WRITE_RSP;
                    end
                end

                ST_WRITE_RSP: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        state        <= ST_IDLE;
                    end
                end

                ST_READ_WB: begin
                    s_axi_arready <= 1'b0;

                    if (m_wb_ack_i || m_wb_err_i) begin
                        m_wb_cyc_o   <= 1'b0;
                        m_wb_stb_o   <= 1'b0;
                        s_axi_rid    <= reg_id;
                        s_axi_rdata  <= {m_wb_dat_i, m_wb_dat_i}; // Duplicate 32-bit into both words
                        s_axi_rresp  <= m_wb_err_i ? 2'b10 : 2'b00;
                        s_axi_rlast  <= 1'b1;
                        s_axi_rvalid <= 1'b1;
                        state        <= ST_READ_RSP;
                    end
                end

                ST_READ_RSP: begin
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        s_axi_rlast  <= 1'b0;
                        state        <= ST_IDLE;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
