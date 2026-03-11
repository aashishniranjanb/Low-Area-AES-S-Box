set_db library /absolute/path/to/your/45nm/typical.lib

read_hdl ping_pong_controller.v
elaborate ping_pong_controller

# OVER-CONSTRAIN THE CLOCK FOR MAXIMUM F_MAX
# We ask for a 1.0ns clock (1 GHz) to force Genus to optimize for sheer speed.
create_clock -name clk -period 1.0 [get_ports clk]

syn_generic -effort high
syn_map -effort high
syn_opt -effort high

# Generate the requested deliverables
report_gates > pingpong_gate_count.txt
report_timing > pingpong_timing_fmax.txt
quit
