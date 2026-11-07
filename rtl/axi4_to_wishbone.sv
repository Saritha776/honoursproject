// ==============================================================================
// Module: axi4_to_wishbone.sv
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: High-performance Dual-Channel 64-bit AXI4 to 32-bit Wishbone B4 Bridge.
//              Arbitrates between VeeR EL2 IFU (Instruction Fetch) and LSU (Load/Store)
//              masters, correctly sequencing 2x 32-bit Wishbone transfers for 64-bit
//              quadword fetches and writes.
// ==============================================================================

`timescale 1ns / 1ps

module axi4_to_wishbone #(
    parameter LSU_ID_WIDTH = 8,
    parameter IFU_ID_WIDTH = 3
)(
    input  logic        clk,
    input  logic        rst_n,

    // -------------------------------------------------------------------------
    // Port 0: LSU AXI4 Master (Full Read/Write)
    // -------------------------------------------------------------------------
    input  logic [LSU_ID_WIDTH-1:0] lsu_axi_awid,
    input  logic [31:0]             lsu_axi_awaddr,
    input  logic [7:0]              lsu_axi_awlen,
    input  logic [2:0]              lsu_axi_awsize,
    input  logic [1:0]              lsu_axi_awburst,
    input  logic                    lsu_axi_awvalid,
    output logic                    lsu_axi_awready,

    input  logic [63:0]             lsu_axi_wdata,
    input  logic [7:0]              lsu_axi_wstrb,
    input  logic                    lsu_axi_wlast,
    input  logic                    lsu_axi_wvalid,
    output logic                    lsu_axi_wready,

    output logic [LSU_ID_WIDTH-1:0] lsu_axi_bid,
    output logic [1:0]              lsu_axi_bresp,
    output logic                    lsu_axi_bvalid,
    input  logic                    lsu_axi_bready,

    input  logic [LSU_ID_WIDTH-1:0] lsu_axi_arid,
    input  logic [31:0]             lsu_axi_araddr,
    input  logic [7:0]              lsu_axi_arlen,
    input  logic [2:0]              lsu_axi_arsize,
    input  logic [1:0]              lsu_axi_arburst,
    input  logic                    lsu_axi_arvalid,
    output logic                    lsu_axi_arready,

    output logic [LSU_ID_WIDTH-1:0] lsu_axi_rid,
    output logic [63:0]             lsu_axi_rdata,
    output logic [1:0]              lsu_axi_rresp,
    output logic                    lsu_axi_rlast,
    output logic                    lsu_axi_rvalid,
    input  logic                    lsu_axi_rready,

    // -------------------------------------------------------------------------
    // Port 1: IFU AXI4 Master (Read-Only)
    // -------------------------------------------------------------------------
    input  logic [IFU_ID_WIDTH-1:0] ifu_axi_arid,
    input  logic [31:0]             ifu_axi_araddr,
    input  logic [7:0]              ifu_axi_arlen,
    input  logic [2:0]              ifu_axi_arsize,
    input  logic [1:0]              ifu_axi_arburst,
    input  logic                    ifu_axi_arvalid,
    output logic                    ifu_axi_arready,

    output logic [IFU_ID_WIDTH-1:0] ifu_axi_rid,
    output logic [63:0]             ifu_axi_rdata,
    output logic [1:0]              ifu_axi_rresp,
    output logic                    ifu_axi_rlast,
    output logic                    ifu_axi_rvalid,
    input  logic                    ifu_axi_rready,

    // -------------------------------------------------------------------------
    // Wishbone Master Interface (to SoC Crossbar Interconnect)
    // -------------------------------------------------------------------------
    output logic [31:0]             m_wb_adr_o,
    output logic [31:0]             m_wb_dat_o,
    input  logic [31:0]             m_wb_dat_i,
    output logic [3:0]              m_wb_sel_o,
    output logic                    m_wb_we_o,
    output logic                    m_wb_stb_o,
    output logic                    m_wb_cyc_o,
    input  logic                    m_wb_ack_i,
    input  logic                    m_wb_err_i
);

    typedef enum logic [3:0] {
        ST_IDLE          = 4'd0,
        // LSU Write states
        ST_LSU_WR_BEAT0  = 4'd1,
        ST_LSU_WR_BEAT1  = 4'd2,
        ST_LSU_WR_RSP    = 4'd3,
        // LSU Read states
        ST_LSU_RD_BEAT0  = 4'd4,
        ST_LSU_RD_BEAT1  = 4'd5,
        ST_LSU_RD_RSP    = 4'd6,
        // IFU Read states
        ST_IFU_RD_BEAT0  = 4'd7,
        ST_IFU_RD_BEAT1  = 4'd8,
        ST_IFU_RD_RSP    = 4'd9
    } state_t;

    state_t state;

    // Registers to latch active transfer metadata
    logic [LSU_ID_WIDTH-1:0] reg_lsu_id;
    logic [31:0]             reg_lsu_addr;
    logic [63:0]             reg_lsu_wdata;
    logic [7:0]              reg_lsu_wstrb;
    logic [2:0]              reg_lsu_size;

    logic [IFU_ID_WIDTH-1:0] reg_ifu_id;
    logic [31:0]             reg_ifu_addr;

    logic [31:0]             reg_rdata_lo;
    logic                    err_flag;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state            <= ST_IDLE;
            lsu_axi_awready  <= 1'b0;
            lsu_axi_wready   <= 1'b0;
            lsu_axi_bvalid   <= 1'b0;
            lsu_axi_bid      <= '0;
            lsu_axi_bresp    <= 2'b00;
            lsu_axi_arready  <= 1'b0;
            lsu_axi_rvalid   <= 1'b0;
            lsu_axi_rid      <= '0;
            lsu_axi_rdata    <= 64'd0;
            lsu_axi_rresp    <= 2'b00;
            lsu_axi_rlast    <= 1'b0;

            ifu_axi_arready  <= 1'b0;
            ifu_axi_rvalid   <= 1'b0;
            ifu_axi_rid      <= '0;
            ifu_axi_rdata    <= 64'd0;
            ifu_axi_rresp    <= 2'b00;
            ifu_axi_rlast    <= 1'b0;

            m_wb_adr_o       <= 32'd0;
            m_wb_dat_o       <= 32'd0;
            m_wb_sel_o       <= 4'b0000;
            m_wb_we_o        <= 1'b0;
            m_wb_stb_o       <= 1'b0;
            m_wb_cyc_o       <= 1'b0;

            reg_lsu_id       <= '0;
            reg_lsu_addr     <= 32'd0;
            reg_lsu_wdata    <= 64'd0;
            reg_lsu_wstrb    <= 8'd0;
            reg_lsu_size     <= 3'd0;

            reg_ifu_id       <= '0;
            reg_ifu_addr     <= 32'd0;
            reg_rdata_lo     <= 32'd0;
            err_flag         <= 1'b0;
        end else begin
            case (state)
                ST_IDLE: begin
                    lsu_axi_awready <= 1'b0;
                    lsu_axi_wready  <= 1'b0;
                    lsu_axi_bvalid  <= 1'b0;
                    lsu_axi_arready <= 1'b0;
                    lsu_axi_rvalid  <= 1'b0;
                    ifu_axi_arready <= 1'b0;
                    ifu_axi_rvalid  <= 1'b0;
                    m_wb_cyc_o      <= 1'b0;
                    m_wb_stb_o      <= 1'b0;
                    m_wb_we_o       <= 1'b0;
                    err_flag        <= 1'b0;

                    // Priority 1: LSU Write Request
                    if (lsu_axi_awvalid && lsu_axi_wvalid) begin
                        lsu_axi_awready <= 1'b1;
                        lsu_axi_wready  <= 1'b1;
                        reg_lsu_id      <= lsu_axi_awid;
                        reg_lsu_addr    <= lsu_axi_awaddr;
                        reg_lsu_wdata   <= lsu_axi_wdata;
                        reg_lsu_wstrb   <= lsu_axi_wstrb;
                        reg_lsu_size    <= lsu_axi_awsize;

                        // Check if lower word has write strobes active
                        if (lsu_axi_wstrb[3:0] != 4'b0000) begin
                            m_wb_adr_o <= {lsu_axi_awaddr[31:3], 3'b000};
                            m_wb_dat_o <= lsu_axi_wdata[31:0];
                            m_wb_sel_o <= lsu_axi_wstrb[3:0];
                            m_wb_we_o  <= 1'b1;
                            m_wb_cyc_o <= 1'b1;
                            m_wb_stb_o <= 1'b1;
                            state      <= ST_LSU_WR_BEAT0;
                        end else begin
                            // Only upper 32-bit word active
                            m_wb_adr_o <= {lsu_axi_awaddr[31:3], 3'b100};
                            m_wb_dat_o <= lsu_axi_wdata[63:32];
                            m_wb_sel_o <= lsu_axi_wstrb[7:4];
                            m_wb_we_o  <= 1'b1;
                            m_wb_cyc_o <= 1'b1;
                            m_wb_stb_o <= 1'b1;
                            state      <= ST_LSU_WR_BEAT1;
                        end
                    // Priority 2: LSU Read Request
                    end else if (lsu_axi_arvalid) begin
                        lsu_axi_arready <= 1'b1;
                        reg_lsu_id      <= lsu_axi_arid;
                        reg_lsu_addr    <= lsu_axi_araddr;
                        reg_lsu_size    <= lsu_axi_arsize;

                        // If 64-bit read (arsize == 3'b011), start at word 0
                        if (lsu_axi_arsize == 3'b011) begin
                            m_wb_adr_o <= {lsu_axi_araddr[31:3], 3'b000};
                            m_wb_sel_o <= 4'b1111;
                            m_wb_we_o  <= 1'b0;
                            m_wb_cyc_o <= 1'b1;
                            m_wb_stb_o <= 1'b1;
                            state      <= ST_LSU_RD_BEAT0;
                        end else begin
                            // 32-bit or sub-word read: single beat
                            m_wb_adr_o <= lsu_axi_araddr;
                            m_wb_sel_o <= 4'b1111;
                            m_wb_we_o  <= 1'b0;
                            m_wb_cyc_o <= 1'b1;
                            m_wb_stb_o <= 1'b1;
                            state      <= ST_LSU_RD_BEAT1;
                        end
                    // Priority 3: IFU Instruction Read Request
                    end else if (ifu_axi_arvalid) begin
                        ifu_axi_arready <= 1'b1;
                        reg_ifu_id      <= ifu_axi_arid;
                        reg_ifu_addr    <= ifu_axi_araddr;

                        // Start 64-bit instruction fetch (beat 0: word at 0x0)
                        m_wb_adr_o <= {ifu_axi_araddr[31:3], 3'b000};
                        m_wb_sel_o <= 4'b1111;
                        m_wb_we_o  <= 1'b0;
                        m_wb_cyc_o <= 1'b1;
                        m_wb_stb_o <= 1'b1;
                        state      <= ST_IFU_RD_BEAT0;
                    end
                end

                // -------------------------------------------------------------
                // LSU Write Execution
                // -------------------------------------------------------------
                ST_LSU_WR_BEAT0: begin
                    lsu_axi_awready <= 1'b0;
                    lsu_axi_wready  <= 1'b0;

                    if (m_wb_ack_i || m_wb_err_i) begin
                        if (m_wb_err_i) err_flag <= 1'b1;

                        // Check if upper 32-bit word also needs to be written
                        if (reg_lsu_wstrb[7:4] != 4'b0000) begin
                            m_wb_adr_o <= {reg_lsu_addr[31:3], 3'b100};
                            m_wb_dat_o <= reg_lsu_wdata[63:32];
                            m_wb_sel_o <= reg_lsu_wstrb[7:4];
                            m_wb_we_o  <= 1'b1;
                            m_wb_cyc_o <= 1'b1;
                            m_wb_stb_o <= 1'b1;
                            state      <= ST_LSU_WR_BEAT1;
                        end else begin
                            m_wb_cyc_o     <= 1'b0;
                            m_wb_stb_o     <= 1'b0;
                            m_wb_we_o      <= 1'b0;
                            lsu_axi_bid    <= reg_lsu_id;
                            lsu_axi_bresp  <= (m_wb_err_i || err_flag) ? 2'b10 : 2'b00;
                            lsu_axi_bvalid <= 1'b1;
                            state          <= ST_LSU_WR_RSP;
                        end
                    end
                end

                ST_LSU_WR_BEAT1: begin
                    lsu_axi_awready <= 1'b0;
                    lsu_axi_wready  <= 1'b0;

                    if (m_wb_ack_i || m_wb_err_i) begin
                        m_wb_cyc_o     <= 1'b0;
                        m_wb_stb_o     <= 1'b0;
                        m_wb_we_o      <= 1'b0;
                        lsu_axi_bid    <= reg_lsu_id;
                        lsu_axi_bresp  <= (m_wb_err_i || err_flag) ? 2'b10 : 2'b00;
                        lsu_axi_bvalid <= 1'b1;
                        state          <= ST_LSU_WR_RSP;
                    end
                end

                ST_LSU_WR_RSP: begin
                    if (lsu_axi_bready) begin
                        lsu_axi_bvalid <= 1'b0;
                        state          <= ST_IDLE;
                    end
                end

                // -------------------------------------------------------------
                // LSU Read Execution
                // -------------------------------------------------------------
                ST_LSU_RD_BEAT0: begin
                    lsu_axi_arready <= 1'b0;

                    if (m_wb_ack_i || m_wb_err_i) begin
                        if (m_wb_err_i) err_flag <= 1'b1;
                        reg_rdata_lo <= m_wb_dat_i;

                        // Issue Beat 1: upper 32-bit word
                        m_wb_adr_o <= {reg_lsu_addr[31:3], 3'b100};
                        m_wb_sel_o <= 4'b1111;
                        m_wb_we_o  <= 1'b0;
                        m_wb_cyc_o <= 1'b1;
                        m_wb_stb_o <= 1'b1;
                        state      <= ST_LSU_RD_BEAT1;
                    end
                end

                ST_LSU_RD_BEAT1: begin
                    lsu_axi_arready <= 1'b0;

                    if (m_wb_ack_i || m_wb_err_i) begin
                        m_wb_cyc_o     <= 1'b0;
                        m_wb_stb_o     <= 1'b0;
                        lsu_axi_rid    <= reg_lsu_id;
                        lsu_axi_rresp  <= (m_wb_err_i || err_flag) ? 2'b10 : 2'b00;
                        lsu_axi_rlast  <= 1'b1;
                        lsu_axi_rvalid <= 1'b1;

                        if (reg_lsu_size == 3'b011) begin
                            lsu_axi_rdata <= {m_wb_dat_i, reg_rdata_lo};
                        end else begin
                            // Single word read: duplicate into both halves so LSU gets data regardless of word align
                            lsu_axi_rdata <= {m_wb_dat_i, m_wb_dat_i};
                        end
                        state <= ST_LSU_RD_RSP;
                    end
                end

                ST_LSU_RD_RSP: begin
                    if (lsu_axi_rready) begin
                        lsu_axi_rvalid <= 1'b0;
                        lsu_axi_rlast  <= 1'b0;
                        state          <= ST_IDLE;
                    end
                end

                // -------------------------------------------------------------
                // IFU Instruction Fetch Execution
                // -------------------------------------------------------------
                ST_IFU_RD_BEAT0: begin
                    ifu_axi_arready <= 1'b0;

                    if (m_wb_ack_i || m_wb_err_i) begin
                        if (m_wb_err_i) err_flag <= 1'b1;
                        reg_rdata_lo <= m_wb_dat_i; // Instruction Word 0 at 0x0

                        // Issue Beat 1: Instruction Word 1 at 0x4
                        m_wb_adr_o <= {reg_ifu_addr[31:3], 3'b100};
                        m_wb_sel_o <= 4'b1111;
                        m_wb_we_o  <= 1'b0;
                        m_wb_cyc_o <= 1'b1;
                        m_wb_stb_o <= 1'b1;
                        state      <= ST_IFU_RD_BEAT1;
                    end
                end

                ST_IFU_RD_BEAT1: begin
                    ifu_axi_arready <= 1'b0;

                    if (m_wb_ack_i || m_wb_err_i) begin
                        m_wb_cyc_o     <= 1'b0;
                        m_wb_stb_o     <= 1'b0;
                        ifu_axi_rid    <= reg_ifu_id;
                        ifu_axi_rresp  <= (m_wb_err_i || err_flag) ? 2'b10 : 2'b00;
                        ifu_axi_rlast  <= 1'b1;
                        ifu_axi_rvalid <= 1'b1;
                        // Return true 64-bit instruction quadword {Word 1, Word 0}
                        ifu_axi_rdata  <= {m_wb_dat_i, reg_rdata_lo};
                        state          <= ST_IFU_RD_RSP;
                    end
                end

                ST_IFU_RD_RSP: begin
                    if (ifu_axi_rready) begin
                        ifu_axi_rvalid <= 1'b0;
                        ifu_axi_rlast  <= 1'b0;
                        state          <= ST_IDLE;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
