ChaCha20-Poly1305 FPGA Implementation

This repository contains a hardware implementation of the ChaCha20-Poly1305 AEAD algorithm optimized for FPGA platforms, suitable for secure storage applications such as NAND flash memory.

Features

Fully synthesizable FPGA cores for ChaCha20 stream cipher and Poly1305 MAC
Memory-mapped wrapper for easy register access and control
Pipelined multiply-accumulate (MAC) units for high throughput
Optimized for low latency and minimal FPGA resource usage
Supports parallel key expansion and block-wise encryption
Simulation stubs and testbenches included for functional verification
