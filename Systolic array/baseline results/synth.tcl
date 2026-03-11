###############################################################
# Cadence Genus Synthesis Script - FINAL RUN
###############################################################

# -------------------------------------------------------------
# Project Paths
# -------------------------------------------------------------
set PROJECT_DIR /home/install/IC618/RA2311067010024/systolic_project
set RTL_DIR      $PROJECT_DIR/rtl
set SCRIPT_DIR   $PROJECT_DIR/scripts
set REPORT_DIR   $PROJECT_DIR/reports
set NETLIST_DIR  $PROJECT_DIR/netlist
set LIB_DIR      $PROJECT_DIR/lib

file mkdir $REPORT_DIR
file mkdir $NETLIST_DIR

set TOP_MODULE systolic_array_4x4
set LIB_PATH /home/install/IC618/RA2311067010024/FOUNDRY/digital/45nm/NangateOpenCellLibrary_v1.00_20080225/liberty/FreePDK45_lib_v1.0_typical.lib

read_libs $LIB_PATH

# -------------------------------------------------------------
# Read RTL & Elaborate
# -------------------------------------------------------------
read_hdl $RTL_DIR/pe_ws.v
read_hdl $RTL_DIR/localized_controller.v
read_hdl $RTL_DIR/systolic_array_4x4.v

elaborate $TOP_MODULE

check_design > $REPORT_DIR/check_design.rpt

# -------------------------------------------------------------
# Constraints (Fixed SDC-201 Warning)
# -------------------------------------------------------------
create_clock -name clk -period 10 [get_ports clk]
set_input_delay  2 -clock clk [all_inputs -no_clocks]
set_output_delay 2 -clock clk [all_outputs]

set_operating_conditions -library typical

# -------------------------------------------------------------
# Optimization & VCD Power Mapping
# -------------------------------------------------------------
set_db syn_global_effort high
set_db syn_map_effort high
set_db syn_opt_effort high

# Fixed VCD-4 Warning by explicitly adding -static
read_vcd -vcd_module tb_systolic_array/dut -static $NETLIST_DIR/../waves/systolic.vcd

# -------------------------------------------------------------
# Synthesis
# -------------------------------------------------------------
syn_generic
syn_map
syn_opt

# -------------------------------------------------------------
# Reports & Netlist
# -------------------------------------------------------------
report_area  > $REPORT_DIR/area_report.rpt
report_power > $REPORT_DIR/power_report.rpt
report_timing > $REPORT_DIR/timing_report.rpt

write_hdl -mapped > $NETLIST_DIR/systolic_array_netlist.v
write_sdc > $REPORT_DIR/systolic_array.sdc
write_db $NETLIST_DIR/systolic_array.db

puts "------------------------------------------"
puts "Synthesis Completed Successfully"
puts "------------------------------------------"
exit
