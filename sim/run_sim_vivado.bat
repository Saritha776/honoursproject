@echo off
REM ==============================================================================
REM Script: run_sim_vivado.bat
REM Project: NeuroEdge SoC (RISC-V with Systolic-Array AI Acceleration)
REM Description: One-click compilation and simulation script using Vivado xsim
REM ==============================================================================

set VIVADO_BIN=C:\Xilinx\Vivado\2018.2\bin

echo [1/3] Compiling SystemVerilog RTL and Testbench...
call "%VIVADO_BIN%\xvlog.bat" -sv -i ..\rtl -i ..\firmware -f ..\tb\filelist.f
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Compilation failed!
    exit /b %ERRORLEVEL%
)

echo [2/3] Elaborating Design Snapshot...
call "%VIVADO_BIN%\xelab.bat" -debug typical -s tb_sim tb_neuroedge_soc
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Elaboration failed!
    exit /b %ERRORLEVEL%
)

echo [3/3] Running Simulation...
call "%VIVADO_BIN%\xsim.bat" tb_sim -runall
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Simulation failed!
    exit /b %ERRORLEVEL%
)

echo.
echo =======================================================
echo    NEUROEDGE SOC SIMULATION COMPLETED SUCCESSFULLY!
echo =======================================================
