# ==============================================================================
# Verdi Command Script: neuroedge_waves.cmd
# Automated Session Setup with 7 Organized Waveform Signal Groups
# ==============================================================================

debImport "-simv" "verification/sim/simv_uvm" "-dbdir" "verification/sim/simv_uvm.daidir"
debLoadSimResult "verification/sim/neuroedge_uvm_sim.fsdb"
wvCreateWindow
wvRestoreSignal -win $_nWave2 "verification/neuroedge_waves.rc"
wvZoomAll -win $_nWave2
