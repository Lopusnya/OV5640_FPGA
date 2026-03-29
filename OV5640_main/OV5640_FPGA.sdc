## Generated SDC file "OV5640_FPGA.sdc"

## Copyright (C) 2022  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details, at
## https://fpgasoftware.intel.com/eula.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 22.1std.0 Build 915 10/25/2022 SC Lite Edition"

## DATE    "Sat Mar 14 15:17:45 2026"

##
## DEVICE  "EP4CE10E22C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {CLK} -period 20.000 -waveform { 0.000 10.000 } [get_ports {CLK}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {pll|altpll_component|auto_generated|pll1|clk[0]} -source [get_pins {pll|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 2 -master_clock {CLK} [get_pins {pll|altpll_component|auto_generated|pll1|clk[0]}] 
create_generated_clock -name {pll|altpll_component|auto_generated|pll1|clk[1]} -source [get_pins {pll|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 2 -phase -216/1 -master_clock {CLK} [get_pins {pll|altpll_component|auto_generated|pll1|clk[1]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  0.010  


#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -2.500 [get_ports {SDRAM_D[0]}]
set_input_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -2.500 [get_ports {SDRAM_D[1]}]
set_input_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -2.500 [get_ports {SDRAM_D[2]}]
set_input_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -2.500 [get_ports {SDRAM_D[3]}]
set_input_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -2.500 [get_ports {SDRAM_D[4]}]
set_input_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -2.500 [get_ports {SDRAM_D[5]}]
set_input_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -2.500 [get_ports {SDRAM_D[6]}]
set_input_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -2.500 [get_ports {SDRAM_D[7]}]
set_input_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -2.500 [get_ports {SDRAM_D[8]}]
set_input_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -2.500 [get_ports {SDRAM_D[9]}]
set_input_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -2.500 [get_ports {SDRAM_D[10]}]
set_input_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -2.500 [get_ports {SDRAM_D[11]}]
set_input_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -2.500 [get_ports {SDRAM_D[12]}]
set_input_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -2.500 [get_ports {SDRAM_D[13]}]
set_input_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -2.500 [get_ports {SDRAM_D[14]}]
set_input_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -2.500 [get_ports {SDRAM_D[15]}]


#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_A[0]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_A[0]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_A[1]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_A[1]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_A[2]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_A[2]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_A[3]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_A[3]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_A[4]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_A[4]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_A[5]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_A[5]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_A[6]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_A[6]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_A[7]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_A[7]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_A[8]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_A[8]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_A[9]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_A[9]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_A[10]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_A[10]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_A[11]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_A[11]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_BS[0]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_BS[0]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_BS[1]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_BS[1]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_CAS}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_CAS}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_CKE}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_CKE}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_CS}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_CS}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_D[0]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_D[0]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_D[1]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_D[1]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_D[2]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_D[2]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_D[3]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_D[3]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_D[4]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_D[4]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_D[5]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_D[5]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_D[6]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_D[6]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_D[7]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_D[7]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_D[8]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_D[8]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_D[9]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_D[9]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_D[10]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_D[10]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_D[11]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_D[11]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_D[12]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_D[12]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_D[13]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_D[13]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_D[14]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_D[14]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_D[15]}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_D[15]}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_LDQM}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_LDQM}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_RAS}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_RAS}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_UDQM}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_UDQM}]
set_output_delay -add_delay -max -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  1.500 [get_ports {SDRAM_WE}]
set_output_delay -add_delay -min -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  -0.800 [get_ports {SDRAM_WE}]


#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

