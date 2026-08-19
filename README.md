# Parameterized Synchronous FIFO

## Project Description
This project implements a parameterized Synchronous FIFO (First-In-First-Out) using Verilog HDL. The FIFO stores data and retrieves it in the same order in which it was written.

The design includes different status flags to monitor the FIFO condition and prevent overflow and underflow.

## Features
- Parameterized data width and FIFO depth
- Write and read operations
- Full and Empty flags
- Almost Full and Almost Empty flags
- Programmable Full and Programmable Empty flags
- Circular read and write pointers
- Overflow and underflow protection

## Test Cases
The FIFO design was verified using the following test cases:

1. Basic FIFO Write and Read Operation
2. Full, Almost Full and Programmable Full
3. Empty, Almost Empty and Programmable Empty
4. FIFO Overflow and Underflow Protection

## Tools Used
- Verilog HDL
- AMD Vivado

## Team Members
- Bhargav Bhujbal
- Agastya Pareek

## Project Structure
- `rtl/` - FIFO RTL design
- `testbench/` - Testbench files
- `docs/` - Project documentation
- `screenshots/` - Simulation waveforms
