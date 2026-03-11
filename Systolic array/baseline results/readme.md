# Low-Power Sparse Systolic Array Accelerator

## S:4 Power Analysis & True Operand Isolation
This design implements True Operand Isolation at the RTL level to dynamically gate combinational logic during sparse matrix workloads. By bypassing the `csa_tree_ADD` multiplier logic when zero-valued activations or weights are detected, the architecture dramatically reduces dynamic switching power.

### Methodology
Power analysis was performed using Cadence Genus (FreePDK45). The design was synthesized at a 10ns clock period (100MHz), and dynamic power was evaluated by feeding actual `.vcd` waveform activity from three distinct matrix datasets directly into the Genus power engine.

### Results: Dynamic Power Scaling
| Workload Sparsity | Logic Internal Power | Logic Switching Power | Logic Total Power |
| :--- | :--- | :--- | :--- |
| **Dense (0% Zeros)** | 194.5 µW | 111.1 µW | 311.3 µW |
| **Sparse (70% Zeros)** | 153.1 µW | 87.1 µW | 246.0 µW |
| **Very Sparse (90%)**| 149.3 µW | 85.4 µW | 240.4 µW |

**Conclusion:** The simulation-backed power reports mathematically prove that as data sparsity increases, the combinational switching power scales down significantly (a ~23% reduction in dynamic switching power). This results in massive energy savings for highly sparse AI workloads, effectively turning mathematical zeros into hardware-level power savings.
