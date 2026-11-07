#!/usr/bin/env bash
# ==============================================================================
# Script: run_uvm_sim.sh
# Description: VCS Compilation and Execution Script for NeuroEdge SoC UVM TB
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SIM_DIR="$PROJ_ROOT/verification/sim"
mkdir -p "$SIM_DIR"
cd "$SIM_DIR"

# Source environment
source ~/.bashrc

export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export PATH=$VERDI_HOME/bin:$VCS_HOME/bin:$PATH

TEST_NAME=${1:-"neuroedge_systolic_test"}
PLUSARGS=${2:-""}

echo "=================================================================="
echo " NeuroEdge SoC: Synopsys VCS UVM Compilation & Simulation"
echo " Target Test: $TEST_NAME"
echo " Project: $PROJ_ROOT"
echo " Output Dir: $SIM_DIR"
echo "=================================================================="

# Check if compilation is required
if [ ! -f "simv_uvm" ] || [ "$COMPILE_CLEAN" = "1" ]; then
    echo ">>> Running Synopsys VCS UVM Compilation..."
    vcs -full64 -sverilog \
        -ntb_opts uvm-1.2 \
        -timescale=1ns/1ps \
        -debug_access+all \
        -kdb -lca \
        -cm line+cond+fsm+tgl+branch+assert \
        -f "$PROJ_ROOT/verification/filelists/filelist_uvm.f" \
        -o simv_uvm \
        -l comp_uvm.log
    echo ">>> VCS Compilation Clean!"
fi

echo ">>> Running UVM Test: $TEST_NAME..."
./simv_uvm +UVM_TESTNAME="$TEST_NAME" \
           +UVM_VERBOSITY=UVM_LOW \
           +vcs+initreg+0 +vcs+initmem+0 \
           -cm line+cond+fsm+tgl+branch+assert \
           -cm_dir neuroedge_cov.vdb \
           -cm_name "$TEST_NAME" \
           $PLUSARGS \
           -l "sim_${TEST_NAME}.log"

echo "=================================================================="
echo " UVM Test $TEST_NAME Finished!"
echo " Log: $SIM_DIR/sim_${TEST_NAME}.log"
echo " Waveform: $SIM_DIR/neuroedge_uvm_sim.fsdb"
echo "=================================================================="
