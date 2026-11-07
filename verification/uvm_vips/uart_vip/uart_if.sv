// ==============================================================================
// Interface: uart_if.sv
// Description: UART physical interface with protocol assertions
// ==============================================================================

interface uart_if (
    input logic clk,
    input logic rst_n
);

    logic tx; // Driven by DUT (transmitter output)
    logic rx; // Driven by Testbench/Driver (receiver input)
    logic [7:0] rx_shift_reg_probe; // Probed from DUT receiver shift register

    // Protocol Assertions
    property p_uart_tx_reset_idle;
        @(posedge clk) $rose(rst_n) |-> (tx === 1'b1);
    endproperty
    assert_uart_tx_reset_idle: assert property (p_uart_tx_reset_idle)
        else $error("[UART_IF] UART TX line did not initialize to idle high (1'b1) on reset deassertion");

    property p_uart_start_bit;
        @(posedge clk) disable iff (!rst_n)
        $fell(tx) |=> (tx === 1'b0);
    endproperty
    assert_uart_start_bit: assert property (p_uart_start_bit)
        else $error("[UART_IF] UART TX start bit glitch detected");

endinterface
