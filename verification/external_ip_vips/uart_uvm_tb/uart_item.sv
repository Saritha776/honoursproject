class uart_item extends uvm_sequence_item;

  bit tx;
  rand bit rx;

  `uvm_object_utils(uart_item)

  function new(string name="uart_item"); super.new(name); endfunction
endclass
