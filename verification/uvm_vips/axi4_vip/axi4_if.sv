// ==============================================================================
// Interface: axi4_if.sv
// Description: AXI4 64-bit Data / 32-bit Address Interface with protocol SVA
// ==============================================================================

`timescale 1ns / 1ps

interface axi4_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 64,
    parameter ID_WIDTH   = 8
)(
    input logic clk,
    input logic rst_n
);

    // Write Address Channel
    logic [ID_WIDTH-1:0]    awid;
    logic [ADDR_WIDTH-1:0]  awaddr;
    logic [7:0]             awlen;
    logic [2:0]             awsize;
    logic [1:0]             awburst;
    logic                   awvalid;
    logic                   awready;

    // Write Data Channel
    logic [DATA_WIDTH-1:0]  wdata;
    logic [(DATA_WIDTH/8)-1:0] wstrb;
    logic                   wlast;
    logic                   wvalid;
    logic                   wready;

    // Write Response Channel
    logic [ID_WIDTH-1:0]    bid;
    logic [1:0]             bresp;
    logic                   bvalid;
    logic                   bready;

    // Read Address Channel
    logic [ID_WIDTH-1:0]    arid;
    logic [ADDR_WIDTH-1:0]  araddr;
    logic [7:0]             arlen;
    logic [2:0]             arsize;
    logic [1:0]             arburst;
    logic                   arvalid;
    logic                   arready;

    // Read Data Channel
    logic [ID_WIDTH-1:0]    rid;
    logic [DATA_WIDTH-1:0]  rdata;
    logic [1:0]             rresp;
    logic                   rlast;
    logic                   rvalid;
    logic                   rready;

    // Clocking block for Master Driver
    clocking mst_cb @(posedge clk);
        default input #1ns output #1ns;
        output awid, awaddr, awlen, awsize, awburst, awvalid;
        input  awready;
        output wdata, wstrb, wlast, wvalid;
        input  wready;
        input  bid, bresp, bvalid;
        output bready;
        output arid, araddr, arlen, arsize, arburst, arvalid;
        input  arready;
        input  rid, rdata, rresp, rlast, rvalid;
        output rready;
    endclocking

    // Clocking block for Monitor
    clocking mon_cb @(posedge clk);
        default input #1ns output #1ns;
        input awid, awaddr, awlen, awsize, awburst, awvalid, awready;
        input wdata, wstrb, wlast, wvalid, wready;
        input bid, bresp, bvalid, bready;
        input arid, araddr, arlen, arsize, arburst, arvalid, arready;
        input rid, rdata, rresp, rlast, rvalid, rready;
    endclocking

    // =========================================================================
    // Protocol Assertions (AXI4 Core Rules)
    // =========================================================================
    property p_awvalid_stable;
        @(posedge clk) disable iff (!rst_n)
        (awvalid && !awready) |=> $stable(awvalid) && $stable(awaddr) && $stable(awlen) && $stable(awsize);
    endproperty
    assert_awvalid_stable: assert property (p_awvalid_stable)
        else $error("[AXI4_IF] AWVALID asserted must remain stable until AWREADY");

    property p_arvalid_stable;
        @(posedge clk) disable iff (!rst_n)
        (arvalid && !arready) |=> $stable(arvalid) && $stable(araddr) && $stable(arlen) && $stable(arsize);
    endproperty
    assert_arvalid_stable: assert property (p_arvalid_stable)
        else $error("[AXI4_IF] ARVALID asserted must remain stable until ARREADY");

    property p_wvalid_stable;
        @(posedge clk) disable iff (!rst_n)
        (wvalid && !wready) |=> $stable(wvalid) && $stable(wdata) && $stable(wstrb) && $stable(wlast);
    endproperty
    assert_wvalid_stable: assert property (p_wvalid_stable)
        else $error("[AXI4_IF] WVALID asserted must remain stable until WREADY");

    property p_rvalid_stable;
        @(posedge clk) disable iff (!rst_n)
        (rvalid && !rready) |=> $stable(rvalid) && $stable(rdata) && $stable(rlast);
    endproperty
    assert_rvalid_stable: assert property (p_rvalid_stable)
        else $error("[AXI4_IF] RVALID asserted must remain stable until RREADY");

endinterface
