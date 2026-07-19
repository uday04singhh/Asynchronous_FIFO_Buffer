# Asynchronous FIFO Buffer

A parameterized 64-bit asynchronous FIFO buffer designed in SystemVerilog, built to safely 
transfer data between two independently clocked domains.

## Overview
- Parameterized data width and depth for reuse across different applications
- Handles Clock Domain Crossing (CDC) between independent read and write clocks
- Uses standard CDC-safe techniques (Gray-coded pointer synchronization, multi-flop 
  synchronizers) to prevent metastability
- Verified correct operation across different read/write clock frequency combinations

## Tech Stack
- **Language:** SystemVerilog
- **Verification:** SystemVerilog testbench (simulation-based)

## Files
- `Sources/` — Asynch FIFO RTL (write/read pointer handler, fifo memory, 2 flip-flop synchronizer, Asynch FIFO top module)
- `Testbench/` — SystemVerilog testbench
- `docs/` — waveform screenshots / notes (if available)


## Author
Uday Singh — BE Electronics and Computer Engineering, Thapar Institute of Engineering and Technology
