# RealCPU Project

Make a MIPS CPU and write an operating system.

## Goals

- [x] Single Cycle
- [ ] Memory Access not only for lw/sw
- [ ] Interrupt & Syscalls support
- [ ] L1 Data/Instruction Cache & Unified Memory
- [ ] Initialize $sp and $gp, support $gp addressing
- [ ] Pipeline
- [ ] DDR3 Support
- [ ] SD Card Support
- [ ] Bootloader

## Developing Guide

### Vivado

1. Create a new project
2. **Import** verilog source files
3. Import ipcores folder
4. Regenerate ip cores
5. Import simulation files

### Assembly 

1. Learn Makefile
2. modify objs in Makefile or add a new target
3. use `make` to generate coe files
4. Regenerate ROM/RAM ipcores


