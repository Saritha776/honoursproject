# ==============================================================================
# Makefile: NeuroEdge RISC-V SoC with Systolic Array AI Accelerator
# Target: Synopsys VCS U-2023.03, Verdi U-2023.03-SP1, RISC-V GCC
# ==============================================================================

SHELL := /bin/bash

.PHONY: all help sim regression wave-sim wave-uvm coverage firmware host-test clean

all: help

help:
	@echo "=================================================================="
	@echo "   NeuroEdge SoC: Automated Build, Simulation & Verification Menu"
	@echo "=================================================================="
	@echo "  make sim          - Run 1-Click VeeR EL2 Bare-Metal Firmware Simulation"
	@echo "  make regression   - Run Master Multi-Seed UVM 1.2 Regression Suite"
	@echo "  make wave-sim     - Open Non-UVM Firmware FSDB Waveform in Verdi"
	@echo "  make wave-uvm     - Open UVM Regression FSDB Waveform in Verdi"
	@echo "  make coverage     - Display URG Functional & Code Coverage Summary"
	@echo "  make firmware     - Rebuild Bare-Metal C Test Firmware (RISC-V GCC)"
	@echo "  make host-test    - Compile & Execute Host C Numerical Golden Model"
	@echo "  make clean        - Clean Simulator Output Directories & Cache"
	@echo "=================================================================="

sim:
	@echo ">>> Starting NeuroEdge SoC Non-UVM Firmware Simulation..."
	cd sim && ./run_sim_vcs.sh

regression:
	@echo ">>> Starting NeuroEdge SoC Master UVM Regression Suite..."
	bash verification/scripts/run_all_uvm_tests.sh

wave-sim:
	@echo ">>> Launching Synopsys Verdi for Non-UVM Simulation Waveform..."
	verdi -ssf sim/neuroedge_sim.fsdb -simv sim/simv -sswr verification/neuroedge_soc_waves.rc &

wave-uvm:
	@echo ">>> Launching Synopsys Verdi for UVM Regression Waveform..."
	verdi -ssf verification/sim/neuroedge_uvm_sim.fsdb -simv verification/sim/simv_uvm -sswr verification/neuroedge_waves.rc &

coverage:
	@echo ">>> NeuroEdge SoC Functional & Code Coverage Report:"
	@cat verification/coverage_report/dashboard.txt

firmware:
	@echo ">>> Compiling RISC-V Bare-Metal C Test Firmware..."
	cd firmware && make clean && make

host-test:
	@echo ">>> Running Host C Inference Golden Predictor..."
	cd firmware && gcc -O2 -Wall -I. test_neural_ops_host.c neural_ops.c -o test_host && ./test_host && rm -f test_host

clean:
	@echo ">>> Cleaning Simulation Artifacts..."
	rm -rf sim/csrc sim/simv.daidir sim/*.log sim/ucli.key sim/vc_hdrs.h
	rm -rf verification/sim/csrc verification/sim/simv*.daidir verification/sim/*.log verification/sim/ucli.key
