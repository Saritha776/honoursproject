// ==============================================================================
// Class: axi4_scoreboard.sv
// Description: Scoreboard for AXI4 VIP verifying memory read/write consistency
// ==============================================================================

`ifndef AXI4_SCOREBOARD_SV
`define AXI4_SCOREBOARD_SV

class axi4_scoreboard extends uvm_scoreboard;

    uvm_analysis_imp #(axi4_item, axi4_scoreboard) item_collected_export;

    // Associative memory model for data consistency checks
    bit [63:0] mem_model [bit [31:3]];

    int match_count = 0;
    int mismatch_count = 0;
    int write_count = 0;
    int read_count = 0;

    `uvm_component_utils(axi4_scoreboard)

    function new(string name = "axi4_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        item_collected_export = new("item_collected_export", this);
    endfunction

    function void write(axi4_item item);
        bit [31:3] qword_idx;

        if (item.xfer_type == AXI_WRITE) begin
            write_count++;
            for (int i = 0; i <= item.len; i++) begin
                qword_idx = (item.addr + (i * 8)) >> 3;
                if (!mem_model.exists(qword_idx)) mem_model[qword_idx] = '0;
                // Apply byte strobes
                for (int b = 0; b < 8; b++) begin
                    if (item.strb[i][b]) begin
                        mem_model[qword_idx][b*8 +: 8] = item.data[i][b*8 +: 8];
                    end
                end
            end
        end else begin
            read_count++;
            for (int i = 0; i <= item.len; i++) begin
                qword_idx = (item.addr + (i * 8)) >> 3;
                // Only check data consistency for full 64-bit quadword reads in DSRAM
                if (item.size == 3'b011 && mem_model.exists(qword_idx) && (item.addr >= 32'h2000_0000 && item.addr <= 32'h2000_FFFF)) begin
                    if (item.data[i] === mem_model[qword_idx]) begin
                        match_count++;
                    end else begin
                        mismatch_count++;
                        `uvm_info(get_type_name(),
                            $sformatf("AXI4 Read Mismatch at 0x%08h: Read=0x%016h, Expected=0x%016h",
                                      (qword_idx << 3), item.data[i], mem_model[qword_idx]), UVM_DEBUG)
                    end
                end
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(),
            $sformatf("AXI4 Scoreboard Summary: Writes=%0d, Reads=%0d, Matches=%0d, Mismatches=%0d",
                      write_count, read_count, match_count, mismatch_count), UVM_LOW)
    endfunction

endclass

`endif // AXI4_SCOREBOARD_SV
