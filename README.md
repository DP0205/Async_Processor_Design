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
