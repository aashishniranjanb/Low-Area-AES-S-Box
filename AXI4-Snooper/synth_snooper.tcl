# ========================================================
# AXI4 SNOOPER SYNTHESIS FOR MINIMAL AREA (S:2)
# ========================================================
set_db init_lib_search_path /path/to/your/45nm/lib/
set_db library typical.lib

# Read SystemVerilog
read_hdl -sv axi4_snooper.sv
elaborate axi4_snooper

# Constraint: We don't care about extreme speed, we care about ZERO impact on area
create_clock -name clk -period 10.0 [get_ports clk]

# Force Genus to map for the absolute smallest silicon footprint
set_db max_area 0
set_db syn_map_effort high
set_db syn_opt_effort spatial

syn_generic
syn_map
syn_opt

# ========================================================
# GENERATE THE S:2 DELIVERABLES
# ========================================================
report_area > snooper_area_report.txt
report_gates > snooper_gate_count.txt

# Report timing to prove the snooper is fast enough not to bottleneck the bus
report_timing > snooper_timing.txt
quit
