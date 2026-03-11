set_db library /path/to/your/45nm/typical.lib

read_hdl aes_sbox_low_area.v gf_inverse_gf24.v
elaborate aes_sbox_low_area

# THE WINNING S:4 CONSTRAINTS
# Force Genus to prioritize area over everything else
set_db max_area 0 

# High effort synthesis mapped for spatial density
syn_generic -effort high
syn_map -effort high
syn_opt -spatial

report_area > sbox_area_report.txt
report_gates > sbox_gate_count.txt
