# RealCPU Project

Make a MIPS CPU and write an operating system.

## CPU Features

1. Nearly complete MIPS32 Release 6 ISA support, without floating points and privileged instructions
2. five stages pipeline with 40M clock
3. Dedicated L1 32K Instrcution & 32K Data Cache
4. 512K Main Memory
5. GCC cross-compile support

## IO Devices Support

1. UART: 4K TX/RX FIFO, support send / receive in c code
2. 24 switches & 24 leds
3. 5 buttons and the keypad
4. Seven-segment display

## TODOs

- [ ] SRAM support
- [ ] TF Card support
- [ ] 


## Goals

- [x] Single Cycle
- [x] Pipeline
- [x] Byte & half-word Memory Access support
- [x] L1 Data/Instruction Cache & Unified Main Memory
- [x] Bootloader, UART loader
- [x] C/C++ cross compile support (limited)
- [ ] Interrupt & Syscalls support
- [x] Initialize $sp and $gp, support $gp addressing
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


