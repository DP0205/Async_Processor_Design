# RV32I 5-Stage Pipelined Processor — Pure Verilog

This is the synchronous baseline processor for the asynchronous RISC-V project.

## Supported instructions

- ADD
- ADDI
- SUB
- AND
- OR
- SLT
- LW
- SW
- BEQ

## Pipeline

IF -> ID -> EX -> MEM -> WB

Pipeline registers:

- IF/ID
- ID/EX
- EX/MEM
- MEM/WB

## Main features

- 32-bit datapath
- 32 x 32-bit register file
- x0 hardwired to zero
- Immediate generation for I/S/B formats
- ALU
- Control decoder
- Data memory
- Instruction memory
- EX/MEM and MEM/WB forwarding
- Load-use hazard detection
- Taken-branch flushing

## Simulation

Using Icarus Verilog:

    iverilog -o sim *.v
    vvp sim

The instruction memory loads `program.hex`.

The testbench prints selected registers and data memory after execution.

## Important

This is deliberately synchronous. Do not add C-elements, Req/Ack,
bundled-data delay paths, or asynchronous stage controllers yet.

The next development step should be:

1. Verify every instruction individually.
2. Verify RAW forwarding.
3. Verify load-use stalls.
4. Verify branch flushing.
5. Add waveform/ILA-visible debug signals.
6. Freeze this as the synchronous baseline.
7. Then begin the asynchronous conversion.
