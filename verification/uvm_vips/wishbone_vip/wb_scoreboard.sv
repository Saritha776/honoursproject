// ==============================================================================
// Class: wb_scoreboard.sv
// Description: Scoreboard for Wishbone VIP
// ==============================================================================

`ifndef WB_SCOREBOARD_SV
`define WB_SCOREBOARD_SV

class wb_scoreboard extends uvm_scoreboard;

    uvm_analysis_imp #(wb_item, wb_scoreboard) item_collected_export;

    // Word-addressable associative memory model
    bit [31:0] mem_model [bit [31:2]];

    int write_count = 0;
    int read_count = 0;
    int match_count = 0;
    int mismatch_count = 0;
    int error_resp_count = 0;

    `uvm_component_utils(wb_scoreboard)

    function new(string name = "wb_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        item_collected_export = new("item_collected_export", this);
    endfunction

    function void write(wb_item item);
        bit [31:2] word_idx;

        if (item.err) begin
            error_resp_count++;
            return;
        end

        word_idx = item.addr >> 2;

        if (item.op == WB_WRITE) begin
            write_count++;
            if (!mem_model.exists(word_idx)) mem_model[word_idx] = '0;
            for (int b = 0; b < 4; b++) begin
                if (item.sel[b]) begin
                    mem_model[word_idx][b*8 +: 8] = item.data[b*8 +: 8];
                end
            end
        end else begin
            read_count++;
            // Check memory consistency for DSRAM
            if (mem_model.exists(word_idx) && (item.addr >= 32'h2000_0000 && item.addr <= 32'h2000_FFFF)) begin
                bit [31:0] mask;
                mask = 32'h0;
                for (int b = 0; b < 4; b++) begin
                    if (item.sel[b]) mask[b*8 +: 8] = 8'hFF;
                end
                if ((item.data & mask) === (mem_model[word_idx] & mask)) begin
                    match_count++;
                end else begin
                    mismatch_count++;
                    `uvm_warning(get_type_name(),
                        $sformatf("WB Read Mismatch at 0x%08h: Read=0x%08h, Expected=0x%08h (Mask=0x%08h)",
                                  item.addr, item.data, mem_model[word_idx], mask))
                end
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(),
            $sformatf("Wishbone Scoreboard Summary: Writes=%0d, Reads=%0d, Matches=%0d, Mismatches=%0d, BusErrors=%0d",
                      write_count, read_count, match_count, mismatch_count, error_resp_count), UVM_LOW)
    endfunction

endclass

`endif // WB_SCOREBOARD_SV
