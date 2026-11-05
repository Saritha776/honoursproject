// ==============================================================================
// Source: neural_ops.c
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: Software Activation Functions & Classification Routines
// ==============================================================================

#include "neural_ops.h"

void relu_int32(const int32_t *in, int32_t *out, int len) {
    for (int i = 0; i < len; i++) {
        out[i] = (in[i] > 0) ? in[i] : 0;
    }
}

void leaky_relu_int32(const int32_t *in, int32_t *out, int len, int alpha_shift) {
    for (int i = 0; i < len; i++) {
        if (in[i] >= 0) {
            out[i] = in[i];
        } else {
            out[i] = in[i] >> alpha_shift;
        }
    }
}

int argmax_int32(const int32_t *in, int len) {
    if (len <= 0) return 0;
    int max_idx = 0;
    int32_t max_val = in[0];
    for (int i = 1; i < len; i++) {
        if (in[i] > max_val) {
            max_val = in[i];
            max_idx = i;
        }
    }
    return max_idx;
}

void softmax_int32(const int32_t *in, int32_t *out, int len) {
    // Fixed-point scaled softmax
    int32_t max_val = in[0];
    for (int i = 1; i < len; i++) {
        if (in[i] > max_val) max_val = in[i];
    }

    int32_t sum = 0;
    for (int i = 0; i < len; i++) {
        int32_t shift_val = in[i] - max_val;
        // Piecewise linear approximation of exp(x)
        int32_t exp_approx = 256 + (shift_val > -256 ? shift_val : -256);
        if (exp_approx < 0) exp_approx = 0;
        out[i] = exp_approx;
        sum += exp_approx;
    }

    if (sum > 0) {
        for (int i = 0; i < len; i++) {
            out[i] = (out[i] * 100) / sum; // Normalized percentage (0-100%)
        }
    }
}
