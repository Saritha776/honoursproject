// ==============================================================================
// Class: gpio_base_sequence.sv
// Description: GPIO UVM Sequence extending uvm_sequence #(gpio_seq_item).
//              Generates systematic and random GPIO test patterns:
//              1. All zeros (8'h00)
//              2. All ones (8'hFF)
//              3. Alternating pattern (8'hAA)
//              4. Alternating pattern (8'h55)
//              5. Walking-one patterns (8'h01, 8'h02, 8'h04, ..., 8'h80)
//              6. Walking-zero patterns (8'hFE, 8'hFD, 8'hFB, ..., 8'h7F)
//              7. Random GPIO patterns
// ==============================================================================

`ifndef GPIO_BASE_SEQUENCE_SV
`define GPIO_BASE_SEQUENCE_SV

class gpio_base_sequence extends uvm_sequence #(gpio_seq_item);

    `uvm_object_utils(gpio_base_sequence)

    function new(string name = "gpio_base_sequence");
        super.new(name);
    endfunction

    // Helper task to execute standard UVM sequence item handshake with directed pattern
    task send_pattern(bit [7:0] pattern_val, string pattern_desc);
        gpio_seq_item req;
        req = gpio_seq_item::type_id::create("gpio_req");
        start_item(req);
        if (!req.randomize() with { gpio_in == pattern_val; }) begin
            `uvm_error(get_type_name(), $sformatf("Randomization failed for %s (val=0x%02h)", pattern_desc, pattern_val))
        end
        finish_item(req);
        `uvm_info(get_type_name(),
            $sformatf("[GPIO_SEQ] Finished %s -> Driven: 0x%02h (delay=%0d clks)",
                      pattern_desc, req.gpio_in, req.delay), UVM_LOW)
    endtask

    // Helper task to execute standard UVM sequence item handshake with random pattern
    task send_random_item(int unsigned index);
        gpio_seq_item req;
        req = gpio_seq_item::type_id::create($sformatf("gpio_rnd_req_%0d", index));
        start_item(req);
        if (!req.randomize()) begin
            `uvm_error(get_type_name(), $sformatf("Randomization failed for random item #%0d", index))
        end
        finish_item(req);
        `uvm_info(get_type_name(),
            $sformatf("[GPIO_SEQ] Finished Random Pattern #%0d -> Driven: 0x%02h (delay=%0d clks)",
                      index, req.gpio_in, req.delay), UVM_LOW)
    endtask

    virtual task body();
        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        `uvm_info(get_type_name(), "   Starting Systematic GPIO Input Stimulus Sequence", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================", UVM_LOW)

        // 1. All zeros (8'h00)
        send_pattern(8'h00, "Pattern 1: All Zeros");

        // 2. All ones (8'hFF)
        send_pattern(8'hFF, "Pattern 2: All Ones");

        // 3. Alternating pattern (8'hAA)
        send_pattern(8'hAA, "Pattern 3: Alternating 8'hAA");

        // 4. Alternating pattern (8'h55)
        send_pattern(8'h55, "Pattern 4: Alternating 8'h55");

        // 5. Walking-one pattern
        `uvm_info(get_type_name(), "Pattern 5: Starting Walking-One Patterns (8 bits)", UVM_LOW)
        for (int i = 0; i < 8; i++) begin
            send_pattern(8'(1 << i), $sformatf("Pattern 5: Walking-One bit %0d", i));
        end

        // 6. Walking-zero pattern
        `uvm_info(get_type_name(), "Pattern 6: Starting Walking-Zero Patterns (8 bits)", UVM_LOW)
        for (int i = 0; i < 8; i++) begin
            send_pattern(8'(~(1 << i)), $sformatf("Pattern 6: Walking-Zero bit %0d", i));
        end

        // 7. Random GPIO patterns
        `uvm_info(get_type_name(), "Pattern 7: Starting Random GPIO Patterns (10 items)", UVM_LOW)
        for (int i = 1; i <= 10; i++) begin
            send_random_item(i);
        end

        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        `uvm_info(get_type_name(), "   Completed All 7 GPIO Stimulus Patterns         ", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
    endtask

endclass

`endif // GPIO_BASE_SEQUENCE_SV
