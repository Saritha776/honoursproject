// ==============================================================================
// Interface: systolic_if.sv
// Description: Systolic Array hardware interface and assertion monitors
// ==============================================================================

interface systolic_if (
    input logic clk,
    input logic rst_n
);

    // Wishbone Register Port
    logic [31:0]        wb_adr;
    logic [31:0]        wb_dat_w;
    logic [31:0]        wb_dat_r;
    logic               wb_we;
    logic               wb_stb;
    logic               wb_cyc;
    logic               wb_ack;

    // Direct DMA Streaming Ports
    logic               dma_act_valid;
    logic [31:0]        dma_act_data;
    logic               dma_wgt_valid;
    logic [31:0]        dma_wgt_data;

    // Accelerator IRQ
    logic               array_irq;

    // Column Output Probes
    logic signed [31:0] res_out [0:3];

    // Assertions
    property p_irq_pulse;
        @(posedge clk) disable iff (!rst_n)
        $isunknown(array_irq) == 0;
    endproperty
    assert_array_irq_known: assert property (p_irq_pulse)
        else $error("[SYSTOLIC_IF] array_irq contains unknown state");

endinterface
