@echo off
set xv_path=C:\\Xilinx\\Vivado\\2015.4\\bin
call %xv_path%/xsim bm_noisegen_tb_behav -key {Behavioral:sim_1:Functional:bm_noisegen_tb} -tclbatch bm_noisegen_tb.tcl -view C:/work/SCU/CourseWork/PhD courses/ELEN 249 - Topics in communication/project_2/temp/Verilog/test8/bm_noisegen/bm_noisegen_xilinx/bm_noisegen_tb_behav.wcfg -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
