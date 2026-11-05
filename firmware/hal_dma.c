// ==============================================================================
// Source: hal_dma.c
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: Dual-Channel DMA Controller Driver Implementation
// ==============================================================================

#include "neuroedge_hw.h"
#include "hal_dma.h"

void dma_init(void) {
    DMA_REG_CTRL = 0;
    // Clear sticky status flags
    DMA_REG_STATUS = DMA_STATUS_CH0_DONE | DMA_STATUS_CH1_DONE | DMA_STATUS_ERR;
}

int dma_is_busy(void) {
    return (DMA_REG_STATUS & DMA_STATUS_BUSY) ? 1 : 0;
}

void dma_stream_weights(uint32_t sram_src_addr, uint16_t word_count) {
    // Wait if already busy
    while (dma_is_busy());

    // Configure Channel 1 for weights (targets ARRAY_WEIGHT_PORT 0x40002010)
    DMA_REG_CH1_SRC = sram_src_addr;
    DMA_REG_CH1_DST = ARRAY_BASE + 0x10;
    DMA_REG_CH1_LEN = (uint32_t)word_count;

    // Clear done flag & enable Ch1
    DMA_REG_STATUS  = DMA_STATUS_CH1_DONE;
    DMA_REG_CTRL    = DMA_CTRL_EN | DMA_CTRL_CH1_EN;
}

void dma_stream_activations(uint32_t sram_src_addr, uint16_t word_count) {
    while (dma_is_busy());

    // Configure Channel 0 for activations (targets ARRAY_ACT_PORT 0x40002014)
    DMA_REG_CH0_SRC = sram_src_addr;
    DMA_REG_CH0_DST = ARRAY_BASE + 0x14;
    DMA_REG_CH0_LEN = (uint32_t)word_count;

    // Clear done flag & enable Ch0
    DMA_REG_STATUS  = DMA_STATUS_CH0_DONE;
    DMA_REG_CTRL    = DMA_CTRL_EN | DMA_CTRL_CH0_EN;
}

void dma_wait_channel(int channel) {
    if (channel == 1) {
        while (!(DMA_REG_STATUS & DMA_STATUS_CH1_DONE));
        DMA_REG_STATUS = DMA_STATUS_CH1_DONE; // Clear W1C
    } else {
        while (!(DMA_REG_STATUS & DMA_STATUS_CH0_DONE));
        DMA_REG_STATUS = DMA_STATUS_CH0_DONE; // Clear W1C
    }
}
