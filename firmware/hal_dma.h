// ==============================================================================
// Header: hal_dma.h
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: Dual-Channel DMA Controller Hardware Abstraction Layer
// ==============================================================================

#ifndef HAL_DMA_H_
#define HAL_DMA_H_

#include <stdint.h>

void dma_init(void);
int  dma_is_busy(void);
void dma_stream_weights(uint32_t sram_src_addr, uint16_t word_count);
void dma_stream_activations(uint32_t sram_src_addr, uint16_t word_count);
void dma_wait_channel(int channel);

#endif // HAL_DMA_H_
