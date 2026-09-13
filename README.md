# Clockless 32-Bit RISC-V (RV32I) Core — Version 1.0 (Asynchronous Baseline)

An event-driven, clockless 5-stage RISC-V processor implemented in pure Verilog HDL. This project converts a standard synchronous RV32I pipelined core into a 4-phase Bundled-Data asynchronous architecture controlled by Muller C-element handshake logic.

---

## 📌 Features in v1.0

* **Global Clock Tree Removed:** The traditional global clock signal has been completely stripped from the pipeline stages, PC, and memory units.
* **4-Phase Bundled-Data Protocol:** Stage synchronization is governed by local `Req` (Request) and `Ack` (Acknowledge) handshake controllers (`async_pipeline_controller.v`).
* **Level-Sensitive Pipeline Latches:** Standard D Flip-Flops across `IF/ID`, `ID/EX`, `EX/MEM`, and `MEM/WB` are replaced by level-sensitive latch arrays (`async_pipeline_latch.v`) driven by stage-wise `latch_enable` signals.
* **Pulse-Strobed Registers & Memory:** The Program Counter (`pc.v`), Register File (`register_file.v`), and Data Memory (`data_memory.v`) write on localized handshake pulses rather than global clock edges.
* **Asynchronous Scoreboarding:** Load-use hazards are handled by withholding local `Ack` signals to freeze upstream stages without needing active clock-gating cells.
* **Internal Write-Bypass:** The register file features write-first logic to prevent same-cycle read/write races during asynchronous execution.

---

## 🏗️ Architecture Overview

```text
                   +-------------------------------------------------------+
                   |          ASYNCHRONOUS PIPELINE HANDSHAKING            |
                   +-------------------------------------------------------+

   [ req_in ] ---> [ IF Controller ] ---> [ ID Controller ] ---> [ EX Controller ] ---> [ MEM Controller ] ---> [ WB Controller ] ---> [ req_out ]
                        |                      |                      |                      |                      |
                        v                      v                      v                      v                      v
                    le_if                  le_id                  le_ex                  le_mem                 le_wb
                        |                      |                      |                      |                      |
                        v                      v                      v                      v                      v
[ PC / Imem ] ====> [ IF/ID Latch ] ========> [ ID/EX Latch ] ========> [ EX/MEM Latch ] ======> [ MEM/WB Latch ] ======> [ Register File ]

---

## 📚 **Academic References & Prior Art**

This implementation is informed by foundational literature in asynchronous hardware design, desynchronization methodology, and variable-latency arithmetic:

1. **I. E. Sutherland**, "Micropipelines," *Communications of the ACM*, vol. 32, no. 6, pp. 720–738, 1989.  
   *(Introduced bundled-data asynchronous processing, Muller C-element controllers, and transparent latch pipelines.)*
2. **J. Cortadella, A. Kondratyev, L. Lavagno, and C. Soteriou**, "Desynchronization: Synthesis of Asynchronous Circuits from Synchronous Specifications," *IEEE Transactions on Computer-Aided Design of Integrated Circuits and Systems*, 2006.  
   *(Provides the theoretical methodology for converting synchronous RTL baselines to clockless handshake logic.)*
3. **S. M. Nowick**, "Design of High-Performance Asynchronous Microprocessors," *PhD Dissertation, Stanford University*, 1993.  
   *(Covers 4-phase handshake protocols, asynchronous scoreboarding, and hazard mitigation.)*
4. **S. M. Nowick et al.**, "Variable-Latency Arithmetic Units for Asynchronous Datapaths," *IEEE Transactions on VLSI Systems*, 1997.  
   *(Foundational theory for early-completion detection and data-dependent execution paths.)*
5. **I. E. Sutherland and S. Cox**, "Data-Dependent Delay Lines for Asynchronous Circuits," *Asynch*, 1996.  
   *(Pioneered dynamic delay tap selection based on operand inspection.)*
6. **M. Tine et al.**, "Mapping Asynchronous Logic Architectures to Modern FPGAs," *FPL*, 2014.  
   *(Implementation guidelines for LUT-based delay lines, primitive preservation (`DONT_TOUCH`), and routing on Xilinx PL architectures.)*

---

## 🚀 **Upcoming Improvements (v2.0 Roadmap)
**
* **Data-Dependent Variable-Delay ALU:** Dynamic delay tap selection (Fast ~2ns, Medium ~5ns, Slow ~12ns) based on opcode and operand bit-width inspection.
* **Xilinx Primitive Delay Mapping:** Mapping delay lines using explicit `LUT1`/`CARRY4` primitives with `DONT_TOUCH` synthesis attributes.
* **Request Gating:** Selective suppression of `Req` signals at WB for non-register writing instructions (`SW`, `BEQ`).
* **ZedBoard FPGA Deployment:** Vivado timing closure, ILA hardware debugging, and dynamic power comparison against a synchronous baseline core.
