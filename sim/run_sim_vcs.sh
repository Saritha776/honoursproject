#!/bin/bash
# ==============================================================================
# Script: run_sim_vcs.sh
# Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
# Description: Automated Synopsys VCS compilation, simulation and Verdi launch
# ==============================================================================

set -e

echo "======================================================="
echo "   Compiling NeuroEdge SoC with Synopsys VCS           "
echo "======================================================="

# Compile with Knowledge Database (-kdb) and FSDB dump define for Verdi
vcs -full64 \
    -sverilog \
    -kdb \
    -debug_access+all \
    -lca \
    -timescale=1ns/1ps \
    +define+DUMP_FSDB \
    -f ../tb/filelist.f \
    -top tb_neuroedge_soc \
    -l vcs_compile.log

echo ""
echo "======================================================="
echo "   Executing Simulation (Generating neuroedge_sim.fsdb)"
echo "======================================================="
./simv -l vcs_sim.log

echo ""
echo "======================================================="
echo "   Launching Synopsys Verdi Waveform Viewer            "
echo "======================================================="
if command -v verdi &> /dev/null; then
    verdi -ssf neuroedge_sim.fsdb -simv simv &
else
    echo "[INFO] Verdi executable not found in PATH. FSDB dumped at neuroedge_sim.fsdb"
fi
