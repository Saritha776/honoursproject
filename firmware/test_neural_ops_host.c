// ==============================================================================
// Host Verification Runner: test_neural_ops_host.c
// Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
// Description: Standalone C verification program running on host PC (GCC)
//              validating the exact neural operations and matrix math.
// ==============================================================================

#include <stdio.h>
#include <stdint.h>
#include "neural_ops.h"

// Weight matrix (4x4)
static const int8_t weights[4][4] = {
    {  2, -1,  4,  0 },
    {  1,  3, -2,  5 },
    { -3,  0,  1,  2 },
    {  4, -2,  3, -1 }
};

// Input activation vector
static const int8_t activations[4] = { 10, -5, 20, 8 };

// Expected golden dot products
static const int32_t expected[4] = { -13, -41, 94, 7 };

int main(void) {
    printf("=======================================================\n");
    printf("   NEUROEDGE SOC: HOST C INFERENCE VERIFICATION TEST   \n");
    printf("=======================================================\n\n");

    // 1. Matrix-Vector Multiplication Simulation
    int32_t dot_products[4] = {0};
    for (int col = 0; col < 4; col++) {
        for (int row = 0; row < 4; row++) {
            dot_products[col] += (int32_t)activations[row] * (int32_t)weights[row][col];
        }
    }

    printf("[STEP 1] Matrix-Vector Dot-Product Verification:\n");
    int pass = 1;
    for (int i = 0; i < 4; i++) {
        printf("         Column %d: Computed = %3d | Expected = %3d", i, dot_products[i], expected[i]);
        if (dot_products[i] == expected[i]) {
            printf("  [PASS]\n");
        } else {
            printf("  [FAIL]\n");
            pass = 0;
        }
    }

    // 2. Non-linear Activation (ReLU)
    printf("\n[STEP 2] Non-Linear Activation (ReLU):\n");
    int32_t relu_out[4];
    relu_int32(dot_products, relu_out, 4);
    printf("         Input:  [%d, %d, %d, %d]\n", dot_products[0], dot_products[1], dot_products[2], dot_products[3]);
    printf("         Output: [%d, %d, %d, %d]\n", relu_out[0], relu_out[1], relu_out[2], relu_out[3]);

    // 3. Classification (ArgMax)
    printf("\n[STEP 3] Category Classification (ArgMax):\n");
    int top_class = argmax_int32(relu_out, 4);
    printf("         Predicted Class: Class %d (Confidence Score = %d)\n", top_class, relu_out[top_class]);

    // 4. Softmax Probability
    printf("\n[STEP 4] Softmax Probability Distribution:\n");
    int32_t softmax_out[4];
    softmax_int32(relu_out, softmax_out, 4);
    for (int i = 0; i < 4; i++) {
        printf("         Class %d Probability: %d%%\n", i, softmax_out[i]);
    }

    printf("\n=======================================================\n");
    if (pass && top_class == 2) {
        printf("   >>> ALL HOST C VERIFICATION CHECKS PASSED! <<<      \n");
    } else {
        printf("   >>> FAILURE DETECTED IN C CALCULATIONS <<<          \n");
    }
    printf("=======================================================\n");

    return (pass && top_class == 2) ? 0 : 1;
}
