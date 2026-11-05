// ==============================================================================
// Header: neural_ops.h
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: Software Activation Functions & Classification Routines
// ==============================================================================

#ifndef NEURAL_OPS_H_
#define NEURAL_OPS_H_

#include <stdint.h>

void    relu_int32(const int32_t *in, int32_t *out, int len);
void    leaky_relu_int32(const int32_t *in, int32_t *out, int len, int alpha_shift);
int     argmax_int32(const int32_t *in, int len);
void    softmax_int32(const int32_t *in, int32_t *out, int len);

#endif // NEURAL_OPS_H_
