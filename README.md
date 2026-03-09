# AES-256-CTR-Mode-Implementation-in-Verilog
This project involves designing an **AES-256** encoder/decoder operating in Counter (CTR) mode using the Verilog hardware description language.

The design is optimized for hardware such as FPGAs, focusing on parallel processing capabilities and low latency.


##  Key Features
* **Algorithm:** AES-256 (Key 256-bit, 14 rounds).
* **Mode:** CTR (Counter Mode).
* **Architecture:** Area-optimized design.
* **Language:** Verilog HDL.

##  Project Structure
* `src/`: Contains the design source code files (.v).
* `tb/`: Includes the Testbench and various test vectors.
* `docs/`: Holds the design documentation and block diagrams.

##  Simulation Guide
To run the simulation using ModelSim or QuestaSim, follow these steps:
1. Open your terminal at the project's root directory.
2. Execute the following commands:
   ```bash
   vlib work
   vlog src/*.v tb/*.v
   vsim -c tb_aes_ctr -do "run -all; quit"
