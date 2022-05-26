# RealCPU Project

Make a MIPS CPU and write an operating system.

## Goals

- [x] Single Cycle
- [x] Pipeline
- [x] Byte & half-word Memory Access support
- [x] L1 Data/Instruction Cache & Unified Main Memory
- [x] Bootloader, UART loader
- [x] C/C++ cross compile support (limited)
- [ ] Interrupt & Syscalls support
- [ ] Initialize $sp and $gp, support $gp addressing
- [ ] DDR3 Support
- [ ] SD Card Support

## Developing Guide

### Vivado

1. Create a new project
2. **Import** verilog source files
3. Import ipcores folder
4. Regenerate ip cores
5. Import simulation files

### Assembly 

1. Learn Makefile
2. use `make $(targets)` to generate ROM and other files
3. Reconfigure coe files generate ROM/RAM ipcores


