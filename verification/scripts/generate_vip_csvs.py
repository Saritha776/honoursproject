#!/usr/bin/env python3
"""
Generate CSV signal lists for NeuroEdge SoC VIP interfaces.
Used in conjunction with uvm_full_tb_generator.py
"""

import os

CSV_DATA = {
    "axi4": [
        ("clk", "input", 1),
        ("rst_n", "input", 1),
        ("awid", "input", 8),
        ("awaddr", "input", 32),
        ("awlen", "input", 8),
        ("awsize", "input", 3),
        ("awburst", "input", 2),
        ("awvalid", "input", 1),
        ("awready", "output", 1),
        ("wdata", "input", 64),
        ("wstrb", "input", 8),
        ("wlast", "input", 1),
        ("wvalid", "input", 1),
        ("wready", "output", 1),
        ("bid", "output", 8),
        ("bresp", "output", 2),
        ("bvalid", "output", 1),
        ("bready", "input", 1),
        ("arid", "input", 8),
        ("araddr", "input", 32),
        ("arlen", "input", 8),
        ("arsize", "input", 3),
        ("arburst", "input", 2),
        ("arvalid", "input", 1),
        ("arready", "output", 1),
        ("rid", "output", 8),
        ("rdata", "output", 64),
        ("rresp", "output", 2),
        ("rlast", "output", 1),
        ("rvalid", "output", 1),
        ("rready", "input", 1),
    ],
    "wishbone": [
        ("clk", "input", 1),
        ("rst_n", "input", 1),
        ("adr", "input", 32),
        ("dat_w", "input", 32),
        ("dat_r", "output", 32),
        ("sel", "input", 4),
        ("we", "input", 1),
        ("stb", "input", 1),
        ("cyc", "input", 1),
        ("ack", "output", 1),
        ("err", "output", 1),
    ],
    "uart": [
        ("clk", "input", 1),
        ("rst_n", "input", 1),
        ("tx", "output", 1),
        ("rx", "input", 1),
    ],
    "systolic": [
        ("clk", "input", 1),
        ("rst_n", "input", 1),
        ("wb_adr", "input", 32),
        ("wb_dat_w", "input", 32),
        ("wb_dat_r", "output", 32),
        ("wb_we", "input", 1),
        ("wb_stb", "input", 1),
        ("wb_cyc", "input", 1),
        ("wb_ack", "output", 1),
        ("dma_act_valid", "input", 1),
        ("dma_act_data", "input", 32),
        ("dma_wgt_valid", "input", 1),
        ("dma_wgt_data", "input", 32),
        ("array_irq", "output", 1),
    ],
    "spi_flash": [
        ("clk", "input", 1),
        ("rst_n", "input", 1),
        ("sclk", "output", 1),
        ("mosi", "output", 1),
        ("miso", "input", 1),
        ("cs_n", "output", 1),
    ],
    "gpio": [
        ("clk", "input", 1),
        ("rst_n", "input", 1),
        ("gpio_in", "input", 8),
        ("gpio_out", "output", 8),
        ("gpio_dir", "output", 8),
    ],
}

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    for vip_name, sigs in CSV_DATA.items():
        csv_path = os.path.join(script_dir, f"{vip_name}_signals.csv")
        with open(csv_path, "w") as f:
            for s in sigs:
                f.write(f"{s[0]},{s[1]},{s[2]}\n")
        print(f"Wrote {csv_path} ({len(sigs)} signals)")

if __name__ == "__main__":
    main()
