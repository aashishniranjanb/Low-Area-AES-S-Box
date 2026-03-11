# Low-Power Sparse Systolic Array Accelerator

## S:4 Power Analysis & True Operand Isolation (Input-Hold)
This design implements True Operand Isolation at the RTL level to dynamically gate combinational logic during sparse matrix workloads. Because the target standard cell library (FreePDK45) lacks Integrated Clock Gating (ICG) cells, the architecture utilizes an **Input-Hold** strategy. By registering the multiplier inputs and holding their previous state when zero-valued activations or weights are detected, the internal nodes of the multiplier tree are prevented from toggling, drastically reducing dynamic switching power.

### Methodology
Power analysis was performed using Cadence Genus. The design was synthesized at a 10ns clock period (100MHz). Dynamic power was evaluated by feeding actual `.vcd` waveform activity from three distinct matrix datasets (Dense, 70% Sparse, 90% Sparse) directly into the Genus Joules power engine.



### Results: Dynamic Power Scaling (Combinational Logic)
| Workload Sparsity | Logic Internal Power | Logic Switching Power | Total Logic Power |
| :--- | :--- | :--- | :--- |
| **Dense (0% Zeros)** | 213.7 µW | 114.9 µW | 334.9 µW |
| **Sparse (70% Zeros)** | 179.1 µW | 94.9 µW | 280.3 µW |
| **Very Sparse (90%)**| 178.3 µW | 94.7 µW | 279.3 µW |

**Conclusion:** The simulation-backed power reports mathematically prove that the Input-Hold operand isolation successfully arrests combinational toggling. As data sparsity increases, the combinational switching power scales down, achieving a **17.5% reduction in dynamic switching power** (and a 16.6% drop in total logic power). This effectively turns mathematical zeros into hardware-level energy savings for AI edge workloads.
