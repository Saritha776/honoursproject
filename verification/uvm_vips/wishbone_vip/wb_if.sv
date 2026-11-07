// ==============================================================================
// Interface: wb_if.sv
// Description: Wishbone B4 Interface with assertions and clocking blocks
// ==============================================================================

interface wb_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input logic clk,
    input logic rst_n
);

    logic [ADDR_WIDTH-1:0]  adr;
    logic [DATA_WIDTH-1:0]  dat_w;
    logic [DATA_WIDTH-1:0]  dat_r;
    logic [3:0]             sel;
    logic                   we;
    logic                   stb;
    logic                   cyc;
    logic                   ack;
    logic                   err;

    clocking mst_cb @(posedge clk);
        default input #1ns output #1ns;
        output adr, dat_w, sel, we, stb, cyc;
        input  dat_r, ack, err;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1ns output #1ns;
        input adr, dat_w, dat_r, sel, we, stb, cyc, ack, err;
    endclocking

    // =========================================================================
    // Protocol Assertions
    // =========================================================================
    property p_stb_implies_cyc;
        @(posedge clk) disable iff (!rst_n)
        stb |-> cyc;
    endproperty
    assert_stb_implies_cyc: assert property (p_stb_implies_cyc)
        else $error("[WB_IF] Wishbone STB asserted without CYC");

    property p_master_signals_stable;
        @(posedge clk) disable iff (!rst_n)
        (cyc && stb && !ack && !err) |=> $stable(adr) && $stable(we) && $stable(sel) && ($stable(dat_w) || !we);
    endproperty
    assert_master_signals_stable: assert property (p_master_signals_stable)
        else $error("[WB_IF] Master signals must remain stable until ACK or ERR");

    property p_ack_err_mutually_exclusive;
        @(posedge clk) disable iff (!rst_n)
        !(ack && err);
    endproperty
    assert_ack_err_mutually_exclusive: assert property (p_ack_err_mutually_exclusive)
        else $error("[WB_IF] Wishbone ACK and ERR cannot be asserted simultaneously");

    property p_timeout_guard;
        @(posedge clk) disable iff (!rst_n)
        ($rose(stb) && cyc) |-> ##[1:65] (ack || err);
    endproperty
    assert_timeout_guard: assert property (p_timeout_guard)
        else $error("[WB_IF] Wishbone bus transaction exceeded 64-cycle timeout");

endinterface
