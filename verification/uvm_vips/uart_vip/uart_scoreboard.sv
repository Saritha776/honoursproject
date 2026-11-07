// ==============================================================================
// Class: uart_scoreboard.sv
// Description: Scoreboard for UART VIP buffering lines & verifying telemetry
// ==============================================================================

`ifndef UART_SCOREBOARD_SV
`define UART_SCOREBOARD_SV

class uart_scoreboard extends uvm_scoreboard;

    uvm_analysis_imp #(uart_item, uart_scoreboard) item_collected_export;

    string current_line = "";
    int total_chars_received = 0;
    int total_lines_received = 0;
    bit banner_seen = 0;
    bit pass_msg_seen = 0;

    `uvm_component_utils(uart_scoreboard)

    function new(string name = "uart_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        item_collected_export = new("item_collected_export", this);
    endfunction

    function void write(uart_item item);
        total_chars_received++;

        if (item.data == 8'h0A || item.data == 8'h0D) begin
            if (current_line.len() > 0) begin
                total_lines_received++;
                `uvm_info("UART_TELEMETRY", current_line, UVM_LOW)

                if (str_contains(current_line, "NEUROEDGE SOC")) begin
                    banner_seen = 1;
                end
                if (str_contains(current_line, "ALL INFERENCE TESTS PASSED")) begin
                    pass_msg_seen = 1;
                end
                current_line = "";
            end
        end else if (item.data >= 8'h20 && item.data <= 8'h7E) begin
            current_line = {current_line, string'(item.data)};
        end
    endfunction

    function bit str_contains(string haystack, string needle);
        int h_len, n_len;
        h_len = haystack.len();
        n_len = needle.len();
        if (n_len > h_len) return 0;
        for (int i = 0; i <= (h_len - n_len); i++) begin
            if (haystack.substr(i, i + n_len - 1) == needle) return 1;
        end
        return 0;
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(),
            $sformatf("UART Scoreboard Summary: Chars=%0d, Lines=%0d, BannerSeen=%0b, PassSeen=%0b",
                      total_chars_received, total_lines_received, banner_seen, pass_msg_seen), UVM_LOW)
    endfunction

endclass

`endif // UART_SCOREBOARD_SV
